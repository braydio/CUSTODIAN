from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Literal

LANDMARK_NAMES = {
    "head_center", "hood_top", "shoulder_near", "shoulder_far", "elbow_near",
    "elbow_far", "hand_near", "hand_far", "hip_center", "hip_near", "hip_far",
    "knee_near", "knee_far", "ankle_near", "ankle_far", "toe_near", "toe_far",
    "cloak_tip_near", "cloak_tip_far", "weapon_grip", "weapon_tip",
}


@dataclass(frozen=True)
class Landmark:
    frame: int
    name: str
    x: int
    y: int
    semantic_side: Literal["near", "far", "center", "none"]
    confidence: float
    provenance: Literal["agent", "human", "heuristic", "imported", "pilot_fixture"]
    approved: bool = False
    source_hash: str = ""
    status: Literal["CURRENT", "STALE"] = "CURRENT"


def load(path: Path) -> list[Landmark]:
    if not path.exists():
        return []
    payload = json.loads(path.read_text())
    return [Landmark(**item) for item in payload.get("landmarks", [])]


def save(path: Path, items: list[Landmark]) -> None:
    path.write_text(json.dumps({"schema": "custodian.operator_landmarks.v1", "landmarks": [asdict(x) for x in items]}, indent=2) + "\n")


def validate(item: Landmark, *, frame_count: int, width: int, height: int) -> None:
    if item.name not in LANDMARK_NAMES:
        raise ValueError(f"unknown Operator landmark: {item.name}")
    if not 1 <= item.frame <= frame_count or not 0 <= item.x < width or not 0 <= item.y < height:
        raise ValueError("landmark outside animation contract")
    if not 0.0 <= item.confidence <= 1.0:
        raise ValueError("landmark confidence must be in 0..1")


def reconcile_hashes(items: list[Landmark], frame_hashes: dict[int, str]) -> list[Landmark]:
    result = []
    for item in items:
        if item.source_hash and frame_hashes.get(item.frame) != item.source_hash:
            if item.approved or item.provenance == "human":
                result.append(Landmark(**{**asdict(item), "status": "STALE"}))
            continue
        result.append(item)
    return result
