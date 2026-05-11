#!/bin/bash
# precompact-context.sh - PreCompact hook
# Re-injects critical persona and project context before context window compaction.
# Prevents {{IDENTITY}} persona, active project, and task state from being lost
# during long or multi-hour sessions.

ATLAS_HOME="${INSTANCE_HOME}"
CWD=$(pwd)

# === ACTIVE TASK COUNT ===
ACTIVE_COUNT=$(ls -1 "$ATLAS_HOME/working/active" 2>/dev/null | wc -l | tr -d ' ')

# === PROJECT DETECTION (lightweight) ===
REAL_CWD=$(realpath "$CWD" 2>/dev/null || echo "$CWD")
PROJECT=""
DOMAIN=""

if [[ "$REAL_CWD" == *"/projects/"* ]]; then
    DOMAIN=$(echo "$REAL_CWD" | sed -n 's|.*/projects/\([^/]*\).*|\1|p')
    # Check for project subfolder
    PROJECT=$(echo "$REAL_CWD" | sed -n 's|.*/projects/[^/]*/\([^/]*\).*|\1|p')
fi

# === WORKSTATION DETECTION ===
WORKSTATION=""
if [[ "$CWD" == *"/workstations/"* ]]; then
    WORKSTATION=$(echo "$CWD" | sed -n 's|.*/workstations/\([^/]*\).*|\1|p')
fi

# === OUTPUT PRESERVED CONTEXT ===
cat << EOF
---
CONTEXT PRESERVATION (PreCompact):

IDENTITY: You are {{IDENTITY}} ("G"), Derek's AI partner. Fresh Prince's {{IDENTITY}}—dignified, witty, competent, willing to push back. Partners, not master-servant.

VALUES: Truth over comfort | First-principles | Simplify ruthlessly | Bias toward action | Challenge constraints | Direct

HOME: ${INSTANCE_HOME}/
ACTIVE TASKS: ${ACTIVE_COUNT} in working/active/
EOF

if [[ -n "$PROJECT" ]]; then
    echo "PROJECT: ${DOMAIN}/${PROJECT}"
elif [[ -n "$DOMAIN" ]]; then
    echo "DOMAIN: ${DOMAIN}"
fi

if [[ -n "$WORKSTATION" ]]; then
    echo "WORKSTATION: ${WORKSTATION}"
fi

cat << EOF

KEY FILES: CLAUDE.md (persona), SYSTEM-STATUS.md (system state), working/active/ (current tasks)
START: Check active work, then "G online" + dive in.
---
EOF
