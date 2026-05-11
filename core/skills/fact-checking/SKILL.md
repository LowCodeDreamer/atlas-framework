---
name: fact-checking
description: Verify factual claims in blog posts and generate citations. Stores results in Supabase for human review before applying to documents.
user-invocable: true
context: fork
allowed-tools:
  - Read
  - Edit
  - Glob
  - Grep
  - Task
  - TaskOutput
  - mcp__supabase__execute_sql
---

# Fact-Checking Workflow

You are the factcheck orchestrator. Parse documents, extract claims, spawn verifier agents in parallel, and store results in Supabase for human review.

**CRITICAL: This is an orchestrator. Spawn fact-checker subagents for ALL verification work.**

## Usage

```
/factcheck <file-path>
/factcheck <file-path> --dry-run
/factcheck <file-path> --limit=10
/factcheck <file-path> --skip-cited
/factcheck <file-path> --apply
```

## Arguments

| Argument | Default | Description |
| --- | --- | --- |
| `$1` | required | Path to MDX/MD file to fact-check |
| `--dry-run` | false | Show extracted claims without verifying |
| `--limit=N` | 20 | Maximum claims to verify |
| `--skip-cited` | false | Skip claims that already have citations |
| `--apply` | false | Apply previously approved changes from Supabase |

---

## EXECUTE THIS WORKFLOW

**YOU MUST USE TOOLS. Do not assume or skip steps.**

### MODE: Normal (Verify)

When called WITHOUT `--apply`:

#### STEP 1: Parse Arguments

Extract from user input:
- `file_path`: Required first argument
- `dry_run`: Boolean (default: false)
- `limit`: Number (default: 20)
- `skip_cited`: Boolean (default: false)

Validate file exists:
```
Read tool: file_path
```

If file not found, error and stop.

#### STEP 2: Read Document and Extract Claims

Read the entire document. Scan for fact-checkable claims.

**Claim Detection Heuristics:**

Include if claim contains:
- Year (1800-2099) + factual statement
- Dollar amount or percentage
- Named person/org + specific action or quote
- Reference to study, paper, or official document
- Quantitative data (numbers, measurements)

Exclude if claim:
- Is opinion/analysis ("I believe", "arguably", subjective)
- Already has `[@citation]` inline
- Contains markdown link to source `[text](url)`
- Is in "Sources", "References", or "Appendix" section
- Is a rhetorical question

For each claim, extract:
- `claim_text`: The full sentence/claim
- `claim_context`: 1-2 surrounding sentences for context
- `line_number`: Approximate line number

**If `--skip-cited`:** Also skip claims followed by citation markers.

Report:
```
📄 Parsing: [file_path]

Found [N] fact-checkable claims
[If --dry-run, list claims and stop here]

Proceeding with verification of [min(N, limit)] claims...
```

#### STEP 3: Create Run in Supabase

**ACTION REQUIRED:** Use mcp__supabase__execute_sql:

```sql
INSERT INTO factcheck_runs (post_path, post_title, total_claims)
VALUES ('[file_path]', '[extracted_title]', [claim_count])
RETURNING id;
```

Store the returned `run_id` for subsequent inserts.

Report:
```
✓ Created factcheck run: [run_id]
```

#### STEP 4: Spawn Verifier Subagents (PARALLEL)

**CRITICAL: Spawn up to 5 fact-checkers in a SINGLE message.**

For claims 1-5 (first batch):

```
Task tool:
  subagent_type: "fact-checker"
  run_in_background: true
  model: haiku
  description: "Verify claim 1"
  prompt: |
    Verify this factual claim:

    claim_id: "claim_001"
    claim_text: "[claim text here]"
    context: "[surrounding context]"

    Use WebSearch to find authoritative sources.
    Return ONLY valid JSON (no markdown, no backticks).
```

**SEND ALL 5 TASK CALLS IN ONE MESSAGE.** They will run concurrently.

Report:
```
Spawning verifiers for batch 1 (claims 1-5)...
✓ fact-checker spawned for claim 1
✓ fact-checker spawned for claim 2
✓ fact-checker spawned for claim 3
✓ fact-checker spawned for claim 4
✓ fact-checker spawned for claim 5

Waiting for results...
```

#### STEP 5: Collect Results

Use TaskOutput for each task_id. Parse JSON responses.

For each completed verification, insert into Supabase:

```sql
INSERT INTO factcheck_claims (
  run_id, claim_text, claim_context, line_number,
  verification_status, confidence, notes, update_available, review_status
) VALUES (
  '[run_id]', '[claim_text]', '[context]', [line_number],
  '[status]', [confidence], '[notes]', '[update_json]', 'pending'
) RETURNING id;
```

