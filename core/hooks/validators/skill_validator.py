#!/usr/bin/env python3
"""
skill_validator.py - Validates skill SKILL.md files have proper structure.

Hook Usage:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/hooks/validators/skill_validator.py"

Exit Codes:
  0 = Valid (or not a skill file)
  2 = Invalid (blocks and feeds back to Claude)
"""
import json
import sys
import re
from pathlib import Path

REQUIRED_FIELDS = ['name', 'description']
VALID_CONTEXT_VALUES = ['fork', 'inline']

def validate_skill(file_path: str) -> list[str]:
    """Validate a skill file and return list of issues."""
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
    
    # Validate context if present
    context = get_field(fm_text, 'context')
    if context and context not in VALID_CONTEXT_VALUES:
        issues.append(f"Invalid context '{context}'. Valid: {VALID_CONTEXT_VALUES}")
    
    # Validate user-invocable if present
    user_invocable = get_field(fm_text, 'user-invocable')
    if user_invocable and user_invocable not in ['true', 'false']:
        issues.append(f"user-invocable must be true or false, got '{user_invocable}'")
    
    # Check for skill content
    body = content[match.end():].strip()
    if not body:
        issues.append("Skill file has no instructions after frontmatter")
    
    return issues

def main():
    try:
        data = json.load(sys.stdin)
    except:
        sys.exit(0)
    
    file_path = data.get('tool_input', {}).get('file_path', '')
    
    if not file_path:
        sys.exit(0)
    
    # Only validate SKILL.md files
    if not file_path.endswith('SKILL.md'):
        sys.exit(0)
    
    # Skip archive
    if '.archive' in file_path:
        sys.exit(0)
    
    issues = validate_skill(file_path)
    
    if issues:
        print(f"Fix skill in {file_path}:", file=sys.stderr)
        for issue in issues:
            print(f"  - {issue}", file=sys.stderr)
        sys.exit(2)
    
    print(f"✓ Skill validated: {file_path}")
    sys.exit(0)

if __name__ == '__main__':
    main()
