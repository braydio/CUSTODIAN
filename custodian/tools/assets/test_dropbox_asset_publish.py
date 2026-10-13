"""Publication is opt-in, append-receipt-first and never changes source batches."""
import json
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import dropbox_asset_publish as publish


class PublishTests(unittest.TestCase):
    def setUp(self):
        self.snapshot = {
            "schema": "custodian.dropbox_asset_lifecycle.v1",
            "coverage": {"complete": True, "zip_count": 2},
            "repository_revision": "abcd",
            "batches": [], "findings": [], "families": {}, "requirements": {}
        }

    def test_dry_run_never_invokes_remote(self):
        seen = []
        result = publish.publish(self.snapshot, "dropbox:", "CUSTODIAN", apply=False,
                                 run_id="20261013T000000Z", runner=lambda c: seen.append(c))
        self.assertFalse(result["applied"])
        self.assertEqual(seen, [])
        self.assertIn("audit-runs", result["immutable_run"])

    def test_publishes_immutable_evidence_before_latest(self):
        seen = []
        result = publish.publish(self.snapshot, "dropbox:", "CUSTODIAN", apply=True,
                                 run_id="20261013T000000Z", runner=lambda c: seen.append(c))
        self.assertTrue(result["applied"])
        self.assertEqual(len(seen), 5)
        self.assertEqual(seen[0][:2], ["rclone", "mkdir"])
        self.assertEqual(seen[1][2], "--immutable")
        self.assertEqual(seen[2][2], "--immutable")
        self.assertTrue(seen[3][-1].endswith("/INDEX.json"))
        self.assertTrue(seen[4][-1].endswith("/INDEX.md"))
        self.assertTrue(all("/asset_batches/_registry/lifecycle" in c[-1] for c in seen))

    def test_unverified_coverage_never_published(self):
        snapshot = dict(self.snapshot, coverage={"complete": False})
        with self.assertRaisesRegex(ValueError, "incomplete"):
            publish.publish(snapshot, "dropbox:", "CUSTODIAN", apply=True, runner=lambda _: None)

    def test_bad_root_rejected(self):
        with self.assertRaisesRegex(ValueError, "invalid Dropbox root"):
            publish.publish(self.snapshot, "dropbox:", "../elsewhere", apply=True, runner=lambda _: None)


if __name__ == "__main__":
    unittest.main()
