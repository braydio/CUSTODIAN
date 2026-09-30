"""Immutable presentation projections over Asset Pipeline V2 truth."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class StateProjection:
    state_id: str
    role: str
    layer: str
    action_group: str
    animation: bool
    fps: float | None
    expected_frames: int | None
    frame_width: int
    frame_height: int
    min_direction_count: int
    required_directions: tuple[str, ...]
    authored_directions: tuple[str, ...]
    mirrored_directions: tuple[str, ...]
    source_pending: bool
    art_present: bool
    imported: bool
    bound: bool
    runtime_verified: bool
    runtime_path: str | None


@dataclass(frozen=True)
class FamilyProjection:
    family_id: str
    kind: str
    required_completeness: str
    canvas_width: int
    canvas_height: int
    direction_policy: str
    allowed_directions: tuple[str, ...]
    auto_mirror: bool
    consumers: tuple[tuple[tuple[str, str], ...], ...]
    inbox_exists: bool
    inbox_pending_filenames: tuple[str, ...]
    runtime_outputs: tuple[str, ...]
    states: tuple[StateProjection, ...]

    def state(self, state_id: str) -> StateProjection | None:
        return next((state for state in self.states if state.state_id == state_id), None)


@dataclass(frozen=True)
class AssetSnapshot:
    families: tuple[FamilyProjection, ...]

    def family(self, family_id: str) -> FamilyProjection | None:
        return next((family for family in self.families if family.family_id == family_id), None)
