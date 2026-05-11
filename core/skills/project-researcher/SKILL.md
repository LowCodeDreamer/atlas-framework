---
name: project-researcher
description: Search for existing solutions before building new. Queries GitHub skills repos, MCP registry, and Atlas knowledge. Returns quality-scored findings with adapt vs build recommendations.
user-invocable: false
context: fork
agent: researcher
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - Task
---

# Project Researcher

Find existing solutions before reinventing the wheel.

## Quick Reference

```
Input: SCAFFOLD_MANIFEST.json (project requirements)
Output: working/planning/{project}/RESEARCH_FINDINGS.md
```

## Core Workflow

### 1. Load Requirements

Read manifest to understand what to search for:
- Project type (coding, research, etc.)
- Tech stack (languages, frameworks)
- Required MCPs
- Required skills
- Domain expertise needed

### 2. Search Strategy

Search in priority order:

**Tier 1: Official Sources (highest trust)**
- Anthropic skills: `github.com/anthropics/skills`
- MCP Registry: `registry.modelcontextprotocol.io`
- Claude Code docs: `code.claude.com/docs`

**Tier 2: Community Vetted**
- obra/superpowers: `github.com/obra/superpowers`
- awesome-claude-skills collections
- High-star community repos

**Tier 3: Atlas Knowledge**
- Past similar projects: `projects/*/`
- Expertise files: `expertise/**/*.md`
- Knowledge archive: `knowledge/*.md`

### 3. Search Execution

For each requirement, search relevant sources:

**Skills Search:**
```
Query: "{skill-name} OR {alternative-terms} site:github.com claude skills"
Targets: anthropics/skills, awesome-claude-skills lists
```

**MCP Search:**
```
Query: "{mcp-name} MCP server"
Targets: MCP Registry API, modelcontextprotocol/servers
```

**Pattern Search:**
```
Query: "{project-type} {tech-stack} pattern example"
Targets: GitHub, Claude Code docs
```

**Atlas Search:**
```
Glob: projects/*/_domain.md (check project types)
Grep: expertise/**/*.md for {domain} patterns
```

### 4. Quality Scoring

Score each finding 0-10:

| Factor | Points | Criteria |
|--------|--------|----------|
| Recency | 0-3 | <6mo=3, <12mo=2, <24mo=1, older=0 |
| Popularity | 0-2 | >1000 stars=2, >100=1, <100=0 |
| Maintenance | 0-2 | Commits <30d=2, <90d=1, older=0 |
| Documentation | 0-2 | Comprehensive=2, basic=1, none=0 |
| Tests | 0-1 | Present and passing=1, none=0 |

**Thresholds:**
- 8-10: Use directly or with minor changes
- 5-7: Adapt significantly
- <5: Reference only, likely build from scratch

### 5. Adaptation Analysis

For each high-scoring finding:

**Compatibility Check:**
- Same language/framework? (required for code)
- Same MCP protocol version? (for MCPs)
- Compatible license? (MIT/Apache preferred)
- Atlas integration feasible?

**Effort Estimation:**
- Direct use: 0-1 hours
- Minor adaptation: 1-4 hours
- Significant adaptation: 4-8 hours
- Reference only: Full build time

### 6. Generate Recommendations

**Recommendation Categories:**

`USE`: Score 8+, compatible, tested
```
USE: anthropics/skills/docx
- Score: 9/10
- Effort: 1 hour (configure for Atlas)
- Why: Production-ready, official, well-tested
```

`ADAPT`: Score 5-7, needs modification
```
ADAPT: obra/superpowers/write-plan
- Score: 7/10
- Effort: 4 hours (merge with Atlas patterns)
- Why: Good foundation, needs Atlas integration
```

`REFERENCE`: Score <5, patterns useful
```
REFERENCE: random-repo/project-setup
- Score: 4/10
- Effort: N/A (don't use code)
- Why: Interesting patterns, but outdated/unmaintained
```

`BUILD`: No good match found
```
BUILD: custom-integration-skill
- Score: N/A (nothing found)
- Effort: 8-12 hours
- Why: Novel requirement, no existing solutions
```

### 7. Generate Report

Write `RESEARCH_FINDINGS.md`:

```markdown
# Research Findings: {Project Name}

**Research Date:** {date}
**Requirements Analyzed:** {count}
**Findings:** {count} relevant, {count} recommended

## Summary

| Requirement | Recommendation | Source | Score | Effort |
|-------------|----------------|--------|-------|--------|
| {item} | USE/ADAPT/BUILD | {source} | {n}/10 | {hours} |

## Detailed Findings

### {Requirement 1}

**Recommendation:** USE

**Source:** https://github.com/anthropics/skills/tree/main/docx

**Score:** 9/10
- Recency: 3/3 (updated last month)
- Popularity: 2/2 (official Anthropic)
- Maintenance: 2/2 (active development)
- Documentation: 2/2 (comprehensive)
- Tests: 0/1 (no tests found)

**Compatibility:**
- Language: Python (matches project)
- License: MIT (compatible)
- Integration: Standard skill format

**Adaptation Plan:**
1. Clone skill to `.claude/skills/`
2. Update paths for Atlas structure
3. Add Atlas-specific frontmatter
4. Test with sample files

**Effort:** 1 hour

---

### {Requirement 2}
[...]

## Recommendations Summary

### Immediate Actions
1. Clone {source} for {requirement}
2. Adapt {source} for {requirement}

### Build from Scratch
1. {requirement} - No existing solution found

### User Decisions Needed
1. {requirement} - Multiple options, user should choose

## Sources Searched
- [x] anthropics/skills
- [x] MCP Registry
- [x] obra/superpowers
- [x] Atlas knowledge base
- [x] awesome-claude-skills
```

### 8. Return Results

Report to orchestrator:
- `RESEARCH_FINDINGS.md` location
- Count of USE/ADAPT/BUILD recommendations
- Any decisions needed from user
- Estimated total adaptation effort

## Search Patterns

### GitHub Search

```python
# Example search patterns
searches = [
    f"{requirement} claude skill site:github.com",
    f"{tech_stack} {pattern} example site:github.com",
    f"site:github.com/anthropics/skills {keyword}",
]
```

### MCP Registry

Query: `GET https://registry.modelcontextprotocol.io/v0/servers?search={mcp-name}`

### Atlas Knowledge

```bash
# Past projects with similar type
grep -r "project_type: {type}" projects/

# Expertise files mentioning tech
grep -r "{framework}" expertise/

# Knowledge entries about pattern
grep -r "{pattern}" knowledge/
```

## Error Handling

| Issue | Action |
|-------|--------|
| Search API fails | Fall back to WebSearch |
| No results found | Document "BUILD" recommendation |
| Too many results | Filter by quality score |
| Rate limited | Cache results, retry later |

## Related

- [[working/planning/atlas-self-scaffolding/RESEARCH_SOURCES|Research Sources Catalog]]
- [[.claude/skills/project-analyzer/SKILL|Project Analyzer]]
- [[.claude/skills/workspace-scaffold/SKILL|Workspace Scaffold]]
