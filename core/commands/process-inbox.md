---
description: Process inbox files through classification, normalization, and domain curation
argument-hint: "[--dry-run] [--skip-curation] [--limit=N]"
context: fork
allowed-tools: null
---
# Process Inbox

Process files in `working/inbox/` through the normalization pipeline.

## Architecture

```
/process-inbox (Geoffrey orchestrates)
    │
    ├─ STAGE 1: Scan & Classify
    │   └─ normalize.py --dry-run --json → get metadata
    │
    ├─ STAGE 2: AI Analysis (per file)
    │   └─ Generate title, summary, tags from content
    │
    ├─ STAGE 3: Normalize
    │   └─ normalize.py --title --summary --tags → knowledge/{date}-{slug}.md
    │
    ├─ STAGE 4: Domain Curation (default ON, parallel)
    │   └─ Route to domain experts by tag matching
    │
    └─ STAGE 5: Report
```

## Arguments

- `--dry-run` — Preview what would happen without writing
- `--skip-curation` — Skip domain expert curation (default: curation ON)
- `--limit=N` — Process only first N files

## Process

### STAGE 1: Scan Inbox

```bash
ls -1 ${INSTANCE_HOME}/working/inbox/ 2>/dev/null | grep -v "^\."
```

If empty, report and exit.

### STAGE 2: Classify Each File

For each file, run the classify script:

```bash
python3 ~/.claude/skills/file-normalization/scripts/normalize.py \
  "/Users/derekchapman/${INSTANCE_HOME}/working/inbox/{filename}" \
  --dry-run --json
```

This returns:
- `classification.handler` — file type (text, image, document, etc.)
- `extraction.content` — extracted text (if applicable)
- `needs_ai` — whether AI analysis needed
- `ai_prompt` — suggested prompt for analysis

### STAGE 3: AI Analysis

For files needing AI analysis, analyze the extracted content:

**Generate:**
1. **Title** — Concise, descriptive (3-8 words)
2. **Summary** — 1-2 sentence description
3. **Tags** — 3-7 relevant tags
4. **Domains** — Which domain experts should curate (atlas, <domain>, eno, <domain>)
5. **Type** — note, reference, artifact, media, or data

**Tag sources:**
- Check existing tags in similar `knowledge/*.md` files
- Use domain names when relevant
- Balance broad (eno) with specific (market-strategy)

### STAGE 4: Normalize

Run normalization with AI-generated metadata:

```bash
python3 ~/.claude/skills/file-normalization/scripts/normalize.py \
  "/Users/derekchapman/${INSTANCE_HOME}/working/inbox/{filename}" \
  --title="{title}" \
  --summary="{summary}" \
  --tags={comma-separated-tags} \
  --type={type}
```

This:
- Creates `knowledge/{date}-{slug}.md` with YAML frontmatter
- Archives original to `knowledge/.originals/`

### STAGE 5: Domain Curation (Default ON)

**This stage runs by default.** Only skip if `--skip-curation` is explicitly passed.

**Build routing map from tags — match any tag in the set:**

| Domain | Matching tags |
|--------|--------------|
| atlas | `atlas`, `multi-agent-systems`, `agent-architecture`, `prompt-engineering`, `tool-design`, `ai-agents`, `self-improvement` |
| eno | `eno`, `eno-project`, `energy`, `insurance-market`, `deregulation` |
| <domain> | `<domain>`, `consulting`, `brand`, `business-strategy` |
| <domain> | `<domain>`, `sierra-insurance`, `salesforce`, `broker-of-record`, `fsc` |

A file routes to ALL matching domains (can hit multiple).

**Spawn domain experts in parallel:**

```
Task tool:
  subagent_type: "domain-{domain}"
  model: sonnet
  prompt: |
    Curate this newly normalized knowledge file for your domain:

    **File:** `{knowledge_path}`
    **Title:** {title}
    **Summary:** {summary}
    **Tags:** {tags}

    Read the full file, assess relevance to your domain,
    identify connections to existing knowledge, and update
    your domain index.
```

Launch all matching domain experts in parallel (use separate Task calls, not sequential). If no tags match any domain, skip this stage for that file and note it in the report.

### STAGE 6: Report

```markdown
📥 Inbox Processing Complete

## Summary
- **Files processed**: {count}
- **Normalized**: {count} → knowledge/
- **Domain experts invoked**: {count} (if curation enabled)

## Files

| Original | Output | Tags |
|----------|--------|------|
| {filename} | knowledge/{output}.md | [tag1, tag2] |

## Domain Routing

| Domain | Files | Status |
|--------|-------|--------|
| eno | 2 | ✓ curated |
| atlas | 1 | ✓ curated |

## Next Steps
- Review normalized files in knowledge/
- Check domain indices for new connections
```

## Examples

```bash
# Process all inbox files
/process-inbox

# Preview only (no writes)
/process-inbox --dry-run

# Process 3 files, skip curation
/process-inbox --limit=3 --skip-curation
```

## Scripts

The heavy lifting is in Python scripts:
- `~/.claude/skills/file-normalization/scripts/classify.py` — File type detection
- `~/.claude/skills/file-normalization/scripts/extract.py` — Content extraction
- `~/.claude/skills/file-normalization/scripts/normalize.py` — Full pipeline

## Related

- [[.claude/skills/file-normalization/SKILL|File Normalization Skill]]
- [[.claude/agents/file-organizer|File Organizer Agent]]
- [[expertise/domains/_registry|Domain Expert Registry]]
