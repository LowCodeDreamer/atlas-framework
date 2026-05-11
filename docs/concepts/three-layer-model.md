# Three-layer model

The framework partitions a deployment into three layers with different responsibilities, lifetimes, and authority.

## Layers

```
┌─────────────────────────────────────────────────────────────┐
│ INFRA LAYER                                                  │
│ /root, /etc, /docker — host config, services, OS-level      │
│ Lifetime: persistent (years). Changes via system admin.      │
│ The framework does NOT manage this layer.                    │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │
┌─────────────────────────────────────────────────────────────┐
│ INSTANCE LAYER                                               │
│ /opt/<name> or ~/Documents/<name> — the framework conventions│
│ Lifetime: persistent (months/years). Changes via PRs/edits. │
│ This is what the framework manages.                          │
│ Cascade root CLAUDE.md, projects, workstations, services,    │
│ expertise, working, system, .claude, hooks, scripts          │
└─────────────────────────────────────────────────────────────┘
                              ▲
                              │
┌─────────────────────────────────────────────────────────────┐
│ WORK LAYER                                                   │
│ Claude Code sessions, Hermes runs, n8n workflows             │
│ Lifetime: transient (minutes/hours per invocation).          │
│ Multiple consumers can read the same instance simultaneously.│
└─────────────────────────────────────────────────────────────┘
```

## Why this matters

### Separation of concerns
Each layer has a different change cadence. Infra changes weekly at most. Instance changes daily. Work happens continuously. Conflating them creates surprise outages — e.g., an autonomous routine writing to a Caddy config file shouldn't be possible by construction.

### Multiple work consumers, one instance
The same instance layer can be consumed by Claude Code (interactive, human-driven) AND Hermes (autonomous, scheduled) AND n8n workflows AND cron jobs simultaneously. They all read the same skills, follow the same conventions, write to the same proposal queue. No translation layer between human-driven and autonomous work.

### Source of truth
Within the instance layer, the filesystem IS the source of truth. Git remote is for backup, history, and team contribution — not stricter canonicality. This works because all writers (humans, Claude Code, autonomous routines via /promote) end up at the same filesystem.

### Reversibility
Want to remove the framework? Delete the instance directory. Infra unaffected. Want to start fresh? `instance-init` to a new path. Existing instance untouched.

## Practical implications

- **Hooks are instance-scoped.** Each instance has its own `hooks/` and `.claude/settings.json`. Changes don't propagate to other instances on the same machine.
- **MCP configs are layered.** `~/.claude.json` for personal global; `<instance>/.mcp.json` for instance-wide; `workstations/<ws>/.mcp.json` for workstation-scoped.
- **Hermes runs in the work layer**, but reads the instance layer (e.g., `/opt/eno/system/proposals/` is where it writes).
- **No symlink between layers** unless explicit and documented. Keep the boundary visible.

## Anti-patterns

- **"Just edit `/etc/...` from inside Claude Code"** — that crosses from work layer to infra layer. Instead: write a proposal, review with `/promote`, manually apply infra change.
- **"Hermes writes directly to `expertise/`"** — that crosses from work layer to instance canonical state without review. Instead: Hermes writes to `system/proposals/`; human promotes.
- **"One CLAUDE.md at `/root`"** — confuses infra and instance. Keep instance-level CLAUDE.md inside the instance directory; infra-level guidance (if any) stays in `/root/CLAUDE.md` and addresses infra-only concerns.

## See also

- [`workstations-vs-projects-vs-services.md`](workstations-vs-projects-vs-services.md) — the three sibling concepts in the instance layer
- [`source-of-truth.md`](source-of-truth.md) — what canonical means and who can write to it
- [`hermes-bridge.md`](hermes-bridge.md) — how the autonomous plane reads the instance layer
