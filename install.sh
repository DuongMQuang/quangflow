#!/usr/bin/env bash
# QuangFlow installer
# Installs commands and agent instructions globally (~/.claude/) or per-project (.claude/).
#
# Usage:
#   bash install.sh                    # interactive — asks where to install
#   bash install.sh --global           # install to ~/.claude/
#   bash install.sh --project [path]   # install to <path>/.claude/ (default: CWD)
#   bash install.sh /path/to/project   # legacy — same as --project /path/to/project

set -euo pipefail

# --- Configuration ---
QUANGFLOW_VERSION="1.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_MODE=""   # "global" or "project"
TARGET_DIR=""
UPDATE_ONLY=false

# --- Colors ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

info()  { echo -e "${BLUE}[info]${NC}  $1"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $1"; }
err()   { echo -e "${RED}[error]${NC} $1"; }

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --global|-g)
      INSTALL_MODE="global"
      shift
      ;;
    --project|-p)
      INSTALL_MODE="project"
      if [[ $# -gt 1 && ! "$2" =~ ^- ]]; then
        TARGET_DIR="$2"
        shift
      fi
      shift
      ;;
    --update|-u)
      INSTALL_MODE="${INSTALL_MODE:-project}"
      UPDATE_ONLY=true
      shift
      ;;
    --help|-h)
      echo "Usage: bash install.sh [OPTIONS] [path]"
      echo ""
      echo "Options:"
      echo "  --global, -g         Install to ~/.claude/ (available in all projects)"
      echo "  --project, -p [path] Install to <path>/.claude/ (default: current directory)"
      echo "  --update, -u         Update commands+agents only (skip CLAUDE.md)"
      echo "  --help, -h           Show this help"
      echo ""
      echo "Without options: interactive mode (asks where to install)"
      exit 0
      ;;
    *)
      # Legacy: treat bare path as --project <path>
      if [[ -d "$1" ]]; then
        INSTALL_MODE="project"
        TARGET_DIR="$1"
      else
        err "Unknown option or directory: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

# --- Pre-flight: check source files ---
if [ ! -d "$SCRIPT_DIR/commands" ] || [ ! -d "$SCRIPT_DIR/agents" ]; then
  err "Source files not found. Run this script from the quangflow directory."
  exit 1
fi

# --- Banner ---
echo ""
echo -e "${BOLD}========================================"
echo "  QuangFlow Installer v${QUANGFLOW_VERSION}"
echo -e "========================================${NC}"
echo ""

# --- Interactive mode selection ---
if [[ -z "$INSTALL_MODE" ]]; then
  echo "Where do you want to install QuangFlow?"
  echo ""
  echo -e "  ${BOLD}1)${NC} Global  (~/.claude/)  — available in ALL projects"
  echo -e "  ${BOLD}2)${NC} Project (./.claude/)  — available in this project only"
  echo ""
  read -rp "Choose [1/2]: " choice
  case "$choice" in
    1) INSTALL_MODE="global" ;;
    2) INSTALL_MODE="project" ;;
    *)
      err "Invalid choice. Run again and pick 1 or 2."
      exit 1
      ;;
  esac
  echo ""

  # If project mode, ask for path
  if [[ "$INSTALL_MODE" == "project" && -z "$TARGET_DIR" ]]; then
    read -rp "Project path (press Enter for current directory): " input_path
    TARGET_DIR="${input_path:-.}"
  fi
fi

# --- Resolve paths ---
if [[ "$INSTALL_MODE" == "global" ]]; then
  CLAUDE_DIR="$HOME/.claude"
  COMMANDS_DIR="$CLAUDE_DIR/commands"
  AGENTS_DIR="$CLAUDE_DIR/agents"
  # Global install: CLAUDE.md goes to ~/.claude/CLAUDE.md
  CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
  # No plans dir for global — each project has its own
  PLANS_DIR=""
  info "Install mode: ${BOLD}global${NC} (~/.claude/)"
else
  TARGET_DIR="${TARGET_DIR:-.}"
  TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
    err "Target directory '$TARGET_DIR' does not exist."
    exit 1
  }
  CLAUDE_DIR="$TARGET_DIR/.claude"
  COMMANDS_DIR="$CLAUDE_DIR/commands"
  AGENTS_DIR="$CLAUDE_DIR/agents"
  CLAUDE_MD="$TARGET_DIR/CLAUDE.md"
  PLANS_DIR="$TARGET_DIR/plans"
  info "Install mode: ${BOLD}project${NC} ($TARGET_DIR)"
fi
echo ""

# --- Auto-detect update if version file exists ---
if $UPDATE_ONLY && [[ -f "$CLAUDE_DIR/.quangflow-version" ]]; then
  OLD_VER=$(cat "$CLAUDE_DIR/.quangflow-version")
  info "Updating QuangFlow: $OLD_VER → $QUANGFLOW_VERSION"
fi

# --- Detect existing installation ---
EXISTING_COMMANDS=0
EXISTING_AGENTS=0

if [ -d "$COMMANDS_DIR" ]; then
  for d in "$SCRIPT_DIR/commands/"*/; do
    dname="$(basename "$d")"
    [[ -d "$COMMANDS_DIR/$dname" ]] && EXISTING_COMMANDS=$((EXISTING_COMMANDS + 1))
  done
