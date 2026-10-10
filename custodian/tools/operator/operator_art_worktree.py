#!/usr/bin/env python3
"""Persistent, isolated checkout authority for Operator Workbench art."""
from __future__ import annotations

import argparse
import filecmp
import fcntl
import hashlib
import json
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Iterable


ART_BRANCH = "workbench/operator-art"
SPARSE_PROFILE = "operator-authoring-v1"
SPARSE_PROFILE_PATHS = (
    ".githooks",
    "tools/validate_filenames.py",
    "tools/custodian_aliases.sh",
    "custodian/project.godot",
    "custodian/AGENTS.md",
    "custodian/game",
    "custodian/autoload",
    "custodian/debug",
    "custodian/addons/godot_ai/runtime/game_helper.gd",
    "custodian/addons/godot_ai/runtime",
    "custodian/addons/godot_ai/utils",
    "custodian/addons/dev-console",
    "custodian/tools/operator",
    "custodian/tools/aseprite",
    "custodian/tools/art",
    "custodian/tools/assets",
    "custodian/tools/pipelines",
    "custodian/tools/agent",
    "custodian/tools/validation",
    "custodian/tools/godot_project_lock.py",
    "custodian/content/data/operator",
    "custodian/content/resources/resource_defs.json",
    "custodian/content/fabrication/fab_recipes.json",
    "custodian/content/metadata/assets",
    "custodian/content/sprites/operator",
    "custodian/assets/resources/vfx/weapons/carbine_mk1",
    "custodian/assets/sprites/world/ingress/ash_bell",
    "custodian/content/backgrounds/procgen/drowned_basilica",
    "custodian/content/backgrounds/procgen/endless_forest",
    "custodian/content/backgrounds/procgen/depth_chunks",
    "custodian/content/backgrounds/procgen/depth_chunks/scrubland",
    "custodian/content/backgrounds/procgen/depth_chunks/universal",
    "custodian/content/backgrounds/procgen/depth_chunks/woodland",
    "custodian/content/procgen/biomes",
    "custodian/content/procgen/dressing_clusters",
    "custodian/content/procgen/presentation",
    "custodian/content/props/ruins",
    "custodian/content/runtime/sundered_keep/terrain/ocean",
    "custodian/content/sprites/effects/combat/critical",
    "custodian/content/sprites/effects/weapons/carbine_mk1",
    "custodian/content/sprites/environment/props/portal_ring/runtime/fx",
    "custodian/scenes/debug/dev_observatory_overlay.tscn",
    "custodian/scripts/debug/dev_observatory_overlay.gd",
    "custodian/content/sprites/weapons/melee/1-hand",
    "custodian/content/sprites/weapons/carbine_mk1/runtime",
    "custodian/content/sprites/effects/combat/status",
    "custodian/content/sprites/effects/combat/unarmed",
    "custodian/content/sprites/effects/runtime/block_spark",
    "custodian/content/sprites/effects/runtime/hit_spark",
    "custodian/content/sprites/effects/runtime/motion",
    "custodian/content/sprites/effects/runtime/muzzle_flash_yellow.png",
    "custodian/content/sprites/world/lighting",
    "custodian/content/sprites/world/shadows",
    "custodian/content/sprites/world/ingress/ash_bell",
    "custodian/content/sprites/environment/props/vault_storage/runtime",
    "custodian/content/audio/sfx/ambience",
    "custodian/content/audio/sfx/combat",
    "custodian/content/audio/sfx/healing",
    "custodian/content/audio/sfx/environment",
    "custodian/content/audio/sfx/structures",
    "custodian/content/spriteframes/effects/combat",
    "custodian/content/tiles/encounters/ritualant_set/underground",
    "custodian/content/tiles/elevation/industrial",
    "custodian/content/tiles/interiors/runtime",
    "custodian/content/tiles/interiors/temp",
    "custodian/content/tiles/mountain_cliffs",
    "custodian/content/tiles/mountain_cliffs/void_fascia",
    "custodian/content/tiles/procgen/atlases",
    "custodian/content/tiles/procgen_macro/runtime/meridian_hardstand",
    "custodian/content/tiles/procgen_macro/runtime/rocky_upland",
    "custodian/content/tiles/procgen/surfaces/hardened",
    "custodian/content/tiles/source/placeholder-tileset/0x72_DungeonTilesetII_v1.7",
    "custodian/content/tiles/sundered_keep/floors",
    "custodian/content/tiles/terrain/runtime/ascent",
    "custodian/content/tiles/terrain/runtime/chasm_bridge",
    "custodian/content/tiles/terrain/runtime/connector",
    "custodian/content/tiles/tilesets/procgen_world_tileset.tres",
    "custodian/content/tiles/walls/generated",
    "custodian/addons/Sound FX Starter Pack Vol. 1/Motions and Impacts/Impact Vox Hammer.wav",
    "design/02_features/animation",
)
OPERATOR_LFS_GLOBS = (
    "custodian/content/sprites/operator/source/animations/**",
    "custodian/content/sprites/operator/runtime/animations/**",
    "custodian/content/sprites/weapons/*/source/operator/**",
    "custodian/content/sprites/weapons/*/runtime/operator/**",
)
PENDING_RELATIVE = Path(".ai/operator_animation_workbench/publish_land_pending.json")
CATALOG_RELATIVE = Path("custodian/content/data/operator/generated/operator_animation_catalog.generated.json")
CANONICAL_RUNTIME_FRAMES = Path("custodian/content/sprites/operator/runtime/operator_runtime_frames.tres")


