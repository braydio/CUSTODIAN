"""Asset Workbench service layer — the ONLY place the UI talks to Asset V2.

This module intentionally contains no projection logic of its own beyond
shaping the existing Asset Pipeline V2 authorities (``asset_contract``,
``asset_status``, ``asset_plan``, ``asset_doctor``, ``asset_catalog``) into
UI-friendly dataclasses. It never parses CLI text output, never re-derives
lifecycle/coverage rules, and never mutates assets. If a fact isn't already
computed by one of the underlying authority modules, this layer does not
invent it.
"""
from __future__ import annotations

import sys
from collections import Counter
from pathlib import Path

from PIL import Image

ASSETS_DIR = Path(__file__).resolve().parents[1]
PROJECT_DIR = ASSETS_DIR.parent.parent
TOOLS_DIR = ASSETS_DIR.parent
if str(ASSETS_DIR) not in sys.path:
    sys.path.insert(0, str(ASSETS_DIR))
# Appended, never inserted at 0: TOOLS_DIR contains a sibling directory named
# "operator", which must never shadow the stdlib "operator" module for any
# code that imports it for the first time after this line runs.
if str(TOOLS_DIR) not in sys.path:
    sys.path.append(str(TOOLS_DIR))

from asset_catalog import asset_catalog_key, load_catalog
from asset_classifier import classify_input
from asset_contract import AssetFamilyContract, AssetStateContract, load_all_families
from asset_doctor import run_doctor
from asset_inspector import FrameLayout, inspect_png
from asset_plan import generate_plan
from asset_status import FamilyStatus, StateStatus, get_family_status
from workbench.preview.frame_ops import split_image, split_strip

from .state import (
    AssetSelection,
    DirectionCoverage,
    DoctorIssueView,
    FamilyProjection,
    PipelineReport,
    StateProjection,
)

INBOX_ROOT = PROJECT_DIR / "asset_drop/inbox"
CATALOG_PATH = PROJECT_DIR / "content/metadata/assets/generated/asset_catalog.generated.json"


def _tier(state: AssetStateContract) -> str:
    return "required" if state.required else "recommended" if state.recommended else "optional"


def _direction_coverage(family: AssetFamilyContract, status: StateStatus) -> tuple[DirectionCoverage, ...]:
    authored, mirrored = set(status.authored_directions), set(status.mirrored_directions)
    coverage = []
    for direction in family.allowed_directions:
        state = "authored" if direction in authored else "mirrored" if direction in mirrored else "missing"
        coverage.append(DirectionCoverage(direction, state))
    return tuple(coverage)


