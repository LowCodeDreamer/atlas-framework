#!/bin/bash
# Logs subagent spawns to session log
# Hook events: SubagentStart, SubagentStop

LOG_DIR="$HOME/${INSTANCE_HOME}/logs/sessions"
mkdir -p "$LOG_DIR"

# Get today's session log
SESSION_LOG="$LOG_DIR/session-$(date +%Y-%m-%d).log"

# Read hook input from stdin
INPUT=$(cat)

# Parse JSON fields
EVENT_TYPE=$(echo "$INPUT" | jq -r '.hook_event_type // "unknown"')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
PARENT_ID=$(echo "$INPUT" | jq -r '.parent_agent_id // "root"')
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.subagent_type // "unknown"')
DESCRIPTION=$(echo "$INPUT" | jq -r '.description // ""')

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ "$EVENT_TYPE" = "SubagentStart" ]; then
    echo "[$TIMESTAMP] SUBAGENT_START: $SUBAGENT_TYPE ($AGENT_ID)" >> "$SESSION_LOG"
    echo "  Parent: $PARENT_ID" >> "$SESSION_LOG"
    echo "  Task: $DESCRIPTION" >> "$SESSION_LOG"
elif [ "$EVENT_TYPE" = "SubagentStop" ]; then
    echo "[$TIMESTAMP] SUBAGENT_STOP: $AGENT_ID" >> "$SESSION_LOG"
fi

# Always succeed - logging is observational
exit 0
