# Hermes Bridge

How the autonomous plane (Hermes, n8n, cron, scheduled agents) consumes the framework's instance layer.

## Premise

Claude Code is the human work layer. Hermes is the autonomous work layer. **Both consume the same instance** — same filesystem, same skills, same conventions.

Hermes ships a `claude-code` skill (`skills/autonomous-ai-agents/claude-code/SKILL.md`) that invokes the `claude` CLI as a subprocess. This is the bridge: Hermes doesn't reinvent Claude Code's capabilities; it invokes a Claude Code session against the instance and consumes the result.

## The pattern

```
┌──────────────────────────────────────────────────────────────┐
│ Hermes scheduled task fires (cron, heartbeat, event)         │
│                                                               │
│   1. Hermes determines: "This task needs reasoning. Run a    │
│      Claude Code session against workstation X."             │
│                                                               │
│   2. Hermes invokes its claude-code skill:                   │
│      terminal(command="claude --print '<task>'              │
│                workdir=instance/workstations/<ws>/active-project│
│                --output-format json", pty=true)              │
│                                                               │
│   3. Claude Code session runs:                               │
│      - Loads cascade CLAUDE.md (root → workstation → project)│
│      - Loads framework agents/commands/skills                │
│      - Executes the task                                     │
│      - May write to working/, may propose to system/proposals│
│                                                               │
│   4. Session completes. Hermes captures stdout (JSON):       │
│      { result, session_id, files_changed, ... }              │
│                                                               │
│   5. Hermes processes the result:                            │
│      - If files_changed includes canonical paths → propose   │
│        review via /promote (don't auto-apply)                │
│      - If result is informational → log and notify           │
│      - If session failed → retry or alert                    │
└──────────────────────────────────────────────────────────────┘
```

## Auth: Claude Max OAuth

Both human-driven sessions and Hermes-driven sessions use the same Claude Max OAuth credentials. No API key needed for personal-use deployments.

The `claude` CLI inherits auth from the user's `~/.claude/` config. Set up auth interactively once (under the user that will run Hermes), and that user's invocations are authenticated.

Per Anthropic Feb 2026: personal use via Max is explicitly permitted, including driving agents like Hermes. Building a service for external users requires API keys instead.

## Execution context

**Hermes must run as a non-root user** (e.g., `hermes`, `eno-agent`). Claude Code blocks `--dangerously-skip-permissions` when running as root, which breaks autonomous invocations.

If Hermes currently runs as root, migrate it to a dedicated user before relying on the Claude Code bridge for canonical work.

## Constitutional rule for Hermes

**Hermes never writes to canonical instance state directly.** When a Hermes-driven Claude Code session would modify canonical state (anything in `projects/`, `workstations/`, `services/`, `expertise/`, `system/`, `.claude/`, `hooks/`, root files), the session writes a proposal to `system/proposals/` instead.

The session's prompt should include this rule. Example:

```
You are running in autonomous mode under Hermes.

Constitutional rule: do NOT modify any file under projects/, workstations/, 
services/, expertise/, system/, .claude/, hooks/, or root files (CLAUDE.md, 
_domain.md). If a change to these is needed, write a proposal to 
system/proposals/<timestamp>-hermes-<slug>.md instead, following the 
proposal-pipeline skill.

Free to edit: working/, logs/, system/proposals/.
```

This is enforced by convention, not the filesystem. A misbehaving session could write canonically — the protect-files.sh hook should be configured to block writes to these paths during autonomous sessions.

## Recommended task patterns for Hermes

### 1. Read-only digest tasks
Hermes runs Claude Code to read state and produce a summary. No proposals, no edits.

```
"Read services/*/CLAUDE.md and produce a short health summary. 
Return as JSON with one entry per service: {name, status, last_updated, concerns}."
```

### 2. Drift detection → proposal tasks
Hermes runs Claude Code to compare expected vs actual state, propose corrections.

```
"Compare the running docker containers (via docker ps) against system/registries/services.md. 
For each discrepancy (running container not in registry, or registry entry not running), 
write a proposal to system/proposals/ following the proposal-pipeline skill. 
Do not edit the registry directly."
```

### 3. Scheduled refresh tasks
Hermes runs Claude Code to regenerate computed artifacts.

```
"Run /refresh-status to regenerate SYSTEM-STATUS.md. Then run git status; 
if SYSTEM-STATUS.md changed, write a proposal to commit it via system/proposals/."
```

### 4. Inbox processing tasks
Hermes runs Claude Code to triage inbox files.

```
"Run /process-inbox to classify and route files in working/inbox/. 
Each ingestion writes to expertise/domains/<domain>/ via proposal pipeline."
```

## Anti-patterns

- ❌ Hermes session edits `services/widget-service/_manifest.md` directly — should propose
- ❌ Hermes runs as root — should run as `hermes` or `eno-agent`
- ❌ Hermes reuses no session_id — burns 50K tokens per cold start; reuse for sequential same-workdir tasks
- ❌ Hermes runs without timeout — should hard-cap with `timeout` or Hermes's own budget mechanism
- ❌ Hermes auto-applies proposals — `/promote` is human-only by default; auto-apply only with explicit toggle and only for low-risk edits

## See also

- Hermes claude-code skill: `${HERMES_HOME}/skills/autonomous-ai-agents/claude-code/SKILL.md`
- `core/skills/claude-code-runner/SKILL.md` — equivalent skill for non-Hermes consumers (n8n, cron, scripts)
- `core/skills/proposal-pipeline/SKILL.md` — the constitutional rule and filesystem convention
- `core/commands/promote.md` — the human-side review/apply tool
