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
