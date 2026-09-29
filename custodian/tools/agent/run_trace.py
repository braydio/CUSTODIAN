#!/usr/bin/env python3
"""Inspect local or published CUSTODIAN workflow diagnostics."""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from workflow_control import common_dir, find_local_trace, git


def list_traces(repo: Path, workstream: str | None) -> int:
    root = common_dir(repo) / "custodian-workflow" / "traces"
    local = []
    if root.exists():
        for path in sorted(root.glob("*/**/*.jsonl")):
            if workstream and path.parent.name != workstream:
                continue
            local.append({"run_id": path.stem, "workstream": path.parent.name, "source": "local", "path": str(path)})
    remote = git(repo, "ls-remote", "--heads", "origin", "refs/heads/agent-diagnostics/*", check=False)
    refs = []
    for line in remote.stdout.splitlines():
        if len(line.split()) < 2:
            continue
        ref = line.split()[1].removeprefix("refs/heads/")
        bits = ref.split("/")
        if len(bits) >= 3 and (not workstream or bits[1] == workstream):
            refs.append({"run_id": "/".join(bits[2:]), "workstream": bits[1], "source": "origin", "ref": ref})
    print(json.dumps(local + refs, indent=2, sort_keys=True))
    return 0


def export_trace(repo: Path, identity: str) -> int:
    if identity.startswith("refs/heads/"):
        ref = identity
        match = re.fullmatch(r"refs/heads/agent-diagnostics/([a-z0-9-]+)/([A-Za-z0-9Tz-]+)", ref)
        if not match:
            raise ValueError("export accepts only refs/heads/agent-diagnostics/<workstream>/<run-id>")
        result = git(repo, "show", f"{ref}:trace.jsonl", check=False)
        content = result.stdout if result.returncode == 0 else git(repo, "show", f"origin/{ref.removeprefix('refs/heads/')}:trace.jsonl")
    else:
        if not re.fullmatch(r"[A-Za-z0-9Tz-]+", identity):
            raise ValueError("run ID has invalid characters")
        path = find_local_trace(repo, identity)
        if path:
            content = path.read_text()
        else:
            refs = git(repo, "ls-remote", "--heads", "origin", "refs/heads/agent-diagnostics/*", check=False).stdout.splitlines()
            candidates = [line.split()[1] for line in refs if line.split()[1].endswith("/" + identity)]
            if len(candidates) != 1:
                raise ValueError("run ID is unavailable locally or ambiguous/unavailable on origin")
            content = git(repo, "show", f"origin/{candidates[0].removeprefix('refs/heads/')}:trace.jsonl")
    events = [json.loads(line) for line in content.splitlines() if line.strip()]
    print(json.dumps({"schema": "custodian.workflow_trace_export.v1", "events": events}, indent=2, sort_keys=True))
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    p = subs.add_parser("list"); p.add_argument("--workstream")
    p = subs.add_parser("export"); p.add_argument("identity"); p.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    try:
        repo = Path(git(Path.cwd(), "rev-parse", "--show-toplevel")).resolve()
        if args.command == "list":
            return list_traces(repo, args.workstream)
        return export_trace(repo, args.identity)
    except (ValueError, RuntimeError) as error:
        print(f"run_trace: BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
