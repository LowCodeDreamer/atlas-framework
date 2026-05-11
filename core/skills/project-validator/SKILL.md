---
name: project-validator
description: Verify workspace setup is complete and correct. Checks file structure, MCP configurations, context loading, and generates readiness report.
user-invocable: false
context: fork
agent: validator
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

# Project Validator

Verify scaffolded workspace is ready to use.

## Quick Reference

```
Input: projects/{project}/, SCAFFOLD_MANIFEST.json
Output: working/planning/{project}/VALIDATION_REPORT.md
```

## Core Workflow

### 1. Load Validation Requirements

From manifest:
```json
{
  "validation": {
    "required_files": ["README.md", "_domain.md", "PLAN.md"],
    "required_mcps": ["github"],
    "test_mcp_connections": true
  }
}
```

### 2. Structure Validation

**Check Required Files:**

```bash
for file in README.md _domain.md PLAN.md; do
  if [ -f "projects/{project}/$file" ]; then
    echo "PASS: $file exists"
  else
    echo "FAIL: $file missing"
  fi
done
```

**Check Required Directories:**

```bash
for dir in {expected_dirs}; do
  if [ -d "projects/{project}/$dir" ]; then
    echo "PASS: $dir/ exists"
  else
    echo "FAIL: $dir/ missing"
  fi
done
```

**Check File Contents:**

```python
# Validate _domain.md has required frontmatter
required_fields = ['id', 'type', 'name', 'status']
for field in required_fields:
    if field not in frontmatter:
        errors.append(f"_domain.md missing: {field}")

# Validate README has content
if len(readme_content) < 100:
    warnings.append("README.md seems minimal")

# Validate PLAN.md links correctly
if 'PROJECT_PLAN' not in plan_content:
    errors.append("PLAN.md doesn't link to planning doc")
```

### 3. MCP Validation

**Check Configuration Exists:**

```bash
if [ -f "projects/{project}/.mcp.json" ]; then
  echo "PASS: .mcp.json exists"
  # Validate JSON syntax
  python3 -c "import json; json.load(open('projects/{project}/.mcp.json'))"
else
  if [ required_mcps ]; then
    echo "FAIL: .mcp.json missing but MCPs required"
  fi
fi
```

**Test MCP Connections (if enabled):**

```python
# For each configured MCP
for mcp_name, mcp_config in config['mcpServers'].items():
    try:
        # Try to start the server
        # Check for response
        results[mcp_name] = "connected"
    except Exception as e:
        results[mcp_name] = f"failed: {e}"
```

### 4. Context Validation

**Check Context Loading:**

```bash
# Verify auto-include files exist
for file in _domain.md PLAN.md; do
  if [ ! -f "projects/{project}/$file" ]; then
    echo "WARN: Auto-include file missing: $file"
  fi
done

# Check file count doesn't exceed max
file_count=$(find projects/{project} -type f | wc -l)
if [ $file_count -gt {max_files} ]; then
  echo "WARN: File count ($file_count) exceeds max ({max_files})"
fi
```

**Verify Exclude Patterns:**

```bash
# Check .gitignore or context exclude
if [ -f "projects/{project}/.gitignore" ]; then
  echo "PASS: .gitignore exists"
fi
```

### 5. Integration Validation

**Git Repository (if configured):**

```bash
if [ scaffold.create_git_repo = true ]; then
  if [ -d "projects/{project}/.git" ]; then
    echo "PASS: Git repo initialized"
  else
    echo "FAIL: Git repo not initialized"
  fi
fi
```

**External Links:**

```bash
# Check URLs in plan are valid (basic)
grep -o 'http[s]*://[^)]*' projects/{project}/PLAN.md | while read url; do
  echo "Found URL: $url"
done
```

### 6. Generate Validation Report

```markdown
# Validation Report: {Project Name}

**Validated:** {timestamp}
**Status:** {PASS | FAIL | WARNINGS}

## Summary

| Category | Result | Issues |
|----------|--------|--------|
| Structure | {PASS/FAIL} | {count} |
| MCP Config | {PASS/FAIL/SKIP} | {count} |
| Context | {PASS/WARN} | {count} |
| Integration | {PASS/FAIL/SKIP} | {count} |

## Detailed Results

### Structure Validation

| Check | Result | Details |
|-------|--------|---------|
| _domain.md exists | {PASS} | |
| README.md exists | {PASS} | |
| PLAN.md exists | {PASS} | |
| src/ directory | {PASS} | |
| _domain.md fields | {PASS} | All required fields present |

### MCP Configuration

| MCP | Config | Connection |
|-----|--------|------------|
| github | {PASS} | {PASS/FAIL/SKIP} |
| supabase | {PASS} | {PASS/FAIL/SKIP} |

### Context Setup

| Check | Result | Details |
|-------|--------|---------|
| Auto-include files | {PASS} | {count} files |
| File count | {PASS} | {n} of {max} max |
| Exclude patterns | {PASS} | .gitignore present |

### Integration

| Check | Result | Details |
|-------|--------|---------|
| Git repo | {PASS/SKIP} | {status} |
| External links | {PASS} | {count} URLs |

## Issues Found

### Errors (blocking)
{list of errors, empty if none}

### Warnings (non-blocking)
{list of warnings, empty if none}

## Readiness Status

**{READY | NOT READY}**

{If ready}
The workspace is ready to use. Next steps:
1. `cd projects/{project}`
2. Review _domain.md
3. Start working!

{If not ready}
The following issues must be resolved:
1. {issue 1}
2. {issue 2}

## Workspace Location

`projects/{project}/`

## Files Created

| File | Status |
|------|--------|
| _domain.md | Created |
| README.md | Created |
| PLAN.md | Created |
| .mcp.json | Created |
```

### 7. Return Results

Report to orchestrator:
- Overall status (READY / NOT READY)
- Error count
- Warning count
- Validation report location
- Specific blockers if not ready

## Validation Checks Reference

### Required Checks (Blocking)

| Check | Criteria |
|-------|----------|
| _domain.md | File exists, valid YAML frontmatter |
| README.md | File exists, has content |
| PLAN.md | File exists, links to planning doc |
| Required dirs | All manifest directories exist |
| MCP config | Valid JSON if MCPs required |

### Optional Checks (Warnings)

| Check | Criteria |
|-------|----------|
| File count | Under max_files limit |
| MCP connection | Can connect to configured MCPs |
| .gitignore | Present for context exclusion |
| Links valid | URLs in docs are reachable |

### Skip Conditions

| Check | Skip When |
|-------|-----------|
| Git validation | `create_git_repo: false` |
| MCP connection | `test_mcp_connections: false` |
| Integration | No integrations configured |

## Error Messages

| Code | Message | Resolution |
|------|---------|------------|
| E001 | Required file missing | Create the file |
| E002 | Invalid YAML frontmatter | Fix YAML syntax |
| E003 | MCP config invalid | Fix JSON syntax |
| E004 | Required directory missing | Create directory |
| W001 | File count exceeds max | Consider context strategy |
| W002 | MCP connection failed | Check credentials/config |
| W003 | .gitignore missing | Add for context exclusion |

## Related

- [[.claude/skills/workspace-scaffold/SKILL|Workspace Scaffold]]
- [[.claude/commands/scaffold|/scaffold Command]]
