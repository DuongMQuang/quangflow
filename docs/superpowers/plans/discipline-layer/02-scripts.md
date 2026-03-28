# Validation & Hook Scripts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the validation scripts (TDD coverage, evidence, memory) and hook scripts (auto-checkpoint, evidence tracker, feature memory save) that provide system-level enforcement of the discipline protocols.

**Architecture:** Three validation scripts in `scripts/validate/` check evidence artifacts at phase gates. Three hook scripts in `scripts/hooks/` auto-track progress via PostToolUse and phase transition events. Scripts use colored output and exit codes (0=pass, 1=block) for pipeline integration.

**Tech Stack:** Bash, Markdown

**Parent plan:** `_index.md`
**Depends on:** @plan-protocols (scripts validate artifacts defined by protocols)

---

## Task 1: Create validation scripts

**Files:**
- Create: `scripts/validate/validate-tdd-coverage.sh`
- Create: `scripts/validate/validate-evidence.sh`
- Create: `scripts/validate/validate-memory.sh`

- [ ] **Step 1: Create `validate-tdd-coverage.sh`**

```bash
#!/usr/bin/env bash
# Validates TDD evidence coverage: every REQ-ID must have red + green logs.
#
# Usage:
#   bash scripts/validate/validate-tdd-coverage.sh <plans-feature-dir>
#
# Reads REQUIREMENTS.md for REQ-IDs, checks .evidence/tdd/ for matching logs.
# Exit codes: 0 = pass, 1 = block

set -euo pipefail

FEATURE_DIR="${1:-}"
if [[ -z "$FEATURE_DIR" ]]; then
  echo "Usage: validate-tdd-coverage.sh <plans-feature-dir>"
  exit 1
fi

# Find project root (parent of plans/)
PROJECT_ROOT="$(cd "$FEATURE_DIR/../.." 2>/dev/null && pwd || cd "$FEATURE_DIR/.." && pwd)"
EVIDENCE_DIR="$PROJECT_ROOT/.evidence/tdd"
REQS_FILE="$FEATURE_DIR/REQUIREMENTS.md"

PASS=0; FAIL=0
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }

echo -e "${BOLD}TDD Coverage Validation${NC}"
echo "Feature: $FEATURE_DIR"
echo ""

# Check REQUIREMENTS.md exists
if [[ ! -f "$REQS_FILE" ]]; then
  fail "REQUIREMENTS.md not found at $REQS_FILE"
  echo -e "\n${RED}Validation failed. 1 failure(s).${NC}"
  exit 1
fi

# Extract REQ-IDs
REQ_IDS=$(grep -oE 'REQ-[0-9]+' "$REQS_FILE" | sort -u)
if [[ -z "$REQ_IDS" ]]; then
  fail "No REQ-IDs found in REQUIREMENTS.md"
  echo -e "\n${RED}Validation failed. 1 failure(s).${NC}"
  exit 1
fi

REQ_COUNT=$(echo "$REQ_IDS" | wc -l | tr -d ' ')
echo "Found $REQ_COUNT REQ-IDs to check"
echo ""

# Check evidence directory exists
if [[ ! -d "$EVIDENCE_DIR" ]]; then
  fail ".evidence/tdd/ directory does not exist"
  echo "All $REQ_COUNT REQ-IDs are missing TDD evidence"
  echo -e "\n${RED}Validation failed.${NC}"
  exit 1
fi

# Check each REQ-ID has red + green logs
while IFS= read -r req_id; do
  RED_LOG="$EVIDENCE_DIR/${req_id}-red.log"
  GREEN_LOG="$EVIDENCE_DIR/${req_id}-green.log"

  # Check red log
  if [[ -f "$RED_LOG" ]]; then
    # Verify it contains a failure indicator
    if grep -qiE 'FAIL|ERROR|FAILED|AssertionError' "$RED_LOG" 2>/dev/null; then
      pass "$req_id: red log exists and contains failure"
    else
      fail "$req_id: red log exists but does NOT contain failure indicator (FAIL/ERROR)"
    fi
  else
    fail "$req_id: red log missing (.evidence/tdd/${req_id}-red.log)"
  fi

  # Check green log
  if [[ -f "$GREEN_LOG" ]]; then
    # Verify it contains a pass indicator and no failures
    if grep -qiE 'PASS|OK|SUCCESS|passed' "$GREEN_LOG" 2>/dev/null; then
      if grep -qiE 'FAIL|ERROR|FAILED' "$GREEN_LOG" 2>/dev/null; then
        fail "$req_id: green log contains both PASS and FAIL — tests not fully passing"
      else
        pass "$req_id: green log exists and all tests pass"
      fi
    else
      fail "$req_id: green log exists but does NOT contain pass indicator (PASS/OK/SUCCESS)"
    fi
  else
    fail "$req_id: green log missing (.evidence/tdd/${req_id}-green.log)"
  fi
done <<< "$REQ_IDS"

# Summary
echo ""
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}TDD coverage complete. All $REQ_COUNT REQ-IDs have valid evidence.${NC}"
  exit 0
else
  echo -e "${RED}TDD coverage incomplete. $FAIL failure(s) out of $TOTAL checks.${NC}"
  exit 1
fi
```

