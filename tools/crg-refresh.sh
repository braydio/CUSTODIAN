#!/usr/bin/env bash

set -u

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$REPO_ROOT" || exit 0

if ! command -v uvx >/dev/null 2>&1; then
    echo "[code-review-graph] WARNING: uvx not found; graph not updated." >&2
    exit 0
fi

echo "[code-review-graph] Updating graph..."

if uvx code-review-graph update --repo "$REPO_ROOT"; then
    echo "[code-review-graph] Graph updated."
else
    echo "[code-review-graph] WARNING: graph update failed." >&2
    exit 0
fi

if [ "${1:-}" = "--status" ]; then
    echo "[code-review-graph] Status:"
    uvx code-review-graph status --repo "$REPO_ROOT" || \
        echo "[code-review-graph] WARNING: status check failed." >&2
fi

exit 0
