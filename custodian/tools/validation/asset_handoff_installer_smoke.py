#!/usr/bin/env python3
"""Exercise the copied standalone Asset V2 handoff installer in temp checkouts."""
from __future__ import annotations

import hashlib
import json
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
INSTALLER = ROOT / "tools/assets/asset_handoff_installer.py"


def png(width: int, height: int) -> bytes:
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    pixels = b"\x00" + b"\x10\x20\x30\xff" * width
    raw = pixels * height
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")


SOURCE_BYTES = png(2, 3)
INBOX_BYTES = png(4, 5)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def row(status: str = "RUNTIME_READY", *, install_source: bool = True, install_inbox: bool = True) -> dict:
    return {
        "state_id": "idle",
        "review_status": status,
        "install_source": install_source,
        "package_source": "source/idle_master.png",
        "repo_source_destination": "custodian/asset_drop/source_work/ambient/test_family/idle_master.png",
        "source_sha256": digest(SOURCE_BYTES),
        "source_size_bytes": len(SOURCE_BYTES),
        "generated_dimensions": {"width": 2, "height": 3},
        "install_inbox": install_inbox,
        "package_inbox": "normalized/idle.png",
        "repo_inbox_destination": "custodian/asset_drop/inbox/test_family/idle.png",
        "inbox_sha256": digest(INBOX_BYTES),
        "inbox_size_bytes": len(INBOX_BYTES),
        "normalized_dimensions": {"width": 4, "height": 5},
    }


def make_repo(base: Path, name: str = "repo") -> Path:
    repo = base / name
    (repo / "custodian/tools/assets").mkdir(parents=True)
    (repo / "AGENTS.md").write_text("fixture checkout\n", encoding="utf-8")
    (repo / "custodian/project.godot").write_text("config_version=5\n", encoding="utf-8")
    (repo / "custodian/tools/assets/asset.py").write_text("# fixture marker\n", encoding="utf-8")
    return repo


