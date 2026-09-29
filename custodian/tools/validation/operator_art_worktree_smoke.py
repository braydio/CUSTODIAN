#!/usr/bin/env python3
"""Fixture-isolated checks for Operator art checkout routing and landing."""
from __future__ import annotations

import os
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

OPERATOR_TOOLS = Path(__file__).resolve().parents[1] / "operator"
sys.path.insert(0, str(OPERATOR_TOOLS))
import operator_art_worktree as art

LAND_MAIN = Path(__file__).resolve().parents[1] / "agent/land_main.py"
REPO_ROOT = Path(__file__).resolve().parents[3]
SOURCE = "custodian/content/sprites/operator/source/animations/unarmed/attack/fast_01/lower.png"


def git(root: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=root, text=True, capture_output=True, check=False)
    if check and result.returncode:
        raise AssertionError(f"git {' '.join(args)} failed: {result.stderr or result.stdout}")
    return result.stdout.strip()


def fixture(base: Path) -> tuple[Path, Path, Path]:
    bare = base / "remote.git"
    coordination = base / "CUSTODIAN"
    source = coordination / SOURCE
    subprocess.run(["git", "init", "--bare", str(bare)], check=True, capture_output=True)
    coordination.mkdir()
    git(coordination, "init", "-b", "main")
    git(coordination, "config", "user.name", "Workbench fixture")
    git(coordination, "config", "user.email", "workbench@example.invalid")
    (coordination / ".gitignore").write_text(".ai/\n")
    (coordination / "custodian/tools/agent").mkdir(parents=True)
    shutil.copy2(LAND_MAIN, coordination / "custodian/tools/agent/land_main.py")
    for relative in (
        "tools/custodian_aliases.sh",
        "custodian/tools/operator/operator_cli.py",
        "custodian/tools/aseprite/bridge.py",
        "custodian/tools/art/custodian_pixelart_converter.py",
        "custodian/tools/assets/asset.py",
        "custodian/tools/pipelines/operator_runtime_build.py",
        "custodian/tools/validation/operator_animation_workbench_smoke.py",
        "custodian/game/actors/operator/operator.gd",
        "custodian/content/data/operator/profile.json",
        "custodian/content/metadata/assets/families/operator.asset.json",
        "custodian/content/sprites/operator/runtime/idle.png",
        "custodian/content/sprites/weapons/sword_cleaver/source/operator/heavy.png",
        "custodian/content/sprites/weapons/sword_cleaver/runtime/operator/heavy.png",
        "custodian/content/weapons/p9.json",
        "design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md",
        "custodian/content/sprites/enemies/unrelated/large.png",
        "custodian/content/sprites/effects/runtime/muzzle_flash_yellow.png",
        "custodian/content/sprites/effects/runtime/unrelated_large_pack.png",
        "custodian/addons/Sound FX Starter Pack Vol. 1/Motions and Impacts/Impact Vox Hammer.wav",
        "custodian/addons/Sound FX Starter Pack Vol. 1/Motions and Impacts/unrelated.wav",
        "reports/unrelated/report.json",
        "custodian/asset_drop/unrelated/source.png",
    ):
        path = coordination / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b"fixture\n")
    source.parent.mkdir(parents=True)
    source.write_bytes(b"original canonical art\n")
    git(coordination, "add", "-A")
    git(coordination, "commit", "-m", "fixture main")
    git(coordination, "remote", "add", "origin", str(bare))
    git(coordination, "push", "-u", "origin", "main")
    git(coordination, "fetch", "origin", "main")
    return bare, coordination, source


def commit_remote(coordination: Path, relative: str, payload: bytes, message: str) -> None:
    target = coordination / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(payload)
    git(coordination, "add", relative)
    git(coordination, "commit", "-m", message)
    git(coordination, "push", "origin", "main")


