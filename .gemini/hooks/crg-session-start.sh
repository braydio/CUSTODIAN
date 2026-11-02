#!/usr/bin/env bash

set -u

cat >/dev/null || true

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
MESSAGE=""

if [ -z "$REPO_ROOT" ]; then
    MESSAGE="code-review-graph: not inside a Git repository"
elif [ ! -x "$REPO_ROOT/tools/crg-refresh.sh" ]; then
    MESSAGE="code-review-graph: shared refresh policy unavailable"
else
    "$REPO_ROOT/tools/crg-refresh.sh" --status >&2 || true
    GIT_DIR="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-dir 2>/dev/null || true)"
    COMMON_DIR="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
    if [ -n "$GIT_DIR" ] && [ -n "$COMMON_DIR" ] && [ "$GIT_DIR" != "$COMMON_DIR" ]; then
        MESSAGE="code-review-graph: linked worktree; use coordination-root graph for baseline only, then targeted worktree reads"
    else
        MESSAGE="code-review-graph: persistent checkout refresh/status attempted"
    fi
fi

CRG_MSG="$MESSAGE" python3 - <<'PY'
import json
import os

print(json.dumps({
    "systemMessage": os.environ.get("CRG_MSG", ""),
    "suppressOutput": True
}))
PY

exit 0
