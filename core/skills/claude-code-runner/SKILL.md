---
name: claude-code-runner
description: Invoke Claude Code as a subprocess from non-interactive contexts (n8n, cron, scripts, parent agents). Mirrors the Hermes claude-code skill pattern but exposes it as a framework primitive for any consumer. Use when something other than a human (or Hermes) needs to drive a Claude Code session against the instance.
---

# Claude Code Runner

A thin wrapper for invoking Claude Code as a subprocess from non-interactive contexts. The framework's bridge for letting any consumer (n8n exec node, cron job, parent script, sibling agent) drive a Claude Code session against the instance using the same conventions.

## When to use this

- An n8n workflow needs to run a Claude Code task on a workstation (e.g., "draft the weekly metrics report against `workstations/operations/active-project/`")
- A cron job needs to run a scheduled task (e.g., "every Monday at 9am, run `/refresh-status` and commit")
- A parent script orchestrates a multi-step workflow that includes a Claude Code session
- An external system (Atlas instance on Mac mini) wants to drive a remote instance (Eno on VPS)

## When NOT to use this

- **Hermes consumers** — Hermes already ships its own `claude-code` skill at `skills/autonomous-ai-agents/claude-code/`. Use Hermes's, not this. Both follow the same pattern; Hermes's is tighter integrated with `terminal()` and `process()` primitives.
- **Direct human invocation** — just type `claude` in a terminal. This skill is for programmatic callers.
- **Tasks that don't need full Claude Code** — if a script can do it deterministically (bash, python, jq), do that. Claude Code is for when reasoning is required.

## Auth model

**Claude Max OAuth — same auth as interactive use.** No API key needed for personal-use deployments.

The `claude` CLI inherits auth from the user's `~/.claude/` config (or the equivalent under whatever HOME the invoking process has). Set up auth once, interactively (`claude` and follow OAuth prompt), under the user that will invoke this skill (typically `eno-agent` or similar non-root service user).

If you need a different non-interactive auth path (CI/CD, true server-to-server with no user account), use `ANTHROPIC_API_KEY` env var — but that's outside this skill's default scope.

## Execution context

**Run as a non-root user.** Claude Code blocks `--dangerously-skip-permissions` when running as root. The invoking process must be a non-root user (`eno-agent`, `hermes`, etc.).

If a privileged process needs to invoke Claude Code, use `sudo -u eno-agent` to drop privileges first, OR use one of the published `claude-code-root-runner` workarounds (creates an unprivileged temp user).

## Invocation pattern

### One-shot, blocking

```bash
cd "${WORKDIR:-$INSTANCE_HOME}" && \
claude --print "${PROMPT}" \
  --max-turns "${MAX_TURNS:-20}" \
  --output-format json \
  --allowedTools "${ALLOWED_TOOLS:-Read,Edit,Bash,Glob,Grep}" \
  ${MODEL:+--model $MODEL} \
  ${SESSION_ID:+--session-id $SESSION_ID}
```

Returns JSON: `{result, session_id, num_turns, total_cost_usd, stop_reason}`.

### Background (long-running)

For tasks > 60s, run in background and poll:

```bash
# Start
SESSION_LOG="${INSTANCE_HOME}/working/sessions/runner-$(date -u +%Y%m%dT%H%M%SZ).log"
nohup bash -c "cd '$WORKDIR' && claude --print '$PROMPT' --max-turns $MAX_TURNS --output-format stream-json --session-id auto > '$SESSION_LOG' 2>&1" &
RUNNER_PID=$!

# Poll
tail -f "$SESSION_LOG"

# Kill if needed
kill "$RUNNER_PID"
```

### Session reuse (cost optimization)

Cold-starting a session re-loads ~50K tokens of system prompt + CLAUDE.md cascade + skill metadata. For sequential tasks against the same workdir, reuse the session:

```bash
# First task — capture session_id
RESULT1=$(claude --print "Task 1" --output-format json --session-id auto)
SID=$(echo "$RESULT1" | jq -r .session_id)

# Subsequent tasks — reuse
claude --print "Task 2" --session-id "$SID"
claude --print "Task 3" --session-id "$SID"
```

## Inputs (when called as a parent-agent skill)

