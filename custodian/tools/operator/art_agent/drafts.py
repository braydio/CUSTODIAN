from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Literal

DRAFTS_SCHEMA = "custodian.operator_art_drafts.v1"


@dataclass
class DraftRecord:
    draft_id: str
    kind: Literal["shift", "copy", "replace", "mirror"]
    part: str

    source_mask_id: str
    destination_mask_id: str | None

    source_layer: str
    source_frame: int

    destination_layer: str
    destination_frame: int

    source_spans: list[dict[str, int]]
    destination_spans: list[dict[str, int]] | None

    source_mask_fingerprint: str
    source_cel_fingerprint: str
    destination_cel_fingerprint: str

    draft_cel_fingerprint: str

    dx: int
    dy: int
    axis_x: int | None

    created_operation_key: str
    created_workbench_sha256: str

    status: Literal["ACTIVE", "BAKED", "DISCARDED", "STALE"]

    created_utc: str

    needs_gap_repair: bool = False
    gap_repair_note: str = ""
    advisory_note: str = ""

    def to_json(self) -> dict[str, Any]:
        return asdict(self)

    @classmethod
    def from_json(cls, value: dict[str, Any]) -> "DraftRecord":
        known = {field for field in cls.__dataclass_fields__}
        return cls(**{key: item for key, item in value.items() if key in known})


def load(path: Path) -> list[DraftRecord]:
    if not path.exists():
        return []
    payload = json.loads(path.read_text())
    return [DraftRecord.from_json(item) for item in payload.get("drafts", [])]


def save(path: Path, items: list[DraftRecord]) -> None:
    path.write_text(
        json.dumps({"schema": DRAFTS_SCHEMA, "drafts": [item.to_json() for item in items]}, indent=2) + "\n"
    )


def find(items: list[DraftRecord], draft_id: str) -> DraftRecord | None:
    for item in items:
        if item.draft_id == draft_id:
            return item
    return None


def replace(items: list[DraftRecord], record: DraftRecord) -> list[DraftRecord]:
    return [record if item.draft_id == record.draft_id else item for item in items]
