#!/bin/bash
# track-session-activity.sh - PostToolUse hook
# Logs file operations (Read/Edit/Write) to temp file for fast session enrichment
# Cleaned up by session-end.sh

ACTIVITY_LOG="$HOME/.${INSTANCE_NAME}-session-activity.log"

# Read tool input from stdin
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // "{}"')

# Only track file operations
case "$TOOL_NAME" in
    Read|Edit|Write)
        FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
        if [ -n "$FILE_PATH" ]; then
            TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')
            # Format: timestamp|tool|path
            echo "${TIMESTAMP}|${TOOL_NAME}|${FILE_PATH}" >> "$ACTIVITY_LOG"
        fi
        ;;
esac

# Always exit success - don't block operations
exit 0