class ArtWorktreeError(RuntimeError):
    pass


@dataclass(frozen=True)
class PublishReadiness:
    status: str
    checkout: dict[str, str | bool]
    pending_land: bool
    dirty: dict[str, tuple[str, ...]]
    sparse_healthy: bool
    dependencies: dict[str, tuple[str, ...]]
    transaction: dict[str, str] | None
    source_freshness: dict[str, str]
    preparations: tuple[str, ...]
    blockers: tuple[str, ...]

    def as_dict(self) -> dict:
        return {
            "status": self.status,
            "checkout": dict(self.checkout),
            "pending_land": self.pending_land,
            "dirty": {key: list(value) for key, value in self.dirty.items()},
            "sparse_healthy": self.sparse_healthy,
            "dependencies": {key: list(value) for key, value in self.dependencies.items()},
            "transaction": self.transaction,
            "source_freshness": dict(self.source_freshness),
            "preparations": list(self.preparations),
            "blockers": list(self.blockers),
        }


def _git(root: Path, *args: str, check: bool = True) -> str:
    result = subprocess.run(["git", *args], cwd=root, text=True, capture_output=True, check=False)
    if check and result.returncode:
        detail = (result.stderr or result.stdout).strip()
        raise ArtWorktreeError(f"git {' '.join(args)} failed: {detail}")
    return result.stdout.strip()


def _git_without_hooks(root: Path, *args: str) -> str:
    """Run a checkout-only synchronization command without mutating repository hooks."""
    result = subprocess.run(
        ["git", "-c", "core.hooksPath=/dev/null", *args], cwd=root,
        text=True, capture_output=True, check=False,
        env={**os.environ, "GIT_LFS_SKIP_SMUDGE": "1"},
    )
    if result.returncode:
        raise ArtWorktreeError(f"git {' '.join(args)} failed: {(result.stderr or result.stdout).strip()}")
    return result.stdout.strip()


def _sparse_paths(root: Path) -> list[str]:
    """Return existing profile paths plus tracked Godot sidecars for explicit files."""
    def tracked(relative: str) -> bool:
        return subprocess.run(
            ["git", "cat-file", "-e", f"HEAD:{relative}"], cwd=root,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False,
        ).returncode == 0

    def tracked_directory(relative: str) -> bool:
        return subprocess.run(
            ["git", "cat-file", "-e", f"HEAD:{relative}/."], cwd=root,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False,
        ).returncode == 0

    paths = [path for path in SPARSE_PROFILE_PATHS if tracked(path)]
    # Explicit one-file dependencies must bring their already-tracked Godot metadata
    # with them. Otherwise Godot recreates the omitted sidecar during validation and
    # the publish firewall correctly rejects that unrelated worktree change.
    for path in tuple(paths):
        if tracked_directory(path):
            continue
        for suffix in (".import", ".uid"):
            sidecar = f"{path}{suffix}"
            if tracked(sidecar):
                paths.append(sidecar)

    weapon_tree = "custodian/content/sprites/weapons"
    listing = subprocess.run(
        ["git", "ls-tree", "-d", "--name-only", f"HEAD:{weapon_tree}"],
        cwd=root, text=True, capture_output=True, check=False,
    )
    if listing.returncode == 0:
        for family in listing.stdout.splitlines():
            for role in ("source", "runtime"):
                relative = f"{weapon_tree}/{family}/{role}/operator"
                if tracked(relative):
                    paths.append(relative)
    patterns = []
    for path in sorted(set(paths)):
        # Sparse-checkout's non-cone patterns let the one-file runtime dependencies
        # stay narrow instead of materializing their unrelated sibling directories.
        patterns.append(f"/{path}/**" if tracked_directory(path) else f"/{path}")
    return patterns


