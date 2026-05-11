#!/bin/bash
#
# setup.sh - Atlas initialization and health check
# Triggered by: claude --init or claude --maintenance
# Event: Setup
#
# Validates system health and ensures Atlas is ready for operation.

set -euo pipefail

ATLAS_DIR="${CLAUDE_PROJECT_DIR:-$HOME/${INSTANCE_HOME}}"
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Atlas Setup & Health Check"
echo "   Session: ${SESSION_ID:0:8}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Track issues
ISSUES=()
WARNINGS=()

# 1. Check required directories
echo -e "\n📁 Checking directories..."
REQUIRED_DIRS=(
    "hooks"
    "hooks/validators"
    "working/active"
    "working/planning"
    "working/plans"
    "working/inbox"
    "working/archive"
    "expertise/domains"
    ".claude/skills"
    ".claude/agents"
    ".claude/commands"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "$ATLAS_DIR/$dir" ]]; then
        echo -e "  ${GREEN}✓${NC} $dir"
    else
        echo -e "  ${YELLOW}○${NC} $dir (creating...)"
        mkdir -p "$ATLAS_DIR/$dir"
    fi
done

# 2. Check validator executability
echo -e "\n🔍 Checking validators..."
VALIDATORS=(
    "knowledge_validator.py"
    "agent_validator.py"
    "skill_validator.py"
    "json_output_validator.py"
    "csv_validator.py"
)

for validator in "${VALIDATORS[@]}"; do
    path="$ATLAS_DIR/hooks/validators/$validator"
    if [[ -x "$path" ]]; then
        echo -e "  ${GREEN}✓${NC} $validator"
    elif [[ -f "$path" ]]; then
        echo -e "  ${YELLOW}○${NC} $validator (making executable...)"
        chmod +x "$path"
    else
        echo -e "  ${RED}✗${NC} $validator (missing)"
        ISSUES+=("Missing validator: $validator")
    fi
done

# 3. Check MCP servers (from settings)
echo -e "\n🔌 Checking MCP servers..."
MCP_CONFIG="$HOME/.claude.json"
if [[ -f "$MCP_CONFIG" ]]; then
    # Check for key MCPs
    for mcp in "supabase" "n8n-cloud" "n8n-builder"; do
        if grep -q "\"$mcp\"" "$MCP_CONFIG" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $mcp"
        else
            echo -e "  ${YELLOW}○${NC} $mcp (not configured)"
            WARNINGS+=("MCP not configured: $mcp")
        fi
    done
else
    echo -e "  ${YELLOW}○${NC} No global MCP config found at ~/.claude.json"
    WARNINGS+=("No global MCP configuration")
fi

# 4. Check hook executability
echo -e "\n⚡ Checking hooks..."
for hook in "$ATLAS_DIR"/hooks/*.sh; do
    if [[ -x "$hook" ]]; then
        echo -e "  ${GREEN}✓${NC} $(basename "$hook")"
    elif [[ -f "$hook" ]]; then
        echo -e "  ${YELLOW}○${NC} $(basename "$hook") (making executable...)"
        chmod +x "$hook"
    fi
done

# 5. Check domain experts
echo -e "\n🧠 Checking domain experts..."
DOMAIN_EXPERTS=("domain-atlas" "domain-eno" "domain-<domain>" "domain-<domain>")
for expert in "${DOMAIN_EXPERTS[@]}"; do
    path="$ATLAS_DIR/.claude/agents/${expert}.md"
    if [[ -f "$path" ]]; then
        # Check if hooks are configured
        if grep -q "^hooks:" "$path" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $expert (with hooks)"
        else
            echo -e "  ${YELLOW}○${NC} $expert (no hooks)"
            WARNINGS+=("Domain expert without hooks: $expert")
        fi
    else
        echo -e "  ${RED}✗${NC} $expert (missing)"
        ISSUES+=("Missing domain expert: $expert")
    fi
done

# Summary
echo -e "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ ${#ISSUES[@]} -eq 0 && ${#WARNINGS[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ Atlas is healthy${NC}"
elif [[ ${#ISSUES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  Atlas operational with ${#WARNINGS[@]} warning(s)${NC}"
    for warn in "${WARNINGS[@]}"; do
        echo "   • $warn"
    done
else
    echo -e "${RED}❌ Atlas has ${#ISSUES[@]} issue(s)${NC}"
    for issue in "${ISSUES[@]}"; do
        echo "   • $issue"
    done
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Exit 0 even with warnings (don't block startup)
exit 0
