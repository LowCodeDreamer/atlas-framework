#!/bin/bash
# log-commands.sh - PreToolUse hook for Bash
# Logs all bash commands with timestamps

ATLAS_DIR="${HOME}/${INSTANCE_HOME}"
LOG_FILE="${ATLAS_DIR}/logs/bash-commands.log"

# Ensure log directory exists
mkdir -p "${ATLAS_DIR}/logs"

# Read input from stdin
INPUT=$(cat)

# Extract command using jq
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // "unknown"')
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // "no description"')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Log the command
echo "[$TIMESTAMP] $COMMAND | $DESCRIPTION" >> "$LOG_FILE"

# Allow execution (exit 0)
exit 0
