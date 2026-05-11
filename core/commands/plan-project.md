# /plan-project Command

Create a comprehensive project planning document through adaptive interview.

## Usage

```
/plan-project [description]
/plan-project (with attached documents)
```

## What This Command Does

1. **Analyzes Input**
   - If you attached documents: Extracts goals, requirements, tech stack from them
   - If description only: Uses your description to seed the interview

2. **Adaptive Interview**
   - Only asks questions for information NOT found in docs
   - Groups related questions together
   - Skips irrelevant sections based on project type

3. **Generates Planning Doc**
   - Creates comprehensive PROJECT_PLAN.md
   - Includes YAML frontmatter for machine parsing
   - Saves to `working/planning/{project-name}/`

## Examples

**Simple project from description:**
```
/plan-project Build a REST API for user authentication with JWT
```

**Complex project with docs:**
```
/plan-project
[Attach: requirements.pdf, architecture.docx]
```

## Interview Flow

The planner asks only what's needed:

### Essential (always asked if unknown)
- Project name
- Project type (coding, research, client, content)
- Primary goal
- Success criteria

### Scope (complex projects)
- Key deliverables
- Out of scope
- Timeline
- Dependencies

### Technical (coding projects)
- Languages/frameworks
- Database needs
- External APIs
- Deployment target

### Tools (integration-heavy)
- MCP servers needed
- Atlas skills to use
- External integrations

## Output

Creates: `working/planning/{project-slug}/PROJECT_PLAN.md`

The document includes:
- Machine-parseable YAML frontmatter
- 15 structured sections
- All information needed for `/scaffold`

## Next Steps

After planning:
1. Review the generated plan
2. Edit if anything needs adjustment
3. Run `/scaffold {project-name}` to create workspace

## See Also

- [[.claude/skills/project-planner/SKILL|Project Planner Skill]]
- [[.claude/commands/scaffold|/scaffold Command]]
- [[templates/planning/PROJECT_PLAN_TEMPLATE|Planning Template]]
