#!/usr/bin/env bash
# Builds scoped context for a specific agent role.
# Extracts only relevant sections from project artifacts — deterministic, no LLM filtering.
#
# Usage:
#   bash scripts/build-agent-context.sh --role <role> --milestone-dir <path> [options]
#
# Options:
#   --role <role>           Agent role (dev-backend, dev-frontend, tester, tech-lead, etc.)
#   --milestone-dir <path>  Path to milestone directory
#   --ownership <globs>     File ownership globs, comma-separated (for dev roles)
#   --reqs <ids>            REQ-IDs assigned to this role, comma-separated
#   --phases <nums>         ROADMAP phase numbers assigned, comma-separated
#   --output <path>         Output file path (default: stdout)
#
# Output: A single markdown file with all scoped context for the agent

set -euo pipefail

ROLE=""
MILESTONE_DIR=""
OWNERSHIP=""
REQS=""
PHASES=""
OUTPUT="/dev/stdout"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role) ROLE="$2"; shift 2 ;;
    --milestone-dir) MILESTONE_DIR="$2"; shift 2 ;;
    --ownership) OWNERSHIP="$2"; shift 2 ;;
    --reqs) REQS="$2"; shift 2 ;;
    --phases) PHASES="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$ROLE" || -z "$MILESTONE_DIR" ]]; then
  echo "Usage: build-agent-context.sh --role <role> --milestone-dir <path> [--ownership <globs>] [--reqs <ids>] [--phases <nums>]" >&2
  exit 1
fi

FEATURE_DIR="$(dirname "$MILESTONE_DIR")"
DESIGN_DIR="$MILESTONE_DIR/design"

# --- Helper: extract sections matching a pattern from a markdown file ---
extract_sections() {
  local file="$1"
  local pattern="$2"
  if [[ ! -f "$file" ]]; then return; fi
  # Extract ## or ### sections whose heading matches the pattern (case-insensitive)
  awk -v pat="$pattern" '
    BEGIN { IGNORECASE=1; printing=0 }
    /^##/ {
      if ($0 ~ pat) { printing=1 }
      else if (printing) { printing=0 }
    }
    printing { print }
  ' "$file"
}

# --- Helper: extract lines containing specific REQ-IDs ---
extract_reqs() {
  local file="$1"
  local req_ids="$2"
  if [[ ! -f "$file" || -z "$req_ids" ]]; then return; fi
  IFS=',' read -ra IDS <<< "$req_ids"
  for id in "${IDS[@]}"; do
    id=$(echo "$id" | tr -d ' ')
    grep -i "$id" "$file" 2>/dev/null || true
  done
}

# --- Helper: extract ROADMAP phases by number ---
extract_phases() {
  local file="$1"
  local phase_nums="$2"
  if [[ ! -f "$file" || -z "$phase_nums" ]]; then
    # No filter — return full file
    cat "$file" 2>/dev/null || true
    return
  fi
  IFS=',' read -ra NUMS <<< "$phase_nums"
  for num in "${NUMS[@]}"; do
    num=$(echo "$num" | tr -d ' ')
    # Extract "## Phase N" sections
    awk -v n="$num" '
      /^## Phase/ {
        if ($0 ~ "Phase " n "[^0-9]" || $0 ~ "Phase " n "$") { printing=1 }
        else if (printing) { printing=0 }
      }
      printing { print }
    ' "$file"
    echo ""
  done
}

