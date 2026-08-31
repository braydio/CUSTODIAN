from __future__ import annotations

from dataclasses import asdict, dataclass
from typing import Any, Literal

SESSION_SCHEMA = "custodian.operator_art_agent.session.v2"
REQUEST_SCHEMA = "custodian.operator_art_agent.request.v2"
RESPONSE_SCHEMA = "custodian.operator_art_agent.response.v2"
CAPABILITY_SCHEMA = "custodian.operator_art_agent.capability.v1"

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
