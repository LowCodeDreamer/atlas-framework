---
name: hook-system
description: Event-driven automation for Claude Code. Use when configuring hooks for context injection, file protection, command logging, session summaries, or notifications. Covers hook events, configuration, and debugging.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
---

# Hook System

Hooks are commands that execute at specific points in Claude Code's lifecycle. They provide reliable automation that doesn't depend on AI choosing to run them—the system enforces it.

## Available Hook Events

| Event | When It Fires | Can Block? |
|-------|---------------|------------|
| `UserPromptSubmit` | Before user prompt is processed | Yes |
| `PreToolUse` | Before a tool executes | Yes (exit 2) |
| `PostToolUse` | After a tool completes | No |
| `Stop` | When agent finishes responding | No |
| `Notification` | When Claude sends notification | No |
| `SessionStart` | When Claude Code session begins | No |
| `SubagentStart` | Before subagent spawns | No |
| `SubagentStop` | After subagent completes | No |
| `PermissionRequest` | When permission prompt appears | Yes (allow/deny) |

**New in Claude Code 2.1:**
- `SessionStart` — Initialize session state, load context
- `SubagentStart`/`SubagentStop` — Track subagent lifecycle for orchestration visibility
- `PermissionRequest` — Auto-approve safe operations (output JSON with decision)

## Configuration

Hooks are configured in `.claude/settings.json`:

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",
            "command": "path/to/script.sh"
          }
        ]
      }
    ]
  }
}
```

### Matcher Patterns

- `"*"` — Match all
- `"Bash"` — Match specific tool
- `"Edit|Write|MultiEdit"` — Match multiple tools (regex OR)

## Atlas Hooks

Located in `${INSTANCE_HOME}/hooks/`:

| Script | Event | Purpose |
|--------|-------|---------|
| `inject-context.sh` | UserPromptSubmit | Load <Identity> persona and values |
| `protect-files.sh` | PreToolUse | Block edits to `.env`, secrets, credentials |
| `check-file-exists.sh` | PreToolUse (Read/Edit) | Validate file paths exist |
| `log-commands.sh` | PreToolUse (Bash) | Audit all bash commands |
| `update-indexes.sh` | PostToolUse (Edit/Write) | Update registry indexes |
| `track-session-activity.sh` | PostToolUse (Read/Edit/Write) | Log file operations to temp activity log |
| `session-init.sh` | SessionStart | Initialize session state |
| `session-end.sh` | Stop | Capture session summary with activity stats |
| `subagent-log.sh` | SubagentStart/Stop | Log subagent lifecycle |
| `auto-approve.sh` | PermissionRequest | Auto-approve safe reads |
| `notify.sh` | Notification | Desktop alerts |

## Input/Output Protocol

### Input (via stdin)

Hooks receive JSON with context:

```json
{
  "session_id": "abc123",
  "cwd": "/current/working/directory",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "ls -la",
    "description": "List files"
  }
}
```

### Output (via exit code)

- **Exit 0:** Success, continue
- **Exit 2:** Block the action (PreToolUse only)

Stdout from hooks can inject content into prompts (UserPromptSubmit).

## Workflow

### How inject-context.sh Works

1. User submits prompt
2. Hook fires before processing
3. Script outputs <Identity> context to stdout
4. Context prepended to user's prompt
5. Claude receives enriched prompt

### How protect-files.sh Works

1. Edit/Write tool about to execute
2. Hook receives file path via stdin JSON
3. Script checks against protected patterns
4. Exit 0 = allow, Exit 2 = block
5. Blocked edits show error message

## Best Practices

1. **Keep hooks fast** — They run on every matching event
2. **Fail gracefully** — Non-critical hooks shouldn't block work
3. **Log sparingly** — Don't fill up disk with logs
4. **Test thoroughly** — Broken hooks break the workflow
5. **Use scripts** — Complex logic goes in script files, not inline JSON

## Debugging

### Check Configuration

```bash
cat ${INSTANCE_HOME}/.claude/settings.json | jq
```

### Test Hook Manually

```bash
echo '{"tool_input":{"command":"ls"}}' | ${INSTANCE_HOME}/hooks/log-commands.sh
echo $?  # Should be 0
```

### View Logs

```bash
# Bash command log
cat ${INSTANCE_HOME}/logs/bash-commands.log

# Session logs
ls ${INSTANCE_HOME}/logs/sessions/
```

## PermissionRequest Hook Output

The `PermissionRequest` event can auto-approve operations by outputting JSON:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow"
    }
  }
}
```

Possible behaviors:
- `"allow"` — Auto-approve the action
- `"deny"` — Auto-deny the action
- (no output) — Fall through to normal permission prompt

## Subagent Lifecycle Tracking

`SubagentStart` and `SubagentStop` events provide visibility into orchestration:

```json
{
  "hook_event_type": "SubagentStart",
  "agent_id": "abc123",
  "parent_agent_id": "root",
  "subagent_type": "file-classifier",
  "description": "Classify inbox file"
}
```

Use for:
- Logging agent spawns for debugging
- Tracking parallel execution patterns
- Measuring agent performance

---

*Hooks make AI behavior deterministic. Use them to enforce what matters.*
