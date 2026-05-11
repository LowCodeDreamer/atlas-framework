#!/bin/bash
# instance-init.sh — bootstrap a new agentic-framework instance
#
# Usage: instance-init.sh --target <path> --name <instance-name> --role "<identity>" [--register-hooks <yes|no>] [--existing-instance]
#
# Creates the framework conventions at <path>:
#   CLAUDE.md, _domain.md, .claude/, .claude-plugin/, .mcp.json,
#   hooks/, projects/, workstations/, services/, expertise/, working/, system/, scripts/
#
# Modes:
#   default        — fail if <path>/CLAUDE.md already exists
#   --existing-instance — additive only; don't overwrite existing files; warn on collisions

set -euo pipefail

# === Args ===
TARGET=""
NAME=""
ROLE=""
REGISTER_HOOKS="yes"
EXISTING_INSTANCE="no"
GREETING=""
VALUES="Truth over comfort | First-principles | Simplify ruthlessly | Bias toward action | Direct"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --name) NAME="$2"; shift 2 ;;
        --role) ROLE="$2"; shift 2 ;;
        --greeting) GREETING="$2"; shift 2 ;;
        --values) VALUES="$2"; shift 2 ;;
        --register-hooks) REGISTER_HOOKS="$2"; shift 2 ;;
        --existing-instance) EXISTING_INSTANCE="yes"; shift ;;
        -h|--help)
            sed -n '2,15p' "$0" | sed 's/^# *//'
            exit 0
            ;;
        *) echo "ERROR: unknown arg: $1"; exit 1 ;;
    esac
done

# === Validate ===
[[ -z "$TARGET" ]] && { echo "ERROR: --target required"; exit 1; }
[[ -z "$NAME" ]] && { echo "ERROR: --name required"; exit 1; }
[[ -z "$ROLE" ]] && { echo "ERROR: --role required"; exit 1; }
[[ -z "$GREETING" ]] && GREETING="${NAME^} online"

# Resolve target to absolute path
TARGET=$(cd "$(dirname "$TARGET")" 2>/dev/null && pwd)/$(basename "$TARGET") || TARGET=$(realpath -m "$TARGET")

# Detect framework source
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
FRAMEWORK_ROOT=$(dirname "$SCRIPT_DIR")

[[ ! -d "$FRAMEWORK_ROOT/core" ]] && { echo "ERROR: framework source not found at $FRAMEWORK_ROOT"; exit 1; }

# Check existing
if [[ -f "$TARGET/CLAUDE.md" ]] && [[ "$EXISTING_INSTANCE" != "yes" ]]; then
    echo "ERROR: $TARGET/CLAUDE.md already exists. Use --existing-instance to layer additively."
    exit 1
fi

