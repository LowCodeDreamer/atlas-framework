---
name: strategy-session
description: Multi-domain strategic analysis with parallel advisor agents. Use when evaluating strategic questions, making cross-domain decisions, or running decision sessions.
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Task
  - TaskOutput
  - WebSearch
  - AskUserQuestion
  - Write
---

# Strategy Session

You are the strategy orchestrator. Frame the question, spawn domain advisors in parallel, synthesize findings, and present a structured assessment.

**CRITICAL: You are an orchestrator. Spawn subagents for ALL domain analysis work.**

## Usage

```
/strategy <question>
/strategy <question> --domain=eno
/strategy <question> --domain=all --depth=deep
```

## Arguments

| Argument | Default | Description |
| --- | --- | --- |
| Question | (required) | The strategic question to analyze |
| `--domain` | auto-detect | `eno`, `<domain>`, `<domain>`, `atlas`, `all`, or comma-separated |
| `--depth` | standard | `quick` (frame + synthesize), `standard` (advisors + research), `deep` (advisors + deep research + follow-up) |

---

## EXECUTE THIS WORKFLOW

**YOU MUST USE TOOLS. Do not assume or skip steps. Execute each step.**

### STEP 1: Parse Arguments

Extract from `$ARGUMENTS`:
- `question`: The strategic question (everything not a flag)
- `domain`: Which domains to consult (default: auto-detect from mounted project, fall back to "all")
- `depth`: "quick" | "standard" | "deep" (default: "standard")

Auto-detect domain: If in a workstation with a mounted project, read `active-project/_domain.md` to determine domain. If multiple are relevant, include all.

Map domain values to expertise paths:
- `eno` → `expertise/domains/eno/index.md`
- `<domain>` → `expertise/domains/<domain>/index.md`
- `<domain>` → `expertise/domains/<domain>/index.md`
- `atlas` → `expertise/domains/atlas/index.md`
- `all` → all four domains

### STEP 2: Frame the Question

Restate the question precisely and classify it:

**Cynefin Classification:**
- **Clear** — Best practice exists, cause-effect obvious. Execute.
- **Complicated** — Expert analysis needed, cause-effect discoverable. Analyze.
- **Complex** — Emergent patterns, no predictable cause-effect. Probe-sense-respond.
- **Chaotic** — No patterns, novel situation. Act-sense-respond.

**Door Type:**
- **One-way door** — Hard/impossible to reverse. Requires high conviction.
- **Two-way door** — Easily reversible. Bias toward speed over analysis.

**Constraints:** List known constraints (time, money, dependencies, commitments).

**Success Criteria:** What does "good" look like for this decision?

Present framing to user:

```
## Question Frame

**Question:** [Precise restatement]
**Cynefin:** [Classification] — [one-line rationale]
**Door type:** [One-way / Two-way] — [reversibility assessment]
**Constraints:** [List]
**Good looks like:** [Success criteria]

**Consulting domains:** [list]
**Depth:** [quick/standard/deep]
```

For `quick` depth: Skip to STEP 7 (synthesize inline without advisors).

### STEP 3: Load Domain Expertise

**ACTION REQUIRED:** Read the expertise index for each domain being consulted.

```
Read expertise/domains/{domain}/index.md
```

This content will be passed to each advisor. Do this silently — no output to user.

### STEP 4: Spawn Strategy Advisors (PARALLEL)

**CRITICAL: Spawn ALL advisors in a SINGLE message using multiple Task tool calls.**

For each domain, spawn a strategy-advisor:

```
Task tool:
  subagent_type: "strategy-advisor"
  run_in_background: true
  description: "Analyze from [domain] perspective"
  prompt: |
    You are a strategy advisor analyzing from the [DOMAIN] domain perspective.

    ## Domain Expertise
    [INSERT FULL EXPERTISE INDEX CONTENT HERE]

    ## Strategic Question
    [INSERT FRAMED QUESTION]

    ## Classification
    Cynefin: [class]
    Door type: [type]
    Constraints: [list]

    ## Your Task
    Analyze this question through the lens of [DOMAIN] domain expertise.
    Focus on what this domain uniquely sees that others might miss.

    Return ONLY valid JSON matching this schema (no markdown, no backticks):
    {
      "domain": "[domain]",
      "perspective_summary": "2-3 sentence take",
      "opportunities": [{"description": "...", "reasoning": "...", "magnitude": "high|medium|low"}],
      "risks": [{"description": "...", "reasoning": "...", "severity": "critical|high|medium|low"}],
      "assumptions_to_validate": ["..."],
      "recommendation": "Clear recommendation",
      "confidence": 0.0-1.0,
      "key_insight": "Single most important insight"
    }
```

**SEND ALL TASK CALLS IN ONE MESSAGE.** They will run concurrently.

