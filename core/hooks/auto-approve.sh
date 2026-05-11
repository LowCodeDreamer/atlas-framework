#!/bin/bash
# Auto-approves safe read-only operations within Atlas
# Hook event: PermissionRequest

set -e

# Read hook input from stdin
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')

# Extract file paths depending on tool
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .path // ""')

ATLAS_DIR="$HOME/${INSTANCE_HOME}"

# Helper: check if path is within Atlas
is_atlas_path() {
    local path="$1"
    [[ "$path" == "$ATLAS_DIR"* ]] || [[ "$path" == "${INSTANCE_HOME}"* ]]
}

# Helper: output allow decision
allow() {
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow"
    }
  }
}
EOF
    exit 0
}

# Auto-approve safe read-only tools
case "$TOOL_NAME" in
    Read)
        # Auto-approve reading Atlas files
        if is_atlas_path "$FILE_PATH"; then
            allow
        fi
        ;;
    Glob)
        # Auto-approve glob searches within Atlas
        GLOB_PATH=$(echo "$TOOL_INPUT" | jq -r '.path // ""')
        if [ -z "$GLOB_PATH" ] || is_atlas_path "$GLOB_PATH"; then
            allow
        fi
        ;;
    Grep)
        # Auto-approve grep searches within Atlas
        GREP_PATH=$(echo "$TOOL_INPUT" | jq -r '.path // ""')
        if [ -z "$GREP_PATH" ] || is_atlas_path "$GREP_PATH"; then
            allow
        fi
        ;;
    Task)
        # Auto-approve spawning subagents (they have their own restrictions)
        allow
        ;;
esac

# Default: don't override, let normal permission flow handle it
exit 0
