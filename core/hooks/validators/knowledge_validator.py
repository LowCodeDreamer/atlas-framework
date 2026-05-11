#!/usr/bin/env python3
"""
knowledge_validator.py - Validates knowledge files have proper frontmatter and structure.

Hook Usage:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/hooks/validators/knowledge_validator.py"

Exit Codes:
  0 = Valid (or not a knowledge file)
  2 = Invalid (blocks and feeds back to Claude)
"""
import json
import sys
import re
from pathlib import Path

VALID_TYPES = [
    'knowledge', 'reference', 'insight', 'decision', 'log',
    'session_summary', 'retro', 'expertise', 'schema', 'persona',
    'status', 'registry', 'index'
]

def validate_knowledge_file(file_path: str) -> list[str]:
    """Validate a knowledge file and return list of issues."""
    issues = []
    
    try:
        content = Path(file_path).read_text()
    except FileNotFoundError:
        return [f"File not found: {file_path}"]
    except Exception as e:
        return [f"Cannot read file: {e}"]
    
    # Check for YAML frontmatter
    if not content.startswith('---'):
        issues.append("Missing YAML frontmatter (file must start with ---)")
        return issues
    
    # Extract frontmatter
    match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not match:
        issues.append("Invalid frontmatter format (missing closing ---)")
        return issues
    
    fm_text = match.group(1)
    
    # Simple field extraction (avoid YAML dependency)
    def get_field(text, field):
        m = re.search(rf'^{field}:\s*(.+)$', text, re.MULTILINE)
        return m.group(1).strip().strip('"\'') if m else None
    
    # Required fields
    file_id = get_field(fm_text, 'id')
    file_type = get_field(fm_text, 'type')
    
    if not file_id:
        issues.append("Missing required frontmatter field: id")
    
    if not file_type:
        issues.append("Missing required frontmatter field: type")
    
    # Validate type if present
    if file_type and file_type not in VALID_TYPES:
        issues.append(f"Invalid type '{file_type}'. Valid types: {VALID_TYPES}")
    
    # Validate ID format (should be lowercase with underscores)
    if file_id and not re.match(r'^[a-z][a-z0-9_-]*$', file_id):
        issues.append(f"ID '{file_id}' should be lowercase alphanumeric with underscores/hyphens")
    
    # Check for content after frontmatter
    body = content[match.end():].strip()
    if not body:
        issues.append("File has no content after frontmatter")
    
    return issues

def main():
    # Read hook input from stdin
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        # No valid input, skip validation
        sys.exit(0)
    except Exception:
        sys.exit(0)
    
    # Extract file path from tool input
    file_path = data.get('tool_input', {}).get('file_path', '')
    
    if not file_path:
        # No file path in input
        sys.exit(0)
    
    # Only validate knowledge files
    # Match: knowledge/, expertise/, or files with knowledge-related names
    knowledge_paths = ['/knowledge/', 'knowledge/', '/expertise/', 'expertise/']
    is_knowledge_file = any(p in file_path for p in knowledge_paths)
    
    if not is_knowledge_file:
        # Not a knowledge file, skip validation
        sys.exit(0)
    
    # Skip index and registry files
    skip_patterns = ['_INDEX', '_REGISTRY', '_index', '_registry', '.archive']
    if any(p in file_path for p in skip_patterns):
        sys.exit(0)
    
    # Validate the file
    issues = validate_knowledge_file(file_path)
    
    if issues:
        # Output errors to stderr (feeds back to Claude)
        print(f"Fix knowledge file issues in {file_path}:", file=sys.stderr)
        for issue in issues:
            print(f"  • {issue}", file=sys.stderr)
        sys.exit(2)  # Exit 2 = block and provide feedback
    
    # Success
    print(f"✓ Validated: {file_path}")
    sys.exit(0)

if __name__ == '__main__':
    main()
