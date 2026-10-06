from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Literal

SOURCE_SESSION_SCHEMA = "custodian.operator_art_source_session.v1"
SOURCE_ANALYSIS_SCHEMA = "custodian.operator_art_source_analysis.v1"
NORMALIZATION_PLAN_SCHEMA = "custodian.operator_art_normalization_plan.v2"
NORMALIZATION_PLAN_SCHEMA_V1 = "custodian.operator_art_normalization_plan.v1"


@dataclass(frozen=True)
class SourceGeometry:
    columns: int
    rows: int
    frame_count: int
    source_cell_width: int
    source_cell_height: int


@dataclass
class FrameSourceAnalysis:
    frame: int
    alpha_bbox: list[int] | None
    occupied_width: int
    occupied_height: int
    bottom_y: int | None
    top_y: int | None
    centroid_x: float | None
    centroid_y: float | None
    touches_left: bool
    touches_right: bool
    touches_top: bool
    touches_bottom: bool
    opaque_pixels: int


@dataclass
class SourceSession:
    schema: str
    session_id: str
    created_utc: str
    source_original: str
    source_sha256: str
    geometry: SourceGeometry
    target_width: int
    target_height: int
    state: Literal[
        "STAGED", "ANALYZED", "PLANNED", "CONVERTED", "REGISTERED",
        "REVIEWED", "READY", "CLOSED",
    ] = "STAGED"
    selected_candidate: str = ""
    reviewed_candidate_sha256: str = ""
    approved_normalization_plan_sha256: str = ""

    @classmethod
    def create(cls, **kwargs: Any) -> "SourceSession":
        return cls(schema=SOURCE_SESSION_SCHEMA, **kwargs)

    @classmethod
    def from_json(cls, value: dict[str, Any]) -> "SourceSession":
        if value.get("schema") != SOURCE_SESSION_SCHEMA:
            raise ValueError(f"unsupported source-session schema: {value.get('schema')}")
        payload = dict(value)
        payload["geometry"] = SourceGeometry(**payload["geometry"])
        return cls(**payload)

    def to_json(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class FrameRegistration:
    frame: int
    dx: int = 0
    dy: int = 0


@dataclass
class NormalizationPlan:
    schema: str
    source_sha256: str
    frame_count: int
    source_cell_width: int
    source_cell_height: int
    target_width: int
    target_height: int
    shared_union_bbox: list[int]
    global_scale: float
    prepared_width: int
    prepared_height: int
    destination_x: int
    destination_y: int
    anchor: Literal["feet", "center", "top-center", "bottom-center"]
    method: Literal["crisp", "balanced", "clustered"]
    registrations: list[FrameRegistration] = field(default_factory=list)
    mode: Literal["contain", "operator_profile"] = "contain"
    profile_sha256: str = ""
    profile_id: str = ""
    clipping_safe_scale: float | None = None
    scale_observations: list[dict[str, Any]] = field(default_factory=list)
    registration_basis: dict[str, Any] = field(default_factory=dict)

    @classmethod
    def create(cls, **kwargs: Any) -> "NormalizationPlan":
        return cls(schema=NORMALIZATION_PLAN_SCHEMA, **kwargs)

    @classmethod
    def from_json(cls, value: dict[str, Any]) -> "NormalizationPlan":
        schema = value.get("schema")
        if schema not in {NORMALIZATION_PLAN_SCHEMA, NORMALIZATION_PLAN_SCHEMA_V1}:
            raise ValueError(f"unsupported normalization-plan schema: {value.get('schema')}")
        payload = dict(value)
        if schema == NORMALIZATION_PLAN_SCHEMA_V1:
            payload["schema"] = NORMALIZATION_PLAN_SCHEMA
            payload["mode"] = "contain"
            payload["profile_sha256"] = ""
            payload["clipping_safe_scale"] = None
            payload["scale_observations"] = []
            payload["registration_basis"] = {}
        payload["registrations"] = [FrameRegistration(**item) for item in payload.get("registrations", [])]
        return cls(**payload)

    def to_json(self) -> dict[str, Any]:
        return asdict(self)