Report:
```
Spawning advisors...
✓ strategy-advisor (domain: eno) spawned
✓ strategy-advisor (domain: <domain>) spawned
✓ strategy-advisor (domain: <domain>) spawned
✓ strategy-advisor (domain: atlas) spawned
```

### STEP 5: External Research (standard/deep only)

While advisors are running, use WebSearch to gather external context:

**Standard depth:** 1-2 targeted searches on the core question.
**Deep depth:** 3-5 searches covering the question, competitors, market trends, analogous situations.

Store key findings for synthesis. Do NOT present research separately — weave into synthesis.

### STEP 6: Collect Results

Use TaskOutput for each advisor task_id. Parse JSON responses.

Report as each completes:
```
✓ eno advisor complete (confidence: 0.82)
✓ <domain> advisor complete (confidence: 0.71)
✓ <domain> advisor complete (confidence: 0.65)
✓ atlas advisor complete (confidence: 0.88)
```

Handle failures gracefully — if an advisor fails or returns invalid JSON, note it and continue.

### STEP 7: Synthesize

As orchestrator, review all advisor assessments and external research:

**Apply these lenses sequentially:**

1. **Atlas lens (synthesis):** Find agreement — where do multiple domains converge?
2. **Muse lens (exploration):** Find creative tensions — where do domains disagree, and what does the tension reveal?
3. **Cipher lens (skepticism):** Find blind spots — what's NO domain talking about? What assumptions are shared but untested?
4. **Marshall lens (planning):** Find the path — given all of the above, what's the actionable sequence?

**Strategic Frameworks to Apply:**

- **Leverage Points:** Where does small effort yield disproportionate effect?
- **Second-Order Effects:** "And then what?" — trace consequences 2-3 steps out
- **Regret Minimization:** Which option minimizes regret in 5 years?
- **Reversibility Check:** Can we try this and back out if it fails?

### STEP 8: Present Assessment

```markdown
## Strategic Assessment: [Question short title]

### Frame
- **Cynefin:** [Classification]
- **Door type:** [Type]
- **Constraints:** [List]

---

### Domain Perspectives

**[Domain 1]** (confidence: [X])
> [key_insight from advisor]
[1-2 sentence perspective_summary]

**[Domain 2]** (confidence: [X])
> [key_insight from advisor]
[1-2 sentence perspective_summary]

[... repeat for each domain]

---

### Synthesis

**Agreement:** [Where domains converge]

**Tension:** [Where domains disagree and what it reveals]

**Blind Spots:** [What no domain addressed]

**External Context:** [Key findings from web research]

---

### Options

| Option | Upside | Downside | Reversibility | Domains Favoring |
|--------|--------|----------|---------------|-----------------|
| [A] | ... | ... | High/Med/Low | eno, atlas |
| [B] | ... | ... | High/Med/Low | <domain> |
| [C] | ... | ... | High/Med/Low | <domain> |

---

### Recommendation

**[Clear recommendation]**

**Rationale:** [Why this is the right call given synthesis]

**Reversal criteria:** [What would make us change course]

**Second-order effects:** [Expected downstream consequences]

---

### Next Steps

1. [ ] [Immediate action]
2. [ ] [Validation step]
3. [ ] [Follow-up decision point]
```

### STEP 9: Decision Capture (optional)

Ask the user:
```
Capture this as a decision record? (y/n)
```

If yes, write to `knowledge/YYYY-MM-DD-decision-{slug}.md`:

```yaml
---
type: decision
domain: [primary domain]
status: decided
reversibility: [one-way|two-way]
confidence: [0.0-1.0]
created: YYYY-MM-DD
tags:
  - strategy
  - [domain]
---
```

Body: Context, options considered, decision made, rationale, reversal criteria.

---

## Parallel Execution Enforcement

**WRONG (Sequential):**
```
Message 1: Task(advisor-eno)
[wait]
Message 2: Task(advisor-<domain>)
[wait]
```

**RIGHT (Parallel):**
```
Message 1: Task(advisor-eno) + Task(advisor-<domain>) + Task(advisor-<domain>) + Task(advisor-atlas)
[all run concurrently]
Message 2: TaskOutput(1) + TaskOutput(2) + TaskOutput(3) + TaskOutput(4)
```

## Quick Depth Behavior

When `--depth=quick`:
- Skip advisor spawning entirely
- Load expertise indexes inline (STEP 3)
- Go directly to STEP 7 synthesis using loaded expertise
- Lighter framework application (Cynefin + door type + one lens)
- Still present structured assessment (STEP 8)
- Skip external research

This is for fast, low-cost strategic thinking — 1-2 minute sessions.

## Related

- [[../../agents/strategy-advisor|strategy-advisor]] — Domain analysis subagent
- [[../output-styles/SKILL|Output Styles]] — Lens composition (atlas, muse, cipher, marshall)
- [[../agent-orchestration/SKILL|Agent Orchestration]] — Fork vs inline patterns

---

*Frame. Analyze. Synthesize. Decide.*
