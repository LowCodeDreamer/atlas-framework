---
description: Review and promote (or reject) autonomous-routine proposals from system/proposals/
argument-hint: [<proposal-id>] [--reject "<reason>"] | [--review-all] | [--list]
---

# /promote

Review and apply changes proposed by autonomous routines (Hermes, n8n, cron, scheduled agents). Per the proposal-pipeline constitutional rule, autonomous routines never write canonical state directly — they propose changes via `system/proposals/`. This command is the human-side gate.

## Usage

```
/promote                                  # interactive: list pending, prompt for action
/promote <proposal-id>                    # apply this specific proposal
/promote <proposal-id> --reject "<reason>" # reject this proposal
/promote --review-all                     # step through every pending proposal
/promote --list                           # just list pending proposals, no action
```

Where `<proposal-id>` matches a file at `${INSTANCE_HOME}/system/proposals/<proposal-id>.md`.

## Skill

Read the methodology:
@core/skills/proposal-pipeline/SKILL.md

## Process

### 1. Discover proposals

```bash
ls -t ${INSTANCE_HOME}/system/proposals/*.md 2>/dev/null
```

If empty: report "No pending proposals." and exit.

### 2. Default action: interactive

If invoked with no arguments:
1. List pending proposals (newest first), with `proposal_id`, `generated_by`, `change_type`, `target_path`, `risk_assessment`
2. Ask which to act on (or `all`, or `none`)
3. For each chosen proposal, run the review flow

### 3. Review flow per proposal

For each proposal:
1. Read the proposal file end-to-end (frontmatter + diff/content + context + validation + risk)
2. Read the target file (the file the proposal would change) — show current state
3. Present a side-by-side or diff view to the user
4. Ask the user: `apply | reject | skip | edit-then-apply`

### 4. Apply

If `apply`:
1. Verify `target_path` exists (for edit/delete) or that the parent dir exists (for create)
2. Run a backup: `cp <target> ${INSTANCE_HOME}/working/.backup-promote/<target>.<timestamp>` (skip for create)
3. Apply the change:
   - `edit`: apply the diff (or write the new content if proposal contains full file)
   - `create`: write the new file
   - `delete`: delete the file
4. Validate: if a knowledge_validator or similar applies to the target, run it
5. Append to `${INSTANCE_HOME}/system/proposals/_registry.md`:
   ```
   - 2026-05-11T14:22:01Z | promoted | hermes | system/registries/services.md | <proposal-id>
   ```
6. Move proposal to `.archive/`:
   ```bash
   # Add outcome to the proposal frontmatter, then move
   sed -i '' '/^---$/{x;/^$/{x;s/^/outcome: promoted\noutcome_at: '"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'\n/;b};x}' <proposal>
   mv ${INSTANCE_HOME}/system/proposals/<id>.md ${INSTANCE_HOME}/system/proposals/.archive/
   ```
7. Report what changed

### 5. Reject

If `reject` (with reason):
1. Add `outcome: rejected` and `outcome_reason: "<reason>"` to proposal frontmatter
2. Append to `_registry.md`:
   ```
   - 2026-05-11T14:22:01Z | rejected | hermes | <reason> | <proposal-id>
   ```
3. Move proposal to `.archive/`
4. Report rejection

### 6. Skip

If `skip`: leave proposal in place; user will decide later

### 7. Edit-then-apply

If `edit-then-apply`:
1. Open the proposal in $EDITOR (or show the diff and ask user to provide a modified version)
2. Apply the modified version
3. Mark in registry: `promoted_modified | <reason for modification>`

## Output format

```
== Pending proposals (3) ==

1. 2026-05-11-hermes-update-service-registry [edit | low risk]
   target: system/registries/services.md
   reason: New service `widget-service` detected; not in registry

2. 2026-05-11-hermes-cleanup-stale-active-task [delete | low risk]
   target: working/active/task-2026-04-01.md
   reason: Task is 40 days old with no recent activity

3. 2026-05-10-cron-promote-domain-knowledge [create | medium risk]
   target: expertise/domains/widgets/index.md
   reason: 12 new widget-related notes in working/inbox; suggest creating domain

Action: [1-3 to review one | all to step through | none to exit]
```

## Auto-apply rules

If a proposal has `auto_apply: true` and meets ALL of:
- Has been in `system/proposals/` for more than `${AUTO_APPLY_GRACE_HOURS:-24}` hours
- No human has rejected it
- Risk assessment is `low`
- Change type is `edit` (not `create` or `delete`)

Then `/promote --auto-apply-pending` (typically run by a daily cron) will apply it.

For v0.1, auto-apply is OFF by default. Set `AUTO_APPLY_ENABLED=1` in `${INSTANCE_HOME}/system/identity.env` to enable.

## Safety

- Backup before every edit
- Never auto-apply `delete` or `create`
- Always validate after applying (run target's validators if any)
- Archive every outcome (no proposal is silently dropped)

## Related

- `proposal-pipeline` skill — the convention this command implements
- `meta-agent`, `meta-skill` — building autonomous routines that emit proposals
