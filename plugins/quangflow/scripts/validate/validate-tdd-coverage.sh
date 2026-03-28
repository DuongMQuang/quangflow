#!/usr/bin/env bash
# Validates TDD red/green evidence coverage against requirements.
# Ensures every REQ-ID has matching red (fail) and green (pass) test logs.
#
# Usage:
#   bash scripts/validate/validate-tdd-coverage.sh <plans-feature-dir>
#
# Exit codes: 0 = all REQ-IDs covered, 1 = gaps found

set -euo pipefail

FEATURE_DIR="${1:-}"

if [[ -z "$FEATURE_DIR" ]]; then
  echo "Usage: validate-tdd-coverage.sh <plans-feature-dir>"
  exit 1
fi

if [[ ! -d "$FEATURE_DIR" ]]; then
  echo "Error: feature directory not found: $FEATURE_DIR"
  exit 1
fi

# --- Detect project root by walking up from feature dir to find .evidence/ ---
find_project_root() {
  local dir="$1"
  while [[ "$dir" != "/" && "$dir" != "." ]]; do
    if [[ -d "$dir/.evidence" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

PROJECT_ROOT=$(find_project_root "$(cd "$FEATURE_DIR" && pwd)") || {
  echo "Error: could not find .evidence/ directory above $FEATURE_DIR"
  exit 1
}

EVIDENCE_TDD="$PROJECT_ROOT/.evidence/tdd"

PASS=0; FAIL=0
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }

echo -e "${BOLD}TDD Coverage Validation${NC}"
echo "Feature: $FEATURE_DIR"
echo ""

# --- Find REQUIREMENTS.md and extract REQ-IDs ---
REQUIREMENTS=""
for candidate in "$FEATURE_DIR/REQUIREMENTS.md" "$FEATURE_DIR/requirements.md"; do
  if [[ -f "$candidate" ]]; then
    REQUIREMENTS="$candidate"
    break
  fi
done

if [[ -z "$REQUIREMENTS" ]]; then
  fail "REQUIREMENTS.md not found in $FEATURE_DIR"
  echo ""
  echo -e "${RED}TDD coverage check cannot proceed without REQUIREMENTS.md${NC}"
  exit 1
fi

# Extract REQ-IDs (e.g., REQ-001, REQ-AUTH-01, etc.)
REQ_IDS=$(grep -oE 'REQ-[A-Z0-9_-]+' "$REQUIREMENTS" | sort -u)

if [[ -z "$REQ_IDS" ]]; then
  fail "No REQ-IDs found in $REQUIREMENTS"
  echo ""
  echo -e "${RED}REQUIREMENTS.md must contain REQ-ID identifiers (e.g., REQ-001)${NC}"
  exit 1
fi

REQ_COUNT=$(echo "$REQ_IDS" | wc -l | tr -d ' ')
echo "Found $REQ_COUNT REQ-ID(s) in REQUIREMENTS.md"
echo ""

# --- Check each REQ-ID for red+green evidence ---
while IFS= read -r req_id; do
  [[ -z "$req_id" ]] && continue

  # Look for red log (case-insensitive filename match)
  RED_LOG=""
  GREEN_LOG=""

  if [[ -d "$EVIDENCE_TDD" ]]; then
    # Find red log: *red*REQ-ID* or *REQ-ID*red*
    RED_LOG=$(find "$EVIDENCE_TDD" -maxdepth 2 -type f \( -iname "*red*${req_id}*" -o -iname "*${req_id}*red*" \) 2>/dev/null | head -1)
    # Find green log: *green*REQ-ID* or *REQ-ID*green*
    GREEN_LOG=$(find "$EVIDENCE_TDD" -maxdepth 2 -type f \( -iname "*green*${req_id}*" -o -iname "*${req_id}*green*" \) 2>/dev/null | head -1)
  fi

  # Validate red log
  RED_OK=false
  if [[ -n "$RED_LOG" && -f "$RED_LOG" ]]; then
    if grep -qiE 'FAIL|ERROR|FAILED' "$RED_LOG" 2>/dev/null; then
      RED_OK=true
    else
      fail "$req_id: red log exists but contains no FAIL/ERROR/FAILED indicator"
    fi
  else
    fail "$req_id: red log missing in .evidence/tdd/"
  fi

  # Validate green log
  GREEN_OK=false
  if [[ -n "$GREEN_LOG" && -f "$GREEN_LOG" ]]; then
    if grep -qiE 'PASS|OK|SUCCESS' "$GREEN_LOG" 2>/dev/null; then
      # Also check no failures snuck in
      if grep -qiE 'FAIL|FAILED|ERROR' "$GREEN_LOG" 2>/dev/null; then
        fail "$req_id: green log contains failure indicators — tests not fully passing"
      else
        GREEN_OK=true
      fi
    else
      fail "$req_id: green log exists but contains no PASS/OK/SUCCESS indicator"
    fi
  else
    fail "$req_id: green log missing in .evidence/tdd/"
  fi

  if $RED_OK && $GREEN_OK; then
    pass "$req_id: red+green evidence complete"
  fi
done <<< "$REQ_IDS"

# --- Summary ---
echo ""
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}TDD coverage complete: $PASS/$TOTAL REQ-IDs verified.${NC}"
  exit 0
else
  echo -e "${RED}TDD coverage incomplete: $FAIL failure(s) out of $TOTAL check(s).${NC}"
  exit 1
fi
