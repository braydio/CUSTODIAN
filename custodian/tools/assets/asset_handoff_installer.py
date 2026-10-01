#!/usr/bin/env python3
"""Install reviewed Asset V2 source handoffs into source_work/inbox only.

This file is intentionally standalone so it can be copied into a generated
handoff bundle as INSTALL_INTO_REPO.py.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import struct
import subprocess
import sys
import tempfile
from pathlib import Path, PurePosixPath, PureWindowsPath


SCHEMA = "custodian.asset_handoff.v1"
STATUSES = {"RUNTIME_READY", "SOURCE_READY_NEEDS_TUNE", "REJECT_REGENERATE"}
IDENTIFIER = re.compile(r"^[a-z0-9][a-z0-9_-]*$")
SHA256 = re.compile(r"^[0-9a-fA-F]{64}$")
REPO_MARKERS = ("AGENTS.md", "custodian/project.godot", "custodian/tools/assets/asset.py")
DESTINATION_ROOTS = (
    PurePosixPath("custodian/asset_drop/source_work"),
    PurePosixPath("custodian/asset_drop/inbox"),
)


class HandoffError(ValueError):
    pass


def _object_no_duplicates(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise HandoffError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def _relative_path(value, label: str) -> PurePosixPath:
    if not isinstance(value, str) or not value or "\\" in value or ":" in value:
        raise HandoffError(f"{label} must be a non-empty portable relative path")
    posix = PurePosixPath(value)
    windows = PureWindowsPath(value)
    if posix.is_absolute() or windows.is_absolute() or windows.drive:
        raise HandoffError(f"{label} must not be absolute: {value!r}")
    if any(part in {"", ".", ".."} for part in value.split("/")):
        raise HandoffError(f"{label} contains an unsafe path component: {value!r}")
    return posix


def _contained(path: Path, root: Path, label: str) -> Path:
    resolved = path.resolve(strict=False)
    try:
        resolved.relative_to(root.resolve(strict=False))
    except ValueError as exc:
        raise HandoffError(f"{label} resolves outside its allowed root: {path}") from exc
    return resolved


def _package_file(package_root: Path, value: str, label: str) -> tuple[Path, bytes]:
    rel = _relative_path(value, label)
    path = package_root.joinpath(*rel.parts)
    resolved = _contained(path, package_root, label)
    try:
        data = resolved.read_bytes()
    except OSError as exc:
        raise HandoffError(f"cannot read {label} {value!r}: {exc}") from exc
    if not resolved.is_file():
        raise HandoffError(f"{label} is not a regular file: {value!r}")
    return resolved, data


def _repo_root(raw: str | None) -> Path:
    if raw:
        candidate = Path(raw).expanduser()
    else:
        cwd = Path.cwd()
        git_root = None
        try:
            result = subprocess.run(
                ["git", "-C", str(cwd), "rev-parse", "--show-toplevel"],
                capture_output=True,
                text=True,
                check=False,
                timeout=5,
            )
            if result.returncode == 0:
                git_root = Path(result.stdout.strip())
        except (OSError, subprocess.TimeoutExpired):
            pass
        candidate = git_root or next(
            (parent for parent in (cwd, *cwd.parents) if all((parent / marker).exists() for marker in REPO_MARKERS)),
            cwd,
        )
    try:
        root = candidate.resolve(strict=True)
    except OSError as exc:
        raise HandoffError(f"repository path does not exist: {candidate}") from exc
    if not root.is_dir() or not all((root / marker).is_file() for marker in REPO_MARKERS):
        raise HandoffError(
            "repository root is not a CUSTODIAN checkout; expected markers: " + ", ".join(REPO_MARKERS)
        )
    return root


def _integer(value, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise HandoffError(f"{label} must be a non-negative integer")
    return value


def _dimensions(value, label: str) -> tuple[int, int] | None:
    if value is None:
        return None
    if not isinstance(value, dict):
        raise HandoffError(f"{label} must be an object with width and height")
    width, height = value.get("width"), value.get("height")
    if any(isinstance(part, bool) or not isinstance(part, int) or part <= 0 for part in (width, height)):
        raise HandoffError(f"{label} width and height must be positive integers")
    return width, height


def _png_dimensions(data: bytes, label: str) -> tuple[int, int]:
    if len(data) < 33 or data[:8] != b"\x89PNG\r\n\x1a\n":
        raise HandoffError(f"{label} declares PNG dimensions but is not a valid PNG header")
    length = struct.unpack(">I", data[8:12])[0]
    if length != 13 or data[12:16] != b"IHDR":
        raise HandoffError(f"{label} has a malformed PNG IHDR chunk")
    width, height = struct.unpack(">II", data[16:24])
    if width < 1 or height < 1 or width > 0x7FFFFFFF or height > 0x7FFFFFFF:
        raise HandoffError(f"{label} has invalid PNG dimensions {width}x{height}")
    return width, height


def _verify_file(data: bytes, row: dict, prefix: str, dimensions_field: str, label: str) -> None:
    expected_hash = row.get(f"{prefix}_sha256")
    expected_size = row.get(f"{prefix}_size_bytes")
    if not isinstance(expected_hash, str) or not SHA256.fullmatch(expected_hash):
        raise HandoffError(f"{label} requires a 64-character {prefix}_sha256")
    expected_size = _integer(expected_size, f"{label} {prefix}_size_bytes")
    actual_hash = hashlib.sha256(data).hexdigest()
    if len(data) != expected_size:
        raise HandoffError(f"{label} byte size mismatch: expected {expected_size}, got {len(data)}")
    if actual_hash != expected_hash.lower():
        raise HandoffError(f"{label} SHA-256 mismatch")
    expected_dimensions = _dimensions(row.get(dimensions_field), f"{label} {dimensions_field}")
    if expected_dimensions is not None:
        actual_dimensions = _png_dimensions(data, label)
        if actual_dimensions != expected_dimensions:
            raise HandoffError(
                f"{label} PNG dimensions mismatch: expected {expected_dimensions[0]}x{expected_dimensions[1]}, "
                f"got {actual_dimensions[0]}x{actual_dimensions[1]}"
            )


def _destination(repo: Path, value: str, label: str) -> Path:
    rel = _relative_path(value, label)
    if not any(rel.parts[: len(root.parts)] == root.parts and len(rel.parts) > len(root.parts) for root in DESTINATION_ROOTS):
        raise HandoffError(f"{label} must be below custodian/asset_drop/source_work/ or custodian/asset_drop/inbox/")
    destination = repo.joinpath(*rel.parts)
    resolved = _contained(destination, repo, label)
    allowed = False
    for allowed_root in DESTINATION_ROOTS:
        real_root = repo.joinpath(*allowed_root.parts).resolve(strict=False)
        try:
            resolved.relative_to(real_root)
            allowed = True
            break
        except ValueError:
            continue
    if not allowed:
        raise HandoffError(f"{label} resolves outside the permitted intake roots: {value!r}")
    return resolved


def _manifest(package_root: Path) -> dict:
    manifest_path = _contained(package_root / "MANIFEST.json", package_root, "MANIFEST.json")
    try:
        raw = manifest_path.read_text(encoding="utf-8")
        manifest = json.loads(raw, object_pairs_hook=_object_no_duplicates)
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise HandoffError(f"cannot read MANIFEST.json: {exc}") from exc
    if not isinstance(manifest, dict) or manifest.get("schema") != SCHEMA:
        raise HandoffError(f"MANIFEST.json schema must be {SCHEMA!r}")
    family_id = manifest.get("family_id")
    if not isinstance(family_id, str) or not IDENTIFIER.fullmatch(family_id):
        raise HandoffError("family_id must be a lowercase Asset V2 family identifier")
    assets = manifest.get("assets")
    if not isinstance(assets, list) or not assets:
        raise HandoffError("assets must be a non-empty array")
    return manifest


def _preflight(package_root: Path, repo: Path, manifest: dict) -> tuple[list[dict], list[dict], list[dict]]:
    prepared: list[dict] = []
    family_targets: dict[str, dict] = {}
    seen_states: set[str] = set()
    seen_destinations: dict[Path, str] = {}

    for index, row in enumerate(manifest["assets"]):
        label = f"assets[{index}]"
        if not isinstance(row, dict):
            raise HandoffError(f"{label} must be an object")
        state_id = row.get("state_id")
        if not isinstance(state_id, str) or not IDENTIFIER.fullmatch(state_id):
            raise HandoffError(f"{label} state_id must be a lowercase identifier")
        if state_id in seen_states:
            raise HandoffError(f"duplicate state_id: {state_id}")
        seen_states.add(state_id)
        status = row.get("review_status")
        if status not in STATUSES:
            raise HandoffError(f"{label} review_status must be one of {', '.join(sorted(STATUSES))}")
        install_source, install_inbox = row.get("install_source"), row.get("install_inbox")
        if not isinstance(install_source, bool) or not isinstance(install_inbox, bool):
            raise HandoffError(f"{label} install_source and install_inbox must be booleans")
        if status == "REJECT_REGENERATE" and (install_source or install_inbox):
            raise HandoffError(f"{label} REJECT_REGENERATE cannot install source or inbox files")
        if status == "SOURCE_READY_NEEDS_TUNE" and install_inbox:
            raise HandoffError(f"{label} SOURCE_READY_NEEDS_TUNE cannot install an inbox file")

        source_path, source_data = _package_file(package_root, row.get("package_source"), f"{label} package_source")
        _verify_file(source_data, row, "source", "generated_dimensions", f"{label} source")
        source_dest = _destination(repo, row.get("repo_source_destination"), f"{label} repo_source_destination")
        files = [("source", source_path, source_data, source_dest, install_source)]

        package_inbox, repo_inbox = row.get("package_inbox"), row.get("repo_inbox_destination")
        if (package_inbox is None) != (repo_inbox is None):
            raise HandoffError(f"{label} package_inbox and repo_inbox_destination must be supplied together")
        if install_inbox and package_inbox is None:
            raise HandoffError(f"{label} install_inbox requires package_inbox and repo_inbox_destination")
        if package_inbox is not None:
            inbox_path, inbox_data = _package_file(package_root, package_inbox, f"{label} package_inbox")
            _verify_file(inbox_data, row, "inbox", "normalized_dimensions", f"{label} inbox")
            inbox_dest = _destination(repo, repo_inbox, f"{label} repo_inbox_destination")
            files.append(("inbox", inbox_path, inbox_data, inbox_dest, install_inbox))

        family_targets[manifest["family_id"]] = {
            "family_id": manifest["family_id"],
            "contract": f"custodian/content/metadata/assets/families/{manifest['family_id']}.asset.json",
        }
        for role, package_path, data, destination, install in files:
            existing = None
            if install:
                previous = seen_destinations.get(destination)
                if previous is not None:
                    raise HandoffError(f"multiple package files target {destination}: {previous} and {role}:{state_id}")
                seen_destinations[destination] = f"{role}:{state_id}"
                try:
                    existing = destination.read_bytes() if destination.exists() else None
                except OSError as exc:
                    raise HandoffError(f"cannot inspect destination {destination}: {exc}") from exc
                if existing is not None and existing != data:
                    raise HandoffError(f"destination collision with different bytes: {destination}")
            prepared.append({
                "state_id": state_id,
                "status": status,
                "role": role,
                "source": package_path,
                "destination": destination,
                "data": data,
                "install": install,
                "unchanged": existing is not None,
            })
    return prepared, list(family_targets.values())


def _write_atomically(destination: Path, data: bytes) -> bool:
    destination.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(prefix=f".{destination.name}.", suffix=".tmp", dir=destination.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, 0o644)
        try:
            # A hard-link creates the destination atomically without replacing a
            # file that appeared after preflight (for example, a parallel install).
            os.link(temporary, destination)
        except FileExistsError as exc:
            try:
                same = destination.read_bytes() == data
            except OSError:
                same = False
            if not same:
                raise HandoffError(f"destination collision with different bytes: {destination}") from exc
            return False
        temporary.unlink(missing_ok=True)
        return True
    except BaseException:
        try:
            temporary.unlink(missing_ok=True)
        except OSError:
            pass
        raise


def _receipt(prepared: list[dict], family_targets: list[dict], *, dry_run: bool) -> None:
    copied, unchanged, skipped, would_copy = [], [], [], []
    for item in prepared:
        display = f"{item['state_id']} ({item['role']}): {item['destination']}"
        if not item["install"]:
            skipped.append(display)
        elif item["unchanged"]:
            unchanged.append(display)
        elif dry_run:
            would_copy.append(display)
        else:
            copied.append(display)
    print("Asset handoff " + ("dry run" if dry_run else "installed"))
    for name, values in (("Copied", copied), ("Would copy", would_copy), ("Unchanged", unchanged), ("Skipped", skipped)):
        print(f"{name}:")
        for value in values:
            print(f"  - {value}")
        if not values:
            print("  - none")
    print("Family contract targets:")
    for target in family_targets:
        print(f"  - {target['family_id']}: {target['contract']}")
    print("Next: inspect or update the family contract as needed, then use the current Asset V2 plan/status/doctor/ingest workflow.")
    print("No family contract, runtime asset, generated catalog, consumer binding, or Asset V2 ingest was changed by this installer.")


def install(package_root: Path, repo_arg: str | None, dry_run: bool) -> int:
    manifest = _manifest(package_root)
    repo = _repo_root(repo_arg)
    prepared, family_targets = _preflight(package_root, repo, manifest)
    if not dry_run:
        for item in prepared:
            if item["install"] and not item["unchanged"]:
                if not _write_atomically(item["destination"], item["data"]):
                    item["unchanged"] = True
    _receipt(prepared, family_targets, dry_run=dry_run)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Safely install a custodian.asset_handoff.v1 bundle into a CUSTODIAN checkout.")
    parser.add_argument("--repo", help="CUSTODIAN repository root; defaults to the Git root of the current directory")
    parser.add_argument("--dry-run", action="store_true", help="validate and report planned copies without writing files")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    package_root = Path(__file__).resolve().parent
    try:
        return install(package_root, args.repo, args.dry_run)
    except (HandoffError, OSError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
