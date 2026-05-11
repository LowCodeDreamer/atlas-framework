---
description: Validate expertise files against sources of truth
argument-hint: [expertise-path] [--sources=<paths>] [--claims=<specific>]
---

# Validate

Check assumptions and mental models against sources of truth.

Use when expertise may be stale, before major decisions, or when something feels "off."

## Arguments

- `$1` — Path to expertise file to validate
- `--sources=<paths>` — Files or sources to check against (optional, comma-separated)
- `--claims=<specific>` — Specific claims to validate (optional)

## Process

1. **Load Expertise**
   - Read the expertise file at $1
   - Identify claims that can be validated:
     - Key entities and their attributes
     - Stated patterns
     - Relationships
     - Learnings marked as high-confidence

2. **Gather Sources**
   - Read linked files from Key Files section
   - Check referenced domains
   - Access external sources if available (web, APIs)
   - Use provided `--sources` if specified

3. **Compare**
   For each validatable claim:
   - Does the source confirm it?
   - Does the source contradict it?
   - Has the source been updated since the expertise was last updated?
   - Is the claim no longer relevant?

4. **Categorize Findings**
   - ✅ **Confirmed:** Source agrees with expertise
   - ⚠️ **Stale:** Source has newer information
   - ❌ **Contradicted:** Source disagrees with expertise
   - ❓ **Unverifiable:** No source available to check

5. **Recommend Actions**
   - Update expertise with confirmed/stale items
   - Flag contradictions for review
   - Add validation sources for unverifiable claims

## Output Format

```
🔍 Validation Report: [expertise file]

## Summary
- Checked: [N] claims
- Confirmed: [N] ✅
- Stale: [N] ⚠️
- Contradicted: [N] ❌
- Unverifiable: [N] ❓

## Findings

### Confirmed ✅
- [claim]: [source confirms]

### Stale ⚠️
- [claim]: [source has newer info: ...]

### Contradicted ❌
- [claim]: [source says instead: ...]

### Unverifiable ❓
- [claim]: [no source found]

## Recommended Actions
1. [action]
2. [action]
```

## Related Commands

- `/self-improve` — Apply validation findings to update expertise
- `/question` — Uses validation as part of Q&A process
