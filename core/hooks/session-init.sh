#!/bin/bash
# session-init.sh - Start hook
# Creates session log stub with frontmatter at session start
# IDEMPOTENT: Only creates if no active session exists

ATLAS_DIR="${HOME}/${INSTANCE_HOME}"
LOG_DIR="${ATLAS_DIR}/logs/sessions"
TODAY=$(date '+%Y-%m-%d')

# Ensure directory exists
mkdir -p "$LOG_DIR"

# Check if an active session already exists for today
EXISTING_ACTIVE=$(grep -l "status: active" "${LOG_DIR}/session-${TODAY}"*.md 2>/dev/null | head -1)

if [ -n "$EXISTING_ACTIVE" ]; then
    # Active session exists, skip creation
    exit 0
fi

# Read input from stdin (session metadata)
INPUT=$(cat)
# Use environment variable if available, otherwise try stdin, fallback to unknown
SESSION_ID="${CLAUDE_SESSION_ID:-$(echo "$INPUT" | jq -r '.session_id // "unknown"')}"
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')

TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_FILE="${LOG_DIR}/session-${TIMESTAMP}.md"

# Create session log stub with frontmatter
cat > "$LOG_FILE" << EOF
---
id: session_${TIMESTAMP}
type: session_summary
created_at: $(date -Iseconds)
status: active
session_id: ${SESSION_ID}
---

# Session: ${TIMESTAMP}

**Started:** $(date '+%Y-%m-%d %H:%M:%S')
**Working Directory:** ${CWD}
**Status:** Active

---
*Stub created at session start. Run /retro to enrich with domains and files.*
EOF

exit 0
