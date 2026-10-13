#!/usr/bin/env python3
"""Explicit, hash-verified Dropbox source staging and optional pixel-art conversion.

This deliberately does NOT call Asset V2 ingest. Review must be pinned to
a particular package hash and every imported source entry.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import stat
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

PROJECT = Path(__file__).resolve().parents[2]
TOOLS = Path(__file__).resolve().parents[1]
REVIEW_FILE = "content/metadata/assets/source_review_receipts.v1.json"
MAX_ARCHIVE = 1024 * 1024 * 1024
MAX_ENTRY = 256 * 1024 * 1024


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _safe_path(path: str) -> PurePosixPath:
    p = PurePosixPath(path)
    if (not path or path.startswith("/") or "\\" in path or
            any(part in ("", ".", "..") for part in path.split("/")) or
            p.is_absolute() or p.as_posix() != path):
        raise ValueError("unsafe archive path")
    return p


def _read_receipt(project: Path, batch_id: str, digest: str) -> dict:
    path = project / REVIEW_FILE
    raw = json.loads(path.read_text(encoding="utf-8"))
    if raw.get("schema") != "custodian.asset_source_reviews.v1":
        raise ValueError("unrecognized review receipt schema")
    matching = [r for r in raw.get("receipts", [])
                if r.get("batch_id") == batch_id and r.get("sha256") == digest]
    if len(matching) != 1:
        raise ValueError("exact approved source package receipt not found")
    receipt = matching[0]
    if receipt.get("decision") != "approved":
        raise ValueError("source package review is not approved")
    if not receipt.get("reviewed_by") or not receipt.get("reviewed_at") or not receipt.get("authoring_chat"):
        raise ValueError("approval provenance missing")
    if not receipt.get("sources") or not isinstance(receipt["sources"], list):
        raise ValueError("approved receipt requires exact per-state sources")
    return receipt


def _audit_zip(path: Path, receipt: dict) -> list[tuple[dict, bytes]]:
    approved: dict[str, dict] = {}
    for source in receipt["sources"]:
        name = source.get("entry", "")
        p = _safe_path(name)
        if not (str(p).startswith("custodian/asset_drop/source_work/") and p.suffix.lower() == ".png"):
            raise ValueError("approved source must live in asset_drop/source_work")
        if len(p.parts) < 6 or not p.name.endswith("_source.png"):
            raise ValueError("source state path does not meet family convention")
        if source.get("family_id") != p.parts[-2]:
            raise ValueError("source family mismatch")
        if source.get("state_id") + "_source.png" != p.name:
            raise ValueError("source state ID mismatch")
        digest = source.get("sha256", "")
        if len(digest) != 64 or not all(c in "0123456789abcdef" for c in digest):
            raise ValueError("source state hash required")
        if name in approved:
            raise ValueError("duplicate approved source path")
        approved[name] = source
    inspected: list[tuple[dict, bytes]] = []
    with zipfile.ZipFile(path) as archive:
        seen: set[str] = set()
        total = 0
        for info in archive.infolist():
            p = _safe_path(info.filename.rstrip("/"))
            if info.filename in seen:
                raise ValueError("duplicate archive member")
            seen.add(info.filename)
            if stat.S_IFMT(info.external_attr >> 16) == stat.S_IFLNK:
                raise ValueError("archive contains symlink")
            if info.is_dir():
                continue
            if info.file_size > MAX_ENTRY:
                raise ValueError("oversize archive member")
            total += info.file_size
            if total > MAX_ARCHIVE:
                raise ValueError("archive decompression limit exceeded")
            if str(p) not in approved:
                # README and manifest may accompany source images.
                if (p.suffix.lower() == ".png" or
                        p.suffix.lower() not in (".md", ".json", ".txt", ".sha256")):
                    raise ValueError("undeclared binary source in archive")
                continue
            with archive.open(info) as handle:
                data = handle.read(MAX_ENTRY + 1)
            if len(data) != info.file_size or len(data) > MAX_ENTRY:
                raise ValueError("truncated source entry")
            if sha256_bytes(data) != approved[str(p)]["sha256"]:
                raise ValueError("source member SHA256 differs from approved receipt")
            inspected.append((approved[str(p)], data))
    if len(inspected) != len(approved):
        raise ValueError("approved source member missing from archive")
    try:
        from PIL import Image
        from io import BytesIO
    except ImportError as exc:
        raise ValueError("Pillow required for source validation") from exc
    for source, data in inspected:
        with Image.open(BytesIO(data)) as im:
            im.verify()
        with Image.open(BytesIO(data)) as im:
            if im.format != "PNG" or im.mode != "RGBA":
                raise ValueError("source asset requires true RGBA PNG")
            if source.get("source_dimensions") and list(im.size) != source["source_dimensions"]:
                raise ValueError("source dimensions do not match approval")
            frames = source.get("frames", 1)
            if not isinstance(frames, int) or frames < 1:
                raise ValueError("invalid frame count")
            if frames > 1 and im.width % frames:
                raise ValueError("source strip cannot be divided into fixed frames")
    return sorted(inspected, key=lambda item: item[0]["entry"])


def _normalize(source_path: Path, state: dict, target: Path) -> None:
    size = state.get("target_frame_size")
    if not (isinstance(size, list) and len(size) == 2 and
            all(isinstance(x, int) and x > 0 for x in size)):
        raise ValueError("normalization requires reviewed target_frame_size")
    cmd = [sys.executable, str(TOOLS / "art/custodian_pixelart_converter.py"),
           str(source_path), str(target), "--size", str(size[0]) + "x" + str(size[1]),
           "--choose", state.get("method", "balanced")]
    if state.get("frames", 1) > 1:
        cmd += ["--sheet", "--frames", str(state["frames"])]
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False, timeout=180)
    if proc.returncode or not target.is_file():
        raise RuntimeError("pixel-art conversion failed: " + proc.stderr[-350:])
    from PIL import Image
    with Image.open(target) as im:
        expected = (size[0] * state.get("frames", 1), size[1])
        if im.size != expected or im.mode != "RGBA":
            raise ValueError("normalized output does not match approved sheet contract")


def plan(project: Path, package: Path, batch_id: str, normalize: bool) -> tuple[list[dict], list[tuple[Path, bytes]]]:
    if not package.is_file():
        raise ValueError("source ZIP missing")
    if package.stat().st_size > MAX_ARCHIVE:
        raise ValueError("package exceeds maximum size")
    digest = file_sha256(package)
    receipt = _read_receipt(project, batch_id, digest)
    inspected = _audit_zip(package, receipt)
    operations = []
    objects = []
    for state, data in inspected:
        source = project / _safe_path(state["entry"])
        target = project / "asset_drop/inbox" / state["family_id"] / (state["state_id"] + ".png")
        if source.exists() or (normalize and target.exists()):
            raise ValueError("destination exists; replacement requires separate approved workflow")
        # Normalization may only target already registered Asset V2 states.
        if normalize:
            contract_file = project / "content/metadata/assets/families" / (state["family_id"] + ".asset.json")
            if not contract_file.is_file():
                raise ValueError("Asset V2 family not registered")
            contract = json.loads(contract_file.read_text(encoding="utf-8"))
            if state["state_id"] not in contract.get("states", {}):
                raise ValueError("Asset V2 state not registered")
            if not state.get("target_frame_size"):
                raise ValueError("approved per-frame target dimensions required")
        operations.append({"source": str(source.relative_to(project)),
                           "source_sha256": state["sha256"],
                           "family_id": state["family_id"], "state_id": state["state_id"],
                           "normalize_to": str(target.relative_to(project)) if normalize else None})
        objects.append((source, data))
    return operations, objects


def stage(project: Path, package: Path, batch_id: str, normalize: bool, apply: bool) -> dict:
    operations, objects = plan(project, package, batch_id, normalize)
    result = {"batch_id": batch_id, "package_sha256": file_sha256(package),
              "applied": False, "operations": operations}
    if not apply:
        return result
    # Prepare all normalized products first. No repository writes until every conversion passes.
    staged: list[tuple[Path, Path]] = []
    with tempfile.TemporaryDirectory(prefix="custodian-asset-stage-") as tmp:
        base = Path(tmp)
        for i, (destination, data) in enumerate(objects):
            source_temp = base / ("src_" + str(i) + ".png")
            source_temp.write_bytes(data)
            staged.append((source_temp, destination))
            if normalize:
                state = next(s for s in operations if s["source"] == str(destination.relative_to(project)))
                reviewed = next(s for s in _read_receipt(project, batch_id, result["package_sha256"])["sources"]
                                if s["state_id"] == state["state_id"] and s["family_id"] == state["family_id"])
                out_temp = base / ("norm_" + str(i) + ".png")
                _normalize(source_temp, reviewed, out_temp)
                staged.append((out_temp, project / state["normalize_to"]))
        created: list[Path] = []
        try:
            for source_temp, destination in staged:
                destination.parent.mkdir(parents=True, exist_ok=True)
                with destination.open("xb") as out, source_temp.open("rb") as src:
                    while chunk := src.read(1024 * 1024):
                        out.write(chunk)
                created.append(destination)
        except Exception:
            for destination in reversed(created):
                destination.unlink(missing_ok=True)
            raise
    result["applied"] = True
    result["outputs"] = [{"path": str(path.relative_to(project)), "sha256": file_sha256(path)}
                         for _, path in staged]
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("batch_id")
    parser.add_argument("--zip", type=Path, required=True, help="local full-resolution source ZIP; download via verified Dropbox handoff first")
    parser.add_argument("--project-dir", type=Path, default=PROJECT)
    parser.add_argument("--normalize", action="store_true", help="also derive reviewed pixels into Asset V2 inbox")
    parser.add_argument("--apply", action="store_true", help="perform staged writes; default dry-run")
    args = parser.parse_args()
    try:
        payload = stage(args.project_dir.resolve(), args.zip.resolve(), args.batch_id,
                        args.normalize, args.apply)
    except (ValueError, OSError, RuntimeError, zipfile.BadZipFile, json.JSONDecodeError) as exc:
        print("Asset staging rejected: " + str(exc), file=sys.stderr)
        return 2
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
