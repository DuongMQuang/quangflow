#!/usr/bin/env bash
# Logs what context an agent received for post-hoc verification.
# Called by cook after building context for each agent.
#
# Usage:
#   bash scripts/log-agent-audit.sh --role <role> --milestone-dir <path> \
#     --model <model> --context-file <path> [--ownership <globs>] [--reqs <ids>]
#
# Appends to: plans/{slug}/milestone-{N}/AUDIT-LOG.md

set -euo pipefail

ROLE=""
MILESTONE_DIR=""
MODEL=""
CONTEXT_FILE=""
OWNERSHIP=""
REQS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role) ROLE="$2"; shift 2 ;;
    --milestone-dir) MILESTONE_DIR="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --context-file) CONTEXT_FILE="$2"; shift 2 ;;
    --ownership) OWNERSHIP="$2"; shift 2 ;;
    --reqs) REQS="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$ROLE" || -z "$MILESTONE_DIR" ]]; then
  echo "Usage: log-agent-audit.sh --role <role> --milestone-dir <path> --model <model> --context-file <path>" >&2
  exit 1
fi

AUDIT_FILE="$MILESTONE_DIR/AUDIT-LOG.md"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Calculate context size
CONTEXT_LINES=0
CONTEXT_CHARS=0
if [[ -n "$CONTEXT_FILE" && -f "$CONTEXT_FILE" ]]; then
  CONTEXT_LINES=$(wc -l < "$CONTEXT_FILE" | tr -d ' ')
  CONTEXT_CHARS=$(wc -c < "$CONTEXT_FILE" | tr -d ' ')
fi

# Create header if file doesn't exist
if [[ ! -f "$AUDIT_FILE" ]]; then
  cat > "$AUDIT_FILE" << 'HEADER'
# Agent Audit Log

Records what context each agent received. For post-hoc verification of scoping correctness.

HEADER
fi

# Append audit entry
cat >> "$AUDIT_FILE" << EOF
### ${ROLE} — ${TIMESTAMP}
- **Model:** ${MODEL:-unknown}
- **Context size:** ${CONTEXT_LINES} lines / ${CONTEXT_CHARS} chars
- **Context file:** ${CONTEXT_FILE:-none}
- **Ownership:** ${OWNERSHIP:-N/A}
- **REQ-IDs:** ${REQS:-N/A}
EOF

# If context file exists, log its section headings as a manifest
if [[ -n "$CONTEXT_FILE" && -f "$CONTEXT_FILE" ]]; then
  echo "- **Sections injected:**" >> "$AUDIT_FILE"
  grep '^## ' "$CONTEXT_FILE" 2>/dev/null | while IFS= read -r heading; do
    echo "  - ${heading}" >> "$AUDIT_FILE"
  done
fi

echo "" >> "$AUDIT_FILE"
