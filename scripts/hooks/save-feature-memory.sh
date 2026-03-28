#!/usr/bin/env bash
# Saves phase artifacts into a Feature Memory Unit (FMU) in .memory/.
# Called after stage validation passes to persist learnings across sessions.
#
# Usage:
#   bash scripts/hooks/save-feature-memory.sh <feature-slug> <phase> <milestone-dir>
#
# Phases: init, brainstorm, design, verify, maintain
# Creates .memory/<feature-slug>/ with phase-appropriate artifacts.

set -euo pipefail

FEATURE_SLUG="${1:-}"
PHASE="${2:-}"
MILESTONE_DIR="${3:-}"

if [[ -z "$FEATURE_SLUG" || -z "$PHASE" || -z "$MILESTONE_DIR" ]]; then
  echo "Usage: save-feature-memory.sh <feature-slug> <phase> <milestone-dir>"
  exit 1
fi

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BOLD='\033[1m'; NC='\033[0m'

MEMORY_DIR=".memory"
FMU_DIR="$MEMORY_DIR/$FEATURE_SLUG"
INDEX_FILE="$MEMORY_DIR/_index.md"

echo -e "${BOLD}Saving Feature Memory: $FEATURE_SLUG (phase: $PHASE)${NC}"

# --- Ensure .memory/ and FMU directory exist ---
mkdir -p "$FMU_DIR"

# --- Create _index.md if it doesn't exist ---
if [[ ! -f "$INDEX_FILE" ]]; then
  cat > "$INDEX_FILE" <<EOF
# Feature Memory Index

| Feature | Created | Last Updated | Phases |
|---------|---------|--------------|--------|
EOF
fi

# --- Determine feature dir (parent of milestone dir) ---
FEATURE_DIR="$(dirname "$MILESTONE_DIR")"

# --- Copy phase artifacts ---
TIMESTAMP=$(date '+%Y-%m-%d')

case "$PHASE" in
  init)
    # Copy CONTEXT.md from the feature/milestone area
    for candidate in "$FEATURE_DIR/CONTEXT.md" "$MILESTONE_DIR/CONTEXT.md"; do
      if [[ -f "$candidate" ]]; then
        cp "$candidate" "$FMU_DIR/CONTEXT.md"
        echo -e "${GREEN}  Copied CONTEXT.md${NC}"
        break
      fi
    done
    # Create CONTEXT.md stub if none found
    if [[ ! -f "$FMU_DIR/CONTEXT.md" ]]; then
      cat > "$FMU_DIR/CONTEXT.md" <<EOF
# $FEATURE_SLUG

Created: $TIMESTAMP
Phase: init

## Summary

Feature memory unit initialized.
EOF
      echo -e "${YELLOW}  Created CONTEXT.md stub (no source found)${NC}"
    fi
    ;;

  brainstorm)
    for candidate in "$FEATURE_DIR/REQUIREMENTS.md" "$MILESTONE_DIR/REQUIREMENTS.md"; do
      if [[ -f "$candidate" ]]; then
        cp "$candidate" "$FMU_DIR/REQUIREMENTS.md"
        echo -e "${GREEN}  Copied REQUIREMENTS.md${NC}"
        break
      fi
    done
    ;;

  design)
    for candidate in "$FEATURE_DIR/DESIGN.md" "$MILESTONE_DIR/DESIGN.md"; do
      if [[ -f "$candidate" ]]; then
        cp "$candidate" "$FMU_DIR/DESIGN.md"
        echo -e "${GREEN}  Copied DESIGN.md${NC}"
        break
      fi
    done
    ;;

  verify|maintain)
    # Append to HISTORY.md
    HISTORY_FILE="$FMU_DIR/HISTORY.md"
    if [[ ! -f "$HISTORY_FILE" ]]; then
      cat > "$HISTORY_FILE" <<EOF
# History — $FEATURE_SLUG

## Entries

EOF
    fi

    # Gather relevant info
    ENTRY="### $PHASE — $TIMESTAMP\n"

    # Include QA/certification summary if available
    for report in "$MILESTONE_DIR/CERTIFICATION.md" "$MILESTONE_DIR/QA-REPORT.md"; do
      if [[ -f "$report" ]]; then
        ENTRY="$ENTRY\nSource: $(basename "$report")\n"
        # Include first 20 lines as summary
        SUMMARY=$(head -20 "$report" 2>/dev/null || true)
        ENTRY="$ENTRY\n\`\`\`\n$SUMMARY\n\`\`\`\n"
        break
      fi
    done

    # Include GOTCHAS if available
    for gotchas in "$FEATURE_DIR/GOTCHAS.md" "$MILESTONE_DIR/GOTCHAS.md"; do
      if [[ -f "$gotchas" ]]; then
        ENTRY="$ENTRY\nGotchas captured: $(grep -c '### G-[0-9]' "$gotchas" 2>/dev/null || echo 0) entries\n"
        break
      fi
    done

    echo -e "$ENTRY" >> "$HISTORY_FILE"
    echo -e "${GREEN}  Appended $PHASE entry to HISTORY.md${NC}"
    ;;

  *)
    echo "Warning: unknown phase '$PHASE' — no artifacts copied"
    ;;
esac

# --- Create LINKS.md if it doesn't exist ---
if [[ ! -f "$FMU_DIR/LINKS.md" ]]; then
  cat > "$FMU_DIR/LINKS.md" <<EOF
# Links — $FEATURE_SLUG

## Related Features

_No links yet. Add cross-references as features connect._
EOF
  echo -e "${GREEN}  Created LINKS.md${NC}"
fi

# --- Update _index.md ---
if grep -qF "$FEATURE_SLUG" "$INDEX_FILE" 2>/dev/null; then
  # Update existing entry — replace the line
  # Use sed to update the last-updated date and phase
  sed -i "s|$FEATURE_SLUG.*|$FEATURE_SLUG | ... | $TIMESTAMP | $PHASE |" "$INDEX_FILE" 2>/dev/null || true
  echo -e "${GREEN}  Updated _index.md entry${NC}"
else
  # Add new entry
  echo "| $FEATURE_SLUG | $TIMESTAMP | $TIMESTAMP | $PHASE |" >> "$INDEX_FILE"
  echo -e "${GREEN}  Added to _index.md${NC}"
fi

echo -e "${GREEN}Feature memory saved successfully.${NC}"
exit 0
