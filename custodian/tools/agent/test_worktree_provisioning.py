"""Disposable Git/LFS fixtures for profile capacity, omission, and hydration."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import worktree_provisioning as provisioning


def git(cwd: Path, *args: str, env: dict[str, str] | None = None) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, env=env, text=True, capture_output=True)
    if result.returncode:
        raise AssertionError(result.stderr or result.stdout)
    return result.stdout.strip()


class WorktreeProvisioningTests(unittest.TestCase):
    def test_published_awakening_profile_pins_gate_plates_and_sparse_dependencies(self):
        project_root = Path(__file__).resolve().parents[3]
        profile_path = project_root / "custodian/docs/ai_context/worktree_profiles/awakening_gate_lateral_overlooks_v1.json"
        profile = json.loads(profile_path.read_text())
        required_plates = {
            "custodian/content/levels/awakening/07_gate_of_dust/awakening_gate_plaza_underlay_1536x768.png",
            "custodian/content/levels/awakening/07_gate_of_dust/awakening_gate_plaza_foreground_1536x768.png",
        }
        self.assertTrue(required_plates.issubset(profile["hydrate_lfs_paths"]))
        self.assertIn("custodian/scenes/awakening_first_return.tscn", profile["include_paths"])
        self.assertIn("custodian/icon.svg", profile["include_paths"])
        self.assertIn("custodian/tools/validation/awakening_first_return_geometry_smoke.gd", profile["include_paths"])
        self.assertFalse(any(path.startswith("custodian/content/levels/hub/")
                             for path in profile["hydrate_lfs_paths"]))
        self.assertEqual(len(profile["include_paths"]), len(set(profile["include_paths"])))

    def test_published_awakening_profile_covers_static_scene_and_test_dependencies(self):
        project_root = Path(__file__).resolve().parents[3]
        profile_path = project_root / "custodian/docs/ai_context/worktree_profiles/awakening_gate_lateral_overlooks_v1.json"
        included = set(json.loads(profile_path.read_text())["include_paths"])
        tracked = set(subprocess.check_output(
            ["git", "ls-tree", "-r", "--name-only", "HEAD"], cwd=project_root, text=True,
        ).splitlines())
        roots = {
            "custodian/project.godot",
            "custodian/icon.svg",
            "custodian/scenes/awakening_first_return.tscn",
            "custodian/game/world/awakening/awakening_layout.gd",
            "custodian/game/world/awakening/awakening_first_return.gd",
            "custodian/tools/validation/awakening_first_return_geometry_smoke.gd",
            "custodian/tools/validation/awakening_first_return_smoke.gd",
            "custodian/tools/validation/awakening_first_return_progression_smoke.gd",
            "custodian/tools/validation/awakening_art_registration_smoke.gd",
        }
        self.assertTrue(roots.issubset(included))
        self.assertTrue(roots.issubset(tracked))
        call_ref = re.compile(r"(?:preload|load|exists)\s*\(\s*['\"]res://([^'\"]+)")
        scene_ref = re.compile(r"(?m)^path\s*=\s*['\"]res://([^'\"]+)")
        queue = list(roots)
        visited: set[str] = set()
        missing: set[str] = set()
        while queue:
            path = queue.pop()
            if path in visited or path not in tracked:
                continue
            visited.add(path)
            if path not in included:
                missing.add(path)
            source = project_root / path
            try:
                contents = source.read_text(encoding="utf-8", errors="ignore")
            except OSError:
                continue
            refs = call_ref.findall(contents) if path.endswith((".gd", ".godot", ".cfg")) else scene_ref.findall(contents)
            if path == "custodian/project.godot":
                autoload = re.search(r"(?ms)^\[autoload\]\s*\n(.*?)(?=^\[|\Z)", contents)
                if autoload:
                    refs.extend(re.findall(r"['\"]res://([^'\"]+)['\"]", autoload.group(1)))
            for ref in refs:
                dependency = "custodian/" + ref
                if dependency in tracked and dependency not in visited:
                    queue.append(dependency)
                    if dependency.endswith(".png") and dependency + ".import" in tracked:
                        queue.append(dependency + ".import")
        self.assertEqual(sorted(missing), [])

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="custodian-lfs-fixture-")
        self.base = Path(self.temp.name)
        self.remote = self.base / "remote.git"
        self.repo = self.base / "repo"
        self.global_config = self.base / "global.gitconfig"
        self.global_config.write_text("[fixture]\n\tsentinel = preserved\n")
        self.env = {**os.environ, "GIT_CONFIG_GLOBAL": str(self.global_config), "GIT_LFS_SKIP_SMUDGE": "1"}
        git(self.base, "init", "--bare", str(self.remote), env=self.env)
        git(self.base, "clone", str(self.remote), str(self.repo), env=self.env)
        git(self.repo, "checkout", "-b", "main", env=self.env)
        git(self.repo, "config", "user.name", "Provisioning Fixture", env=self.env)
        git(self.repo, "config", "user.email", "fixture@example.invalid", env=self.env)
        git(self.repo, "lfs", "install", "--local", env=self.env)
        git(self.repo, "lfs", "track", "*.bin", env=self.env)
        (self.repo / "custodian").mkdir()
        (self.repo / "custodian" / "keep.txt").write_text("usable checked out text\n")
        self.asset = bytes(range(256)) * 64
        self.omitted = b"unrequested payload\n" * 16_384
        (self.repo / "custodian" / "asset.bin").write_bytes(self.asset)
        (self.repo / "custodian" / "omitted.bin").write_bytes(self.omitted)
        self.profile_rel = "custodian/docs/worktree-profile.json"
        profile_path = self.repo / self.profile_rel
        profile_path.parent.mkdir(parents=True)
        profile_path.write_text(json.dumps({
            "schema": provisioning.PROFILE_SCHEMA,
            "include_paths": [self.profile_rel, "custodian/keep.txt", "custodian/asset.bin"],
            "hydrate_lfs_paths": ["custodian/asset.bin"],
        }, sort_keys=True) + "\n")
        git(self.repo, "add", ".gitattributes", "custodian", env=self.env)
        git(self.repo, "commit", "-m", "fixture", env=self.env)
        git(self.repo, "push", "-u", "origin", "main", env=self.env)
        git(self.repo, "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/main", env=self.env)
        git(self.repo, "fetch", "origin", env=self.env)

    def tearDown(self):
        self.temp.cleanup()

    def test_profile_estimate_accounts_for_hydration_but_not_omitted_lfs(self):
        with mock.patch.dict(os.environ, self.env):
            profile = provisioning.load_profile(self.repo, "origin/main", self.profile_rel)
            files = provisioning.inventory(self.repo, "origin/main", profile)
            asset = next(item for item in files if item.path == "custodian/asset.bin")
            self.assertEqual(asset.lfs_size, len(self.asset))
            self.assertTrue(asset.lfs_oid)
            deferred = provisioning.estimate_checkout_bytes(
                self.repo, ref="origin/main", profile=profile, deferred_lfs=True,
            )
            self.assertEqual(deferred["payload_bytes"], len(self.asset) + sum(
                item.git_size for item in files if item.path != "custodian/asset.bin"
            ))
            full = provisioning.estimate_checkout_bytes(self.repo, ref="origin/main")
            self.assertGreaterEqual(full["payload_bytes"], len(self.asset) + len(self.omitted))
            full_capacity = provisioning.preflight_capacity(
                self.repo, ref="origin/main", target=self.base,
            )
            self.assertEqual(full_capacity["cache_bytes_to_fetch"], 0)
            low = provisioning.preflight_capacity(
                self.repo, profile_path=self.profile_rel, ref="origin/main", target=self.base,
            )
            self.assertIn("available_free_bytes", low)
            self.assertEqual(self.global_config.read_text(), "[fixture]\n\tsentinel = preserved\n")

    def test_large_batch_drains_git_output_while_feeding_object_ids(self):
        oid = git(self.repo, "rev-parse", "origin/main:custodian/keep.txt", env=self.env)
        # More than a typical pipe buffer in both directions. This would hang if
        # the caller wrote every OID before consuming cat-file's output.
        blobs = provisioning._batch_blobs(self.repo, [oid] * 20_000)
        self.assertEqual(blobs[oid], b"usable checked out text\n")

    def test_sparse_checkout_omits_unrequested_lfs_and_hydrates_exact_local_asset(self):
        with mock.patch.dict(os.environ, self.env):
            full = self.base / "full-worktree"
            git(self.repo, "worktree", "add", "-b", "agent/full-fixture", str(full), "origin/main", env=self.env)
            git(full, "lfs", "checkout", env=self.env)
            target = self.base / "sparse-worktree"
            git(self.repo, "worktree", "add", "-b", "agent/fixture", str(target), "origin/main", env=self.env)
            profile = provisioning.load_profile(self.repo, "origin/main", self.profile_rel)
            selected = provisioning.configure_sparse_checkout(target, self.repo, "origin/main", profile)
            self.assertTrue((target / "custodian/keep.txt").is_file())
            self.assertEqual((target / "custodian/keep.txt").read_text(), "usable checked out text\n")
            self.assertEqual((target / "custodian/asset.bin").read_bytes(), self.asset)
            self.assertFalse((target / "custodian/omitted.bin").exists())
            self.assertEqual([item.path for item in selected if item.lfs_size], ["custodian/asset.bin"])
            def allocated_bytes(root: Path) -> int:
                return sum(path.stat().st_blocks * 512 for path in root.rglob("*") if not path.is_symlink())
            self.assertGreater(allocated_bytes(full), allocated_bytes(target))
            self.assertEqual(self.global_config.read_text(), "[fixture]\n\tsentinel = preserved\n")

    def test_missing_local_lfs_object_fails_without_network_fetch(self):
        with mock.patch.dict(os.environ, self.env):
            target = self.base / "missing-lfs-worktree"
            git(self.repo, "worktree", "add", "-b", "agent/missing-lfs", str(target), "origin/main", env=self.env)
            profile = provisioning.load_profile(self.repo, "origin/main", self.profile_rel)
            item = next(item for item in provisioning.inventory(self.repo, "origin/main", profile)
                        if item.path == "custodian/asset.bin")
            oid = item.lfs_oid
            obj = self.repo / ".git" / "lfs" / "objects" / oid[:2] / oid[2:4] / oid
            self.assertTrue(obj.is_file())
            obj.unlink()
            full_report = provisioning.preflight_capacity(self.repo, ref="origin/main", target=self.base)
            self.assertEqual(full_report["cache_bytes_to_fetch"], len(self.asset))
            report = provisioning.preflight_capacity(
                self.repo, profile_path=self.profile_rel, ref="origin/main", target=self.base,
            )
            self.assertFalse(report["sufficient"])
            self.assertEqual(report["local_lfs_failures"][0]["path"], "custodian/asset.bin")
            with self.assertRaisesRegex(provisioning.ProvisioningError, "hydrated LFS bytes do not match pinned pointer"):
                provisioning.configure_sparse_checkout(target, self.repo, "origin/main", profile)
            self.assertTrue(provisioning._pointer((target / "custodian/asset.bin").read_bytes()))

    def test_profile_rejects_escaping_duplicate_and_unapproved_hydration_paths(self):
        for invalid in ("../outside", "/absolute", ".", "custodian//file"):
            with self.subTest(path=invalid), self.assertRaises(provisioning.ProvisioningError):
                provisioning._safe_relative(invalid)
        profile_path = self.repo / self.profile_rel
        original = json.loads(profile_path.read_text())
        original["include_paths"] = ["custodian/keep.txt", "custodian/keep.txt"]
        profile_path.write_text(json.dumps(original))
        git(self.repo, "add", self.profile_rel, env=self.env)
        git(self.repo, "commit", "-m", "duplicate profile fixture", env=self.env)
        git(self.repo, "push", "origin", "main", env=self.env)
        git(self.repo, "fetch", "origin", env=self.env)
        with mock.patch.dict(os.environ, self.env), self.assertRaisesRegex(provisioning.ProvisioningError, "unique"):
            provisioning.load_profile(self.repo, "origin/main", self.profile_rel)
        original["include_paths"] = [self.profile_rel, "custodian/keep.txt"]
        original["hydrate_lfs_paths"] = ["custodian/asset.bin"]
        profile_path.write_text(json.dumps(original, sort_keys=True) + "\n")
        git(self.repo, "add", self.profile_rel, env=self.env)
        git(self.repo, "commit", "-m", "unapproved hydration fixture", env=self.env)
        git(self.repo, "push", "origin", "main", env=self.env)
        git(self.repo, "fetch", "origin", env=self.env)
        with mock.patch.dict(os.environ, self.env):
            profile = provisioning.load_profile(self.repo, "origin/main", self.profile_rel)
            with self.assertRaisesRegex(provisioning.ProvisioningError, "not included by profile"):
                provisioning.inventory(self.repo, "origin/main", profile)
