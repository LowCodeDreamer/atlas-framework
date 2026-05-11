---
description: Expert Q&A pattern - load expertise, validate, answer
argument-hint: <question> [--domain=<domain>] [--expertise=<path>]
---
# Question

Expert Q&A pattern: load expertise, validate, answer.

Use when answering domain-specific questions. Ensures answers are grounded in accumulated expertise rather than generic knowledge.

## Arguments

- `$ARGUMENTS` — The question to answer
- `--domain=<domain>` — The domain context (for loading relevant expertise)
- `--expertise=<path>` — Path to relevant expertise file (optional, auto-detected if not provided)

## Process

1. **Load Expertise**
  - Read the relevant expertise file
  - If no path provided, check `expertise/domains/` and `expertise/functions/` for matches
  - Note the current confidence level and open questions

2. **Validate Assumptions**
  - Does the mental model in the expertise file match current reality?
  - Are there any outdated assumptions?
  - Flag if expertise seems stale or contradicted

3. **Answer the Question**
  - Ground your answer in the loaded expertise
  - Be explicit about confidence level
  - Reference specific entities, patterns, or learnings from expertise
  - If the answer requires knowledge not in expertise, note this

4. **Note Learnings**
  - Did answering this reveal new insights?
  - Should the expertise file be updated?
  - Are there new open questions?

## Output Format

```
**Answer:** [Direct answer to the question]

**Confidence:** [High/Medium/Low] — based on expertise confidence and validation

**Sources:** [References from expertise file or other Atlas files]

**Learnings:** [Any new insights to add to expertise, or "None"]
```

## Example

```
/question What's the best approach for thermal management in the Eno Cube? --domain=eno
```

Output:
```
**Answer:** Based on our mental model, waste heat integration is a key differentiator. The current thinking prioritizes passive cooling with optional heat capture for home heating.

**Confidence:** Medium — this matches our expertise but hasn't been validated with thermal testing.

**Sources:**
- expertise/domains/eno.md (Learnings: "Waste heat integration is key differentiator")
- ventures/eno/HARDWARE.md (size constraints)

**Learnings:** Should add "thermal management approach" to open questions with specific options to evaluate.
```

## Related Commands

- `/validate` — Deeper validation of mental models
- `/self-improve` — Update expertise with learnings
