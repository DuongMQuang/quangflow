#!/usr/bin/env bash
# QuangFlow remote installer
# Usage: curl -fsSL https://raw.githubusercontent.com/DuongMQuang/quangflow/main/remote-install.sh | bash

set -euo pipefail

REPO="https://github.com/DuongMQuang/quangflow.git"
TMPDIR="$(mktemp -d)"
TARGET_DIR="${1:-.}"

cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo "Downloading QuangFlow..."
git clone --depth 1 --quiet "$REPO" "$TMPDIR/quangflow"

bash "$TMPDIR/quangflow/install.sh" "$TARGET_DIR"
