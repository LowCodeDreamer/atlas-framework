#!/bin/bash
# update-indexes.sh - PostToolUse hook for Edit|Write|MultiEdit
# Triggers index updates when Atlas markdown files change
#
# Called by Claude Code hooks system with JSON input on stdin.
# Filters quickly in bash, then invokes Python for actual indexing.

set -e

# Auto-detect Atlas root from script location
# hooks/update-indexes.sh → hooks → Atlas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ATLAS_ROOT="${ATLAS_ROOT:-$(dirname "$SCRIPT_DIR")}"

INDEXER_SCRIPT="${ATLAS_ROOT}/scripts/indexer/main.py"

# Read input from stdin
INPUT=$(cat)

# Extract file path from tool_input using jq if available, else Python
if command -v jq &> /dev/null; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
else
    FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
fi

# Quick exit if no file path
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Quick exit if not an Atlas path
if [[ "$FILE_PATH" != *"$ATLAS_ROOT"* ]] && [[ "$FILE_PATH" != "$ATLAS_ROOT"* ]]; then
    # Try resolving relative paths
    RESOLVED_PATH=$(cd "$ATLAS_ROOT" && realpath "$FILE_PATH" 2>/dev/null || echo "")
    if [[ "$RESOLVED_PATH" != "$ATLAS_ROOT"* ]]; then
        exit 0
    fi
    FILE_PATH="$RESOLVED_PATH"
fi

# Quick exit if not a markdown file
if [[ "$FILE_PATH" != *.md ]]; then
    exit 0
fi

# Skip system paths (fast string matching)
if [[ "$FILE_PATH" == *"/.git/"* ]] || \
   [[ "$FILE_PATH" == *"/.obsidian/"* ]] || \
   [[ "$FILE_PATH" == *"/node_modules/"* ]] || \
   [[ "$FILE_PATH" == *"/__pycache__/"* ]] || \
   [[ "$FILE_PATH" == *"/.originals/"* ]] || \
   [[ "$FILE_PATH" == *"/.system/"* ]]; then
    exit 0
fi

# Skip index files themselves (prevent recursion)
FILENAME=$(basename "$FILE_PATH")
if [[ "$FILENAME" == "_INDEX.md" ]] || [[ "$FILENAME" == "_REGISTRY.md" ]]; then
    exit 0
fi

# Run indexer
# Use timeout command if available (macOS/Linux)
if command -v timeout &> /dev/null; then
    echo "$INPUT" | timeout 1s python3 -m scripts.indexer.main 2>/dev/null || true
elif command -v gtimeout &> /dev/null; then
    # macOS with coreutils installed
    echo "$INPUT" | gtimeout 1s python3 -m scripts.indexer.main 2>/dev/null || true
else
    # Fallback: run without timeout, rely on Python's internal efficiency
    echo "$INPUT" | python3 -m scripts.indexer.main 2>/dev/null || true
fi

# Validate Obsidian links in domain index files
# Auto-fix corruption from domain expert agents
if [[ "$FILE_PATH" == *"/expertise/domains/"*"/index.md" ]]; then
    python3 "${ATLAS_ROOT}/scripts/validate-obsidian-links.py" "$FILE_PATH" --fix 2>&1 | \
        while read -r line; do
            # Log to file for visibility
            echo "$(date '+%Y-%m-%d %H:%M:%S') $line" >> "${ATLAS_ROOT}/logs/validation.log"
        done || true
fi

# Always exit 0 to not block Claude
exit 0
