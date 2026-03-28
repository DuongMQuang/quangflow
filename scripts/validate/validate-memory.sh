#!/usr/bin/env bash
# Validates Feature Memory Unit (FMU) integrity in .memory/ directory.
# Checks index consistency, required files, and bidirectional links.
#
# Usage:
#   bash scripts/validate/validate-memory.sh [feature-name]
#
# Without args: validates all FMUs in .memory/
# With arg: validates a single FMU
#
# Exit codes: 0 = no failures, 1 = failures found

set -euo pipefail

FEATURE_NAME="${1:-}"
MEMORY_DIR=".memory"

PASS=0; FAIL=0; WARN=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; WARN=$((WARN + 1)); }

echo -e "${BOLD}Memory Validation${NC}"
echo ""

# --- Check .memory/ directory exists ---
if [[ ! -d "$MEMORY_DIR" ]]; then
  fail ".memory/ directory not found"
  echo ""
  echo -e "${RED}No memory to validate.${NC}"
  exit 1
fi

# --- Check _index.md exists ---
INDEX_FILE="$MEMORY_DIR/_index.md"
if [[ -f "$INDEX_FILE" ]]; then
  pass "_index.md exists"
else
  fail "_index.md missing — memory index required"
  echo ""
  echo -e "${RED}Cannot validate FMUs without _index.md${NC}"
  exit 1
fi

# --- Collect FMU directories ---
FMUS=()
if [[ -n "$FEATURE_NAME" ]]; then
  if [[ -d "$MEMORY_DIR/$FEATURE_NAME" ]]; then
    FMUS=("$FEATURE_NAME")
  else
    fail "FMU not found: $MEMORY_DIR/$FEATURE_NAME"
    echo ""
    echo -e "${RED}Memory validation failed.${NC}"
    exit 1
  fi
else
  # All subdirectories (excluding files and _ prefixed items)
  for dir in "$MEMORY_DIR"/*/; do
    [[ ! -d "$dir" ]] && continue
    dirname=$(basename "$dir")
    [[ "$dirname" == _* ]] && continue
    FMUS+=("$dirname")
  done
fi

if [[ ${#FMUS[@]} -eq 0 ]]; then
  warn "No FMUs found in $MEMORY_DIR/"
  echo ""
  echo -e "${YELLOW}Memory is empty — nothing to validate.${NC}"
  exit 0
fi

echo "Found ${#FMUS[@]} FMU(s) to validate"
echo ""

# --- Validate each FMU ---
for fmu in "${FMUS[@]}"; do
  FMU_DIR="$MEMORY_DIR/$fmu"
  echo -e "${BOLD}FMU: $fmu${NC}"

  # Check CONTEXT.md exists
  if [[ -f "$FMU_DIR/CONTEXT.md" ]]; then
    pass "$fmu/CONTEXT.md exists"
  else
    fail "$fmu/CONTEXT.md missing — every FMU must have a context file"
  fi

  # Check FMU is listed in _index.md
  if grep -qF "$fmu" "$INDEX_FILE" 2>/dev/null; then
    pass "$fmu is listed in _index.md"
  else
    fail "$fmu is not listed in _index.md — orphan FMU"
  fi

  # Check LINKS.md bidirectional references
  LINKS_FILE="$FMU_DIR/LINKS.md"
  if [[ -f "$LINKS_FILE" ]]; then
    # Extract referenced FMU names from links
    LINKED_FMUS=$(grep -oE '\[.*\]\(\.\.\/[^)]+\)' "$LINKS_FILE" 2>/dev/null | grep -oE '\.\.\/[^)]+' | sed 's|\.\./||' | sed 's|/.*||' | sort -u || true)
    if [[ -n "$LINKED_FMUS" ]]; then
      while IFS= read -r linked; do
        [[ -z "$linked" ]] && continue
        # Check the linked FMU exists
        if [[ ! -d "$MEMORY_DIR/$linked" ]]; then
          fail "$fmu/LINKS.md references non-existent FMU: $linked"
          continue
        fi
        # Check bidirectional: linked FMU should reference back
        BACK_LINKS="$MEMORY_DIR/$linked/LINKS.md"
        if [[ -f "$BACK_LINKS" ]]; then
          if grep -qF "$fmu" "$BACK_LINKS" 2>/dev/null; then
            pass "$fmu <-> $linked bidirectional link OK"
          else
            warn "$fmu -> $linked link exists but $linked does not link back"
          fi
        else
          warn "$fmu -> $linked: target FMU has no LINKS.md"
        fi
      done <<< "$LINKED_FMUS"
    else
      pass "$fmu/LINKS.md exists (no outbound links)"
    fi
  else
    warn "$fmu/LINKS.md not found — consider adding cross-references"
  fi

  echo ""
done

# --- Check for orphan directories not in index ---
for dir in "$MEMORY_DIR"/*/; do
  [[ ! -d "$dir" ]] && continue
  dirname=$(basename "$dir")
  [[ "$dirname" == _* ]] && continue
  if ! grep -qF "$dirname" "$INDEX_FILE" 2>/dev/null; then
    fail "Orphan FMU: $dirname exists but is not in _index.md"
  fi
done

# --- Summary ---
echo ""
TOTAL=$((PASS + FAIL + WARN))
echo "Results: $PASS passed, $FAIL failed, $WARN warnings ($TOTAL total checks)"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}Memory validation passed.${NC}"
  exit 0
else
  echo -e "${RED}Memory validation failed: $FAIL failure(s).${NC}"
  exit 1
fi
