#!/usr/bin/env bash
# Validates pre-conditions before /quangflow:close writes MILESTONE.yml.
# Enforces evidence requirements (STATUS.md + at least one of QA / CERT / SOLO-LOG).
#
# Usage:
#   bash scripts/validate/validate-milestone-close.sh --milestone-dir <path> [--force]
#
# Options:
#   --milestone-dir <path>   Path to milestone directory (e.g. plans/foo/milestone-1)
#   --force                  Skip evidence checks (still requires dir exists, not already closed)
#
# Exit codes:
#   0 = pre-conditions pass, /quangflow:close may proceed
#   1 = missing required artifact (STATUS.md or evidence file). Suggest --force.
#   2 = milestone already closed. Abort (do not overwrite).
#   3 = plan dir not found. Abort.

set -euo pipefail

MILESTONE_DIR=""
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --milestone-dir) MILESTONE_DIR="$2"; shift 2 ;;
    --force)         FORCE=1; shift ;;
    -h|--help)
      grep -E '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$MILESTONE_DIR" ]]; then
  echo "ERROR: --milestone-dir is required" >&2
  echo "Usage: validate-milestone-close.sh --milestone-dir <path> [--force]" >&2
  exit 1
fi

# --- Check 1: Plan dir exists ---
if [[ ! -d "$MILESTONE_DIR" ]]; then
  echo "FAIL: milestone dir not found: $MILESTONE_DIR" >&2
  exit 3
fi

# --- Check 2: Already closed? ---
YML="$MILESTONE_DIR/MILESTONE.yml"
if [[ -f "$YML" ]]; then
  if grep -qE '^status:[[:space:]]*CLOSED' "$YML" 2>/dev/null; then
    CLOSED_AT="$(grep -E '^closed_at:' "$YML" | head -1 | sed -E 's/^closed_at:[[:space:]]*//')"
    echo "FAIL: milestone already closed at ${CLOSED_AT:-unknown}" >&2
    echo "       To reopen: rm $YML" >&2
    exit 2
  fi
fi

# --- Check 3 + 4: Evidence files (skipped with --force) ---
if [[ "$FORCE" -eq 1 ]]; then
  echo "PASS: pre-conditions skipped via --force"
  exit 0
fi

STATUS_MD="$MILESTONE_DIR/STATUS.md"
QA_REPORT="$MILESTONE_DIR/QA-REPORT.md"
CERT="$MILESTONE_DIR/CERTIFICATION.md"
SOLO_LOG="$MILESTONE_DIR/SOLO-LOG.md"

# STATUS.md required
if [[ ! -f "$STATUS_MD" ]]; then
  echo "FAIL: STATUS.md missing — milestone has not reached PM stage" >&2
  echo "       Use --force to bypass this check (e.g. abandoned milestone)" >&2
  exit 1
fi

# At least one evidence file
if [[ ! -f "$QA_REPORT" && ! -f "$CERT" && ! -f "$SOLO_LOG" ]]; then
  echo "FAIL: no evidence file found (QA-REPORT.md / CERTIFICATION.md / SOLO-LOG.md)" >&2
  echo "       Milestone has not been verified or solo-logged." >&2
  echo "       Use --force to bypass this check." >&2
  exit 1
fi

echo "PASS: pre-conditions met"
[[ -f "$STATUS_MD" ]] && echo "  - STATUS.md present"
[[ -f "$QA_REPORT" ]] && echo "  - QA-REPORT.md present"
[[ -f "$CERT" ]]      && echo "  - CERTIFICATION.md present"
[[ -f "$SOLO_LOG" ]]  && echo "  - SOLO-LOG.md present"

exit 0
