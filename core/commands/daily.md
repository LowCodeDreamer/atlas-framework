---
description: Quick daily note interaction — read, log, or add notes
argument-hint: "[log|note] [text]"
---

# Daily Note

Interact with today's daily note in `daily/`.

## Usage

```
/daily            — Read today's daily note (create if missing)
/daily log [text] — Append to Work Log section
/daily note [text] — Append to Notes section
```

## Process

### Determine Today's File

Today's file path: `daily/YYYY-MM-DD.md` (using current date).

### Parse Arguments

Parse `$ARGUMENTS`:
- Empty → **read**
- Starts with "log" → **log** (rest is text)
- Starts with "note" → **note** (rest is text)

### Subcommand: Read (default)

1. Check if `daily/[today].md` exists
2. If exists: Read and display the content
3. If missing: Create from template:

```markdown
---
type: daily-note
date: "[today's date]"
---

# [today's date]

## Work Log

-

## Notes

```

4. Display the note content

### Subcommand: Log

1. Ensure today's daily note exists (create if missing, as above)
2. Read the file
3. Find the `## Work Log` section
4. Append `- [text]` after the last entry in that section
5. Write the updated file
6. Confirm: `Logged to [date]: [text]`

### Subcommand: Note

1. Ensure today's daily note exists (create if missing)
2. Read the file
3. Find the `## Notes` section
4. Append the text after existing content in that section
5. Write the updated file
6. Confirm: `Added note to [date]`

## Notes

- Daily notes live in `daily/` with format `YYYY-MM-DD.md`
- Template is at `templates/daily-note.md`
- Obsidian daily-notes plugin is configured to use the same folder
