# Changelog

## v0.1.0 — 2026-05-11 (in progress)

Initial extraction from Atlas. Pre-1.0; breaking changes possible.

### Added
- Repo skeleton (`core/`, `templates/`, `scripts/`, `docs/`, `examples/`)
- `README.md`, `BOOTSTRAP.md`, `LICENSE` (AGPLv3), `VERSION`
- Meta-agents: `meta-agent`, `meta-command`, `meta-skill`, `meta-domain`, `meta-expertise`
- Utility agents: `file-organizer`, `git-ops`, `fact-checker`, `session-context-manager`
- Commands: `/equip`, `/init-project`, `/init-domain`, `/init-workstation`, `/init-service`, `/mount`, `/unmount`, `/workstations`, `/clear-workstations`, `/plan`, `/track`, `/work`, `/roadmap`, `/process-inbox`, `/factcheck`, `/strategy`, `/question`, `/sync`, `/git`, `/retro`, `/daily`, `/refresh-status`, `/self-improve`, `/validate`, `/promote`
- Skills: `self-scaffold`, `workspace-scaffold`, `project-{analyzer,planner,researcher,validator}`, `agent-orchestration`, `output-styles`, `hook-system`, `file-normalization`, `fact-checking`, `session-closure`, `strategy-session`, `mcp-server-installation`, `obsidian-{cli,bases,markdown}`, `json-canvas`, `defuddle`, `image-generation`, `claude-code-runner` (new), `proposal-pipeline` (new)
- Hooks: full set with content sanitized to templates
- Templates: `instance/`, `workstation/`, `project/`, `service/`
- Scripts: `instance-init.sh`, `instance-update.sh`, `mount.sh`, `unmount.sh`, `status.sh`, `clear.sh`, `inventory.py`
- Concept docs: three-layer model, workstations vs projects vs services, hermes bridge, source of truth

### Source
Extracted from Atlas (Derek Chapman's personal vault), May 2026. Original source: `~/Documents/Atlas/`.

Path-portability sweep: hardcoded `~/Documents/Atlas/` → `${INSTANCE_HOME}`; "Geoffrey", "Optevo", "NHP" content → `{{TEMPLATE_VAR}}` placeholders.
