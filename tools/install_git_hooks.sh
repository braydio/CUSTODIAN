#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

chmod +x .githooks/pre-commit
git config core.hooksPath .githooks

echo "Installed repo git hooks via core.hooksPath=.githooks"
echo "Current hook path: $(git config --get core.hooksPath)"
