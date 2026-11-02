"""The Awakening inbox stager must not overwrite a global status manifest."""
from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image

SCRIPT = Path(__file__).resolve().parents[1] / "art" / "stage_awakening_inbox.py"
SPEC = importlib.util.spec_from_file_location("awakening_staging_receipt", SCRIPT)
stager = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = stager
SPEC.loader.exec_module(stager)


class AwakeningStagingReceiptTests(unittest.TestCase):
    def test_stage_receipt_is_scoped_to_family_and_preserves_global_name(self) -> None:
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            ready = root / "ready" / "awakening_test_family"
            ready.mkdir(parents=True)
            Image.new("RGBA", (2, 2), (12, 24, 36, 255)).save(ready / "idle.png")
            (root / "content/metadata/assets/families").mkdir(parents=True)
            contract_path = root / "content/metadata/assets/families/awakening_test_family.asset.json"
            contract_path.write_text(json.dumps({
                "states": {"idle": {"frame_width": 2, "frame_height": 2}}
            }))
            inbox = root / "inbox"
            inbox.mkdir()
            global_manifest = inbox / "awakening_ingest_manifest.json"
            global_manifest.write_text('{"preserve": true}\n')

            with patch.object(stager, "ROOT", root), patch.object(stager, "READY", root / "ready"), \
                    patch.object(stager, "INBOX", inbox), patch.object(
                        sys, "argv", [str(SCRIPT), "--family", "awakening_test_family"]
                    ):
                self.assertEqual(stager.main(), 0)

            receipt = inbox / "awakening_test_family/awakening_staging_manifest.json"
            self.assertTrue(receipt.is_file())
            self.assertEqual(json.loads(receipt.read_text())["schema"], "custodian.awakening_staging.v1")
            self.assertEqual(global_manifest.read_text(), '{"preserve": true}\n')
            self.assertTrue((inbox / "awakening_test_family/idle.png").is_file())


if __name__ == "__main__":
    unittest.main()
