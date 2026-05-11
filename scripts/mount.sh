#!/bin/bash
# Mount a project into a workstation
# Usage: mount.sh <project-path> <workstation>
#        mount.sh here <workstation>     (detect project from CWD)
#        mount.sh <project-path> here    (detect workstation from CWD)
# Example: mount.sh eno/eno-website web-dev

set -euo pipefail

INSTANCE_HOME="${INSTANCE_HOME:-$(pwd)}"
PROJECTS_DIR="$INSTANCE_HOME/projects"
WORKSTATIONS_DIR="$INSTANCE_HOME/workstations"

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "Usage: mount.sh <project-path> <workstation>"
  echo "       mount.sh here <workstation>"
  echo "       mount.sh <project-path> here"
  exit 1
fi

# === Resolve "here" for project path ===
PROJECT_PATH="$1"
if [ "$PROJECT_PATH" = "here" ]; then
  REAL_CWD=$(realpath "$(pwd)")
  if [[ "$REAL_CWD" == "$PROJECTS_DIR"/* ]]; then
    PROJECT_PATH="${REAL_CWD#$PROJECTS_DIR/}"
  else
    echo "Error: Not inside projects/. Can't detect project from $(pwd)"
    exit 1
  fi
fi

# === Resolve "here" for workstation ===
WORKSTATION="${2:-}"
if [ -z "$WORKSTATION" ]; then
  echo "Usage: mount.sh <project-path> <workstation>"
  exit 1
fi
if [ "$WORKSTATION" = "here" ]; then
  CWD=$(pwd)
  if [[ "$CWD" == "$WORKSTATIONS_DIR"/* ]]; then
    WORKSTATION=$(echo "$CWD" | sed -n "s|$WORKSTATIONS_DIR/\([^/]*\).*|\1|p")
  else
    echo "Error: Not inside workstations/. Can't detect workstation from $(pwd)"
    exit 1
  fi
fi

FULL_PROJECT_PATH="$PROJECTS_DIR/$PROJECT_PATH"
MOUNT_POINT="$WORKSTATIONS_DIR/$WORKSTATION/active-project"

# Validate project exists
if [ ! -d "$FULL_PROJECT_PATH" ]; then
  echo "Error: Project not found: $FULL_PROJECT_PATH"
  exit 1
fi

# Validate workstation exists
if [ ! -d "$WORKSTATIONS_DIR/$WORKSTATION" ]; then
  echo "Error: Workstation not found: $WORKSTATION"
  echo "Available workstations:"
  ls -1 "$WORKSTATIONS_DIR"
  exit 1
fi

# Auto-unmount if already mounted
if [ -L "$MOUNT_POINT" ]; then
  CURRENT=$(readlink "$MOUNT_POINT")
  echo "Unmounting current project: $CURRENT"
  rm "$MOUNT_POINT"
elif [ -d "$MOUNT_POINT" ]; then
  # It's a real directory (with .gitkeep), replace it
  rm -rf "$MOUNT_POINT"
fi

# Create symlink
ln -s "$FULL_PROJECT_PATH" "$MOUNT_POINT"
echo "Mounted: $PROJECT_PATH → $WORKSTATION"
echo "Workstation: $WORKSTATIONS_DIR/$WORKSTATION/"
