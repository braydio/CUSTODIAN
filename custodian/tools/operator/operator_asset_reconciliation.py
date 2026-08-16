#!/usr/bin/env python3
"""Safe source/runtime reconciliation for Modular Operator artwork repair."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import shutil
import sys
import tempfile
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable

from PIL import Image


REPO_ROOT = Path(__file__).resolve().parents[3]
CUSTODIAN_ROOT = REPO_ROOT / "custodian"
SOURCE_ROOT = CUSTODIAN_ROOT / "content/sprites/operator/new_operator/modular"
MODULE_ROOT = CUSTODIAN_ROOT / "content/sprites/operator/runtime/modules/new_operator"
ARCHIVE_ROOT = CUSTODIAN_ROOT / "content/sprites/_pipeline/archive"
DEFAULT_WORKSPACE = REPO_ROOT / ".ai/operator_modular_alignment_repair"
BUILDER_PATH = CUSTODIAN_ROOT / "tools/pipelines/build_operator_modular_runtime.py"


def _load_builder():
    spec = importlib.util.spec_from_file_location("operator_modular_runtime_builder", BUILDER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to import builder: {BUILDER_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


BUILDER = _load_builder()


@dataclass
class EditableSourceRecord:
    semantic_id: str
    runtime_path: str
    selected_source_path: str | None
    source_candidates: list[str]
    editable_path: str | None
    resolution: str
    runtime_pixel_sha256: str
    source_pixel_sha256: str | None
    rebuilt_pixel_sha256: str | None
    original_source_backup: str | None
    provenance_note: str
    backup_paths: list[str]
    quarantined_paths: list[str]
    archive_candidate: str | None = None
    promoted_at_utc: str | None = None


class MaterializationError(RuntimeError):
    pass


def pixel_sha256(path: Path) -> str:
    with Image.open(path) as image:
        rgba = image.convert("RGBA")
        digest = hashlib.sha256()
        digest.update(rgba.width.to_bytes(8, "big"))
        digest.update(rgba.height.to_bytes(8, "big"))
        digest.update(rgba.tobytes())
        return digest.hexdigest()


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def validate_sheet_contract(path: Path, frames: int, frame_width: int, frame_height: int) -> None:
    if not path.exists():
        raise ValueError(f"source no longer exists: {path}")
    with Image.open(path) as image:
        if image.mode not in {"RGBA", "LA"} and "transparency" not in image.info:
            raise ValueError(f"source lost its alpha channel: {path}")
        rgba = image.convert("RGBA")
        expected = (frames * frame_width, frame_height)
        if rgba.size != expected:
            raise ValueError(f"sheet contract changed: expected {expected}, got {rgba.size}: {path}")


def verify_source_roundtrip(
    runtime_path: Path,
    source_path: Path,
    *,
    module_root: Path = MODULE_ROOT,
    build_one: Callable | None = None,
) -> tuple[bool, str]:
    identity = BUILDER.identify_runtime_module(runtime_path, module_root)
    build_one = build_one or BUILDER.build_runtime_module_from_source
    with tempfile.TemporaryDirectory(prefix="custodian-operator-roundtrip-") as temp_dir:
        rebuilt = Path(temp_dir) / runtime_path.name
        build_one(source_path, rebuilt, identity)
        rebuilt_digest = pixel_sha256(rebuilt)
    return rebuilt_digest == pixel_sha256(runtime_path), rebuilt_digest


def choose_materialized_source_path(runtime_path: Path, source_root: Path, module_root: Path) -> Path:
    identity = BUILDER.identify_runtime_module(runtime_path, module_root)
    family_dir = {
        "locomotion": identity.action.removesuffix("_01"),
        "fast_attack": "fast_attack",
        "sidearm": "sidearm",
        "ranged": "ranged",
        "generic": f"actions/{identity.loadout}/{identity.action}",
    }[identity.family]
    return source_root / family_dir / runtime_path.name


class SourceReconciler:
    def __init__(
        self,
        *,
        repo_root: Path = REPO_ROOT,
        source_root: Path = SOURCE_ROOT,
        module_root: Path = MODULE_ROOT,
        archive_root: Path = ARCHIVE_ROOT,
        workspace: Path = DEFAULT_WORKSPACE,
        build_one: Callable | None = None,
    ) -> None:
        self.repo_root = repo_root.resolve()
        self.source_root = source_root.resolve()
        self.module_root = module_root.resolve()
        self.archive_root = archive_root.resolve()
        self.workspace = workspace.resolve()
        self.build_one = build_one or BUILDER.build_runtime_module_from_source
        self.records: dict[str, EditableSourceRecord] = {}

    def reconcile(self, runtime_path: Path, *, dry_run: bool = False) -> EditableSourceRecord:
        runtime_path = runtime_path.resolve()
        resolution = BUILDER.resolve_source_for_runtime_module(runtime_path, self.source_root, self.module_root)
        identity = resolution.identity
        runtime_digest = pixel_sha256(runtime_path)
        selected = resolution.selected_source.resolve() if resolution.selected_source else None
        candidates = [path.resolve() for path in resolution.candidates]
        archive = self._archive_candidate(runtime_path)
        source_digest = pixel_sha256(selected) if selected and selected.exists() else None
        rebuilt_digest = None

        if selected is not None:
            matched, rebuilt_digest = verify_source_roundtrip(
                runtime_path, selected, module_root=self.module_root, build_one=self.build_one
            )
            if matched:
                record = EditableSourceRecord(
                    identity.semantic_id, self._rel(runtime_path), self._rel(selected),
                    [self._rel(path) for path in candidates], self._rel(selected),
                    "existing_roundtrip_match", runtime_digest, source_digest,
                    rebuilt_digest, None, "Builder-selected source reconstructs live runtime pixels.",
                    [], [], self._rel(archive) if archive else None,
                )
                return self._remember(record, dry_run)

        destination = choose_materialized_source_path(runtime_path, self.source_root, self.module_root)
        if dry_run:
            record = EditableSourceRecord(
                identity.semantic_id, self._rel(runtime_path), self._rel(selected) if selected else None,
                [self._rel(path) for path in candidates], self._rel(destination),
                "promoted_from_runtime", runtime_digest, source_digest, rebuilt_digest,
                None, "Dry run: live runtime would be promoted and roundtrip-proven.", [], [],
                self._rel(archive) if archive else None,
            )
            return self._remember(record, True)

        backup_paths: list[Path] = []
        quarantined: list[tuple[Path, Path]] = []
        exact_competitors = sorted(set(path for path in candidates if path.exists()) | ({selected} if selected else set()))
        try:
            for candidate in exact_competitors:
                backup = self._backup(candidate, "source_before_reconcile")
                backup_paths.append(backup)
                quarantine = self.workspace / "quarantined_sources" / self._rel_path(candidate)
                quarantine.parent.mkdir(parents=True, exist_ok=True)
                if not quarantine.exists():
                    shutil.move(candidate, quarantine)
                else:
                    candidate.unlink()
                quarantined.append((candidate, quarantine))

            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(runtime_path, destination)
            selected_after = BUILDER.resolve_source_for_runtime_module(
                runtime_path, self.source_root, self.module_root
            ).selected_source
            if selected_after is None or selected_after.resolve() != destination.resolve():
                raise MaterializationError(
                    f"promoted path is not selected by {identity.family} builder: {destination}"
                )
            matched, promoted_digest = verify_source_roundtrip(
                runtime_path, destination, module_root=self.module_root, build_one=self.build_one
            )
            if not matched:
                raise MaterializationError(
                    f"promoted source failed pixel roundtrip: runtime={runtime_digest} rebuilt={promoted_digest}"
                )
        except Exception:
            destination.unlink(missing_ok=True)
            for original, quarantine in reversed(quarantined):
                if quarantine.exists() and not original.exists():
                    original.parent.mkdir(parents=True, exist_ok=True)
                    shutil.move(quarantine, original)
            raise

        record = EditableSourceRecord(
            identity.semantic_id, self._rel(runtime_path), self._rel(selected) if selected else None,
            [self._rel(path) for path in candidates], self._rel(destination),
            "promoted_from_runtime", runtime_digest, source_digest, runtime_digest,
            self._rel(backup_paths[0]) if backup_paths else None,
            "Current runtime-normalized art was promoted after stale/missing source reconciliation.",
            [self._rel(path) for path in backup_paths],
            [self._rel(path) for _, path in quarantined],
            self._rel(archive) if archive else None,
            datetime.now(timezone.utc).isoformat(),
        )
        return self._remember(record, False)

    def _archive_candidate(self, runtime_path: Path) -> Path | None:
        if not self.archive_root.exists():
            return None
        matches = sorted(self.archive_root.rglob(runtime_path.name))
        return matches[0] if len(matches) == 1 else None

    def _backup(self, source: Path, category: str) -> Path:
        target = self.workspace / "backups" / category / self._rel_path(source)
        target.parent.mkdir(parents=True, exist_ok=True)
        if not target.exists():
            shutil.copy2(source, target)
        return target

    def backup_before_edit(self, source: Path) -> Path:
        return self._backup(source.resolve(), "source_before_edit")

    def _remember(self, record: EditableSourceRecord, dry_run: bool) -> EditableSourceRecord:
        self.records[record.semantic_id] = record
        if not dry_run:
            self.write_manifest()
        return record

    def write_manifest(self) -> None:
        self.workspace.mkdir(parents=True, exist_ok=True)
        payload = {
            "schema": "custodian.operator_modular_alignment_repair.materialized_sources.v1",
            "records": [asdict(self.records[key]) for key in sorted(self.records)],
        }
        (self.workspace / "materialized_sources.json").write_text(
            json.dumps(payload, indent=2) + "\n", encoding="utf-8"
        )

    def _rel_path(self, path: Path) -> Path:
        try:
            return path.resolve().relative_to(self.repo_root)
        except ValueError:
            return Path("external") / path.name

    def _rel(self, path: Path | None) -> str | None:
        return self._rel_path(path).as_posix() if path else None
