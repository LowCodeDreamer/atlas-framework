#!/bin/bash
# notify.sh - Notification hook
# Sends desktop notification when Claude needs attention
#
# Resolves title from $INSTANCE_IDENTITY (sourced from system/identity.env)
# Falls back to render-time {{IDENTITY}} placeholder if env not set
# Final fallback: "Claude"

# Resolve INSTANCE_HOME so we can source identity.env at runtime
INSTANCE_HOME="${INSTANCE_HOME:-}"
if [[ -z "$INSTANCE_HOME" ]]; then
  d=$(pwd)
  while [[ "$d" != "/" ]] && [[ -n "$d" ]]; do
    if [[ -f "$d/system/identity.env" ]]; then INSTANCE_HOME="$d"; break; fi
    d=$(dirname "$d")
  done
fi
[[ -f "$INSTANCE_HOME/system/identity.env" ]] && source "$INSTANCE_HOME/system/identity.env"

# Title resolution: runtime INSTANCE_NAME (capitalized) > placeholder > generic
if [[ -n "${INSTANCE_NAME:-}" ]]; then
  TITLE="$(tr '[:lower:]' '[:upper:]' <<<"${INSTANCE_NAME:0:1}")${INSTANCE_NAME:1}"
else
  TITLE="{{IDENTITY}}"
  [[ "$TITLE" == "{{IDENTITY}}" ]] && TITLE="Claude"
fi

# Read input from stdin
INPUT=$(cat)

# Extract message
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude needs your attention"')

# macOS notification
if [[ "$OSTYPE" == "darwin"* ]]; then
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"Ping\""
# Linux notification (requires notify-send)
elif command -v notify-send &> /dev/null; then
  notify-send "$TITLE" "$MESSAGE" -u normal -t 5000
fi

exit 0
