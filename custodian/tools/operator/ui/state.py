"""UI-only state and backend projections (no Textual dependency)."""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any


@dataclass(frozen=True, order=True)
class AnimationSelection:
    profile: str
    group: str
    action: str
    direction: str
    weapon_id: str = ""
    linked_profile: str = ""

    @property
    def identity(self) -> str:
        return f"{self.profile}/{self.group}/{self.action}/{self.direction}"


@dataclass(frozen=True)
class AnimationRecord:
    selection: AnimationSelection
    frames: int
    layers: tuple[str, ...]
    completeness: str = "COMPLETE"
    completeness_detail: str = ""

    @property
    def summary(self) -> str:
        names = "+".join(layer.replace("_body", "") for layer in self.layers)
        marker = {"COMPLETE": "●", "PARTIAL": "◐", "REFERENCE/LEGACY": "◇"}.get(self.completeness, "⚠")
        detail = self.completeness_detail or names
        return f"{self.selection.direction}   {self.frames}f   {marker} {detail}"


@dataclass(frozen=True)
class LayerView:
    layer: str
    role: str
    owner: str
    profile: str
    source_frames: int
    workspace_frames: int
    publish_frames: int
    canvas: str
    publishing: bool = True


@dataclass(frozen=True)
class MigrationView:
    operation: str
    position: int
    fill: str
    old_frames: int
    new_frames: int
    affected: tuple[str, ...]
    excluded: tuple[tuple[str, str], ...]
    audit: str
    raw: dict[str, Any] = field(compare=False, repr=False, default_factory=dict)


@dataclass(frozen=True)
class PublishView:
    selection: AnimationSelection
    old_frames: int
    new_frames: int
    retired_paths: tuple[str, ...]
    new_paths: tuple[str, ...]
    migration: MigrationView | None
    audit: str


@dataclass(frozen=True)
class SessionView:
    selection: AnimationSelection
    source_frames: int
    workspace_frames: int
    document_frames: int
    workbench_state: str
    contract_state: str
    dependency_status: str
    workspace_path: Path
    aseprite_path: str
    layers: tuple[LayerView, ...]
    migration: MigrationView | None = None
    context: dict[str, Any] = field(default_factory=dict, compare=False)
    completeness: str = "COMPLETE"
    completeness_detail: str = ""
    workspace_display: str = ""


@dataclass(frozen=True)
class ExistingContextView:
    weapon_id: str
    linked_profile: str
    presentation_mode: str
    fingerprint: str

    @property
    def weapon_label(self) -> str:
        return self.weapon_id or "none"

    @property
    def profile_label(self) -> str:
        return self.linked_profile or "none"


@dataclass(frozen=True)
class ActivityEvent:
    message: str
    severity: str = "INFO"
    timestamp: str = field(default_factory=lambda: datetime.now().strftime("%H:%M:%S"))


@dataclass
class WorkbenchUIState:
    selection: AnimationSelection | None = None
    weapon_id: str = ""
    linked_profile: str = ""
    search_filter: str = ""
    selected_feature: str = "animations"
    activity: list[ActivityEvent] = field(default_factory=list)
    active_operation: str = ""
    aseprite_process: Any = None
    watch_signature: tuple[int | None, int | None] = (None, None)
    mode: str = "workbench"
    preview_source: str = "runtime"
    preview_frame: int = 0
    preview_playing: bool = False
    preview_loop: bool = True
    review_fps: float = 8.0
    preview_zoom: str = "auto"
    sequence_name: str = "review"

    def __post_init__(self) -> None:
        if self.selection is not None:
            self.weapon_id = self.selection.weapon_id
            self.linked_profile = self.selection.linked_profile

    def contextualize(self, identity: AnimationSelection) -> AnimationSelection:
        return AnimationSelection(
            identity.profile, identity.group, identity.action, identity.direction,
            self.weapon_id, self.linked_profile,
        )

    def adopt_context(self, weapon_id: str, linked_profile: str) -> None:
        self.weapon_id = weapon_id
        self.linked_profile = linked_profile
        if self.selection is not None:
            self.selection = self.contextualize(self.selection)

    def add_activity(self, message: str, severity: str = "INFO", limit: int = 200) -> ActivityEvent:
        event = ActivityEvent(message, severity)
        self.activity.append(event)
        del self.activity[:-limit]
        return event


@dataclass(frozen=True)
class ErrorView:
    title: str
    message: str

    @classmethod
    def from_exception(cls, error: Exception) -> "ErrorView":
        message = str(error).strip() or error.__class__.__name__
        first = message.splitlines()[0].upper()
        known = (
            "WORKBENCH STALE", "WORKBENCH CONTEXT MISMATCH",
            "FRAME MIGRATION BLOCKED", "STALE OPERATOR SPRITEFRAMES",
            "RECOVERY_REQUIRED",
        )
        title = next((phrase for phrase in known if phrase in first), error.__class__.__name__.upper())
        return cls(title, message)
