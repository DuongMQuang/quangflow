#!/usr/bin/env bash
# PostToolUse hook: tracks evidence file writes in PIPELINE-STATE.md.
# Only activates for writes to .evidence/ paths.
#
# Hook config (add to .claude/settings.json):
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Write|Edit",
#       "command": "bash scripts/hooks/evidence-tracker.sh"
#     }]
#   }
#
# Requires env var:
#   QF_MILESTONE_DIR  — path to current milestone directory
#
# Input: JSON on stdin with tool_name and tool_input

# Skip silently if milestone dir not set
if [[ -z "${QF_MILESTONE_DIR:-}" ]]; then
  exit 0
fi

# Parse file_path from stdin JSON
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

# Only track .evidence/ paths
if [[ "$FILE_PATH" != *.evidence/* && "$FILE_PATH" != .evidence/* ]]; then
  exit 0
fi

# Extract REQ-ID or BUG-ID from filename
BASENAME=$(basename "$FILE_PATH")
ITEM_ID=""
if echo "$BASENAME" | grep -qoE 'REQ-[A-Z0-9_-]+'; then
  ITEM_ID=$(echo "$BASENAME" | grep -oE 'REQ-[A-Z0-9_-]+' | head -1)
elif echo "$BASENAME" | grep -qoE 'BUG-[A-Z0-9_-]+'; then
  ITEM_ID=$(echo "$BASENAME" | grep -oE 'BUG-[A-Z0-9_-]+' | head -1)
fi

if [[ -z "$ITEM_ID" ]]; then
  exit 0
fi

# Determine evidence type from path components
EVIDENCE_TYPE="unknown"
case "$FILE_PATH" in
  *red*)        EVIDENCE_TYPE="red" ;;
  *green*)      EVIDENCE_TYPE="green" ;;
  *verified*)   EVIDENCE_TYPE="verified" ;;
  *investigated*) EVIDENCE_TYPE="investigated" ;;
  *resolved*)   EVIDENCE_TYPE="resolved" ;;
esac

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
PIPELINE_STATE="$QF_MILESTONE_DIR/PIPELINE-STATE.md"

# Ensure PIPELINE-STATE.md exists
if [[ ! -f "$PIPELINE_STATE" ]]; then
  mkdir -p "$QF_MILESTONE_DIR"
  cat > "$PIPELINE_STATE" <<EOF
# Pipeline State

## Evidence Status

| Time | ID | Type | File |
|------|----|------|------|
EOF
fi

# Add Evidence Status section if it doesn't exist
if ! grep -q '## Evidence Status' "$PIPELINE_STATE" 2>/dev/null; then
  cat >> "$PIPELINE_STATE" <<EOF

## Evidence Status

| Time | ID | Type | File |
|------|----|------|------|
EOF
fi

# Append evidence entry
echo "| $TIMESTAMP | $ITEM_ID | $EVIDENCE_TYPE | \`$FILE_PATH\` |" >> "$PIPELINE_STATE"

exit 0