def _sparse_profile_enabled(root: Path) -> bool:
    return _git(root, "config", "--bool", "core.sparseCheckout", check=False) == "true"


def _sparse_profile_healthy(root: Path) -> bool:
    if not _sparse_profile_enabled(root):
        return False
    configured = set(_git(root, "sparse-checkout", "list", check=False).splitlines())
    return set(_sparse_paths(root)) == configured


def _apply_sparse_profile(root: Path) -> None:
    paths = _sparse_paths(root)
    if not paths:
        raise ArtWorktreeError("Operator sparse profile has no paths present in this checkout")
    _git_without_hooks(root, "sparse-checkout", "init", "--no-cone")
    _git_without_hooks(root, "sparse-checkout", "set", "--no-cone", *paths)


def _main_counts(root: Path) -> tuple[int, int]:
    counts = _git(root, "rev-list", "--left-right", "--count", f"HEAD...origin/main").split()
    if len(counts) != 2:
        raise ArtWorktreeError("cannot determine Operator art checkout relation to origin/main")
    return int(counts[0]), int(counts[1])


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


def _parse_lfs_pointer(data: bytes) -> tuple[str, int] | None:
    if not data.startswith(b"version https://git-lfs.github.com/spec/v1\n"):
        return None
    try:
        fields = dict(line.decode("ascii").split(" ", 1) for line in data.splitlines()[1:])
        oid = fields["oid"]
        if not oid.startswith("sha256:"):
            return None
        return oid[7:], int(fields["size"])
    except (KeyError, UnicodeDecodeError, ValueError):
        return None


def _tracked_checkout_paths(root: Path) -> tuple[list[str], list[str]]:
    """Return sparse-present tracked files and selected paths missing from disk."""
    result = subprocess.run(["git", "ls-files", "-t", "-z"], cwd=root, capture_output=True, check=True)
    present: list[str] = []
    missing: list[str] = []
    for entry in result.stdout.split(b"\0"):
        if not entry:
            continue
        flag, _, raw_path = entry.partition(b" ")
        if flag == b"S":  # sparse-checkout intentionally omits this path
            continue
        relative = raw_path.decode("utf-8", "surrogateescape")
        if (root / relative).is_file():
            present.append(relative)
        else:
            missing.append(relative)
    return present, missing


def checked_out_lfs_pointers(root: Path) -> list[tuple[str, str, int]]:
    """Discover LFS pointer stubs only among tracked files materialized by sparse checkout."""
    present, _missing = _tracked_checkout_paths(root)
    pointers = []
    for relative in present:
        path = root / relative
        try:
            with path.open("rb") as stream:
                pointer = _parse_lfs_pointer(stream.read(1024))
        except OSError as error:
            raise ArtWorktreeError(f"cannot inspect checked-out dependency {relative}: {error}") from error
        if pointer:
            pointers.append((relative, *pointer))
    return pointers


def _operator_art_lfs_pointers(root: Path) -> list[Path]:
    """Compatibility discovery helper limited to Operator source/runtime art."""
    root=Path(root); prefixes=[root/"custodian/content/sprites/operator/source/animations",root/"custodian/content/sprites/operator/runtime/animations"]
    weapons=root/"custodian/content/sprites/weapons"
    if weapons.is_dir():
        prefixes.extend(weapons.glob("*/source/operator")); prefixes.extend(weapons.glob("*/runtime/operator"))
    result=[]
    for prefix in prefixes:
        if prefix.is_dir():
            for path in prefix.rglob("*.png"):
                try:
                    if _parse_lfs_pointer(path.read_bytes()[:1024]): result.append(path)
                except OSError as error:
                    raise ArtWorktreeError(f"cannot inspect Operator LFS content: {path}: {error}") from error
    return result


