"""Focused offline tests for the read-only Dropbox asset lifecycle audit."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import dropbox_asset_audit as audit


class DropboxAssetAuditTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.project = Path(self.temp.name)
        (self.project / "content/metadata/assets/families").mkdir(parents=True)
        self.registry = {"schema": "custodian.dropbox_asset_upload_index.v1",
                         "updated_utc": "2026-10-07T00:00:00Z",
                         "batches": [{"batch_id": "cliff", "status": "active",
                                      "dropbox_path": "/CUSTODIAN/asset_batches/alpine/cliff",
                                      "zip_name": "cliff.zip", "asset_count": 12,
                                      "family_ids": ["procgen_alpine_cliff_fascia"]}]}
        self.items = [
            {"path": "/CUSTODIAN/asset_batches/alpine/cliff/cliff.zip", "name": "cliff.zip", "bytes": 100},
            {"path": "/CUSTODIAN/asset_batches/ash-bell-ritualant/lift.zip", "name": "lift.zip", "bytes": 250},
            {"path": "/CUSTODIAN/generated_asset_batches/awakening.zip", "name": "awakening.zip", "bytes": 300},
            {"path": "/CUSTODIAN/visual_review/ignore.zip", "name": "ignore.zip", "bytes": 1},
        ]

    def tearDown(self):
        self.temp.cleanup()

    def test_legacy_registry_and_unindexed_uploads(self):
        items = [i for i in self.items if "/visual_review/" not in i["path"]]
        result = audit.reconcile(items, self.registry, self.project, "test-main")
        self.assertEqual(result["coverage"]["zip_count"], 3)
        self.assertEqual(len(result["batches"]), 3)
        self.assertEqual(sum(x["type"] == "unregistered_package" for x in result["findings"]), 2)
        self.assertEqual(result["batches"][0]["review_status"], "unverified_review")
        self.assertIn("Lift", audit.markdown(result).replace("lift", "Lift"))

    def test_source_review_never_inferred_from_active(self):
        result = audit.reconcile(self.items[:1], self.registry, self.project)
        self.assertFalse(result["batches"][0]["receipt_present"])
        self.assertNotEqual(result["batches"][0]["review_status"], "approved")

    def test_pinned_human_receipt(self):
        dest = self.project / audit.REVIEW_FILE
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps({"schema": "custodian.asset_source_reviews.v1",
            "receipts": [{"batch_id": "cliff", "sha256": "a" * 64,
                          "decision": "approved", "reviewed_by": "user",
                          "reviewed_at": "2026-10-13T00:00:00Z",
                          "authoring_chat": "https://chatgpt.com/c/test"}]}))
        self.registry["batches"][0]["zip_sha256"] = "a" * 64
        result = audit.reconcile(self.items[:1], self.registry, self.project)
        self.assertEqual(result["batches"][0]["review_status"], "approved")

    def test_unregistered_package_uses_receipt_only_with_remote_identity_match(self):
        path = "/CUSTODIAN/asset_batches/ash-bell-ritualant/lift.zip"
        content_hash = "dropbox-content-hash"
        receipt_path = self.project / audit.REVIEW_FILE
        receipt_path.parent.mkdir(parents=True, exist_ok=True)
        receipt_path.write_text(json.dumps({"schema": "custodian.asset_source_reviews.v1", "receipts": [{
            "batch_id": "lift-v1", "sha256": "a" * 64, "decision": "approved",
            "reviewed_by": "user", "reviewed_at": "2026-10-13T00:00:00Z",
            "authoring_chat": "https://chatgpt.com/c/test", "dropbox_path": path,
            "dropbox_file_id": "id:lift", "dropbox_content_hash": content_hash,
            "package_size_bytes": 250,
            "sources": [{"family_id": "lift_family", "state_id": "idle"}],
        }]}))
        item = {"path": path, "name": "lift.zip", "bytes": 250, "id": "id:lift",
                "hashes": {"dropbox": content_hash}}
        result = audit.reconcile([item], {}, self.project)
        package = result["batches"][0]
        self.assertEqual(package["review_status"], "approved")
        self.assertTrue(package["receipt_present"])
        self.assertEqual(package["registry_status"], "unregistered")
        self.assertEqual(package["family_ids"], ["lift_family"])
        item["hashes"] = {"dropbox": "different-content"}
        unmatched = audit.reconcile([item], {}, self.project)["batches"][0]
        self.assertEqual(unmatched["review_status"], "awaiting_review")
        self.assertFalse(unmatched["receipt_present"])

    def test_reject_incomplete_or_duplicate_receipts(self):
        dest = self.project / audit.REVIEW_FILE
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps({"schema": "custodian.asset_source_reviews.v1",
                                    "receipts": [{"batch_id": "cliff", "decision": "approved"}]}))
        with self.assertRaises(ValueError):
            audit.reconcile(self.items[:1], self.registry, self.project)

    def test_malformed_path_rejected(self):
        with self.assertRaises(ValueError):
            audit.reconcile([{"path": "/../escape.zip"}], self.registry, self.project)

    def test_remote_scan_offline_fixture_and_no_writes(self):
        path = self.project / "fixture.json"
        path.write_text(json.dumps({"entries": self.items[:2], "registry": self.registry}))
        before = sorted(str(x.relative_to(self.project)) for x in self.project.rglob("*"))
        exit_code = audit.main(["--project-dir", str(self.project), "--fixture", str(path), "scan", "--json"])
        after = sorted(str(x.relative_to(self.project)) for x in self.project.rglob("*"))
        self.assertEqual(exit_code, 0)
        self.assertEqual(before, after)


if __name__ == "__main__":
    unittest.main()
