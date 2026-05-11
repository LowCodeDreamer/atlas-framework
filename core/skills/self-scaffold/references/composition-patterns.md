# Composition Patterns

How Atlas components wire together to form capability stacks.

## The Four-Layer Stack

```
Layer 4: justfile recipe        just equip "task description"
            │
Layer 3: /equip command         claude -p "/equip {{ARGS}}"
            │
Layer 2: skill knowledge        SKILL.md loaded via @reference or agent context
            │
Layer 1: scripts                Deterministic code (inventory, validation)
            │
Layer 0: hooks                  Pre/PostToolUse validation
```

Each layer composes the ones below. Higher layers add orchestration; lower layers add capability.

## Execution Models

### Inline Execution (Command reads Skill directly)

Use when: The command needs user interaction during execution (approval gates, clarifying questions, iterative refinement).

```markdown
# In .claude/commands/my-command.md

## Context

@.claude/skills/my-skill/SKILL.md
@context/reference/schemas.md

## Process

1. Run deterministic inventory/analysis scripts
2. Apply reasoning using skill methodology
3. Present results to user for approval
4. After approval, build/execute
5. Run verification scripts
```

The command provides the **context** and **orchestration**. The skill provides the **methodology**. Claude applies **reasoning** inline.

**Examples:** `/equip`, `/strategy`, `/plan`

### Agent-Spawn Execution (Command delegates to Task tool)

Use when: The work is autonomous (no user interaction needed), needs isolated context, or benefits from parallelism.

```markdown
# In .claude/commands/my-command.md

## Process

1. Gather context from $ARGUMENTS and dynamic parameters
2. Launch the `my-agent` agent (via Task tool, subagent_type: "my-agent") with:
   - Task description including gathered context
3. Present agent results to user
```

The command provides the **context**. The agent provides the **reasoning** in isolated context.

**Examples:** `/process-inbox` (parallel file processing), `/strategy` (parallel advisor agents)

### Agent -> Skill

An agent references skills for methodology and knowledge:

```markdown
# In .claude/agents/my-agent.md

## Skills

- [[.claude/skills/my-skill/SKILL|My Skill]] — Provides methodology for X

## Process

1. Read the skill for methodology
2. Run `scripts/inventory.py` for deterministic inventory
3. Apply skill methodology to interpret results
4. Produce output following skill's schema
```

The skill provides **static knowledge**. The agent provides **dynamic reasoning**.

### Agent -> Script (Code Before AI)

For deterministic operations, agents/commands call scripts directly:

```markdown
## Process

1. Run inventory analysis:
   ```bash
   python3 ${INSTANCE_HOME}/.claude/skills/self-scaffold/scripts/inventory.py --inventory
   ```
2. Parse JSON output
3. Apply reasoning to interpret gaps
```

Scripts handle **what doesn't need intelligence**. Claude handles **what does**.

### Hook -> Output Validation

Hooks validate work via lifecycle events:

```python
# hooks/validators/skill_validator.py (PostToolUse on Write|Edit|MultiEdit)
# Reads JSON from stdin, filters by file path
# Exit 0: continue (or skip — not my file type)
# Exit 2: block with stderr feedback
```

Hooks provide **automated quality gates** without consuming agent context.

### Justfile -> Command

The outermost layer wraps commands for terminal use:

```makefile
# justfile
my-task *ARGS:
    claude -p "/my-command {{ARGS}}"
```

Justfile provides **human ergonomics**. Commands provide **workflow logic**.

## Common Stack Patterns

### Pattern A: Simple Capability

```
Skill only (no agent, no command)
```

Use when: Knowledge needs to be available but doesn't need dedicated orchestration. Other agents/commands reference the skill directly.

**Example:** `supabase-queries` skill — loaded by any agent that needs to write SQL.

### Pattern B: Interactive Workflow (Inline)

```
Command --(reads)--> Skill
   |
   └--(runs)--> Scripts
   |
   └--(validated by)--> Hooks
```

Use when: User needs a repeatable entry point that requires mid-flow interaction.

**Example:** `/equip` reads `self-scaffold` skill inline, asks for approval, then builds.

### Pattern C: Autonomous Workflow (Agent-Spawn)

```
Command --(spawns)--> Agent --(reads)--> Skill
                        |
                        └--(validated by)--> Hooks
```

Use when: Work is autonomous and benefits from isolated context.

**Example:** `/process-inbox` spawns file-processor agents in parallel.

### Pattern D: Full Stack

```
Justfile -> Command -> Agent(s) -> Skill(s) + Hook(s)
```

Use when: CLI-invokable, multi-step workflow with quality gates.

### Pattern E: Parallel Agents

```
Command -> [Agent A, Agent B, Agent C] -> Shared Skill
```

Use when: Independent work can be parallelized.

**Example:** `/strategy` with parallel advisor agents.

## Naming Conventions

| Component | Convention | Example |
|-----------|-----------|---------|
| Skill | `kebab-case/SKILL.md` | `self-scaffold/SKILL.md` |
| Agent | `kebab-case.md` | `file-processor.md` |
| Command | `kebab-case.md` | `equip.md` |
| Hook (shell) | `kebab-case.sh` | `inject-context.sh` |
| Hook (validator) | `snake_case.py` | `skill_validator.py` |
| Justfile recipe | `kebab-case` | `equip` |

## Anti-Patterns

- **Agent without skill** — Agent reinvents methodology each invocation. Capture knowledge in a skill.
- **Agent-spawn for interactive flow** — Subagents can't interact with users. Use inline execution for approval gates.
- **Hook doing reasoning** — Hooks should be deterministic. If it needs AI, use an agent.
- **Justfile with logic** — Justfile recipes should be thin wrappers. Logic belongs in commands.
- **Monolith agent** — One agent doing everything. Split into focused specialists.
- **Wrong hook paths** — Hooks live at `${INSTANCE_HOME}/hooks/`, NOT `.claude/hooks/`. Validators at `hooks/validators/`.
