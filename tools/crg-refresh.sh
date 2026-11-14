#!/usr/bin/env bash

set -u

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
GIT_DIR="$(git rev-parse --path-format=absolute --git-dir 2>/dev/null || true)"
COMMON_DIR="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
COORD_ROOT=""
if [ -n "$COMMON_DIR" ]; then
    COORD_ROOT="$(dirname "$COMMON_DIR")"
fi

if ! command -v uvx >/dev/null 2>&1; then
    echo "[code-review-graph] WARNING: uvx not found; graph not updated." >&2
    exit 0
fi

# code-review-graph databases are checkout-specific. CUSTODIAN's normal agent
# worktrees are ephemeral, so do not cold-build one graph per worktree unless a
# task explicitly opts in. The persistent coordination checkout is the shared
# baseline for structural orientation.
if [ -n "$GIT_DIR" ] && [ -n "$COMMON_DIR" ] && [ "$GIT_DIR" != "$COMMON_DIR" ] \
   && [ "${CRG_HOOK_WORKTREES:-0}" != "1" ]; then
    echo "[code-review-graph] Linked worktree detected; skipping local graph refresh." >&2
    echo "[code-review-graph] Baseline coordination root: $COORD_ROOT" >&2
    echo "[code-review-graph] Set CRG_HOOK_WORKTREES=1 only when this task needs a local graph." >&2
    if [ "${1:-}" = "--status" ] && [ -d "$COORD_ROOT" ]; then
        uvx code-review-graph status --repo "$COORD_ROOT" || \
            echo "[code-review-graph] WARNING: coordination graph status unavailable." >&2
    fi
    exit 0
fi

cd "$REPO_ROOT" || exit 0
echo "[code-review-graph] Updating graph for $REPO_ROOT..."

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
