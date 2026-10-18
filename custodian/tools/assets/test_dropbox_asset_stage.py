"""Offline source-staging boundary tests; no Dropbox and no runtime mutation."""
import hashlib
import io
import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import dropbox_asset_stage as stage


def png(mode="RGBA"):
    b = io.BytesIO()
    Image.new(mode, (128, 64), (122, 88, 41, 255) if mode == "RGBA" else (20, 60, 80)).save(b, format="PNG")
    return b.getvalue()


class SourceStageTests(unittest.TestCase):
    def setUp(self):
        self.t = tempfile.TemporaryDirectory()
        self.project = Path(self.t.name)
        self.entry = "custodian/asset_drop/source_work/ash_bell/ritualant_family/idle_source.png"
        self.data = png()
        self.path = self.project / "package.zip"
        with zipfile.ZipFile(self.path, "w", compression=zipfile.ZIP_DEFLATED) as z:
            z.writestr(self.entry, self.data)
            z.writestr("MANIFEST.json", "{}")
        self.sha = stage.file_sha256(self.path)
        self.receipt = {"batch_id": "approved-batch", "sha256": self.sha, "decision": "approved",
                        "reviewed_by": "user", "reviewed_at": "2026-10-13T00:00:00Z",
                        "authoring_chat": "https://chatgpt.com/c/test",
                        "sources": [{"entry": self.entry, "family_id": "ritualant_family",
                                     "state_id": "idle", "sha256": stage.sha256_bytes(self.data),
                                     "source_dimensions": [128, 64], "frames": 1,
                                     "target_frame_size": [64, 64]}]}
        self.set_receipts([self.receipt])

    def tearDown(self):
        self.t.cleanup()

    def set_receipts(self, receipts):
        p = self.project / stage.REVIEW_FILE
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(json.dumps({"schema": "custodian.asset_source_reviews.v1",
                                  "receipts": receipts}))

    def test_dry_run_is_read_only(self):
        dest = self.project / self.entry
        answer = stage.stage(self.project, self.path, "approved-batch", False, False)
        self.assertFalse(answer["applied"])
        self.assertEqual(len(answer["operations"]), 1)
        self.assertFalse(dest.exists())

    def test_apply_preserves_source_bytes(self):
        answer = stage.stage(self.project, self.path, "approved-batch", False, True)
        self.assertTrue(answer["applied"])
        self.assertEqual((self.project / self.entry).read_bytes(), self.data)

    def test_reapply_does_not_overwrite(self):
        stage.stage(self.project, self.path, "approved-batch", False, True)
        with self.assertRaisesRegex(ValueError, "destination exists"):
            stage.stage(self.project, self.path, "approved-batch", False, True)

    def test_unapproved_or_wrong_digest_fail_closed(self):
        r = dict(self.receipt, decision="needs_regeneration")
        self.set_receipts([r])
        with self.assertRaisesRegex(ValueError, "not approved"):
            stage.stage(self.project, self.path, "approved-batch", False, True)
        self.set_receipts([])
        with self.assertRaisesRegex(ValueError, "receipt not found"):
            stage.stage(self.project, self.path, "approved-batch", False, True)

    def test_tampered_member_fails_even_if_review_hash_matches_package(self):
        r = dict(self.receipt)
        r["sources"] = [dict(self.receipt["sources"][0], sha256="f" * 64)]
        self.set_receipts([r])
        with self.assertRaisesRegex(ValueError, "differs"):
            stage.stage(self.project, self.path, "approved-batch", False, True)

    def test_source_traversal_rejected(self):
        r = dict(self.receipt)
        r["sources"] = [dict(self.receipt["sources"][0],
                             entry="custodian/asset_drop/source_work/ash_bell/../../escape_source.png")]
        self.set_receipts([r])
        with self.assertRaisesRegex(ValueError, "unsafe"):
            stage.stage(self.project, self.path, "approved-batch", False, True)

    def test_non_rgba_rejected(self):
        self.data = png("RGB")
        with zipfile.ZipFile(self.path, "w") as z:
            z.writestr(self.entry, self.data)
        self.sha = stage.file_sha256(self.path)
        r = dict(self.receipt, sha256=self.sha)
        r["sources"] = [dict(self.receipt["sources"][0], sha256=stage.sha256_bytes(self.data))]
        self.set_receipts([r])
        with self.assertRaisesRegex(ValueError, "RGBA"):
            stage.stage(self.project, self.path, "approved-batch", False, True)

    def test_normalization_refuses_unregistered_family(self):
        with self.assertRaisesRegex(ValueError, "not registered"):
            stage.stage(self.project, self.path, "approved-batch", True, True)
        self.assertFalse((self.project / self.entry).exists())


if __name__ == "__main__":
    unittest.main()