def hydrate_lfs_paths(root: Path, paths: Iterable[str], donor_root: Path | None = None) -> list[str]:
    """Hydrate exact checked-out LFS paths from cache, then verified local donor bytes."""
    root = _top(Path(root).resolve())
    exact = sorted(set(Path(path).as_posix() for path in paths))
    if any(Path(path).is_absolute() or ".." in Path(path).parts for path in exact):
        raise ArtWorktreeError("LFS hydration accepts only repository-relative paths")
    pointers = []
    for relative in exact:
        target = root / relative
        if target.is_file():
            pointer = _parse_lfs_pointer(target.read_bytes())
        else:
            blob = subprocess.run(["git", "show", f"HEAD:{relative}"], cwd=root, capture_output=True, check=False)
            pointer = _parse_lfs_pointer(blob.stdout) if blob.returncode == 0 else None
        if pointer is None:
            continue
        pointers.append((relative, *pointer))
    if not pointers:
        return []
    hook = root / ".githooks/post-commit"
    had_hook = hook.exists()
    hook_bytes = hook.read_bytes() if had_hook else b""
    hook_mode = hook.stat().st_mode & 0o777 if had_hook else 0o755
    # Exact path arguments prevent Git LFS from hydrating sparse-omitted siblings.
    result = subprocess.run(["git", "lfs", "checkout", *(relative for relative, _oid, _size in pointers)], cwd=root, text=True, capture_output=True, check=False)
    # Some Git LFS installations rewrite core.hooksPath's post-commit hook.
    # Treat that tracked repository file as user state and retain its exact bytes.
    if had_hook:
        if not hook.exists() or hook.read_bytes() != hook_bytes:
            hook.write_bytes(hook_bytes)
            hook.chmod(hook_mode)
    else:
        hook.unlink(missing_ok=True)
    # Git LFS may return success while objects are absent; verify by hash and size.
    donor = _top(Path(donor_root).resolve()) if donor_root else None
    unresolved = []
    hydrated = []
    for relative, oid, size in pointers:
        target = root / relative
        if target.is_file():
            content = target.read_bytes()
            if len(content) == size and hashlib.sha256(content).hexdigest() == oid:
                hydrated.append(relative)
                continue
        source = (donor / relative) if donor else None
        if source and source.is_file():
            content = source.read_bytes()
            if len(content) == size and hashlib.sha256(content).hexdigest() == oid:
                cached=subprocess.run(["git","lfs","clean",relative],cwd=root,input=content,capture_output=True,check=False)
                cached_pointer=_parse_lfs_pointer(cached.stdout or b"")
                if cached.returncode!=0 or cached_pointer!=(oid,size):
                    unresolved.append(f"{relative} (verified donor bytes could not be cached locally)")
                    continue
                temporary = target.with_name(target.name + ".hydrate-tmp")
                temporary.write_bytes(content)
                os.replace(temporary, target)
                hydrated.append(relative)
                continue
        unresolved.append(f"{relative} (sha256:{oid}, size:{size})")
    if hydrated:
        # Refresh only the exact verified files' stat cache; this does not stage
        # content and lets Git/LFS recognize the smudged bytes as their pointer.
        subprocess.run(["git","update-index","--refresh","--",*hydrated],cwd=root,capture_output=True,check=False)
    dirty = _status_paths(root)
    if dirty:
        raise ArtWorktreeError("LFS hydration changed Git-visible paths unexpectedly; preserve for inspection: " + ", ".join(sorted(dirty)))
    if unresolved:
        raise ArtWorktreeError("REQUIRED LFS CONTENT UNAVAILABLE LOCALLY; network fetch is disabled:\n" + "\n".join(unresolved))
    return hydrated


def hydrate_operator_art_from_cache(root: Path) -> None:
    """Compatibility wrapper for the explicit Operator art path resolver."""
    pointers = [path for path, _oid, _size in checked_out_lfs_pointers(root)
                if path.startswith(("custodian/content/sprites/operator/", "custodian/content/sprites/weapons/"))]
    hydrate_lfs_paths(root, pointers)