def sparse_sync_smoke(base: Path) -> None:
    _bare, coordination, _source = fixture(base)
    hooks = base / "test-hooks"
    hooks.mkdir()
    for name in ("post-checkout", "post-merge"):
        hook = hooks / name
        hook.write_text("#!/bin/sh\nmkdir -p .githooks\nprintf mutated > .githooks/post-commit\n")
        hook.chmod(0o755)
    git(coordination, "config", "core.hooksPath", str(hooks))
    art_root = art.ensure_art_worktree(coordination)
    assert not (art_root / ".githooks/post-commit").exists(), "checkout hooks ran during sparse initialization"
    ignored = art_root / ".ai/operator_animation_workbench/edited.aseprite"
    ignored.parent.mkdir(parents=True, exist_ok=True)
    ignored.write_bytes(b"user workbench bytes\x00")
    initial = git(art_root, "rev-parse", "HEAD")

    commit_remote(coordination, SOURCE, b"selected source v2\n", "selected source update")
    commit_remote(
        coordination,
        "custodian/content/sprites/enemies/unrelated/large.png",
        b"unrelated v2\n",
        "unrelated asset update",
    )
    art.ensure_art_worktree(coordination)
    assert not (art_root / ".githooks/post-commit").exists(), "merge hooks ran during safe synchronization"
    assert git(art_root, "rev-parse", "HEAD") != initial
    assert (art_root / SOURCE).read_bytes() == b"selected source v2\n"
    assert not (art_root / "custodian/content/sprites/enemies/unrelated/large.png").exists()
    assert ignored.read_bytes() == b"user workbench bytes\x00"
    assert art._git(art_root, "rev-parse", "HEAD") == art._git(art_root, "rev-parse", "origin/main")

    # Dirty authoring content in the sparse checkout blocks all synchronization.
    head_before = git(art_root, "rev-parse", "HEAD")
    (art_root / SOURCE).write_bytes(b"uncommitted authored pixels\n")
    commit_remote(coordination, SOURCE, b"selected source v3\n", "selected source v3")
    art.ensure_art_worktree(coordination)
    assert git(art_root, "rev-parse", "HEAD") == head_before
    assert (art_root / SOURCE).read_bytes() == b"uncommitted authored pixels\n"
    assert art.checkout_identity(art_root, coordination).main_relation == "ahead 0 / behind 1"
    art._git_without_hooks(art_root, "restore", "--", SOURCE)
    art.ensure_art_worktree(coordination)
    v3 = (art_root / SOURCE).read_bytes()
    assert v3 == b"selected source v3\n", f"dirty restore did not resume FF: source={v3!r}, state={art.checkout_identity(art_root, coordination)}, dirty={art._status_paths(art_root)}"

    # An idle branch with a local commit is never rebased or reset.
    (art_root / SOURCE).write_bytes(b"local commit\n")
    git(art_root, "add", SOURCE)
    git(art_root, "commit", "-m", "local authoring checkpoint")
    local_head = git(art_root, "rev-parse", "HEAD")
    commit_remote(coordination, "README.md", b"main changed again\n", "main changed again")
    art.ensure_art_worktree(coordination)
    assert git(art_root, "rev-parse", "HEAD") == local_head
    assert art.checkout_identity(art_root, coordination).main_relation == "ahead 1 / behind 1"

    # Pending landing state also blocks synchronization.
    art._git_without_hooks(art_root, "reset", "--hard", "origin/main")
    pending = art_root / art.PENDING_RELATIVE
    pending.parent.mkdir(parents=True, exist_ok=True)
    pending.write_text('{"status":"land_pending"}\n')
    pending_head = git(art_root, "rev-parse", "HEAD")
    commit_remote(coordination, "README.md", b"main changed pending\n", "main changed pending")
    art.ensure_art_worktree(coordination)
    assert git(art_root, "rev-parse", "HEAD") == pending_head
    assert pending.exists() and ignored.read_bytes() == b"user workbench bytes\x00"

    # A dirty full-tree migration fails closed without removing unrelated data.
    art._git_without_hooks(art_root, "reset", "--hard", "origin/main")
    pending.unlink()
    art._git(art_root, "sparse-checkout", "disable")
    sentinel = art_root / "custodian/content/sprites/enemies/unrelated/large.png"
    sentinel.write_bytes(b"preserve dirty full-tree file")
    try:
        art.ensure_art_worktree(coordination)
    except art.ArtWorktreeError as error:
        assert "existing checkout was preserved" in str(error)
    else:
        raise AssertionError("dirty full-tree migration did not fail closed")
    assert sentinel.read_bytes() == b"preserve dirty full-tree file"


