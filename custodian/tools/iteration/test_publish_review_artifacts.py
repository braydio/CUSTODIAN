#!/usr/bin/env python3
"""Focused unit coverage for publish_review_artifacts.py."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).with_name("publish_review_artifacts.py")
SPEC = importlib.util.spec_from_file_location("custodian_publish_review_artifacts_tests", SCRIPT)
publisher = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = publisher
SPEC.loader.exec_module(publisher)

_sample_evenly = publisher._sample_evenly
_slug = publisher._slug
discover_artifacts = publisher.discover_artifacts
resolve_remote = publisher.resolve_remote
cleanup_reviewed = publisher.cleanup_reviewed
_packet_authoring_chat = publisher._packet_authoring_chat


class PublishReviewArtifactsTest(unittest.TestCase):
    def test_slug_requires_kebab_case(self) -> None:
        self.assertEqual(_slug("awakening-detail-assets"), "awakening-detail-assets")
        with self.assertRaises(ValueError):
            _slug("Awakening Detail Assets")

    def test_sample_evenly_caps_keyframes(self) -> None:
        paths = [Path(f"tick_{index:03d}.png") for index in range(10)]
        sampled = _sample_evenly(paths, 4)
        self.assertEqual(len(sampled), 4)
        self.assertEqual(sampled[0], paths[0])
        self.assertEqual(sampled[-1], paths[-1])

    def test_discover_prefers_compact_surfaces_and_sparse_keyframes(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "keyframes").mkdir()
            (root / "review_contact_sheet.png").write_bytes(b"sheet")
            (root / "metrics.json").write_text("{}", encoding="utf-8")
            for index in range(9):
                (root / "keyframes" / f"tick_{index:06d}.png").write_bytes(
                    f"frame-{index}".encode("utf-8")
                )

            found = discover_artifacts(root, max_keyframes=3)
            names = [path.name for path in found]

            self.assertIn("review_contact_sheet.png", names)
            self.assertIn("metrics.json", names)
            self.assertEqual(
                len([name for name in names if name.startswith("tick_")]),
                3,
            )

    def test_resolve_remote_prefers_explicit_then_environment(self) -> None:
        self.assertEqual(
            resolve_remote("custodian-dropbox", env={}),
            "custodian-dropbox:",
        )
        self.assertEqual(
            resolve_remote(None, env={"CUSTODIAN_REVIEW_REMOTE": "mydropbox"}),
            "mydropbox:",
        )

    def test_auto_detects_one_dropbox_named_remote(self) -> None:
        fake = subprocess.CompletedProcess(
            ["rclone", "listremotes"],
            0,
            stdout="mcgdrive:\nbraydenpc:\ngit-dropbox-sync:\ngit-gdrive-sync:\n",
            stderr="",
        )
        with patch.object(publisher, "_run", return_value=fake):
            self.assertEqual(resolve_remote(None, env={}), "git-dropbox-sync:")

    def test_multiple_dropbox_named_remotes_require_explicit_choice(self) -> None:
        fake = subprocess.CompletedProcess(
            ["rclone", "listremotes"],
            0,
            stdout="dropbox-home:\ndropbox-work:\n",
            stderr="",
        )
        with patch.object(publisher, "_run", return_value=fake):
            with self.assertRaises(RuntimeError):
                resolve_remote(None, env={})


    def test_packet_authoring_chat_resolves_exact_workstream_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            root = repo / "custodian/docs/ai_context/task_packets"
            root.mkdir(parents=True)
            (root / "SAMPLE.md").write_text(
                "# P\n\n"
                "- Workstream: `sample-work`\n"
                "- Status: `ready`\n"
                "- Authoring chat: `https://chatgpt.com/c/sample-authoring`\n",
                encoding="utf-8",
            )
            self.assertEqual(
                _packet_authoring_chat(repo, "sample-work"),
                "https://chatgpt.com/c/sample-authoring",
            )
            self.assertEqual(_packet_authoring_chat(repo, "other-work"), "not-recorded")

    def test_cleanup_reviewed_purges_exact_v2_run_and_matching_latest(self) -> None:
        manifest = {
            "schema": publisher.VISUAL_REVIEW_SCHEMA,
            "workstream": "sample-work",
            "run_id": "run-1",
            "retention": {"policy": publisher.DELETE_AFTER_REVIEW, "cleanup_owner": "execution-agent"},
        }
        latest = {
            "schema": publisher.LATEST_SCHEMA,
            "workstream": "sample-work",
            "run_id": "run-1",
        }
        calls: list[list[str]] = []

        def fake_run(args, check=True, capture_output=True):
            calls.append(args)
            joined = " ".join(args)
            if args[:2] == ["rclone", "cat"] and args[-1].endswith("/run-1/REVIEW_MANIFEST.json"):
                return subprocess.CompletedProcess(args, 0, stdout=__import__("json").dumps(manifest), stderr="")
            if args[:2] == ["rclone", "purge"]:
                return subprocess.CompletedProcess(args, 0, stdout="", stderr="")
            if args[:2] == ["rclone", "lsf"]:
                return subprocess.CompletedProcess(args, 1, stdout="", stderr="missing")
            if args[:2] == ["rclone", "cat"] and args[-1].endswith("/LATEST.json"):
                return subprocess.CompletedProcess(args, 0, stdout=__import__("json").dumps(latest), stderr="")
            if args[:2] == ["rclone", "deletefile"]:
                return subprocess.CompletedProcess(args, 0, stdout="", stderr="")
            raise AssertionError(joined)

        with patch.object(publisher, "_run", side_effect=fake_run):
            self.assertEqual(cleanup_reviewed("dropbox:", publisher.DEFAULT_REMOTE_ROOT, "sample-work", "run-1"), 0)

        self.assertTrue(any(args[:2] == ["rclone", "purge"] and args[-1].endswith("/sample-work/run-1") for args in calls))
        self.assertTrue(any(args[:2] == ["rclone", "deletefile"] and args[-1].endswith("/sample-work/LATEST.json") for args in calls))

    def test_cleanup_reviewed_preserves_newer_latest_pointer(self) -> None:
        manifest = {
            "schema": publisher.VISUAL_REVIEW_SCHEMA,
            "workstream": "sample-work",
            "run_id": "run-1",
            "retention": {"policy": publisher.DELETE_AFTER_REVIEW, "cleanup_owner": "execution-agent"},
        }
        latest = {
            "schema": publisher.LATEST_SCHEMA,
            "workstream": "sample-work",
            "run_id": "run-2",
        }
        calls: list[list[str]] = []

        def fake_run(args, check=True, capture_output=True):
            calls.append(args)
            if args[:2] == ["rclone", "cat"] and args[-1].endswith("/run-1/REVIEW_MANIFEST.json"):
                return subprocess.CompletedProcess(args, 0, stdout=__import__("json").dumps(manifest), stderr="")
            if args[:2] == ["rclone", "purge"]:
                return subprocess.CompletedProcess(args, 0, stdout="", stderr="")
            if args[:2] == ["rclone", "lsf"]:
                return subprocess.CompletedProcess(args, 1, stdout="", stderr="missing")
            if args[:2] == ["rclone", "cat"] and args[-1].endswith("/LATEST.json"):
                return subprocess.CompletedProcess(args, 0, stdout=__import__("json").dumps(latest), stderr="")
            raise AssertionError(" ".join(args))

        with patch.object(publisher, "_run", side_effect=fake_run):
            self.assertEqual(cleanup_reviewed("dropbox:", publisher.DEFAULT_REMOTE_ROOT, "sample-work", "run-1"), 0)

        self.assertFalse(any(args[:2] == ["rclone", "deletefile"] for args in calls))

    def test_cleanup_reviewed_refuses_retained_or_legacy_evidence(self) -> None:
        retained = {
            "schema": publisher.VISUAL_REVIEW_SCHEMA,
            "workstream": "sample-work",
            "run_id": "run-1",
            "retention": {"policy": publisher.RETAIN_AFTER_REVIEW, "cleanup_owner": "execution-agent"},
        }
        legacy = {
            "schema": "custodian.visual_review_handoff.v1",
            "workstream": "sample-work",
            "run_id": "run-1",
        }
        for manifest, expected in ((retained, 4), (legacy, 3)):
            with self.subTest(schema=manifest["schema"], retention=manifest.get("retention")):
                def fake_run(args, check=True, capture_output=True, manifest=manifest):
                    if args[:2] == ["rclone", "cat"]:
                        return subprocess.CompletedProcess(args, 0, stdout=__import__("json").dumps(manifest), stderr="")
                    raise AssertionError("cleanup mutated retained/legacy evidence")
                with patch.object(publisher, "_run", side_effect=fake_run):
                    self.assertEqual(
                        cleanup_reviewed("dropbox:", publisher.DEFAULT_REMOTE_ROOT, "sample-work", "run-1"),
                        expected,
                    )

    def test_cleanup_reviewed_is_idempotent_when_run_is_absent(self) -> None:
        def fake_run(args, check=True, capture_output=True):
            if args[:2] == ["rclone", "cat"]:
                return subprocess.CompletedProcess(args, 1, stdout="", stderr="missing")
            if args[:2] == ["rclone", "lsf"]:
                return subprocess.CompletedProcess(args, 1, stdout="", stderr="missing")
            raise AssertionError(" ".join(args))

        with patch.object(publisher, "_run", side_effect=fake_run):
            self.assertEqual(cleanup_reviewed("dropbox:", publisher.DEFAULT_REMOTE_ROOT, "sample-work", "run-1"), 0)

    def test_opt_in_skip_does_not_require_rclone_or_existing_source(self) -> None:
        self.assertEqual(
            publisher.main([
                "--workstream",
                "visual-review-test",
                "--source",
                "definitely-does-not-exist",
            ]),
            0,
        )


if __name__ == "__main__":
    unittest.main()
