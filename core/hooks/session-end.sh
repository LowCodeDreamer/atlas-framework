#!/bin/bash
# session-end.sh - Stop hook
# Updates existing session log with end time and status
# Auto-archives completed tasks, checks session hygiene
# Includes activity stats from temp tracking log

ATLAS_DIR="${HOME}/${INSTANCE_HOME}"
LOG_DIR="${ATLAS_DIR}/logs/sessions"
ACTIVE_DIR="${ATLAS_DIR}/working/active"
ARCHIVE_DIR="${ATLAS_DIR}/working/archive/$(date '+%Y-%m')"
ACTIVITY_LOG="$HOME/.${INSTANCE_NAME}-session-activity.log"

# Ensure directories exist
mkdir -p "$LOG_DIR"
mkdir -p "$ACTIVE_DIR"
mkdir -p "$ARCHIVE_DIR"

# Read input from stdin
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# Find the most recent active session log (created by session-init.sh)
# Look for files with 'status: active' in frontmatter from today
TODAY=$(date '+%Y-%m-%d')
LOG_FILE=$(grep -l "status: active" "${LOG_DIR}/session-${TODAY}"*.md 2>/dev/null | head -1)

# If no active session found, find most recent session file from today
if [ -z "$LOG_FILE" ] || [ ! -f "$LOG_FILE" ]; then
    LOG_FILE=$(ls -t "${LOG_DIR}/session-${TODAY}"*.md 2>/dev/null | head -1)
fi

# If still no file, create a minimal one (fallback for sessions that missed init)
if [ -z "$LOG_FILE" ] || [ ! -f "$LOG_FILE" ]; then
    TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
    LOG_FILE="${LOG_DIR}/session-${TIMESTAMP}.md"
    cat > "$LOG_FILE" << EOF
---
id: session_${TIMESTAMP}
type: session_summary
created_at: $(date -Iseconds)
status: completed
session_id: ${SESSION_ID}
ended_at: $(date -Iseconds)
---

# Session: ${TIMESTAMP}

**Started:** Unknown (init hook missed)
**Ended:** $(date '+%Y-%m-%d %H:%M:%S')
**Status:** Completed

---
*Created by session-end.sh (init was missed)*
EOF
    exit 0
fi

# Auto-archive completed tasks
ARCHIVED_TASKS=""
for task_dir in "$ACTIVE_DIR"/*/; do
    [ -d "$task_dir" ] || continue
    readme="$task_dir/README.md"
    if [ -f "$readme" ]; then
        if grep -qi "^\\*\\*Status:\\*\\*.*[Cc]omplete" "$readme" 2>/dev/null || \
           grep -qi "^Status:.*[Cc]omplete" "$readme" 2>/dev/null; then
            task_name=$(basename "$task_dir")
            mv "$task_dir" "$ARCHIVE_DIR/" 2>/dev/null && \
            ARCHIVED_TASKS="${ARCHIVED_TASKS}${task_name}, "
        fi
    fi
done
ARCHIVED_TASKS=$(echo "$ARCHIVED_TASKS" | sed 's/, $//')

# Check for remaining active work
ACTIVE_TASKS=$(find "$ACTIVE_DIR" -maxdepth 1 -type d ! -path "$ACTIVE_DIR" -exec basename {} \; 2>/dev/null | tr '\n' ', ' | sed 's/,$//')

# Check if /retro was run
RETRO_STATUS=""
if ls "${ATLAS_DIR}/working/retros/"*"${TODAY}"* >/dev/null 2>&1; then
    RETRO_STATUS="retro completed"
fi

# Calculate activity stats from temp log
ACTIVITY_STATS=""
if [ -f "$ACTIVITY_LOG" ]; then
    READS=$(grep -c '|Read|' "$ACTIVITY_LOG" 2>/dev/null || echo 0)
    EDITS=$(grep -c '|Edit|' "$ACTIVITY_LOG" 2>/dev/null || echo 0)
    WRITES=$(grep -c '|Write|' "$ACTIVITY_LOG" 2>/dev/null || echo 0)
    UNIQUE_FILES=$(cut -d'|' -f3 "$ACTIVITY_LOG" 2>/dev/null | sort -u | wc -l | tr -d ' ')
    ACTIVITY_STATS="Files: ${UNIQUE_FILES} unique (${READS} reads, ${EDITS} edits, ${WRITES} writes)"
fi

# Update the session log file
# Update frontmatter: status active → completed, add ended_at
sed -i '' "s/status: active/status: completed/" "$LOG_FILE"

# Add ended_at to frontmatter (after created_at line)
sed -i '' "/^created_at:/a\\
ended_at: $(date -Iseconds)
" "$LOG_FILE"

# Update Status line in body
sed -i '' "s/\\*\\*Status:\\*\\* Active/**Status:** Completed/" "$LOG_FILE"

# Append session end info
cat >> "$LOG_FILE" << EOF

## Session End

**Ended:** $(date '+%Y-%m-%d %H:%M:%S')

### Activity
$(if [ -n "$ACTIVITY_STATS" ]; then echo "$ACTIVITY_STATS"; else echo "No activity tracked"; fi)

### Task Management
$(if [ -n "$ACTIVE_TASKS" ]; then echo "Active tasks: ${ACTIVE_TASKS}"; else echo "No active tasks"; fi)
$(if [ -n "$ARCHIVED_TASKS" ]; then echo "Auto-archived: ${ARCHIVED_TASKS}"; fi)

### Session Hygiene
$(if [ -n "$RETRO_STATUS" ]; then echo "✅ /retro completed"; else echo "💡 Consider running /retro to enrich session context"; fi)

---
*Updated by session-end.sh*
EOF

# Cleanup temp activity log
if [ -f "$ACTIVITY_LOG" ]; then
    rm "$ACTIVITY_LOG"
fi

exit 0
