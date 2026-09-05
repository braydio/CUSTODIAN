#!/usr/bin/env bash

set -u

cat >/dev/null || true

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
MESSAGE=""

if [ -z "$REPO_ROOT" ]; then
    MESSAGE="code-review-graph: not inside a Git repository"
elif ! command -v uvx >/dev/null 2>&1; then
    MESSAGE="code-review-graph: uvx not found"
else
    if uvx code-review-graph update --repo "$REPO_ROOT" >&2; then
        MESSAGE="$(
            uvx code-review-graph status --repo "$REPO_ROOT" 2>&1 |
            head -n 1
        )"
    else
        MESSAGE="code-review-graph: startup update failed"
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
