#!/usr/bin/env python3
"""Capacity planning and exact, local-only LFS worktree materialization."""
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path, PurePosixPath


PROFILE_SCHEMA = "custodian.worktree_checkout_profile.v1"
SAFETY_RESERVE_BYTES = 1024 * 1024 * 1024
LFS_POINTER_LIMIT = 1024
PROFILE_MAX_BYTES = 2 * 1024 * 1024
PROFILE_MAX_PATHS = 20_000


class ProvisioningError(RuntimeError):
    pass


@dataclass(frozen=True)
class Profile:
    path: str
    digest: str
    include: tuple[str, ...]
    hydrate_lfs: tuple[str, ...]


@dataclass(frozen=True)
class TreeFile:
    path: str
    oid: str
    git_size: int
    lfs_size: int | None = None
    lfs_oid: str | None = None
    mode: str = "100644"


def _git(repo: Path, *args: str, input_bytes: bytes | None = None, check: bool = True) -> bytes:
    result = subprocess.run(["git", *args], cwd=repo, input=input_bytes, capture_output=True, check=False)
    if check and result.returncode:
        detail = (result.stderr or result.stdout).decode("utf-8", "replace").strip()
        raise ProvisioningError(f"git {' '.join(args)} failed: {detail}")
    return result.stdout


def _safe_relative(value: object) -> str:
    if not isinstance(value, str) or not value or "\\" in value or "\x00" in value:
        raise ProvisioningError("profile paths must be non-empty repository-relative POSIX paths")
    path = PurePosixPath(value)
    if (path.is_absolute() or not path.parts or path.as_posix() != value
            or any(part in {"", ".", ".."} for part in path.parts)):
        raise ProvisioningError(f"profile path escapes or is not canonical: {value!r}")
    return path.as_posix()


def load_profile(repo: Path, ref: str, profile_path: str | None) -> Profile | None:
    if profile_path is None:
        return None
    rel = _safe_relative(profile_path)
    try:
        raw = _git(repo, "show", f"{ref}:{rel}")
        if len(raw) > PROFILE_MAX_BYTES:
            raise ProvisioningError(f"checkout profile {rel} exceeds the {PROFILE_MAX_BYTES}-byte limit")
        value = json.loads(raw)
    except (ProvisioningError, json.JSONDecodeError) as exc:
        raise ProvisioningError(f"cannot read checkout profile {rel} from {ref}: {exc}") from exc
    if not isinstance(value, dict) or value.get("schema") != PROFILE_SCHEMA:
        raise ProvisioningError(f"checkout profile {rel} has an unsupported schema")
    include = value.get("include_paths")
    hydrate = value.get("hydrate_lfs_paths")
    if not isinstance(include, list) or not include or not isinstance(hydrate, list):
        raise ProvisioningError("profile must declare non-empty include_paths and hydrate_lfs_paths lists")
    if len(include) > PROFILE_MAX_PATHS or len(hydrate) > PROFILE_MAX_PATHS:
        raise ProvisioningError(f"checkout profile exceeds the {PROFILE_MAX_PATHS}-path limit")
    safe_include = tuple(dict.fromkeys(_safe_relative(path) for path in include))
    safe_hydrate = tuple(dict.fromkeys(_safe_relative(path) for path in hydrate))
    if len(safe_include) != len(include) or len(safe_hydrate) != len(hydrate):
        raise ProvisioningError("profile paths must be unique")
    return Profile(rel, hashlib.sha256(raw).hexdigest(), safe_include, safe_hydrate)


def _tree_files(repo: Path, ref: str) -> list[TreeFile]:
    raw = _git(repo, "ls-tree", "-r", "-l", "-z", ref)
    files: list[TreeFile] = []
    for entry in raw.split(b"\0"):
        if not entry:
            continue
        metadata, sep, path = entry.partition(b"\t")
        fields = metadata.split()
        if not sep or len(fields) != 4 or fields[1] != b"blob":
            continue
        files.append(TreeFile(os.fsdecode(path), fields[2].decode("ascii"), int(fields[3]),
                              mode=fields[0].decode("ascii")))
    return files

def _batch_blobs(repo: Path, oids: list[str]) -> dict[str, bytes]:
    if not oids:
        return {}
    # communicate() drains stdout while feeding stdin. Writing the entire object
    # list before reading can deadlock once both pipes exceed their OS buffers.
    proc = subprocess.run(["git", "cat-file", "--batch"], cwd=repo,
                          input=("\n".join(oids) + "\n").encode("ascii"),
                          capture_output=True, check=False)
    if proc.returncode:
        detail = (proc.stderr or proc.stdout).decode("utf-8", "replace").strip()
        raise ProvisioningError(f"git cat-file batch failed: {detail}")
    result: dict[str, bytes] = {}
    offset = 0
    for expected in oids:
        end = proc.stdout.find(b"\n", offset)
        if end < 0:
            raise ProvisioningError("truncated git cat-file batch header")
        header = proc.stdout[offset:end].split()
        if len(header) != 3 or header[0].decode("ascii", "replace") != expected:
            raise ProvisioningError("could not read tracked blobs for checkout capacity estimate")
        size = int(header[2])
        start = end + 1
        body_end = start + size
        if body_end >= len(proc.stdout) or proc.stdout[body_end:body_end + 1] != b"\n":
            raise ProvisioningError("malformed git cat-file batch response")
        result[expected] = proc.stdout[start:body_end]
        offset = body_end + 1
    if offset != len(proc.stdout):
        raise ProvisioningError("unexpected trailing bytes in git cat-file batch response")
    return result


