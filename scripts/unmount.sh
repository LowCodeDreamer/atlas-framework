#!/bin/bash
# Unmount a project from a workstation
# Usage: unmount.sh <workstation>
# Example: unmount.sh web-dev

set -euo pipefail

INSTANCE_HOME="${INSTANCE_HOME:-$(pwd)}"
WORKSTATIONS_DIR="$INSTANCE_HOME/workstations"

if [ $# -ne 1 ]; then
  echo "Usage: unmount.sh <workstation>"
  exit 1
fi

WORKSTATION="$1"
MOUNT_POINT="$WORKSTATIONS_DIR/$WORKSTATION/active-project"

# Validate workstation exists
if [ ! -d "$WORKSTATIONS_DIR/$WORKSTATION" ]; then
  echo "Error: Workstation not found: $WORKSTATION"
  exit 1
fi

# Check if mounted
if [ -L "$MOUNT_POINT" ]; then
  CURRENT=$(readlink "$MOUNT_POINT")
  rm "$MOUNT_POINT"
  mkdir -p "$MOUNT_POINT"
  touch "$MOUNT_POINT/.gitkeep"
  echo "Unmounted: $CURRENT from $WORKSTATION"
else
  echo "Nothing mounted in $WORKSTATION"
fi
