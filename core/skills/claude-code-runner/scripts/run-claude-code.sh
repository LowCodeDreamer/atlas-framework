#!/bin/bash
# run-claude-code.sh — invoke Claude Code as a subprocess with structured I/O
# Usage: ./run-claude-code.sh <workdir> <prompt> [-- additional claude flags]
set -euo pipefail

WORKDIR="${1:?workdir required}"
PROMPT="${2:?prompt required}"
shift 2

MAX_TURNS="${MAX_TURNS:-20}"
ALLOWED_TOOLS="${ALLOWED_TOOLS:-Read,Edit,Bash,Glob,Grep}"
TIMEOUT_SEC="${TIMEOUT_SEC:-600}"
INSTANCE_HOME="${INSTANCE_HOME:-$(pwd)}"

SESSION_LOG="${INSTANCE_HOME}/working/sessions/runner-$(date -u +%Y%m%dT%H%M%SZ).json"
mkdir -p "$(dirname "$SESSION_LOG")"

START=$(date +%s)
set +e
timeout "$TIMEOUT_SEC" claude --print "$PROMPT" \
  --max-turns "$MAX_TURNS" \
  --output-format json \
  --allowedTools "$ALLOWED_TOOLS" \
  "$@" > "$SESSION_LOG" 2>&1
EXIT_CODE=$?
set -e
END=$(date +%s)

SESSION_ID=$(jq -r '.session_id // empty' "$SESSION_LOG" 2>/dev/null || echo "")
TOTAL_COST=$(jq -r '.total_cost_usd // empty' "$SESSION_LOG" 2>/dev/null || echo "")
RESULT=$(jq -r '.result // empty' "$SESSION_LOG" 2>/dev/null || echo "")

jq -n \
  --arg exit_code "$EXIT_CODE" \
  --arg duration_sec "$((END - START))" \
  --arg session_id "$SESSION_ID" \
  --arg total_cost_usd "$TOTAL_COST" \
  --arg session_log "$SESSION_LOG" \
  --arg result "$RESULT" \
  '{exit_code: ($exit_code | tonumber), duration_sec: ($duration_sec | tonumber), session_id, total_cost_usd, session_log, result}'
