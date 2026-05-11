# Interview Patterns for Project Planning

## Extraction Patterns

### Goal/Objective Detection

Look for these patterns in documents:

```regex
/(?:goal|objective|purpose|mission|aim)[s]?\s*[:\-]/i
/(?:we (?:want|need|aim) to)/i
/(?:the project will|this will|intended to)/i
```

### Requirement Detection

```regex
/(?:must|shall|should|needs to|required to)/i
/(?:requirement|spec|specification)[s]?\s*[:\-]/i
/(?:FR|NFR|REQ)[\s-]*\d+/i  # Formal requirement IDs
```

### Tech Stack Detection

**Languages:**
- Python, JavaScript, TypeScript, Rust, Go, Java, C#, Ruby, PHP, Swift, Kotlin

**Frameworks:**
- React, Vue, Angular, Svelte, Next.js, Nuxt
- FastAPI, Django, Flask, Express, NestJS
- Rails, Laravel, Spring Boot, .NET

**Databases:**
- PostgreSQL, MySQL, MongoDB, Redis, SQLite
- Supabase, Firebase, DynamoDB, Planetscale

**Cloud/Services:**
- AWS, GCP, Azure, Vercel, Netlify, Railway
- Docker, Kubernetes, Terraform

### Timeline Detection

```regex
/(?:deadline|due|by|before|target date)[:\s]+(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/i
/(?:phase|milestone|sprint)\s+\d+/i
/(?:week|month|quarter|Q[1-4])\s*\d*/i
```

## Question Templates

### Essential Questions

```markdown
**Project Basics**

1. **Name:** What should we call this project? (will become folder name)

2. **Type:** What kind of project is this?
   - [ ] Coding (building software)
   - [ ] Research (investigating/analyzing)
   - [ ] Client Work (external deliverable)
   - [ ] Content (documentation, articles)
   - [ ] Mixed

3. **Goal:** In one sentence, what does success look like?

4. **Done When:** How will we know it's complete?
   - [ ] [Criterion 1]
   - [ ] [Criterion 2]
```

### Scope Questions

```markdown
**Scope Definition**

1. **Key Deliverables:** What will we produce?
   - [ ] Deliverable 1
   - [ ] Deliverable 2

2. **Out of Scope:** What are we explicitly NOT doing?
   -

3. **Timeline:** Any deadlines or time constraints?
   -

4. **Dependencies:** What needs to exist before we can start?
   -
```

### Technical Questions (Coding Projects)

```markdown
**Technical Stack**

1. **Primary Language:**
   - [ ] Python  [ ] JavaScript/TypeScript  [ ] Other: ___

2. **Framework:**
   - Backend: ___
   - Frontend: ___

3. **Database:**
   - [ ] PostgreSQL  [ ] MongoDB  [ ] SQLite  [ ] None  [ ] Other: ___

4. **External APIs/Services:** What do we need to integrate with?
   -

5. **Deployment:** Where will this run?
   - [ ] Local only  [ ] Vercel/Netlify  [ ] AWS/GCP  [ ] Docker  [ ] Other: ___
```

### Tool Questions

```markdown
**Tools & Integrations**

1. **MCP Servers Needed:**
   - [ ] GitHub  [ ] ClickUp  [ ] Slack  [ ] Database  [ ] Other: ___

2. **Atlas Skills:** Which existing skills will help?
   - [ ] supabase-queries  [ ] n8n-integration  [ ] Other: ___

3. **External Links:** Any related resources?
   - ClickUp Task:
   - GitHub Repo:
   - Documentation:
```

## Skip Logic Rules

```yaml
# Skip rules based on project type
skip_rules:
  research:
    - tech_stack.frameworks
    - tech_stack.databases
    - mcps (unless explicitly mentioned)

  content:
    - tech_stack (all)
    - mcps (most)
    - scaffold.initialize_virtual_env

  coding:
    - (no skips - ask everything needed)

  client_work:
    - (no skips - thorough documentation needed)
```

## Complexity Scoring

```python
def calculate_complexity(project):
    score = 0

    # File count estimation
    if project.deliverables <= 3:
        score += 1
    elif project.deliverables <= 10:
        score += 3
    else:
        score += 5

    # Integration count
    mcp_count = len(project.mcps.required)
    if mcp_count <= 1:
        score += 1
    elif mcp_count <= 3:
        score += 3
    else:
        score += 5

    # Tech stack complexity
    if len(project.tech_stack.languages) <= 1:
        score += 1
    elif len(project.tech_stack.languages) <= 2:
        score += 3
    else:
        score += 5

    # Novel factor (subjective)
    if project.is_familiar_pattern:
        score += 1
    elif project.has_some_novelty:
        score += 3
    else:
        score += 5

    # Map to complexity level
    if score <= 7:
        return "simple"
    elif score <= 14:
        return "moderate"
    else:
        return "complex"
```

## Output Quality Checklist

Before saving the plan:

- [ ] Project slug is valid (lowercase, dashes, no spaces)
- [ ] Project type is one of: coding, research, client_work, content, mixed
- [ ] At least one clear success criterion
- [ ] YAML frontmatter parses without errors
- [ ] All required sections have content (not just placeholders)
- [ ] Complexity matches content (simple projects aren't marked complex)
- [ ] MCPs listed are valid MCP server names
- [ ] Domains listed exist in Atlas
