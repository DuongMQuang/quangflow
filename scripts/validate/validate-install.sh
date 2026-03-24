#!/usr/bin/env bash
# Validates QuangFlow installation integrity.
# Checks: command files, agent files, cross-references, gate keywords.
#
# Usage:
#   bash scripts/validate/validate-install.sh [commands-dir]
#   commands-dir defaults to ./commands if not specified

set -euo pipefail

# --- Config ---
COMMANDS_DIR="${1:-./commands}"
AGENTS_DIR="$(dirname "$COMMANDS_DIR")/agents"
PASS=0; FAIL=0; WARN=0

# --- Colors ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; WARN=$((WARN + 1)); }

echo -e "${BOLD}QuangFlow Install Validator${NC}"
echo "==========================="
echo ""

# --- Check 1: Command files exist ---
EXPECTED_COMMANDS=(
  "qf/_shared.md" "qf/_autopilot.md"
  "qf/0-init.md" "qf/1-brainstorm.md" "qf/2-design.md"
  "qf/3-handoff.md" "qf/4-verify.md" "qf/5-maintain.md"
  "qf/quick.md" "qf/cook.md" "qf/status.md" "qf/test.md" "qf/update.md"
)
MISSING_CMDS=0
for cmd in "${EXPECTED_COMMANDS[@]}"; do
  if [[ ! -f "$COMMANDS_DIR/$cmd" ]]; then
    fail "Missing command: $cmd"
    MISSING_CMDS=$((MISSING_CMDS + 1))
  fi
done
if [[ $MISSING_CMDS -eq 0 ]]; then
  pass "Command files: ${#EXPECTED_COMMANDS[@]}/${#EXPECTED_COMMANDS[@]} found"
fi

# --- Check 2: Agent files exist ---
EXPECTED_AGENTS=("_shared.md" "domain-engineer.md" "dev-teammate.md" "tech-lead.md" "tester.md" "pm.md" "critic.md")
MISSING_AGENTS=0
for agent in "${EXPECTED_AGENTS[@]}"; do
  if [[ ! -f "$AGENTS_DIR/$agent" ]]; then
    fail "Missing agent: $agent"
    MISSING_AGENTS=$((MISSING_AGENTS + 1))
  fi
done
if [[ $MISSING_AGENTS -eq 0 ]]; then
  pass "Agent files: ${#EXPECTED_AGENTS[@]}/${#EXPECTED_AGENTS[@]} found"
fi

# --- Check 3: No broken cross-references ---
# Grep for /qf: references and verify each target command file exists
BROKEN_REFS=0
if [[ -d "$COMMANDS_DIR/qf" ]]; then
  # Extract unique command references like /qf:0-init, /qf:cook, etc.
  REFS=$(grep -rohE '/qf:[a-z0-9][a-z0-9-]+' "$COMMANDS_DIR/qf/" "$AGENTS_DIR/" 2>/dev/null | sort -u || true)
  for ref in $REFS; do
    # Extract the command name after /qf:
    CMD_NAME="${ref#/qf:}"
    # Check if corresponding .md file exists
    if [[ ! -f "$COMMANDS_DIR/qf/${CMD_NAME}.md" ]]; then
      # Could be a template pattern like /qf:{N}-{phase} — skip those
      if [[ "$CMD_NAME" == *"{"* ]]; then
        continue
      fi
      fail "Broken reference: $ref -> missing $COMMANDS_DIR/qf/${CMD_NAME}.md"
      BROKEN_REFS=$((BROKEN_REFS + 1))
    fi
  done
  if [[ $BROKEN_REFS -eq 0 ]]; then
    pass "Cross-references: 0 broken"
  fi
fi

# --- Check 4: Gate keywords per phase ---
GATE_CHECKS=0
check_gate() {
  local file="$1" keyword="$2" phase="$3"
  if grep -q "$keyword" "$file" 2>/dev/null; then
    GATE_CHECKS=$((GATE_CHECKS + 1))
  else
    fail "Missing gate keyword '$keyword' in $phase"
  fi
}

check_gate "$COMMANDS_DIR/qf/1-brainstorm.md" "APPROVE" "1-brainstorm"
check_gate "$COMMANDS_DIR/qf/2-design.md" "Which option" "2-design"
check_gate "$COMMANDS_DIR/qf/3-handoff.md" "CONFIRM" "3-handoff"
check_gate "$COMMANDS_DIR/qf/4-verify.md" "SHIP" "4-verify"
check_gate "$COMMANDS_DIR/qf/5-maintain.md" "FIX NOW" "5-maintain"

if [[ $GATE_CHECKS -eq 5 ]]; then
  pass "Gate keywords: all 5 phases have review gates"
fi

# --- Check 5: Severity levels in maintain ---
SEVERITY_COUNT=0
for level in CRITICAL ERROR WARNING INFO; do
  if grep -q "$level" "$COMMANDS_DIR/qf/5-maintain.md" 2>/dev/null; then
    SEVERITY_COUNT=$((SEVERITY_COUNT + 1))
  fi
done
if [[ $SEVERITY_COUNT -eq 4 ]]; then
  pass "Severity levels: all 4 in 5-maintain"
else
  fail "Severity levels: only $SEVERITY_COUNT/4 found in 5-maintain"
fi

# --- Check 6: Status covers all phases ---
STATUS_PHASES=0
for phase in "0-init" "1-brainstorm" "2-design" "3-handoff" "4-verify" "5-maintain"; do
  if grep -q "$phase\|Phase ${phase:0:1}" "$COMMANDS_DIR/qf/status.md" 2>/dev/null; then
    STATUS_PHASES=$((STATUS_PHASES + 1))
  fi
done
if [[ $STATUS_PHASES -ge 5 ]]; then
  pass "Status coverage: references $STATUS_PHASES/6 phases"
else
  warn "Status coverage: only $STATUS_PHASES/6 phases referenced"
fi

# --- Check 7: No legacy qf- references ---
LEGACY_REFS="$(grep -rl '/qf-[0-9a-z]' "$COMMANDS_DIR/" "$AGENTS_DIR/" 2>/dev/null | wc -l | tr -d ' ' || true)"
LEGACY_REFS="${LEGACY_REFS:-0}"
if [[ "$LEGACY_REFS" -eq 0 ]]; then
  pass "No legacy /qf- references found"
else
  fail "Found $LEGACY_REFS legacy /qf- references (should be /qf:)"
fi

# --- Check 8: Version file ---
VERSION_FILE="$(dirname "$COMMANDS_DIR")/.quangflow-version"
if [[ -f "$VERSION_FILE" ]]; then
  pass "Version file: v$(cat "$VERSION_FILE")"
else
  warn "No .quangflow-version file found"
fi

# --- Summary ---
echo ""
TOTAL=$((PASS + FAIL + WARN))
echo -e "${BOLD}Result: $PASS passed, $FAIL failed, $WARN warnings (of $TOTAL checks)${NC}"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}QuangFlow installation is valid.${NC}"
  exit 0
else
  echo -e "${RED}QuangFlow installation has issues. Fix the failures above.${NC}"
  exit 1
fi