- [ ] **Step 2: Create `validate-evidence.sh`**

```bash
#!/usr/bin/env bash
# Validates evidence artifacts exist for a given phase transition.
#
# Usage:
#   bash scripts/validate/validate-evidence.sh <plans-feature-dir> <phase>
#
# Phases: 1, 2, 3, 4 (checks evidence required to EXIT that phase)
# Exit codes: 0 = pass, 1 = block

set -euo pipefail

FEATURE_DIR="${1:-}"
PHASE="${2:-}"

if [[ -z "$FEATURE_DIR" || -z "$PHASE" ]]; then
  echo "Usage: validate-evidence.sh <plans-feature-dir> <phase>"
  exit 1
fi

PROJECT_ROOT="$(cd "$FEATURE_DIR/../.." 2>/dev/null && pwd || cd "$FEATURE_DIR/.." && pwd)"
EVIDENCE_DIR="$PROJECT_ROOT/.evidence"

PASS=0; FAIL=0
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }

echo -e "${BOLD}Evidence Validation — Phase $PHASE${NC}"
echo "Feature: $FEATURE_DIR"
echo ""

case "$PHASE" in
  1)
    # Phase 1 → 2: REQUIREMENTS.md with REQ-IDs
    REQS="$FEATURE_DIR/REQUIREMENTS.md"
    if [[ -f "$REQS" ]]; then
      REQ_COUNT=$(grep -cE 'REQ-[0-9]+' "$REQS" 2>/dev/null || echo 0)
      if [[ "$REQ_COUNT" -gt 0 ]]; then
        pass "REQUIREMENTS.md has $REQ_COUNT REQ-IDs"
      else
        fail "REQUIREMENTS.md exists but has no REQ-IDs"
      fi
    else
      fail "REQUIREMENTS.md missing"
    fi

    # Phase gate evidence
    GATE="$EVIDENCE_DIR/verification/phase-1-gate.md"
    if [[ -f "$GATE" ]]; then
      pass "Phase 1 gate evidence exists"
    else
      fail "Phase 1 gate evidence missing (.evidence/verification/phase-1-gate.md)"
    fi
    ;;

  2)
    # Phase 2 → 3: DESIGN.md with chosen option
    # Find milestone dir (most recent)
    MILESTONE_DIR=$(find "$FEATURE_DIR" -maxdepth 1 -name "milestone-*" -type d | sort -V | tail -1)
    if [[ -n "$MILESTONE_DIR" ]]; then
      DESIGN="$MILESTONE_DIR/DESIGN.md"
    else
      DESIGN="$FEATURE_DIR/DESIGN.md"
    fi

    if [[ -f "$DESIGN" ]]; then
      pass "DESIGN.md exists"
    else
      fail "DESIGN.md missing"
    fi

    GATE="$EVIDENCE_DIR/verification/phase-2-gate.md"
    if [[ -f "$GATE" ]]; then
      pass "Phase 2 gate evidence exists"
    else
      fail "Phase 2 gate evidence missing (.evidence/verification/phase-2-gate.md)"
    fi
    ;;

  3)
    # Phase 3 → 4: TDD coverage + all tests green
    echo "Running TDD coverage check..."
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if bash "$SCRIPT_DIR/validate-tdd-coverage.sh" "$FEATURE_DIR"; then
      pass "TDD coverage validation passed"
    else
      fail "TDD coverage validation failed — see above"
    fi

    GATE="$EVIDENCE_DIR/verification/phase-3-gate.md"
    if [[ -f "$GATE" ]]; then
      pass "Phase 3 gate evidence exists"
    else
      fail "Phase 3 gate evidence missing (.evidence/verification/phase-3-gate.md)"
    fi
    ;;

  4)
    # Phase 4 → ship: CERTIFICATION.md OR QA-REPORT.md (backwards compat)
    MILESTONE_DIR=$(find "$FEATURE_DIR" -maxdepth 1 -name "milestone-*" -type d | sort -V | tail -1)
    if [[ -n "$MILESTONE_DIR" ]]; then
      CHECK_DIR="$MILESTONE_DIR"
    else
      CHECK_DIR="$FEATURE_DIR"
    fi

    if [[ -f "$CHECK_DIR/CERTIFICATION.md" ]]; then
      pass "CERTIFICATION.md exists"
      # Check for UNRESOLVED entries
      UNRESOLVED=$(grep -ciE 'UNRESOLVED|unresolved' "$CHECK_DIR/CERTIFICATION.md" 2>/dev/null || echo 0)
      if [[ "$UNRESOLVED" -eq 0 ]]; then
        pass "No unresolved entries in CERTIFICATION.md"
      else
        fail "CERTIFICATION.md has $UNRESOLVED unresolved entries"
      fi
    elif [[ -f "$CHECK_DIR/QA-REPORT.md" ]]; then
      pass "QA-REPORT.md exists (legacy format accepted)"
    else
      fail "Neither CERTIFICATION.md nor QA-REPORT.md found"
    fi

    GATE="$EVIDENCE_DIR/verification/phase-4-certification.md"
    if [[ -f "$GATE" ]]; then
      pass "Phase 4 certification evidence exists"
    else
      # Also accept phase-4-gate.md as legacy
      if [[ -f "$EVIDENCE_DIR/verification/phase-4-gate.md" ]]; then
        pass "Phase 4 gate evidence exists (legacy name)"
      else
        fail "Phase 4 certification evidence missing"
      fi
    fi
    ;;

  *)
    fail "Unknown phase: $PHASE (expected 1, 2, 3, or 4)"
    ;;
esac

# Summary
echo ""
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}Phase $PHASE evidence complete. OK to advance.${NC}"
  exit 0
else
  echo -e "${RED}Phase $PHASE evidence incomplete. $FAIL failure(s).${NC}"
  exit 1
fi
```