def _pointer(data: bytes) -> tuple[str, int] | None:
    if len(data) > LFS_POINTER_LIMIT or not data.startswith(b"version https://git-lfs.github.com/spec/v1\n"):
        return None
    oid = re.search(rb"(?m)^oid sha256:([0-9a-f]{64})$", data)
    size = re.search(rb"(?m)^size ([0-9]+)$", data)
    if not oid or not size:
        raise ProvisioningError("malformed Git LFS pointer in tracked tree")
    return oid.group(1).decode("ascii"), int(size.group(1))


def _matches_profile(path: str, profile: Profile | None, files: set[str]) -> bool:
    if profile is None:
        return True
    for include in profile.include:
        if path == include or path.startswith(include.rstrip("/") + "/"):
            return True
    return False


def inventory(repo: Path, ref: str = "origin/main", profile: Profile | None = None) -> list[TreeFile]:
    all_files = _tree_files(repo, ref)
    file_names = {item.path for item in all_files}
    if profile:
        for include in profile.include:
            if include not in file_names and not any(path.startswith(include + "/") for path in file_names):
                raise ProvisioningError(f"profile path is not tracked at {ref}: {include}")
        for path in profile.hydrate_lfs:
            if path not in file_names or not _matches_profile(path, profile, file_names):
                raise ProvisioningError(f"hydration path is absent or not included by profile: {path}")
    chosen = [item for item in all_files if _matches_profile(item.path, profile, file_names)]
    if profile:
        symlinks = [item.path for item in chosen if item.mode == "120000"]
        if symlinks:
            raise ProvisioningError("checkout profiles cannot include tracked symlinks: " + ", ".join(symlinks))
    small = list(dict.fromkeys(item.oid for item in chosen if item.git_size <= LFS_POINTER_LIMIT))
    blobs = _batch_blobs(repo, small)
    result: list[TreeFile] = []
    for item in chosen:
        parsed = _pointer(blobs.get(item.oid, b""))
        result.append(TreeFile(item.path, item.oid, item.git_size,
                               parsed[1] if parsed else None, parsed[0] if parsed else None))
    if profile:
        for path in profile.hydrate_lfs:
            match = next(item for item in result if item.path == path)
            if match.lfs_oid is None:
                raise ProvisioningError(f"hydration path is not a Git LFS pointer: {path}")
    return result


def estimate_checkout_bytes(repo: Path, *, ref: str = "origin/main", profile: Profile | None = None,
                            deferred_lfs: bool = False) -> dict[str, int | str]:
    return _estimate_files(inventory(repo, ref, profile), profile, deferred_lfs)


def _estimate_files(files: list[TreeFile], profile: Profile | None,
                    deferred_lfs: bool) -> dict[str, int | str]:
    payload = sum(
        (item.lfs_size if item.path in (profile.hydrate_lfs if profile else ()) else item.git_size)
        if deferred_lfs else (item.git_size if item.lfs_size is None else item.lfs_size)
        for item in files
    )
    dirs = {str(PurePosixPath(item.path).parent) for item in files}
    # One filesystem block per file and directory accounts for pointer files,
    # directory entries, and inode/block overhead rather than only Git bytes.
    filesystem = payload + 4096 * (len(files) + len(dirs))
    return {"tracked_paths": len(files), "payload_bytes": payload,
            "filesystem_bytes": filesystem, "reserve_bytes": SAFETY_RESERVE_BYTES,
            "required_free_bytes": filesystem + SAFETY_RESERVE_BYTES,
            "profile_sha256": profile.digest if profile else "full-tree"}


def _local_lfs_media_dir(repo: Path) -> Path | None:
    result = subprocess.run(["git", "lfs", "env"], cwd=repo, text=True, capture_output=True, check=False)
    match = re.search(r"(?m)^LocalMediaDir=(.+)$", result.stdout) if result.returncode == 0 else None
    return Path(match.group(1)).expanduser() if match else None


