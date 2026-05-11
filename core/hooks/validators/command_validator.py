#!/usr/bin/env python3
"""
command_validator.py - Validates command files have proper structure.

Hook Usage:
  PostToolUse:
    - matcher: "Write|Edit|MultiEdit"
      hooks:
        - type: command
          command: "${INSTANCE_HOME}/hooks/validators/command_validator.py"

Exit Codes:
  0 = Valid (or not a command file)
  2 = Invalid (blocks and feeds back to Claude)
"""
import json
import sys
import re
from pathlib import Path

REQUIRED_FIELDS = ['description']


def validate_command(file_path: str) -> list[str]:
    """Validate a command file and return list of issues."""
    issues = []

    try:
        content = Path(file_path).read_text()
    except FileNotFoundError:
        return [f"File not found: {file_path}"]
    except Exception as e:
        return [f"Cannot read file: {e}"]

    # Check for frontmatter
    if not content.startswith('---'):
        issues.append("Missing YAML frontmatter")
        return issues

    match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not match:
        issues.append("Invalid frontmatter format (missing closing ---)")
        return issues

    fm_text = match.group(1)

    def get_field(text, field):
        m = re.search(rf'^{field}:\s*(.+)$', text, re.MULTILINE)
        return m.group(1).strip().strip('"\'') if m else None

    # Check required fields
    for field in REQUIRED_FIELDS:
        value = get_field(fm_text, field)
        if not value:
            issues.append(f"Missing required field: {field}")

    # Check for body content
    body = content[match.end():].strip()
    if not body:
        issues.append("Command file has no instructions after frontmatter")

    # Check for ## Process section
    if '## Process' not in body:
        issues.append("Missing required '## Process' section")

    return issues


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    file_path = data.get('tool_input', {}).get('file_path', '')

    if not file_path:
        sys.exit(0)

    # Only validate command files
    if '/.claude/commands/' not in file_path and '.claude/commands/' not in file_path:
        sys.exit(0)

    if not file_path.endswith('.md'):
        sys.exit(0)

    # Skip archive and registry
    skip_patterns = ['_registry', '.archive', '_index']
    if any(p in file_path.lower() for p in skip_patterns):
        sys.exit(0)

    issues = validate_command(file_path)

    if issues:
        print(f"Fix command in {file_path}:", file=sys.stderr)
        for issue in issues:
            print(f"  - {issue}", file=sys.stderr)
        sys.exit(2)

    print(f"✓ Command validated: {file_path}")
    sys.exit(0)


if __name__ == '__main__':
    main()
