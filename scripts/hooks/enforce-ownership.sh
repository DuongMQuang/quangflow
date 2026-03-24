#!/usr/bin/env bash
# PreToolUse hook: enforces file ownership during agent team execution.
# Blocks Write/Edit operations on files outside the current agent's ownership.
#
# Reads ownership globs from .claude/.current-agent-ownership
# (written by cook before spawning each dev agent)
#
# Hook config (add to .claude/settings.json):
#   "hooks": {
#     "PreToolUse": [{
#       "matcher": "Write|Edit|MultiEdit",
#       "command": "bash .claude/scripts/hooks/enforce-ownership.sh"
#     }]
#   }
#
# Input: JSON on stdin with tool_name and tool_input
# Output: JSON with "decision": "allow" or "decision": "block", "reason": "..."

OWNERSHIP_FILE=".claude/.current-agent-ownership"

# If no ownership file, skip enforcement (not in team mode)
if [[ ! -f "$OWNERSHIP_FILE" ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# Read ownership globs
OWNERSHIP=$(cat "$OWNERSHIP_FILE" 2>/dev/null || true)
if [[ -z "$OWNERSHIP" ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# Parse the file path from stdin JSON
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//')

# If no file path extracted, allow (might be a different tool format)
if [[ -z "$FILE_PATH" ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# Always allow writes to plans/ directory (checkpoints, decisions, etc.)
if [[ "$FILE_PATH" == plans/* || "$FILE_PATH" == */plans/* ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# Always allow writes to tests/ and __tests__/ (tester agent)
if [[ "$FILE_PATH" == tests/* || "$FILE_PATH" == */__tests__/* || "$FILE_PATH" == *.test.* || "$FILE_PATH" == *.spec.* ]]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# Check file against ownership globs
IFS=',' read -ra GLOBS <<< "$OWNERSHIP"
for glob in "${GLOBS[@]}"; do
  glob=$(echo "$glob" | tr -d ' ')
  PREFIX="${glob%%\**}"
  if [[ "$FILE_PATH" == $glob ]] || [[ "$FILE_PATH" == "$PREFIX"* ]]; then
    echo '{"decision": "allow"}'
    exit 0
  fi
done

# File not in any ownership glob — block
echo "{\"decision\": \"block\", \"reason\": \"File ownership violation: '$FILE_PATH' is outside your assigned ownership ($OWNERSHIP). Message the lead if you need this file changed.\"}"
exit 0
