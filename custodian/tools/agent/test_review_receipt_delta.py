"""Focused regressions for archived review target resolution."""
from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

from review_receipt_delta import read_git_text, resolve_target_implementation_commit

ROOT = Path(__file__).resolve().parents[3]
LIFT_MAIN = "8262ac57622059256f9f5d136ef0eff28dd59a1d"
LIFT_INTRODUCTION = "f3b94d0768bc110755f2b9be1d1e60d22fe1577c"
LIFT_RESTORE = "38c188421b18e0f5ddcd47ad0ff3dd5399eceac6"
LIFT_TARGET = "custodian/docs/ai_context/task_packets/archived/ASH_BELL_SURFACE_LIFT_V2_ASSET_INTAKE.md"


def git(repo: Path, *args: str) -> str:
    return subprocess.run(["git", *args], cwd=repo, check=True, capture_output=True, text=True).stdout.strip()


def commit(repo: Path, message: str) -> str:
    subprocess.run(["git", "add", "-A"], cwd=repo, check=True)
    subprocess.run(["git", "commit", "-qm", message], cwd=repo, check=True)
    return git(repo, "rev-parse", "HEAD")


def packet(status: str, *, workstream: str = "target-impl", kind: str = "implementation",
           reviewed_main: str = "0" * 40) -> str:
    return (f"# Target\n- Workstream: `{workstream}`\n- Kind: `{kind}`\n"
            f"- Status: `{status}`\n- Reviewed main: `{reviewed_main}`\n")


class ReviewReceiptTargetResolutionTests(unittest.TestCase):
    def test_lift_archive_resolves_authentic_introduction_not_later_restore(self) -> None:
        baseline = read_git_text(ROOT, LIFT_MAIN, LIFT_TARGET)
        head_before = git(ROOT, "rev-parse", "HEAD")
        resolved, error = resolve_target_implementation_commit(
            ROOT, LIFT_MAIN, LIFT_TARGET, "ash-bell-surface-lift-v2-asset-intake", baseline,
        )
        self.assertIsNone(error)
        self.assertEqual(resolved, LIFT_INTRODUCTION)
        self.assertNotEqual(resolved, LIFT_RESTORE)
        self.assertEqual(git(ROOT, "rev-parse", "HEAD"), head_before)

    def test_archive_restore_without_matching_active_lifecycle_stays_ambiguous(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
            git(repo, "config", "user.name", "Test")
            git(repo, "config", "user.email", "test@example.invalid")
            archive = repo / "custodian/docs/ai_context/task_packets/archived/TARGET.md"
            archive.parent.mkdir(parents=True)
            archive.write_text(packet("complete"), encoding="utf-8")
            commit(repo, "first archive addition")
            archive.unlink()
            commit(repo, "remove archived file")
            archive.parent.mkdir(parents=True, exist_ok=True)
            archive.write_text(packet("complete"), encoding="utf-8")
            pinned_main = commit(repo, "restore same archive bytes")

            resolved, error = resolve_target_implementation_commit(
                repo, pinned_main, "custodian/docs/ai_context/task_packets/archived/TARGET.md", "target-impl",
            )
            self.assertIsNone(resolved)
            self.assertEqual(error, "pinned target has no unique complete archive-introduction commit")

    def test_two_matching_active_archive_lifecycles_remain_ambiguous(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
            git(repo, "config", "user.name", "Test")
            git(repo, "config", "user.email", "test@example.invalid")
            active = repo / "custodian/docs/ai_context/task_packets/TARGET.md"
            archive = repo / "custodian/docs/ai_context/task_packets/archived/TARGET.md"
            (repo / "README").write_text("reviewed baseline\n", encoding="utf-8")
            reviewed_main = commit(repo, "reviewed baseline")
            active.parent.mkdir(parents=True)
            active.write_text(packet("ready", reviewed_main=reviewed_main), encoding="utf-8")
            commit(repo, "first active packet")
            archive.parent.mkdir(parents=True)
            archive.write_text(packet("complete", reviewed_main=reviewed_main), encoding="utf-8")
            commit(repo, "first archive introduction")
            active.unlink()
            commit(repo, "retire first active packet")
            archive.unlink()
            commit(repo, "remove first archive")
            active.parent.mkdir(parents=True, exist_ok=True)
            active.write_text(packet("ready", reviewed_main=reviewed_main), encoding="utf-8")
            commit(repo, "second active packet")
            archive.parent.mkdir(parents=True, exist_ok=True)
            archive.write_text(packet("complete", reviewed_main=reviewed_main), encoding="utf-8")
            commit(repo, "second archive introduction")
            active.unlink()
            pinned_main = commit(repo, "retire second active packet")

            resolved, error = resolve_target_implementation_commit(
                repo, pinned_main, "custodian/docs/ai_context/task_packets/archived/TARGET.md", "target-impl",
            )
            self.assertIsNone(resolved)
            self.assertEqual(error, "pinned target has no unique complete archive-introduction commit")

    def test_existing_single_archive_candidate_still_resolves(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            repo = Path(temp)
            subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
            git(repo, "config", "user.name", "Test")
            git(repo, "config", "user.email", "test@example.invalid")
            archive = repo / "custodian/docs/ai_context/task_packets/archived/TARGET.md"
            archive.parent.mkdir(parents=True)
            (repo / "README").write_text("reviewed baseline\n", encoding="utf-8")
            reviewed_main = commit(repo, "reviewed baseline")
            archive.write_text(packet("complete", reviewed_main=reviewed_main), encoding="utf-8")
            intro = commit(repo, "archive target")
            pinned_main = git(repo, "rev-parse", "HEAD")
            resolved, error = resolve_target_implementation_commit(
                repo, pinned_main, "custodian/docs/ai_context/task_packets/archived/TARGET.md", "target-impl",
            )
            self.assertIsNone(error)
            self.assertEqual(resolved, intro)


if __name__ == "__main__":
    unittest.main()