- [ ] **Step 3: Create `validate-memory.sh`**

```bash
#!/usr/bin/env bash
# Validates Feature Memory Unit structure.
#
# Usage:
#   bash scripts/validate/validate-memory.sh [feature-name]
#
# Without args: validates all FMUs. With arg: validates one FMU.
# Checks: required files, index consistency, bidirectional links, no orphans.
# Exit codes: 0 = pass, 1 = issues found

set -euo pipefail

FEATURE="${1:-}"
MEMORY_DIR=".memory"

PASS=0; FAIL=0; WARN=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; WARN=$((WARN + 1)); }

echo -e "${BOLD}Feature Memory Validation${NC}"
echo ""

# Check .memory/ exists
if [[ ! -d "$MEMORY_DIR" ]]; then
  echo "No .memory/ directory found. Feature Memory not yet initialized."
  exit 0
fi

# Check _index.md exists
INDEX="$MEMORY_DIR/_index.md"
if [[ -f "$INDEX" ]]; then
  pass "_index.md exists"
else
  fail "_index.md missing — create it with the FMU index table"
  exit 1
fi

# Get list of FMU directories
if [[ -n "$FEATURE" ]]; then
  FMUS="$MEMORY_DIR/$FEATURE"
  if [[ ! -d "$FMUS" ]]; then
    fail "FMU directory not found: $FMUS"
    exit 1
  fi
  FMU_LIST="$FEATURE"
else
  FMU_LIST=$(find "$MEMORY_DIR" -mindepth 1 -maxdepth 1 -type d -not -name '_*' -exec basename {} \; | sort)
fi

if [[ -z "$FMU_LIST" ]]; then
  echo "No FMU directories found."
  exit 0
fi

FMU_COUNT=$(echo "$FMU_LIST" | wc -l | tr -d ' ')
echo "Found $FMU_COUNT FMU(s) to validate"
echo ""

while IFS= read -r fmu; do
  FMU_DIR="$MEMORY_DIR/$fmu"
  echo -e "${BOLD}--- @$fmu ---${NC}"

  # Required: CONTEXT.md
  if [[ -f "$FMU_DIR/CONTEXT.md" ]]; then
    pass "CONTEXT.md exists"
  else
    fail "CONTEXT.md missing — every FMU needs a context file"
  fi

  # Optional but expected: LINKS.md
  if [[ -f "$FMU_DIR/LINKS.md" ]]; then
    pass "LINKS.md exists"

    # Check bidirectional links
    DEPS=$(grep -oE '@[a-zA-Z0-9_-]+' "$FMU_DIR/LINKS.md" 2>/dev/null | sort -u || true)
    for dep in $DEPS; do
      DEP_NAME="${dep#@}"
      DEP_LINKS="$MEMORY_DIR/$DEP_NAME/LINKS.md"
      if [[ -f "$DEP_LINKS" ]]; then
        if grep -q "@$fmu" "$DEP_LINKS" 2>/dev/null; then
          pass "Bidirectional link: @$fmu <-> $dep"
        else
          fail "One-way link: @$fmu -> $dep but $dep does not link back to @$fmu"
        fi
      else
        warn "$dep referenced in LINKS.md but has no LINKS.md of its own"
      fi
    done
  else
    warn "LINKS.md missing — add if this feature has dependencies"
  fi

  # Check _index.md has this FMU listed
  if grep -q "@$fmu" "$INDEX" 2>/dev/null; then
    pass "Listed in _index.md"
  else
    fail "@$fmu not listed in _index.md — add it to the index"
  fi

  echo ""
done <<< "$FMU_LIST"

# Check for orphans: FMUs in _index.md but no directory
echo -e "${BOLD}--- Orphan check ---${NC}"
INDEX_FMUS=$(grep -oE '@[a-zA-Z0-9_-]+' "$INDEX" 2>/dev/null | sed 's/@//' | sort -u || true)
for idx_fmu in $INDEX_FMUS; do
  if [[ ! -d "$MEMORY_DIR/$idx_fmu" ]]; then
    fail "Orphan in _index.md: @$idx_fmu listed but directory does not exist"
  fi
done

# Summary
echo ""
TOTAL=$((PASS + FAIL + WARN))
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}Memory validation passed. $PASS checks OK, $WARN warnings.${NC}"
  exit 0
else
  echo -e "${RED}Memory validation found $FAIL issue(s). Fix before proceeding.${NC}"
  exit 1
fi
```

