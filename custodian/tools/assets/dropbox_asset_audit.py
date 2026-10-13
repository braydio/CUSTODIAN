#!/usr/bin/env python3
"""Read-only Dropbox source/review/Asset V2 reconciliation.

No downloading, staging, ingesting, registry writing or remote mutation.
See design/04_architecture/DROPBOX_ASSET_LIFECYCLE_RECONCILIATION_V1.md.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parent.parent
ROOTS = ("asset_batches", "implementation_inputs", "generated_asset_batches")
REGISTRY = "asset_batches/_registry/CUSTODIAN_ASSET_UPLOAD_INDEX.json"
REVIEW_FILE = "content/metadata/assets/source_review_receipts.v1.json"


def _run(args: list[str]) -> str:
    p = subprocess.run(args, capture_output=True, text=True, timeout=120, check=False)
    if p.returncode:
        # rclone stderr may contain sensitive endpoint information.
        raise RuntimeError("Dropbox read failed (check remote, path and permissions)")
    return p.stdout


def _remote_root(root: str, name: str) -> str:
    from pathlib import PurePosixPath
    if not name or name.startswith("/") or ".." in PurePosixPath(name).parts:
        raise ValueError("invalid remote path")
    return root.rstrip("/") + "/" + name


def _rclone_inventory(remote: str, base: str) -> list[dict[str, Any]]:
    from importlib.util import module_from_spec, spec_from_file_location
    mod_path = HERE.parent / "iteration" / "dropbox_transport.py"
    spec = spec_from_file_location("dropbox_transport_for_asset_audit", mod_path)
    assert spec and spec.loader
    module = module_from_spec(spec)
    spec.loader.exec_module(module)
    configured = module.resolve_remote(remote or None, env_precedence=("CUSTODIAN_ASSET_REMOTE", "CUSTODIAN_REVIEW_REMOTE"))
    items: list[dict[str, Any]] = []
    for lane in ROOTS:
        target = configured + _remote_root(base, lane)
        try:
            listing = json.loads(_run(["rclone", "lsjson", "--recursive", "--files-only", target]))
        except (RuntimeError, json.JSONDecodeError) as exc:
            raise RuntimeError("Cannot complete remote lane " + lane) from exc
        if not isinstance(listing, list):
            raise ValueError("unexpected rclone list schema")
        for obj in listing:
            if not isinstance(obj, dict) or not isinstance(obj.get("Path"), str):
                raise ValueError("malformed rclone inventory")
            items.append({
                "path": "/" + _remote_root(base, lane).strip("/") + "/" + obj["Path"].lstrip("/"),
                "name": obj.get("Name", Path(obj["Path"]).name),
                "bytes": obj.get("Size"),
                "modified": obj.get("ModTime"),
                "id": obj.get("ID"),
            })
    return items


def _rclone_registry(remote: str, base: str) -> dict[str, Any]:
    from importlib.util import module_from_spec, spec_from_file_location
    spec = spec_from_file_location("dropbox_transport_for_asset_audit", HERE.parent / "iteration" / "dropbox_transport.py")
    assert spec and spec.loader
    module = module_from_spec(spec)
    spec.loader.exec_module(module)
    configured = module.resolve_remote(remote or None, env_precedence=("CUSTODIAN_ASSET_REMOTE", "CUSTODIAN_REVIEW_REMOTE"))
    try:
        data = json.loads(_run(["rclone", "cat", configured + _remote_root(base, REGISTRY)]))
    except (RuntimeError, json.JSONDecodeError) as exc:
        raise RuntimeError("Cannot read Dropbox upload registry") from exc
    return data


def _fixture(path: Path) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise ValueError("fixture must be object")
    return raw.get("entries", []), raw.get("registry", {})


def _receipts(project: Path) -> dict[tuple[str, str], dict[str, Any]]:
    p = project / REVIEW_FILE
    if not p.exists():
        return {}
    raw = json.loads(p.read_text(encoding="utf-8"))
    if raw.get("schema") != "custodian.asset_source_reviews.v1":
        raise ValueError("unexpected source review receipt schema")
    allowed = {"approved", "rejected", "needs_regeneration", "superseded"}
    by_key: dict[tuple[str, str], dict[str, Any]] = {}
    for r in raw.get("receipts", []):
        if not isinstance(r, dict) or r.get("decision") not in allowed:
            raise ValueError("invalid review receipt")
        batch_id, digest = r.get("batch_id", ""), r.get("sha256", "")
        if not batch_id or len(digest) != 64 or not all(c in "0123456789abcdef" for c in digest):
            raise ValueError("review receipt must pin a package SHA256")
        key = batch_id, digest
        if key in by_key:
            raise ValueError("duplicate review decision for identical package")
        if not r.get("reviewed_by") or not r.get("reviewed_at") or not r.get("authoring_chat"):
            raise ValueError("review decision missing provenance")
        by_key[key] = r
    return by_key


def _families(project: Path) -> dict[str, Any]:
    sys.path.insert(0, str(HERE))
    from asset_contract import load_all_families
    from asset_status import get_family_status
    result: dict[str, Any] = {}
    directory = project / "content/metadata/assets/families"
    for fid, contract in load_all_families(directory).items():
        status = get_family_status(contract, project)
        states = {}
        for sid, s in status.states.items():
            states[sid] = {
                "source_pending": s.source_pending,
                "art_present": s.art_present,
                "imported": s.imported,
                "bound": s.bound,
                "runtime_verified": s.runtime_verified,
                "runtime_path": s.runtime_path,
            }
        result[fid] = {"completeness": status.completeness, "states": states}
    return result


def _required(project: Path) -> dict[str, Any]:
    path = project / "content/metadata/assets/required_assets.registry.json"
    if not path.exists():
        return {}
    raw = json.loads(path.read_text(encoding="utf-8"))
    return {r["id"]: r.get("fulfillment", {}) for r in raw.get("requirements", [])}


def _packages(items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    packages = []
    for entry in items:
        if not isinstance(entry, dict):
            raise ValueError("malformed file in remote inventory")
        path = entry.get("path", "")
        if not isinstance(path, str) or not path.startswith("/") or ".." in Path(path).parts:
            raise ValueError("malformed path in remote inventory")
        if not path.lower().endswith(".zip"):
            continue
        packages.append({
            "path": path, "name": entry.get("name") or Path(path).name,
            "bytes": entry.get("bytes"), "modified": entry.get("modified"),
            "remote_file_id": entry.get("id"),
        })
    return sorted(packages, key=lambda x: x["path"].lower())


def reconcile(items: list[dict[str, Any]], registry: dict[str, Any], project: Path,
              revision: str = "unknown") -> dict[str, Any]:
    if registry and registry.get("schema") != "custodian.dropbox_asset_upload_index.v1":
        raise ValueError("unexpected registry schema")
    packages = _packages(items)
    declared = registry.get("batches", [])
    if not isinstance(declared, list):
        raise ValueError("invalid registry batches")
    receipts = _receipts(project)
    known = _families(project)
    by_dir: dict[str, list[dict[str, Any]]] = {}
    for pkg in packages:
        by_dir.setdefault(str(Path(pkg["path"]).parent), []).append(pkg)
    rows = []
    findings = []
    matched_paths = set()
    for b in declared:
        bid = str(b.get("batch_id", ""))
        folder = str(b.get("dropbox_path", "")).rstrip("/")
        matched = by_dir.get(folder, [])
        declared_name = b.get("zip_name") or b.get("package")
        if declared_name:
            matched = [p for p in matched if p["name"] == declared_name]
        if not matched:
            findings.append({"id": "DBX-MISSING-" + bid, "type": "missing_registered_package", "batch_id": bid})
        for pkg in matched:
            matched_paths.add(pkg["path"])
            digest = b.get("zip_sha256") or b.get("package_sha256")
            receipt = receipts.get((bid, digest)) if digest else None
            fam_ids = b.get("family_ids") or []
            if not isinstance(fam_ids, list):
                fam_ids = []
            rows.append({**pkg, "batch_id": bid, "registry_status": b.get("status", "unknown"),
                         "registered_sha256": digest, "review_status": receipt["decision"] if receipt else "unverified_review",
                         "family_ids": fam_ids, "family_state": {fid: known.get(fid) for fid in fam_ids},
                         "known_asset_count": b.get("asset_count"), "receipt_present": bool(receipt)})
    for pkg in packages:
        if pkg["path"] in matched_paths:
            continue
        name = pkg["name"].removesuffix(".zip").lower().replace("_", "-")
        rows.append({**pkg, "batch_id": name, "registry_status": "unregistered",
                     "registered_sha256": None, "review_status": "awaiting_review",
                     "family_ids": [], "family_state": {}, "known_asset_count": None, "receipt_present": False})
        findings.append({"id": "DBX-UNREGISTERED-" + name, "type": "unregistered_package", "path": pkg["path"]})
    rows.sort(key=lambda p: p["path"].lower())
    findings.sort(key=lambda x: x["id"])
    return {"schema": "custodian.dropbox_asset_lifecycle.v1",
            "repository_revision": revision,
            "coverage": {"lanes": list(ROOTS), "complete": True, "zip_count": len(packages)},
            "registry_updated": registry.get("updated_utc"),
            "batches": rows, "families": known, "requirements": _required(project),
            "findings": findings}


def markdown(result: dict[str, Any]) -> str:
    lines = ["# Dropbox Asset Lifecycle Audit", "",
             "Repository revision: " + result["repository_revision"], "",
             "Remote ZIP packages: " + str(result["coverage"]["zip_count"]),
             "Unregistered ZIP packages: " + str(sum(f["type"] == "unregistered_package" for f in result["findings"])),
             "", "## Package intake", "",
             "| Batch | Registry | Source review | Source states | Next action |",
             "| --- | --- | --- | ---: | --- |"]
    for b in result["batches"]:
        review = b["review_status"]
        next_action = ("Register batch and request review" if b["registry_status"] == "unregistered"
                       else "Verify reviewed source / Asset V2 states" if review == "unverified_review"
                       else "Compare runtime Asset V2 status")
        lines.append("| " + " | ".join((b["batch_id"], b["registry_status"], review,
                                   str(b.get("known_asset_count") or "?"), next_action)) + " |")
    lines.extend(["", "## Current Asset V2 families", "",
                  "| Family | Required completeness | Pending inbox states | Verified states |",
                  "| --- | --- | ---: | ---: |"])
    for fid, f in sorted(result["families"].items()):
        states = f["states"]
        lines.append("| " + fid + " | " + f["completeness"] + " | " +
                     str(sum(x["source_pending"] for x in states.values())) + " | " +
                     str(sum(x["runtime_verified"] for x in states.values())) + " |")
    lines.append("")
    lines.append("Source upload is not review approval. Asset V2 is runtime authority.")
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-dir", type=Path, default=PROJECT)
    parser.add_argument("--fixture", type=Path, help="offline JSON {entries, registry}")
    parser.add_argument("--remote", default="", help="rclone remote name")
    parser.add_argument("--dropbox-root", default="CUSTODIAN")
    parser.add_argument("--revision", default=os.environ.get("CUSTODIAN_MAIN_SHA", "unknown"))
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("scan").add_argument("--json", action="store_true")
    sub.add_parser("report").add_argument("--format", choices=("markdown", "json"), default="markdown")
    a = parser.parse_args(argv)
    try:
        if a.fixture:
            items, registry = _fixture(a.fixture)
        else:
            items = _rclone_inventory(a.remote, a.dropbox_root)
            registry = _rclone_registry(a.remote, a.dropbox_root)
        result = reconcile(items, registry, a.project_dir, a.revision)
    except (RuntimeError, ValueError, OSError, KeyError, json.JSONDecodeError) as exc:
        print("Dropbox audit failed: " + str(exc), file=sys.stderr)
        return 2
    if a.command == "scan" or a.format == "json":
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(markdown(result), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
