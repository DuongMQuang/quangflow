#!/usr/bin/env bash
# Validates evidence required to exit a given phase.
# Ensures all required artifacts exist before a phase gate is crossed.
#
# Usage:
#   bash scripts/validate/validate-evidence.sh <plans-feature-dir> <phase>
#
# Phases: 1 (brainstorm), 2 (design), 3 (handoff/TDD), 4 (verify)
# Exit codes: 0 = pass, 1 = evidence gaps found

set -euo pipefail

FEATURE_DIR="${1:-}"
PHASE="${2:-}"

if [[ -z "$FEATURE_DIR" || -z "$PHASE" ]]; then
  echo "Usage: validate-evidence.sh <plans-feature-dir> <phase>"
  echo "Phases: 1, 2, 3, 4"
  exit 1
fi

if [[ ! -d "$FEATURE_DIR" ]]; then
  echo "Error: feature directory not found: $FEATURE_DIR"
  exit 1
fi

PASS=0; FAIL=0
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }

echo -e "${BOLD}Evidence Validation — Phase $PHASE${NC}"
echo "Feature: $FEATURE_DIR"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$PHASE" in

  1)
    # Phase 1 exit: REQUIREMENTS.md with REQ-IDs + phase-1-gate.md
    if [[ -f "$FEATURE_DIR/REQUIREMENTS.md" ]]; then
      REQ_COUNT=$(grep -cE 'REQ-[A-Z0-9_-]+' "$FEATURE_DIR/REQUIREMENTS.md" 2>/dev/null || echo 0)
      if [[ "$REQ_COUNT" -gt 0 ]]; then
        pass "REQUIREMENTS.md exists with $REQ_COUNT REQ-ID(s)"
      else
        fail "REQUIREMENTS.md exists but contains no REQ-IDs"
      fi
    else
      fail "REQUIREMENTS.md missing"
    fi

    if [[ -f "$FEATURE_DIR/phase-1-gate.md" ]]; then
      pass "phase-1-gate.md exists"
    else
      fail "phase-1-gate.md missing — brainstorm gate not recorded"
    fi
    ;;

  2)
    # Phase 2 exit: DESIGN.md + phase-2-gate.md
    if [[ -f "$FEATURE_DIR/DESIGN.md" ]]; then
      pass "DESIGN.md exists"
    else
      fail "DESIGN.md missing"
    fi

    if [[ -f "$FEATURE_DIR/phase-2-gate.md" ]]; then
      pass "phase-2-gate.md exists"
    else
      fail "phase-2-gate.md missing — design gate not recorded"
    fi
    ;;

  3)
    # Phase 3 exit: TDD coverage + phase-3-gate.md
    echo "Running TDD coverage check..."
    echo ""
    if bash "$SCRIPT_DIR/validate-tdd-coverage.sh" "$FEATURE_DIR"; then
      pass "TDD coverage validated"
    else
      fail "TDD coverage incomplete — see details above"
    fi

    if [[ -f "$FEATURE_DIR/phase-3-gate.md" ]]; then
      pass "phase-3-gate.md exists"
    else
      fail "phase-3-gate.md missing — handoff gate not recorded"
    fi
    ;;

  4)
    # Phase 4 exit: CERTIFICATION.md (or QA-REPORT.md) + phase-4-certification.md
    CERT_FILE=""
    if [[ -f "$FEATURE_DIR/CERTIFICATION.md" ]]; then
      CERT_FILE="$FEATURE_DIR/CERTIFICATION.md"
      pass "CERTIFICATION.md exists"
    elif [[ -f "$FEATURE_DIR/QA-REPORT.md" ]]; then
      CERT_FILE="$FEATURE_DIR/QA-REPORT.md"
      pass "QA-REPORT.md exists (backwards compat)"
    else
      fail "CERTIFICATION.md (or QA-REPORT.md) missing"
    fi

    # Check for UNRESOLVED entries
    if [[ -n "$CERT_FILE" ]]; then
      UNRESOLVED=$(grep -ciE 'UNRESOLVED' "$CERT_FILE" 2>/dev/null || echo 0)
      if [[ "$UNRESOLVED" -gt 0 ]]; then
        fail "Certification has $UNRESOLVED UNRESOLVED entries — must resolve before shipping"
      else
        pass "No UNRESOLVED entries in certification"
      fi
    fi

    if [[ -f "$FEATURE_DIR/phase-4-certification.md" ]]; then
      pass "phase-4-certification.md exists"
    else
      fail "phase-4-certification.md missing — verify gate not recorded"
    fi
    ;;

  *)
    fail "Unknown phase: $PHASE (expected 1, 2, 3, or 4)"
    ;;
esac

# --- Summary ---
echo ""
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}Phase $PHASE evidence complete: $PASS/$TOTAL checks passed.${NC}"
  exit 0
else
  echo -e "${RED}Phase $PHASE evidence incomplete: $FAIL failure(s) out of $TOTAL check(s).${NC}"
  exit 1
fi
