#!/usr/bin/env python3
"""Persistent, isolated checkout authority for Operator Workbench art."""
from __future__ import annotations

import argparse
import filecmp
import fcntl
import json
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


ART_BRANCH = "workbench/operator-art"
OPERATOR_LFS_GLOBS = (
    "custodian/content/sprites/operator/source/animations/**",
    "custodian/content/sprites/operator/runtime/animations/**",
)
PENDING_RELATIVE = Path(".ai/operator_animation_workbench/publish_land_pending.json")
CATALOG_RELATIVE = Path("custodian/content/data/operator/generated/operator_animation_catalog.generated.json")
RESOURCE_NAMES = (
    "operator_runtime_frames.tres", "operator_weapon_frames.tres",
    "operator_melee_overlay_frames.tres", "operator_ranged_fx_frames.tres",
    "operator_modular_lower_body_frames.tres", "operator_modular_upper_body_frames.tres",
    "operator_modular_sidearm_frames.tres", "operator_modular_upper_fx_frames.tres",
    "operator_modular_cape_frames.tres", "operator_modular_head_frames.tres",
    "operator_animation_catalog_frames.tres",
)


class ArtWorktreeError(RuntimeError):
    pass


def _git(root: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=root, text=True, capture_output=True, check=False)
    if check and result.returncode:
        detail = (result.stderr or result.stdout).strip()
        raise ArtWorktreeError(f"git {' '.join(args)} failed: {detail}")
    return result.stdout.strip()


def _top(root: Path) -> Path:
    return Path(_git(root, "rev-parse", "--show-toplevel")).resolve()


def _common(root: Path) -> Path:
    raw = Path(_git(root, "rev-parse", "--git-common-dir"))
    return (root / raw).resolve() if not raw.is_absolute() else raw.resolve()


def default_art_path(coordination_root: Path) -> Path:
    root = _top(Path(coordination_root).resolve())
    return root.parent / f"{root.name}-operator-art"


def _worktrees(root: Path) -> list[tuple[Path, str]]:
    rows: list[tuple[Path, str]] = []
    current: Path | None = None
    branch = ""
    for line in _git(root, "worktree", "list", "--porcelain").splitlines() + [""]:
        if line.startswith("worktree "):
            current = Path(line.removeprefix("worktree ")).resolve()
            branch = ""
        elif line.startswith("branch "):
            branch = line.removeprefix("branch refs/heads/")
        elif not line and current is not None:
            rows.append((current, branch))
            current, branch = None, ""
    return rows


def _operator_art_lfs_pointers(root: Path) -> list[Path]:
    prefixes = (root / "custodian/content/sprites/operator/source/animations", root / "custodian/content/sprites/operator/runtime/animations")
    pointers = []
    for prefix in prefixes:
        if not prefix.exists():
            continue
        for path in prefix.rglob("*.png"):
            try:
                with path.open("rb") as stream:
                    if stream.read(64).startswith(b"version https://git-lfs.github.com/spec/v1"):
                        pointers.append(path)
            except OSError as error:
                raise ArtWorktreeError(f"cannot inspect Operator LFS content: {path}: {error}") from error
    return pointers


def hydrate_operator_art_from_cache(root: Path) -> None:
    """Fill Operator LFS pointer files from the local cache without downloading."""
    pointers = _operator_art_lfs_pointers(root)
    if not pointers:
        return
    result = subprocess.run(["git", "lfs", "checkout", *OPERATOR_LFS_GLOBS], cwd=root, text=True, capture_output=True, check=False)
    if result.returncode:
        raise ArtWorktreeError(f"local Git LFS checkout failed: {(result.stderr or result.stdout).strip()}")
    missing = _operator_art_lfs_pointers(root)
    if missing:
        sample = "\n".join(str(path.relative_to(root)) for path in missing[:5])
        raise ArtWorktreeError(
            "Operator source art is still stored as LFS pointers; local cache is incomplete. "
            "Preserve the checkout and hydrate those assets through the approved LFS workflow:\n" + sample
        )


