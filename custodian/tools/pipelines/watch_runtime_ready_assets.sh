#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
INBOX_DIR="${PROJECT_DIR}/asset_drop/runtime_ready/inbox"

if ! command -v inotifywait >/dev/null 2>&1; then
  echo "watch_runtime_ready_assets.sh requires inotifywait from inotify-tools." >&2
  exit 1
fi

mkdir -p "${INBOX_DIR}"
echo "Watching ${INBOX_DIR} for completed runtime-ready asset drops..."

while true; do
  inotifywait --quiet --recursive --event close_write,moved_to "${INBOX_DIR}"
  sleep 1
  if ! python "${SCRIPT_DIR}/runtime_ready_assets.py" --apply; then
    echo "One or more drops were rejected and remain in the inbox." >&2
  fi
done
