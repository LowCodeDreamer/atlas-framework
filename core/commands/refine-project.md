# Refine Project

Interview to improve an existing project's manifest and ensure correct tools are loaded.

## Usage

```
/refine-project                    # Refine current directory's project
/refine-project <domain>/<project>  # Refine specific project
```

## Instructions

You are refining an existing project setup. This interview improves the manifest based on actual work patterns and ensures all needed tools are available.

### Step 1: Locate Project

Check for argument: `$ARGUMENTS`

If provided, use that path. Otherwise, detect from current working directory:
```bash
# Check if we're in a project
pwd
ls _manifest.md 2>/dev/null
```

If no manifest found, offer options:
1. Run `/new-project` instead to create one
2. Specify a project path to refine

### Step 2: Load Current State

Read the existing manifest:
```bash
cat ${INSTANCE_HOME}/projects/<domain>/<project>/_manifest.md
```

Also check:
- What files exist in the project
- Recent git history if available
- Any `_domain.md` content

### Step 3: Analyze & Interview

Based on current state, ask targeted questions:

**Stack Analysis:**
- Review files in project: "I see `.ts` files but TypeScript isn't in your stack. Add it?"
- Check imports/dependencies: "You're using X library. Should I add it to stack?"

**MCP Analysis:**
- Compare required MCPs to available: "MCP `salesforce` is listed but not installed. Still needed, or remove?"
- Suggest based on stack: "You're using Supabase. Load the `supabase-queries` skill?"

**Credential Check:**
```bash
# Check which env vars are set
env | grep -i "<workspace>"
```
- "Credential X shows 'needed' but I see it's now configured. Update status?"
- "I don't see ENV_VAR set. Still needed?"

**Context Review:**
- "Your context_budget is 'minimal' but this is a complex integration. Increase to 'standard'?"
- "Phase is 'discovery' - has this moved to 'build'?"

**Agent/Skill Suggestions:**
- Based on type and stack, suggest relevant agents/skills not currently listed
- "For Salesforce integration, would the `salesforce-patterns` skill help?" (if exists)

### Step 4: Present Changes

Show a diff of proposed manifest updates:

```
Proposed changes to _manifest.md:

stack:
- + typescript (detected from .ts files)
- + react (detected from imports)

mcps.required:
- - salesforce (not installed, marking optional)

mcps.optional:
+ salesforce (moved from required)

credentials:
~ EXAMPLE_CRED: needed → configured

phase: discovery → build

context_budget: minimal → standard

Apply these changes? [Yes / Edit / Cancel]
```

### Step 5: Apply Updates

If approved, update the manifest file with Edit tool.

Also update `_domain.md` if relevant learnings emerged:
- Add new decisions
- Update overview if scope changed
- Add references discovered

### Step 6: Verify Environment

After updates, run verification:

```bash
# Check MCP availability
cat ~/.claude/settings.json | grep -A 5 '"<mcp-name>"'

# Check credentials
env | grep -E "(YOUR_PREFIX_A|YOUR_PREFIX_B)" | head -5
```

Report final status:
```
✅ Project refined: <workspace>/<project>

Updated:
- stack: +2 technologies
- credentials: 1 status updated
- phase: discovery → build

Environment Status:
- ✅ All required MCPs available
- ✅ All credentials configured
- ⚠️ Optional MCP `salesforce` not installed

Ready to work!
```

### Special Mode: Domain Refinement

If run on a domain folder (`projects/<domain>/`) without a specific project:

Treat the domain's `_domain.md` as the target. Interview to:
- Improve domain-level defaults
- Add relevant MCPs for all projects in this domain
- Update default agent/skill configurations
- Enhance domain patterns and practices

This allows `/refine-project` to also improve <your domains> workspace setups.
