---
description: Initialize a new workstation (recurring capability environment)
argument-hint: "<name>"
id: command_init_workstation
type: command
created_at: 2026-05-14T22:00:00Z
---

# Init Workstation

Create a new workstation directory and scaffold its CLAUDE.md, .mcp.json, and active-project mount point from the framework template.

## Usage

```
/init-workstation <name>
```

`<name>` should be kebab-case and describe the recurring capability (e.g. `web-dev`, `legal-drafting`, `content-studio`).

## Workflow

### 1. Validate

- Parse `$ARGUMENTS` into `WORKSTATION_NAME`.
- If empty, ask: "What capability environment is this for? (kebab-case name)".
- Check that `${INSTANCE_HOME}/workstations/<name>/` does not already exist. If it does, abort with "Workstation already exists at <path>. Pick a different name or rm the old one first.".

### 2. Gather purpose

Use AskUserQuestion to capture:

- **Purpose** — One sentence: what recurring work happens here?
- **Stack** — Comma-separated list of primary tools/languages/services (e.g. "typescript, next.js, supabase, vercel").
- **Rules** (optional) — Any guardrails that only apply inside this workstation.

### 3. Substitute template

Source template: `${INSTANCE_HOME}/.framework-source/templates/workstation/CLAUDE.md.template`

Substitute placeholders:

- `{{WORKSTATION_NAME}}` → `<name>`
- `{{WORKSTATION_NAME_TITLE}}` → title-cased name (e.g. `web-dev` → `Web Dev`)
- `{{WORKSTATION_PURPOSE}}` → purpose from interview
- `{{INSTANCE_NAME}}` → from `system/identity.env`
- `{{INSTANCE_HOME}}` → resolved instance home

Write to: `${INSTANCE_HOME}/workstations/<name>/CLAUDE.md`

If a `.mcp.json.template` exists alongside the workstation template, copy it to `${INSTANCE_HOME}/workstations/<name>/.mcp.json` (or leave empty stub `{ "mcpServers": {} }`).

### 4. Create scoped directories

```bash
mkdir -p ${INSTANCE_HOME}/workstations/<name>/.claude/{agents,skills,commands}
```

Workstation-scoped agents/skills/commands live here and shadow instance-global ones when a session is opened inside the workstation.

### 5. Patch the workstation CLAUDE.md

Append a stack table and rules section based on interview answers.

### 6. Register

Append a row to `${INSTANCE_HOME}/system/registries/workstations.md` with:

```
| <name> | <purpose> | <created date> |
```

### 7. Confirm

Report:

```
Workstation initialized: <name>

Created:
- workstations/<name>/CLAUDE.md
- workstations/<name>/.mcp.json
- workstations/<name>/.claude/{agents,skills,commands}/

Next:
1. /mount <domain>/<project> <name>     # symlink an active project in
2. cd workstations/<name>/active-project && claude     # open session there
```

## Notes

- Do not pre-populate workstation-scoped skills/agents — only add when a real need emerges.
- The `active-project` symlink is created by `/mount`, not by this command.
- Workstations are recurring; if the work has a clear start and end, use `/init-project` instead.
