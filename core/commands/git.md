# /git Command

Execute git operations with terse summaries to preserve main conversation context.

## Usage

```
/git status
/git commit [message]
/git diff
/git log
/git branch [name]
```

## Implementation

1. Load agent instructions from `.claude/agents/git-ops.md`
2. Spawn Bash agent with git-ops response format
3. Return ONLY terse summary to main conversation

## Response Format

All responses follow this terse format:

```
[emoji] [Operation]: [one-line summary]
Files: [count] | Lines: +X/-Y
[Hash/Branch if applicable]
```

## Examples

```
/git status
→ 📊 Status: 3 modified, 2 untracked

/git commit
→ ✅ Committed abc123: feat: add user auth
   Files: 15 | Lines: +200/-50

/git diff
→ 📝 Diff: 8 files, +180/-65 total
```

## Execution

Spawn Task with `subagent_type: Bash` and the following prompt:

```
Execute: git $ARGUMENTS

Return ONLY a terse summary in this format:
[emoji] [Operation]: [summary]
Files: [count] | Lines: +X/-Y

For commits:
- Generate smart message using conventional commits (feat/fix/docs/refactor/chore)
- Include Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
- Warn about potential secrets (.env, tokens)

Do NOT output full diffs, file lists, or verbose git output.
```
