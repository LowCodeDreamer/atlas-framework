---
name: self-scaffold
description: Self-scaffolding methodology for building Atlas infrastructure stacks. Use when analyzing capability gaps, planning component stacks (skills + agents + commands + hooks), or executing the /equip workflow. Triggers on gap analysis, infrastructure planning, stack building, equip.
---

# Self-Scaffold

Analyze task requirements against existing Atlas infrastructure, identify capability gaps, and plan/build component stacks that compose skills, agents, commands, and hooks into complete workflows.

## Core Concept

A capability stack follows the layered architecture:

```
Layer 4: Justfile recipe    → Human CLI entry point
Layer 3: Command            → Workflow orchestration (/command-name)
Layer 2: Agent              → Specialized worker (isolated context)
Layer 1: Skill              → Static capability (knowledge + scripts)
Layer 0: Hook               → Lifecycle validation (pre/post/stop)
```

Each layer composes the ones below it. A single capability (e.g., "deploy Salesforce metadata") might need a skill (the knowledge), an agent (the executor), a command (the entry point), and hooks (the validation).

**Important:** Not every capability needs all layers. Commands can run inline (without spawning agents) when user interaction is needed during execution. Use the decision tree below.

## Gap Analysis Protocol

1. **Parse task description** into required capabilities
2. **Inventory existing infrastructure** using `scripts/inventory.py --inventory`
3. **Match capabilities to components** — partial matches count
4. **Identify gaps** — what's missing to support the task well
5. **Classify gap severity:**
   - **Critical** — cannot proceed without this component
   - **Enhancing** — would significantly improve the workflow
   - **Nice-to-have** — minor improvement

## Stack Planning

For each identified gap, determine the minimal component set:

| Need | Component | When |
|------|-----------|------|
| Knowledge/methodology | Skill | Task requires domain knowledge or repeatable process |
| Autonomous execution | Agent | Task needs isolated context, parallel work, or specialized tools |
| User entry point | Command | Task will be repeated by user via `/command-name` |
| Quality gate | Hook | Task output needs deterministic validation |
| CLI shortcut | Justfile recipe | Task should be invokable from terminal |

**Decision tree:**
- Is this a one-off? Skip command + justfile.
- Does it need reasoning? Use an agent. If not, use a script.
- Does it need validation? Add a hook.
- Will the user invoke it repeatedly? Add a command.
- Does the command need user interaction mid-flow? Run **inline** (no agent spawn).
- Does the command need autonomous execution? Spawn an **agent** via Task tool.

## EQUIP_MANIFEST Schema

The planner produces this JSON for approval before building:

```json
{
  "task": "Description of what the user wants to do",
  "analysis": {
    "existing_capabilities": [
      {"type": "skill|agent|command", "name": "name", "relevance": "full|partial|tangential"}
    ],
    "gaps": ["Gap description 1", "Gap description 2"]
  },
  "components": [
    {
      "type": "skill|agent|command|hook",
      "name": "component-name",
      "purpose": "What this component provides",
      "location": "path/to/file",
      "dependencies": [],
      "details": {}
    }
  ],
  "composition": {
    "flow": "command -> skill (inline) with hook validation",
    "entry_point": "/command-name",
    "justfile_recipe": "recipe-name *ARGS:\n    claude -p \"/command-name {{ARGS}}\""
  }
}
```

### Component Detail Fields

**Skill details:**
```json
{"resources": ["scripts/helper.py", "references/guide.md"]}
```

**Agent details:**
```json
{"model": "sonnet|opus|haiku", "tools": ["Read", "Write"], "uses_skills": ["skill-name"]}
```

**Command details:**
```json
{"execution": "inline|agent-spawn", "arguments": ["$ARGUMENTS"]}
```

**Hook details:**
```json
{"event": "PreToolUse|PostToolUse|Stop", "matcher": "Write|Edit", "exit_code_2_on": "condition"}
```

## Composition Patterns

See `references/composition-patterns.md` for detailed wiring patterns.

**Quick reference:**
- **Inline command** reads skill directly via `@` file reference, runs all logic in main context
- **Agent-spawn command** delegates to Task tool with `subagent_type` for autonomous work
- Agent loads skill knowledge from SKILL.md
- Hook validates output via exit code protocol (0=pass, 2=block)
- Justfile wraps command in `claude -p "/command-name {{ARGS}}"`

## Bundled Resources

- `scripts/inventory.py` — Inventory existing skills/agents/commands/hooks/validators
- `scripts/validate_manifest.py` — Validate EQUIP_MANIFEST.json before execution
- `scripts/verify_build.py` — Closed-loop verification of built components
- `references/composition-patterns.md` — Detailed stack composition guide
- `references/indydevdan-patterns.md` — Framework reference (sections 3, 5, 9)

## Workflow (for /equip)

1. User provides task description
2. Run `inventory.py --inventory` for deterministic component listing
3. Apply gap analysis reasoning against inventory (Claude, not a script)
4. Produce EQUIP_MANIFEST JSON, validate with `validate_manifest.py`
5. Present manifest to user for approval
6. After approval: read schemas, read existing examples, build each component
7. Run `verify_build.py` — if failures, fix and re-verify (max 3 iterations)
8. Report what was built and how to use it
