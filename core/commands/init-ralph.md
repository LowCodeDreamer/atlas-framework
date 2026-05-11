# /init-ralph

Deploy Ralph autonomous building capability to the current project.

## Description

Scaffolds Ralph Wiggum commands and structure into the current project directory, enabling autonomous code generation via the Ralph loop technique.

## What This Does

1. Creates `.claude/commands/` in the project (if not exists)
2. Copies `ralph-specs.md`, `ralph-plan.md`, `ralph-build.md` commands
3. Creates `specs/` directory structure
4. Detects project type and customizes guidance
5. Verifies Ralph plugin is available

## Prerequisites

Ralph plugin must be installed at user level. Check `~/.claude/settings.json`:
```json
{
  "plugins": ["anthropics/claude-code/plugins/ralph-wiggum"]
}
```

## Workflow

### Step 1: Validate Location
Ensure we're in a project directory, not Atlas itself.

### Step 2: Detect Project Type
Look for signals:
- `package.json` with express/fastify → API
- `package.json` with react/next → Fullstack
- `requirements.txt` with fastapi/flask → API
- `go.mod` → API
- Default to generic if unclear

### Step 3: Create Structure
```
{project}/
├── .claude/
│   └── commands/
│       ├── ralph-specs.md
│       ├── ralph-plan.md
│       └── ralph-build.md
└── specs/
    └── .gitkeep
```

### Step 4: Report
Output what was created and next steps.

## Allowed Tools

- Bash (mkdir, cp)
- Read (package.json, requirements.txt, go.mod for detection)
- Write (command files)
- Glob (check existing structure)

## Output

After running, report:
```
✅ Ralph deployed to {project}

Created:
  .claude/commands/ralph-specs.md
  .claude/commands/ralph-plan.md
  .claude/commands/ralph-build.md
  specs/

Detected: {project-type} project

Next steps:
  1. Start fresh Claude session: claude
  2. Generate specs: /ralph-specs
  3. Generate plan: /ralph-plan
  4. Build autonomously: /ralph-build
```

## Usage

```bash
cd ~/workspaces/my-project
/init-ralph
```

## Idempotent

Safe to run multiple times. Will update existing files if templates have changed.

---

## Implementation Instructions

When this command is invoked:

1. **Get current directory:**
   ```bash
   pwd
   ```

2. **Validate not in Atlas:**
   If path contains `/${INSTANCE_HOME}`, warn and ask for confirmation.

3. **Detect project type:**
   - Read `package.json` if exists → check dependencies
   - Read `requirements.txt` if exists → check packages
   - Read `go.mod` if exists → assume API
   - Default: "generic"

4. **Create directories:**
   ```bash
   mkdir -p .claude/commands
   mkdir -p specs
   ```

5. **Read templates from Atlas:**
   Read files from:
   - `${INSTANCE_HOME}/.claude/skills/ralph-capability/templates/commands/ralph-specs.md`
   - `${INSTANCE_HOME}/.claude/skills/ralph-capability/templates/commands/ralph-plan.md`
   - `${INSTANCE_HOME}/.claude/skills/ralph-capability/templates/commands/ralph-build.md`

6. **Write commands to project:**
   Write to:
   - `.claude/commands/ralph-specs.md`
   - `.claude/commands/ralph-plan.md`
   - `.claude/commands/ralph-build.md`

7. **Add project-type guidance:**
   If API or fullstack detected, append relevant guidance from project-types templates.

8. **Create specs placeholder:**
   ```bash
   touch specs/.gitkeep
   ```

9. **Report success with next steps.**