def _running_aseprite_processes() -> list[str]:
    result = subprocess.run(["ps", "-eo", "args="], text=True, capture_output=True, check=False)
    if result.returncode:
        raise ArtWorktreeError("cannot verify whether Aseprite has an open Workbench document")
    return [line.strip() for line in result.stdout.splitlines() if "aseprite" in line.lower()]


def _rewrite_checkout_paths(value, old_root: str, new_root: str):
    if isinstance(value, str):
        if value == old_root:
            return new_root
        if value.startswith(old_root + os.sep):
            return new_root + value[len(old_root):]
        return value
    if isinstance(value, list):
        return [_rewrite_checkout_paths(item, old_root, new_root) for item in value]
    if isinstance(value, dict):
        return {key: _rewrite_checkout_paths(item, old_root, new_root) for key, item in value.items()}
    return value


def migrate_legacy_workbench(coordination_root: Path, art_root: Path) -> bool:
    """Copy ignored Workbench state once, preserving the coordination copy."""
    old_root = _top(coordination_root)
    new_root = _top(art_root)
    legacy = old_root / ".ai/operator_animation_workbench"
    destination = new_root / ".ai/operator_animation_workbench"
    if not legacy.exists():
        return False
    if destination.exists():
        if any(path.is_symlink() for path in destination.rglob("*")):
            return False
        if any(path.is_file() for path in destination.rglob("*")):
            return False
        shutil.rmtree(destination)
    open_apps = _running_aseprite_processes()
    if open_apps:
        raise ArtWorktreeError(
            "legacy Workbench migration paused: close Aseprite before moving ignored workspace state; "
            "the existing coordination checkout copy was left untouched"
        )
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name(destination.name + ".migration-tmp")
    if temporary.exists():
        raise ArtWorktreeError(f"unfinished Workbench migration exists; inspect before retrying: {temporary}")
    shutil.copytree(legacy, temporary, symlinks=True)
    for path in temporary.rglob("*"):
        if path.is_symlink():
            shutil.rmtree(temporary)
            raise ArtWorktreeError(f"legacy Workbench contains a symlink; migration refused: {path.relative_to(temporary)}")
        if path.is_file() and path.suffix.lower() == ".json":
            try:
                payload = json.loads(path.read_text(encoding="utf-8"))
            except (UnicodeDecodeError, json.JSONDecodeError):
                continue
            rewritten = _rewrite_checkout_paths(payload, str(old_root), str(new_root))
            if rewritten != payload:
                path.write_text(json.dumps(rewritten, indent=2) + "\n", encoding="utf-8")
    os.replace(temporary, destination)
    source_files = {path.relative_to(legacy) for path in legacy.rglob("*") if path.is_file()}
    copied_files = {path.relative_to(destination) for path in destination.rglob("*") if path.is_file()}
    if source_files != copied_files:
        raise ArtWorktreeError("legacy Workbench migration verification found differing file sets")
    for relative in source_files:
        if relative.suffix.lower() != ".json" and not filecmp.cmp(legacy / relative, destination / relative, shallow=False):
            raise ArtWorktreeError(f"legacy Workbench migration changed file bytes: {relative}")
    return True


