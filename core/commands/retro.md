---
description: End-of-session capture of progress, learnings, and handoff notes
argument-hint: "[task] [--learnings|--session-end|--quick]"
---
# /retro Command

Alias for the `/session-closure` skill.

## Usage

```
/retro [task] [--learnings]
/retro --session-end
/retro --quick
```

## Implementation

Invoke the `session-closure` skill with all provided arguments:

```
Invoke Skill: session-closure
Arguments: $ARGUMENTS
```

See [[../../skills/session-closure/SKILL|session-closure skill]] for full documentation.
