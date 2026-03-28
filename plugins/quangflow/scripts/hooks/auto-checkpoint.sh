#!/usr/bin/env bash
# PostToolUse hook: auto-records file changes to CHECKPOINT-{role}.md.
# Tracks every Write/Edit operation for audit trail and session resume.
#
# Hook config (add to .claude/settings.json):
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Write|Edit",
#       "command": "bash scripts/hooks/auto-checkpoint.sh"
#     }]
#   }
#
# Requires env vars:
#   QF_AGENT_ROLE     — current agent role (e.g., dev-backend, tester)
#   QF_MILESTONE_DIR  — path to current milestone directory
#
# Input: JSON on stdin with tool_name and tool_input

# Skip silently if env vars not set (not in team mode)
if [[ -z "${QF_AGENT_ROLE:-}" || -z "${QF_MILESTONE_DIR:-}" ]]; then
  exit 0
fi

# Parse file_path from stdin JSON
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

# If no file path extracted, skip
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"tool_name"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

CHECKPOINT_FILE="$QF_MILESTONE_DIR/CHECKPOINT-${QF_AGENT_ROLE}.md"

# Create checkpoint file if it doesn't exist
if [[ ! -f "$CHECKPOINT_FILE" ]]; then
  mkdir -p "$QF_MILESTONE_DIR"
  cat > "$CHECKPOINT_FILE" <<EOF
# Checkpoint — ${QF_AGENT_ROLE}

Auto-generated file change log.

## Changes

| Time | Operation | File |
|------|-----------|------|
EOF
fi

# Append the change entry
echo "| $TIMESTAMP | ${TOOL_NAME:-Write} | \`$FILE_PATH\` |" >> "$CHECKPOINT_FILE"

exit 0
