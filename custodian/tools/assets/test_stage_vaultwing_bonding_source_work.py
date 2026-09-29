"""Focused lifecycle regressions for Vaultwing bonding source staging."""
from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image


SCRIPT = Path(__file__).with_name("stage_vaultwing_bonding_source_work.py")
SPEC = importlib.util.spec_from_file_location("vaultwing_stage", SCRIPT)
stage = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
sys.modules[SPEC.name] = stage
SPEC.loader.exec_module(stage)


class SourceLifecycleTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        stage.REPO = self.root
        stage.SOURCE_WORK = self.root / "source_work"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def make_png(self, name: str, opaque: bool) -> Path:
        path = self.root / name
        image = Image.new("RGBA", (32, 32), (40, 20, 10, 255) if opaque else (0, 0, 0, 0))
        image.save(path)
        return path

    def test_rejected_never_enters_source_work_then_clean_replacement_accepted(self) -> None:
        spec = stage.SPECS[8]
        rejected = self.make_png("vw8.png", opaque=True)
        accepted, _rejected_hash, _reason = stage.preserve_candidate(rejected, spec, 8, apply=True)
        self.assertFalse(accepted)
        self.assertFalse((stage.SOURCE_WORK / "inspect_bait_s_source.png").exists())
        self.assertFalse((self.root / "unresolved").exists())

        replacement = self.make_png("replacement.png", opaque=False)
        accepted, accepted_hash, reason = stage.preserve_candidate(replacement, spec, 8, apply=True)
        self.assertTrue(accepted, reason)
        canonical = stage.SOURCE_WORK / "inspect_bait_s_source.png"
        self.assertEqual(stage.sha256(canonical), accepted_hash)

    def test_different_accepted_master_is_never_overwritten(self) -> None:
        spec = stage.SPECS[8]
        original = self.make_png("first.png", opaque=False)
        stage.preserve_candidate(original, spec, 8, apply=True)
        replacement = self.make_png("second.png", opaque=False)
        replacement_image = Image.open(replacement).convert("RGBA")
        replacement_image.putpixel((4, 4), (10, 20, 30, 255))
        replacement_image.save(replacement)
        with self.assertRaises(stage.StageError):
            stage.preserve_candidate(replacement, spec, 8, apply=True)

    def test_identical_and_ambiguous_numbered_forms(self) -> None:
        compact = self.make_png("vw8.png", opaque=False)
        underscored = self.root / "vw_8.png"
        underscored.write_bytes(compact.read_bytes())
        found, ambiguous, messages = stage.find_sources([8])
        self.assertEqual(found[8], compact)
        self.assertFalse(ambiguous)
        self.assertTrue(any("DUPLICATE-IDENTICAL" in item for item in messages))

        self.make_png("vw_8.png", opaque=True)
        found, ambiguous, _messages = stage.find_sources([8])
        self.assertNotIn(8, found)
        self.assertEqual(ambiguous, {8})

    def test_explicit_source_map_resolves_paths_relative_to_repo(self) -> None:
        source = self.make_png("vw11.png", opaque=False)
        mapped = stage.parse_source_map(["8=vw11.png"], repo=self.root)
        self.assertEqual(mapped, {8: source.resolve()})

    def test_explicit_source_map_rejects_bad_duplicate_and_missing_entries(self) -> None:
        source = self.make_png("vw11.png", opaque=False)
        cases = [
            (["nope=vw11.png"], "invalid --source-map ordinal"),
            (["19=vw11.png"], "ordinal must be from 1 through 18"),
            (["8=vw11.png", "8=vw11.png"], "duplicate --source-map ordinal"),
            (["8=vw11.png", "9=vw11.png"], "duplicate --source-map path"),
            (["8=missing.png"], "does not exist"),
            (["8="], "expected ORDINAL=PATH"),
        ]
        for entries, expected in cases:
            with self.subTest(entries=entries), self.assertRaisesRegex(stage.StageError, expected):
                stage.parse_source_map(entries, repo=self.root)

    def test_numbered_discovery_remains_available(self) -> None:
        source = self.make_png("vw8.png", opaque=False)
        found, ambiguous, _messages = stage.find_sources([8])
        self.assertEqual(found, {8: source})
        self.assertFalse(ambiguous)


if __name__ == "__main__":
    unittest.main()
