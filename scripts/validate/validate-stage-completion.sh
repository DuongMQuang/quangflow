#!/usr/bin/env bash
# Validates stage completion before allowing pipeline to advance.
# Enforces rules that LLM prompts alone cannot guarantee.
#
# Usage:
#   bash scripts/validate/validate-stage-completion.sh <stage> <milestone-dir> [options]
#
# Stages: domain-engineer, devs, tech-lead, tester, pm
# Options:
#   --dev-role <role>       For devs stage: validate a specific dev role
#   --ownership <globs>     For devs stage: file ownership globs (comma-separated)
#
# Exit codes: 0 = pass, 1 = block (do not advance)

set -euo pipefail

STAGE="${1:-}"
MILESTONE_DIR="${2:-}"
DEV_ROLE=""
OWNERSHIP=""

shift 2 || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dev-role) DEV_ROLE="$2"; shift 2 ;;
    --ownership) OWNERSHIP="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$STAGE" || -z "$MILESTONE_DIR" ]]; then
  echo "Usage: validate-stage-completion.sh <stage> <milestone-dir> [--dev-role <role>] [--ownership <globs>]"
  exit 1
fi

PASS=0; FAIL=0
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }

echo -e "${BOLD}Stage Validation: $STAGE${NC}"
echo "Milestone: $MILESTONE_DIR"
echo ""

# --- Common: PIPELINE-STATE.md must exist ---
PIPELINE_STATE="$MILESTONE_DIR/PIPELINE-STATE.md"
if [[ -f "$PIPELINE_STATE" ]]; then
  pass "PIPELINE-STATE.md exists"
else
  fail "PIPELINE-STATE.md missing — cook must track pipeline state"
fi

# --- Common: PROGRESS.md should exist and contain current phase ---
FEATURE_DIR="$(dirname "$MILESTONE_DIR")"
PROGRESS="$FEATURE_DIR/PROGRESS.md"
if [[ -f "$PROGRESS" ]]; then
  pass "PROGRESS.md exists"
else
  # Not a hard fail for cook pipeline stages (domain-engineer, devs, etc.)
  # Only warn — progress is logged by phase commands, not cook stages
  case "$STAGE" in
    domain-engineer|devs|tech-lead|tester|pm) ;; # skip for cook stages
    *) fail "PROGRESS.md missing — each phase must log progress" ;;
  esac
fi

