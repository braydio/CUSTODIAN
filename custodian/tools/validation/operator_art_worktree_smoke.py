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
    source.parent.mkdir(parents=True)
    source.write_bytes(b"original canonical art\n")
    git(coordination, "add", ".gitignore", SOURCE, "custodian/tools/agent/land_main.py")
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
