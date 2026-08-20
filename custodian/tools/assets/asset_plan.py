"""Asset plan — the mutation boundary. Building a plan must never mutate content."""

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from enum import Enum
from pathlib import Path

import sys
from pathlib import Path
ASSETS_DIR = Path(__file__).resolve().parent
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))

from asset_classifier import ResolutionConfidence
from asset_contract import AssetFamilyContract
from asset_inspector import AssetInspection, FrameLayout
from asset_key import AssetKey
from asset_router import resolve_runtime_target, load_kind_schemas, AssetKindSchema
from asset_classifier import classify_input


class AssetOperation(str, Enum):
    CREATE = "create"
    DUPLICATE = "duplicate"
    REPLACE = "replace"
    CONFLICT = "conflict"
    SKIP = "skip"


@dataclass(frozen=True)
class PlannedAsset:
    source_path: Path
    family_id: str
    state_id: str | None
    confidence: ResolutionConfidence
    inspection: AssetInspection
    key: AssetKey
    canonical_filename: str
    target_relative_path: Path
    backend: str
    operation: AssetOperation
    existing_target: Path | None
    warnings: tuple[str, ...]


@dataclass(frozen=True)
class AssetPlan:
    family_id: str
    assets: tuple[PlannedAsset, ...]
    errors: tuple[str, ...] = ()
    warnings: tuple[str, ...] = ()

    @property
    def can_apply(self) -> bool:
        return not self.errors and all(
            a.confidence != ResolutionConfidence.AMBIGUOUS for a in self.assets
        )


def generate_plan(
    family: AssetFamilyContract,
    inbox_dir: Path,
    project_dir: Path,
) -> AssetPlan:
    """Generate a read-only ingest plan for a family's inbox directory.

    This function must NOT write to content/, archive/, staging/, or catalog.
    """
    errors: list[str] = []
    warnings: list[str] = []
    planned: list[PlannedAsset] = []

    kind_schemas = load_kind_schemas()
    kind_schema = kind_schemas.get(family.kind)

    if kind_schema is None:
        return AssetPlan(
            family_id=family.id,
            assets=(),
            errors=(f"unsupported asset kind schema: {family.kind}",),
        )
    if not inbox_dir.exists():
        return AssetPlan(family_id=family.id, assets=())

    png_files = sorted(inbox_dir.glob("*.png"))
    if not png_files:
        return AssetPlan(
            family_id=family.id,
            assets=(),
            warnings=(f"no PNG files found in {inbox_dir}",),
        )

    for png in png_files:
        stem = png.stem

        from asset_inspector import inspect_png
        inspection = inspect_png(png, family.frame_width, family.frame_height)

        resolution = classify_input(family, stem, inspection)

        if resolution.confidence == ResolutionConfidence.AMBIGUOUS:
            planned.append(_make_ambiguous(png, family, inspection, resolution))
            continue

        assert resolution.state_id is not None
        state = family.states[resolution.state_id]
        fw = family.frame_width
        fh = family.frame_height
        frames = inspection.frame_count if inspection.layout != FrameLayout.COPY else 1

        key = AssetKey(
            owner=family.runtime_owner,
            kind=family.kind,
            layer=state.layer,
            action_group=state.action_group,
            variant=state.variant,
            direction=family.direction_policy,
            frames=frames,
            frame_width=fw,
            frame_height=fh,
        )

        from asset_naming import canonical_filename
        cf = canonical_filename(key)
        target = resolve_runtime_target(
            family=family, state=state, key=key, kind_schema=kind_schema,
        )
        target_full = project_dir / target

        existing = target_full if target_full.exists() else None
        operation = AssetOperation.CREATE
        if existing:
            old_hash = _file_hash(existing)
            new_hash = _file_hash(png)
            if old_hash == new_hash:
                operation = AssetOperation.DUPLICATE
                warnings.append(f"{stem}: duplicate (same hash as existing {target})")
            else:
                operation = AssetOperation.REPLACE

        if state.animation and frames <= 1:
            errors.append(f"{png.name}: state '{resolution.state_id}' requires animation but source resolves to one frame")
        if not state.animation and frames > 1:
            errors.append(f"{png.name}: state '{resolution.state_id}' is static but source resolves to {frames} frames")

        backend = _select_backend(state, inspection)

        p = PlannedAsset(
            source_path=png,
            family_id=family.id,
            state_id=resolution.state_id,
            confidence=resolution.confidence,
            inspection=inspection,
            key=key,
            canonical_filename=cf,
            target_relative_path=target,
            backend=backend,
            operation=operation,
            existing_target=existing,
            warnings=(),
        )
        planned.append(p)

    return AssetPlan(
        family_id=family.id,
        assets=tuple(planned),
        errors=tuple(errors),
        warnings=tuple(warnings),
    )


def _make_ambiguous(
    png: Path,
    family: AssetFamilyContract,
    inspection: AssetInspection,
    resolution,
) -> PlannedAsset:
    key = AssetKey(
        owner=family.runtime_owner,
        kind=family.kind,
        layer="unknown",
        action_group="unknown",
        variant=png.stem,
        direction=family.direction_policy,
        frames=0,
        frame_width=inspection.frame_width,
        frame_height=inspection.frame_height,
    )
    return PlannedAsset(
        source_path=png,
        family_id=family.id,
        state_id=None,
        confidence=ResolutionConfidence.AMBIGUOUS,
        inspection=inspection,
        key=key,
        canonical_filename="",
        target_relative_path=Path(),
        backend="none",
        operation=AssetOperation.CONFLICT,
        existing_target=None,
        warnings=(),
    )


def _select_backend(state, inspection) -> str:
    if inspection.frame_count > 1 or inspection.layout == FrameLayout.GRID:
        return "sprite_ingest"
    return "runtime_ready"


def _file_hash(path: Path) -> str:
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest()
