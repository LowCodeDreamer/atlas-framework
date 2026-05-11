# Agentic Framework — Bootstrap Prompt

Paste this into a Claude Code session to install the framework into a new environment.

---

## Bootstrap Prompt

```
I want to install the agentic-framework into this environment.

Steps to take:

1. Confirm the target path. Default suggestions:
   - On a VPS: /opt/<instance-name>
   - On a personal machine: ~/Documents/<instance-name>
   - On a team server: /srv/<instance-name>
   Ask me which to use.

2. Clone the framework if not already present:
   git clone https://git.eno.foundation/eno-foundation/agentic-framework.git /tmp/framework

3. Ask me three questions:
   - Instance name (short, kebab-case): e.g., eno, atlas, client-x
   - Identity/role: a short description of how the instance addresses the user
     e.g., "Eno operator", "Geoffrey personal assistant", "ACME operations agent"
   - Should hooks be registered immediately? (yes/no — yes is recommended for new installs)

4. Run the init script with my answers:
   bash /tmp/framework/scripts/instance-init.sh \
     --target <target-path> \
     --name <instance-name> \
     --role "<identity-role>" \
     --register-hooks <yes|no>

5. After init completes, show me:
   - The created directory tree (depth 2)
   - The cascade root CLAUDE.md
   - A "next steps" summary:
     a. cd <target-path> and open a Claude Code session
     b. Run /refresh-status to confirm framework is active
     c. Run /init-workstation <name> to create your first capability environment
     d. Run /init-project <domain>/<project> to start your first bounded work unit

6. Do NOT migrate any personal/existing content yet. The instance is empty by design;
   I'll fill it in as work begins.

7. Do NOT delete or modify any existing files in the target path that aren't part of
   the framework conventions. If the target path already has content (e.g., it's an
   existing VPS environment), confirm with me before any operation that would touch
   existing files.

Begin.
```

---

## When to use this

- Setting up a fresh VPS with the framework
- Adding the framework to a teammate's machine
- Layering the framework onto an existing environment (use `--existing-instance` flag)
- Creating a sandbox instance for testing

## What the bootstrap WON'T do

- Install Claude Code itself (assumed already present)
- Install the Claude Agent SDK (only needed if Hermes/autonomous agents will invoke Claude Code)
- Set up authentication (use `claude` interactively the first time)
- Migrate content from another instance (use `/init-project` and copy files manually as needed)
- Touch infrastructure layer files (`/root`, `/etc`, `/docker`)

## After bootstrap

The instance is empty. Fill it in by:

1. **Define your workstations.** `/init-workstation governance` (or whatever capability environment you need recurring)
2. **Define your first project.** `/init-project foundation/whitepaper-v1` (bounded work)
3. **Catalog your services.** If layering onto an existing environment with long-running app code, `/init-service nanoclaw` etc. (creates `services/<name>/_manifest.md`)
4. **Mount your first project.** `/mount foundation/whitepaper-v1 community` (symlinks project into a workstation's `active-project/`)
5. **Open a session there.** `cd workstations/community/active-project && claude`

## Updating

The framework evolves. Pull updates with:

```
bash <target-path>/scripts/instance-update.sh
```

This updates: `.claude/agents/`, `.claude/commands/`, `.claude/skills/`, `hooks/`, `scripts/`.
This does NOT touch: `projects/`, `workstations/`, `services/`, `expertise/`, `working/`, `system/`, your CLAUDE.md, your `_domain.md`, your `.mcp.json`.

If a framework update changes a primitive you've customized locally, the update script will warn you and skip that file (your local copy wins). You can review and merge manually.
