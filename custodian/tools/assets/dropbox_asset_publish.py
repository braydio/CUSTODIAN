#!/usr/bin/env python3
"""Publish an immutable Dropbox lifecycle audit and replace its derived latest index.

Opt-in only. Source packages and Asset V2 runtime assets are never uploaded,
moved, deleted or altered. The older upload registry is never rewritten.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import dropbox_asset_audit as audit


def resolved_remote(value: str) -> str:
    from importlib.util import module_from_spec, spec_from_file_location
    p = HERE.parent / "iteration/dropbox_transport.py"
    spec = spec_from_file_location("dropbox_transport_for_asset_publish", p)
    assert spec and spec.loader
    mod = module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.resolve_remote(value or None,
                              env_precedence=("CUSTODIAN_ASSET_REMOTE", "CUSTODIAN_REVIEW_REMOTE"))


def _execute(command: list[str]) -> None:
    p = subprocess.run(command, check=False, capture_output=True, text=True, timeout=180)
    if p.returncode:
        # Never emit rclone full stderr: remote URLs sometimes embed secrets.
        raise RuntimeError("Dropbox report publication failed; inspect configured remote permissions")


def publish(result: dict, remote: str, remote_root: str, *, apply: bool,
            run_id: str | None = None, runner=_execute) -> dict:
    if result.get("schema") != "custodian.dropbox_asset_lifecycle.v1":
        raise ValueError("unexpected audit snapshot schema")
    if not result.get("coverage", {}).get("complete"):
        raise ValueError("incomplete remote inventory cannot be published")
    if not remote_root or remote_root.startswith("/") or ".." in Path(remote_root).parts:
        raise ValueError("invalid Dropbox root")
    current = run_id or datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    if not current.replace("-", "").replace("_", "").isalnum():
        raise ValueError("run id contains unsafe characters")
    base = remote.rstrip(":") + ":" + remote_root.rstrip("/") + "/asset_batches/_registry/lifecycle"
    run_root = base + "/audit-runs"
    commands = [
        ["rclone", "mkdir", run_root],
        ["rclone", "copyto", "--immutable", "SNAPSHOT_JSON", run_root + "/" + current + ".json"],
        ["rclone", "copyto", "--immutable", "SNAPSHOT_MD", run_root + "/" + current + ".md"],
        ["rclone", "copyto", "SNAPSHOT_JSON", base + "/INDEX.json"],
        ["rclone", "copyto", "SNAPSHOT_MD", base + "/INDEX.md"],
    ]
    if not apply:
        return {"applied": False, "remote_index": base + "/INDEX.json",
                "immutable_run": run_root + "/" + current + ".json",
                "commands": [[c if not c.startswith("SNAPSHOT_") else "<local generated report>"
                              for c in cmd] for cmd in commands]}
    report = dict(result)
    report["scan_id"] = current
    report["published_at_utc"] = datetime.now(timezone.utc).isoformat()
    with tempfile.TemporaryDirectory(prefix="custodian-asset-publish-") as tmp:
        j = Path(tmp) / "INDEX.json"
        md = Path(tmp) / "INDEX.md"
        j.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        md.write_text(audit.markdown(report), encoding="utf-8")
        for command in commands:
            resolved = [str(j) if part == "SNAPSHOT_JSON" else
                        str(md) if part == "SNAPSHOT_MD" else part for part in command]
            runner(resolved)
    return {"applied": True, "remote_index": base + "/INDEX.json",
            "immutable_run": run_root + "/" + current + ".json",
            "batch_count": len(result.get("batches", [])),
            "finding_count": len(result.get("findings", []))}


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--apply", action="store_true", help="required for any Dropbox writes")
    p.add_argument("--remote", default="", help="configured rclone remote")
    p.add_argument("--dropbox-root", default="CUSTODIAN")
    p.add_argument("--project-dir", type=Path, default=audit.PROJECT)
    p.add_argument("--revision", default=os.environ.get("CUSTODIAN_MAIN_SHA", "unknown"))
    args = p.parse_args()
    try:
        remote = resolved_remote(args.remote)
        items = audit._rclone_inventory(remote, args.dropbox_root)
        registry = audit._rclone_registry(remote, args.dropbox_root)
        result = audit.reconcile(items, registry, args.project_dir, args.revision)
        posted = publish(result, remote, args.dropbox_root, apply=args.apply)
    except (OSError, ValueError, RuntimeError, json.JSONDecodeError) as exc:
        print("Asset report publication rejected: " + str(exc), file=sys.stderr)
        return 2
    print(json.dumps(posted, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
