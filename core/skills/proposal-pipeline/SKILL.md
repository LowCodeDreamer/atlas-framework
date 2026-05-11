---
name: proposal-pipeline
description: Constitutional rule for autonomous routines — never write to canonical state directly; always to system/proposals/. Humans review and /promote to canonical. Use when building autonomous routines (cron jobs, n8n workflows, Hermes tasks, scheduled agents) that propose changes to the instance.
---

# Proposal Pipeline

The pipeline that lets autonomous routines (Hermes, n8n, cron, scheduled agents) propose changes to canonical state without writing to it directly.

## Constitutional Rule

> **No autonomous routine writes to canonical state directly. Always to `system/proposals/`. Human is the only writer to canonical.**

This rule is the foundation of safe autonomy. It makes autonomous changes:
- **Reviewable** — every proposal is a markdown file you can read and diff
- **Reversible** — rejecting a proposal is just deleting a file
- **Auditable** — proposals accumulate as a record of what autonomous routines suggested
- **Composable** — multiple autonomous routines can propose changes without stepping on each other

Without this rule, autonomous routines either get too much power (write directly to canonical, race conditions and surprise edits) or too little (read-only, can't actually help).

## Filesystem convention

```
${INSTANCE_HOME}/system/proposals/
├── YYYY-MM-DD-<routine>-<slug>.md       # proposed changes awaiting review
├── .archive/                             # promoted or rejected proposals (with outcome)
│   └── YYYY-MM-DD-<routine>-<slug>.md
└── _registry.md                          # log of all proposals (auto-maintained by /promote)
```

## Proposal file format

```markdown
---
proposal_id: 2026-05-11-hermes-update-service-registry
generated_by: hermes
generated_at: 2026-05-11T03:14:22Z
target_path: system/registries/services.md
change_type: edit | create | delete
reason: Detected new service `widget-service` added in /docker/widget-service/. Should be in registry.
auto_apply: false
---

## Proposed change

[For `edit`: show diff or before/after. For `create`: show full file content. For `delete`: explain what and why.]

### Diff

```diff
@@ -42,3 +42,4 @@
 | n8n-mcp-server | active | port 3100 | n8n MCP gateway |
 | affine-mcp-server | active | port 3001 | AFFiNE MCP gateway |
 | mission-control | active | port 8081 | Briefing UI |
+| widget-service | active | port 4321 | Widget operations API |
```

## Context

[Why the routine thinks this change is needed. What it observed. What it tried first.]

## Validation

[What checks the routine ran before proposing. E.g., "Confirmed widget-service is running via `docker ps`. Confirmed port 4321 is bound. CLAUDE.md does not currently document this service."]

## Risk assessment

low | medium | high — [one-sentence justification]
```

## Workflow

### 1. Autonomous routine proposes

Routine writes a proposal file to `system/proposals/<id>.md`. It does NOT touch the target file.

If the routine is uncertain or the change is reversible-but-impactful, it sets `auto_apply: false` (default).

If the change is trivial and the routine is highly confident (e.g., updating a status timestamp), it MAY set `auto_apply: true` — `/promote` will then auto-apply on next run if no human review has rejected it within a configurable window (default: 24 hours).

### 2. Human reviews

Two paths:
- **Manual:** Open `system/proposals/`, read the file, decide
- **Batch:** Run `/promote --review-all` to step through pending proposals

### 3. Promote or reject

- `/promote <proposal-id>` — applies the change, archives the proposal to `.archive/<id>.md` with `outcome: promoted`
- `/promote <proposal-id> --reject "<reason>"` — archives to `.archive/<id>.md` with `outcome: rejected` and the reason
- `/promote --review-all` — interactive review of every pending proposal

### 4. Archive trail

Every proposal — promoted or rejected — ends up in `.archive/` with its outcome. This is the audit log.

## Routines that should use this pipeline

- Hermes scheduled tasks that update registries, indexes, or status files
- n8n workflows that ingest content and want to add it to canonical state
- Cron jobs that detect drift (service running but not registered, file orphaned, etc.)
- Scheduled `/equip` runs that suggest new infrastructure

## Routines that should NOT use this pipeline

- Routines that write to non-canonical locations (logs, caches, temp dirs) — those don't need review
- Routines that read but don't write — proposals are for proposed changes
- One-shot scripts run by humans — use git instead

## Required for autonomous-plane consumers

When you build a Hermes task, n8n workflow, or cron job that wants to modify `${INSTANCE_HOME}/`:

1. Check if the target path is canonical (anything in `projects/`, `workstations/`, `services/`, `expertise/`, `system/`, `.claude/`, `hooks/`, root files like CLAUDE.md or _domain.md). If yes → use this pipeline.
2. If the target path is a working directory (`working/`, `logs/`, `tmp/`), direct writes are fine.

## Integration with /equip

When `/equip` runs in scheduled/autonomous mode (e.g., `/equip --autonomous "audit infrastructure gaps"`), it produces an EQUIP_MANIFEST as a proposal rather than building directly. Human reviews the manifest via `/promote`, then it builds.

## Status

v0.1 — filesystem-only convention. No queue daemon, no notification system, no UI. Future versions may add: webhook on new proposal, control panel UI for review, auto-promote rules with severity thresholds.

## Related

- `/promote` command — the human-side review/apply tool
- `inject-context.sh` hook — surfaces pending proposal count in session context