def _transaction_status(workspace_root: Path) -> dict[str, str] | None:
    transactions = Path(workspace_root) / "transactions"
    if not transactions.is_dir():
        return None
    for journal_path in sorted(transactions.glob("*/transaction.json"), reverse=True):
        try:
            payload = json.loads(journal_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return {"state": "UNREADABLE", "journal": str(journal_path)}
        state = str(payload.get("state", "UNKNOWN"))
        if state not in {"COMMITTED", "ROLLED_BACK"}:
            return {"state": state, "journal": str(journal_path)}
    return None


def _dirty_categories(root: Path, selected_paths: Iterable[str] = ()) -> dict[str, tuple[str, ...]]:
    selected = set(Path(path).as_posix() for path in selected_paths)
    categories: dict[str, list[str]] = {"user": [], "import_metadata": [], "selected_outputs": []}
    for relative in sorted(_status_paths(root)):
        if relative in selected:
            category = "selected_outputs"
        elif relative.endswith((".import", ".uid")):
            category = "import_metadata"
        else:
            category = "user"
        categories[category].append(relative)
    return {key: tuple(paths) for key, paths in categories.items() if paths}


def inspect_publish_readiness(
    repo_root: Path,
    coordination_root: Path | None,
    workspace_root: Path,
    *,
    selected_paths: Iterable[str] = (),
    source_freshness: dict[str, str] | None = None,
) -> PublishReadiness:
    """Read-only snapshot used by startup status and the Publish review boundary."""
    root = _top(Path(repo_root).resolve())
    identity = checkout_identity(root, coordination_root)
    pending_path = _pending_path(root, workspace_root)
    pending = pending_path.exists()
    dirty = _dirty_categories(root, selected_paths)
    sparse = _sparse_profile_healthy(root)
    if identity.publish_allowed:
        present, missing = _tracked_checkout_paths(root)
        pointers = [f"{path} (sha256:{oid}, size:{size})" for path, oid, size in checked_out_lfs_pointers(root)]
    else:
        present, missing, pointers = [], [], []
    ordinary_missing = []
    for relative in missing:
        blob = subprocess.run(["git", "show", f"HEAD:{relative}"], cwd=root, capture_output=True, check=False)
        pointer = _parse_lfs_pointer(blob.stdout) if blob.returncode == 0 else None
        if pointer:
            pointers.append(f"{relative} (sha256:{pointer[0]}, size:{pointer[1]})")
        else:
            ordinary_missing.append(relative)
    transaction = _transaction_status(workspace_root)
    freshness = source_freshness or {}
    dependencies = {key: tuple(value) for key, value in {
        "missing": ordinary_missing,
        "lfs_pointers": pointers,
    }.items() if value}
    blockers = []
    preparations = []
    if not identity.publish_allowed:
        blockers.append(f"tracked publication requires {ART_BRANCH}; checkout is {identity.kind} ({identity.branch})")
    if pending:
        blockers.append("LAND PENDING must use the existing retry path")
    if transaction:
        blockers.append(f"Workbench transaction {transaction['state']} requires recovery: {transaction['journal']}")
    if dirty:
        for category, paths in dirty.items():
            blockers.append(f"{category} changes must be preserved and reviewed: " + ", ".join(paths))
    if freshness:
        blockers.extend(f"WORKBENCH REBASE/REFRESH REQUIRED: {identity}: {reason}" for identity, reason in freshness.items())
    if not sparse:
        preparations.append(f"reapply sparse profile {SPARSE_PROFILE} if the clean checkout permits")
    relation = identity.main_relation
    if relation.startswith("ahead"):
        blockers.append(f"art checkout has local commits ahead of origin/main: {relation}")
    elif relation.startswith("unknown"):
        blockers.append("origin/main relation cannot be verified")
    elif relation != "current":
        preparations.append("fetch origin/main and fast-forward the clean, non-ahead art branch")
    if pointers:
        preparations.append("hydrate checked-out LFS dependencies from local cache or exact verified donor")
    if ordinary_missing:
        blockers.extend(f"required sparse dependency is missing: {path}" for path in ordinary_missing)
    if blockers:
        status = "blocked"
    elif preparations:
        status = "preparable"
    else:
        status = "ready"
    checkout = {
        "kind": identity.kind, "branch": identity.branch,
        "main_relation": identity.main_relation, "worktree": identity.worktree,
        "sparse_profile": identity.sparse_profile, "worktree_state": identity.worktree_state,
        "publish_allowed": identity.publish_allowed,
    }
    return PublishReadiness(status, checkout, pending, dirty, sparse, dependencies,
                            transaction, freshness, tuple(preparations), tuple(blockers))


def prepare_publish_checkout(
    repo_root: Path,
    coordination_root: Path | None,
    workspace_root: Path,
    *,
    selected_paths: Iterable[str] = (),
    source_freshness: dict[str, str] | None = None,
) -> PublishReadiness:
    """Run only clean fast-forward, sparse-profile, and local-only dependency preparation."""
    root = _top(Path(repo_root).resolve())
    before = inspect_publish_readiness(root, coordination_root, workspace_root,
                                       selected_paths=selected_paths,
                                       source_freshness=source_freshness)
    if before.pending_land or before.transaction or before.dirty or not before.checkout["publish_allowed"]:
        return before
    if before.source_freshness:
        return before
    performed=[]
    if coordination_root is None:
        return replace(before, status="blocked", blockers=before.blockers + (
            "persistent coordination checkout is not configured; shared synchronization is unavailable",
        ))
    sync = _persistent_sync_module().apply_profiles(["operator-art"], Path(coordination_root).resolve(), root)[0]
    if sync.state not in {"CURRENT", "SYNCED"}:
        return replace(before, status="blocked", blockers=before.blockers + (
            _persistent_sync_module().format_result(sync),
        ))
    if sync.state == "SYNCED":
        performed.append(f"fast-forwarded clean Operator art checkout to origin/main ({len(sync.changed_paths)} path(s))")
    elif sync.action == "sparse profile repaired":
        performed.append(f"applied sparse profile {SPARSE_PROFILE}")
    if _status_paths(root):
        raise ArtWorktreeError("safe preparation produced Git-visible changes; checkout preserved for inspection")
    if not _sparse_profile_healthy(root):
        return replace(before, status="blocked", blockers=before.blockers + (
            f"shared synchronization did not establish sparse profile {SPARSE_PROFILE}",
        ))
    present, missing = _tracked_checkout_paths(root)
    expected_pointers = []
    ordinary_missing = []
    for relative in missing:
        blob = subprocess.run(["git", "show", f"HEAD:{relative}"], cwd=root, capture_output=True, check=False)
        if blob.returncode == 0 and _parse_lfs_pointer(blob.stdout):
            expected_pointers.append(relative)
        else:
            ordinary_missing.append(relative)
    if ordinary_missing:
        raise ArtWorktreeError("required sparse dependency is missing and is not a hydratable LFS pointer:\n" + "\n".join(ordinary_missing))
    pointers = [relative for relative, _oid, _size in checked_out_lfs_pointers(root)] + expected_pointers
    if pointers:
        hydrated=hydrate_lfs_paths(root, pointers, coordination_root)
        if hydrated: performed.append(f"hydrated {len(hydrated)} checked-out LFS dependencies locally")
    after = inspect_publish_readiness(root, coordination_root, workspace_root,
                                      selected_paths=selected_paths,
                                      source_freshness=source_freshness)
    if after.status != "ready":
        return after
    return replace(after, preparations=tuple(performed))


def _running_aseprite_processes() -> list[str]:
    result = subprocess.run(["ps", "-eo", "comm=,args="], text=True, capture_output=True, check=False)
    if result.returncode:
        raise ArtWorktreeError("cannot verify whether Aseprite has an open Workbench document")
    processes = []
    for line in result.stdout.splitlines():
        command, _, arguments = line.strip().partition(" ")
        if Path(command).name.lower() == "aseprite":
            processes.append(arguments.strip() or command.strip())
    return processes


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
        attached = _worktrees(root)
        by_branch = [path for path, branch in attached if branch == ART_BRANCH]
        by_path = next((branch for path, branch in attached if path == target), None)
        if by_path is not None:
            if by_path != ART_BRANCH:
                raise ArtWorktreeError(f"art checkout path is attached to unexpected branch {by_path}: {target}")
            # Existing checkouts are identified here; the launcher performs a
            # bounded safe sync through the shared authority after this creation
            # lock is released.
            try:
                migrate_legacy_workbench(root, target)
            except ArtWorktreeError:
                # Preserve the checkout and let the mounted UI project the blocker.
                pass
            return target
        if by_branch:
            raise ArtWorktreeError(f"{ART_BRANCH} is already attached at {by_branch[0]}")
        # Creation may fetch its starting point, but synchronization and sparse
        # repair run only after this creation lock is released through the
        # shared persistent-checkout authority.
        _git(root, "fetch", "origin", "main")
        if target.exists():
            if any(target.iterdir()):
                raise ArtWorktreeError(f"art checkout path exists but is not an attached worktree: {target}")
            target.rmdir()
        target.parent.mkdir(parents=True, exist_ok=True)
        branch_exists = _git(root, "show-ref", "--verify", f"refs/heads/{ART_BRANCH}", check=False)
        if branch_exists:
            _git(root, "worktree", "add", "--no-checkout", str(target), ART_BRANCH)
        else:
            _git(root, "worktree", "add", "--no-checkout", "-b", ART_BRANCH, str(target), "origin/main")
        if _top(target) != target or _git(target, "branch", "--show-current") != ART_BRANCH:
            raise ArtWorktreeError(f"created checkout failed identity verification: {target}")
        _apply_sparse_profile(target)
        _git_without_hooks(target, "checkout", ART_BRANCH)
        migrate_legacy_workbench(root, target)
        return target


@dataclass(frozen=True)
class CheckoutIdentity:
    kind: str
    branch: str
    worktree: str
    main_relation: str
    sparse_profile: str
    worktree_state: str
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
    sparse = f"sparse {SPARSE_PROFILE}" if _sparse_profile_healthy(root) else "full-tree"
    dirty_count = len(_status_paths(root))
    pending = (root / PENDING_RELATIVE).exists()
    state_parts = ["clean" if dirty_count == 0 else f"local changes {dirty_count} paths"]
    if pending:
        state_parts.append("LAND PENDING")
    return CheckoutIdentity(kind, branch, str(root), relation, sparse,
                            " · ".join(state_parts), allowed, str(coordination))


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
    # Runtime sync regenerates this canonical SpriteFrames projection as part
    # of publishing selected Operator source art.
    allowed.add(CANONICAL_RUNTIME_FRAMES.as_posix())
    # Canvas/frame migrations also regenerate the canonical runtime manifest.
    allowed.add("custodian/content/sprites/operator/runtime/operator_runtime_manifest.generated.json")
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


def _publication_identity(root: Path, commit: str) -> dict:
    """Stable content identity for one scoped publication commit."""
    paths = _git(root, "diff-tree", "--no-commit-id", "--name-only", "-r", "--no-renames", commit).splitlines()
    entries = []
    for path in sorted(paths):
        before = _git(root, "rev-parse", f"{commit}^:{path}", check=False) or None
        after = _git(root, "rev-parse", f"{commit}:{path}", check=False) or None
        entries.append({"path": path, "before": before, "after": after})
    patch_id = hashlib.sha256(json.dumps(entries, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
    return {"paths": entries, "patch_id": patch_id}


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
    already_landed=subprocess.run(["git", "merge-base", "--is-ancestor", head, "origin/main"], cwd=root, check=False).returncode == 0
    if already_landed and head==payload.get("commit"):
        pending.unlink(missing_ok=True)
        return {**payload, "status": "landed", "commit": head}
    if head != payload.get("commit"):
        recorded = payload.get("publication_identity")
        current = _publication_identity(root, head)
        if not recorded or current != recorded:
            raise ArtWorktreeError(
                "LAND PENDING checkout identity changed and stable publication identity does not match; "
                "preserve the branch and inspect the pending receipt"
            )
        payload = {**payload, "commit": head, "identity_relinked": True}
        _atomic_json(pending, payload)
        if already_landed:
            pending.unlink(missing_ok=True)
            return {**payload, "status":"landed"}
    return _land_and_verify(root, pending, payload)


def publish_to_main(
    *, repo_root: Path, coordination_root: Path | None, workspace_root: Path,
    canonical_paths: Iterable[str], allowlist: set[str], publish_once,
    identity: dict[str, str], mirror: bool = False, pre_publish_check=None,
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
    if pre_publish_check is not None:
        pre_publish_check()
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
    payload["publication_identity"] = _publication_identity(root, payload["commit"])
    _atomic_json(pending, payload)
    landed = _land_and_verify(root, pending, payload)
    landed["changed_sources"] = list(changed_sources)
    landed["staged_paths"] = sorted(staged)
    return landed


def best_effort_coordination_sync(coordination_root: Path | None) -> str:
    if not coordination_root:
        return "not-configured"
    try:
        sync_module = _persistent_sync_module()
        result = sync_module.apply_profiles(
            [sync_module.ROOT_PROFILE], Path(coordination_root).resolve(),
        )[0]
        return sync_module.format_result(result)
    except Exception as error:
        return f"coordination-main: pending · {error}"


def _persistent_sync_module():
    agent_dir = Path(__file__).resolve().parents[1] / "agent"
    if str(agent_dir) not in sys.path:
        sys.path.insert(0, str(agent_dir))
    import persistent_checkout_sync
    return persistent_checkout_sync


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