def launcher_smoke(base: Path) -> None:
    home = base / "home"
    coordination = home / "Projects/CUSTODIAN"
    python = coordination / ".ai/operator-ui-venv/bin/python"
    python.parent.mkdir(parents=True)
    capture = base / "opui-capture.json"
    python.write_text(
        "#!/usr/bin/env python3\n"
        "import json, os, pathlib, sys\n"
        "if sys.argv[1].endswith('operator_art_worktree.py'):\n"
        "    root = pathlib.Path(sys.argv[-1])\n"
        "    print(root.parent / (root.name + '-operator-art'))\n"
        "else:\n"
        "    pathlib.Path(os.environ['OPUI_CAPTURE']).write_text(json.dumps({'args': sys.argv[1:], 'coordination': os.environ.get('CUSTODIAN_COORDINATION_ROOT')}))\n"
    )
    python.chmod(0o755)
    result = subprocess.run(
        ["bash", "-c", f"source {REPO_ROOT / 'tools/custodian_aliases.sh'}; opui --profile fixture"],
        env={**os.environ, "HOME": str(home), "OPUI_CAPTURE": str(capture)},
        text=True, capture_output=True, check=False,
    )
    assert result.returncode == 0, result.stderr
    invocation = json.loads(capture.read_text())
    expected_cli = home / "Projects/CUSTODIAN-operator-art/custodian/tools/operator/operator_cli.py"
    assert invocation["args"] == [str(expected_cli), "ui", "--profile", "fixture"]
    assert invocation["coordination"] == str(coordination)


def lfs_scope_smoke(base: Path) -> None:
    pointer = (
        b"version https://git-lfs.github.com/spec/v1\n"
        b"oid sha256:" + b"0" * 64 + b"\n"
        b"size 123\n"
    )
    operator_png = base / "custodian/content/sprites/operator/source/animations/unarmed/attack/fast_01/operator.png"
    weapon_source_png = base / "custodian/content/sprites/weapons/sword_cleaver/source/operator/heavy.png"
    weapon_runtime_png = base / "custodian/content/sprites/weapons/sword_cleaver/runtime/operator/heavy.png"
    unrelated_png = base / "custodian/content/sprites/weapons/sword_cleaver/source/icon.png"
    for path in (operator_png, weapon_source_png, weapon_runtime_png, unrelated_png):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(pointer)

    detected = {path.relative_to(base).as_posix() for path in art._operator_art_lfs_pointers(base)}
    assert operator_png.relative_to(base).as_posix() in detected
    assert weapon_source_png.relative_to(base).as_posix() in detected
    assert weapon_runtime_png.relative_to(base).as_posix() in detected
    assert unrelated_png.relative_to(base).as_posix() not in detected
    assert "custodian/content/sprites/weapons/*/source/operator/**" in art.OPERATOR_LFS_GLOBS
    assert "custodian/content/sprites/weapons/*/runtime/operator/**" in art.OPERATOR_LFS_GLOBS

    hook_root = base / "lfs-hook-preservation"
    hook = hook_root / ".githooks/post-commit"
    pointer_path = hook_root / "custodian/content/sprites/operator/source/animations/idle.png"
    hook.parent.mkdir(parents=True)
    pointer_path.parent.mkdir(parents=True)
    hook.write_bytes(b"user post-commit hook bytes\n")
    pointer_path.write_bytes(pointer)
    original_run = art.subprocess.run

    def lfs_stub(args, *, cwd=None, **kwargs):
        if args[:3] == ["git", "lfs", "checkout"]:
            hook.write_bytes(b"rewritten LFS post-commit hook\n")
            pointer_path.write_bytes(b"hydrated PNG bytes")
            return subprocess.CompletedProcess(args, 0, "", "")
        return original_run(args, cwd=cwd, **kwargs)

    art.subprocess.run = lfs_stub
    try:
        art.hydrate_operator_art_from_cache(hook_root)
    finally:
        art.subprocess.run = original_run
    assert hook.read_bytes() == b"user post-commit hook bytes\n"
    assert pointer_path.read_bytes() == b"hydrated PNG bytes"


