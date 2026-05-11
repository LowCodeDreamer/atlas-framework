#!/bin/bash
# check-file-exists.sh - PreToolUse hook for Read|Edit
# Warns when attempting to read/edit non-existent files

# Read input from stdin
INPUT=$(cat)

# Extract file path and tool name
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Skip if no file path provided
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Expand ~ to home directory
EXPANDED_PATH="${FILE_PATH/#\~/$HOME}"

# Check if file exists
if [ ! -f "$EXPANDED_PATH" ]; then
    # Output warning message (this appears in Claude's context)
    echo "⚠️ File does not exist: $FILE_PATH"
    echo "Consider using 'ls' or Glob to verify the path first."

    # For Edit, this is always an error - block it
    if [ "$TOOL_NAME" = "Edit" ]; then
        echo "BLOCKED: Cannot Edit non-existent file. Use Write to create new files." >&2
        exit 2
    fi

    # For Read, warn but don't block (tool will return its own error)
    # Exit 0 allows the Read to proceed and fail naturally
fi

exit 0
