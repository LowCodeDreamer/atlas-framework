# New Project

Initialize a new project with manifest and domain scaffolding.

## Usage

```
/new-project <domain>/<project-name>
/new-project <domain>/<sub>/<project>
/new-project <domain>/<project>
/new-project <domain>/<project>
```

## Instructions

You are initializing a new project. Follow this interview flow to gather requirements and create the project scaffold.

### Step 1: Parse Arguments

Extract `workspace` and `project-name` from the argument: `$ARGUMENTS`

If no argument provided, ask:
- "What workspace is this for?" (e.g., <your domains>)
- "What's the project name?" (kebab-case, descriptive)

**Domain = client, product, or system area. Projects live inside domains.**

### Step 2: Interview

Use the AskUserQuestion tool to gather project details. Ask these questions (can batch related ones):

**Question Set 1: Type & Stack**
- Project type? [development | integration | consulting | research]
- Primary technologies/stack? (e.g., typescript, supabase, <integration>, n8n)

**Question Set 2: Tools & Access**
- What MCP servers will this need? Review available:
  - `supabase` - Database operations
  - `n8n-builder` - Workflow automation
  - `n8n-cloud` - Execute existing workflows
  - `<integration>` - SF API (if available)
  - `clickup` - Project management
- Any credentials or API access needed?

**Question Set 3: Context**
- What phase is this? [discovery | build | deploy | maintain]
- Key constraints or context to remember?
- How much context should load by default? [minimal | standard | full]

### Step 3: Check Prerequisites

After gathering answers:

1. **Check MCP availability:**
```bash
# List available MCPs from settings
cat ~/.claude/settings.json | grep -A 50 '"mcpServers"'
```

2. **Check if workspace exists:**
```bash
ls ${INSTANCE_HOME}/projects/<domain>/
```

3. **Check if domain knowledge exists:**
```bash
ls ${INSTANCE_HOME}/expertise/domains/<workspace>/
```

4. **Report any gaps:**
- Missing MCPs that need installation
- Missing credentials that need configuration
- Missing workspace (will be created)
- Missing domain knowledge (suggest creating with /init-domain)

### Step 4: Create Project Structure

Create the project directory and files:

```bash
mkdir -p ${INSTANCE_HOME}/projects/<domain>/<project>
```

**Create `_manifest.md`:**
```yaml
---
project: <project-name>
workspace: <workspace>
type: <type>
inherits:
  - <domain>
  - <workspace>
stack:
  - <technologies...>
mcps:
  required:
    - <required-mcps...>
  optional:
    - <optional-mcps...>
credentials:
  - name: <CRED_NAME>
    env: <ENV_VAR>
    status: needed
agents:
  - domain-<workspace>
skills:
  - <relevant-skills...>
context_budget: <budget>
phase: <phase>
created: <today's date>
updated: <today's date>
notes: |
  <constraints and context from interview>
---
```

**Create `_domain.md`:**
```markdown
# <Project Name>

Project-specific knowledge for <workspace>/<project>.

## Overview

<Brief description from interview>

## Decisions

<!-- Track architectural and design decisions -->

## Learnings

<!-- Capture insights as work progresses -->

## References

<!-- Links, docs, resources -->
```

### Step 5: Confirm & Next Steps

Report what was created:
```
✅ Project initialized: <workspace>/<project>

Created:
- projects/<domain>/<project>/_manifest.md
- projects/<domain>/<project>/_domain.md

Prerequisites:
- ✅ MCP: supabase (available)
- ⚠️ MCP: <integration> (not installed - see setup instructions)
- ⚠️ Credential: EXAMPLE_TOKEN (needs configuration)

Next steps:
1. Configure missing credentials in ~/.secrets/
2. Install missing MCPs if needed
3. cd ${INSTANCE_HOME}/projects/<domain>/<project>
4. Start working!
```

### Step 6: Offer to Load Context

Ask if they want to immediately load the project context:
```
Load project context now and begin work?
```

If yes, read the manifest and prime the conversation with relevant domain knowledge.
