#!/usr/bin/env python3
"""
csv_validator.py - Validates CSV file structure.

Generic validator for any CSV processing agents.
Checks that the file can be parsed as valid CSV with consistent columns.

Hook Usage:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/hooks/validators/csv_validator.py"

Exit Codes:
  0 = Valid (or not a CSV file)
  2 = Invalid (blocks and feeds back to Claude)
"""
import json
import sys
import csv
from pathlib import Path

def validate_csv(file_path: str) -> list[str]:
    """Validate a CSV file and return list of issues."""
    issues = []
    
    try:
        content = Path(file_path).read_text()
    except FileNotFoundError:
        return [f"File not found: {file_path}"]
    except Exception as e:
        return [f"Cannot read file: {e}"]
    
    if not content.strip():
        return ["CSV file is empty"]
    
    try:
        # Try to parse as CSV
        lines = content.splitlines()
        reader = csv.reader(lines)
        rows = list(reader)
        
        if not rows:
            issues.append("CSV file has no rows")
            return issues
        
        # Check header row
        header = rows[0]
        if not header:
            issues.append("CSV has empty header row")
            return issues
        
        if not all(h.strip() for h in header):
            empty_cols = [i for i, h in enumerate(header) if not h.strip()]
            issues.append(f"Header has empty column names at positions: {empty_cols}")
        
        # Check for duplicate headers
        seen = set()
        duplicates = []
        for h in header:
            if h in seen:
                duplicates.append(h)
            seen.add(h)
        if duplicates:
            issues.append(f"Duplicate column names: {duplicates}")
        
        # Check consistent column count
        col_count = len(header)
        inconsistent_rows = []
        
        for i, row in enumerate(rows[1:], start=2):
            if len(row) != col_count:
                inconsistent_rows.append(f"Row {i}: {len(row)} cols (expected {col_count})")
                if len(inconsistent_rows) >= 5:
                    inconsistent_rows.append("... (more errors truncated)")
                    break
        
        if inconsistent_rows:
            issues.append("Inconsistent column counts:")
            issues.extend([f"  {r}" for r in inconsistent_rows])
        
    except csv.Error as e:
        issues.append(f"CSV parsing error: {e}")
    
    return issues

def main():
    try:
        data = json.load(sys.stdin)
    except:
        sys.exit(0)
    
    file_path = data.get('tool_input', {}).get('file_path', '')
    
    if not file_path:
        sys.exit(0)
    
    # Only validate CSV files
    if not file_path.lower().endswith('.csv'):
        sys.exit(0)
    
    issues = validate_csv(file_path)
    
    if issues:
        print(f"Resolve CSV issues in {file_path}:", file=sys.stderr)
        for issue in issues:
            print(f"  • {issue}", file=sys.stderr)
        sys.exit(2)
    
    print(f"✓ CSV validated: {file_path}")
    sys.exit(0)

if __name__ == '__main__':
    main()
