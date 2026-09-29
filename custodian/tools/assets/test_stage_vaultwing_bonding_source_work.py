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

    def test_rejected_candidate_stays_local_then_clean_replacement_is_accepted(self) -> None:
        spec = stage.SPECS[8]
        rejected = self.make_png("vw8.png", opaque=True)
        accepted, rejected_hash, _reason = stage.preserve_candidate(rejected, spec, 8, apply=True)
        self.assertFalse(accepted)
        self.assertFalse((stage.SOURCE_WORK / "inspect_bait_s_source.png").exists())
        self.assertEqual(stage.sha256(rejected), rejected_hash)
        self.assertTrue(rejected.exists())
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


class DownloadsBatchTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.downloads = self.root / "Downloads"
        self.downloads.mkdir()
        stage.REPO = self.root
        stage.SOURCE_WORK = self.root / "source_work"
        stage.INBOX = self.root / "inbox"
        stage.RUNTIME = self.root / "runtime"
        stage.reference_height = lambda *_args: 220.0

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def make_batch(self) -> None:
        colors = {"east": (220, 80, 50, 255), "north": (50, 200, 80, 255), "south": (50, 80, 220, 255), "west": (220, 200, 50, 255)}
        for direction, filename in stage.BOND_GREET_DOWNLOADS.items():
            image = Image.new("RGBA", (8 * 724, 724), (0, 0, 0, 0))
            color = colors[{"e": "east", "n": "north", "s": "south", "w": "west"}[direction]]
            from PIL import ImageDraw
            draw = ImageDraw.Draw(image)
            for frame in range(8):
                left = frame * 724
                draw.ellipse((left + 300, 250, left + 420, 580), fill=color)
            image.save(self.downloads / filename)

    def test_named_batch_maps_directions_and_stages_all_files(self) -> None:
        self.make_batch()
        report = stage.stage_downloads_batch(self.downloads, dry_run=False)
        self.assertEqual([entry["direction"] for entry in report["requirements"]], ["e", "n", "s", "w"])
        for entry in report["requirements"]:
            with Image.open(self.root / entry["inbox_target"]) as strip:
                self.assertEqual(strip.size, (2048, 256))
            self.assertEqual((self.root / entry["source_work_target"]).is_file(), True)
        self.assertEqual(report["requirements"][1]["local_path"], str(self.downloads / "vw_north_facing.png"))
        repeated = stage.stage_downloads_batch(self.downloads, dry_run=True)
        self.assertEqual({entry["disposition"] for entry in repeated["requirements"]}, {"already_staged"})

    def test_missing_input_fails_before_any_output(self) -> None:
        self.make_batch()
        (self.downloads / "vw_west_facing.png").unlink()
        with self.assertRaises(stage.StageError):
            stage.stage_downloads_batch(self.downloads, dry_run=False)
        self.assertFalse(stage.SOURCE_WORK.exists())
        self.assertFalse(stage.INBOX.exists())

    def test_destination_conflict_fails_before_any_output(self) -> None:
        self.make_batch()
        stage.SOURCE_WORK.mkdir(parents=True)
        (stage.SOURCE_WORK / "bond_greet_n_source.png").write_bytes(b"different accepted source")
        with self.assertRaisesRegex(stage.StageError, "conflicting source master"):
            stage.stage_downloads_batch(self.downloads, dry_run=False)
        self.assertFalse(stage.INBOX.exists())
        self.assertFalse((stage.SOURCE_WORK / "bond_greet_e_source.png").exists())

    def test_bad_frame_seam_fails_before_any_output(self) -> None:
        self.make_batch()
        west = self.downloads / "vw_west_facing.png"
        with Image.open(west) as image:
            broken = image.copy()
        broken.putpixel((723, 350), (255, 255, 255, 255))
        broken.save(west)
        with self.assertRaisesRegex(stage.StageError, "boundaries intersect visible pixels"):
            stage.stage_downloads_batch(self.downloads, dry_run=False)
        self.assertFalse(stage.SOURCE_WORK.exists())
        self.assertFalse(stage.INBOX.exists())

    def test_profile_requires_all_four_unique_files(self) -> None:
        self.make_batch()
        (self.downloads / "vw_west_facing.png").write_bytes((self.downloads / "vw_east_facing.png").read_bytes())
        with self.assertRaisesRegex(stage.StageError, "duplicate source hashes"):
            stage.stage_downloads_batch(self.downloads, dry_run=True)


if __name__ == "__main__":
    unittest.main()