- [ ] **Step 4: Make all three scripts executable**

Run: `chmod +x scripts/validate/validate-tdd-coverage.sh scripts/validate/validate-evidence.sh scripts/validate/validate-memory.sh`

- [ ] **Step 5: Commit**

```bash
git add scripts/validate/validate-tdd-coverage.sh scripts/validate/validate-evidence.sh scripts/validate/validate-memory.sh
git commit -m "feat: add validation scripts — TDD coverage, evidence, and memory checks"
```

---

## Task 2: Create hook scripts

**Files:**
- Create: `scripts/hooks/auto-checkpoint.sh`
- Create: `scripts/hooks/evidence-tracker.sh`
- Create: `scripts/hooks/save-feature-memory.sh`

- [ ] **Step 1: Create `auto-checkpoint.sh`**

```bash
#!/usr/bin/env bash
# PostToolUse hook: auto-appends file changes to CHECKPOINT-{role}.md
#
# Hook config (add to .claude/settings.json):
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Write|Edit",
#       "command": "bash .claude/scripts/hooks/auto-checkpoint.sh"
#     }]
#   }
#
# Reads tool_input from stdin (JSON with file_path field).
# Requires QF_AGENT_ROLE env var to be set by cook.md.

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//' || true)

if [[ -z "$FILE_PATH" ]]; then
  exit 0  # No file path found, skip silently
fi

# Skip if not in an agent context
ROLE="${QF_AGENT_ROLE:-}"
if [[ -z "$ROLE" ]]; then
  exit 0  # Not running as a cook agent, skip
fi

# Find milestone dir from env
MILESTONE_DIR="${QF_MILESTONE_DIR:-}"
if [[ -z "$MILESTONE_DIR" || ! -d "$MILESTONE_DIR" ]]; then
  exit 0  # No milestone context, skip
fi

CHECKPOINT="$MILESTONE_DIR/CHECKPOINT-${ROLE}.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create checkpoint if it doesn't exist
if [[ ! -f "$CHECKPOINT" ]]; then
  cat > "$CHECKPOINT" << EOF
# Checkpoint — $ROLE
Updated: $TIMESTAMP

## Files Modified
EOF
fi

# Append the file change
echo "- $FILE_PATH ($TIMESTAMP)" >> "$CHECKPOINT"

# Update the timestamp
sed -i "s/^Updated: .*/Updated: $TIMESTAMP/" "$CHECKPOINT"
```