def ensure_art_worktree(coordination_root: Path, *, art_path: Path | None = None) -> Path:
    """Create or identify the persistent art checkout without touching user edits."""
    root = _top(Path(coordination_root).resolve())
    target = Path(art_path).resolve() if art_path else default_art_path(root)
    common = _common(root)
    lock = common / "operator-art-worktree.lock"
    lock.parent.mkdir(parents=True, exist_ok=True)
    with lock.open("a+") as handle:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
        _git(root, "fetch", "origin", "main")
        attached = _worktrees(root)
        by_branch = [path for path, branch in attached if branch == ART_BRANCH]
        by_path = next((branch for path, branch in attached if path == target), None)
        if by_path is not None:
            if by_path != ART_BRANCH:
                raise ArtWorktreeError(f"art checkout path is attached to unexpected branch {by_path}: {target}")
            migrate_legacy_workbench(root, target)
            hydrate_operator_art_from_cache(target)
            return target
        if by_branch:
            raise ArtWorktreeError(f"{ART_BRANCH} is already attached at {by_branch[0]}")
        if target.exists():
            if any(target.iterdir()):
                raise ArtWorktreeError(f"art checkout path exists but is not an attached worktree: {target}")
            target.rmdir()
        target.parent.mkdir(parents=True, exist_ok=True)
        branch_exists = _git(root, "show-ref", "--verify", f"refs/heads/{ART_BRANCH}", check=False)
        if branch_exists:
            _git(root, "worktree", "add", str(target), ART_BRANCH)
        else:
            _git(root, "worktree", "add", "-b", ART_BRANCH, str(target), "origin/main")
        if _top(target) != target or _git(target, "branch", "--show-current") != ART_BRANCH:
            raise ArtWorktreeError(f"created checkout failed identity verification: {target}")
        migrate_legacy_workbench(root, target)
        hydrate_operator_art_from_cache(target)
        return target


@dataclass(frozen=True)
class CheckoutIdentity:
    kind: str
    branch: str
    worktree: str
    main_relation: str
    publish_allowed: bool
    coordination_root: str


def checkout_identity(repo_root: Path, coordination_root: Path | None = None) -> CheckoutIdentity:
    root = _top(Path(repo_root).resolve())
    coordination = _top(Path(coordination_root).resolve()) if coordination_root else root
    branch = _git(root, "branch", "--show-current") or "detached"
    expected = default_art_path(coordination)
    if root == expected and branch == ART_BRANCH:
        kind, allowed = "DEDICATED ART", True
    elif root == coordination and branch == "main":
        kind, allowed = "COORDINATION MAIN", False
    else:
        kind, allowed = "OTHER CHECKOUT", False
    ref = "refs/remotes/origin/main"
    if _git(root, "show-ref", "--verify", ref, check=False):
        counts = _git(root, "rev-list", "--left-right", "--count", f"HEAD...{ref}").split()
        ahead, behind = (int(value) for value in counts)
        relation = "current" if ahead == behind == 0 else f"ahead {ahead} / behind {behind}"
    else:
        relation = "unknown"
    return CheckoutIdentity(kind, branch, str(root), relation, allowed, str(coordination))


def coordination_operator_changes(coordination_root: Path) -> set[str]:
    root = _top(Path(coordination_root).resolve())
    tracked = set(_git(root, "diff", "--name-only", "HEAD").splitlines())
    prefixes = (
        "custodian/content/sprites/operator/source/animations/",
        "custodian/content/sprites/operator/runtime/animations/",
        "custodian/content/data/operator/generated/operator_animation_catalog.generated.json",
        "custodian/game/actors/operator/",
    )
    return {path for path in tracked if path.startswith(prefixes)}


def _status_paths(root: Path) -> set[str]:
    raw = subprocess.run(
        ["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"],
        cwd=root, capture_output=True, check=True,
    ).stdout
    fields = raw.split(b"\0")
    paths: set[str] = set()
    index = 0
    while index < len(fields):
        record = fields[index]
        index += 1
        if not record:
            continue
        status, path = record[:2].decode(errors="replace"), record[3:].decode(errors="surrogateescape")
        paths.add(Path(path).as_posix())
        if "R" in status or "C" in status:
            if index < len(fields) and fields[index]:
                paths.add(Path(fields[index].decode(errors="surrogateescape")).as_posix())
            index += 1
    return paths


def _add_sidecars(paths: set[str], relative: str) -> None:
    base = Path(relative)
    paths.add(base.as_posix())
    paths.add(Path(f"{relative}.import").as_posix())
    paths.add(base.with_suffix(".animation.json").as_posix())
    source_prefix = "custodian/content/sprites/operator/source/animations/"
    if relative.startswith(source_prefix):
        runtime = relative.replace(source_prefix, "custodian/content/sprites/operator/runtime/animations/", 1)
        paths.add(runtime)
        paths.add(f"{runtime}.import")
        paths.add(str(Path(runtime).with_suffix(".animation.json")))


