#!/bin/bash
# inject-context.sh — Smart context injection with manifest support
# Loads: identity (~50 tokens) + project context (variable based on manifest)
#
# Configuration loaded from ${INSTANCE_HOME}/system/identity.env (created by instance-init.sh):
#   INSTANCE_NAME           # short name (e.g., "eno", "atlas")
#   INSTANCE_IDENTITY       # one-line role/identity statement
#   INSTANCE_VALUES         # pipe-separated value list
#   INSTANCE_GREETING       # what to say at session start

INSTANCE_HOME="${INSTANCE_HOME:-$(pwd)}"
CWD=$(pwd)

# Load instance identity
if [[ -f "$INSTANCE_HOME/system/identity.env" ]]; then
    # shellcheck disable=SC1091
    source "$INSTANCE_HOME/system/identity.env"
fi

INSTANCE_NAME="${INSTANCE_NAME:-instance}"
INSTANCE_IDENTITY="${INSTANCE_IDENTITY:-You are operating in this instance.}"
INSTANCE_VALUES="${INSTANCE_VALUES:-Truth over comfort | First-principles | Direct}"
INSTANCE_GREETING="${INSTANCE_GREETING:-Online}"

# === PROJECT DETECTION ===
PROJECT=""
PROJECT_PATH=""
MANIFEST=""
WORKSPACE=""
WORKSTATION=""

REAL_CWD=$(realpath "$CWD" 2>/dev/null || echo "$CWD")

# Look for _manifest.md in current dir or parents (within projects/)
check_dir="$REAL_CWD"
while [[ "$check_dir" == *"/projects/"* ]]; do
    if [[ -f "$check_dir/_manifest.md" ]]; then
        PROJECT_PATH="$check_dir"
        MANIFEST="$check_dir/_manifest.md"
        PROJECT=$(basename "$check_dir")
        break
    fi
    check_dir=$(dirname "$check_dir")
done

# === WORKSTATION DETECTION ===
if [[ "$CWD" == *"/workstations/"* ]]; then
    WORKSTATION=$(echo "$CWD" | sed -n 's|.*/workstations/\([^/]*\).*|\1|p')
fi

# === SERVICE DETECTION ===
SERVICE=""
if [[ "$REAL_CWD" == *"/services/"* ]]; then
    SERVICE=$(echo "$REAL_CWD" | sed -n 's|.*/services/\([^/]*\).*|\1|p')
fi

# === DOMAIN DETECTION ===
DOMAIN=""
if [[ -n "$PROJECT_PATH" ]]; then
    WORKSPACE=$(echo "$PROJECT_PATH" | sed -n 's|.*/projects/\([^/]*\)/.*|\1|p')
    DOMAIN="$WORKSPACE"
elif [[ "$REAL_CWD" == *"/projects/"* ]]; then
    WORKSPACE=$(echo "$REAL_CWD" | sed -n 's|.*/projects/\([^/]*\).*|\1|p')
    DOMAIN="$WORKSPACE"
fi

# === MANIFEST PARSING (if present) ===
PROJECT_TYPE=""
PROJECT_PHASE=""
CONTEXT_BUDGET="standard"
STACK=""

if [[ -n "$MANIFEST" ]]; then
    PROJECT_TYPE=$(grep -m1 "^type:" "$MANIFEST" 2>/dev/null | sed 's/type: *//')
    PROJECT_PHASE=$(grep -m1 "^phase:" "$MANIFEST" 2>/dev/null | sed 's/phase: *//')
    CONTEXT_BUDGET=$(grep -m1 "^context_budget:" "$MANIFEST" 2>/dev/null | sed 's/context_budget: *//')
    [[ -z "$CONTEXT_BUDGET" ]] && CONTEXT_BUDGET="standard"

    STACK=$(awk '/^stack:/{flag=1; next} /^[a-z]/{flag=0} flag && /^ *- /{gsub(/^ *- /,""); printf "%s, ", $0}' "$MANIFEST" 2>/dev/null | sed 's/, $//')
fi

# === ACTIVE TASK COUNT ===
ACTIVE_COUNT=$(ls -1 "$INSTANCE_HOME/working/active" 2>/dev/null | wc -l | tr -d ' ')

# === OUTPUT ===
INSTANCE_NAME_UPPER=$(echo "$INSTANCE_NAME" | tr '[:lower:]' '[:upper:]')
cat << EOF
---
${INSTANCE_NAME_UPPER}: ${INSTANCE_IDENTITY}

VALUES: ${INSTANCE_VALUES}

EOF

# Context badge — workstation, service, project, or workspace
if [[ -n "$WORKSTATION" ]]; then
    echo "WORKSTATION: $WORKSTATION"
    [[ -L "$INSTANCE_HOME/workstations/$WORKSTATION/active-project" ]] && \
        echo "MOUNTED: $(readlink "$INSTANCE_HOME/workstations/$WORKSTATION/active-project")"
    echo ""
fi

if [[ -n "$SERVICE" ]]; then
    cat << EOF
SERVICE: $SERVICE | Check: services/${SERVICE}/CLAUDE.md or _manifest.md

EOF
fi

if [[ -n "$PROJECT" ]]; then
    cat << EOF
PROJECT: $WORKSPACE/$PROJECT [${PROJECT_TYPE:-?} | ${PROJECT_PHASE:-?}]
${STACK:+STACK: $STACK}
CONTEXT: $CONTEXT_BUDGET | Read manifest for full details

EOF
elif [[ -n "$WORKSPACE" ]]; then
    cat << EOF
WORKSPACE: $WORKSPACE | Check: projects/${WORKSPACE}/_domain.md

EOF
elif [[ -n "$DOMAIN" ]]; then
    cat << EOF
DOMAIN: $DOMAIN

EOF
fi

cat << EOF
ACTIVE: ${ACTIVE_COUNT} task(s) in working/active/
HOME: ${INSTANCE_HOME}/

Start: "${INSTANCE_GREETING}" + dive in.
---
EOF