def local_lfs_object_failures(repo: Path, ref: str, profile: Profile | None,
                              files: list[TreeFile] | None = None) -> list[dict[str, str | int]]:
    """Verify every explicitly hydrated object is already present and OID-valid locally."""
    if profile is None or not profile.hydrate_lfs:
        return []
    files = files if files is not None else inventory(repo, ref, profile)
    expected = {item.path: item for item in files if item.path in profile.hydrate_lfs}
    media = _local_lfs_media_dir(repo)
    if media is None:
        return [{"path": path, "oid": expected[path].lfs_oid or "unknown",
                 "size": expected[path].lfs_size or 0, "reason": "cannot locate local Git LFS media cache"}
                for path in profile.hydrate_lfs]
    failures: list[dict[str, str | int]] = []
    for path in profile.hydrate_lfs:
        item = expected[path]
        assert item.lfs_oid is not None and item.lfs_size is not None
        obj = media / item.lfs_oid[:2] / item.lfs_oid[2:4] / item.lfs_oid
        try:
            digest = hashlib.sha256()
            size = 0
            with obj.open("rb") as stream:
                while chunk := stream.read(1024 * 1024):
                    size += len(chunk)
                    digest.update(chunk)
            valid = size == item.lfs_size and digest.hexdigest() == item.lfs_oid
        except OSError:
            valid = False
        if not valid:
            failures.append({"path": path, "oid": item.lfs_oid, "size": item.lfs_size,
                             "reason": "missing or corrupt local Git LFS object"})
    return failures


def missing_full_lfs_cache_bytes(repo: Path, ref: str = "origin/main",
                                 files: list[TreeFile] | None = None) -> int:
    """Estimate additional cache bytes a full smudge may fetch before materializing the checkout."""
    files = files if files is not None else inventory(repo, ref)
    pointers = [item for item in files if item.lfs_oid and item.lfs_size is not None]
    media = _local_lfs_media_dir(repo)
    if media is None:
        return sum(int(item.lfs_size or 0) for item in pointers)
    missing = 0
    for item in pointers:
        obj = media / item.lfs_oid[:2] / item.lfs_oid[2:4] / item.lfs_oid
        try:
            if not obj.is_file() or obj.stat().st_size != item.lfs_size:
                missing += int(item.lfs_size or 0)
        except OSError:
            missing += int(item.lfs_size or 0)
    return missing


def preflight_capacity(repo: Path, *, profile_path: str | None = None,
                       ref: str = "origin/main", target: Path | None = None) -> dict[str, int | str | bool]:
    deferred = profile_path is not None
    profile = load_profile(repo, ref, profile_path)
    files = inventory(repo, ref, profile)
    estimate = _estimate_files(files, profile, deferred)
    lfs_failures = local_lfs_object_failures(repo, ref, profile, files=files)
    cache_bytes_to_fetch = missing_full_lfs_cache_bytes(repo, ref, files=files) if profile is None else 0
    required_free = int(estimate["required_free_bytes"]) + cache_bytes_to_fetch
    destination = (target or (repo.parent / ".custodian-worktrees")).resolve()
    probe = destination
    while not probe.exists() and probe != probe.parent:
        probe = probe.parent
    if not probe.is_dir():
        raise ProvisioningError(f"checkout destination has no existing directory ancestor: {destination}")
    free = shutil.disk_usage(probe).free
    return {**estimate, "deferred_lfs": deferred, "available_free_bytes": free,
            "cache_bytes_to_fetch": cache_bytes_to_fetch,
            "required_free_bytes": required_free,
            "local_lfs_failures": lfs_failures,
            "sufficient": free >= required_free and not lfs_failures,
            "destination": str(destination)}


def _sparse_pattern(path: str) -> str:
    escaped = "".join("\\" + char if char in "\\*?[!" else char for char in path)
    return "/" + escaped


def configure_sparse_checkout(worktree: Path, repo: Path, ref: str,
                              profile: Profile) -> list[TreeFile]:
    files = inventory(repo, ref, profile)
    patterns = "\n".join(_sparse_pattern(item.path) for item in files) + "\n"
    result = subprocess.run(["git", "sparse-checkout", "set", "--no-cone", "--stdin"], cwd=worktree,
                            input=patterns.encode(), capture_output=True, check=False)
    if result.returncode:
        raise ProvisioningError("could not apply exact sparse checkout: " +
                                (result.stderr or result.stdout).decode("utf-8", "replace").strip())
    for item in files:
        if not (worktree / item.path).is_file():
            raise ProvisioningError(f"sparse checkout omitted declared path: {item.path}")
    selected = {item.path for item in files}
    for item in _tree_files(repo, ref):
        if item.path in selected:
            continue
        if (worktree / item.path).exists():
            raise ProvisioningError(f"sparse checkout unexpectedly materialized path: {item.path}")
    if profile.hydrate_lfs:
        expected = {item.path: item for item in files if item.path in profile.hydrate_lfs}
        args = ["git", "lfs", "checkout", *profile.hydrate_lfs]
        result = subprocess.run(args, cwd=worktree, capture_output=True, check=False,
                                env={**os.environ, "GIT_LFS_SKIP_SMUDGE": "1"})
        if result.returncode:
            raise ProvisioningError("local Git LFS checkout failed: " +
                                    (result.stderr or result.stdout).decode("utf-8", "replace").strip())
        for path, item in expected.items():
            target = worktree / path
            data = target.read_bytes()
            if _pointer(data) is not None or len(data) != item.lfs_size or hashlib.sha256(data).hexdigest() != item.lfs_oid:
                raise ProvisioningError(f"hydrated LFS bytes do not match pinned pointer: {path} oid={item.lfs_oid} size={item.lfs_size}")
    return files
