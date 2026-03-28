#!/usr/bin/env bash
# Validates QuangFlow plan artifacts for a specific feature.
# Checks: required sections, cross-references, milestone consistency.
#
# Usage:
#   bash scripts/validate/validate-artifacts.sh <plans-dir>/<feature-slug>
#   Example: bash scripts/validate/validate-artifacts.sh ./plans/user-auth
#
# Exit codes: 0 = all pass, 1 = failures found

set -euo pipefail

FEATURE_DIR="${1:-}"
if [[ -z "$FEATURE_DIR" || ! -d "$FEATURE_DIR" ]]; then
  echo "Usage: bash scripts/validate/validate-artifacts.sh <plans-dir>/<feature-slug>"
  echo "Example: bash scripts/validate/validate-artifacts.sh ./plans/user-auth"
  exit 1
fi

PASS=0; FAIL=0; WARN=0

# --- Colors ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; WARN=$((WARN + 1)); }

SLUG="$(basename "$FEATURE_DIR")"
echo -e "${BOLD}QuangFlow Artifact Validator${NC}"
echo "============================"
echo "Feature: $SLUG"
echo "Path:    $FEATURE_DIR"
echo ""

# --- Helper: check if file has required sections (## headings) ---
check_sections() {
  local file="$1" label="$2"
  shift 2
  local missing=0
  for section in "$@"; do
    if ! grep -qi "^##.*${section}" "$file" 2>/dev/null; then
      fail "$label: missing section '## $section'"
      missing=$((missing + 1))
    fi
  done
  if [[ $missing -eq 0 ]]; then
    pass "$label: all required sections present"
  fi
}

# =====================
# Project-level files
# =====================
echo -e "${BOLD}--- Project-Level ---${NC}"

# --- CONTEXT.md ---
CTX="$FEATURE_DIR/CONTEXT.md"
if [[ -f "$CTX" ]]; then
  check_sections "$CTX" "CONTEXT.md" "Metadata" "Tech Stack" "Constraints"
  # Check for quangflow_version in metadata
  if grep -q "quangflow_version" "$CTX" 2>/dev/null; then
    pass "CONTEXT.md: has quangflow_version"
  else
    warn "CONTEXT.md: missing quangflow_version in metadata"
  fi
  # Check for pm_mode
  if grep -q "pm_mode" "$CTX" 2>/dev/null; then
    pass "CONTEXT.md: has pm_mode"
  else
    warn "CONTEXT.md: missing pm_mode"
  fi
else
  warn "CONTEXT.md: not found (run /qf:0-init first)"
fi

# --- REQUIREMENTS.md ---
REQ="$FEATURE_DIR/REQUIREMENTS.md"
if [[ -f "$REQ" ]]; then
  check_sections "$REQ" "REQUIREMENTS.md" "Requirements" "Edge Cases"
  # Check for REQ-IDs
  REQ_COUNT=$(grep -c 'REQ-[0-9]' "$REQ" 2>/dev/null || echo 0)
  if [[ "$REQ_COUNT" -gt 0 ]]; then
    pass "REQUIREMENTS.md: $REQ_COUNT requirement IDs found"
  else
    warn "REQUIREMENTS.md: no REQ-IDs found (added in Phase 3)"
  fi
  # Check for milestone tags
  M_TAGS=$(grep -c '\[M[0-9]' "$REQ" 2>/dev/null || echo 0)
  if [[ "$M_TAGS" -gt 0 ]]; then
    pass "REQUIREMENTS.md: milestone tags found ($M_TAGS tagged)"
  else
    warn "REQUIREMENTS.md: no milestone tags [M1], [M2] found"
  fi
  # Check team_mode
  if grep -q "team_mode" "$REQ" 2>/dev/null; then
    pass "REQUIREMENTS.md: has team_mode setting"
  else
    warn "REQUIREMENTS.md: missing team_mode"
  fi
else
  warn "REQUIREMENTS.md: not found (run /qf:1-brainstorm first)"
fi

# --- OPEN_QUESTIONS.md ---
OQ="$FEATURE_DIR/OPEN_QUESTIONS.md"
if [[ -f "$OQ" ]]; then
  pass "OPEN_QUESTIONS.md: exists"
else
  warn "OPEN_QUESTIONS.md: not found"
fi

# =====================
# Milestone-level files
# =====================

# Detect milestone directories
MILESTONES=()
for d in "$FEATURE_DIR"/milestone-*/; do
  [[ -d "$d" ]] && MILESTONES+=("$d")
done

