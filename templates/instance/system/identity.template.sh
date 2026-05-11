# Instance identity — sourced by inject-context.sh hook on every UserPromptSubmit
# Rename to identity.env when applying via instance-init.sh
# Edit to customize how the instance addresses the user.

INSTANCE_NAME="{{INSTANCE_NAME}}"
INSTANCE_IDENTITY="{{INSTANCE_IDENTITY}}"
INSTANCE_VALUES="{{INSTANCE_VALUES}}"
INSTANCE_GREETING="{{INSTANCE_GREETING}}"

# Auto-apply for proposal pipeline (default: off)
# AUTO_APPLY_ENABLED=1
# AUTO_APPLY_GRACE_HOURS=24
