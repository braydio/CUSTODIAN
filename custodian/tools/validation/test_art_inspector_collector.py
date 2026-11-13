#!/usr/bin/env python3
"""Unit tests for the read-only ArtInspector collector."""
from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "custodian/tools/art/collect_art_flags.py"
SPEC = importlib.util.spec_from_file_location("collect_art_flags", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
collector = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(collector)


class ArtInspectorCollectorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.geometry = json.loads(collector.GEOMETRY.read_text(encoding="utf-8"))

    def test_known_gardens_landmark_walkable(self) -> None:
        flag = {"world_position": [-1376, -3296]}
        data = collector._describe(flag, self.geometry)
        self.assertEqual(data["region"], "Gardens")
        self.assertEqual(data["mask"], "walkable")
        self.assertTrue(data["nearest_landmark"].startswith("L01:"))

    def test_outside_gardens_unclassified(self) -> None:
        data = collector._describe({"world_position": [3000, 3000]}, self.geometry)
        self.assertEqual(data["region"], "unclassified")
        self.assertEqual(data["mask"], "outside_envelope")

    def test_polygon(self) -> None:
        square = [[0, 0], [10, 0], [10, 10], [0, 10]]
        self.assertTrue(collector._inside_polygon((5, 5), square))
        self.assertFalse(collector._inside_polygon((50, 50), square))

    def test_grouping_and_invalid_records(self) -> None:
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            for i, x in enumerate([-1376, -1350]):
                (root / f"flag{i}.json").write_text(json.dumps({
                    "schema": collector.SCHEMA,
                    "id": f"flag{i}",
                    "scene_path": "res://game/world/hub/first_set/hub_first_set_map.tscn",
                    "world_position": [x, -3296],
                }), encoding="utf-8")
            (root / "broken.json").write_text("{broken", encoding="utf-8")
            flags, problems = collector.collect(root, self.geometry)
            summary = collector.summarize(flags, problems)
            self.assertEqual(summary["flags"], 2)
            self.assertEqual(len(summary["stretches"]), 1)
            self.assertEqual(summary["stretches"][0]["flag_count"], 2)
            self.assertEqual(len(summary["problems"]), 1)
            self.assertIn("read_only", summary["policy"])
            self.assertIn("flag0", collector.markdown(summary))


if __name__ == "__main__":
    unittest.main()
