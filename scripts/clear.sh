#!/bin/bash
# Clear all workstation mounts
# Usage: clear.sh

INSTANCE_HOME="${INSTANCE_HOME:-$(pwd)}"
WORKSTATIONS_DIR="$INSTANCE_HOME/workstations"

cleared=0
for ws_dir in "$WORKSTATIONS_DIR"/*/; do
  ws=$(basename "$ws_dir")
  mount_point="$ws_dir/active-project"

  if [ -L "$mount_point" ]; then
    rm "$mount_point"
    mkdir -p "$mount_point"
    touch "$mount_point/.gitkeep"
    cleared=$((cleared + 1))
  fi
done

if [ $cleared -eq 0 ]; then
  echo "Nothing mounted."
else
  echo "Cleared $cleared workstation(s)."
fi
