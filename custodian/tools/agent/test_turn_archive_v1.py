"""Content-verified archive inventory and restore tests."""
import hashlib
import json
import os
import stat
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path

from custodian.tools.agent import turn_archive_v1 as archive


COMMIT = "a" * 40


class TurnArchiveTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="custodian-turn-archive-v1-")
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.source = self.base / "archive"
        self.source.mkdir()

    def sample(self):
        folder = self.source / "worktree/source"
        folder.mkdir(parents=True)
        data = folder / "code.py"
        data.write_bytes(b"source bytes\n")
        os.chmod(data, 0o755)
        (self.source / "worktree/alias.py").symlink_to("source/code.py")
        pointer = self.source / "worktree/art.bin"
        pointer.write_text(
            "version https://git-lfs.github.com/spec/v1\n"
            + "oid sha256:" + "b" * 64 + "\nsize 1024\n",
            encoding="ascii")
        external = self.base / "external-evidence.bin"
        external.write_bytes(b"private evidence")
        self.external_ref = {"id": "evidence-1", "source_path": str(external),
                             "sha256": hashlib.sha256(b"private evidence").hexdigest(),
                             "size": len(b"private evidence")}

    def test_inventory_restore_preserves_files_modes_links_and_lfs_identity(self):
        self.sample()
        manifest = archive.inventory(self.source, COMMIT, [self.external_ref])
        path = self.base / "private-manifest.json"
        archive.write_manifest(path, manifest)
        loaded = archive.load_manifest(path)
        self.assertEqual(archive.verify(self.source, loaded)["external_evidence_verified"], 1)
        entry = next(row for row in loaded["entries"] if row["path"] == "worktree/art.bin")
        self.assertEqual(entry["git_lfs"], {"oid": "b" * 64, "size": 1024})
        destination = self.base / "restored"
        archive.restore(self.source, loaded, destination)
        self.assertEqual((destination / "worktree/source/code.py").read_bytes(), b"source bytes\n")
        self.assertEqual(stat.S_IMODE((destination / "worktree/source/code.py").stat().st_mode), 0o755)
        self.assertEqual(os.readlink(destination / "worktree/alias.py"), "source/code.py")
        self.assertEqual(archive.verify(destination, loaded)["verified"], True)

    def test_changed_external_evidence_blocks_archive_verification(self):
        self.sample()
        manifest = archive.inventory(self.source, COMMIT, [self.external_ref])
        Path(self.external_ref["source_path"]).write_bytes(b"changed evidence")
        with self.assertRaisesRegex(archive.ArchiveError, "external evidence (changed|identity mismatch)"):
            archive.verify(self.source, manifest)

    def test_wrong_content_hash_and_incomplete_archive_block(self):
        (self.source / "data.txt").write_text("original", encoding="utf-8")
        manifest = archive.inventory(self.source, COMMIT)
        (self.source / "data.txt").write_text("changed", encoding="utf-8")
        with self.assertRaisesRegex(archive.ArchiveError, "verification failed"):
            archive.verify(self.source, manifest)
        self.assertFalse((self.base / "restored").exists())

    def test_incorrect_manifest_file_hash_blocks_verification(self):
        (self.source / "data.txt").write_text("original", encoding="utf-8")
        manifest = archive.inventory(self.source, COMMIT)
        manifest["entries"][0]["sha256"] = "d" * 64
        unsigned = {key: value for key, value in manifest.items() if key != "manifest_sha256"}
        manifest["manifest_sha256"] = hashlib.sha256(archive._canonical(unsigned)).hexdigest()
        with self.assertRaisesRegex(archive.ArchiveError, "verification failed"):
            archive.verify(self.source, manifest)

    def test_manifest_checksum_and_path_traversal_are_rejected(self):
        (self.source / "data.txt").write_text("contents", encoding="utf-8")
        manifest = archive.inventory(self.source, COMMIT)
        path = self.base / "bad.json"
        archive.write_manifest(path, manifest)
        raw = json.loads(path.read_text(encoding="utf-8"))
        raw["entries"][0]["path"] = "../escape"
        path.write_text(json.dumps(raw), encoding="utf-8")
        with self.assertRaisesRegex(archive.ArchiveError, "checksum"):
            archive.load_manifest(path)
        raw["manifest_sha256"] = hashlib.sha256(
            archive._canonical({key: val for key, val in raw.items() if key != "manifest_sha256"})
        ).hexdigest()
        path.write_text(json.dumps(raw), encoding="utf-8")
        with self.assertRaisesRegex(archive.ArchiveError, "unsafe archive path"):
            archive.load_manifest(path)

    def test_symlink_escape_is_recorded_but_rejected_during_restore(self):
        (self.source / "outside-link").symlink_to("../../outside")
        manifest = archive.inventory(self.source, COMMIT)
        row = next(item for item in manifest["entries"] if item["path"] == "outside-link")
        self.assertFalse(row["restore_safe"])
        with self.assertRaisesRegex(archive.ArchiveError, "unsafe symlink restore blocked"):
            archive.restore(self.source, manifest, self.base / "restored")

    def test_unsupported_file_type_is_rejected(self):
        if not hasattr(os, "mkfifo"):
            self.skipTest("named pipes unavailable")
        os.mkfifo(self.source / "pipe")
        with self.assertRaisesRegex(archive.ArchiveError, "unsupported filesystem object"):
            archive.inventory(self.source, COMMIT)

    def test_restore_requires_new_destination_and_leaves_none_on_verification_failure(self):
        (self.source / "data.txt").write_text("source", encoding="utf-8")
        manifest = archive.inventory(self.source, COMMIT)
        (self.source / "data.txt").write_text("modified", encoding="utf-8")
        destination = self.base / "interrupted-restore"
        with self.assertRaises(archive.ArchiveError):
            archive.restore(self.source, manifest, destination)
        self.assertFalse(destination.exists())
        self.assertFalse(list(self.base.glob(".interrupted-restore.restore-*")))
        destination.mkdir()
        with self.assertRaisesRegex(archive.ArchiveError, "must not already exist"):
            archive.restore(self.source, manifest, destination)

    def test_interrupted_restore_cleans_staging_without_creating_destination(self):
        (self.source / "data.txt").write_text("source", encoding="utf-8")
        manifest = archive.inventory(self.source, COMMIT)
        calls = 0
        original_verify = archive.verify

        def fail_after_copy(root, payload):
            nonlocal calls
            calls += 1
            if calls == 1:
                return original_verify(root, payload)
            raise archive.ArchiveError("injected verification interruption")

        destination = self.base / "interrupted"
        with patch.object(archive, "verify", side_effect=fail_after_copy):
            with self.assertRaisesRegex(archive.ArchiveError, "injected verification interruption"):
                archive.restore(self.source, manifest, destination)
        self.assertFalse(destination.exists())
        self.assertFalse(list(self.base.glob(".interrupted.restore-*")))

    def test_invalid_archive_commit_and_external_evidence_identity_are_rejected(self):
        with self.assertRaisesRegex(archive.ArchiveError, "full Git object id"):
            archive.inventory(self.source, "deadbeef")
        with self.assertRaisesRegex(archive.ArchiveError, "SHA-256"):
            archive.inventory(self.source, COMMIT, [{"id": "receipt", "sha256": "bad"}])


if __name__ == "__main__":
    unittest.main(verbosity=2)
