#!/usr/bin/env python3
"""Fixture-isolated checks that `operator anim publish` obeys the shared publication boundary."""
from __future__ import annotations

import contextlib
import hashlib
import io
import json
import os
import sys
import tempfile
from pathlib import Path
from PIL import Image

OPERATOR_TOOLS = Path(__file__).resolve().parents[1] / "operator"
sys.path.insert(0, str(OPERATOR_TOOLS))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import animation_workbench as w
import animation_workbench_model as m
import operator_art_worktree as art
import operator_cli
from ui import service as ui_service
from operator_art_worktree_smoke import SOURCE, CANONICAL_RUNTIME_FRAMES, commit_remote, fixture, git

IDENTITY = {"profile": "unarmed", "group": "attack", "action": "fast_01", "direction": "e"}
OTHER_SOURCE = "custodian/content/sprites/operator/source/animations/unarmed/attack/fast_02/lower_body__operator__unarmed__attack__fast_02__e__6f__96.png"
PUBLISHED = b"cli published art\n"


def digest(root: Path) -> dict[str, str | None]:
    return {
        relative: hashlib.sha256((root / relative).read_bytes()).hexdigest() if (root / relative).is_file() else None
        for relative in (SOURCE, CANONICAL_RUNTIME_FRAMES)
    }


def run_cli(repo_root: Path, coordination: Path, *extra: str, tamper_initially: bool = False, tamper_after_prepare: bool = False):
    """Run operator_cli.main against the fixture checkout with the Aseprite backend stubbed."""
    workspace_root = repo_root / ".ai/operator_animation_workbench"
    events: list[str] = []
    publish_calls: list[dict] = []
    semantic = {"owner": "operator", "layer": "lower_body", "profile": "unarmed", "group": "attack", "action": "fast_01", "direction": "e"}
    binding = {
        **semantic, "binding_id": "lower_body", "source_path": SOURCE,
        "semantic_identity": dict(semantic), "source_contract": {"path": SOURCE, "frames": 6, "frame_size": [96, 96]},
        "publish_contract": {"path": SOURCE, "frames": 6, "frame_size": [96, 96]},
    }
    manifest_data = {"identity": dict(IDENTITY), "layers": [binding]}

    def retarget_manifest():
        alternate_sha = m.file_sha256(repo_root / OTHER_SOURCE)
        alternate_pixels = m.pixel_sha256(repo_root / OTHER_SOURCE)
        manifest_data["layers"][0].update({
            "source_path": OTHER_SOURCE,
            "source_file_sha256": alternate_sha,
            "source_pixel_sha256": alternate_pixels,
            "source_contract": {"path": OTHER_SOURCE, "frames": 6, "frame_size": [96, 96],
                                "file_sha256": alternate_sha, "pixel_sha256": alternate_pixels},
            "publish_contract": {"path": OTHER_SOURCE, "frames": 6, "frame_size": [96, 96]},
        })

    if tamper_initially:
        retarget_manifest()

    def fake_publish(manifest, aseprite=None, force_stale=False, dry_run=False, *_rest):
        events.append("publish")
        publish_calls.append({"force_stale": force_stale, "dry_run": dry_run})
        if not dry_run:
            (repo_root / SOURCE).write_bytes(PUBLISHED)
        return [SOURCE]

    def wrap(name, original):
        def wrapped(*args, **kwargs):
            events.append(name)
            result = original(*args, **kwargs)
            if name == "prepare" and tamper_after_prepare:
                retarget_manifest()
            return result
        return wrapped

    plan_binding = {
        **semantic, "binding_id": "lower_body", "source_path": SOURCE,
        "semantic_identity": dict(semantic), "source_contract": {"path": SOURCE, "frames": 6, "frame_size": [96, 96]},
        "publish_contract": {"path": SOURCE, "frames": 6, "frame_size": [96, 96]},
    }

    real_service = ui_service.WorkbenchService
    patches = [
        (m, "build_plan", lambda *_a, **_k: {"identity": dict(IDENTITY), "layers": [plan_binding]}),
        (w, "workspace", lambda root, _identity: Path(root) / "unarmed/attack/fast_01/e"),
        (w, "load", lambda _path: manifest_data),
        (w, "source_contract_freshness", lambda *_a, **_k: {}),
        (w, "horizontal_counterpart", lambda _direction: None),
        (w, "publish", fake_publish),
        (art, "prepare_publish_checkout", wrap("prepare", art.prepare_publish_checkout)),
        (art, "inspect_publish_readiness", wrap("inspect", art.inspect_publish_readiness)),
        (ui_service, "WorkbenchService", lambda **kwargs: real_service(repo_root=repo_root, **kwargs)),
    ]
    saved = [(owner, name, getattr(owner, name)) for owner, name, _ in patches]
    old_env, old_argv = os.environ.get("CUSTODIAN_COORDINATION_ROOT"), sys.argv
    os.environ["CUSTODIAN_COORDINATION_ROOT"] = str(coordination)
    for owner, name, value in patches:
        setattr(owner, name, value)
    sys.argv = ["operator", "anim", "publish", IDENTITY["profile"], IDENTITY["action"], IDENTITY["direction"], "--workspace-root", str(workspace_root),
                "--no-mirror-counterpart", "--json", *extra]
    out, err = io.StringIO(), io.StringIO()
    try:
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            try:
                code = operator_cli.main()
            except SystemExit as error:
                code = error.code
    finally:
        sys.argv = old_argv
        for owner, name, value in saved:
            setattr(owner, name, value)
        if old_env is None:
            os.environ.pop("CUSTODIAN_COORDINATION_ROOT", None)
        else:
            os.environ["CUSTODIAN_COORDINATION_ROOT"] = old_env
    if code not in (0, 2):
        raise AssertionError(f"unexpected exit {code}: {err.getvalue()}")
    return code, out.getvalue(), err.getvalue(), events, publish_calls


