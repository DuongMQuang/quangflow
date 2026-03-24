#!/usr/bin/env bash
# UserPromptSubmit hook: detects correction/rule patterns in user messages.
# When triggered, injects a reminder for the agent to log a gotcha.
#
# Hook config (add to .claude/settings.json):
#   "hooks": {
#     "UserPromptSubmit": [{
#       "command": "bash .claude/scripts/hooks/detect-gotcha-trigger.sh"
#     }]
#   }
#
# Input: JSON on stdin with "prompt" field
# Output: JSON with optional "message" to inject into conversation

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | grep -o '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"prompt"[[:space:]]*:[[:space:]]*"//' | sed 's/"$//' || true)

# If can't parse prompt, skip
if [[ -z "$PROMPT" ]]; then
  exit 0
fi

# Convert to lowercase for pattern matching
LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Detect correction/rule patterns
TRIGGERED=false
TRIGGER_TYPE=""

# Strong correction signals
for pattern in \
  "you must" "you should always" "you should never" \
  "never do" "always do" "don't ever" "do not ever" \
  "you wrong" "you're wrong" "that's wrong" "that is wrong" \
  "no, " "no! " "wrong," "wrong!" \
  "remember this" "remember that" "don't forget" \
  "rule:" "important:" "gotcha:" \
  "stop doing" "don't do that" "not like that" \
  "i told you" "i already said" "i mentioned" \
  "this is a mistake" "that's a mistake" "that was a mistake" \
  "fix this pattern" "bad pattern" "anti-pattern" \
  "lesson learned" "we learned" "note to self"; do
  if echo "$LOWER" | grep -qi "$pattern" 2>/dev/null; then
    TRIGGERED=true
    TRIGGER_TYPE="$pattern"
    break
  fi
done

if $TRIGGERED; then
  # Inject a reminder into the conversation
  cat << 'EOF'
{"message": "[GOTCHA DETECTED] The user just provided a correction or rule. After addressing their feedback, you MUST log this as a gotcha entry. Use the GOTCHAs Logging Protocol from _shared.md: determine if it's global or feature-specific, assign a G-ID, and append to the appropriate GOTCHAS.md. If uncertain about scope, ask the user."}
EOF
else
  # No trigger — pass through silently
  exit 0
fi
