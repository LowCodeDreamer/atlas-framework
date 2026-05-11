---
description: Analyze capability gaps and build infrastructure stacks for new tasks
argument-hint: <task-description>
---

# Equip

Self-scaffolding command. Analyzes what Atlas infrastructure exists vs. what's needed for a task, then builds the missing components.

Use when starting new work that might benefit from dedicated skills, agents, commands, or hooks.

## Arguments

- `$ARGUMENTS` — Description of what you want to accomplish

## Context

Current infrastructure inventory:
!`python3 ${INSTANCE_HOME}/.claude/skills/self-scaffold/scripts/inventory.py --summary 2>/dev/null || echo "Run inventory.py manually"`

## Methodology

Read the self-scaffold skill for the full methodology:
@.claude/skills/self-scaffold/SKILL.md

Read composition patterns for wiring guidance:
@.claude/skills/self-scaffold/references/composition-patterns.md

## Process

### Phase 1: Planning (inline)

1. If `$ARGUMENTS` is empty, ask the user what task they want to equip for
2. Run inventory to understand existing infrastructure:
   ```bash
   python3 ${INSTANCE_HOME}/.claude/skills/self-scaffold/scripts/inventory.py --inventory
   ```
3. Analyze the inventory against the task requirements:
   - Identify existing capabilities that can be reused
   - Identify gaps that need new components
   - Classify gap severity (Critical / Enhancing / Nice-to-have)
4. Design the minimal component stack using the decision tree from the skill:
   - Is this a one-off? Skip command + justfile
   - Does it need reasoning? Use an agent. If not, use a script
   - Does it need validation? Add a hook
   - Will the user invoke it repeatedly? Add a command
5. Produce an EQUIP_MANIFEST JSON following the schema in the skill
6. Write the manifest to `working/active/EQUIP_MANIFEST.json` for persistence
7. Validate the manifest:
   ```bash
   python3 ${INSTANCE_HOME}/.claude/skills/self-scaffold/scripts/validate_manifest.py working/active/EQUIP_MANIFEST.json
   ```
8. Present the manifest to the user for approval:
   - Human-readable summary of what will be built
   - What existing components will be reused
   - Composition flow diagram
   - **Wait for explicit user approval before proceeding**

### Phase 2: Building (after approval)

9. Read `context/reference/schemas.md` for canonical file formats
10. For each component in the manifest, in dependency order:
    - Read existing examples of the same type for style consistency
    - Build the component following Atlas conventions
    - Hooks fire automatically on each Write (validators validate the output)
11. Run closed-loop verification:
    ```bash
    python3 ${INSTANCE_HOME}/.claude/skills/self-scaffold/scripts/verify_build.py working/active/EQUIP_MANIFEST.json
    ```
12. If verification fails, fix the issues and re-verify (max 3 iterations)
13. Clean up: remove `working/active/EQUIP_MANIFEST.json`

### Phase 3: Reporting

14. Summarize what was built:
    - List all created files with absolute locations
    - Show the composition flow
    - Explain how to use the new capability
    - Note any hook registration needed in `.claude/settings.json`
    - Suggest a justfile recipe if appropriate

## Output Format

```
## Equip: [Task Name]

### Analysis
[Gap analysis summary — what exists, what's needed]

### Built
| Type | Name | Location |
|------|------|----------|
| ... | ... | ... |

### Composition
[Flow diagram showing how components wire together]

### Usage
- Command: /[name]
- CLI: just [recipe]

### Hook Registration
[Any settings.json changes needed, or "None — all hooks auto-registered"]
```

## Example

```
/equip Salesforce metadata deployment with validation
```

## Related Commands

- `/plan` — General task planning (equip is specifically for infrastructure)
- `/refresh-status` — Update system status after equipping