| Input         | Required | Default                              | Description |
|---------------|----------|--------------------------------------|-------------|
| workdir       | yes      | —                                    | absolute path under `${INSTANCE_HOME}` |
| prompt        | yes      | —                                    | the task instruction |
| max_turns     | no       | 20                                   | turn limit |
| allowed_tools | no       | `Read,Edit,Bash,Glob,Grep`           | tool allowlist |
| model         | no       | session default                      | `sonnet`, `opus`, `haiku` |
| session_id    | no       | new                                  | reuse existing for cost |
| timeout_sec   | no       | 600                                  | hard kill after N seconds |
| output_format | no       | `json`                               | `text`, `json`, `stream-json` |

## Outputs

| Output        | Description |
|---------------|-------------|
| stdout        | captured session output (final result if --output-format json) |
| files_changed | list of files created/modified (diffed before/after invocation) |
| session_id    | for reuse |
| exit_code     | 0 = success |
| duration_sec  | actual execution time |
| total_cost_usd | from JSON output (if Max OAuth, this is informational only) |

## Reference implementation: bash wrapper

`scripts/run-claude-code.sh` (called by parent agents):

```bash
#!/bin/bash
# run-claude-code.sh — invoke Claude Code with structured I/O
set -euo pipefail

WORKDIR="${1:?workdir required}"
PROMPT="${2:?prompt required}"
MAX_TURNS="${MAX_TURNS:-20}"
ALLOWED_TOOLS="${ALLOWED_TOOLS:-Read,Edit,Bash,Glob,Grep}"
TIMEOUT_SEC="${TIMEOUT_SEC:-600}"

SESSION_LOG="${INSTANCE_HOME:-$(pwd)}/working/sessions/runner-$(date -u +%Y%m%dT%H%M%SZ).json"
mkdir -p "$(dirname "$SESSION_LOG")"

# Snapshot files before
BEFORE=$(cd "$WORKDIR" && find . -type f -newer /tmp -mmin -10000 2>/dev/null | sort | xargs -I{} stat -f "%N %m" {} 2>/dev/null | sort)

# Run with timeout
START=$(date +%s)
timeout "$TIMEOUT_SEC" bash -c "cd '$WORKDIR' && claude --print '$PROMPT' --max-turns $MAX_TURNS --output-format json --allowedTools '$ALLOWED_TOOLS'" > "$SESSION_LOG" 2>&1
EXIT_CODE=$?
END=$(date +%s)

# Snapshot files after
AFTER=$(cd "$WORKDIR" && find . -type f -mmin -10000 2>/dev/null | sort | xargs -I{} stat -f "%N %m" {} 2>/dev/null | sort)

# Diff to find changes
FILES_CHANGED=$(diff <(echo "$BEFORE") <(echo "$AFTER") | grep -E "^[<>]" | awk '{print $2}' | sort -u | jq -R . | jq -s .)

# Extract session_id from result
SESSION_ID=$(jq -r .session_id "$SESSION_LOG" 2>/dev/null || echo "")
TOTAL_COST=$(jq -r .total_cost_usd "$SESSION_LOG" 2>/dev/null || echo "")

# Emit structured result
jq -n \
  --arg exit_code "$EXIT_CODE" \
  --arg duration_sec "$((END - START))" \
  --arg session_id "$SESSION_ID" \
  --arg total_cost_usd "$TOTAL_COST" \
  --arg session_log "$SESSION_LOG" \
  --argjson files_changed "$FILES_CHANGED" \
  '{exit_code: ($exit_code | tonumber), duration_sec: ($duration_sec | tonumber), session_id, total_cost_usd, session_log, files_changed}'
```

## Hermes parity

The Hermes `claude-code` skill at `skills/autonomous-ai-agents/claude-code/SKILL.md` does the same thing with Hermes's own `terminal()` and `process()` primitives. If you're inside Hermes, use Hermes's. If you're outside Hermes (n8n, cron, generic parent agent), use this.

## Related

- Hermes claude-code skill (parity reference): `${HERMES_HOME}/skills/autonomous-ai-agents/claude-code/SKILL.md`
- `proposal-pipeline` — autonomous Claude Code runs should write proposals, not direct edits
- Anthropic Claude Code docs: https://docs.anthropic.com/en/docs/claude-code