- [ ] **Step 2: Create `evidence-tracker.sh`**

```bash
#!/usr/bin/env bash
# PostToolUse hook: tracks evidence artifacts in PIPELINE-STATE.md
#
# Hook config (add to .claude/settings.json):
#   "hooks": {
#     "PostToolUse": [{
#       "matcher": "Write|Edit",
#       "command": "bash .claude/scripts/hooks/evidence-tracker.sh"
#     }]
#   }
#
# Monitors writes to .evidence/ and updates PIPELINE-STATE.md with evidence status.

set -euo pipefail

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//' || true)

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Only track writes to .evidence/
case "$FILE_PATH" in
  *.evidence/*|*/.evidence/*) ;;
  *) exit 0 ;;
esac

MILESTONE_DIR="${QF_MILESTONE_DIR:-}"
if [[ -z "$MILESTONE_DIR" || ! -d "$MILESTONE_DIR" ]]; then
  exit 0
fi

PIPELINE_STATE="$MILESTONE_DIR/PIPELINE-STATE.md"
if [[ ! -f "$PIPELINE_STATE" ]]; then
  exit 0
fi

# Extract REQ-ID or BUG-ID from filename
BASENAME=$(basename "$FILE_PATH")
ID=$(echo "$BASENAME" | grep -oE '(REQ|BUG)-[0-9]+' || true)

if [[ -z "$ID" ]]; then
  exit 0
fi

# Determine evidence type from path
TYPE=""
case "$FILE_PATH" in
  *tdd*red*) TYPE="red" ;;
  *tdd*green*) TYPE="green" ;;
  *verification*) TYPE="verified" ;;
  *debug*investigation*) TYPE="investigated" ;;
  *debug*resolution*) TYPE="resolved" ;;
esac

if [[ -z "$TYPE" ]]; then
  exit 0
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Append evidence tracking to PIPELINE-STATE if section exists
if grep -q "## Evidence Status" "$PIPELINE_STATE" 2>/dev/null; then
  # Update existing entry or add new one
  if grep -q "$ID" "$PIPELINE_STATE" 2>/dev/null; then
    # Entry exists — update the specific type
    sed -i "s/\($ID.*${TYPE}\) [XY-]/\1 Y/" "$PIPELINE_STATE"
  else
    # New entry
    echo "- $ID: $TYPE Y | ($TIMESTAMP)" >> "$PIPELINE_STATE"
  fi
else
  # Add Evidence Status section
  echo "" >> "$PIPELINE_STATE"
  echo "## Evidence Status" >> "$PIPELINE_STATE"
  echo "- $ID: $TYPE Y | ($TIMESTAMP)" >> "$PIPELINE_STATE"
fi
```

- [ ] **Step 3: Create `save-feature-memory.sh`**

