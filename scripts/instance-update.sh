#!/bin/bash
# instance-update.sh — pull framework updates into an existing instance
# Updates: .claude/agents/, .claude/commands/, .claude/skills/, hooks/, scripts/
# Does NOT touch: projects/, workstations/, services/, expertise/, working/, system/, root files
#
# Usage: instance-update.sh [--source <framework-path>] [--dry-run] [--force]
#   --source     Override framework source (default: detect from script location or $FRAMEWORK_HOME)
#   --dry-run    Show what would change without applying
#   --force      Overwrite even when local file has been modified

set -euo pipefail

INSTANCE_HOME="${INSTANCE_HOME:-$(pwd)}"
SOURCE=""
DRY_RUN="no"
FORCE="no"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source) SOURCE="$2"; shift 2 ;;
        --dry-run) DRY_RUN="yes"; shift ;;
        --force) FORCE="yes"; shift ;;
        -h|--help) sed -n '2,11p' "$0" | sed 's/^# *//'; exit 0 ;;
        *) echo "ERROR: unknown arg: $1"; exit 1 ;;
    esac
done

# Detect framework source
if [[ -z "$SOURCE" ]]; then
    if [[ -n "${FRAMEWORK_HOME:-}" ]]; then
        SOURCE="$FRAMEWORK_HOME"
    elif [[ -d "$INSTANCE_HOME/.framework-source" ]]; then
        SOURCE="$INSTANCE_HOME/.framework-source"
    else
        echo "ERROR: framework source not found. Set FRAMEWORK_HOME or pass --source"
        exit 1
    fi
fi

[[ ! -d "$SOURCE/core" ]] && { echo "ERROR: $SOURCE doesn't look like a framework repo (no core/ dir)"; exit 1; }

# === Sync ===
echo "=== Updating instance $INSTANCE_HOME from $SOURCE ==="
echo "  Mode: ${DRY_RUN:+DRY RUN }${FORCE:+FORCE }${DRY_RUN:-}${FORCE:-normal}"
echo ""

RSYNC_FLAGS="-rv"
[[ "$DRY_RUN" == "yes" ]] && RSYNC_FLAGS="$RSYNC_FLAGS --dry-run"
[[ "$FORCE" != "yes" ]] && RSYNC_FLAGS="$RSYNC_FLAGS --update"

echo "→ .claude/agents/"
rsync $RSYNC_FLAGS "$SOURCE/core/agents/" "$INSTANCE_HOME/.claude/agents/"

echo "→ .claude/commands/"
rsync $RSYNC_FLAGS "$SOURCE/core/commands/" "$INSTANCE_HOME/.claude/commands/"

echo "→ .claude/skills/"
rsync $RSYNC_FLAGS "$SOURCE/core/skills/" "$INSTANCE_HOME/.claude/skills/"

echo "→ hooks/"
rsync $RSYNC_FLAGS --exclude="*.log" "$SOURCE/core/hooks/" "$INSTANCE_HOME/hooks/"
chmod +x "$INSTANCE_HOME/hooks/"*.sh 2>/dev/null || true
chmod +x "$INSTANCE_HOME/hooks/validators/"*.py 2>/dev/null || true

echo "→ scripts/"
rsync $RSYNC_FLAGS --exclude="instance-init.sh" "$SOURCE/scripts/" "$INSTANCE_HOME/scripts/"
chmod +x "$INSTANCE_HOME/scripts/"*.sh 2>/dev/null || true

echo ""
echo "=== Update complete ==="
echo "  Instance content (projects/, workstations/, services/, expertise/, working/, system/) untouched."
[[ "$DRY_RUN" == "yes" ]] && echo "  (Dry run — no files actually changed.)"