def publication_allowlist(repo_root: Path, canonical_paths: Iterable[str]) -> set[str]:
    allowed: set[str] = set()
    for path in canonical_paths:
        _add_sidecars(allowed, Path(path).as_posix())
    allowed.add(CATALOG_RELATIVE.as_posix())
    allowed.update((Path("custodian/game/actors/operator") / name).as_posix() for name in RESOURCE_NAMES)
    return allowed


def upstream_source_conflicts(root: Path, canonical_paths: Iterable[str]) -> set[str]:
    """Return selected canonical source paths changed on origin/main since divergence."""
    base = _git(root, "merge-base", "HEAD", "origin/main")
    changed = set(_git(root, "diff", "--no-renames", "--name-only", f"{base}..origin/main").splitlines())
    return changed.intersection(Path(path).as_posix() for path in canonical_paths)


def _pending_path(root: Path, workspace_root: Path | None = None) -> Path:
    return (Path(workspace_root) if workspace_root else root / ".ai/operator_animation_workbench") / PENDING_RELATIVE.name


def _atomic_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(temporary, path)


def _land_and_verify(root: Path, pending: Path, payload: dict) -> dict:
    script = root / "custodian/tools/agent/land_main.py"
    try:
        subprocess.run(
            [sys.executable, str(script), "--approved-operator-publication"],
            cwd=root, check=True,
        )
        _git(root, "fetch", "origin", "main")
        head = _git(root, "rev-parse", "HEAD")
        reachable = subprocess.run(["git", "merge-base", "--is-ancestor", head, "origin/main"], cwd=root, check=False)
        if reachable.returncode:
            raise ArtWorktreeError("land completed but HEAD is not reachable from fresh origin/main")
        payload = {**payload, "status": "landed", "commit": head}
        _atomic_json(pending, payload)
        pending.unlink(missing_ok=True)
        return payload
    except (subprocess.CalledProcessError, ArtWorktreeError) as error:
        payload = {**payload, "status": "land_pending", "error": str(error)}
        _atomic_json(pending, payload)
        raise ArtWorktreeError(f"LAND PENDING\n{error}\nRetry Publish to Main to resume landing without republishing.") from error


def retry_pending_land(root: Path, pending: Path) -> dict | None:
    if not pending.exists():
        return None
    payload = json.loads(pending.read_text(encoding="utf-8"))
    branch = _git(root, "branch", "--show-current")
    head = _git(root, "rev-parse", "HEAD")
    if branch != ART_BRANCH:
        raise ArtWorktreeError("LAND PENDING checkout identity changed; preserve the branch and inspect the pending receipt")
    if _status_paths(root):
        raise ArtWorktreeError("LAND PENDING retry requires a clean art checkout")
    _git(root, "fetch", "origin", "main")
    if subprocess.run(["git", "merge-base", "--is-ancestor", head, "origin/main"], cwd=root, check=False).returncode == 0:
        pending.unlink(missing_ok=True)
        return {**payload, "status": "landed", "commit": head}
    if head != payload.get("commit"):
        raise ArtWorktreeError("LAND PENDING checkout identity changed; preserve the branch and inspect the pending receipt")
    return _land_and_verify(root, pending, payload)