def assert_blocked(repo_root, coordination, label, *extra, expect=""):
    before, head = digest(repo_root), git(repo_root, "rev-parse", "HEAD")
    status = git(repo_root, "status", "--porcelain")
    code, _out, err, events, calls = run_cli(repo_root, coordination, *extra)
    assert code == 2, f"{label}: expected fail-closed exit 2, got {code}\n{err}"
    assert not calls, f"{label}: canonical-mutating publish ran"
    assert "publish" not in events, label
    assert expect in err, f"{label}: blocker not actionable: {err!r}"
    assert digest(repo_root) == before, f"{label}: canonical hashes changed"
    assert git(repo_root, "rev-parse", "HEAD") == head, f"{label}: commit created"
    assert git(repo_root, "status", "--porcelain") == status, f"{label}: tracked/untracked state changed"


def smoke() -> None:
    with tempfile.TemporaryDirectory(prefix="operator-cli-publish-") as temporary:
        _bare, coordination, _source = fixture(Path(temporary))
        art_root = art.ensure_art_worktree(coordination)

        assert_blocked(coordination, coordination, "coordination main", expect="COORDINATION MAIN")
        assert_blocked(coordination, coordination, "coordination main + stale override",
                       "--force-stale-source", expect="COORDINATION MAIN")

        # Dry-run never replaces canonical files, commits, or lands.
        before, head = digest(coordination), git(coordination, "rev-parse", "HEAD")
        code, _out, err, _events, calls = run_cli(coordination, coordination, "--dry-run")
        assert code == 0, err
        assert calls == [{"force_stale": False, "dry_run": True}]
        assert digest(coordination) == before and git(coordination, "rev-parse", "HEAD") == head

        git(art_root, "checkout", "--detach")
        assert_blocked(art_root, coordination, "detached checkout", "--force-stale-source", expect="OTHER CHECKOUT")
        git(art_root, "checkout", art.ART_BRANCH)

        (art_root / "unrelated_dirt.txt").write_text("preserve me")
        assert_blocked(art_root, coordination, "dirty art checkout", "--force-stale-source", expect="unrelated_dirt.txt")
        assert (art_root / "unrelated_dirt.txt").read_text() == "preserve me"
        (art_root / "unrelated_dirt.txt").unlink()

        # A fully rebound manifest with coherent path metadata still cannot retarget another valid source.
        alternate = Image.new("RGBA", (96 * 6, 96), (15, 20, 25, 255))
        encoded = io.BytesIO(); alternate.save(encoded, format="PNG")
        commit_remote(coordination, OTHER_SOURCE, encoded.getvalue(), "fixture alternate Operator source")
        git(art_root, "fetch", "origin", "main")
        git(art_root, "merge", "--ff-only", "origin/main")
        # Keep main and the art checkout aligned to the same fixture head for readiness.
        before, head, status = digest(art_root), git(art_root, "rev-parse", "HEAD"), git(art_root, "status", "--porcelain")
        code, _out, err, events, calls = run_cli(art_root, coordination, tamper_initially=True)
        assert code == 2 and "SOURCE PATH DOES NOT MATCH THE SELECTED ANIMATION PLAN" in err, err
        assert not calls and "publish" not in events, (events, calls)
        assert digest(art_root) == before and git(art_root, "rev-parse", "HEAD") == head
        assert git(art_root, "status", "--porcelain") == status

        # A manifest changed after initial preparation is reloaded and rejected at the final boundary.
        before, head, status = digest(art_root), git(art_root, "rev-parse", "HEAD"), git(art_root, "status", "--porcelain")
        code, _out, err, events, calls = run_cli(art_root, coordination, tamper_after_prepare=True)
        assert code == 2 and "SOURCE PATH DOES NOT MATCH THE SELECTED ANIMATION PLAN" in err, err
        assert events[0] == "prepare" and "publish" not in events and not calls, (events, calls)
        assert digest(art_root) == before and git(art_root, "rev-parse", "HEAD") == head
        assert git(art_root, "status", "--porcelain") == status

        before = digest(art_root)
        code, out, err, events, calls = run_cli(art_root, coordination)
        assert code == 0, err
        assert events[0] == "prepare" and events[-2:] == ["inspect", "publish"], events
        assert calls == [{"force_stale": False, "dry_run": False}]
        result = json.loads(out)
        assert result["status"] == "landed", result
        assert result["staged_paths"] == [SOURCE], result["staged_paths"]
        assert set(result["staged_paths"]) <= art.publication_allowlist(art_root, {SOURCE})
        assert digest(art_root)[SOURCE] != before[SOURCE]
        git(coordination, "fetch", "origin", "main")
        assert git(coordination, "show", f"origin/main:{SOURCE}") == PUBLISHED.decode().strip()
        assert not art._status_paths(art_root)
    print("Operator CLI publish boundary smoke: PASS")


if __name__ == "__main__":
    smoke()
