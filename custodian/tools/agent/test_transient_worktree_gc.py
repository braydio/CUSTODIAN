"""Disposable Git end-to-end safety checks for transient checkout reclamation."""
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import transient_worktree_gc as gc


def git(repo, *args):
    result = subprocess.run(['git', '-C', str(repo), *args], capture_output=True, text=True)
    if result.returncode:
        raise AssertionError(result.stderr or result.stdout)
    return result.stdout.strip()


class TransientGcTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.bare = self.base / 'remote.git'
        self.repo = self.base / 'repo'
        git(self.base, 'init', '--bare', str(self.bare))
        git(self.base, 'clone', str(self.bare), str(self.repo))
        git(self.repo, 'checkout', '-b', 'main')
        git(self.repo, 'config', 'user.name', 'Test')
        git(self.repo, 'config', 'user.email', 'test@example.test')
        (self.repo / 'base.txt').write_text('base\n')
        git(self.repo, 'add', 'base.txt')
        git(self.repo, 'commit', '-m', 'base')
        git(self.repo, 'push', '-u', 'origin', 'main')
        git(self.repo, 'symbolic-ref', 'refs/remotes/origin/HEAD', 'refs/remotes/origin/main')
        self.pool = self.base / '.custodian-worktrees'
        self.pool.mkdir()
        self.wid = 'demo-done'
        self.path = self.pool / f'{self.wid}-20261028T120000Z-aabbccddeeff'
        self.arch = self.repo / gc.ARCHIVE / 'DEMO_DONE.md'
        self.arch.parent.mkdir(parents=True)
        self.arch.write_text('# Done\n- Workstream: `demo-done`\n- Status: `complete`\n')
        git(self.repo, 'add', str(self.arch.relative_to(self.repo)))
        git(self.repo, 'commit', '-m', 'archive existing done')
        git(self.repo, 'push', 'origin', 'main')
        git(self.repo, 'worktree', 'add', '-b', 'agent/demo-done', str(self.path), 'main')
        self.patch = patch.object(gc, 'in_use', return_value=False)
        self.patch.start()
        self.addCleanup(self.patch.stop)

    def scan(self, apply=True):
        return gc.sweep(self.repo, apply=apply)

    def test_reaps_only_checkout_and_preserves_branch(self):
        result = self.scan(apply=False)
        self.assertEqual(result['eligible'], [str(self.path)])
        self.assertTrue(self.path.exists())
        result = self.scan()
        self.assertEqual(result['removed'], [str(self.path)])
        self.assertFalse(self.path.exists())
        self.assertEqual(git(self.repo, 'rev-parse', 'refs/heads/agent/demo-done'), git(self.repo, 'rev-parse', 'main'))
        self.assertEqual(git(self.repo, 'rev-parse', 'refs/remotes/origin/main'), git(self.repo, 'rev-parse', 'main'))

    def test_retains_dirty_untracked_and_ignored_content(self):
        (self.path / 'base.txt').write_text('dirty\n')
        self.assertEqual(self.scan()['removed'], [])
        (self.path / 'base.txt').write_text('base\n')
        (self.path / 'untracked.bin').write_bytes(b'valuable')
        self.assertEqual(self.scan()['removed'], [])
        (self.path / 'untracked.bin').unlink()
        (self.path / '.gitignore').write_text('*.uid\n')
        git(self.path, 'add', '.gitignore'); git(self.path, 'commit', '-m', 'ignored fixture')
        # HEAD is not on main so already protected.
        (self.path / 'asset.uid').write_text('asset')
        self.assertEqual(self.scan()['removed'], [])

    def test_retains_ignored_only_payload(self):
        (self.repo / '.gitignore').write_text('*.uid\n')
        git(self.repo, 'add', '.gitignore'); git(self.repo, 'commit', '-m', 'ignore uid')
        git(self.repo, 'push', 'origin', 'main')
        git(self.path, 'merge', '--ff-only', 'main')
        (self.path / 'private.uid').write_text('irreplaceable')
        self.assertEqual(self.scan()['removed'], [])
        self.assertTrue((self.path / 'private.uid').exists())

    def test_preserves_unlanded_head_and_live_claim(self):
        (self.path / 'change.txt').write_text('future')
        git(self.path, 'add', 'change.txt'); git(self.path, 'commit', '-m', 'unlanded')
        self.assertEqual(self.scan()['removed'], [])
        git(self.path, 'reset', '--hard', 'main')  # disposable fixture only
        git(self.repo, 'update-ref', 'refs/remotes/origin/dispatch-claims/demo-done', git(self.repo, 'rev-parse', 'main'))
        self.assertEqual(self.scan()['removed'], [])

    def test_preserves_active_packet_and_mismatched_remote(self):
        active = self.repo / gc.ACTIVE / 'DEMO_DONE.md'
        active.write_text('# Active\n- Workstream: `demo-done`\n- Status: `ready`\n')
        git(self.repo, 'add', str(active.relative_to(self.repo)))
        git(self.repo, 'commit', '-m', 'active override')
        git(self.repo, 'push', 'origin', 'main')
        self.assertEqual(self.scan()['removed'], [])
        git(self.repo, 'rm', str(active.relative_to(self.repo)))
        git(self.repo, 'commit', '-m', 'remove active override')
        git(self.repo, 'push', 'origin', 'main')
        git(self.repo, 'update-ref', 'refs/remotes/origin/agent/demo-done', git(self.repo, 'rev-parse', 'main~1'))
        self.assertEqual(self.scan()['removed'], [])

    def test_preserves_locked_worktree_and_in_use_process(self):
        git(self.repo, 'worktree', 'lock', '--reason', 'important evidence', str(self.path))
        self.assertEqual(self.scan()['removed'], [])
        git(self.repo, 'worktree', 'unlock', str(self.path))
        with patch.object(gc, 'in_use', return_value=True):
            self.assertEqual(self.scan()['removed'], [])
        self.assertEqual(self.scan()['removed'], [str(self.path)])

    def test_rejects_wrong_directory_and_status(self):
        self.arch.write_text('# Bad\n- Workstream: `demo-done`\n- Status: `blocked`\n')
        git(self.repo, 'add', str(self.arch.relative_to(self.repo)))
        git(self.repo, 'commit', '-m', 'block archived')
        git(self.repo, 'push', 'origin', 'main')
        self.assertEqual(self.scan()['removed'], [])
        self.arch.write_text('# Done\n- Workstream: `demo-done`\n- Status: `complete`\n')
        git(self.repo, 'add', str(self.arch.relative_to(self.repo)))
        git(self.repo, 'commit', '-m', 'complete archived')
        git(self.repo, 'push', 'origin', 'main')
        foreign = self.base / 'not-a-worktree-pool'
        foreign.mkdir()
        # The existing checkout remains outside the foreign pool, which is not an authorized target.
        self.assertFalse(gc.eligible(self.repo, self.path, self.wid, foreign, git(self.path, 'rev-parse', 'HEAD')))


if __name__ == '__main__':
    unittest.main()
