# Workstations vs Projects vs Services

The instance layer has three sibling concepts. Don't conflate them.

## Quick reference

| | Projects | Workstations | Services |
|---|---|---|---|
| **Lifetime** | Bounded (start → end) | Persistent | Persistent (long-running) |
| **Has end state?** | Yes | No | No |
| **Mounted into?** | A workstation | — | — |
| **Has runtime?** | No | No | Yes (process, container, daemon) |
| **Examples** | Whitepaper v1, Form 1023 filing, Hardware rev 0.3 BOM | governance, agent-ops, knowledge-curation, content-publishing | nanoclaw, paperclip, mission-control, postgres |

## Projects

**A bounded unit of work with a clear start and end state.**

- Lives at `projects/<domain>/<project>/`
- Has `_manifest.md` (metadata + status) and `_domain.md` (project-specific knowledge)
- When complete: archive to `working/completed/` or leave in `projects/` with `phase: complete`
- One project = one deliverable, milestone, or initiative

Examples:
- `projects/foundation/form-1023-filing/`
- `projects/token/vesting-v1/`
- `projects/whitepaper/v0.4-revision/`

Bad project names (these are workstations or services, not projects):
- ❌ `projects/governance/` (too broad — that's a workstation)
- ❌ `projects/postgres/` (that's a service)

## Workstations

**A recurring capability environment that can have any project mounted into it.**

- Lives at `workstations/<name>/`
- Has `CLAUDE.md` (purpose + stack + rules + scoped skills)
- Has `.claude/{agents,skills,commands}/` for workstation-scoped components
- Has `.mcp.json` for workstation-scoped MCP servers
- Has `active-project/` (a symlink, set by `/mount`)

Workstations capture *how* you work in a domain, not *what* you're working on. The "what" is whichever project is currently mounted.

Examples:
- `workstations/governance/` — has skills like `legal-compliance-check`, `board-packet-builder`
- `workstations/agent-ops/` — has skills for operating the agent fleet
- `workstations/content-publishing/` — has skills for whitepaper, blog, social

When a project needs governance work, mount it in `governance`. When it needs publishing, mount it in `content-publishing`. Same project, different workstation, different scoped capabilities.

Bad workstation names:
- ❌ `workstations/whitepaper-v1/` (that's a project)
- ❌ `workstations/postgres-admin/` (services have their own CLAUDE.md; you don't need a workstation for ops on a single service)

## Services

**Long-running app code or infrastructure this instance operates.**

- Lives at `services/<name>/` (often a symlink to existing code at another path)
- Has `_manifest.md` documenting: ports, container/systemd unit, owner, dependencies, backups, on-call
- Has `CLAUDE.md` with operational guidance
- The actual code lives wherever it lives; the framework cataloging is the manifest

Services are **operated** by workstations. E.g., `agent-ops` workstation has skills for managing the `nanoclaw`, `paperclip`, `mission-control` services. The services themselves don't have skills; they have manifests + ops docs.

Examples:
- `services/nanoclaw/` (symlink to `/opt/eno/nanoclaw/` where the actual Node code lives)
- `services/paperclip/`
- `services/postgres/` (the database itself, with backup procedures)
- `services/n8n/`

Bad service definitions:
- ❌ `services/foundation/` (that's a domain, not a service)
- ❌ `services/board-packet-builder/` (that's a skill, not a service)

## When to choose which

You're starting new work. Ask:

1. **Does this have a deliverable that ends?** → project
2. **Is this a recurring capability environment?** → workstation
3. **Is this a long-running process or system I operate?** → service

Most "I want to organize this" cases are projects. Workstations are added when you find yourself repeating the same setup. Services are added when you actually have a runtime to manage.

## Cross-reference

A project can mention services it depends on:
```yaml
# projects/foundation/form-1023-filing/_manifest.md
services_used:
  - vaultwarden  # for storing IRS account credentials
  - postgres     # for status tracking
```

A workstation can declare services it manages:
```markdown
# workstations/agent-ops/CLAUDE.md
## Services operated
- services/nanoclaw
- services/paperclip
- services/mission-control
- services/openclaw
```

A service can declare workstations that operate it:
```yaml
# services/nanoclaw/_manifest.md
operated_by:
  - workstations/agent-ops
```

These cross-references aren't enforced by the framework; they're convention. Keep them honest because they're useful for navigation and for /equip's gap analysis.
