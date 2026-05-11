---
name: project-analyzer
description: Parse PROJECT_PLAN.md and extract structured requirements for scaffolding. Generates manifest for orchestrating sub-agents. Use after planning, before scaffolding.
user-invocable: false
context: fork
agent: analyzer
allowed-tools:
  - Read
  - Write
  - Glob
---

# Project Analyzer

Parse planning documents and generate scaffolding manifests.

## Quick Reference

```
Input: working/planning/{project}/PROJECT_PLAN.md
Output: working/planning/{project}/SCAFFOLD_MANIFEST.json
```

## Core Workflow

### 1. Load Planning Document

```bash
Read working/planning/{project-slug}/PROJECT_PLAN.md
```

### 2. Parse YAML Frontmatter

Extract all frontmatter fields:

```yaml
project_type: coding
project_scale: medium
complexity: moderate
scaffold:
  workspace_location: projects/{slug}
  create_git_repo: false
agents: {...}
domains: {...}
mcps: {...}
skills: {...}
tech_stack: {...}
context: {...}
validation: {...}
```

### 3. Validate Frontmatter

Check required fields present:
- [ ] `id` - project identifier
- [ ] `project_type` - one of: coding, research, client_work, content, mixed
- [ ] `complexity` - one of: simple, moderate, complex
- [ ] `scaffold.workspace_location` - valid path

Report missing/invalid fields.

### 4. Derive Requirements

**From project_type:**

| Type | Implications |
|------|--------------|
| coding | Full tech structure, MCPs likely, tests expected |
| research | Minimal structure, docs focus, no MCPs typically |
| client_work | Full docs, delivery artifacts, status tracking |
| content | Docs only, minimal code structure |
| mixed | Combine as appropriate |

**From complexity:**

| Complexity | Agent Strategy |
|------------|----------------|
| simple | Sequential, no backgrounding |
| moderate | Parallel structure + config |
| complex | Full parallel, all agents |

### 5. Map Dependencies

**Domains:**
Check each listed domain exists in `expertise/domains/`:
```bash
ls expertise/domains/{domain-name}/
```

**MCPs:**
Check each MCP is known:
```bash
# Validate against known MCPs
# github, clickup, supabase, slack, n8n, etc.
```

**Skills:**
Check each skill exists:
```bash
ls .claude/skills/{skill-name}/SKILL.md
```

Report any missing dependencies.

### 6. Generate Scaffold Manifest

Create JSON manifest for orchestration:

```json
{
  "project": {
    "id": "project_{slug}",
    "name": "{Project Name}",
    "type": "{project_type}",
    "complexity": "{complexity}"
  },
  "workspace": {
    "location": "projects/{slug}",
    "create_git": false
  },
  "structure": {
    "template": "{simple|moderate|complex}",
    "directories": [
      "docs",
      "src",
      "tests"
    ],
    "files": [
      {"path": "_domain.md", "template": "domain"},
      {"path": "README.md", "template": "readme"},
      {"path": "PLAN.md", "type": "link", "target": "../../working/planning/{slug}/PROJECT_PLAN.md"}
    ]
  },
  "agents": {
    "pipeline": [
      {"agent": "structure", "background": true, "depends_on": []},
      {"agent": "config", "background": true, "depends_on": []},
      {"agent": "validation", "background": false, "depends_on": ["structure", "config"]}
    ]
  },
  "dependencies": {
    "domains": {
      "required": ["backend", "api-design"],
      "status": {"backend": "found", "api-design": "found"}
    },
    "mcps": {
      "required": ["github"],
      "status": {"github": "available"}
    },
    "skills": {
      "required": ["supabase-queries"],
      "status": {"supabase-queries": "found"}
    }
  },
  "context": {
    "strategy": "hybrid",
    "max_files": 50,
    "auto_include": ["_domain.md", "PLAN.md"],
    "exclude": ["node_modules/**", ".git/**"]
  },
  "validation": {
    "required_files": ["README.md", "_domain.md", "PLAN.md"],
    "test_mcps": true
  },
  "ready": true,
  "issues": []
}
```

### 7. Check Readiness

Manifest is ready if:
- [ ] All required fields present
- [ ] All required domains exist
- [ ] All required MCPs available
- [ ] All required skills exist
- [ ] No blocking issues

If not ready, populate `issues` array with blockers.

### 8. Save Manifest

```bash
Write working/planning/{slug}/SCAFFOLD_MANIFEST.json
```

## Template Mapping

### Structure Templates

Based on `project_type` and `complexity`:

**simple-coding:**
```
{project}/
├── _domain.md
├── README.md
├── PLAN.md → ../planning/{slug}/PROJECT_PLAN.md
└── src/
    └── main.{ext}
```

**moderate-coding:**
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
└── docs/
```

**complex-coding:**
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
│   └── services/
├── tests/
│   ├── unit/
│   └── integration/
├── docs/
│   ├── architecture.md
│   └── api.md
└── scripts/
```

**research:**
```
{project}/
├── _domain.md
├── README.md
├── PLAN.md
├── notes/
├── sources/
└── output/
```

### Context Strategy

Based on `complexity`:

| Complexity | Strategy | Max Files | Tier 1 |
|------------|----------|-----------|--------|
| simple | minimal | 10 | _domain.md, PLAN.md |
| moderate | hybrid | 50 | _domain.md, PLAN.md, README.md |
| complex | comprehensive | 100 | All core files |

## Error Handling

| Issue | Action |
|-------|--------|
| Plan file not found | Error: "Planning doc not found at {path}" |
| Invalid YAML | Error: "YAML parse error: {details}" |
| Missing domain | Warning: "Domain {name} not found" |
| Missing MCP | Warning: "MCP {name} not configured" |
| Missing skill | Warning: "Skill {name} not found" |

## Output

Return to orchestrator:
1. `SCAFFOLD_MANIFEST.json` location
2. Readiness status (ready/blocked)
3. List of issues if any
4. Suggested user actions if blocked

## Related

- [[.claude/skills/project-planner/SKILL|Project Planner]]
- [[.claude/skills/workspace-scaffold/SKILL|Workspace Scaffold]]
- [[.claude/commands/scaffold|/scaffold Command]]
