#!/usr/bin/env bash
# SessionStart hook: checks if a newer QuangFlow version is available.
#
# Hook config (add to .claude/settings.json):
#   "hooks": {
#     "SessionStart": [{
#       "matcher": "",
#       "hooks": [{
#         "type": "command",
#         "command": "bash .claude/scripts/hooks/check-update.sh",
#         "async": true
#       }]
#     }]
#   }
#
# Checks GitHub for latest version, compares with local .quangflow-version.
# Prints a one-liner if update is available. Silent if up-to-date or offline.
# Rate-limited: checks at most once per 24 hours (cache file).

set -euo pipefail

# --- Find local version ---
LOCAL_VERSION=""
VERSION_FILE=""

# Check project-level first, then global
if [[ -f ".claude/.quangflow-version" ]]; then
  VERSION_FILE=".claude/.quangflow-version"
elif [[ -f "$HOME/.claude/.quangflow-version" ]]; then
  VERSION_FILE="$HOME/.claude/.quangflow-version"
fi

if [[ -z "$VERSION_FILE" ]]; then
  exit 0  # Not installed via script, skip (plugin users get auto-updates)
fi

LOCAL_VERSION=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]')
if [[ -z "$LOCAL_VERSION" ]]; then
  exit 0
fi

# --- Rate limiting: check at most once per 24 hours ---
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quangflow"
CACHE_FILE="$CACHE_DIR/last-update-check"
mkdir -p "$CACHE_DIR" 2>/dev/null || true

if [[ -f "$CACHE_FILE" ]]; then
  LAST_CHECK=$(cat "$CACHE_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  ELAPSED=$((NOW - LAST_CHECK))
  # 86400 seconds = 24 hours
  if [[ $ELAPSED -lt 86400 ]]; then
    exit 0  # Checked recently, skip
  fi
fi

# --- Fetch latest version from GitHub ---
REMOTE_VERSION=""

# Try GitHub API first (fast, no clone needed)
if command -v curl &>/dev/null; then
  REMOTE_VERSION=$(curl -fsSL --connect-timeout 3 --max-time 5 \
    "https://raw.githubusercontent.com/DuongMQuang/quangflow/main/install.sh" 2>/dev/null \
    | grep -oP 'QUANGFLOW_VERSION="\K[^"]+' || true)
fi

# Update cache timestamp regardless of result (prevents hammering on failure)
date +%s > "$CACHE_FILE" 2>/dev/null || true

if [[ -z "$REMOTE_VERSION" ]]; then
  exit 0  # Offline or fetch failed, skip silently
fi

# --- Compare versions ---
if [[ "$LOCAL_VERSION" == "$REMOTE_VERSION" ]]; then
  exit 0  # Up to date
fi

# --- Notify user ---
echo ""
echo "  QuangFlow update available: v${LOCAL_VERSION} → v${REMOTE_VERSION}"
echo "  Run /quangflow:update to upgrade, or see CHANGELOG.md for what's new."
echo ""
