---
name: workspace-scaffold
description: Create folder structure and generate initial files for project workspaces. Reads manifest from analyzer, applies templates, creates domain file and README.
user-invocable: false
context: fork
agent: structure
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
---

# Workspace Scaffold

Create project workspace structure from manifest.

## Quick Reference

```
Input: SCAFFOLD_MANIFEST.json
Output: projects/{project}/ (complete structure)
```

## Core Workflow

### 1. Load Manifest

```bash
Read working/planning/{project}/SCAFFOLD_MANIFEST.json
```

Extract:
- `workspace.location` - where to create
- `structure.template` - which template to use
- `structure.directories` - folders to create
- `structure.files` - files to generate

### 2. Validate Location

```bash
# Check parent exists
ls workspaces/

# Check workspace doesn't exist (prevent overwrite)
if [ -d "projects/{project}" ]; then
  echo "Error: Workspace already exists"
  exit 1
fi
```

### 3. Create Directory Structure

```bash
# Create root
mkdir -p projects/{project}

# Create all directories from manifest
mkdir -p projects/{project}/src
mkdir -p projects/{project}/docs
mkdir -p projects/{project}/tests
# ... etc based on template
```

### 4. Generate Core Files

**_domain.md (Required)**

```markdown
---
id: workspace_{slug}
type: workspace
created_at: {ISO 8601}
name: {Project Name}
status: active
project_type: {type}
complexity: {complexity}
domains:
  - {domain1}
  - {domain2}
skills:
  - {skill1}
  - {skill2}
---

# {Project Name}

> {One-sentence description from plan}

## Context

{Brief summary of what this workspace is for}

## Quick Reference

| Key | Value |
|-----|-------|
| Type | {project_type} |
| Status | Active |
| Plan | [[PLAN]] |
| Created | {date} |

## Structure

{Describe folder layout}

## Getting Started

{Quick start instructions}

## Related

- [[PLAN|Project Plan]]
- [[../planning/{slug}/PROJECT_PLAN|Full Planning Doc]]
```

**README.md (Required)**

```markdown
# {Project Name}

{One-sentence description}

## Quick Start

1. {First step}
2. {Second step}
3. {Third step}

## Project Structure

\`\`\`
{project}/
├── _domain.md      # Workspace context
├── README.md       # This file
├── PLAN.md         # Link to planning doc
└── ...
\`\`\`

## Status

- [x] Planning complete
- [x] Workspace scaffolded
- [ ] {Next milestone}

## Resources

- [Project Plan](./PLAN.md)
- {Other links from plan}
```

**PLAN.md (Symlink or content)**

```markdown
---
type: reference
target: ../../working/planning/{slug}/PROJECT_PLAN.md
---

# Project Plan

See: [[../../working/planning/{slug}/PROJECT_PLAN|Full Project Plan]]

## Quick Summary

{Copy essential info from plan}

---

*This is a reference to the main planning document.*
```

### 5. Template-Based Generation

**Simple Coding Template:**
```
{project}/
├── _domain.md
├── README.md
├── PLAN.md
└── src/
    └── main.{ext}
```

**Moderate Coding Template:**
```
{project}/
├── _domain.md
├── README.md
├── PLAN.md
├── .mcp.json
├── src/
│   ├── main.{ext}
│   └── lib/
├── tests/
│   └── test_main.{ext}
└── docs/
    └── notes.md
```

**Complex Coding Template:**
```
{project}/
├── _domain.md
├── README.md
├── PLAN.md
├── .mcp.json
├── config/
│   ├── development.json
│   └── production.json
├── src/
│   ├── main.{ext}
│   ├── lib/
│   ├── services/
│   └── utils/
├── tests/
│   ├── unit/
│   └── integration/
├── docs/
│   ├── architecture.md
│   ├── api.md
│   └── guides/
└── scripts/
    └── setup.sh
```

**Research Template:**
```
{project}/
├── _domain.md
├── README.md
├── PLAN.md
├── notes/
│   └── .gitkeep
├── sources/
│   └── .gitkeep
└── output/
    └── .gitkeep
```

**Client Work Template:**
```
{project}/
├── _domain.md
├── README.md
├── PLAN.md
├── deliverables/
│   └── .gitkeep
├── correspondence/
│   └── .gitkeep
├── references/
│   └── .gitkeep
└── status/
    └── current.md
```

### 6. Apply Research Adaptations

If `RESEARCH_FINDINGS.md` has USE recommendations:

```bash
# Clone recommended skill
cp -r .claude/skills/{source-skill}/ .claude/skills/{new-skill}/

# Clone recommended template
cp {source-template} projects/{project}/{file}
```

Update paths and references for Atlas structure.

### 7. Configure MCP (if required)

Generate `.mcp.json` if MCPs listed:

```json
{
  "mcpServers": {
    "{mcp-name}": {
      "command": "npx",
      "args": ["-y", "@{mcp-package}"],
      "env": {
        "{ENV_VAR}": "${{{ENV_VAR}}}"
      }
    }
  }
}
```

### 8. Verify Creation

```bash
# Check all required files exist
for file in _domain.md README.md PLAN.md; do
  if [ ! -f "projects/{project}/$file" ]; then
    echo "Missing: $file"
  fi
done

# Check all directories exist
for dir in {directories}; do
  if [ ! -d "projects/{project}/$dir" ]; then
    echo "Missing: $dir"
  fi
done
```

### 9. Report Results

Return to orchestrator:
- Workspace location
- Files created (list)
- Directories created (list)
- MCP configuration status
- Any warnings or issues

## File Templates

### Domain File Template

See: `templates/workspace-domain.md`

### README Template

See: `templates/workspace-readme.md`

### MCP Config Template

See: `templates/mcp-config.json`

## Error Handling

| Issue | Action |
|-------|--------|
| Workspace exists | Error: Refuse to overwrite |
| Parent missing | Create parent directory |
| Template not found | Use default structure |
| File write fails | Log error, continue others |
| Permission denied | Report with fix suggestion |

## Extension Points

### Custom Templates

Add templates to `templates/`:
```
templates/
├── workspace-domain.md
├── workspace-readme.md
├── structures/
│   ├── simple-coding.yaml
│   ├── moderate-coding.yaml
│   └── complex-coding.yaml
└── file-types/
    ├── python/
    ├── typescript/
    └── rust/
```

### Language-Specific Setup

Based on `tech_stack.languages`:
- Python: Create `requirements.txt`, `pyproject.toml`
- TypeScript: Create `package.json`, `tsconfig.json`
- Rust: Create `Cargo.toml`

## Related

- [[.claude/skills/project-analyzer/SKILL|Project Analyzer]]
- [[.claude/skills/project-validator/SKILL|Project Validator]]
- [[.claude/commands/scaffold|/scaffold Command]]
