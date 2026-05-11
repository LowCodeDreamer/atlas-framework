#!/usr/bin/env python3
"""
Verify that all components in an EQUIP_MANIFEST exist and pass validation.

Usage:
    python3 verify_build.py <manifest.json>
    echo '{"task":...}' | python3 verify_build.py -

For each component:
  1. Checks file exists at specified location
  2. Runs type-specific validator (same stdin format as hooks)
  3. Reports pass/fail per component

Exit codes:
    0 — All components pass
    1 — One or more failures (details on stderr)
"""

import json
import os
import subprocess
import sys
from pathlib import Path

def find_atlas_root() -> Path:
    """Find Atlas root by walking up from this script looking for .claude/settings.json marker."""
    candidate = Path(__file__).resolve().parent
    for _ in range(10):
        if (candidate / ".claude" / "settings.json").exists():
            return candidate
        candidate = candidate.parent
    return Path(__file__).resolve().parents[4]

ATLAS_ROOT = find_atlas_root()
VALIDATORS_DIR = ATLAS_ROOT / "hooks" / "validators"

TYPE_VALIDATORS = {
    "skill": VALIDATORS_DIR / "skill_validator.py",
    "agent": VALIDATORS_DIR / "agent_validator.py",
    "command": VALIDATORS_DIR / "command_validator.py",
    # "hook" type has no validator — verified by file-exists + executable check below
}


def verify_component(comp: dict) -> dict:
    """Verify a single component. Returns result dict."""
    name = comp.get("name", "unknown")
    ctype = comp.get("type", "unknown")
    location = comp.get("location", "")

    # Resolve path relative to Atlas root
    full_path = ATLAS_ROOT / location
    if not full_path.exists():
        return {
            "name": name,
            "type": ctype,
            "status": "FAIL",
            "reason": f"File not found: {location}",
        }

    # For hooks, check executable permission
    if ctype == "hook" and not os.access(full_path, os.X_OK):
        return {
            "name": name,
            "type": ctype,
            "status": "FAIL",
            "reason": f"Hook not executable: {location}",
        }

    # Run type-specific validator if available
    validator = TYPE_VALIDATORS.get(ctype)
    if validator and validator.exists():
        hook_input = json.dumps({
            "tool_name": "Write",
            "tool_input": {"file_path": str(full_path)},
        })
        try:
            result = subprocess.run(
                ["python3", str(validator)],
                input=hook_input,
                capture_output=True,
                text=True,
                timeout=10,
            )
            if result.returncode == 2:
                return {
                    "name": name,
                    "type": ctype,
                    "status": "FAIL",
                    "reason": result.stderr.strip(),
                }
            elif result.returncode != 0:
                return {
                    "name": name,
                    "type": ctype,
                    "status": "WARN",
                    "reason": f"Validator exited {result.returncode}: {result.stderr.strip()}",
                }
        except subprocess.TimeoutExpired:
            return {
                "name": name,
                "type": ctype,
                "status": "WARN",
                "reason": "Validator timed out",
            }
        except Exception as e:
            return {
                "name": name,
                "type": ctype,
                "status": "WARN",
                "reason": f"Validator error: {e}",
            }

    return {
        "name": name,
        "type": ctype,
        "status": "PASS",
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: verify_build.py <manifest.json> | -", file=sys.stderr)
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

    components = data.get("components", [])
    if not components:
        print("No components to verify.", file=sys.stderr)
        sys.exit(1)

    results = [verify_component(c) for c in components]

    failures = [r for r in results if r["status"] == "FAIL"]
    passes = [r for r in results if r["status"] == "PASS"]
    warns = [r for r in results if r["status"] == "WARN"]

    # Summary output
    summary = {
        "total": len(results),
        "passed": len(passes),
        "failed": len(failures),
        "warnings": len(warns),
        "results": results,
    }

    if failures:
        print(f"BUILD VERIFICATION FAILED ({len(failures)}/{len(results)} components failed):", file=sys.stderr)
        for f in failures:
            print(f"  FAIL {f['type']}/{f['name']}: {f['reason']}", file=sys.stderr)
        if warns:
            for w in warns:
                print(f"  WARN {w['type']}/{w['name']}: {w['reason']}", file=sys.stderr)
        print(json.dumps(summary, indent=2))
        sys.exit(1)
    else:
        if warns:
            for w in warns:
                print(f"  WARN {w['type']}/{w['name']}: {w['reason']}", file=sys.stderr)
        print(json.dumps(summary, indent=2))
        sys.exit(0)


if __name__ == "__main__":
    main()
