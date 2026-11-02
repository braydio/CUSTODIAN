from __future__ import annotations
import json, sys, tempfile, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from tools.export_godot_parity_fixtures import export
from tools.world_parity_contract import sha256

class GodotParityExportTests(unittest.TestCase):
    def test_export_is_deterministic_and_valid(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory); first=root/"a"; second=root/"b"; export(1,[0,1,10,100],first); export(1,[0,1,10,100],second)
            self.assertEqual([(p.name,p.read_bytes()) for p in sorted(first.iterdir())],[(p.name,p.read_bytes()) for p in sorted(second.iterdir())])
            for path in first.iterdir():
                raw=path.read_text(); data=json.loads(raw); self.assertEqual(data["checkpoint_world_tick"],data["projection"]["world_tick"]); self.assertEqual(data["projection_sha256"],sha256(data["projection"])); self.assertEqual(data["projection"]["policies"]["repair_intensity"],3); self.assertNotIn(str(root),raw); self.assertNotIn("timestamp",raw.lower())
    def test_seeds_are_explicitly_distinct(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory); a=json.loads(export(1,[0],root/"a")[0].read_text()); b=json.loads(export(2,[0],root/"b")[0].read_text()); self.assertNotEqual(a["projection"]["seed"],b["projection"]["seed"])

if __name__ == "__main__": unittest.main()
