#!/usr/bin/env python3
"""Focused unit coverage for publish_review_artifacts.py."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from custodian.tools.iteration.publish_review_artifacts import (
    _sample_evenly,
    _slug,
    discover_artifacts,
    resolve_remote,
)


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


if __name__ == "__main__":
    unittest.main()
