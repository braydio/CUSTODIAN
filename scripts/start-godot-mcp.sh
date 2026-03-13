#!/usr/bin/env bash
set -euo pipefail

# Starts Godot MCP server (if needed) and launches Godot editor wired to it.
# Usage:
#   scripts/start-godot-mcp.sh
#   scripts/start-godot-mcp.sh --headless-editor

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/custodian"
MCP_URL_DEFAULT="ws://127.0.0.1:6505"
MCP_URL="${GODOT_MCP_URL:-$MCP_URL_DEFAULT}"
GODOT_CMD=(godot --path "$PROJECT_DIR")

if [[ "${1:-}" == "--headless-editor" ]]; then
  GODOT_CMD=(godot --headless --editor --path "$PROJECT_DIR")
fi

host_and_port="${MCP_URL#ws://}"
MCP_HOST="${host_and_port%%:*}"
MCP_PORT="${host_and_port##*:}"

if [[ -z "$MCP_HOST" || -z "$MCP_PORT" ]]; then
  echo "Invalid GODOT_MCP_URL: $MCP_URL" >&2
  exit 1
fi

server_started_by_script=0
server_pid=""

cleanup() {
  if [[ "$server_started_by_script" -eq 1 && -n "$server_pid" ]]; then
    kill "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if nc -z "$MCP_HOST" "$MCP_PORT" >/dev/null 2>&1; then
  echo "[start-godot-mcp] MCP server already listening at $MCP_URL"
else
  echo "[start-godot-mcp] Starting MCP server on $MCP_URL"
  (
    cd "$ROOT_DIR"
    npx -y godot-mcp-server
  ) &
  server_pid="$!"
  server_started_by_script=1

  for _ in {1..30}; do
    if nc -z "$MCP_HOST" "$MCP_PORT" >/dev/null 2>&1; then
      break
    fi
    sleep 0.2
  done

  if ! nc -z "$MCP_HOST" "$MCP_PORT" >/dev/null 2>&1; then
    echo "[start-godot-mcp] MCP server did not open $MCP_URL in time" >&2
    exit 1
  fi
fi

echo "[start-godot-mcp] Launching Godot with GODOT_MCP_URL=$MCP_URL"
GODOT_MCP_URL="$MCP_URL" "${GODOT_CMD[@]}"