def smoke() -> None:
    with tempfile.TemporaryDirectory(prefix="operator-art-lfs-scope-") as temporary:
        lfs_scope_smoke(Path(temporary))

    with tempfile.TemporaryDirectory(prefix="operator-art-launcher-") as temporary:
        launcher_smoke(Path(temporary))

    with tempfile.TemporaryDirectory(prefix="operator-art-worktree-") as temporary:
        base = Path(temporary)
        _bare, coordination, source = fixture(base)
        source.write_bytes(b"uncommitted coordination art\n")
        art_root = art.ensure_art_worktree(coordination)
        assert art_root == base / "CUSTODIAN-operator-art"
        assert git(art_root, "branch", "--show-current") == art.ART_BRANCH
        assert art.ensure_art_worktree(coordination) == art_root
        ignored = art_root / ".ai/operator_animation_workbench/workbench.aseprite"
        ignored.parent.mkdir(parents=True)
        ignored.write_bytes(b"unsaved authoring bytes")
        assert not art._status_paths(art_root), "ignored Workbench edits must stay outside Git status"
        identity = art.checkout_identity(art_root, coordination)
        assert identity.kind == "DEDICATED ART" and identity.publish_allowed
        main_identity = art.checkout_identity(coordination, coordination)
        assert main_identity.kind == "COORDINATION MAIN" and not main_identity.publish_allowed
        assert source.read_bytes() == b"uncommitted coordination art\n"
        assert SOURCE in art.coordination_operator_changes(coordination)
        assert art._sparse_profile_healthy(art_root), "new checkout did not apply the Operator sparse profile"
        assert not (art_root / "custodian/content/sprites/enemies/unrelated/large.png").exists()
        assert (art_root / "custodian/content/sprites/effects/runtime/muzzle_flash_yellow.png").exists()
        assert not (art_root / "custodian/content/sprites/effects/runtime/unrelated_large_pack.png").exists()
        assert (art_root / "custodian/addons/Sound FX Starter Pack Vol. 1/Motions and Impacts/Impact Vox Hammer.wav").exists()
        assert not (art_root / "custodian/addons/Sound FX Starter Pack Vol. 1/Motions and Impacts/unrelated.wav").exists()
        assert not (art_root / "reports/unrelated/report.json").exists()
        assert not (art_root / "custodian/asset_drop/unrelated/source.png").exists()
        assert "sparse " + art.SPARSE_PROFILE in identity.sparse_profile

        # Existing clean full-tree art checkouts migrate in place; ignored authoring bytes survive.
        art._git(art_root, "sparse-checkout", "disable")
        ignored.write_bytes(b"modified user workbench bytes\x00")
        assert art.ensure_art_worktree(coordination) == art_root
        assert ignored.read_bytes() == b"modified user workbench bytes\x00"
        assert art._sparse_profile_healthy(art_root)
        assert not (art_root / "custodian/content/sprites/enemies/unrelated/large.png").exists()
        assert not art._status_paths(art_root)

        commit_remote(coordination, "README.md", b"unrelated upstream change\n", "unrelated upstream")
        paths = {SOURCE}
        allowlist = art.publication_allowlist(art_root, paths)

        def publish_once():
            (art_root / SOURCE).write_bytes(b"published art\n")
            return [SOURCE]

        result = art.publish_to_main(
            repo_root=art_root, coordination_root=coordination,
            workspace_root=art_root / ".ai/operator_animation_workbench",
            canonical_paths=paths, allowlist=allowlist,
            publish_once=publish_once,
            identity={"profile": "unarmed", "group": "attack", "action": "fast_01", "direction": "e"},
        )
        assert result["status"] == "landed"
        assert SOURCE in result["staged_paths"]
        assert not art._status_paths(art_root)
        git(coordination, "fetch", "origin", "main")
        assert subprocess.run(["git", "merge-base", "--is-ancestor", result["commit"], "origin/main"], cwd=coordination).returncode == 0

        calls = []
        try:
            art.publish_to_main(
                repo_root=coordination, coordination_root=coordination,
                workspace_root=coordination / ".ai/operator_animation_workbench",
                canonical_paths=paths, allowlist=allowlist,
                publish_once=lambda: calls.append(True), identity={"profile": "unarmed"},
            )
        except art.ArtWorktreeError as error:
            assert "PUBLISH DISABLED" in str(error)
        else:
            raise AssertionError("coordination main allowed tracked publish")
        assert not calls

    with tempfile.TemporaryDirectory(prefix="operator-art-conflict-") as temporary:
        _bare, coordination, _source = fixture(Path(temporary))
        art_root = art.ensure_art_worktree(coordination)
        commit_remote(coordination, SOURCE, b"upstream changed selected art\n", "upstream art")
        git(art_root, "fetch", "origin", "main")
        conflicts = art.upstream_source_conflicts(art_root, {SOURCE})
        assert conflicts == {SOURCE}
        calls = []
        try:
            art.publish_to_main(
                repo_root=art_root, coordination_root=coordination,
                workspace_root=art_root / ".ai/operator_animation_workbench",
                canonical_paths={SOURCE}, allowlist=art.publication_allowlist(art_root, {SOURCE}),
                publish_once=lambda: calls.append(True), identity={"profile": "unarmed"},
            )
        except art.ArtWorktreeError as error:
            assert "SOURCE CONFLICT" in str(error)
        else:
            raise AssertionError("same-source upstream change did not block publish")
        assert not calls

    with tempfile.TemporaryDirectory(prefix="operator-art-scope-") as temporary:
        _bare, coordination, _source = fixture(Path(temporary))
        art_root = art.ensure_art_worktree(coordination)
        allowlist = art.publication_allowlist(art_root, {SOURCE})

        def unexpected_output():
            (art_root / SOURCE).write_bytes(b"published")
            (art_root / "unexpected.txt").write_text("preserve")
            return [SOURCE]

        try:
            art.publish_to_main(
                repo_root=art_root, coordination_root=coordination,
                workspace_root=art_root / ".ai/operator_animation_workbench",
                canonical_paths={SOURCE}, allowlist=allowlist,
                publish_once=unexpected_output, identity={"profile": "unarmed"},
            )
        except art.ArtWorktreeError as error:
            assert "PUBLISH OUTPUT BLOCKED" in str(error)
        else:
            raise AssertionError("unexpected output was not rejected")
        assert (art_root / "unexpected.txt").read_text() == "preserve"
        assert not git(art_root, "diff", "--cached", "--name-only")

    with tempfile.TemporaryDirectory(prefix="operator-art-pending-") as temporary:
        bare, coordination, _source = fixture(Path(temporary))
        art_root = art.ensure_art_worktree(coordination)
        hook = bare / "hooks/pre-receive"
        hook.write_text("#!/bin/sh\nexit 1\n")
        hook.chmod(0o755)
        workspace = art_root / ".ai/operator_animation_workbench"
        allowlist = art.publication_allowlist(art_root, {SOURCE})

        def publish_once():
            (art_root / SOURCE).write_bytes(b"pending art\n")
            return [SOURCE]

        try:
            art.publish_to_main(
                repo_root=art_root, coordination_root=coordination, workspace_root=workspace,
                canonical_paths={SOURCE}, allowlist=allowlist, publish_once=publish_once,
                identity={"profile": "unarmed", "action": "attack"},
            )
        except art.ArtWorktreeError as error:
            assert "LAND PENDING" in str(error)
        else:
            raise AssertionError("rejected landing did not become resumable")
        pending = workspace / art.PENDING_RELATIVE.name
        assert pending.exists() and not art._status_paths(art_root)
        hook.unlink()
        resumed = art.retry_pending_land(art_root, pending)
        assert resumed and resumed["status"] == "landed" and not pending.exists()

    with tempfile.TemporaryDirectory(prefix="operator-art-migration-") as temporary:
        _bare, coordination, _source = fixture(Path(temporary))
        legacy = coordination / ".ai/operator_animation_workbench/unarmed/attack/fast_01/e"
        legacy.mkdir(parents=True)
        document = legacy / "workbench.aseprite"
        document.write_bytes(b"exact Aseprite bytes\x00\x01")
        manifest = legacy / "workbench.json"
        manifest.write_text('{"aseprite":{"path":"' + str(document) + '"}}\n')
        old_probe = art._running_aseprite_processes
        art._running_aseprite_processes = lambda: []
        try:
            art_root = art.ensure_art_worktree(coordination)
        finally:
            art._running_aseprite_processes = old_probe
        migrated = art_root / legacy.relative_to(coordination)
        assert (migrated / "workbench.aseprite").read_bytes() == document.read_bytes()
        json_path = json.loads((migrated / "workbench.json").read_text())
        assert json_path["aseprite"]["path"].startswith(str(art_root))
        assert document.exists(), "one-time migration preserves the coordination copy"

    with tempfile.TemporaryDirectory(prefix="operator-art-sparse-sync-") as temporary:
        sparse_sync_smoke(Path(temporary))

    with tempfile.TemporaryDirectory(prefix="operator-art-migration-guard-") as temporary:
        _bare, coordination, _source = fixture(Path(temporary))
        legacy = coordination / ".ai/operator_animation_workbench"
        legacy.mkdir(parents=True)
        old_probe = art._running_aseprite_processes
        art._running_aseprite_processes = lambda: ["aseprite --some-open-document"]
        try:
            try:
                art.ensure_art_worktree(coordination)
            except art.ArtWorktreeError as error:
                assert "close Aseprite" in str(error)
            else:
                raise AssertionError("live Aseprite did not block ignored-workspace migration")
        finally:
            art._running_aseprite_processes = old_probe
        assert legacy.exists()

    print("Operator art worktree smoke: PASS")


if __name__ == "__main__":
    smoke()
