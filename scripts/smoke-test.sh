#!/bin/bash
# smoke-test.sh — verify framework primitives are wired correctly.
# Run after instance-init.sh or instance-update.sh to catch CLAUDE.md/command drift.
#
# Usage: smoke-test.sh <instance-path>

set -uo pipefail

INSTANCE_PATH="${1:-/opt/eno}"
FAIL=0

fail() { echo "FAIL: $1"; FAIL=1; }
ok()   { echo "OK:   $1"; }

# === Check 1: instance has framework conventions ===
for f in CLAUDE.md _domain.md .claude/settings.json system/identity.env hooks/inject-context.sh; do
    if [[ -f "$INSTANCE_PATH/$f" ]]; then
        ok "$f exists"
    else
        fail "$f missing at $INSTANCE_PATH/$f"
    fi
done

# === Check 2: every backticked /command in CLAUDE.md exists ===
# Match only `/cmd ...` or `/cmd` — backtick-delimited, kebab-case slug.
if [[ -f "$INSTANCE_PATH/CLAUDE.md" ]]; then
    refs=$(grep -oE '`/[a-z][a-z0-9-]*' "$INSTANCE_PATH/CLAUDE.md" | sort -u | sed 's|`/||')
    for cmd in $refs; do
        case "$cmd" in opt|home|tmp|var|etc|usr|root|bin|sbin|lib|local|run|dev|sys|proc|mnt|srv) continue ;; esac
        if [[ -f "$INSTANCE_PATH/.claude/commands/$cmd.md" ]] || [[ -f "$INSTANCE_PATH/.framework-source/core/commands/$cmd.md" ]]; then
            ok "command /$cmd resolvable"
        else
            fail "CLAUDE.md references /$cmd but no command file found"
        fi
    done
fi

# === Check 3: hooks are executable ===
for h in "$INSTANCE_PATH"/hooks/*.sh; do
    [[ -f "$h" ]] || continue
    if [[ -x "$h" ]]; then
        ok "hook executable: $(basename "$h")"
    else
        fail "hook NOT executable: $h"
    fi
done

# === Check 4: framework templates intact ===
for tmpl in workstation/CLAUDE.md.template project/_domain.md.template project/_manifest.md.template service/_manifest.md.template instance/CLAUDE.md.template; do
    if [[ -f "$INSTANCE_PATH/.framework-source/templates/$tmpl" ]]; then
        ok "template $tmpl present"
    else
        fail "template missing: $tmpl"
    fi
done

echo ""
if [[ $FAIL -eq 0 ]]; then
    echo "=== smoke test PASSED ==="
    exit 0
else
    echo "=== smoke test FAILED ==="
    exit 1
fi
