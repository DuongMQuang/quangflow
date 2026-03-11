#!/usr/bin/env bash
# QuangFlow uninstaller
# Removes commands and agent instructions from global or project install.
#
# Usage:
#   bash uninstall.sh                    # interactive — asks which install to remove
#   bash uninstall.sh --global           # remove from ~/.claude/
#   bash uninstall.sh --project [path]   # remove from <path>/.claude/
#   bash uninstall.sh /path/to/project   # legacy — same as --project

set -euo pipefail

INSTALL_MODE=""
TARGET_DIR=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

info()  { echo -e "${BLUE}[info]${NC}  $1"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $1"; }

# QuangFlow-owned files (only these get removed)
COMMAND_DIRS=("qf-0" "qf-1" "qf-2" "qf-3" "qf-4" "qf-5" "qf-c" "qf-s" "qf-t" "qf-q" "qf-u")
SHARED_FILES=("_shared.md" "_autopilot.md")
AGENTS=("domain-engineer.md" "dev-teammate.md" "tech-lead.md" "tester.md" "pm.md" "_shared.md")

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --global|-g) INSTALL_MODE="global"; shift ;;
    --project|-p)
      INSTALL_MODE="project"
      if [[ $# -gt 1 && ! "$2" =~ ^- ]]; then TARGET_DIR="$2"; shift; fi
      shift ;;
    --help|-h)
      echo "Usage: bash uninstall.sh [--global | --project [path] | path]"
      exit 0 ;;
    *)
      if [[ -d "$1" ]]; then INSTALL_MODE="project"; TARGET_DIR="$1"
      else echo "Error: Unknown option or directory: $1"; exit 1; fi
      shift ;;
  esac
done

echo ""
echo -e "${BOLD}QuangFlow — Uninstaller${NC}"
echo "================================"
echo ""

# --- Interactive mode selection ---
if [[ -z "$INSTALL_MODE" ]]; then
  # Auto-detect: check both locations
  HAS_GLOBAL=false
  HAS_PROJECT=false
  [[ -f "$HOME/.claude/.quangflow-version" ]] && HAS_GLOBAL=true
  [[ -f ".claude/.quangflow-version" ]] && HAS_PROJECT=true

  if $HAS_GLOBAL && $HAS_PROJECT; then
    echo "QuangFlow detected in both locations:"
    echo -e "  ${BOLD}1)${NC} Global  (~/.claude/)"
    echo -e "  ${BOLD}2)${NC} Project ($(pwd)/.claude/)"
    echo -e "  ${BOLD}3)${NC} Both"
    echo ""
    read -rp "Remove from [1/2/3]: " choice
    case "$choice" in
      1) INSTALL_MODE="global" ;;
      2) INSTALL_MODE="project" ;;
      3) INSTALL_MODE="both" ;;
      *) echo "Aborted."; exit 1 ;;
    esac
  elif $HAS_GLOBAL; then
    INSTALL_MODE="global"
    info "Found global install"
  elif $HAS_PROJECT; then
    INSTALL_MODE="project"
    info "Found project install"
  else
    warn "No QuangFlow installation detected."
    echo "Specify location: bash uninstall.sh --global  OR  bash uninstall.sh --project [path]"
    exit 0
  fi
  echo ""
fi

# --- Remove function ---
remove_from() {
  local claude_dir="$1"
  local label="$2"
  local removed=0

  if [[ ! -d "$claude_dir" ]]; then
    warn "Directory $claude_dir does not exist — skipping"
    return
  fi

  info "Removing QuangFlow from $label ($claude_dir)..."

  # Remove command directories
  for d in "${COMMAND_DIRS[@]}"; do
    if [[ -d "$claude_dir/commands/$d" ]]; then
      rm -rf "$claude_dir/commands/$d"
      echo -e "  ${RED}removed${NC} commands/$d/"
      removed=$((removed + 1))
    fi
  done

  # Remove shared command files
  for f in "${SHARED_FILES[@]}"; do
    if [[ -f "$claude_dir/commands/$f" ]]; then
      rm "$claude_dir/commands/$f"
      echo -e "  ${RED}removed${NC} commands/$f"
      removed=$((removed + 1))
    fi
  done

  # Remove agent files
  for f in "${AGENTS[@]}"; do
    if [[ -f "$claude_dir/agents/$f" ]]; then
      rm "$claude_dir/agents/$f"
      echo -e "  ${RED}removed${NC} agents/$f"
      removed=$((removed + 1))
    fi
  done

  # Remove version file
  if [[ -f "$claude_dir/.quangflow-version" ]]; then
    rm "$claude_dir/.quangflow-version"
    echo -e "  ${RED}removed${NC} .quangflow-version"
    removed=$((removed + 1))
  fi

  # Clean up empty directories (don't remove if other files exist)
  rmdir "$claude_dir/commands" 2>/dev/null && echo -e "  ${RED}removed${NC} commands/ (empty)" || true
  rmdir "$claude_dir/agents" 2>/dev/null && echo -e "  ${RED}removed${NC} agents/ (empty)" || true

  echo ""
  echo -e "${GREEN}Removed $removed file(s) from $label.${NC}"
}

# --- Confirm ---
read -rp "Remove QuangFlow files? [y/N] " answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi
echo ""

# --- Execute removal ---
case "$INSTALL_MODE" in
  global)
    remove_from "$HOME/.claude" "global"
    ;;
  project)
    TARGET_DIR="${TARGET_DIR:-.}"
    TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)"
    remove_from "$TARGET_DIR/.claude" "project ($TARGET_DIR)"
    ;;
  both)
    TARGET_DIR="$(pwd)"
    remove_from "$HOME/.claude" "global"
    echo ""
    remove_from "$TARGET_DIR/.claude" "project ($TARGET_DIR)"
    ;;
esac

echo ""
echo -e "${YELLOW}Note:${NC} CLAUDE.md and plans/ were NOT removed. Clean up manually if needed."
echo ""