def publish_to_main(
    *, repo_root: Path, coordination_root: Path | None, workspace_root: Path,
    canonical_paths: Iterable[str], allowlist: set[str], publish_once,
    identity: dict[str, str], mirror: bool = False,
) -> dict:
    """Publish once, stage only scoped outputs, commit, and use land_main.py."""
    root = _top(Path(repo_root).resolve())
    checkout = checkout_identity(root, coordination_root)
    if not checkout.publish_allowed:
        if checkout.kind == "COORDINATION MAIN":
            raise ArtWorktreeError("PUBLISH DISABLED\nTracked publish is unsafe from coordination main. Launch OPUI with 'opui' to use the isolated art checkout.")
        raise ArtWorktreeError(f"PUBLISH DISABLED\nTracked publish requires {ART_BRANCH}; current checkout is {checkout.branch}.")
    pending = _pending_path(root, workspace_root)
    resumed = retry_pending_land(root, pending)
    if resumed is not None:
        return resumed
    if _status_paths(root):
        raise ArtWorktreeError("PUBLISH BLOCKED\nThe dedicated art checkout has pre-existing tracked or untracked changes. Preserve them and resolve them before starting another publication.")
    _git(root, "fetch", "origin", "main")
    conflicts = upstream_source_conflicts(root, canonical_paths)
    if conflicts:
        names = "\n".join(sorted(conflicts))
        raise ArtWorktreeError(f"SOURCE CONFLICT\norigin/main changed selected canonical paths since this art checkout diverged:\n{names}\nRefresh/review the selected Workbench before publishing.")
    changed_sources = publish_once()
    changed = _status_paths(root)
    unexpected = changed - allowlist
    if unexpected:
        names = "\n".join(sorted(unexpected))
        raise ArtWorktreeError(f"PUBLISH OUTPUT BLOCKED\nUnexpected changed paths were preserved and not staged:\n{names}")
    if not changed:
        return {"status": "unchanged", "changed_sources": list(changed_sources), "coordination_sync": "not-needed"}
    _git(root, "add", "--", *sorted(changed))
    staged = set(_git(root, "diff", "--cached", "--name-only").splitlines())
    if not staged or staged - allowlist:
        raise ArtWorktreeError("PUBLISH OUTPUT BLOCKED\nVerified staging set did not match the Operator publication allowlist.")
    label = "mirror" if mirror else "direct"
    semantic = "/".join(str(identity.get(key, "")) for key in ("profile", "group", "action", "direction") if identity.get(key))
    summary = f"operator art publish, {semantic}" + (f", {label} counterpart" if mirror else "")
    _git(root, "commit", "-m", summary)
    payload = {
        "schema": "custodian.operator_art_publish_land.v1", "status": "land_pending",
        "commit": _git(root, "rev-parse", "HEAD"), "branch": ART_BRANCH,
        "identity": identity, "summary": summary,
    }
    _atomic_json(pending, payload)
    landed = _land_and_verify(root, pending, payload)
    landed["changed_sources"] = list(changed_sources)
    landed["staged_paths"] = sorted(staged)
    return landed


def best_effort_coordination_sync(coordination_root: Path | None) -> str:
    if not coordination_root:
        return "not-configured"
    root = _top(Path(coordination_root).resolve())
    if _git(root, "branch", "--show-current") != "main":
        return "pending: coordination checkout is not on main"
    if _status_paths(root):
        return "pending: coordination checkout has local changes"
    result = subprocess.run(["git", "pull", "--ff-only", "origin", "main"], cwd=root, text=True, capture_output=True)
    if result.returncode:
        return "pending: " + (result.stderr or result.stdout).strip()
    return "synced"


def _main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    ensure = sub.add_parser("ensure", help="create or identify the persistent art worktree")
    ensure.add_argument("--coordination-root", type=Path, required=True)
    ensure.add_argument("--art-path", type=Path)
    args = parser.parse_args()
    try:
        preserved = coordination_operator_changes(args.coordination_root)
        if preserved:
            print(
                "operator-art-worktree: coordination checkout contains tracked Operator changes; "
                "they were preserved and need explicit recovery: " + ", ".join(sorted(preserved)),
                file=sys.stderr,
            )
        art_root = ensure_art_worktree(args.coordination_root, art_path=args.art_path)
        print(art_root)
        return 0
    except (ArtWorktreeError, OSError) as error:
        print(f"operator-art-worktree: BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(_main())
