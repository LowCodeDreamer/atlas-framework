#!/bin/bash
# notify.sh - Notification hook
# Sends desktop notification when Claude needs attention

# Read input from stdin
INPUT=$(cat)

# Extract message
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude needs your attention"')

# macOS notification
if [[ "$OSTYPE" == "darwin"* ]]; then
  osascript -e "display notification \"$MESSAGE\" with title \"{{IDENTITY}}\" sound name \"Ping\""
# Linux notification (requires notify-send)
elif command -v notify-send &> /dev/null; then
  notify-send "{{IDENTITY}}" "$MESSAGE" -u normal -t 5000
fi

exit 0
