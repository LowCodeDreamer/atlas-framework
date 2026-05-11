# Tag System

Self-evolving tag registry for Atlas knowledge organization.

## Design Principles

1. **Emergent taxonomy** — Tags evolve from usage, not predetermined
2. **Low friction** — New tags allowed freely, consolidate later
3. **Hierarchical** — Parent.child relationships (e.g., `atlas.skills`)
4. **Monthly review** — Consolidation candidates identified automatically

## Tag Format

- Lowercase
- Dash-separated words (`weekly-review` not `weeklyReview`)
- Hierarchical with dots (`atlas.skills`, `<domain>.clients`)
- Max 30 characters

## Registry Structure

Location: `knowledge/.system/tag-registry.md`

```yaml
tags:
  productivity:
    count: 47
    last_used: 2025-12-26
    parent: null
    aliases: []

  weekly-review:
    count: 12
    last_used: 2025-12-25
    parent: productivity
    aliases: [weekly-planning]

  atlas:
    count: 89
    last_used: 2025-12-26
    parent: null
    aliases: []

  atlas.skills:
    count: 23
    last_used: 2025-12-26
    parent: atlas
    aliases: []
```

## Operations

### Add Tag

When normalizing a file:
1. Check if tag exists in registry
2. If exists: increment count, update last_used
3. If new: add with count=1, no parent

### Suggest Tags

AI analysis should:
1. Load current registry tags
2. Prefer existing tags when appropriate
3. Suggest new tags only when no good match
4. Flag potential duplicates (fuzzy match)

### Consolidation

Monthly review identifies:
- **Duplicates:** Tags with >80% co-occurrence
- **Orphans:** Tags with count=1 after 30 days
- **Candidates:** Similar tags (Levenshtein distance < 3)

Consolidation actions:
- **Merge:** Combine into canonical tag, update aliases
- **Hierarchy:** Make one parent of other
- **Delete:** Remove unused tags (update files first)

## Standard Tags

### Content Type Tags

Always include one:
- `note` — Original thinking
- `reference` — Captured external content
- `artifact` — Created output
- `media` — Visual/audio
- `data` — Structured data

### Domain Tags

Top-level domains:
- `atlas` — System itself
- `<domain>` — Consulting
- `personal` — Personal life
- `ventures` — Side projects

### Temporal Tags

For time-bound content:
- `q1-2025`, `q2-2025` — Quarters
- `2025-12` — Months (when relevant)
- `weekly-review` — Recurring

### Status Tags

For tracking state:
- `needs-review`
- `in-progress`
- `archived`
- `evergreen` — Timeless content

## AI Tagging Prompt

```
Given this content, suggest 3-7 tags.

Existing tags in the system:
[registry tag list]

Rules:
1. Prefer existing tags when they fit
2. Use hierarchical format (parent.child) for specificity
3. Include one content-type tag (note/reference/artifact/media/data)
4. Include domain tag if clear (atlas/<domain>/personal/ventures)
5. Flag if suggesting a new tag similar to existing

Content:
[extracted content]
```

## Evolution Example

### Initial State (Month 1)

```yaml
productivity: {count: 5}
planning: {count: 3}
weekly-planning: {count: 2}
```

### After Review

Consolidation identified:
- `planning` and `weekly-planning` often co-occur with `productivity`
- `weekly-planning` is specific type of `planning`

Action:
```yaml
productivity: {count: 5}
planning: {count: 5, parent: productivity}
weekly-review: {count: 2, parent: planning, aliases: [weekly-planning]}
```

Files updated to use canonical tags.

## Reporting

Monthly tag health report:
- Total tags
- New tags this month
- Consolidation candidates
- Unused tags (count=1, >30 days old)
- Most used tags (top 10)
- Tag hierarchy visualization
