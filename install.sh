#!/usr/bin/env bash
# quangflow installer
# Copies QuangFlow commands and agent instructions into your project's .claude/ directory.
#
# Usage:
#   curl -fsSL <url>/install.sh | bash
#   OR
#   git clone <repo> && cd quangflow && bash install.sh
#   OR
#   bash install.sh /path/to/your/project

set -euo pipefail

# --- Configuration ---
QUANGFLOW_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"  # Default: current directory

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
  echo "Error: Target directory '$1' does not exist."
  exit 1
}

CLAUDE_DIR="$TARGET_DIR/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
AGENTS_DIR="$CLAUDE_DIR/agents"
PLANS_DIR="$TARGET_DIR/plans"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[info]${NC}  $1"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $1"; }
err()   { echo -e "${RED}[error]${NC} $1"; }

# --- Pre-flight checks ---
echo ""
echo "========================================"
echo "  QuangFlow Installer"
echo "========================================"
echo ""
info "Target project: $TARGET_DIR"
echo ""

# Check source files exist
if [ ! -d "$SCRIPT_DIR/commands" ] || [ ! -d "$SCRIPT_DIR/agents" ]; then
  err "Source files not found. Run this script from the quangflow directory."
  exit 1
fi

# --- Detect existing installations ---
EXISTING_COMMANDS=0
EXISTING_AGENTS=0

if [ -d "$COMMANDS_DIR" ]; then
  for d in "$SCRIPT_DIR/commands/"*/; do
    dname="$(basename "$d")"
    if [ -d "$COMMANDS_DIR/$dname" ]; then
      EXISTING_COMMANDS=$((EXISTING_COMMANDS + 1))
    fi
  done
fi

if [ -d "$AGENTS_DIR" ]; then
  for f in "$SCRIPT_DIR/agents/"*.md; do
    fname="$(basename "$f")"
    if [ -f "$AGENTS_DIR/$fname" ]; then
      EXISTING_AGENTS=$((EXISTING_AGENTS + 1))
    fi
  done
fi

if [ $EXISTING_COMMANDS -gt 0 ] || [ $EXISTING_AGENTS -gt 0 ]; then
  warn "Found existing files: $EXISTING_COMMANDS command(s), $EXISTING_AGENTS agent(s)"
  echo ""
  read -rp "Overwrite existing files? [y/N] " answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    info "Aborted. No files changed."
    exit 0
  fi
  echo ""
fi

# --- Create directories ---
mkdir -p "$COMMANDS_DIR"
mkdir -p "$AGENTS_DIR"
mkdir -p "$PLANS_DIR"

# --- Copy commands (subdirectory structure for cross-platform compatibility) ---
info "Installing commands..."
CMD_COUNT=0
for d in "$SCRIPT_DIR/commands/"*/; do
  dname="$(basename "$d")"
  mkdir -p "$COMMANDS_DIR/$dname"
  for f in "$d"*.md; do
    fname="$(basename "$f")"
    cp "$f" "$COMMANDS_DIR/$dname/$fname"
    ok "  $dname/$fname"
    CMD_COUNT=$((CMD_COUNT + 1))
  done
done

# --- Copy agent instructions ---
echo ""
info "Installing agent instructions..."
AGENT_COUNT=0
for f in "$SCRIPT_DIR/agents/"*.md; do
  fname="$(basename "$f")"
  cp "$f" "$AGENTS_DIR/$fname"
  ok "  $fname"
  AGENT_COUNT=$((AGENT_COUNT + 1))
done

# --- Handle CLAUDE.md ---
echo ""
CLAUDE_MD="$TARGET_DIR/CLAUDE.md"
if [ -f "$CLAUDE_MD" ]; then
  # Check if QuangFlow section already exists
  if grep -q "## Phase Workflow" "$CLAUDE_MD" 2>/dev/null; then
    warn "CLAUDE.md already contains QuangFlow section — skipping"
    warn "To update manually, see CLAUDE.md.template in the package"
  else
    info "Appending QuangFlow config to existing CLAUDE.md..."
    echo "" >> "$CLAUDE_MD"
    echo "<!-- QuangFlow Configuration (auto-appended by quangflow installer) -->" >> "$CLAUDE_MD"
    echo "" >> "$CLAUDE_MD"
    cat "$SCRIPT_DIR/CLAUDE.md.template" >> "$CLAUDE_MD"
    ok "  QuangFlow config appended to CLAUDE.md"
  fi
else
  info "Creating CLAUDE.md from template..."
  cp "$SCRIPT_DIR/CLAUDE.md.template" "$CLAUDE_MD"
  # Replace placeholder with directory name
  PROJECT_NAME="$(basename "$TARGET_DIR")"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$CLAUDE_MD"
  else
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$CLAUDE_MD"
  fi
  ok "  CLAUDE.md created (edit Tech Stack and project-specific sections)"
fi

# --- Write version file ---
echo "$QUANGFLOW_VERSION" > "$CLAUDE_DIR/.quangflow-version"
ok "  Version $QUANGFLOW_VERSION written to .claude/.quangflow-version"

# --- Summary ---
echo ""
echo "========================================"
echo -e "  ${GREEN}Installation complete!${NC}"
echo "========================================"
echo ""
echo "  Installed:"
echo "    - $CMD_COUNT commands  -> $COMMANDS_DIR/"
echo "    - $AGENT_COUNT agents   -> $AGENTS_DIR/"
echo "    - plans dir    -> $PLANS_DIR/"
echo ""
echo "  Available commands:"
echo "    /qf-1::brainstorm <idea>  — Phase 1: Requirements discovery"
echo "    /qf-2::design             — Phase 2: Architecture design"
echo "    /qf-3::handoff            — Phase 3: Execution handoff"
echo "    /qf-4::verify             — Phase 4: QA & verification"
echo "    /qf-q::quick               — Quick mode for small tasks (single-pass)"
echo "    /qf-5::maintain            — Phase 5: Post-ship bug fix & triage"
echo "    /qf-c::cook               — Team pipeline orchestrator"
echo "    /qf-s::status             — Project status & session resume"
echo "    /qf-t::test               — Smoke test: real integration tests"
echo ""
echo "  Get started:"
echo "    cd $TARGET_DIR"
echo "    claude"
echo "    /qf-1::brainstorm my feature idea"
echo ""
