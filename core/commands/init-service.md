---
description: Catalog a long-running service operated by this instance
argument-hint: "<name>"
id: command_init_service
type: command
created_at: 2026-05-14T22:00:00Z
---

# Init Service

Register a long-running service (daemon, web app, MCP server, scheduler) under `services/<name>/` with a `_manifest.md` so the instance knows how to operate it.

Use this command for code that runs continuously and is operated by this instance — NOT for bounded projects (use `/init-project`) or recurring work environments (use `/init-workstation`).

## Usage

```
/init-service <name>
```

## Workflow

### 1. Validate

- Parse `$ARGUMENTS` into `SERVICE_NAME` (kebab-case).
- If `${INSTANCE_HOME}/services/<name>/_manifest.md` already exists, abort with a pointer to the existing manifest.
- If `${INSTANCE_HOME}/services/<name>/` exists but no manifest, offer to layer the manifest onto the existing code (additive mode).

### 2. Detect existing code

```bash
ls -la ${INSTANCE_HOME}/services/<name>/ 2>/dev/null
```

If a directory already exists with code, set `SERVICE_STATUS=existing` and skip directory creation. Otherwise `SERVICE_STATUS=stub`.

### 3. Interview

Use AskUserQuestion to gather:

- **Purpose** — One sentence on what the service does.
- **Language / Runtime** — e.g. `node 20`, `python 3.12`, `bash`, `rust`.
- **Surface** — How does the rest of the instance talk to it? (`http :3000`, `mcp stdio`, `unix socket /run/<name>.sock`, `cron`, `systemd unit`).
- **Start / Stop / Logs / Health commands** — Best-known commands; `TBD` is fine.
- **Dependencies** — Other services, MCPs, env vars, secrets.

### 4. Scaffold

```bash
mkdir -p ${INSTANCE_HOME}/services/<name>
```

Substitute placeholders in `${INSTANCE_HOME}/.framework-source/templates/service/_manifest.md.template` and write to `${INSTANCE_HOME}/services/<name>/_manifest.md`.

Placeholders:

- `{{SERVICE_NAME}}`, `{{SERVICE_NAME_TITLE}}`, `{{SERVICE_PURPOSE}}`
- `{{SERVICE_STATUS}}` — `existing` or `stub`
- `{{SERVICE_LANGUAGE}}`, `{{SERVICE_RUNTIME}}`, `{{SERVICE_EXPOSES}}`
- `{{SERVICE_START_CMD}}`, `{{SERVICE_STOP_CMD}}`, `{{SERVICE_LOGS_CMD}}`, `{{SERVICE_HEALTH_CMD}}`
- `{{INSTANCE_NAME}}`, `{{INSTANCE_HOME}}`, `{{INIT_DATE}}`

### 5. Register

Append a row to `${INSTANCE_HOME}/system/registries/services.md`:

```
| <name> | <purpose> | <surface> | <status> | <created date> |
```

### 6. Confirm

```
Service cataloged: <name>

Created:
- services/<name>/_manifest.md

Status: <existing|stub>
Surface: <surface>

Next:
1. Review services/<name>/_manifest.md
2. If stub: scaffold the implementation
3. If existing: verify operations commands are correct
```

## Notes

- This command does NOT install dependencies, build, or start the service. It only catalogs it for the instance.
- For services that run as systemd units, the manifest should reference the unit file path under `Operations`.
- For MCP servers, also register in the instance `.mcp.json` so Claude Code can connect.
