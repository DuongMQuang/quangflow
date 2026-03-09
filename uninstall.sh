#!/usr/bin/env bash
# quangflow uninstaller
# Removes QuangFlow commands and agent instructions from your project.
#
# Usage: bash uninstall.sh [/path/to/project]

set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
  echo "Error: Target directory '$1' does not exist."
  exit 1
}

CLAUDE_DIR="$TARGET_DIR/.claude"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "QuangFlow — Uninstaller"
echo "================================"
echo ""
echo -e "${YELLOW}Target:${NC} $TARGET_DIR"
echo ""

# QuangFlow files to remove
COMMANDS=(
  "qf-1::brainstorm.md"
  "qf-2::design.md"
  "qf-3::handoff.md"
  "qf-4::verify.md"
  "qf-c::cook.md"
  "qf-s::status.md"
)

AGENTS=(
  "domain-engineer.md"
  "dev-teammate.md"
  "tech-lead.md"
  "tester.md"
  "pm.md"
)

read -rp "Remove QuangFlow files from this project? [y/N] " answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo ""
REMOVED=0

for f in "${COMMANDS[@]}"; do
  if [ -f "$CLAUDE_DIR/commands/$f" ]; then
    rm "$CLAUDE_DIR/commands/$f"
    echo -e "  ${RED}removed${NC} commands/$f"
    REMOVED=$((REMOVED + 1))
  fi
done

for f in "${AGENTS[@]}"; do
  if [ -f "$CLAUDE_DIR/agents/$f" ]; then
    rm "$CLAUDE_DIR/agents/$f"
    echo -e "  ${RED}removed${NC} agents/$f"
    REMOVED=$((REMOVED + 1))
  fi
done

# Clean up empty directories
rmdir "$CLAUDE_DIR/commands" 2>/dev/null && echo -e "  ${RED}removed${NC} commands/ (empty)" || true
rmdir "$CLAUDE_DIR/agents" 2>/dev/null && echo -e "  ${RED}removed${NC} agents/ (empty)" || true
rmdir "$CLAUDE_DIR" 2>/dev/null && echo -e "  ${RED}removed${NC} .claude/ (empty)" || true

echo ""
echo -e "${GREEN}Removed $REMOVED file(s).${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} CLAUDE.md and plans/ were NOT removed. Clean up manually if needed."
echo ""