# --- Build context based on role ---
{
  echo "# Scoped Context — ${ROLE}"
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""

  case "$ROLE" in
    dev-*)
      # Dev agents get scoped slices
      echo "## Assigned Ownership"
      echo "$OWNERSHIP"
      echo ""

      echo "## Assigned Requirements"
      if [[ -f "$FEATURE_DIR/REQUIREMENTS.md" && -n "$REQS" ]]; then
        extract_reqs "$FEATURE_DIR/REQUIREMENTS.md" "$REQS"
      else
        echo "(no specific REQ-IDs assigned)"
      fi
      echo ""

      echo "## Assigned ROADMAP Phases"
      if [[ -f "$MILESTONE_DIR/ROADMAP.md" ]]; then
        extract_phases "$MILESTONE_DIR/ROADMAP.md" "$PHASES"
      fi
      echo ""

      echo "## Relevant Contracts"
      if [[ -f "$DESIGN_DIR/CONTRACTS.md" ]]; then
        # Extract sections that mention any of the ownership paths
        if [[ -n "$OWNERSHIP" ]]; then
          IFS=',' read -ra GLOBS <<< "$OWNERSHIP"
          for glob in "${GLOBS[@]}"; do
            PREFIX="${glob%%\**}"
            PREFIX=$(echo "$PREFIX" | tr -d ' ' | sed 's|/$||')
            grep -A 20 -i "$PREFIX" "$DESIGN_DIR/CONTRACTS.md" 2>/dev/null || true
          done | sort -u
        else
          cat "$DESIGN_DIR/CONTRACTS.md"
        fi
      fi
      echo ""

      echo "## Relevant Modules"
      if [[ -f "$DESIGN_DIR/MODULES.md" ]]; then
        if [[ -n "$OWNERSHIP" ]]; then
          IFS=',' read -ra GLOBS <<< "$OWNERSHIP"
          for glob in "${GLOBS[@]}"; do
            PREFIX="${glob%%\**}"
            PREFIX=$(echo "$PREFIX" | tr -d ' ' | sed 's|/$||')
            grep -A 15 -i "$PREFIX" "$DESIGN_DIR/MODULES.md" 2>/dev/null || true
          done | sort -u
        else
          cat "$DESIGN_DIR/MODULES.md"
        fi
      fi
      echo ""

      echo "## Relevant Sequences"
      if [[ -f "$DESIGN_DIR/SEQUENCES.md" ]]; then
        cat "$DESIGN_DIR/SEQUENCES.md"
      fi
      echo ""

      # Shared decisions
      echo "## Decisions Log"
      if [[ -f "$MILESTONE_DIR/DECISIONS.md" ]]; then
        cat "$MILESTONE_DIR/DECISIONS.md"
      else
        echo "(none yet)"
      fi
      ;;

    tester)
      # Tester gets acceptance criteria + edge cases only
      echo "## Acceptance Criteria"
      if [[ -f "$FEATURE_DIR/REQUIREMENTS.md" ]]; then
        extract_sections "$FEATURE_DIR/REQUIREMENTS.md" "acceptance\|criteria\|edge.case\|verification"
        # Also get REQ lines
        grep 'REQ-[0-9]' "$FEATURE_DIR/REQUIREMENTS.md" 2>/dev/null || true
      fi
      echo ""

      echo "## Contracts"
      if [[ -f "$DESIGN_DIR/CONTRACTS.md" ]]; then
        cat "$DESIGN_DIR/CONTRACTS.md"
      fi
      echo ""

      echo "## Implemented Files"
      # List source files in project (exclude plans, node_modules, etc.)
      PROJECT_ROOT="$(cd "$FEATURE_DIR/../.." 2>/dev/null && pwd || echo "$FEATURE_DIR")"
      find "$PROJECT_ROOT/src" "$PROJECT_ROOT/app" "$PROJECT_ROOT/lib" -type f 2>/dev/null | head -50 || echo "(no src/ app/ lib/ found)"
      ;;

    tech-lead)
      # Tech-lead gets design docs + all dev output
      echo "## Design"
      if [[ -f "$MILESTONE_DIR/DESIGN.md" ]]; then
        cat "$MILESTONE_DIR/DESIGN.md"
      fi
      echo ""

      echo "## Contracts"
      if [[ -f "$DESIGN_DIR/CONTRACTS.md" ]]; then
        cat "$DESIGN_DIR/CONTRACTS.md"
      fi
      echo ""

      echo "## Modules"
      if [[ -f "$DESIGN_DIR/MODULES.md" ]]; then
        cat "$DESIGN_DIR/MODULES.md"
      fi
      ;;

    pm)
      # PM gets high-level artifacts
      echo "## Requirements Summary"
      if [[ -f "$FEATURE_DIR/REQUIREMENTS.md" ]]; then
        head -50 "$FEATURE_DIR/REQUIREMENTS.md"
      fi
      echo ""

      echo "## ROADMAP"
      if [[ -f "$MILESTONE_DIR/ROADMAP.md" ]]; then
        cat "$MILESTONE_DIR/ROADMAP.md"
      fi
      echo ""

      # Include review/gaps/test results if they exist
      for artifact in REVIEW.md GAPS.md; do
        if [[ -f "$MILESTONE_DIR/$artifact" ]]; then
          echo "## $artifact"
          cat "$MILESTONE_DIR/$artifact"
          echo ""
        fi
      done
      ;;

    domain-engineer)
      # Domain-engineer gets full project context (no scoping needed)
      for doc in "$FEATURE_DIR/REQUIREMENTS.md" "$FEATURE_DIR/CONTEXT.md" "$MILESTONE_DIR/DESIGN.md" "$MILESTONE_DIR/ROADMAP.md"; do
        if [[ -f "$doc" ]]; then
          echo "## $(basename "$doc")"
          cat "$doc"
          echo ""
        fi
      done
      ;;

    critic-*)
      # Critics get design docs + requirements + context
      for doc in "$FEATURE_DIR/REQUIREMENTS.md" "$FEATURE_DIR/CONTEXT.md" "$MILESTONE_DIR/ROADMAP.md"; do
        if [[ -f "$doc" ]]; then
          echo "## $(basename "$doc")"
          cat "$doc"
          echo ""
        fi
      done
      for doc in OVERVIEW.md MODULES.md SEQUENCES.md CONTRACTS.md; do
        if [[ -f "$DESIGN_DIR/$doc" ]]; then
          echo "## design/$doc"
          cat "$DESIGN_DIR/$doc"
          echo ""
        fi
      done
      ;;

    *)
      echo "Unknown role: $ROLE" >&2
      exit 1
      ;;
  esac

  # GOTCHAs (filtered) — append for all roles
  echo ""
  echo "## Past Lessons (GOTCHAs)"
  for gotcha_file in "$FEATURE_DIR/../GOTCHAS.md" "$FEATURE_DIR/GOTCHAS.md"; do
    if [[ -f "$gotcha_file" ]]; then
      # Extract entries — take last 5
      grep -A 4 '^### G-' "$gotcha_file" 2>/dev/null | tail -25 || true
    fi
  done
  echo "(end of gotchas)"

} > "$OUTPUT"

if [[ "$OUTPUT" != "/dev/stdout" ]]; then
  echo "Context written to: $OUTPUT ($(wc -l < "$OUTPUT" | tr -d ' ') lines)" >&2
fi
