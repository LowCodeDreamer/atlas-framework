#!/bin/bash
# track-errors.sh - PostToolUseFailure hook (async)
# Logs tool failures to logs/tool-errors.log for pattern analysis.
# Captures: timestamp, tool name, error snippet, file path (if applicable).

ATLAS_HOME="${INSTANCE_HOME}"
LOG_FILE="${ATLAS_HOME}/logs/tool-errors.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Read hook input from stdin
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // "{}"')
ERROR=$(echo "$INPUT" | jq -r '.tool_error // .error // "no error captured"' | head -c 200)
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // .command // "n/a"' | head -c 150)

TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')

# Append structured log line
echo "${TIMESTAMP}|${TOOL_NAME}|${FILE_PATH}|${ERROR}" >> "$LOG_FILE"

exit 0
