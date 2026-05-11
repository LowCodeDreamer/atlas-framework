---
name: project-planner
description: Create comprehensive PROJECT_PLAN.md through adaptive interview. Use when starting new projects, especially with attached documents. Extracts from docs first, asks only for gaps.
user-invocable: true
context: inline
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - AskUserQuestion
  - Task
---

# Project Planner

Create structured planning documents through adaptive interview.

## Quick Reference

```
Trigger: /plan-project [description or attach docs]
Output: working/planning/{project-name}/PROJECT_PLAN.md
```

## Core Workflow

### 1. Initialize

```bash
# Create planning folder
mkdir -p working/planning/{project-slug}/
```

Derive project slug from description (lowercase, dashes, max 40 chars).

### 2. Analyze Input

**If documents attached:**
1. Read all attached documents
2. Extract: goals, requirements, tech stack, constraints, timeline
3. Build initial project profile from docs
4. Only ask questions for MISSING information

**If description only:**
1. Parse description for keywords
2. Infer project type (coding, research, client, content)
3. Run minimal interview for essentials

### 3. Adaptive Interview

Ask ONLY what's missing. Group questions when possible.

**Phase 1: Essential (always ask if unknown)**
- Project name (validate slug-friendly)
- Project type (coding | research | client_work | content | mixed)
- Primary goal in one sentence
- Success criteria (how we know it's done)

**Phase 2: Scope (ask if complex/unclear)**
- Key deliverables
- What's explicitly out of scope
- Timeline/deadline
- Dependencies

**Phase 3: Technical (coding projects only)**
- Primary language/framework
- Database requirements
- External services/APIs
- Hosting/deployment

**Phase 4: Tools (ask if integration-heavy)**
- Required MCP servers
- Required skills
- External integrations (ClickUp, GitHub, etc.)

### 4. Complexity Assessment

Score 1-5 based on:

| Factor | Low (1) | Medium (3) | High (5) |
|--------|---------|------------|----------|
| File count | <10 | 10-50 | >50 |
| Integrations | 0-1 | 2-3 | 4+ |
| Team size | Solo | 2-3 | 4+ |
| Dependencies | None | Few | Many |
| Novelty | Familiar | Some new | All new |

**Complexity mapping:**
- Score 1-7: `simple`
- Score 8-14: `moderate`
- Score 15+: `complex`

### 5. Generate Planning Document

Use template at `templates/planning/PROJECT_PLAN_TEMPLATE.md`

Fill YAML frontmatter from interview:

```yaml
---
id: project_{slug}
type: project_plan
created_at: {ISO 8601}
updated_at: {ISO 8601}
version: 1.0.0
status: planning

project_type: {type}
project_scale: {small|medium|large}
complexity: {simple|moderate|complex}

scaffold:
  workspace_location: projects/{slug}
  create_git_repo: false

agents:
  analysis: {enabled: true, agent_type: analyzer, context: fork}
  structure: {enabled: true, agent_type: structure, context: fork, background: true}
  validation: {enabled: true, agent_type: validator, context: fork}

domains:
  required: [{derived from tech stack}]

mcps:
  required: [{from interview}]
  optional: [{suggestions}]

skills:
  primary: [{from interview}]

tech_stack:
  languages: [{from interview}]
  frameworks: [{from interview}]
  databases: [{from interview}]

context:
  priority: {hybrid|optimized|minimal}
  max_files: {10|50|100 based on complexity}

validation:
  required_files: [README.md, _domain.md, PLAN.md]
  test_mcp_connections: true
---
```

Fill markdown sections with interview responses. Mark unknown sections as `[TBD]`.

### 6. Save and Report

1. Write to `working/planning/{slug}/PROJECT_PLAN.md`
2. Report success with next steps:
   - "Review the plan, edit if needed"
   - "When ready: `/scaffold {slug}`"

## Interview Patterns

### Smart Extraction

When docs provided, look for:
- **Goals/Objectives:** Sections titled "Goals", "Objectives", "Purpose"
- **Requirements:** Numbered lists, "must have", "should have"
- **Tech Stack:** Technology names, framework mentions, language references
- **Timeline:** Dates, deadlines, phases, milestones
- **Constraints:** "Cannot", "must not", budget mentions

### Question Grouping

Don't ask one question at a time. Group related questions:

```
**Project Basics**
1. Name: [what should we call this project?]
2. Type: [coding | research | client | content]
3. One-sentence goal: [what does success look like?]
```

### Skip Logic

- If `project_type = research` → skip all tech stack questions
- If `project_type = content` → skip database, API questions
- If docs mention specific tech → don't ask about tech stack
- If timeline in docs → don't ask about deadline

## Validation

Before saving, verify:
- [ ] Project name is slug-friendly
- [ ] At least one success criterion
- [ ] Project type selected
- [ ] Complexity assessed
- [ ] YAML frontmatter is valid

## Error Handling

| Issue | Action |
|-------|--------|
| Invalid project name | Suggest slug-friendly alternative |
| Missing required field | Ask specifically for that field |
| Conflicting info | Ask user to clarify |
| Template not found | Generate from embedded spec |

## Related

- [[templates/planning/PROJECT_PLAN_TEMPLATE|Planning Template]]
- [[.claude/skills/project-analyzer/SKILL|Project Analyzer]]
- [[.claude/commands/plan-project|/plan-project Command]]
