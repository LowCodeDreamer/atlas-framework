#!/bin/bash
# Show mount status of all workstations
# Usage: status.sh

INSTANCE_HOME="${INSTANCE_HOME:-$(pwd)}"
WORKSTATIONS_DIR="$INSTANCE_HOME/workstations"

echo "Atlas Workstation Status"
echo "========================"
echo ""

for ws_dir in "$WORKSTATIONS_DIR"/*/; do
  ws=$(basename "$ws_dir")
  mount_point="$ws_dir/active-project"

  if [ -L "$mount_point" ]; then
    target=$(readlink "$mount_point")
    # Make target relative to projects dir for cleaner display
    relative="${target#$INSTANCE_HOME/projects/}"
    printf "  %-18s → %s\n" "$ws" "$relative"
  else
    printf "  %-18s   (empty)\n" "$ws"
  fi
done

echo ""
