from __future__ import annotations

import importlib.util
from pathlib import Path
import tempfile
import unittest

from PIL import Image, ImageDraw


SCRIPT = Path(__file__).resolve().parents[1] / "slice_authored_underlay.py"
SPEC = importlib.util.spec_from_file_location("underlay_pipeline", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class PipelineTest(unittest.TestCase):
    def test_exact_core_round_trip(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            godot = repo / "custodian"
            godot.mkdir()
            (godot / "project.godot").write_text(
                '[application]\nconfig/name="pipeline-test"\n',
                encoding="utf-8",
            )

            master = repo / "master.png"
            image = Image.new("RGBA", (530, 410), (0, 0, 0, 0))
            draw = ImageDraw.Draw(image)
            draw.rectangle((0, 0, 260, 409), fill=(20, 50, 90, 255))
            draw.ellipse((240, 100, 529, 409), fill=(180, 90, 30, 220))
            image.save(master)

            args = MODULE.parser().parse_args([
                "--source", str(master),
                "--repo-root", str(repo),
                "--godot-root", str(godot),
                "--asset-id", "test_map",
                "--plate-size", "256",
                "--bleed", "8",
                "--clean",
            ])
            MODULE.apply_defaults(args)
            manifest = MODULE.build(args)

            self.assertEqual(
                manifest["schema"],
                "custodian.authored_underlay_plate_manifest.v1",
            )
            self.assertGreater(manifest["plate_count"], 0)

            manifest_path = (
                godot
                / "content/backgrounds/authored_underlays/test_map"
                / "test_map.plates.json"
            )
            self.assertTrue(manifest_path.exists())
            MODULE.verify_existing(manifest_path, godot, master)

            self.assertTrue(
                (
                    godot
                    / "game/world/presentation/generated"
                    / "test_map_underlay_runtime.tscn"
                ).exists()
            )
            self.assertTrue(
                (
                    godot
                    / "scenes/debug/generated"
                    / "test_map_underlay_preview.tscn"
                ).exists()
            )


if __name__ == "__main__":
    unittest.main()
