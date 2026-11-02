#!/usr/bin/env python3
"""Focused security and transport tests for implementation_handoff.py."""

from __future__ import annotations

import contextlib
import hashlib
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).with_name("implementation_handoff.py")
SPEC = importlib.util.spec_from_file_location("custodian_implementation_handoff_tests", SCRIPT)
handoff = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = handoff
SPEC.loader.exec_module(handoff)


class ImplementationHandoffTest(unittest.TestCase):
    def setUp(self) -> None:
        self.png = b"deterministic png bytes"
        self.zip = b"opaque deterministic zip bytes"
        self.files = {"payload/art/test.png": self.png, "payload/source/test.zip": self.zip}
        self.manifest = {
            "schema": handoff.SCHEMA,
            "workstream": "sample-workstream",
            "handoff_id": "test-handoff-01",
            "created_at_utc": "2026-10-05T12:00:00Z",
            "authoring_chat": "not-recorded",
            "payloads": [
                self.record(path, data, purpose="fixture")
                for path, data in self.files.items()
            ],
        }
        self.stdout = io.StringIO()

    @staticmethod
    def record(path: str, data: bytes, *, purpose: str, **changes: object) -> dict[str, object]:
        result: dict[str, object] = {
            "path": path,
            "size_bytes": len(data),
            "sha256": hashlib.sha256(data).hexdigest(),
            "purpose": purpose,
        }
        result.update(changes)
        return result

    def mock_runner(self, *, extra: dict[str, bytes] | None = None, omit: set[str] | None = None):
        raw_manifest = json.dumps(self.manifest, separators=(",", ":")).encode("utf-8")
        remote_files = {**self.files, **(extra or {})}
        listed = {"HANDOFF_MANIFEST.json": raw_manifest, **remote_files}
        for path in omit or set():
            listed.pop(path, None)

        def run(args: list[str], *, check: bool = True, capture_output: bool = True):
            if args[1] == "cat":
                return subprocess.CompletedProcess(args, 0, raw_manifest.decode("utf-8"), "")
            if args[1] == "lsjson":
                if "--stat" in args:
                    return subprocess.CompletedProcess(
                        args,
                        0,
                        json.dumps({"Path": "HANDOFF_MANIFEST.json", "Size": len(raw_manifest), "IsDir": False}),
                        "",
                    )
                rows = [
                    {"Path": path, "Name": Path(path).name, "Size": len(data), "IsDir": False}
                    for path, data in listed.items()
                ]
                return subprocess.CompletedProcess(args, 0, json.dumps(rows), "")
            if args[1] == "copyto":
                source, destination = args[2], Path(args[3])
                # Preserve nested remote paths after the handoff identity.
                marker = "/test-handoff-01/"
                relative = source.split(marker, 1)[1]
                if relative not in remote_files:
                    raise AssertionError(f"unexpected copy source: {source}")
                destination.write_bytes(remote_files[relative])
                return subprocess.CompletedProcess(args, 0, "", "")
            raise AssertionError(f"unexpected rclone command: {args}")

        return run

    def fetch_with(self, runner, *, staging_root: Path, repo_root: Path, max_bytes: int = 1024) -> int:
        with patch.object(handoff, "_run", side_effect=runner), contextlib.redirect_stdout(self.stdout):
            return handoff.fetch(
                "git-dropbox-sync:",
                "sample-workstream",
                "test-handoff-01",
                staging_root=staging_root,
                max_bytes=max_bytes,
                repo_root=repo_root,
            )

    def test_validate_manifest_accepts_png_and_zip_records(self) -> None:
        payloads = handoff.validate_manifest(
            self.manifest,
            expected_workstream="sample-workstream",
            expected_handoff_id="test-handoff-01",
            max_bytes=1024,
        )
        self.assertEqual([row["path"] for row in payloads], list(self.files))

    def test_inbound_remote_environment_precedence_preserves_legacy_review_setting(self) -> None:
        self.assertEqual(
            handoff._resolve_remote(
                None,
                {
                    "CUSTODIAN_IMPLEMENTATION_REMOTE": "implementation-dropbox",
                    "CUSTODIAN_REVIEW_REMOTE": "legacy-dropbox",
                },
            ),
            "implementation-dropbox:",
        )
        self.assertEqual(
            handoff._resolve_remote(None, {"CUSTODIAN_REVIEW_REMOTE": "legacy-dropbox"}),
            "legacy-dropbox:",
        )

    def test_validate_manifest_rejects_bad_schema_and_identity(self) -> None:
        for key, value in (("schema", "other.v1"), ("workstream", "other-workstream"), ("handoff_id", "other")):
            with self.subTest(key=key):
                changed = json.loads(json.dumps(self.manifest))
                changed[key] = value
                with self.assertRaises(ValueError):
                    handoff.validate_manifest(
                        changed,
                        expected_workstream="sample-workstream",
                        expected_handoff_id="test-handoff-01",
                        max_bytes=1024,
                    )

    def test_validate_manifest_rejects_absolute_traversal_and_duplicate_paths(self) -> None:
        for paths in (
            ["/payload/escape.png"],
            ["payload/../escape.png"],
            ["payload/a.png", "payload/a.png"],
            ["payload/tree", "payload/tree/file.png"],
        ):
            with self.subTest(paths=paths):
                changed = json.loads(json.dumps(self.manifest))
                changed["payloads"] = [
                    self.record(path, self.png, purpose="fixture") for path in paths
                ]
                with self.assertRaises(ValueError):
                    handoff.validate_manifest(
                        changed,
                        expected_workstream="sample-workstream",
                        expected_handoff_id="test-handoff-01",
                        max_bytes=1024,
                    )

    def test_validate_manifest_rejects_malformed_hash_size_and_limit(self) -> None:
        cases = (
            ("sha256", "A" * 64, 1024),
            ("sha256", "not-a-hash", 1024),
            ("size_bytes", True, 1024),
            ("size_bytes", -1, 1024),
            ("size_bytes", 1.5, 1024),
            ("size_bytes", len(self.png), len(self.png) - 1),
        )
        for key, value, limit in cases:
            with self.subTest(key=key, value=value, limit=limit):
                changed = json.loads(json.dumps(self.manifest))
                changed["payloads"][0][key] = value
                with self.assertRaises(ValueError):
                    handoff.validate_manifest(
                        changed,
                        expected_workstream="sample-workstream",
                        expected_handoff_id="test-handoff-01",
                        max_bytes=limit,
                    )

    def test_fetch_verifies_and_atomically_exposes_png_and_opaque_zip(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            staging = root / "cache"
            repo = root / "repo"
            repo.mkdir()
            result = self.fetch_with(self.mock_runner(), staging_root=staging, repo_root=repo)
            final = staging / "sample-workstream" / "test-handoff-01"
            self.assertEqual(result, 0)
            self.assertEqual((final / "payload/art/test.png").read_bytes(), self.png)
            self.assertEqual((final / "payload/source/test.zip").read_bytes(), self.zip)
            self.assertTrue((final / "HANDOFF_MANIFEST.json").is_file())
            self.assertFalse((final / "payload/source/test").exists())
            self.assertIn("CUSTODIAN_IMPLEMENTATION_HANDOFF_JSON:", self.stdout.getvalue())

    def test_fetch_rejects_extra_and_missing_remote_files_without_final_directory(self) -> None:
        for name, runner in (
            ("extra", self.mock_runner(extra={"payload/unlisted.bin": b"extra"})),
            ("missing", self.mock_runner(omit={"payload/source/test.zip"})),
        ):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                staging = root / "cache"
                repo = root / "repo"
                repo.mkdir()
                self.assertNotEqual(self.fetch_with(runner, staging_root=staging, repo_root=repo), 0)
                self.assertFalse((staging / "sample-workstream" / "test-handoff-01").exists())

    def test_fetch_rejects_listed_size_mismatch_before_download(self) -> None:
        base = self.mock_runner()
        copied: list[str] = []

        def run(args: list[str], **kwargs):
            result = base(args, **kwargs)
            if args[1] == "lsjson" and "--recursive" in args:
                rows = json.loads(result.stdout)
                next(row for row in rows if row["Path"] == "payload/art/test.png")["Size"] += 1
                result.stdout = json.dumps(rows)
            if args[1] == "copyto":
                copied.append(args[2])
            return result

        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            staging = root / "cache"
            repo = root / "repo"
            repo.mkdir()
            self.assertNotEqual(self.fetch_with(run, staging_root=staging, repo_root=repo), 0)
            self.assertEqual(copied, [])
            self.assertFalse((staging / "sample-workstream" / "test-handoff-01").exists())

    def test_fetch_rejects_oversized_manifest_before_reading_it(self) -> None:
        raw = json.dumps(self.manifest, separators=(",", ":"))
        cat_called = False

        def run(args: list[str], **kwargs):
            nonlocal cat_called
            if args[1] == "lsjson" and "--stat" in args:
                return subprocess.CompletedProcess(
                    args,
                    0,
                    json.dumps({"Path": "HANDOFF_MANIFEST.json", "Size": handoff.MAX_MANIFEST_BYTES + 1}),
                    "",
                )
            if args[1] == "cat":
                cat_called = True
                return subprocess.CompletedProcess(args, 0, raw, "")
            raise AssertionError(f"unexpected command after oversized manifest: {args}")

        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            staging = root / "cache"
            repo = root / "repo"
            repo.mkdir()
            self.assertNotEqual(self.fetch_with(run, staging_root=staging, repo_root=repo), 0)
            self.assertFalse(cat_called)
            self.assertFalse((staging / "sample-workstream" / "test-handoff-01").exists())

    def test_fetch_rejects_corrupt_payload_without_final_directory(self) -> None:
        self.manifest["payloads"][0]["sha256"] = "0" * 64
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            staging = root / "cache"
            repo = root / "repo"
            repo.mkdir()
            self.assertNotEqual(self.fetch_with(self.mock_runner(), staging_root=staging, repo_root=repo), 0)
            self.assertFalse((staging / "sample-workstream" / "test-handoff-01").exists())

    def test_fetch_rejects_existing_or_in_checkout_staging_destination(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            repo = root / "repo"
            repo.mkdir()
            existing = root / "cache" / "sample-workstream" / "test-handoff-01"
            existing.mkdir(parents=True)
            self.assertNotEqual(
                self.fetch_with(self.mock_runner(), staging_root=existing.parents[1], repo_root=repo), 0
            )
            self.assertTrue(existing.is_dir())
            inside_repo = repo / ".ai" / "implementation_inputs"
            self.assertNotEqual(
                self.fetch_with(self.mock_runner(), staging_root=inside_repo, repo_root=repo), 0
            )
            self.assertFalse(inside_repo.exists())

    def test_prepare_refuses_existing_handoff_folder(self) -> None:
        calls: list[list[str]] = []

        def run(args: list[str], **kwargs):
            calls.append(args)
            if args[1] == "lsjson":
                return subprocess.CompletedProcess(
                    args,
                    0,
                    json.dumps([{"Path": "test-handoff-01", "Name": "test-handoff-01", "IsDir": True}]),
                    "",
                )
            return subprocess.CompletedProcess(args, 0, "", "")

        with patch.object(handoff, "_run", side_effect=run), contextlib.redirect_stdout(self.stdout):
            result = handoff.prepare("git-dropbox-sync:", "sample-workstream", "test-handoff-01")
        self.assertEqual(result, 3)
        self.assertFalse(any(args[1] == "mkdir" and args[2].endswith("/payload") for args in calls))


if __name__ == "__main__":
    unittest.main()
