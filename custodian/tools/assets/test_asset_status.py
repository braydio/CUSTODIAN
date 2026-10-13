"""Source-only reviewed art must remain visibly pending in Asset V2 status."""
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from asset_contract import parse_family
from asset_status import get_family_status


class SourceOnlyStatusTests(unittest.TestCase):
    def test_hash_pinned_source_only_state_is_pending(self):
        with tempfile.TemporaryDirectory() as raw:
            project = Path(raw)
            source = project / "asset_drop/source_work/ash_bell/family/arming_source.png"
            source.parent.mkdir(parents=True)
            source.write_bytes(b"approved source work")
            digest = hashlib.sha256(source.read_bytes()).hexdigest()
            receipt = {
                "schema": "custodian.asset_source_reviews.v1",
                "receipts": [{"decision": "approved", "sources": [{
                    "family_id": "family", "state_id": "arming",
                    "state_decision": "approved_source_work_only",
                    "entry": "custodian/asset_drop/source_work/ash_bell/family/arming_source.png",
                    "sha256": digest,
                }]}],
            }
            receipt_path = project / "content/metadata/assets/source_review_receipts.v1.json"
            receipt_path.parent.mkdir(parents=True)
            receipt_path.write_text(json.dumps(receipt), encoding="utf-8")
            catalog = project / "content/metadata/assets/generated/asset_catalog.generated.json"
            catalog.parent.mkdir(parents=True)
            catalog.write_text('{"schema":"custodian.asset_catalog.v2","families":{}}', encoding="utf-8")
            family = parse_family({
                "schema": "custodian.asset_family.v2", "id": "family", "kind": "effect",
                "runtime": {"domain": "sprites/effects/test", "owner": "family"},
                "canvas": {"width": 512, "height": 192}, "direction_policy": "omni",
                "states": {"arming": {"required": True, "layer": "fx", "action_group": "effect",
                    "variant": "arming", "layout": "horizontal_strip", "animation": True,
                    "frames": 8, "fps": 12}},
            })
            self.assertTrue(get_family_status(family, project).states["arming"].source_pending)
            source.write_bytes(b"different source bytes")
            self.assertFalse(get_family_status(family, project).states["arming"].source_pending)


if __name__ == "__main__":
    unittest.main()
