#!/usr/bin/env python3
"""
json_output_validator.py - Validates JSON output from judge analysts.

This validator is meant to be called from a prompt-based hook or directly.
It checks that analyst output has the required fields.

Usage (command line):
  python3 json_output_validator.py <analyst_type> '<json_output>'

Usage (prompt-based hook):
  The prompt hook should instruct the LLM to validate the output structure.
  This script is provided as a reference implementation.

Exit Codes:
  0 = Valid
  1 = Invalid (prints JSON with decision and reason)
"""
import json
import sys

# Required fields for each analyst type
REQUIRED_FIELDS = {
    'tool': ['analyst', 'sessions_analyzed', 'key_metrics', 'findings', 'recommendations'],
    'error': ['analyst', 'sessions_analyzed', 'key_metrics', 'findings', 'recommendations'],
    'session': ['analyst', 'sessions_analyzed', 'key_metrics', 'findings', 'recommendations'],
    'component': ['analyst', 'sessions_analyzed', 'key_metrics', 'findings', 'recommendations'],
}

def validate_analyst_output(output: str, analyst_type: str) -> tuple[bool, str]:
    """
    Validate analyst JSON output.
    Returns (is_valid, message).
    """
    # Try to parse JSON
    try:
        data = json.loads(output)
    except json.JSONDecodeError as e:
        return False, f"Invalid JSON: {e}"
    
    if not isinstance(data, dict):
        return False, "Output must be a JSON object"
    
    # Get required fields for this analyst type
    required = REQUIRED_FIELDS.get(analyst_type, REQUIRED_FIELDS['tool'])
    
    # Check for missing fields
    missing = [f for f in required if f not in data]
    if missing:
        return False, f"Missing required fields: {missing}"
    
    # Type validations
    if not isinstance(data.get('sessions_analyzed'), (int, float)):
        return False, "sessions_analyzed must be a number"
    
    if not isinstance(data.get('findings'), list):
        return False, "findings must be an array"
    
    if not isinstance(data.get('recommendations'), list):
        return False, "recommendations must be an array"
    
    if not isinstance(data.get('key_metrics'), dict):
        return False, "key_metrics must be an object"
    
    # Check analyst field matches expected type
    if data.get('analyst') != analyst_type:
        return False, f"analyst field should be '{analyst_type}', got '{data.get('analyst')}'"
    
    return True, "Valid analyst output"

def main():
    if len(sys.argv) < 3:
        print("Usage: json_output_validator.py <analyst_type> '<json_output>'")
        print("  analyst_type: tool, error, session, or component")
        print("  json_output: JSON string to validate")
        sys.exit(1)
    
    analyst_type = sys.argv[1]
    output = sys.argv[2]
    
    # Handle potential shell escaping issues
    if output.startswith("'") and output.endswith("'"):
        output = output[1:-1]
    
    valid, message = validate_analyst_output(output, analyst_type)
    
    # Output decision in hook-compatible format
    result = {
        "decision": "approve" if valid else "block",
        "reason": message
    }
    print(json.dumps(result))
    
    sys.exit(0 if valid else 1)

if __name__ == '__main__':
    main()
