from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Literal

from .models import ArtIdentity


@dataclass
class AnimationPlan:
    identity: ArtIdentity
    frame_count: int
    frame_size: tuple[int, int]
    recipe: str
    immutable_contract: dict
    perspective_contract: dict
    constraints: list[str]
    references: list[dict]
    required_landmarks: list[str] | dict[str, list[str]]
    status: Literal["DRAFT", "READY", "BLOCKED", "COMPLETE"]
    blockers: list[str]

    def to_json(self) -> dict: return asdict(self)


def build(
    identity: ArtIdentity,
    manifest: dict,
    recipe_path: Path,
    projection: dict,
    references: list[dict],
    *,
    landmarks: list[dict[str, Any]] | None = None,
    masks: list[dict[str, Any]] | None = None,
) -> AnimationPlan:
    recipe = json.loads(recipe_path.read_text())
    canvas = manifest["canvas"]
    frame_count = int(manifest["timeline"]["document_frames"])
    required = recipe.get("required_landmarks", [])
    each_frame = required.get("each_frame", []) if isinstance(required, dict) else required

    blockers: list[str] = []
    if not references:
        blockers.append("no semantic references resolved")

    if landmarks is None or masks is None:
        status = "DRAFT"
    else:
        by_frame: dict[int, set[str]] = {}
        for item in landmarks:
            if item.get("status", "CURRENT") == "CURRENT":
                by_frame.setdefault(item["frame"], set()).add(item["name"])
        missing = sorted({
            name for frame in range(1, frame_count + 1) for name in each_frame
            if name not in by_frame.get(frame, set())
        })
        stale_masks = [item.get("mask_id") for item in masks if item.get("status") == "STALE"]
        if missing:
            blockers.append(f"missing required landmarks: {missing}")
        if stale_masks:
            blockers.append(f"stale masks require re-validation: {stale_masks}")
        status = "BLOCKED" if blockers else "READY"

    return AnimationPlan(
        identity,
        frame_count,
        (int(canvas["width"]), int(canvas["height"])),
        recipe["kind"],
        {"frame_count_mutable": False, "timing_mutable": False, "frame_size_mutable": False},
        projection,
        recipe.get("constraints", []),
        references,
        required,
        status,
        blockers,
    )
