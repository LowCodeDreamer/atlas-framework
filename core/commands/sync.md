---
description: Git sync - stage, commit with smart message, push
argument-hint: "[message]"
---

# Sync

Quick git sync for Atlas. Stages all changes, generates a commit message from the diff, and pushes.

## Usage

```
/sync
/sync [custom message]
```

## Arguments

- `$ARGUMENTS` — Optional custom commit message (overrides auto-generated)

## Workflow

### Step 1: Pre-flight Checks

```bash
cd ${INSTANCE_HOME} && git rev-parse --git-dir 2>/dev/null
```

If not a git repo, stop with error.

```bash
cd ${INSTANCE_HOME} && git remote get-url origin 2>/dev/null
```

If no remote configured, warn but allow local commit.

### Step 2: Check for Changes

```bash
cd ${INSTANCE_HOME} && git status --porcelain
```

If empty output, report "Nothing to sync" and exit.

### Step 3: Stage All Changes

```bash
cd ${INSTANCE_HOME} && git add -A
```

### Step 4: Generate Commit Message

If `$ARGUMENTS` provided, use that as the commit message.

Otherwise, analyze what changed:

```bash
cd ${INSTANCE_HOME} && git diff --cached --stat
```

Generate a concise commit message based on:
- Files added/modified/deleted
- Directories affected (domains, skills, commands, working, etc.)
- Nature of changes (new content, updates, cleanup, etc.)

Format: `[area]: brief description`

Examples:
- `skills: add sync command`
- `domains: update client project notes`
- `working: archive completed tasks`
- `multi: inbox processing + domain updates`

### Step 5: Commit

```bash
cd ${INSTANCE_HOME} && git commit -m "MESSAGE"
```

### Step 6: Push (if remote exists)

```bash
cd ${INSTANCE_HOME} && git push origin HEAD
```

If push fails due to upstream changes:
```bash
cd ${INSTANCE_HOME} && git pull --rebase origin HEAD && git push origin HEAD
```

## Output Format

```
Synced to Atlas:
- [+3 -1 ~5] files (added/deleted/modified)
- Commit: [commit message]
- Pushed: origin/[branch]
```

Or if no remote:
```
Committed locally:
- [+3 -1 ~5] files
- Commit: [commit message]
- No remote configured (local only)
```

## Edge Cases

| Situation | Behavior |
|-----------|----------|
| No changes | "Nothing to sync" - exit cleanly |
| Not a git repo | Error with instructions to initialize |
| No remote | Commit locally, note no push |
| Push rejected | Auto-rebase and retry |
| Merge conflict | Stop and report, don't auto-resolve |

---

*Quick sync. No friction.*
