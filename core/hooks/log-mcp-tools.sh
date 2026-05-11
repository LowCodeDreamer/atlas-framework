#!/bin/bash
# log-mcp-tools.sh - PreToolUse hook for MCP tools (async)
# Lightweight audit log for n8n, Supabase, ClickUp, Chrome MCP calls.
# Tracks usage patterns and aids troubleshooting.

ATLAS_HOME="${INSTANCE_HOME}"
LOG_FILE="${ATLAS_HOME}/logs/mcp-tools.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Read hook input from stdin
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')

# Extract the MCP server name (e.g., "n8n-builder" from "mcp__n8n-builder__get_node")
MCP_SERVER=$(echo "$TOOL_NAME" | sed -n 's/^mcp__\([^_]*\)__.*/\1/p')
MCP_ACTION=$(echo "$TOOL_NAME" | sed -n 's/^mcp__[^_]*__//p')

TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')

# Append structured log line
echo "${TIMESTAMP}|${MCP_SERVER}|${MCP_ACTION}|${TOOL_NAME}" >> "$LOG_FILE"

exit 0
