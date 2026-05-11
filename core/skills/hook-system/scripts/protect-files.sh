#!/bin/bash
# protect-files.sh - PreToolUse hook for Edit/Write
# Blocks modifications to protected files

# Read input from stdin
INPUT=$(cat)

# Extract file path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# Protected patterns
PROTECTED_PATTERNS=(
  ".env"
  ".env.local"
  "secrets"
  "credentials"
  ".git/config"
  "id_rsa"
  "id_ed25519"
)

# Check if file matches protected patterns
for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "BLOCKED: Cannot modify protected file: $FILE_PATH" >&2
    exit 2
  fi
done

# Allow execution
exit 0
