# Stage Validation Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modify the existing `validate-stage-completion.sh` script to add TDD evidence checks to the devs stage, CERTIFICATION.md support to the verify stage, and auto-save to Feature Memory on successful validation.

**Architecture:** The devs stage gets a new Check 4 that verifies `.evidence/tdd/` has green logs. The verify stage is updated to accept CERTIFICATION.md (new) or QA-REPORT.md (legacy) and checks `.evidence/verification/` for phase gate files. On successful validation, the script calls `save-feature-memory.sh` to auto-update the FMU.

**Tech Stack:** Bash, Markdown

**Parent plan:** `_index.md`
**Depends on:** @plan-protocols (evidence spec defined in `_hard-gates.md`), @plan-scripts (calls `save-feature-memory.sh` hook)

---

## Task 1: Modify `validate-stage-completion.sh` — add evidence checks

**Files:**
- Modify: `scripts/validate/validate-stage-completion.sh`

- [ ] **Step 1: Add evidence check to `devs` stage**

After the existing devs checks (file ownership, line ~140), add:

```bash
      # Check 4: TDD evidence exists for assigned REQ-IDs
      if [[ -n "$OWNERSHIP" ]]; then
        EVIDENCE_DIR="$(cd "$MILESTONE_DIR/../.." && pwd)/.evidence/tdd"
        if [[ -d "$EVIDENCE_DIR" ]]; then
          # Count evidence files that match any log pattern
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
```

- [ ] **Step 2: Update `verify` stage to check for CERTIFICATION.md**

Replace the verify stage check (lines 200-206) with:

```bash
  verify)
    # CERTIFICATION.md or QA-REPORT.md must exist (backwards compat)
    if [[ -f "$MILESTONE_DIR/CERTIFICATION.md" ]]; then
      pass "CERTIFICATION.md exists"
      # Check for unresolved entries
      UNRESOLVED=$(grep -ciE 'UNRESOLVED' "$MILESTONE_DIR/CERTIFICATION.md" 2>/dev/null || echo 0)
      if [[ "$UNRESOLVED" -eq 0 ]]; then
        pass "No unresolved entries in CERTIFICATION.md"
      else
        fail "CERTIFICATION.md has $UNRESOLVED unresolved entries"
      fi
    elif [[ -f "$MILESTONE_DIR/QA-REPORT.md" ]]; then
      pass "QA-REPORT.md exists (legacy format accepted)"
    else
      fail "Neither CERTIFICATION.md nor QA-REPORT.md found — verify must produce one"
    fi

    # Evidence directory check
    PROJECT_ROOT="$(cd "$MILESTONE_DIR/../.." && pwd)"
    EVIDENCE_DIR="$PROJECT_ROOT/.evidence"
    if [[ -d "$EVIDENCE_DIR/verification" ]]; then
      GATE_COUNT=$(find "$EVIDENCE_DIR/verification" -name "phase-*" 2>/dev/null | wc -l | tr -d ' ')
      if [[ "$GATE_COUNT" -gt 0 ]]; then
        pass "Verification evidence: $GATE_COUNT phase gate file(s)"
      else
        fail "Verification evidence directory exists but no phase gate files found"
      fi
    else
      fail ".evidence/verification/ missing — phase gates must save evidence"
    fi

    # Existing GAPS + GOTCHAS check (preserved from original)
```

- [ ] **Step 3: Add `save-feature-memory.sh` call at the end of successful validation**

Before the final summary (line 264), add:

```bash
# Auto-save to Feature Memory on successful validation
if [[ $FAIL -eq 0 ]]; then
  FEATURE_SLUG=$(basename "$FEATURE_DIR")
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  MEMORY_HOOK="$SCRIPT_DIR/../hooks/save-feature-memory.sh"
  if [[ -x "$MEMORY_HOOK" ]]; then
    bash "$MEMORY_HOOK" "$FEATURE_SLUG" "$STAGE" "$MILESTONE_DIR" 2>/dev/null || true
  fi
fi
```

- [ ] **Step 4: Commit**

```bash
git add scripts/validate/validate-stage-completion.sh
git commit -m "feat: add TDD evidence and CERTIFICATION.md checks to stage validation"
```
