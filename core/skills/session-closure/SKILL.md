---
name: session-closure
description: End-of-session capture of progress, learnings, and handoff notes. Use when ending work sessions, capturing learnings, or ensuring seamless handoff to future sessions.
user-invocable: true
context: fork
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - TaskOutput
---

# Session Closure

End-of-session capture to ensure seamless handoff to future sessions.

## Usage

```
/session-closure [task] [--learnings]
/session-closure --session-end
/session-closure --quick
```

**Alias:** `/retro` (common shorthand)

## Arguments

- `$1` — Specific task to retro (optional, defaults to all active work)
- `--learnings` — Also capture system-level learnings via agent delegation
- `--session-end` — Full session closure with learning capture and archival
- `--quick` — Fast update of active task READMEs only

## When to Run

| Flag | When to Use |
|------|-------------|
| `--session-end` | End of day, significant milestones, before context switching |
| `--learnings` | When system insights emerged that should be captured |
| `--quick` | Quick handoff between sessions, update current state |
| `[task]` | Specific task completion or major progress |

## Workflow

### Step 1: Session Context Enrichment (ALWAYS RUN)

**This step is MANDATORY for every /retro invocation regardless of flags or mode.**

Enrich the session log with domain connections and file tracking:

```
Task tool:
  subagent_type: "session-context-manager"
  prompt: |
    Enrich the current session log with domains touched, files modified,
    and components used.
```

The agent reads from two sources (in order of preference):
1. **Temp activity log** (`~/.atlas-session-activity.log`) — Fast, pre-tracked file operations
2. **JSONL transcript** (`~/.claude/projects/`) — Full extraction if temp log unavailable

Updates the session log at `logs/sessions/session-{timestamp}.md` with:
- Domains touched (wikilinks)
- Files modified (wikilinks with action)
- Components used (skills, agents, commands)
- Primary task extracted from first user message

Use the returned `{domains: [...]}` data to inform learning capture.

**Why mandatory:** Session logs without context are orphaned stubs. Every session must be connected to the knowledge graph.

### Step 2: Skill Discovery

Check what skills might be relevant for the work being retro'd:

```bash
grep -r "skill_" skills/ | grep -i {task-domain}
```

This informs which expertise might need updating.

### Step 3: Identify Active Work

Check what's currently in progress:

```bash
ls ${INSTANCE_HOME}/working/active/
```

If a specific task was named, focus on that.

### Step 4: Update Task READMEs

For each active task, ensure README.md contains current state:

```markdown
## Current State
{What just happened — update this section}

## Progress
- [x] What was completed this session
- [ ] What's still pending

## Next Steps
{What the next session should do first}

## Decisions Made
{Any choices made and why}

**Last Updated:** {now}
```

**The test:** If this session died right now, could the next session pick up seamlessly?

### Step 5: Learning Capture (if --learnings or --session-end)

#### 5a. Learning Assessment

Ask:
- Did we learn something about how the system should work?
- Did we discover a pattern worth documenting?
- Did we find friction that should be fixed?
- What domain-specific insights emerged?

#### 5b. Agent Delegation Strategy

Based on learning type, delegate to the appropriate agent:

**For System/Process Learnings:**
```
Task tool:
  subagent_type: "meta-expertise"
  prompt: |
    Create expertise for [learning topic] in system/ category.
    Key insights: [insights]. Confidence level: low/medium.
```

**For Domain-Specific Learnings:**
```
Task tool:
  subagent_type: "meta-expertise"
  prompt: |
    Create expertise for [domain topic] in domains/ category.
    Related domain: [[domain/path]]. Key insights: [insights].
```

**For Skill/Capability Learnings:**
```
Task tool:
  subagent_type: "meta-skill"
  prompt: |
    Create skill for [capability] in [category].
    Workflow discovered: [workflow]. Integration: [if MCP-related].
```

#### 5c. Agent Validation

Execute the delegation:
1. Gather learning context from session
2. Determine appropriate agent and category
3. Invoke agent with explicit context
4. Validate agent output and file creation
5. Link new artifacts to relevant domains

**Always confirm before delegating to agents that create permanent context.**

### Step 6: Archive Completed Work

If any tasks have status "Complete":

```bash
mv working/active/{task} working/archive/{YYYY-MM}/{task}
```

### Step 7: Refresh System Status

Run `/refresh-status --quiet` to update SYSTEM-STATUS.md with current counts.

### Step 8: Generate Summary

```markdown
## Session Retro Complete

### Skills Checked
- {skill-files-reviewed} — Relevance to current work

### Tasks Updated
- {task-name}/README.md — Current state captured with next steps

### Archived Work
- {task-name} → working/archive/2025-12/

### Agent-Generated Artifacts (if --learnings)
- **Expertise Created:** [{count}] via meta-expertise delegation
- **Skills Created:** [{count}] via meta-skill delegation

### Knowledge Graph Impact
- **New Links:** {count} wikilinks added to connect learnings
- **Updated Domains:** {domain-list} if applicable

### Ready for Next Session
Active work in `working/active/`:
- {list of remaining tasks with status}

**Atlas Handoff Test:** Can the next session resume with zero context loss? ✓/✗
```

## Mode Differences

### Quick Mode (`--quick`)

1. Skip skill discovery
2. Update active task READMEs only
3. Output summary of current state
4. Exit (no archival, no learning capture)

### Standard Mode (default)

1. Full skill discovery
2. Update task READMEs
3. No learning capture unless `--learnings`
4. Archive completed work
5. Generate handoff summary

### Session End Mode (`--session-end`)

1. Full skill discovery
2. Update task READMEs
3. **Auto-enable** learning capture
4. Archive completed work
5. Generate comprehensive handoff summary
6. Create session archive entry

### Learning Mode (`--learnings`)

1. Normal workflow plus agent delegation for insights
2. Requires explicit confirmation before permanent updates
3. Validates all agent-created artifacts

## Agent Delegation Validation

When agents create artifacts, verify:
- [ ] Proper frontmatter with correct ID format
- [ ] Schema compliance
- [ ] Appropriate wikilinks to related artifacts
- [ ] Version control (initial version = 1)
- [ ] Clear connection to originating domain if applicable

## Related

- [[../../agents/session-context-manager|session-context-manager]] — Enriches session logs
- [[../../agents/meta-expertise|meta-expertise]] — Creates expertise files
- [[../../agents/meta-skill|meta-skill]] — Creates skill files
- `/refresh-status` — Updates system status

---

*Run /retro before stepping away. Future you will thank present you.*
