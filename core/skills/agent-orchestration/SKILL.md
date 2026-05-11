---
name: agent-orchestration
description: Guidance for orchestrating subagents and deciding when to use forked vs inline context. Use when designing skills that coordinate multiple agents or when choosing context mode for a new skill.
user-invocable: false
---

# Agent Orchestration

Guidance for designing skills and agents that work with Claude Code's context system.

## Context Modes

Skills can declare `context: fork` in their frontmatter:

| Mode | Behavior | Context |
|------|----------|---------|
| **Inline** (default) | Runs in main conversation | Full history available |
| **Fork** (`context: fork`) | Spawns isolated subagent | Fresh start, explicit input only |

## When to Fork vs Stay Inline

### Use `context: fork` when:

- **Heavy processing** — File extraction, content transformation, image analysis
- **Parallel workers** — Multiple instances can run concurrently
- **Isolation needed** — Task shouldn't pollute main context with intermediate state
- **No conversation context needed** — Input is fully specified in the prompt
- **Single responsibility** — One input → one output, no coordination

**Examples:** `file-normalization`, `image-generation`, `session-closure`

### Stay Inline (no fork) when:

- **Orchestrating subagents** — Need to spawn, wait, collect, synthesize
- **Conversation-dependent** — References previous messages or context
- **State accumulation** — Building results across multiple steps
- **Small operations** — Quick tasks that don't justify spawn overhead
- **User interaction** — Needs to ask questions mid-task

**Examples:** `inbox-orchestration`, `output-styles`, `n8n-integration`

## Decision Tree

```
Is this skill an orchestrator that spawns subagents?
├─ YES → INLINE (needs to collect results)
└─ NO
   ├─ Does it need previous conversation context?
   │  ├─ YES → INLINE
   │  └─ NO
   │     ├─ Will it process heavy content (files, images)?
   │     │  ├─ YES → FORK (saves main context budget)
   │     │  └─ NO → INLINE (default, lower overhead)
```

**Default: Stay inline.** Fork is opt-in for specific patterns.

## The Orchestrator Pattern

Orchestrators run **inline** but spawn **forked** workers:

```
Orchestrator (INLINE)
├── spawn worker 1 (FORK) → returns JSON
├── spawn worker 2 (FORK) → returns JSON
├── spawn worker 3 (FORK) → returns JSON
└── collect + synthesize results
```

**Why this works:**
- Orchestrator maintains state across all spawns
- Workers run in isolation, can't affect each other
- Results collected via TaskOutput
- Synthesis happens in main context with full history

**Example:** `/process-inbox` skill (inline) spawns `file-classifier` agents (can fork) in parallel.

## Anti-Patterns

### 1. Forked Orchestrator

**Problem:** Skill marked `context: fork` tries to spawn and collect from subagents.

**Failure mode:** Loses ability to collect results. Each subagent spawn is a new message, but forked skill can't maintain state between them.

**Fix:** Remove `context: fork` from orchestrator skills.

### 2. Inline Heavy Processor

**Problem:** Skill processes large files inline, consuming main context budget.

**Symptom:** Summarization requests appear. Conversation history lost.

**Fix:** Add `context: fork` for content-heavy single-purpose skills.

### 3. Fork Without Explicit Input

**Problem:** Forked skill assumes conversation context is available.

**Symptom:** Agent starts blind, produces wrong output.

**Fix:** Forked skills must receive ALL needed input in the prompt. Never rely on "previous conversation".

## Frontmatter Reference

```yaml
---
name: skill-name
description: What this skill does
user-invocable: true|false
context: fork          # ONLY if meets fork criteria above
allowed-tools:
  - Read
  - Write
  - Task             # Include if skill spawns subagents
  - TaskOutput       # Include if collecting from subagents
---
```

## Atlas Examples

| Skill | Context | Why |
|-------|---------|-----|
| `inbox-orchestration` | Inline | Spawns classifiers, collects results, synthesizes report |
| `file-normalization` | Fork | Heavy processing, single file → single output |
| `image-generation` | Fork | API call, isolated, explicit input |
| `session-closure` | Fork | Session capture is isolated work |
| `output-styles` | Inline | Lightweight, conversation-dependent |
| `n8n-integration` | Inline | Needs conversation context for workflow selection |

## Parallel Execution Pattern

To spawn multiple workers in parallel:

```
In a SINGLE message, call Task tool multiple times:

Task(subagent_type: "file-classifier", run_in_background: true, ...)
Task(subagent_type: "file-classifier", run_in_background: true, ...)
Task(subagent_type: "file-classifier", run_in_background: true, ...)

Then collect with:

TaskOutput(task_id: "id1", block: true)
TaskOutput(task_id: "id2", block: true)
TaskOutput(task_id: "id3", block: true)
```

Workers can have `context: fork` in their skill definition. The orchestrator must stay inline to collect results.

## Quick Reference

```
Fork?
- Orchestrator → NO (needs state for collection)
- Heavy processor → YES (saves context)
- Parallel worker → YES (isolation is good)
- Conversation-dependent → NO (needs history)
- Default → NO (inline is simpler)
```

---

*When in doubt, stay inline. Fork is an optimization, not a default.*
