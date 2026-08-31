from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Literal

from .models import ArtIdentity


@dataclass
class AnimationPlan:
    identity: ArtIdentity
    frame_count: int
    frame_size: tuple[int,int]
    recipe: str
    immutable_contract: dict
    perspective_contract: dict
    constraints: list[str]
    references: list[dict]
    required_landmarks: list[str]
    status: Literal["DRAFT","READY","BLOCKED","COMPLETE"]

    def to_json(self) -> dict: return asdict(self)


def build(identity: ArtIdentity, manifest: dict, recipe_path: Path, projection: dict, references: list[dict]) -> AnimationPlan:
    recipe=json.loads(recipe_path.read_text()); canvas=manifest["canvas"]
    return AnimationPlan(identity,int(manifest["timeline"]["document_frames"]),(int(canvas["width"]),int(canvas["height"])),recipe["kind"],{"frame_count_mutable":False,"timing_mutable":False,"frame_size_mutable":False},projection,recipe.get("constraints",[]),references,recipe.get("required_landmarks",[]),"DRAFT")