def make_bundle(base: Path, manifest: dict, *, file_overrides: dict[str, bytes] | None = None) -> Path:
    bundle = base / "bundle"
    bundle.mkdir()
    shutil.copyfile(INSTALLER, bundle / "INSTALL_INTO_REPO.py")
    files = {"source/idle_master.png": SOURCE_BYTES, "normalized/idle.png": INBOX_BYTES}
    files.update(file_overrides or {})
    for relative, data in files.items():
        path = bundle / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    (bundle / "MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return bundle


def case_bundle(base: Path, name: str, manifest: dict, *, file_overrides: dict[str, bytes] | None = None) -> Path:
    case = base / name
    case.mkdir()
    return make_bundle(case, manifest, file_overrides=file_overrides)


def run(bundle: Path, repo: Path, *extra: str, discover: bool = False) -> subprocess.CompletedProcess[str]:
    command = [sys.executable, str(bundle / "INSTALL_INTO_REPO.py")]
    if not discover:
        command.extend(("--repo", str(repo)))
    command.extend(extra)
    return subprocess.run(
        command,
        capture_output=True,
        text=True,
        check=False,
        timeout=10,
        cwd=repo,
    )


def assert_failed_without_new_assets(result: subprocess.CompletedProcess[str], repo: Path) -> None:
    assert result.returncode != 0, result.stdout
    assert "ERROR:" in result.stderr, result.stderr
    for root in (repo / "custodian/asset_drop/source_work", repo / "custodian/asset_drop/inbox"):
        assert not root.exists() or not any(path.is_file() for path in root.rglob("*")), root


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="asset-handoff-smoke-") as temp:
        base = Path(temp)

        # The exact copied file runs without importing the repository and installs both routes.
        repo = make_repo(base / "valid")
        subprocess.run(["git", "init", "--quiet", str(repo)], check=True)
        bundle = case_bundle(base, "valid-bundle", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [row()]})
        first = run(bundle, repo, discover=True)
        assert first.returncode == 0, first.stderr
        source_dest = repo / row()["repo_source_destination"]
        inbox_dest = repo / row()["repo_inbox_destination"]
        assert source_dest.read_bytes() == SOURCE_BYTES and inbox_dest.read_bytes() == INBOX_BYTES
        assert "Copied:" in first.stdout and "test_family.asset.json" in first.stdout and "No family contract" in first.stdout
        source_mtime, inbox_mtime = source_dest.stat().st_mtime_ns, inbox_dest.stat().st_mtime_ns
        second = run(bundle, repo)
        assert second.returncode == 0, second.stderr
        assert "Unchanged:" in second.stdout and source_dest.stat().st_mtime_ns == source_mtime
        assert inbox_dest.stat().st_mtime_ns == inbox_mtime

        # Dry-run validates all inputs but creates no intake paths.
        dry_repo = make_repo(base / "dry-repo")
        dry_bundle = case_bundle(base, "dry-bundle", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [row()]})
        dry = run(dry_bundle, dry_repo, "--dry-run")
        assert dry.returncode == 0, dry.stderr
        assert "Would copy:" in dry.stdout
        assert not (dry_repo / "custodian/asset_drop").exists()

        # Tune-needed keeps the inbox untouched; rejected material is retained only in the bundle.
        tune_repo = make_repo(base / "tune-repo")
        tune_inbox = tune_repo / row()["repo_inbox_destination"]
        tune_inbox.parent.mkdir(parents=True)
        tune_inbox.write_bytes(b"existing inbox sentinel")
        tune_bundle = case_bundle(base, "tune-bundle", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [row("SOURCE_READY_NEEDS_TUNE", install_inbox=False)]})
        tune = run(tune_bundle, tune_repo)
        assert tune.returncode == 0, tune.stderr
        assert (tune_repo / row()["repo_source_destination"]).read_bytes() == SOURCE_BYTES
        assert tune_inbox.read_bytes() == b"existing inbox sentinel"
        assert "Skipped:" in tune.stdout and "inbox" in tune.stdout

        reject_repo = make_repo(base / "reject-repo")
        reject_bundle = case_bundle(base, "reject-bundle", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [row("REJECT_REGENERATE", install_source=False, install_inbox=False)]})
        rejected = run(reject_bundle, reject_repo)
        assert rejected.returncode == 0, rejected.stderr
        assert not (reject_repo / "custodian/asset_drop").exists()
        assert "Skipped:" in rejected.stdout

        # Existing differing destinations fail before any other package file is copied.
        collision_repo = make_repo(base / "collision-repo")
        collision = collision_repo / row()["repo_source_destination"]
        collision.parent.mkdir(parents=True)
        collision.write_bytes(b"do not overwrite")
        collision_bundle = case_bundle(base, "collision-bundle", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [row()]})
        collision_result = run(collision_bundle, collision_repo)
        assert collision_result.returncode != 0 and "destination collision" in collision_result.stderr
        assert collision.read_bytes() == b"do not overwrite"
        assert not (collision_repo / row()["repo_inbox_destination"]).exists()

        invalid_cases = []
        invalid = row()
        invalid["source_sha256"] = "0" * 64
        invalid_cases.append(("hash", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [invalid]}, None))
        invalid = row()
        invalid["source_size_bytes"] += 1
        invalid_cases.append(("size", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [invalid]}, None))
        invalid = row()
        invalid["generated_dimensions"] = {"width": 999, "height": 3}
        invalid_cases.append(("dimensions", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [invalid]}, None))
        malformed_png = row()
        malformed_png_bytes = b"not a png"
        malformed_png["source_sha256"] = digest(malformed_png_bytes)
        malformed_png["source_size_bytes"] = len(malformed_png_bytes)
        invalid_cases.append(("malformed-png", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [malformed_png]}, {"source/idle_master.png": malformed_png_bytes}))
        invalid = row()
        invalid["repo_source_destination"] = "/tmp/escape.png"
        invalid_cases.append(("absolute-destination", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [invalid]}, None))
        invalid = row()
        invalid["repo_inbox_destination"] = "custodian/asset_drop/inbox/../../content/runtime.png"
        invalid_cases.append(("traversal-destination", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [invalid]}, None))
        invalid = row()
        invalid["repo_inbox_destination"] = "custodian/content/runtime.png"
        invalid_cases.append(("runtime-destination", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [invalid]}, None))
        invalid = row("SOURCE_READY_NEEDS_TUNE", install_inbox=True)
        invalid_cases.append(("tune-promotion", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [invalid]}, None))
        invalid = row("REJECT_REGENERATE", install_source=True, install_inbox=False)
        invalid_cases.append(("rejected-install", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [invalid]}, None))
        invalid = row()
        invalid["package_source"] = "../outside.png"
        invalid_cases.append(("package-traversal", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [invalid]}, None))
        invalid = row()
        invalid["package_source"] = "/tmp/outside.png"
        invalid_cases.append(("absolute-package", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [invalid]}, None))

        for name, manifest, overrides in invalid_cases:
            case_base = base / f"invalid-{name}"
            case_base.mkdir()
            case_repo = make_repo(case_base)
            case_path = make_bundle(case_base, manifest, file_overrides=overrides)
            assert_failed_without_new_assets(run(case_path, case_repo), case_repo)

        # Tampered bytes are detected even when a valid-looking manifest remains.
        tamper_base = base / "tampered"
        tamper_base.mkdir()
        tamper_repo = make_repo(tamper_base)
        tamper_bundle = make_bundle(tamper_base, {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [row()]}, file_overrides={"source/idle_master.png": b"tampered"})
        assert_failed_without_new_assets(run(tamper_bundle, tamper_repo), tamper_repo)

        wrong_root = base / "wrong-root"
        wrong_root.mkdir()
        wrong_bundle = case_bundle(base, "wrong-root-bundle", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [row()]})
        wrong = run(wrong_bundle, wrong_root)
        assert wrong.returncode != 0 and "not a CUSTODIAN checkout" in wrong.stderr
        assert not (wrong_root / "custodian/asset_drop").exists()

        # Symlinks that escape either the unpacked bundle or repository are refused.
        symlink_base = base / "symlink-package"
        symlink_base.mkdir()
        symlink_repo = make_repo(symlink_base)
        outside_file = symlink_base / "outside.png"
        outside_file.write_bytes(SOURCE_BYTES)
        symlink_manifest = {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [row()]}
        symlink_bundle = make_bundle(symlink_base, symlink_manifest)
        (symlink_bundle / "source/idle_master.png").unlink()
        (symlink_bundle / "source/idle_master.png").symlink_to(outside_file)
        assert_failed_without_new_assets(run(symlink_bundle, symlink_repo), symlink_repo)

        escape_repo = make_repo(base / "escape-repo")
        outside_dir = base / "outside-dir"
        outside_dir.mkdir()
        symlink_parent = escape_repo / "custodian/asset_drop/source_work/escape"
        symlink_parent.parent.mkdir(parents=True)
        symlink_parent.symlink_to(outside_dir, target_is_directory=True)
        escape_row = row()
        escape_row["repo_source_destination"] = "custodian/asset_drop/source_work/escape/idle.png"
        escape_bundle = case_bundle(base, "escape-bundle", {"schema": "custodian.asset_handoff.v1", "family_id": "test_family", "assets": [escape_row]})
        escape = run(escape_bundle, escape_repo)
        assert escape.returncode != 0 and "outside" in escape.stderr.lower()
        assert not list(outside_dir.iterdir())

    print("PASS: standalone handoff install, dry-run, review gates, checksums/dimensions, conflicts, path safety, and symlink containment")


if __name__ == "__main__":
    main()