class AssetWorkbenchService:
    """Thin, read-only projection layer over live Asset Pipeline V2 state."""

    def __init__(self, project_dir: Path | None = None) -> None:
        self.project_dir = project_dir or PROJECT_DIR
        self.inbox_root = self.project_dir / "asset_drop/inbox"
        self._families: dict[str, AssetFamilyContract] | None = None

    def families(self) -> dict[str, AssetFamilyContract]:
        if self._families is None:
            self._families = load_all_families()
        return self._families

    def family_ids(self) -> list[str]:
        return sorted(self.families())

    def refresh(self) -> None:
        self._families = None

    def family_status(self, family_id: str) -> FamilyStatus:
        family = self.families()[family_id]
        return get_family_status(family, self.project_dir)

    def family_projection(self, family_id: str) -> FamilyProjection:
        family = self.families()[family_id]
        status = self.family_status(family_id)
        groups: dict[str, list[StateProjection]] = {}
        for state_id, state in family.states.items():
            item_status = status.states[state_id]
            projection = StateProjection(
                state_id=state_id,
                layer=state.layer,
                action_group=state.action_group,
                variant=state.variant,
                tier=_tier(state),
                animation=state.animation,
                fps=state.fps,
                expected_frames=state.expected_frames,
                required_directions=state.required_directions,
                directions=_direction_coverage(family, item_status),
                art_present=item_status.art_present,
                imported=item_status.imported,
                bound=item_status.bound,
                runtime_verified=item_status.runtime_verified,
                runtime_path=item_status.runtime_path,
                source_pending=item_status.source_pending,
            )
            groups.setdefault(state.action_group, []).append(projection)
        return FamilyProjection(
            family_id=family.id,
            kind=family.kind,
            runtime_domain=family.runtime_domain,
            runtime_owner=family.runtime_owner,
            canvas=(family.frame_width, family.frame_height),
            direction_policy=family.direction_policy,
            auto_mirror=family.auto_mirror,
            consumers=tuple(family.consumers),
            completeness=status.completeness,
            inbox_files=tuple(status.inbox_files),
            groups=tuple((group, tuple(states)) for group, states in groups.items()),
        )

    def pipeline_report(self, family_id: str) -> PipelineReport:
        family = self.families()[family_id]
        plan = generate_plan(family, self.inbox_root / family.id, self.project_dir)
        operation_counts = dict(Counter(output.operation.value for output in plan.outputs))
        issues = run_doctor(self.project_dir)
        family_issues: list[DoctorIssueView] = []
        global_issues: list[DoctorIssueView] = []
        for issue in issues:
            bucket = family_issues if family_id in issue.message else global_issues
            bucket.append(DoctorIssueView(issue.severity, issue.message))
        return PipelineReport(
            family_id=family_id,
            plan_can_apply=plan.can_apply,
            plan_source_count=len(plan.assets),
            plan_output_count=len(plan.outputs),
            plan_operation_counts=operation_counts,
            plan_errors=tuple(plan.errors),
            plan_warnings=tuple(plan.warnings),
            doctor_family_issues=tuple(family_issues),
            doctor_global_issues=tuple(global_issues),
            doctor_healthy=not any(issue.severity == "error" for issue in family_issues),
        )

    def _catalog_entry(self, family_id: str, state_id: str, direction: str) -> dict | None:
        catalog = load_catalog(CATALOG_PATH)
        assets = catalog.get("families", {}).get(family_id, {}).get("assets", {})
        return assets.get(asset_catalog_key(state_id, direction))

    def _inbox_candidate(self, family_id: str, state_id: str, direction: str) -> Path | None:
        inbox = self.inbox_root / family_id
        if not inbox.exists():
            return None
        for name in (f"{state_id}__{direction}.png", f"{state_id}.png"):
            candidate = inbox / name
            if candidate.is_file():
                return candidate
        matches = sorted(path for path in inbox.glob("*.png") if path.stem == state_id or path.stem.startswith(f"{state_id}__"))
        return matches[0] if matches else None

    def available_review_sources(self, family_id: str, state_id: str, direction: str) -> tuple[str, ...]:
        sources = []
        if self._catalog_entry(family_id, state_id, direction) is not None:
            sources.append("runtime")
        if self._inbox_candidate(family_id, state_id, direction) is not None:
            sources.append("inbox")
        return tuple(sources)

    def review_frames(self, family_id: str, state_id: str, direction: str, source: str = "runtime") -> tuple[tuple[Image.Image, ...], dict]:
        """Read-only frame slicing for REVIEW. Never mutates catalog or content."""
        if source == "runtime":
            entry = self._catalog_entry(family_id, state_id, direction)
            if entry is None:
                raise ValueError(f"no runtime catalog entry for {family_id}/{state_id}/{direction}")
            path = self.project_dir / str(entry["path"])
            if not path.is_file():
                raise ValueError(f"runtime asset missing on disk: {entry['path']}")
            frame_size = tuple(entry["frame_size"])
            frames = tuple(split_strip(path, int(entry["frames"]), frame_size))
            return frames, {"path": entry["path"], "frames": entry["frames"], "frame_size": frame_size, "provenance": entry.get("provenance", "authored")}
        if source == "inbox":
            candidate = self._inbox_candidate(family_id, state_id, direction)
            if candidate is None:
                raise ValueError(f"no inbox artifact for {family_id}/{state_id}")
            family = self.families()[family_id]
            state = family.states[state_id]
            frame_width, frame_height = family.state_frame_size(state)
            inspection = inspect_png(candidate, frame_width, frame_height, state.layout, state.columns, state.rows)
            if inspection.layout == FrameLayout.AMBIGUOUS:
                raise ValueError(f"inbox artifact has an ambiguous frame layout: {candidate.name}")
            with Image.open(candidate) as opened:
                frames = tuple(split_image(opened, (inspection.frame_width, inspection.frame_height)))
            relative = candidate.relative_to(self.project_dir).as_posix()
            return frames, {"path": relative, "frames": inspection.frame_count, "frame_size": (inspection.frame_width, inspection.frame_height), "provenance": "inbox"}
        raise ValueError(f"unsupported review source: {source}")

    def resolve_selection(self, family_id: str, state_id: str | None = None, direction: str | None = None) -> AssetSelection | None:
        """Pick a deterministic default selection: first state with art, else first state."""
        family = self.families().get(family_id)
        if family is None:
            return None
        if state_id and state_id not in family.states:
            resolved, _ = family.resolve_state(state_id)
            state_id = resolved
        status = self.family_status(family_id)
        if state_id is None:
            with_art = [sid for sid, item in status.states.items() if item.art_present]
            state_id = with_art[0] if with_art else next(iter(family.states))
        state = family.states[state_id]
        if direction is None or direction not in family.allowed_directions:
            item = status.states[state_id]
            present = item.authored_directions + item.mirrored_directions
            direction = present[0] if present else family.allowed_directions[0]
        source = "runtime" if self._catalog_entry(family_id, state_id, direction) is not None else "inbox"
        return AssetSelection(family_id, state_id, direction, source)