```bash
#!/usr/bin/env bash
# Phase transition hook: auto-updates Feature Memory Unit on phase completion.
#
# Usage:
#   bash scripts/hooks/save-feature-memory.sh <feature-slug> <phase> <milestone-dir>
#
# Called by validate-stage-completion.sh after a phase passes validation.
# Extracts key info from phase artifacts and writes to .memory/{feature}/

set -euo pipefail

FEATURE="${1:-}"
PHASE="${2:-}"
MILESTONE_DIR="${3:-}"

if [[ -z "$FEATURE" || -z "$PHASE" ]]; then
  exit 0  # Missing args, skip silently
fi

MEMORY_DIR=".memory/$FEATURE"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
INDEX=".memory/_index.md"

# Create .memory/ and FMU directory if needed
mkdir -p "$MEMORY_DIR"

# Create _index.md if missing
if [[ ! -f "$INDEX" ]]; then
  cat > "$INDEX" << 'EOF'
# Feature Memory Index

| Feature | Status | Dependencies | Last updated |
|---------|--------|-------------|--------------|
EOF
fi

# Add to index if not present
if ! grep -q "@$FEATURE" "$INDEX" 2>/dev/null; then
  echo "| @$FEATURE | active | — | $TIMESTAMP |" >> "$INDEX"
fi

# Update timestamp in index
sed -i "s/\(@$FEATURE.*|\)[^|]*|$/\1 $TIMESTAMP |/" "$INDEX"

case "$PHASE" in
  0-init|init)
    # Create CONTEXT.md from plans artifacts
    FEATURE_DIR="$(dirname "$MILESTONE_DIR" 2>/dev/null || echo "plans/$FEATURE")"
    CONTEXT_SRC="$FEATURE_DIR/CONTEXT.md"
    if [[ -f "$CONTEXT_SRC" && ! -f "$MEMORY_DIR/CONTEXT.md" ]]; then
      cp "$CONTEXT_SRC" "$MEMORY_DIR/CONTEXT.md"
    fi
    ;;

  1-brainstorm|brainstorm)
    # Copy requirements to FMU
    FEATURE_DIR="$(dirname "$MILESTONE_DIR" 2>/dev/null || echo "plans/$FEATURE")"
    REQS_SRC="$FEATURE_DIR/REQUIREMENTS.md"
    if [[ -f "$REQS_SRC" ]]; then
      cp "$REQS_SRC" "$MEMORY_DIR/REQUIREMENTS.md"
    fi
    ;;

  2-design|design)
    # Copy design to FMU
    if [[ -n "$MILESTONE_DIR" && -f "$MILESTONE_DIR/DESIGN.md" ]]; then
      cp "$MILESTONE_DIR/DESIGN.md" "$MEMORY_DIR/DESIGN.md"
    fi
    ;;

  4-verify|verify)
    # Append verification summary to HISTORY.md
    HISTORY="$MEMORY_DIR/HISTORY.md"
    if [[ ! -f "$HISTORY" ]]; then
      echo "# Decision History — $FEATURE" > "$HISTORY"
      echo "" >> "$HISTORY"
    fi
    echo "- **$TIMESTAMP** — Phase 4 verified. Milestone certified." >> "$HISTORY"
    ;;

  5-maintain|maintain)
    # Bug fixes auto-append to GOTCHAS.md via the debugging protocol
    # This hook just updates HISTORY.md
    HISTORY="$MEMORY_DIR/HISTORY.md"
    if [[ ! -f "$HISTORY" ]]; then
      echo "# Decision History — $FEATURE" > "$HISTORY"
      echo "" >> "$HISTORY"
    fi
    echo "- **$TIMESTAMP** — Maintenance session completed." >> "$HISTORY"
    ;;
esac
```

- [ ] **Step 4: Make all three scripts executable**

Run: `chmod +x scripts/hooks/auto-checkpoint.sh scripts/hooks/evidence-tracker.sh scripts/hooks/save-feature-memory.sh`

- [ ] **Step 5: Commit**

```bash
git add scripts/hooks/auto-checkpoint.sh scripts/hooks/evidence-tracker.sh scripts/hooks/save-feature-memory.sh
git commit -m "feat: add progress hooks — auto-checkpoint, evidence tracking, FMU save"
```
