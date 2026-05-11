#!/usr/bin/env python3
"""
Inventory existing Atlas infrastructure components.

Usage:
    python3 inventory.py --inventory     # Full JSON inventory
    python3 inventory.py --summary       # One-line summary counts

Output: JSON with all skills, agents, commands, hooks, and validators.
"""

import json
import re
import sys
from pathlib import Path

def find_atlas_root() -> Path:
    """Find Atlas root by walking up from this script looking for .claude/settings.json marker."""
    candidate = Path(__file__).resolve().parent
    for _ in range(10):
        if (candidate / ".claude" / "settings.json").exists():
            return candidate
        candidate = candidate.parent
    # Fallback to depth-based calculation
    return Path(__file__).resolve().parents[4]

ATLAS_ROOT = find_atlas_root()
SKILLS_DIR = ATLAS_ROOT / ".claude" / "skills"
AGENTS_DIR = ATLAS_ROOT / ".claude" / "agents"
COMMANDS_DIR = ATLAS_ROOT / ".claude" / "commands"
HOOKS_DIR = ATLAS_ROOT / "hooks"


def extract_frontmatter(filepath: Path) -> dict:
    """Extract YAML frontmatter from a markdown file. Handles list items."""
    try:
        text = filepath.read_text(encoding="utf-8")
    except Exception:
        return {}

    match = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
    if not match:
        return {}

    fm = {}
    current_key = None
    for line in match.group(1).split("\n"):
        # List item under current key
        if line.startswith("  - ") and current_key:
            if not isinstance(fm[current_key], list):
                fm[current_key] = []
            fm[current_key].append(line.strip().lstrip("- ").strip())
            continue

        if ":" in line:
            key, _, val = line.partition(":")
            key = key.strip()
            val = val.strip().strip('"').strip("'")
            current_key = key
            if val:
                fm[key] = val
            else:
                fm[key] = []  # Prepare for list items
        else:
            current_key = None

    return fm


def inventory_skills() -> list[dict]:
    """List all skills with name and description."""
    skills = []
    if not SKILLS_DIR.exists():
        return skills

    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        if not skill_dir.is_dir():
            continue
        skill_file = skill_dir / "SKILL.md"
        if skill_file.exists():
            fm = extract_frontmatter(skill_file)
            skills.append({
                "type": "skill",
                "name": fm.get("name", skill_dir.name),
                "description": fm.get("description", ""),
                "location": str(skill_file.relative_to(ATLAS_ROOT)),
            })
    return skills


def inventory_agents() -> list[dict]:
    """List all agents with metadata."""
    agents = []
    if not AGENTS_DIR.exists():
        return agents

    for agent_file in sorted(AGENTS_DIR.glob("*.md")):
        if agent_file.name.startswith("_"):
            continue
        fm = extract_frontmatter(agent_file)
        agents.append({
            "type": "agent",
            "name": agent_file.stem,
            "description": fm.get("description", ""),
            "location": str(agent_file.relative_to(ATLAS_ROOT)),
        })
    return agents


def inventory_commands() -> list[dict]:
    """List all commands with descriptions."""
    commands = []
    if not COMMANDS_DIR.exists():
        return commands

    for cmd_file in sorted(COMMANDS_DIR.glob("*.md")):
        if cmd_file.name.startswith("_"):
            continue
        fm = extract_frontmatter(cmd_file)
        commands.append({
            "type": "command",
            "name": cmd_file.stem,
            "description": fm.get("description", ""),
            "location": str(cmd_file.relative_to(ATLAS_ROOT)),
        })
    return commands


def inventory_hooks() -> list[dict]:
    """List all hook scripts and validators."""
    hooks = []
    if not HOOKS_DIR.exists():
        return hooks

    # Shell hooks at hooks/*.sh
    for hook_file in sorted(HOOKS_DIR.glob("*.sh")):
        hooks.append({
            "type": "hook",
            "subtype": "shell",
            "name": hook_file.stem,
            "location": str(hook_file.relative_to(ATLAS_ROOT)),
        })

    # Python validators at hooks/validators/*.py
    validators_dir = HOOKS_DIR / "validators"
    if validators_dir.exists():
        for val_file in sorted(validators_dir.glob("*.py")):
            hooks.append({
                "type": "hook",
                "subtype": "validator",
                "name": val_file.stem,
                "location": str(val_file.relative_to(ATLAS_ROOT)),
            })

    return hooks


def full_inventory() -> dict:
    """Return complete infrastructure inventory."""
    skills = inventory_skills()
    agents = inventory_agents()
    commands = inventory_commands()
    hooks = inventory_hooks()

    shell_hooks = [h for h in hooks if h.get("subtype") == "shell"]
    validators = [h for h in hooks if h.get("subtype") == "validator"]

    return {
        "summary": {
            "skills": len(skills),
            "agents": len(agents),
            "commands": len(commands),
            "hooks": len(shell_hooks),
            "validators": len(validators),
            "total": len(skills) + len(agents) + len(commands) + len(hooks),
        },
        "skills": skills,
        "agents": agents,
        "commands": commands,
        "hooks": hooks,
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: inventory.py --inventory | --summary", file=sys.stderr)
        sys.exit(1)

    if sys.argv[1] == "--summary":
        inv = full_inventory()
        s = inv["summary"]
        print(f"Skills: {s['skills']}, Agents: {s['agents']}, Commands: {s['commands']}, Hooks: {s['hooks']}, Validators: {s['validators']}, Total: {s['total']}")
    elif sys.argv[1] == "--inventory":
        result = full_inventory()
        print(json.dumps(result, indent=2))
    else:
        print("Usage: inventory.py --inventory | --summary", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
