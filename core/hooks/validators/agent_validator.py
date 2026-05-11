#!/usr/bin/env python3
"""
agent_validator.py - Validates agent definition files have required frontmatter.

Hook Usage:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/hooks/validators/agent_validator.py"

Exit Codes:
  0 = Valid (or not an agent file)
  2 = Invalid (blocks and feeds back to Claude)
"""
import json
import sys
import re
from pathlib import Path

REQUIRED_FIELDS = ['name', 'description', 'model']
VALID_MODELS = ['haiku', 'sonnet', 'opus']

def validate_agent(file_path: str) -> list[str]:
    """Validate an agent definition and return list of issues."""
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
    
    # Validate model if present
    model = get_field(fm_text, 'model')
    if model and model not in VALID_MODELS:
        issues.append(f"Invalid model '{model}'. Valid models: {VALID_MODELS}")
    
    # Check for agent content
    body = content[match.end():].strip()
    if not body:
        issues.append("Agent file has no instructions after frontmatter")
    
    return issues

def main():
    try:
        data = json.load(sys.stdin)
    except:
        sys.exit(0)
    
    file_path = data.get('tool_input', {}).get('file_path', '')
    
    if not file_path:
        sys.exit(0)
    
    # Only validate agent files
    if '/.claude/agents/' not in file_path and '.claude/agents/' not in file_path:
        sys.exit(0)
    
    if not file_path.endswith('.md'):
        sys.exit(0)
    
    # Skip registry and archive
    skip_patterns = ['_registry', '.archive', '_index']
    if any(p in file_path.lower() for p in skip_patterns):
        sys.exit(0)
    
    issues = validate_agent(file_path)
    
    if issues:
        print(f"Fix agent definition in {file_path}:", file=sys.stderr)
        for issue in issues:
            print(f"  - {issue}", file=sys.stderr)
        sys.exit(2)
    
    print(f"✓ Agent validated: {file_path}")
    sys.exit(0)

if __name__ == '__main__':
    main()
