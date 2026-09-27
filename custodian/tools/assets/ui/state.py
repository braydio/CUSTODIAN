"""UI-only projections over Asset Pipeline V2 authority (no Textual dependency).

This is the Asset Workbench's own identity model. It intentionally does not
reuse Operator Workbench's ``AnimationSelection`` — Asset V2 families are not
profile/group/action/direction tuples, they are family/state/direction, with
layer, action_group and variant resolved through the family contract. There
must remain one semantic source of truth: the contract.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Literal

ReviewSource = Literal["runtime", "inbox"]
ReviewView = Literal["single", "split", "diff"]


@dataclass(frozen=True, order=True)
class AssetSelection:
    family_id: str
    state_id: str
    direction: str
    review_source: ReviewSource = "runtime"

    @property
    def identity(self) -> str:
        return f"{self.family_id}/{self.state_id}/{self.direction}"


@dataclass(frozen=True)
class DirectionCoverage:
    direction: str
    status: Literal["authored", "mirrored", "missing"]


@dataclass(frozen=True)
class StateProjection:
    """One family state as the workbench should show it — contract-first."""

    state_id: str
    layer: str
    action_group: str
    variant: str
    tier: Literal["required", "recommended", "optional"]
    animation: bool
    fps: float | None
    expected_frames: int | None
    required_directions: tuple[str, ...]
    directions: tuple[DirectionCoverage, ...]
    art_present: bool
    imported: bool
    bound: bool
    runtime_verified: bool
    runtime_path: str | None
    source_pending: bool

    @property
    def authored_directions(self) -> tuple[str, ...]:
        return tuple(item.direction for item in self.directions if item.status == "authored")

    @property
    def mirrored_directions(self) -> tuple[str, ...]:
        return tuple(item.direction for item in self.directions if item.status == "mirrored")

    @property
    def missing_directions(self) -> tuple[str, ...]:
        return tuple(item.direction for item in self.directions if item.status == "missing")


@dataclass(frozen=True)
class FamilyProjection:
    family_id: str
    kind: str
    runtime_domain: str
    runtime_owner: str
    canvas: tuple[int, int]
    direction_policy: str
    auto_mirror: bool
    consumers: tuple[dict, ...]
    completeness: str
    inbox_files: tuple[str, ...]
    # action_group -> states in contract order
    groups: tuple[tuple[str, tuple[StateProjection, ...]], ...]

    @property
    def states(self) -> tuple[StateProjection, ...]:
        return tuple(state for _, states in self.groups for state in states)


@dataclass(frozen=True)
class DoctorIssueView:
    severity: str
    message: str


@dataclass(frozen=True)
class PipelineReport:
    family_id: str
    plan_can_apply: bool
    plan_source_count: int
    plan_output_count: int
    plan_operation_counts: dict[str, int]
    plan_errors: tuple[str, ...]
    plan_warnings: tuple[str, ...]
    doctor_family_issues: tuple[DoctorIssueView, ...]
    doctor_global_issues: tuple[DoctorIssueView, ...]
    doctor_healthy: bool


@dataclass
class AssetWorkbenchUIState:
    family_id: str = ""
    selection: AssetSelection | None = None
    mode: str = "family"  # family | review | pipeline
    search_filter: str = ""
    review_frame: int = 0
    review_playing: bool = False
    review_loop: bool = True
    review_fps: float = 8.0
    review_zoom: str = "auto"
    review_view: ReviewView = "single"
    activity: list[str] = field(default_factory=list)

    def add_activity(self, message: str, limit: int = 200) -> None:
        self.activity.append(message)
        del self.activity[:-limit]


@dataclass(frozen=True)
class ErrorView:
    title: str
    message: str

    @classmethod
    def from_exception(cls, error: Exception) -> "ErrorView":
        message = str(error).strip() or error.__class__.__name__
        return cls(error.__class__.__name__.upper(), message)