# === Plan ===
INIT_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
NAME_TITLE=$(echo "$NAME" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')

echo ""
echo "=== Agentic Framework — instance-init ==="
echo "  Source:    $FRAMEWORK_ROOT"
echo "  Target:    $TARGET"
echo "  Name:      $NAME ($NAME_TITLE)"
echo "  Role:      $ROLE"
echo "  Greeting:  $GREETING"
if [[ "$EXISTING_INSTANCE" == "yes" ]]; then
    echo "  Mode:      layer onto existing instance (additive)"
else
    echo "  Mode:      fresh install"
fi
echo "  Register hooks: $REGISTER_HOOKS"
echo ""

# === Build directory tree ===
echo "→ Creating directory tree..."
mkdir -p "$TARGET"/{projects,workstations,services,expertise/domains,working/{inbox,active,archive,plans,completed},logs/sessions,system/{proposals/.archive,registries},scripts,.claude/{agents,commands,skills},.claude-plugin,hooks/validators,docs}

# === Substitute templates ===
substitute() {
    local src=$1
    local dst=$2
    # Use ASCII Record Separator (036) as sed delimiter to avoid collisions with | / etc.
    local D=$'\x1e'
    sed \
        -e "s${D}{{INSTANCE_NAME}}${D}${NAME}${D}g" \
        -e "s${D}{{INSTANCE_NAME_TITLE}}${D}${NAME_TITLE}${D}g" \
        -e "s${D}{{INSTANCE_IDENTITY}}${D}${ROLE}${D}g" \
        -e "s${D}{{INSTANCE_VALUES}}${D}${VALUES}${D}g" \
        -e "s${D}{{INSTANCE_GREETING}}${D}${GREETING}${D}g" \
        -e "s${D}{{INSTANCE_HOME}}${D}${TARGET}${D}g" \
        -e "s${D}{{INIT_DATE}}${D}${INIT_DATE}${D}g" \
        "$src" > "$dst"
}

# === Place template files ===
echo "→ Placing template files..."
#
# Behavior matrix:
#   File doesn't exist          → write framework template
#   File exists, fresh-install   → ERROR (we already exited above for CLAUDE.md collision)
#   File exists, --existing-instance:
#     - For CLAUDE.md, _domain.md, .mcp.json (cascade-critical):
#         backup existing → <name>.pre-framework.<ts>, then write framework template
#         (the framework cascade root MUST land; existing is preserved as backup)
#     - For everything else (toggles.md, identity.env, registries):
#         skip (don't clobber instance state)
write_critical() {
    local dst=$1
    local src=$2
    local base=$(basename "$dst")
    if [[ -f "$dst" ]]; then
        local backup="${dst}.pre-framework.$(date -u +%Y%m%dT%H%M%SZ)"
        cp "$dst" "$backup"
        echo "    BACKUP: $base → $(basename "$backup")"
    fi
    substitute "$src" "$dst"
    echo "    WROTE: $base"
}

write_if_absent() {
    local dst=$1
    local src=$2
    local base=$(basename "$dst")
    if [[ -f "$dst" ]]; then
        echo "    SKIP (exists): $base"
    else
        substitute "$src" "$dst"
        echo "    WROTE: $base"
    fi
}

# Cascade-critical: framework template MUST land; existing backed up
write_critical "$TARGET/CLAUDE.md"           "$FRAMEWORK_ROOT/templates/instance/CLAUDE.md.template"
write_critical "$TARGET/_domain.md"          "$FRAMEWORK_ROOT/templates/instance/_domain.md.template"
write_critical "$TARGET/.mcp.json"           "$FRAMEWORK_ROOT/templates/instance/.mcp.json.template"

# Instance state: only write if absent (don't clobber)
write_if_absent "$TARGET/system/identity.env" "$FRAMEWORK_ROOT/templates/instance/system/identity.template.sh"
write_if_absent "$TARGET/system/toggles.md"   "$FRAMEWORK_ROOT/templates/instance/system/toggles.md.template"
write_if_absent "$TARGET/system/registries/services.md" "$FRAMEWORK_ROOT/templates/instance/system/registries/services.md.template"

# === Copy core/agents ===
echo "→ Copying core agents..."
cp -n "$FRAMEWORK_ROOT/core/agents/"*.md "$TARGET/.claude/agents/" 2>/dev/null || true
ls "$TARGET/.claude/agents/" | wc -l | xargs printf "    %s agents in place\n"

# === Copy core/commands ===
echo "→ Copying core commands..."
cp -n "$FRAMEWORK_ROOT/core/commands/"*.md "$TARGET/.claude/commands/" 2>/dev/null || true
ls "$TARGET/.claude/commands/" | wc -l | xargs printf "    %s commands in place\n"

# === Copy core/skills ===
echo "→ Copying core skills..."
for skill_dir in "$FRAMEWORK_ROOT/core/skills/"*/; do
    skill_name=$(basename "$skill_dir")
    if [[ -d "$TARGET/.claude/skills/$skill_name" ]]; then
        echo "    SKIP (exists): $skill_name"
    else
        cp -r "$skill_dir" "$TARGET/.claude/skills/$skill_name"
    fi
done
ls "$TARGET/.claude/skills/" | wc -l | xargs printf "    %s skills in place\n"

# === Copy hooks ===
echo "→ Copying hooks..."
cp -n "$FRAMEWORK_ROOT/core/hooks/"*.sh "$TARGET/hooks/" 2>/dev/null || true
cp -n "$FRAMEWORK_ROOT/core/hooks/validators/"*.py "$TARGET/hooks/validators/" 2>/dev/null || true
chmod +x "$TARGET/hooks/"*.sh 2>/dev/null || true
chmod +x "$TARGET/hooks/validators/"*.py 2>/dev/null || true
ls "$TARGET/hooks/"*.sh | wc -l | xargs printf "    %s hook scripts in place\n"

# === Copy scripts ===
echo "→ Copying scripts..."
cp -n "$FRAMEWORK_ROOT/scripts/mount.sh" "$TARGET/scripts/" 2>/dev/null || true
cp -n "$FRAMEWORK_ROOT/scripts/unmount.sh" "$TARGET/scripts/" 2>/dev/null || true
cp -n "$FRAMEWORK_ROOT/scripts/status.sh" "$TARGET/scripts/" 2>/dev/null || true
cp -n "$FRAMEWORK_ROOT/scripts/clear.sh" "$TARGET/scripts/" 2>/dev/null || true
cp -n "$FRAMEWORK_ROOT/scripts/instance-update.sh" "$TARGET/scripts/" 2>/dev/null || true
chmod +x "$TARGET/scripts/"*.sh 2>/dev/null || true

# === Marketplace pointer ===
cat > "$TARGET/.claude-plugin/marketplace.json" << EOF
{
  "name": "$NAME-skills",
  "owner": { "name": "$NAME instance" },
  "metadata": { "description": "$NAME instance skills (agentic-framework v0.1.0)", "version": "0.1.0" },
  "plugins": []
}
EOF
echo "    WROTE: .claude-plugin/marketplace.json"

# === settings.json (hook registrations) ===
if [[ "$REGISTER_HOOKS" == "yes" ]]; then
    echo "→ Registering hooks in .claude/settings.json..."
    cat > "$TARGET/.claude/settings.json" << EOF
{
  "hooks": {
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "$TARGET/hooks/inject-context.sh" }] }],
    "SessionStart":     [{ "hooks": [{ "type": "command", "command": "$TARGET/hooks/session-init.sh" }] }],
    "Stop":             [{ "hooks": [{ "type": "command", "command": "$TARGET/hooks/session-end.sh" }] }],
    "PreToolUse":       [{ "hooks": [
      { "type": "command", "command": "$TARGET/hooks/check-file-exists.sh" },
      { "type": "command", "command": "$TARGET/hooks/protect-files.sh" }
    ] }],
    "PostToolUse":      [{ "hooks": [
      { "type": "command", "command": "$TARGET/hooks/track-session-activity.sh" },
      { "type": "command", "command": "$TARGET/hooks/validators/skill_validator.py" },
      { "type": "command", "command": "$TARGET/hooks/validators/agent_validator.py" },
      { "type": "command", "command": "$TARGET/hooks/validators/command_validator.py" }
    ] }],
    "SubagentStart":    [{ "hooks": [{ "type": "command", "command": "$TARGET/hooks/subagent-log.sh" }] }],
    "SubagentStop":     [{ "hooks": [{ "type": "command", "command": "$TARGET/hooks/subagent-log.sh" }] }],
    "Notification":     [{ "hooks": [{ "type": "command", "command": "$TARGET/hooks/notify.sh" }] }]
  }
}
EOF
fi

# === Verification ===
echo ""
echo "=== Init complete ==="
echo ""
echo "Tree:"
find "$TARGET" -maxdepth 2 -type d | sort | head -40
echo ""
echo "Next:"
echo "  cd $TARGET"
echo "  claude                  # open a session, verify cascade with /help"
echo "  /refresh-status         # generate SYSTEM-STATUS.md"
echo "  /init-workstation <name> # create your first capability environment"
echo ""
