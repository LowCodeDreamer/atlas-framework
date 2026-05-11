---
description: Manage work items — list, add, complete, or set waiting
argument-hint: "[add|done|waiting] [title/name] [reason]"
---

# Work Management

Manages work items in `working/items/`.

## Usage

```
/work              — List active work items
/work add [title]  — Create new work item
/work done [name]  — Mark item as done
/work waiting [name] [reason] — Set item to waiting
```

## Process

### Parse Arguments

Parse `$ARGUMENTS` to determine subcommand:
- Empty or no args → **list**
- Starts with "add" → **add** (rest is title)
- Starts with "done" → **done** (rest is file name fragment)
- Starts with "waiting" → **waiting** (rest is name + reason)

### Subcommand: List (default)

1. Read all `.md` files in `working/items/`
2. Parse frontmatter from each file
3. Display as a table grouped by status:

```markdown
## Active Work

| Item | Priority | Project | Domain | Due |
|------|----------|---------|--------|-----|
| <Client> Salesforce FSC | high | <domain> | <domain> | 2026-03-15 |
| Lattice Dev Skills | medium | lattice | eno | — |
| ClickUp Cowork Connection | medium | — | atlas | — |
| AI Onboarding Service | medium | — | <domain> | — |

## Waiting

(none)
```

### Subcommand: Add

1. Prompt user for details if not provided:
   - Title (required, from args)
   - Priority (default: medium)
   - Project (optional)
   - Domain (optional)
   - Due date (optional)
2. Generate filename from title: lowercase, hyphens, no special chars
3. Create file in `working/items/` using work-item template frontmatter:

```yaml
---
type: work-item
status: active
priority: [priority]
project: [project]
domain: [domain]
created: "[today's date]"
due: [due or empty]
---

# [Title]

## Objective

[Ask user or leave blank]

## Tasks

- [ ]

## Notes

```

4. Confirm creation with file path.

### Subcommand: Done

1. Find matching file in `working/items/` by name fragment (case-insensitive)
2. If multiple matches, show options and ask user to pick
3. Update frontmatter: set `status: done`
4. Add completion date to frontmatter: `completed: "[today's date]"`
5. Move file to `working/completed/`
6. Confirm with file name

### Subcommand: Waiting

1. Find matching file in `working/items/` by name fragment
2. Update frontmatter: set `status: waiting`
3. Append reason to Notes section if provided
4. Confirm update

## Notes

- All work items live in `working/items/` (active/waiting) or `working/completed/` (done)
- Use `working/WORK.base` in Obsidian for visual dashboard
- Frontmatter is the source of truth for status, priority, etc.
