#!/usr/bin/env python3
"""Private, content-verified inventories and safe restore for archived turns.

Manifest files may contain sensitive local paths. Keep them in a private store;
the CLI never chooses a repository path for its output.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import posixpath
import shutil
import stat
import sys
import uuid
from pathlib import Path, PurePosixPath


SCHEMA = "custodian.turn_archive.v1"
LFS_HEADER = b"version https://git-lfs.github.com/spec/v1\n"


class ArchiveError(RuntimeError):
    """An unsafe or unverifiable archive operation."""


def _canonical(payload: dict) -> bytes:
    return (json.dumps(payload, sort_keys=True, separators=(",", ":"),
                       ensure_ascii=False) + "\n").encode("utf-8")


def _safe_rel(value: str) -> str:
    if not isinstance(value, str) or not value or "\0" in value or "\\" in value:
        raise ArchiveError("manifest contains an invalid path")
    try:
        value.encode("utf-8")
    except UnicodeEncodeError as exc:
        raise ArchiveError("archive paths must be valid UTF-8") from exc
    path = PurePosixPath(value)
    if path.is_absolute() or any(part in {"", ".", ".."} for part in value.split("/")):
        raise ArchiveError(f"unsafe archive path: {value!r}")
    if path.as_posix() != value:
        raise ArchiveError(f"non-canonical archive path: {value!r}")
    return value


def _safe_symlink(root: Path, rel: str, target: str) -> None:
    if not target or "\0" in target or "\\" in target or PurePosixPath(target).is_absolute():
        raise ArchiveError(f"unsafe symlink target for {rel}")
    combined = posixpath.normpath(posixpath.join(posixpath.dirname(rel), target))
    if combined == ".." or combined.startswith("../") or combined.startswith("/"):
        raise ArchiveError(f"symlink escapes archive root: {rel}")
    resolved = (root / rel).parent.joinpath(target).resolve(strict=False)
    if not resolved.is_relative_to(root):
        raise ArchiveError(f"symlink resolves outside archive root: {rel}")


def _sha_file(path: Path) -> tuple[str, int]:
    before = path.stat(follow_symlinks=False)
    digest, size = hashlib.sha256(), 0
    with path.open("rb") as stream:
        while chunk := stream.read(1024 * 1024):
            digest.update(chunk)
            size += len(chunk)
    after = path.stat(follow_symlinks=False)
    if (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) != (
            after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns) or size != before.st_size:
        raise ArchiveError(f"file changed during inventory: {path}")
    return digest.hexdigest(), size


def _lfs_pointer(path: Path, size: int) -> dict | None:
    if size > 1024:
        return None
    content = path.read_bytes()
    if not content.startswith(LFS_HEADER):
        return None
    fields = {}
    for line in content.decode("ascii", errors="strict").splitlines()[1:]:
        key, sep, value = line.partition(" ")
        if not sep or key in fields:
            raise ArchiveError(f"malformed Git LFS pointer: {path}")
        fields[key] = value
    oid = fields.get("oid", "")
    declared_size = fields.get("size", "")
    if not oid.startswith("sha256:") or len(oid.removeprefix("sha256:")) != 64:
        raise ArchiveError(f"invalid Git LFS object identity: {path}")
    try:
        int(oid.removeprefix("sha256:"), 16)
        lfs_size = int(declared_size)
    except ValueError as exc:
        raise ArchiveError(f"invalid Git LFS pointer metadata: {path}") from exc
    if lfs_size < 0:
        raise ArchiveError(f"invalid Git LFS size: {path}")
    return {"oid": oid.removeprefix("sha256:"), "size": lfs_size}


def inventory(root: Path, archive_commit: str, external_evidence: list[dict] | None = None) -> dict:
    root = root.expanduser().resolve(strict=True)
    if not root.is_dir():
        raise ArchiveError("archive root must be a directory")
    if not isinstance(archive_commit, str) or len(archive_commit) not in {40, 64}:
        raise ArchiveError("archive commit must be a full Git object id")
    try:
        int(archive_commit, 16)
    except ValueError as exc:
        raise ArchiveError("archive commit must be hexadecimal") from exc

    rows: list[dict] = []
    stack = [root]
    while stack:
        directory = stack.pop()
        try:
            children = sorted(os.scandir(directory), key=lambda item: item.name, reverse=True)
        except OSError as exc:
            raise ArchiveError(f"cannot read archive directory {directory}") from exc
        for child in children:
            path = Path(child.path)
            rel = path.relative_to(root).as_posix()
            _safe_rel(rel)
            info = child.stat(follow_symlinks=False)
            mode = stat.S_IMODE(info.st_mode)
            if stat.S_ISDIR(info.st_mode):
                rows.append({"path": rel, "type": "directory", "mode": mode})
                stack.append(path)
            elif stat.S_ISREG(info.st_mode):
                sha, size = _sha_file(path)
                entry = {"path": rel, "type": "file", "mode": mode,
                         "sha256": sha, "size": size}
                lfs = _lfs_pointer(path, size)
                if lfs:
                    entry["git_lfs"] = lfs
                rows.append(entry)
            elif stat.S_ISLNK(info.st_mode):
                target = os.readlink(path)
                encoded = target.encode("utf-8", errors="surrogateescape")
                row = {"path": rel, "type": "symlink", "mode": mode,
                       "target": target,
                       "target_sha256": hashlib.sha256(encoded).hexdigest()}
                try:
                    _safe_symlink(root, rel, target)
                    row["restore_safe"] = True
                except ArchiveError:
                    row["restore_safe"] = False
                rows.append(row)
            else:
                raise ArchiveError(f"unsupported filesystem object: {rel}")
    rows.sort(key=lambda item: item["path"])
    refs = []
    for reference in external_evidence or []:
        if not isinstance(reference, dict) or not reference.get("id"):
            raise ArchiveError("external evidence references need a stable id")
        digest = reference.get("sha256")
        if not isinstance(digest, str) or len(digest) != 64:
            raise ArchiveError("external evidence references need a SHA-256")
        try:
            int(digest, 16)
        except ValueError as exc:
            raise ArchiveError("external evidence SHA-256 must be hexadecimal") from exc
        source_path = Path(reference.get("source_path", "")).expanduser()
        if not source_path.is_absolute() or not source_path.is_file() or source_path.is_symlink():
            raise ArchiveError("external evidence needs an absolute regular-file source_path")
        actual_sha, actual_size = _sha_file(source_path)
        if actual_sha != digest or reference.get("size") != actual_size:
            raise ArchiveError(f"external evidence identity mismatch: {reference['id']}")
        refs.append({"id": str(reference["id"]), "source_path": str(source_path.resolve()),
                     "type": "file", "sha256": actual_sha, "size": actual_size,
                     "state": "verified-external-reference"})
    payload = {"schema": SCHEMA, "archive_commit": archive_commit,
               "coverage": {"filesystem": "complete", "external_evidence":
                            "enumerated" if refs else "not-enumerated"},
               "entries": rows, "external_evidence": refs}
    payload["manifest_sha256"] = hashlib.sha256(_canonical(payload)).hexdigest()
    return payload


def write_manifest(path: Path, manifest: dict) -> None:
    path = path.expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + f".{uuid.uuid4().hex}.tmp")
    try:
        temp.write_bytes(_canonical(manifest))
        os.chmod(temp, 0o600)
        os.replace(temp, path)
    finally:
        if temp.exists():
            temp.unlink()


def load_manifest(path: Path) -> dict:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ArchiveError("manifest is missing or invalid JSON") from exc
    if not isinstance(payload, dict) or payload.get("schema") != SCHEMA:
        raise ArchiveError("unsupported archive manifest schema")
    claimed = payload.get("manifest_sha256")
    unsigned = {key: value for key, value in payload.items() if key != "manifest_sha256"}
    actual = hashlib.sha256(_canonical(unsigned)).hexdigest()
    if claimed != actual:
        raise ArchiveError("manifest checksum mismatch")
    seen: set[str] = set()
    for entry in payload.get("entries", []):
        rel = _safe_rel(entry.get("path"))
        if rel in seen:
            raise ArchiveError(f"duplicate manifest path: {rel}")
        seen.add(rel)
        if entry.get("type") not in {"directory", "file", "symlink"}:
            raise ArchiveError(f"unsupported manifest file type: {rel}")
    return payload


def verify(root: Path, manifest: dict) -> dict:
    actual = inventory(root, manifest["archive_commit"], manifest.get("external_evidence", []))
    if actual != manifest:
        expected = {item["path"]: item for item in manifest.get("entries", [])}
        observed = {item["path"]: item for item in actual.get("entries", [])}
        missing = sorted(expected.keys() - observed.keys())
        extra = sorted(observed.keys() - expected.keys())
        changed = sorted(path for path in expected.keys() & observed.keys()
                         if expected[path] != observed[path])
        raise ArchiveError(f"archive verification failed (missing={len(missing)}, "
                           f"extra={len(extra)}, changed={len(changed)})")
    for reference in manifest.get("external_evidence", []):
        path = Path(reference["source_path"])
        if path.is_symlink() or not path.is_file():
            raise ArchiveError(f"external evidence is unavailable: {reference['id']}")
        digest, size = _sha_file(path)
        if digest != reference["sha256"] or size != reference["size"]:
            raise ArchiveError(f"external evidence changed: {reference['id']}")
    return {"verified": True, "entries": len(actual["entries"]),
            "manifest_sha256": actual["manifest_sha256"],
            "external_evidence_verified": len(manifest.get("external_evidence", []))}


def restore(source: Path, manifest: dict, destination: Path) -> dict:
    source = source.expanduser().resolve(strict=True)
    destination = destination.expanduser().absolute()
    if destination.name in {"", ".", ".."}:
        raise ArchiveError("restore destination must name a new directory")
    if destination.exists() or destination.is_symlink():
        raise ArchiveError("restore destination must not already exist")
    if not destination.parent.is_dir():
        raise ArchiveError("restore destination parent must exist")
    destination = destination.parent.resolve(strict=True) / destination.name
    verify(source, manifest)
    stage = destination.parent / f".{destination.name}.restore-{uuid.uuid4().hex}"
    stage.mkdir(mode=0o700)
    try:
        entries = manifest["entries"]
        for entry in entries:
            rel = _safe_rel(entry["path"])
            target = stage.joinpath(*PurePosixPath(rel).parts)
            if not target.resolve(strict=False).is_relative_to(stage.resolve()):
                raise ArchiveError(f"restore path escapes destination: {rel}")
            if entry["type"] == "directory":
                target.mkdir(parents=True, exist_ok=True, mode=0o700)
        for entry in entries:
            if entry["type"] != "file":
                continue
            rel = _safe_rel(entry["path"])
            source_file = source.joinpath(*PurePosixPath(rel).parts)
            target = stage.joinpath(*PurePosixPath(rel).parts)
            target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            digest, size = hashlib.sha256(), 0
            with source_file.open("rb") as incoming, target.open("xb") as outgoing:
                while chunk := incoming.read(1024 * 1024):
                    digest.update(chunk)
                    size += len(chunk)
                    outgoing.write(chunk)
                outgoing.flush()
                os.fsync(outgoing.fileno())
            if digest.hexdigest() != entry["sha256"] or size != entry["size"]:
                raise ArchiveError(f"source changed during restore: {rel}")
            os.chmod(target, entry["mode"])
        for entry in entries:
            if entry["type"] != "symlink":
                continue
            rel = _safe_rel(entry["path"])
            target = stage.joinpath(*PurePosixPath(rel).parts)
            if entry.get("restore_safe") is not True:
                raise ArchiveError(f"unsafe symlink restore blocked: {rel}")
            _safe_symlink(stage, rel, entry["target"])
            target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            os.symlink(entry["target"], target)
        for entry in reversed(entries):
            if entry["type"] == "directory":
                target = stage.joinpath(*PurePosixPath(entry["path"]).parts)
                os.chmod(target, entry["mode"])
        verify(stage, manifest)
        os.rename(stage, destination)
    except Exception:
        for root, dirs, _ in os.walk(stage, topdown=True, followlinks=False):
            for directory in dirs:
                path = Path(root) / directory
                if not path.is_symlink():
                    try:
                        os.chmod(path, 0o700)
                    except OSError:
                        pass
        shutil.rmtree(stage, ignore_errors=True)
        raise
    return {"restored": True, "destination": str(destination),
            "manifest_sha256": manifest["manifest_sha256"]}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="action", required=True)
    cmd = commands.add_parser("inventory")
    cmd.add_argument("--root", type=Path, required=True)
    cmd.add_argument("--commit", required=True)
    cmd.add_argument("--manifest", type=Path, required=True)
    cmd.add_argument("--external-evidence-json", type=Path,
                     help="private JSON array of {id, source_path, sha256, size} records")
    cmd = commands.add_parser("verify")
    cmd.add_argument("--root", type=Path, required=True)
    cmd.add_argument("--manifest", type=Path, required=True)
    cmd = commands.add_parser("restore")
    cmd.add_argument("--root", type=Path, required=True)
    cmd.add_argument("--manifest", type=Path, required=True)
    cmd.add_argument("--destination", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        if args.action == "inventory":
            refs = (json.loads(args.external_evidence_json.read_text(encoding="utf-8"))
                    if args.external_evidence_json else [])
            manifest = inventory(args.root, args.commit, refs)
            write_manifest(args.manifest, manifest)
            result = {"entries": len(manifest["entries"]),
                      "manifest": str(args.manifest),
                      "manifest_sha256": manifest["manifest_sha256"]}
        else:
            manifest = load_manifest(args.manifest)
            if args.action == "verify":
                result = verify(args.root, manifest)
            else:
                result = restore(args.root, manifest, args.destination)
        print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    except (ArchiveError, OSError) as exc:
        print(json.dumps({"status": "blocked", "error": str(exc)}, indent=2), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
