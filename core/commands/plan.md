---
description: Create a structured plan for complex tasks
argument-hint: <goal> [--context=<background>] [--constraints=<limits>]
---
# Plan

Create a structured plan for a complex task or goal.

Use when you need to break down a complex task into actionable steps before execution.

## Arguments

- `$ARGUMENTS` — The goal to plan for (what needs to be accomplished)
- `--context=<background>` — Relevant background information and current state (optional)
- `--constraints=<limits>` — Limitations, requirements, or boundaries (optional)

## Process

1. Break the goal into discrete phases (3-7 phases typically)
2. For each phase, identify:
  - **Objective:** What success looks like
  - **Actions:** Specific steps to take
  - **Dependencies:** What must happen first
  - **Validation:** How to verify completion
3. Flag any ambiguities or decisions needed before proceeding
4. Note which phases can run in parallel vs. must be sequential
5. Identify risks or blockers that could derail the plan

## Output Format

```markdown
# Plan: [Goal]

## Phase 1: [Name]
- **Objective:** [What success looks like]
- **Actions:**
  - [Step 1]
  - [Step 2]
- **Dependencies:** [What must happen first]
- **Validation:** [How to verify completion]

## Phase 2: [Name]
...

## Risks & Blockers
- [Risk 1]
- [Risk 2]

## Decisions Needed
- [Decision 1]
```

## Example

```
/plan Set up marketing automation for <Client> --context="Small consulting practice, LinkedIn focus, limited budget" --constraints="Must integrate with HubSpot, <$100/month tools"
```

## Related Commands

- `/validate` — Check plan against reality before executing
- `/question` — Clarify unknowns identified in planning
