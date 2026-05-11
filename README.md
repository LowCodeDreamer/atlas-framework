# Agentic Framework

A portable meta-framework for building self-improving, self-scaffolding agentic infrastructure on top of [Claude Code](https://claude.ai/code).

## What this is

A set of conventions, meta-agents, commands, skills, and hooks that you install into any environment (personal vault, VPS, team workspace) to get:

- **Cascading CLAUDE.md** — context loads from global → instance → workstation → project layers
- **Workstations / projects / services** — clean three-way split for capability environments, bounded work, and long-running app code
- **Self-scaffolding** — `/equip` analyzes capability gaps and builds the missing skills/agents/commands/hooks on demand
- **Meta-agents** — agents that build new agents, commands, skills, and domain-expert structures
- **Mount/unmount** — symlink any project into any workstation; switch contexts without losing state
- **Markdown source-of-truth** — everything is plain markdown with YAML frontmatter; readable, diff-able, version-controllable
- **Hook-driven validation** — schema validators, file protection, context injection, session logging fire automatically
- **Proposal pipeline** — autonomous routines write to `system/proposals/`; humans review and `/promote` to canonical

## What this is NOT

- A runtime — Claude Code is the runtime; this is the convention layer it operates inside
- A SaaS — fully self-hosted; you own everything
- An autonomous agent — pairs with autonomous agents (Hermes, n8n, OpenClaw) but is itself the substrate
- Personal content — zero opinions about your work; you fill in the workstations, projects, services

## Three-layer model

```
INFRA LAYER         your /root, /etc, /docker, system services
                    (the framework doesn't touch this)

INSTANCE LAYER      /opt/<name>/ or ~/Documents/<name>/
                    cascade root, framework conventions land here
                    (this is what the framework manages)

WORK LAYER          Claude Code sessions, autonomous agent runs
                    (transient; consumes the instance layer)
```

The same instance can be consumed by multiple work-layer agents — Claude Code (interactive, human-driven) and Hermes/n8n/cron (autonomous) read the same filesystem and the same skills.

## Install

```bash
# Clone
git clone https://git.eno.foundation/eno-foundation/agentic-framework.git /tmp/framework

# Bootstrap a new instance
bash /tmp/framework/scripts/instance-init.sh /opt/myproject

# Open a Claude Code session at the new instance
cd /opt/myproject && claude
```

You'll be prompted for:
- Instance name (e.g., `eno`, `atlas`, `client-x`)
- Identity/role (e.g., `Eno operator`, `Geoffrey personal assistant`)
- Whether to register hooks immediately

After init, verify:
- `/help` lists framework commands (`/equip`, `/init-project`, `/mount`, `/promote`, ...)
- `/refresh-status` generates `SYSTEM-STATUS.md`
- `/equip "test capability"` enters the gap-analysis flow

## Update

```bash
bash /opt/myproject/scripts/instance-update.sh
```

Pulls framework updates without touching your content. Your projects, workstations, services, expertise, and working directories are untouched.

## Layout after install

```
/opt/myproject/
├── CLAUDE.md                     # cascade root
├── _domain.md
├── .claude/                      # framework agents, commands, skills (updated by instance-update)
├── .claude-plugin/               # marketplace pointer
├── .mcp.json                     # MCP defaults
├── hooks/                        # framework hooks (updated by instance-update)
├── projects/                     # bounded work units
├── workstations/                 # capability environments
├── services/                     # long-running app code
├── expertise/                    # curated knowledge
├── working/                      # inbox, plans, active, archive
├── system/                       # proposals, toggles, registries
└── scripts/                      # mount, unmount, status, inventory
```

## Reference instances

- [`examples/personal-vault/`](examples/personal-vault/) — personal knowledge vault pattern (sanitized from Atlas)
- [`examples/vps-instance/`](examples/vps-instance/) — VPS instance pattern (sanitized from Eno)

## Documentation

- [`docs/concepts/`](docs/concepts/) — three-layer model, workstations vs projects vs services, source-of-truth, Hermes bridge
- [`docs/installation/`](docs/installation/) — new instance, layering onto existing environment
- [`docs/primitives/`](docs/primitives/) — one doc per primitive type

## License

AGPLv3 — see [LICENSE](LICENSE). If you operate this framework as a service for others, you must share modifications.

## Status

`v0.1.0` — pre-1.0; breaking changes possible in minor versions. See [CHANGELOG.md](CHANGELOG.md).
