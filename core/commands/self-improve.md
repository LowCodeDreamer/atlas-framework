---
description: Update expertise files with learnings from completed work
argument-hint: <expertise-path> [--work=<summary>] [--notes=<observations>]
---

# Self-Improve

Update expertise files with learnings from completed work.

Use at the end of a work session or after completing a significant task. Ensures learnings are captured and the mental model evolves.

## Arguments

- `$1` — Path to expertise file to update
- `--work=<summary>` — Brief summary of work completed
- `--notes=<observations>` — Notes, insights, or observations from the session

## Process

1. **Load Current Expertise**
   - Read the expertise file
   - Note current version, confidence, and last update

2. **Identify Learnings**
   Review the work and notes for:
   - New entities to add to Mental Model
   - New patterns discovered
   - Updated relationships
   - Answered open questions (move to Learnings)
   - New open questions
   - Confidence changes (up or down)

3. **Categorize Changes**
   - **Minor:** Small additions, clarifications → increment version
   - **Significant:** New patterns, major insights → increment version, consider confidence bump
   - **Corrective:** Fixed wrong assumptions → increment version, may lower confidence

4. **Update the File**
   - Add to Learnings table with date and source
   - Update Key Entities if new ones discovered
   - Update Patterns if new patterns emerged
   - Resolve or add Open Questions
   - Update confidence if warranted
   - Update `updated_at` timestamp
   - Increment version number

5. **Report Changes**
   Summarize what was updated and why.

## Output Format

```
📝 Updated: [expertise file path]
📊 Version: [old] → [new]
📈 Confidence: [unchanged/increased/decreased]

Changes:
- Added learning: "[insight]"
- Resolved question: "[question]"
- New question: "[question]"
- [other changes]
```

## Example

```
/self-improve expertise/domains/eno.md --work="Researched grant landscape for digital sovereignty projects" --notes="Found NSF has relevant programs. Mozilla Foundation also funds this space."
```

Output:
```
📝 Updated: expertise/domains/eno.md
📊 Version: 1 → 2
📈 Confidence: unchanged (medium)

Changes:
- Added learning: "NSF and Mozilla Foundation have relevant grant programs" (2025-12-26, grant research)
- Resolved question: "Which grants align with digital sovereignty mission?" → partially answered
- New question: "What are specific NSF program deadlines?"
- Added entity: "NSF" (type: funder)
- Added entity: "Mozilla Foundation" (type: funder)
```

## Related Commands

- `/question` — Often generates learnings to capture
- `/validate` — Check if learnings are accurate
