#!/usr/bin/env python3
"""
Validate an EQUIP_MANIFEST.json before execution.

Usage:
    python3 validate_manifest.py <path-to-manifest.json>
    echo '{"task": "..."}' | python3 validate_manifest.py -

Exit codes:
    0 — Valid manifest
    1 — Invalid manifest (errors printed to stderr)
"""

import json
import sys
from pathlib import Path

REQUIRED_TOP_LEVEL = {"task", "analysis", "components", "composition"}
REQUIRED_ANALYSIS = {"existing_capabilities", "gaps"}
REQUIRED_COMPONENT = {"type", "name", "purpose", "location"}
VALID_TYPES = {"skill", "agent", "command", "hook"}
VALID_MODELS = {"sonnet", "opus", "haiku"}
VALID_EVENTS = {"PreToolUse", "PostToolUse", "Stop", "UserPromptSubmit", "SessionStart", "SessionEnd", "Notification", "SubagentStart", "SubagentStop", "PermissionRequest"}


def validate(manifest: dict) -> list[str]:
    """Validate manifest structure. Returns list of error strings."""
    errors = []

    # Top-level fields
    missing = REQUIRED_TOP_LEVEL - set(manifest.keys())
    if missing:
        errors.append(f"Missing top-level fields: {', '.join(sorted(missing))}")
        return errors  # Can't validate further

    # Task
    if not isinstance(manifest["task"], str) or not manifest["task"].strip():
        errors.append("'task' must be a non-empty string")

    # Analysis
    analysis = manifest["analysis"]
    if not isinstance(analysis, dict):
        errors.append("'analysis' must be an object")
    else:
        missing_a = REQUIRED_ANALYSIS - set(analysis.keys())
        if missing_a:
            errors.append(f"Missing analysis fields: {', '.join(sorted(missing_a))}")

        for cap in analysis.get("existing_capabilities", []):
            if not isinstance(cap, dict):
                errors.append("Each existing_capability must be an object")
            elif "type" not in cap or "name" not in cap:
                errors.append(f"Existing capability missing type/name: {cap}")

    # Components
    components = manifest["components"]
    if not isinstance(components, list):
        errors.append("'components' must be an array")
    elif len(components) == 0:
        errors.append("'components' array is empty — nothing to build")
    else:
        names_seen = set()
        for i, comp in enumerate(components):
            prefix = f"components[{i}]"
            if not isinstance(comp, dict):
                errors.append(f"{prefix}: must be an object")
                continue

            missing_c = REQUIRED_COMPONENT - set(comp.keys())
            if missing_c:
                errors.append(f"{prefix}: missing fields: {', '.join(sorted(missing_c))}")

            ctype = comp.get("type", "")
            if ctype not in VALID_TYPES:
                errors.append(f"{prefix}: invalid type '{ctype}' (valid: {', '.join(sorted(VALID_TYPES))})")

            name = comp.get("name", "")
            if name in names_seen:
                errors.append(f"{prefix}: duplicate name '{name}'")
            names_seen.add(name)

            location = comp.get("location", "")
            if not location:
                errors.append(f"{prefix}: location is empty")

            # Type-specific validation
            details = comp.get("details", {})
            if ctype == "agent" and details:
                model = details.get("model", "sonnet")
                if model not in VALID_MODELS:
                    errors.append(f"{prefix}: invalid model '{model}'")

            if ctype == "hook" and details:
                event = details.get("event", "")
                if event and event not in VALID_EVENTS:
                    errors.append(f"{prefix}: invalid hook event '{event}'")

    # Composition
    composition = manifest["composition"]
    if not isinstance(composition, dict):
        errors.append("'composition' must be an object")
    elif "flow" not in composition:
        errors.append("composition missing 'flow' description")

    return errors


def main():
    if len(sys.argv) < 2:
        print("Usage: validate_manifest.py <manifest.json> | -", file=sys.stderr)
        sys.exit(1)

    source = sys.argv[1]

    try:
        if source == "-":
            data = json.loads(sys.stdin.read())
        else:
            data = json.loads(Path(source).read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"Invalid JSON: {e}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(f"File not found: {source}", file=sys.stderr)
        sys.exit(1)

    errors = validate(data)

    if errors:
        print(f"Manifest validation FAILED ({len(errors)} errors):", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        sys.exit(1)
    else:
        print(json.dumps({"status": "valid", "components": len(data["components"])}))
        sys.exit(0)


if __name__ == "__main__":
    main()
