#!/bin/bash
#
# inject-domain-context.sh - Inject domain expertise on file edits
# Triggered by: PreToolUse (Edit|Write)
#
# Provides domain-specific guidance when editing files in workspace directories.
# Uses additionalContext to surface relevant expertise.

set -euo pipefail

ATLAS_DIR="${CLAUDE_PROJECT_DIR:-$HOME/${INSTANCE_HOME}}"

# Read hook input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# If no file path, exit silently
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Determine which domain this file belongs to
DOMAIN=""
CONTEXT=""

# Check project patterns (resolve symlinks for workstation paths)
REAL_FILE_PATH=$(realpath "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")

if [[ "$REAL_FILE_PATH" == *"projects/eno"* ]]; then
    DOMAIN="eno"
    CONTEXT="Eno Project Guidelines:
- Use 'digital sovereignty' and 'personal compute' terminology
- Target audience: tech-savvy but not developer
- Vision: 'iMac of home labs' - accessible, empowering
- Philosophy: Technology should empower individuals"

elif [[ "$REAL_FILE_PATH" == *"projects/<domain>"* || "$REAL_FILE_PATH" == *"clients/"* ]]; then
    DOMAIN="<domain>"
    CONTEXT="<Domain> Consulting Guidelines:
- Professional, client-facing tone
- Platform-agnostic approach
- Focus on business value over technical details
- Excellence in delivery"

elif [[ "$REAL_FILE_PATH" == *"<domain>"* ]]; then
    DOMAIN="<domain>"
    CONTEXT="<Client> Insurance Project:
- Salesforce Financial Services Cloud implementation
- Key stakeholders: Sarah (Operations), Mike (IT)
- Target go-live: Q1 2026
- Focus on insurance brokerage operations"

elif [[ "$REAL_FILE_PATH" == *".claude/skills"* ]]; then
    DOMAIN="skills"
    CONTEXT="Skill Authoring Guidelines:
- Frontmatter requires: name, description
- Use 'context: fork' for heavy processing
- User-invocable skills need clear usage examples
- Keep instructions actionable and tool-focused"

elif [[ "$REAL_FILE_PATH" == *".claude/agents"* ]]; then
    DOMAIN="agents"
    CONTEXT="Agent Definition Guidelines:
- Frontmatter requires: name, description, model
- Add hooks for self-validation where appropriate
- Specify allowed-tools explicitly
- Return structured JSON for orchestrated agents"

elif [[ "$REAL_FILE_PATH" == *"expertise/"* || "$REAL_FILE_PATH" == *"knowledge/"* ]]; then
    DOMAIN="knowledge"
    CONTEXT="Knowledge File Guidelines:
- YAML frontmatter required with id and type
- Valid types: knowledge, reference, insight, decision, log
- Use Obsidian wikilinks: [[path|Display Name]]
- Keep content atomic and linkable"
fi

# If domain identified, output context
if [[ -n "$DOMAIN" && -n "$CONTEXT" ]]; then
    # Output as JSON with additionalContext
    cat << EOF
{
  "additionalContext": "Domain: $DOMAIN\n\n$CONTEXT"
}
EOF
fi

exit 0
