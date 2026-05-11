# Porting Self-Scaffold to Another Claude Code Instance

Guide for porting the `/equip` self-scaffolding system to nanoclaw or any other Claude Code project.

## What You're Porting

The self-scaffold system is 4 layers:

```
Layer 3: /equip command        .claude/commands/equip.md
Layer 2: self-scaffold skill   .claude/skills/self-scaffold/
Layer 1: scripts               .claude/skills/self-scaffold/scripts/
Layer 0: validators            hooks/validators/*.py
```

Plus: settings.json hook wiring, schemas reference, and a working directory.

## File Manifest

### Required Files (copy these)

```
.claude/commands/equip.md                              Command entry point
.claude/skills/self-scaffold/SKILL.md                  Methodology
.claude/skills/self-scaffold/scripts/inventory.py      Infrastructure scanner
.claude/skills/self-scaffold/scripts/validate_manifest.py  Manifest validator
.claude/skills/self-scaffold/scripts/verify_build.py   Closed-loop verifier
.claude/skills/self-scaffold/references/composition-patterns.md  Wiring guide
hooks/validators/skill_validator.py                    Skill file validator
hooks/validators/agent_validator.py                    Agent file validator
hooks/validators/command_validator.py                  Command file validator
context/reference/schemas.md                           Document schemas
```

### Optional Files (adapt or skip)

```
.claude/skills/self-scaffold/references/indydevdan-patterns.md  Framework theory
justfile                                               CLI entry point
```

## Adaptation Checklist

### 1. Directory Structure

Create these directories in your target project:

```bash
mkdir -p .claude/commands
mkdir -p .claude/skills/self-scaffold/scripts
mkdir -p .claude/skills/self-scaffold/references
mkdir -p hooks/validators
mkdir -p context/reference
mkdir -p working/active
```

### 2. Path Updates in `equip.md`

The command uses absolute paths with `${INSTANCE_HOME}/`. Replace all occurrences:

```
${INSTANCE_HOME}/  →  ~/path/to/your/project/
```

Specifically these lines:
- `python3 ${INSTANCE_HOME}/.claude/skills/self-scaffold/scripts/inventory.py`
- `python3 ${INSTANCE_HOME}/.claude/skills/self-scaffold/scripts/validate_manifest.py`
- `python3 ${INSTANCE_HOME}/.claude/skills/self-scaffold/scripts/verify_build.py`

### 3. Path Updates in `composition-patterns.md`

One absolute path reference:
```
python3 ${INSTANCE_HOME}/.claude/skills/self-scaffold/scripts/inventory.py
```
Change to your project path.

### 4. Scripts Need No Changes

`inventory.py` and `verify_build.py` use `find_atlas_root()` which walks up the directory tree looking for `.claude/settings.json`. This works at any directory depth — no path changes needed.

### 5. Validator Hook Registration

Add to your `.claude/settings.json` under `hooks.PostToolUse`:

```json
{
  "matcher": "Write|Edit|MultiEdit",
  "hooks": [
    {"type": "command", "command": "~/your/project/hooks/validators/skill_validator.py"}
  ]
},
{
  "matcher": "Write|Edit|MultiEdit",
  "hooks": [
    {"type": "command", "command": "~/your/project/hooks/validators/agent_validator.py"}
  ]
},
{
  "matcher": "Write|Edit|MultiEdit",
  "hooks": [
    {"type": "command", "command": "~/your/project/hooks/validators/command_validator.py"}
  ]
}
```

### 6. Schemas Adaptation

`context/reference/schemas.md` defines Atlas-specific document types (Domain, Expertise). For nanoclaw:
- Keep: Skill, Agent, Command, Hook schemas (these are universal Claude Code patterns)
- Remove or adapt: Domain, Expertise schemas (Atlas-specific)
- Keep: Hook schema section (universal)

### 7. SKILL.md References

The skill references `indydevdan-patterns.md` via symlink. For nanoclaw:
- Either copy the file directly (no symlink)
- Or remove the reference from the Bundled Resources section

### 8. Working Directory

The equip command writes manifests to `working/active/EQUIP_MANIFEST.json`. Ensure this directory exists or change the path in the command.

## Minimal Port (Just the Core)

If you want the smallest useful subset:

1. Copy `inventory.py` + `validate_manifest.py` + `verify_build.py` to `.claude/skills/self-scaffold/scripts/`
2. Copy `SKILL.md` to `.claude/skills/self-scaffold/`
3. Copy `equip.md` to `.claude/commands/` (update paths)
4. Copy 3 validators to `hooks/validators/`
5. Wire validators in settings.json

That gives you: `/equip` with gap analysis, manifest validation, build verification, and write-time validators. ~500 lines of Python + ~400 lines of markdown.

## Smoke Test

After porting, run:

```bash
# Inventory finds components
python3 .claude/skills/self-scaffold/scripts/inventory.py --summary

# Validators work
echo '{"tool_input":{"file_path":"'"$(pwd)"'/.claude/skills/self-scaffold/SKILL.md"}}' | python3 hooks/validators/skill_validator.py
echo $?  # Should be 0

# Verify build works
echo '{"task":"test","analysis":{"existing_capabilities":[],"gaps":[]},"components":[{"type":"skill","name":"self-scaffold","purpose":"test","location":".claude/skills/self-scaffold/SKILL.md"}],"composition":{"flow":"test"}}' | python3 .claude/skills/self-scaffold/scripts/verify_build.py -
echo $?  # Should be 0
```

## Architecture Decisions (Why It Works This Way)

| Decision | Reason |
|----------|--------|
| Inline execution (not subagent) | `/equip` needs user approval mid-flow; subagents can't ask |
| Python validators (not shell) | Structural validation needs regex/JSON parsing; bash is fragile for this |
| `find_atlas_root()` in scripts | Portability — works at any directory depth |
| Manifest → file → verify | Closed loop requires persistence; can't verify what's only in memory |
| Gap analysis = Claude reasoning | Keyword matching was fake intelligence; let the LLM do what LLMs do |
| Validators self-filter by path | One registration fires on all writes; each validator ignores non-target files |
