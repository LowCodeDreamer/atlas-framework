# /scaffold Command

Transform a planning document into a ready-to-work project workspace.

## Usage

```
/scaffold {project-name}
```

Where `{project-name}` matches a folder in `working/planning/`.

## What This Command Does

### 1. Analyze (Sequential)
- Parses PROJECT_PLAN.md
- Extracts requirements from YAML frontmatter
- Generates SCAFFOLD_MANIFEST.json
- Validates all dependencies exist

### 2. Research (Sequential, Optional)
- Searches for existing solutions
- Queries GitHub, MCP Registry, Atlas knowledge
- Scores findings by quality
- Generates RESEARCH_FINDINGS.md
- **User reviews findings before proceeding**

### 3. Build (Parallel)
- **Structure Agent:** Creates folders and files
- **Config Agent:** Sets up MCP configuration
- Both run simultaneously for speed

### 4. Validate (Sequential)
- Verifies all files created
- Tests MCP connections (if configured)
- Checks context loading setup
- Generates VALIDATION_REPORT.md

### 5. Report
- Shows workspace location
- Lists what was created
- Provides next steps

## Orchestration Flow

```
/scaffold project-name
        │
        ▼
┌─────────────────┐
│  Analyzer       │ Parse planning doc
│  (sequential)   │ Generate manifest
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Researcher     │ Find existing solutions
│  (sequential)   │ User reviews findings
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌───────┐
│ Struct│ │ Config│  Run in parallel
│ Agent │ │ Agent │  (backgrounded)
└───┬───┘ └───┬───┘
    └────┬────┘
         ▼
┌─────────────────┐
│  Validator      │ Verify everything
│  (sequential)   │ Generate report
└────────┬────────┘
         │
         ▼
    Workspace Ready!
```

## Prerequisites

Before running `/scaffold`:

1. Planning doc exists: `working/planning/{project}/PROJECT_PLAN.md`
2. Plan has valid YAML frontmatter
3. Plan status is `planning` or `ready`

## Examples

**Scaffold a simple API:**
```
/scaffold todo-api
```

**Scaffold a complex project:**
```
/scaffold enterprise-crm
```

## Output Structure

Creates project at `projects/{project}/`:

```
{project}/
├── _domain.md          # Workspace context
├── README.md           # Quick start guide
├── PLAN.md            # Link to planning doc
├── .mcp.json          # MCP config (if needed)
└── [project structure based on type/complexity]
```

## Research Review

When the researcher finds existing solutions:

```
Found 3 relevant solutions:

1. USE: anthropics/skills/docx (9/10)
   - Production-ready document handling
   - Effort: 1 hour to adapt

2. ADAPT: obra/superpowers/write-plan (7/10)
   - Good foundation for planning
   - Effort: 4 hours to integrate

3. BUILD: custom-validation (no match)
   - Novel requirement
   - Effort: 8 hours to build

Proceed with these recommendations? [Y/n]
```

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| "Planning doc not found" | No PROJECT_PLAN.md | Run `/plan-project` first |
| "Invalid YAML" | Frontmatter syntax error | Fix the YAML |
| "Workspace exists" | Already scaffolded | Delete or rename existing |
| "Missing dependency" | Required MCP/skill missing | Install the dependency |

## Generated Reports

After scaffolding, find these in `working/planning/{project}/`:

- `SCAFFOLD_MANIFEST.json` - Machine-readable requirements
- `RESEARCH_FINDINGS.md` - What existing solutions were found
- `VALIDATION_REPORT.md` - Verification of setup

## Post-Scaffold Steps

1. Navigate to project: `cd projects/{project}`
2. Review `_domain.md` for accuracy
3. Verify MCP connections (if applicable)
4. Start working!

## See Also

- [[.claude/commands/plan-project|/plan-project Command]]
- [[.claude/skills/project-analyzer/SKILL|Project Analyzer]]
- [[.claude/skills/project-researcher/SKILL|Project Researcher]]
- [[.claude/skills/workspace-scaffold/SKILL|Workspace Scaffold]]
- [[.claude/skills/project-validator/SKILL|Project Validator]]