fi

if [ -d "$AGENTS_DIR" ]; then
  for f in "$SCRIPT_DIR/agents/"*.md; do
    fname="$(basename "$f")"
    [[ -f "$AGENTS_DIR/$fname" ]] && EXISTING_AGENTS=$((EXISTING_AGENTS + 1))
  done
fi

if [ $EXISTING_COMMANDS -gt 0 ] || [ $EXISTING_AGENTS -gt 0 ]; then
  warn "Found existing: $EXISTING_COMMANDS command(s), $EXISTING_AGENTS agent(s)"
  echo ""
  read -rp "Overwrite existing QuangFlow files? [y/N] " answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    info "Aborted. No files changed."
    exit 0
  fi
  echo ""
fi

# --- Create directories ---
mkdir -p "$COMMANDS_DIR"
mkdir -p "$AGENTS_DIR"
[[ -n "$PLANS_DIR" ]] && mkdir -p "$PLANS_DIR"

# --- Copy shared protocol files ---
info "Installing shared protocols..."
SHARED_COUNT=0
for f in "$SCRIPT_DIR/commands/"_*.md; do
  [[ -f "$f" ]] || continue
  fname="$(basename "$f")"
  cp "$f" "$COMMANDS_DIR/$fname"
  ok "  $fname"
  SHARED_COUNT=$((SHARED_COUNT + 1))
done

# --- Copy commands ---
info "Installing commands..."
CMD_COUNT=0
for d in "$SCRIPT_DIR/commands/"*/; do
  dname="$(basename "$d")"
  mkdir -p "$COMMANDS_DIR/$dname"
  for f in "$d"*.md; do
    [[ -f "$f" ]] || continue
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
  [[ -f "$f" ]] || continue
  fname="$(basename "$f")"
  cp "$f" "$AGENTS_DIR/$fname"
  ok "  $fname"
  AGENT_COUNT=$((AGENT_COUNT + 1))
done

# --- Handle CLAUDE.md (skip in update mode) ---
echo ""
if $UPDATE_ONLY; then
  info "Update mode — skipping CLAUDE.md"
elif [ -f "$CLAUDE_MD" ]; then
  if grep -q "## Phase Workflow" "$CLAUDE_MD" 2>/dev/null; then
    warn "CLAUDE.md already contains QuangFlow section — skipping"
    warn "To update: see CLAUDE.md.template in the quangflow package"
  else
    info "Appending QuangFlow config to existing CLAUDE.md..."
    {
      echo ""
      echo "<!-- QuangFlow Configuration (auto-appended by installer) -->"
      echo ""
      cat "$SCRIPT_DIR/CLAUDE.md.template"
    } >> "$CLAUDE_MD"
    ok "QuangFlow config appended to CLAUDE.md"
  fi
else
  info "Creating CLAUDE.md from template..."
  cp "$SCRIPT_DIR/CLAUDE.md.template" "$CLAUDE_MD"
  if [[ "$INSTALL_MODE" == "project" ]]; then
    PROJECT_NAME="$(basename "$TARGET_DIR")"
  else
    PROJECT_NAME="Global QuangFlow"
  fi
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$CLAUDE_MD"
  else
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$CLAUDE_MD"
  fi
  ok "CLAUDE.md created"
fi

# --- Write version file ---
echo "$QUANGFLOW_VERSION" > "$CLAUDE_DIR/.quangflow-version"

# --- Summary ---
echo ""
echo -e "${BOLD}========================================"
echo -e "  ${GREEN}Installation complete!${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""
echo "  Mode:     $INSTALL_MODE"
echo "  Path:     $CLAUDE_DIR/"
echo "  Version:  $QUANGFLOW_VERSION"
echo ""
echo "  Installed:"
echo "    $SHARED_COUNT shared protocol(s)"
echo "    $CMD_COUNT command(s)  -> $COMMANDS_DIR/"
echo "    $AGENT_COUNT agent(s)   -> $AGENTS_DIR/"
[[ -n "$PLANS_DIR" ]] && echo "    plans dir    -> $PLANS_DIR/"
echo ""
echo "  Commands:"
echo "    /qf:1-brainstorm <idea>  — Requirements discovery"
echo "    /qf:2-design             — Architecture design"
echo "    /qf:3-handoff            — Execution handoff"
echo "    /qf:4-verify             — QA & verification"
echo "    /qf:5-maintain           — Post-ship bug fix & triage"
echo "    /qf:quick <task>       — Quick mode (single-pass)"
echo "    /qf:cook               — Team pipeline orchestrator"
echo "    /qf:status             — Status & session resume"
echo "    /qf:test               — Smoke test"
echo ""
if [[ "$INSTALL_MODE" == "global" ]]; then
  echo "  Global install — commands available in every project."
  echo "  Per-project CLAUDE.md still recommended for project-specific config."
else
  echo "  Get started:"
  echo "    cd $(printf '%q' "$TARGET_DIR")"
  echo "    claude"
  echo "    /qf:1-brainstorm my feature idea"
fi
echo ""