# --- Stage-specific checks ---
case "$STAGE" in

  domain-engineer)
    # Design docs must exist
    DESIGN_DIR="$MILESTONE_DIR/design"
    for doc in OVERVIEW.md MODULES.md SEQUENCES.md CONTRACTS.md; do
      if [[ -f "$DESIGN_DIR/$doc" ]]; then
        pass "design/$doc exists"
      else
        fail "design/$doc missing — domain-engineer must produce this"
      fi
    done
    ;;

  devs)
    # Per-dev validation
    if [[ -z "$DEV_ROLE" ]]; then
      fail "No --dev-role specified for devs stage validation"
    else
      # Check 1: Checkpoint file exists
      CHECKPOINT="$MILESTONE_DIR/CHECKPOINT-${DEV_ROLE}.md"
      if [[ -f "$CHECKPOINT" ]]; then
        # Check it has content (not just header)
        LINES=$(wc -l < "$CHECKPOINT" | tr -d ' ')
        if [[ "$LINES" -gt 3 ]]; then
          pass "CHECKPOINT-${DEV_ROLE}.md exists ($LINES lines)"
        else
          fail "CHECKPOINT-${DEV_ROLE}.md exists but too short ($LINES lines) — may be incomplete"
        fi
      else
        fail "CHECKPOINT-${DEV_ROLE}.md missing — dev must write progress checkpoints"
      fi

      # Check 2: File ownership enforcement
      if [[ -n "$OWNERSHIP" ]]; then
        # Get files changed by this dev (in worktree or main branch)
        # Look at git diff for recently modified files
        VIOLATIONS=0
        IFS=',' read -ra GLOBS <<< "$OWNERSHIP"

        # Get all files modified in working tree
        CHANGED_FILES=$(git diff --name-only HEAD~1 2>/dev/null || true)
        if [[ -z "$CHANGED_FILES" ]]; then
          pass "File ownership: no changed files to check"
        else
          while IFS= read -r file; do
            MATCHED=false
            for glob in "${GLOBS[@]}"; do
              glob=$(echo "$glob" | tr -d ' ')
              # Simple glob matching: check if file starts with the glob prefix
              PREFIX="${glob%%\**}"
              if [[ "$file" == $glob ]] || [[ "$file" == "$PREFIX"* ]]; then
                MATCHED=true
                break
              fi
            done
            if ! $MATCHED; then
              # Check if it's a plan file (always allowed)
              if [[ "$file" == plans/* ]]; then
                continue
              fi
              fail "File ownership violation: ${DEV_ROLE} modified '$file' outside ownership ($OWNERSHIP)"
              VIOLATIONS=$((VIOLATIONS + 1))
            fi
          done <<< "$CHANGED_FILES"

          if [[ $VIOLATIONS -eq 0 ]]; then
            pass "File ownership: all changes within $OWNERSHIP"
          fi
        fi
      fi

      # Check 4: TDD evidence exists for assigned REQ-IDs
      if [[ -n "$OWNERSHIP" ]]; then
        EVIDENCE_DIR="$(cd "$MILESTONE_DIR/../.." && pwd)/.evidence/tdd"
        if [[ -d "$EVIDENCE_DIR" ]]; then
          EVIDENCE_COUNT=$(find "$EVIDENCE_DIR" -name "REQ-*-green.log" 2>/dev/null | wc -l | tr -d ' ')
          if [[ "$EVIDENCE_COUNT" -gt 0 ]]; then
            pass "TDD evidence: $EVIDENCE_COUNT REQ-IDs have green logs"
          else
            fail "TDD evidence: no green logs found in .evidence/tdd/ — devs must follow TDD"
          fi
        else
          fail ".evidence/tdd/ directory missing — devs must save TDD evidence"
        fi
      fi
    fi

    # Check 3: DECISIONS.md format (if exists and has entries)
    DECISIONS="$MILESTONE_DIR/DECISIONS.md"
    if [[ -f "$DECISIONS" ]]; then
      # Check that entries follow D-NNN format
      D_COUNT=$(grep -c '### D-[0-9]' "$DECISIONS" 2>/dev/null || echo 0)
      if [[ "$D_COUNT" -gt 0 ]]; then
        # Check each entry has required fields
        MISSING_FIELDS=0
        for field in "Context:" "Choice:" "Affects:"; do
          FIELD_COUNT=$(grep -c "\*\*$field\*\*" "$DECISIONS" 2>/dev/null || echo 0)
          if [[ "$FIELD_COUNT" -lt "$D_COUNT" ]]; then
            fail "DECISIONS.md: some entries missing **$field** field"
            MISSING_FIELDS=$((MISSING_FIELDS + 1))
          fi
        done
        if [[ $MISSING_FIELDS -eq 0 ]]; then
          pass "DECISIONS.md: $D_COUNT entries, all properly formatted"
        fi
      else
        pass "DECISIONS.md: exists, no entries (OK)"
      fi
    fi
    ;;

  tech-lead)
    # REVIEW.md must exist
    if [[ -f "$MILESTONE_DIR/REVIEW.md" ]]; then
      pass "REVIEW.md exists"
    else
      fail "REVIEW.md missing — tech-lead must produce review report"
    fi
    ;;

  tester)
    # Test files should exist somewhere
    PROJECT_ROOT=$(cd "$MILESTONE_DIR/../.." && pwd)
    TEST_COUNT=$(find "$PROJECT_ROOT" -path "*/tests/*" -o -path "*/__tests__/*" -o -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | head -20 | wc -l | tr -d ' ')
    if [[ "$TEST_COUNT" -gt 0 ]]; then
      pass "Test files found: $TEST_COUNT file(s)"
    else
      fail "No test files found — tester must generate tests"
    fi
    ;;

  pm)
    # STATUS.md must exist
    if [[ -f "$MILESTONE_DIR/STATUS.md" ]]; then
      # Check for session resume section
      if grep -qi "resume\|next" "$MILESTONE_DIR/STATUS.md" 2>/dev/null; then
        pass "STATUS.md exists with resume context"
      else
        fail "STATUS.md exists but missing resume/next section"
      fi
    else
      fail "STATUS.md missing — PM must produce status report"
    fi
    ;;

  verify)
    # CERTIFICATION.md (new format) or QA-REPORT.md (legacy) must exist
    CERTIFICATION="$MILESTONE_DIR/CERTIFICATION.md"
    QA_REPORT="$MILESTONE_DIR/QA-REPORT.md"
    if [[ -f "$CERTIFICATION" ]]; then
      pass "CERTIFICATION.md exists"
      # Check for UNRESOLVED entries
      UNRESOLVED=$(grep -ci 'UNRESOLVED\|BLOCKED\|FAILED' "$CERTIFICATION" 2>/dev/null || echo 0)
      if [[ "$UNRESOLVED" -gt 0 ]]; then
        fail "CERTIFICATION.md has $UNRESOLVED UNRESOLVED/BLOCKED/FAILED entries — resolve before shipping"
      else
        pass "CERTIFICATION.md: no unresolved entries"
      fi
    elif [[ -f "$QA_REPORT" ]]; then
      pass "QA-REPORT.md exists (legacy format — consider upgrading to CERTIFICATION.md)"
    else
      fail "CERTIFICATION.md or QA-REPORT.md missing — verify must produce certification report"
    fi
    # Evidence directory check
    EVIDENCE_VERIFY_DIR="$(cd "$MILESTONE_DIR/../.." && pwd)/.evidence/verification"
    if [[ -d "$EVIDENCE_VERIFY_DIR" ]]; then
      GATE_COUNT=$(find "$EVIDENCE_VERIFY_DIR" -name "*.log" -o -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
      if [[ "$GATE_COUNT" -gt 0 ]]; then
        pass "Verification evidence: $GATE_COUNT phase gate file(s) in .evidence/verification/"
      else
        fail "Verification evidence: .evidence/verification/ exists but is empty"
      fi
    else
      fail ".evidence/verification/ directory missing — verify must save phase gate evidence"
    fi
    # If GAPS.md has entries, GOTCHAS.md must have been updated
    GAPS="$MILESTONE_DIR/GAPS.md"
    if [[ -f "$GAPS" ]]; then
      GAP_COUNT=$(grep -c 'GAP-[0-9]' "$GAPS" 2>/dev/null || echo 0)
      if [[ "$GAP_COUNT" -gt 0 ]]; then
        # Check both global and feature GOTCHAS.md
        FEATURE_GOTCHAS="$FEATURE_DIR/GOTCHAS.md"
        GLOBAL_GOTCHAS="$FEATURE_DIR/../GOTCHAS.md"
        GOTCHA_COUNT=0
        if [[ -f "$FEATURE_GOTCHAS" ]]; then
          GOTCHA_COUNT=$((GOTCHA_COUNT + $(grep -c '### G-[0-9]' "$FEATURE_GOTCHAS" 2>/dev/null || echo 0)))
        fi
        if [[ -f "$GLOBAL_GOTCHAS" ]]; then
          GOTCHA_COUNT=$((GOTCHA_COUNT + $(grep -c '### G-[0-9]' "$GLOBAL_GOTCHAS" 2>/dev/null || echo 0)))
        fi
        if [[ "$GOTCHA_COUNT" -gt 0 ]]; then
          pass "GOTCHAs logged: $GOTCHA_COUNT entries (gaps found: $GAP_COUNT)"
        else
          fail "GAPS.md has $GAP_COUNT gaps but no GOTCHAs logged — lessons must be captured"
        fi
      fi
    fi
    ;;

  maintain)
    # If bugs were fixed, GOTCHAS.md should have been updated
    BUGLOG="$FEATURE_DIR/BUGLOG.md"
    if [[ -f "$BUGLOG" ]]; then
      RESOLVED=$(grep -c 'RESOLVED' "$BUGLOG" 2>/dev/null || echo 0)
      if [[ "$RESOLVED" -gt 0 ]]; then
        FEATURE_GOTCHAS="$FEATURE_DIR/GOTCHAS.md"
        GLOBAL_GOTCHAS="$FEATURE_DIR/../GOTCHAS.md"
        GOTCHA_COUNT=0
        if [[ -f "$FEATURE_GOTCHAS" ]]; then
          GOTCHA_COUNT=$((GOTCHA_COUNT + $(grep -c '### G-[0-9]' "$FEATURE_GOTCHAS" 2>/dev/null || echo 0)))
        fi
        if [[ -f "$GLOBAL_GOTCHAS" ]]; then
          GOTCHA_COUNT=$((GOTCHA_COUNT + $(grep -c '### G-[0-9]' "$GLOBAL_GOTCHAS" 2>/dev/null || echo 0)))
        fi
        if [[ "$GOTCHA_COUNT" -gt 0 ]]; then
          pass "GOTCHAs logged: $GOTCHA_COUNT entries ($RESOLVED bugs resolved)"
        else
          fail "$RESOLVED bugs resolved but no GOTCHAs logged — lessons must be captured"
        fi
      else
        pass "BUGLOG.md exists, no resolved bugs to check"
      fi
    else
      pass "No BUGLOG.md (maintain not yet active)"
    fi
    ;;

  *)
    fail "Unknown stage: $STAGE"
    ;;
esac

# Auto-save to Feature Memory on successful validation
if [[ $FAIL -eq 0 ]]; then
  FEATURE_SLUG=$(basename "$FEATURE_DIR")
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  MEMORY_HOOK="$SCRIPT_DIR/../hooks/save-feature-memory.sh"
  if [[ -x "$MEMORY_HOOK" ]]; then
    bash "$MEMORY_HOOK" "$FEATURE_SLUG" "$STAGE" "$MILESTONE_DIR" 2>/dev/null || true
  fi
fi

# --- Summary ---
echo ""
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}Stage '$STAGE' validated. OK to advance.${NC}"
  exit 0
else
  echo -e "${RED}Stage '$STAGE' has $FAIL failure(s). Fix before advancing.${NC}"
  exit 1
fi
