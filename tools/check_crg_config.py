#!/usr/bin/env python3
"""Verify code-review-graph client config matches tools/crg-pin.env.

Checks the tracked Claude config (.mcp.json), the refresh hook, the
linked-worktree skip behavior, and, when present, the user-level Codex config
(reported as a warning only; it is not tracked in the repo).
"""
import json
import os
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PIN = {}
for line in (REPO / "tools" / "crg-pin.env").read_text().splitlines():
    if line and not line.startswith("#") and "=" in line:
        key, value = line.split("=", 1)
        PIN[key] = value
SPEC = f"code-review-graph=={PIN['CRG_VERSION']}"
failures = []
warnings = []


def check(ok, message):
    if not ok:
        failures.append(message)


def check_args(label, args, cwd):
    check(args[:2] == ["--from", SPEC], f"{label}: expected --from {SPEC}, got {args[:2]}")
    check("serve" in args, f"{label}: missing 'serve'")
    tools = args[args.index("--tools") + 1] if "--tools" in args else None
    check(tools == PIN["CRG_MCP_TOOLS"], f"{label}: --tools does not match crg-pin.env")
    check("[embeddings]" not in " ".join(args), f"{label}: embeddings extra must not be installed")
    check(cwd is not None and ".custodian-worktrees" not in cwd and ".codex/worktrees" not in cwd,
          f"{label}: cwd must be the persistent coordination root, got {cwd}")


mcp = json.loads((REPO / ".mcp.json").read_text())["mcpServers"]["code-review-graph"]
check_args(".mcp.json", mcp["args"], mcp.get("cwd"))

codex_path = Path.home() / ".codex" / "config.toml"
if codex_path.exists():
    server = tomllib.loads(codex_path.read_text()).get("mcp_servers", {}).get("code-review-graph")
    if server:
        before = len(failures)
        check_args("~/.codex/config.toml", server["args"], server.get("cwd"))
        if len(failures) > before:
            warnings.extend(failures[before:])
            del failures[before:]

refresh = (REPO / "tools" / "crg-refresh.sh").read_text()
check("uvx code-review-graph" not in refresh, "crg-refresh.sh: unpinned 'uvx code-review-graph' call")

# Behavior: fake uvx records its argv; no network, no real graph.
with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)
    log = tmp / "uvx.log"
    bindir = tmp / "bin"
    bindir.mkdir()
    fake = bindir / "uvx"
    fake.write_text(f'#!/usr/bin/env bash\necho "$*" >> "{log}"\n')
    fake.chmod(0o755)
    root, wt = tmp / "root", tmp / "wt"
    git = lambda *a, cwd=root: subprocess.run(["git", *a], cwd=cwd, check=True, capture_output=True)
    root.mkdir()
    git("init", "-q", "-b", "main")
    git("-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "x")
    git("worktree", "add", "-q", str(wt), "-b", "side")

    def run(cwd, *args, **env):
        log.write_text("")
        subprocess.run(["bash", str(REPO / "tools" / "crg-refresh.sh"), *args], cwd=cwd,
                       env={**os.environ, "PATH": f"{bindir}:{os.environ['PATH']}", **env},
                       check=True, capture_output=True)
        return log.read_text().splitlines()

    calls = run(wt, "--status")
    check(not any(" update " in f" {c} " for c in calls), f"linked worktree must not update: {calls}")
    check(any(f"status --repo {root.resolve()}" in c for c in calls),
          f"linked worktree should report root status: {calls}")
    check(all(SPEC in c for c in calls), f"unpinned call in linked worktree: {calls}")
    check(any(" update " in f" {c} " for c in run(wt, CRG_HOOK_WORKTREES="1")),
          "CRG_HOOK_WORKTREES=1 must allow a worktree update")
    calls = run(root)
    check(any(" update " in f" {c} " for c in calls) and all(SPEC in c for c in calls),
          f"root checkout must run a pinned update: {calls}")

for w in warnings:
    print(f"WARN  {w}")
for f in failures:
    print(f"FAIL  {f}")
if failures:
    sys.exit(1)
print("crg config OK" + (f" ({len(warnings)} user-level warning(s))" if warnings else ""))
