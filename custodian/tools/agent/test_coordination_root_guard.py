"""Focused regression checks for the Claude coordination-root Bash guard."""
from __future__ import annotations
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("coordination_root_guard.py")
spec = importlib.util.spec_from_file_location("coordination_root_guard", SCRIPT)
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)


class RootGuardTests(unittest.TestCase):
    def test_blocks_branch_switch_and_commit_at_root(self):
        root = Path("/tmp/custodian-coordination")
        for command in ("git switch -c feature", "git checkout branch", "git rebase main",
                        "rtk git reset --hard", "git add AGENTS.md && git commit -m x"):
            self.assertTrue(guard.is_restricted(command, root, root), command)

    def test_allows_read_only_and_main_sync_in_root(self):
        root = Path("/tmp/custodian-coordination")
        for command in ("git status --short", "git fetch origin",
                        "git pull --ff-only origin main", "git log -1"):
            self.assertFalse(guard.is_restricted(command, root, root), command)

    def test_allows_worktree_mutations(self):
        root = Path("/tmp/custodian-coordination")
        worktree = Path("/tmp/custodian-turns/one")
        self.assertFalse(guard.is_restricted("git checkout -b own", worktree, root))
        self.assertFalse(guard.is_restricted(
            f"git -C {worktree} commit -m change", root, root
        ))

    def test_allows_several_isolated_git_targets_from_root_cwd(self):
        root = Path("/tmp/custodian-coordination")
        worktree = Path("/tmp/custodian-turns/one")
        self.assertFalse(guard.is_restricted(
            f"git -C {worktree} add a.py && git -C {worktree} commit -m change", root, root
        ))
        self.assertTrue(guard.is_restricted(
            f"git -C {worktree} add a.py && git commit -m change", root, root
        ))

    def test_explicit_root_target_denied_from_other_checkout(self):
        root = Path("/tmp/custodian-coordination")
        worktree = Path("/tmp/custodian-turns/one")
        self.assertTrue(guard.is_restricted(
            f"git -C {root} switch task", worktree, root
        ))


if __name__ == "__main__":
    unittest.main()
