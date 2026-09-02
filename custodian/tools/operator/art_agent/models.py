from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Literal

SESSION_SCHEMA = "custodian.operator_art_agent.session.v2"
REQUEST_SCHEMA = "custodian.operator_art_agent.request.v2"
RESPONSE_SCHEMA = "custodian.operator_art_agent.response.v2"
CAPABILITY_SCHEMA = "custodian.operator_art_agent.capability.v1"
REFERENCE_SCHEMA = "custodian.operator_art_reference.v1"
PALETTE_SCHEMA = "custodian.operator_art_palette_report.v1"
RECOLOR_PLAN_SCHEMA = "custodian.operator_art_recolor_plan.v1"

OperationKind = Literal[
    "paint_pixels",
    "erase_pixels",
    "stroke",
    "copy_region",
    "move_region",
    "draft_shift_part",
    "draft_copy_part",
    "draft_replace_part",
    "draft_mirror_part",
    "discard_draft",
    "bake_draft",
    "clear_masked_region",
    "recolor_plan",
]


@dataclass(frozen=True)
class ArtIdentity:
    profile: str
    group: str
    action: str
    direction: str
    weapon: str = ""
    linked_profile: str = ""


@dataclass
class ArtSession:
    schema: str
    session_id: str
    created_utc: str
    identity: ArtIdentity
    workbench_manifest: str
    workbench_path: str
    context_fingerprint: str
    initial_workbench_sha256: str
    expected_workbench_sha256: str
    capability_path: str = ""
    operation_count: int = 0
    state: Literal["ACTIVE", "CLOSED", "ERROR"] = "ACTIVE"

    @classmethod
    def create(
        cls,
        *,
        session_id: str,
        created_utc: str,
        identity: ArtIdentity,
        workbench_manifest: str,
        workbench_path: str,
        context_fingerprint: str,
        workbench_sha256: str,
        capability_path: str = "",
    ) -> "ArtSession":
        return cls(
            schema=SESSION_SCHEMA,
            session_id=session_id,
            created_utc=created_utc,
            identity=identity,
            workbench_manifest=workbench_manifest,
            workbench_path=workbench_path,
            context_fingerprint=context_fingerprint,
            initial_workbench_sha256=workbench_sha256,
            expected_workbench_sha256=workbench_sha256,
            capability_path=capability_path,
        )

    @classmethod
    def from_json(cls, payload: dict[str, Any]) -> "ArtSession":
        if payload.get("schema") != SESSION_SCHEMA:
            raise ValueError(f"unsupported Art Agent session schema: {payload.get('schema')}")
        data = dict(payload)
        data["identity"] = ArtIdentity(**data["identity"])
        return cls(**data)

    def to_json(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True)
class ReferenceIdentity:
    profile: str
    group: str
    action: str
    direction: str
    weapon: str = ""
    linked_profile: str = ""


@dataclass
class ReferenceRecord:
    reference_id: str
    identity: ReferenceIdentity
    authority: Literal["canonical_source", "workbench_reference", "runtime_reference"]
    resolved_paths: list[str]
    source_hashes: dict[str, str]
    frame_count: int
    frame_width: int
    frame_height: int
    context_fingerprint: str
    created_utc: str
    layers: dict[str, str] = field(default_factory=dict)

    def to_json(self) -> dict[str, Any]: return asdict(self)


@dataclass(frozen=True)
class PaletteColor:
    rgb: tuple[int, int, int]
    count: int
    frame_count: int
    frames: list[int]
    relative_luminance: float
    first_seen_frame: int


@dataclass
class PaletteRegion:
    region_id: str
    name: str
    layer: str
    mask_ids: list[str]
    role: Literal["outline", "cloth", "armor", "metal", "skin", "trim", "accent", "weapon", "effect", "other"]
    protected: bool


@dataclass
class RecolorMapping:
    mapping_id: str
    scope: str
    source_rgb: tuple[int, int, int]
    destination_rgb: tuple[int, int, int] | None
    action: Literal["map", "preserve"]
    method: Literal["exact", "luminance_rank", "agent_selected"]
    confidence: float
    locked: bool
    region_id: str = ""


@dataclass
class RecolorPlan:
    schema: str
    plan_id: str
    target_session_id: str
    target_workbench_sha256: str
    reference_id: str
    reference_hashes: dict[str, str]
    target_layers: list[str]
    target_frames: list[int]
    region_ids: list[str]
    mappings: list[RecolorMapping]
    unmapped_colors: list[list[int]]
    ambiguous_colors: list[list[int]]
    preserve_alpha: bool
    status: Literal["DRAFT", "NEEDS_REVIEW", "READY", "PREVIEWED", "APPLIED", "STALE"]
    preview_sha256: str | None
    created_utc: str
