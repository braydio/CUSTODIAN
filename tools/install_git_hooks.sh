#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

HOOKS=(
    pre-commit
    post-commit
    post-checkout
    post-merge
    pre-push
)

for hook in "${HOOKS[@]}"; do
    if [ -f ".githooks/$hook" ]; then
        chmod +x ".githooks/$hook"
    fi
done

[ -f tools/crg-refresh.sh ] && chmod +x tools/crg-refresh.sh
[ -f rclone-git-sync.sh ] && chmod +x rclone-git-sync.sh

git config --local core.hooksPath .githooks

echo
echo "Installed CUSTODIAN Git hooks."
echo "core.hooksPath=$(git config --local --get core.hooksPath)"
echo

for dep in git-lfs python3 uvx; do
    if command -v "$dep" >/dev/null 2>&1; then
        echo "[ok] $dep"
    else
        echo "[warning] $dep not found"
    fi
done