Then insert source:

```sql
INSERT INTO factcheck_sources (claim_id, url, title, snippet, reliability_tier)
VALUES ('[claim_id]', '[url]', '[title]', '[snippet]', '[reliability]');
```

Update run verified_count:

```sql
UPDATE factcheck_runs SET verified_count = verified_count + 1 WHERE id = '[run_id]';
```

Report as each completes:
```
✓ Claim 1: verified (95% confidence) - Reuters
✓ Claim 2: verified (80% confidence) - Wikipedia
✓ Claim 3: unverifiable - no sources found
...
```

#### STEP 6: Repeat for Remaining Batches

If more claims remain, spawn next batch of 5.

Wait 2 seconds between batches to avoid rate limits.

#### STEP 7: Generate Summary

Query final counts:

```sql
SELECT
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE verification_status = 'verified') as verified,
  COUNT(*) FILTER (WHERE verification_status = 'partially_verified') as partial,
  COUNT(*) FILTER (WHERE verification_status = 'disputed') as disputed,
  COUNT(*) FILTER (WHERE verification_status = 'unverifiable') as unverifiable
FROM factcheck_claims
WHERE run_id = '[run_id]';
```

Report:
```
## Factcheck Complete

**Post:** [file_path]
**Run ID:** [run_id]

### Summary
- Total claims checked: [N]
- Verified: [N] ✓
- Partially verified: [N] ~
- Disputed: [N] ⚠
- Unverifiable: [N] ?

### Review Required
[N] claims pending human review.

**Review at:** https://[supabase-project].supabase.co/functions/v1/factcheck-review?run=[run_id]

Once reviewed, run:
/factcheck [file_path] --apply
```

---

### MODE: Apply

When called WITH `--apply`:

#### STEP 1: Get Approved Claims

```sql
SELECT
  c.id, c.claim_text, c.line_number, c.verification_status,
  c.confidence, c.notes, c.update_available,
  s.url, s.title, s.reliability_tier
FROM factcheck_claims c
LEFT JOIN factcheck_sources s ON s.claim_id = c.id
WHERE c.run_id IN (
  SELECT id FROM factcheck_runs
  WHERE post_path = '[file_path]'
  AND applied_at IS NULL
)
AND c.review_status = 'accepted'
AND c.applied_at IS NULL;
```

If no approved claims:
```
No approved claims to apply.
Review claims at: [review URL]
```

#### STEP 2: Build Citations Section

Format approved claims into markdown:

```markdown
---

## Sources & Verification

*Fact-checked on [date] via Atlas*

| Claim | Status | Source |
|-------|--------|--------|
| [claim summary] | Verified | [1] |
| [claim summary] | Verified | [2] |

## References

[1] [Author]. "[Title]." [Source]. [URL]
[2] ...
```

#### STEP 3: Apply Updates (if any)

For claims with `update_available` where `is_material_change = false`:
- Find original text in document
- Replace with `suggested_replacement`

#### STEP 4: Append Citations to Document

Use Edit tool to append the citations section to the document.

#### STEP 5: Mark as Applied

```sql
UPDATE factcheck_claims
SET applied_at = NOW()
WHERE run_id = '[run_id]' AND review_status = 'accepted';

UPDATE factcheck_runs
SET applied_at = NOW()
WHERE id = '[run_id]';
```

Report:
```
## Changes Applied

✓ [N] citations added to document
✓ [N] text updates applied (non-material)
✓ Run marked as applied

Skipped:
- [N] claims rejected
- [N] material changes (require manual review)
```

---

## Error Handling

| Scenario | Action |
| --- | --- |
| File not found | Error: "File not found: [path]" |
| Not MDX/MD | Error: "Unsupported file type" |
| No claims found | Report: "No fact-checkable claims found" |
| Agent timeout | Log error, continue with other claims |
| Supabase error | Log and continue if possible |
| All agents fail | Report partial results |

## Parallel Execution Pattern

**✅ RIGHT (Parallel):**
```
Message 1: Task(claim1) + Task(claim2) + Task(claim3) + Task(claim4) + Task(claim5)
           [all run concurrently]
Message 2: TaskOutput(1) + TaskOutput(2) + TaskOutput(3) + TaskOutput(4) + TaskOutput(5)
```

**❌ WRONG (Sequential):**
```
Message 1: Task(claim1)
[wait]
Message 2: Task(claim2)
[wait]
...
```

## Review URL Format

After verification, provide the review URL:
```
https://[project].supabase.co/functions/v1/factcheck-review?run=[run_id]
```

The Edge Function serves a simple HTML page for human review.