# If no milestone dirs, check for flat structure (quick mode)
if [[ ${#MILESTONES[@]} -eq 0 ]]; then
  # Quick mode or single milestone with files at feature level
  if [[ -f "$FEATURE_DIR/ROADMAP.md" ]]; then
    echo ""
    echo -e "${BOLD}--- Flat Structure (quick mode) ---${NC}"
    check_sections "$FEATURE_DIR/ROADMAP.md" "ROADMAP.md" "Tasks"
    pass "Quick mode: flat ROADMAP.md found"
  else
    echo ""
    echo -e "${BOLD}--- Milestones ---${NC}"
    warn "No milestone directories or flat ROADMAP.md found"
  fi
else
  for m_dir in "${MILESTONES[@]}"; do
    m_name="$(basename "$m_dir")"
    echo ""
    echo -e "${BOLD}--- $m_name ---${NC}"

    # --- DESIGN.md ---
    DESIGN="$m_dir/DESIGN.md"
    if [[ -f "$DESIGN" ]]; then
      check_sections "$DESIGN" "$m_name/DESIGN.md" "Architecture\|Chosen\|Option"
      # Check for rejected options
      if grep -qi "reject" "$DESIGN" 2>/dev/null; then
        pass "$m_name/DESIGN.md: has rejected options section"
      else
        warn "$m_name/DESIGN.md: no rejected options documented"
      fi
    else
      warn "$m_name/DESIGN.md: not found (run /qf:2-design)"
    fi

    # --- ROADMAP.md ---
    ROADMAP="$m_dir/ROADMAP.md"
    if [[ -f "$ROADMAP" ]]; then
      check_sections "$ROADMAP" "$m_name/ROADMAP.md" "Phase"
      # Check phases have deliverables
      PHASE_COUNT=$(grep -c '^## Phase' "$ROADMAP" 2>/dev/null || echo 0)
      DELIVERABLE_COUNT=$(grep -ci 'deliverable\|done' "$ROADMAP" 2>/dev/null || echo 0)
      if [[ "$PHASE_COUNT" -gt 0 ]]; then
        pass "$m_name/ROADMAP.md: $PHASE_COUNT phases found"
      else
        fail "$m_name/ROADMAP.md: no phases defined"
      fi
      if [[ "$DELIVERABLE_COUNT" -gt 0 ]]; then
        pass "$m_name/ROADMAP.md: has deliverables/done criteria"
      else
        warn "$m_name/ROADMAP.md: missing deliverable or done criteria"
      fi
    else
      warn "$m_name/ROADMAP.md: not found (run /qf:3-handoff)"
    fi

    # --- QA-REPORT.md ---
    QA="$m_dir/QA-REPORT.md"
    if [[ -f "$QA" ]]; then
      check_sections "$QA" "$m_name/QA-REPORT.md" "Requirement Coverage\|Coverage"
      # Check for REQ-ID mapping
      if grep -q 'REQ-[0-9]' "$QA" 2>/dev/null; then
        pass "$m_name/QA-REPORT.md: has requirement traceability"
      else
        warn "$m_name/QA-REPORT.md: no REQ-IDs in coverage matrix"
      fi
    fi

    # --- GAPS.md ---
    GAPS="$m_dir/GAPS.md"
    if [[ -f "$GAPS" ]]; then
      GAP_COUNT=$(grep -c 'GAP-[0-9]' "$GAPS" 2>/dev/null || echo 0)
      pass "$m_name/GAPS.md: exists ($GAP_COUNT gaps logged)"
    fi

    # --- STATUS.md ---
    STATUS="$m_dir/STATUS.md"
    if [[ -f "$STATUS" ]]; then
      if grep -qi "resume\|next" "$STATUS" 2>/dev/null; then
        pass "$m_name/STATUS.md: has session resume context"
      else
        warn "$m_name/STATUS.md: missing resume/next section"
      fi
    fi

    # --- PIPELINE-STATE.md ---
    PIPE="$m_dir/PIPELINE-STATE.md"
    if [[ -f "$PIPE" ]]; then
      pass "$m_name/PIPELINE-STATE.md: exists"
    fi

    # --- design/ subdirectory ---
    if [[ -d "$m_dir/design" ]]; then
      DESIGN_DOCS=0
      for df in OVERVIEW.md MODULES.md SEQUENCES.md CONTRACTS.md; do
        [[ -f "$m_dir/design/$df" ]] && DESIGN_DOCS=$((DESIGN_DOCS + 1))
      done
      if [[ $DESIGN_DOCS -eq 4 ]]; then
        pass "$m_name/design/: all 4 domain-engineer docs present"
      else
        warn "$m_name/design/: $DESIGN_DOCS/4 domain-engineer docs found"
      fi
    fi
  done
fi

# =====================
# Cross-reference checks
# =====================
echo ""
echo -e "${BOLD}--- Cross-References ---${NC}"

# Check that milestone tags in REQUIREMENTS.md match milestone dirs
if [[ -f "$REQ" && ${#MILESTONES[@]} -gt 0 ]]; then
  MAX_TAG=$(grep -o '\[M[0-9]*\]' "$REQ" 2>/dev/null | grep -o '[0-9]*' | sort -n | tail -1 || echo 0)
  DIR_COUNT=${#MILESTONES[@]}
  if [[ "$MAX_TAG" -eq "$DIR_COUNT" ]]; then
    pass "Milestone count: $MAX_TAG tags match $DIR_COUNT directories"
  elif [[ "$MAX_TAG" -gt "$DIR_COUNT" ]]; then
    warn "Milestone mismatch: $MAX_TAG tags but only $DIR_COUNT directories (later milestones not started)"
  else
    warn "Milestone mismatch: $MAX_TAG tags vs $DIR_COUNT directories"
  fi
fi

# Check BUGLOG.md (post-ship)
BUGLOG="$FEATURE_DIR/BUGLOG.md"
if [[ -f "$BUGLOG" ]]; then
  BUG_COUNT=$(grep -c 'BUG-[0-9]' "$BUGLOG" 2>/dev/null || echo 0)
  pass "BUGLOG.md: exists ($BUG_COUNT bugs logged)"
fi

# --- Summary ---
echo ""
TOTAL=$((PASS + FAIL + WARN))
echo -e "${BOLD}Result: $PASS passed, $FAIL failed, $WARN warnings (of $TOTAL checks)${NC}"
if [[ $FAIL -eq 0 && $WARN -eq 0 ]]; then
  echo -e "${GREEN}All artifacts valid.${NC}"
elif [[ $FAIL -eq 0 ]]; then
  echo -e "${YELLOW}Artifacts valid with warnings (some phases not yet completed).${NC}"
else
  echo -e "${RED}Artifact issues found. Review failures above.${NC}"
fi
exit "$( [[ $FAIL -gt 0 ]] && echo 1 || echo 0 )"
