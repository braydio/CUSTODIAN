from __future__ import annotations

from dataclasses import asdict, dataclass
import json
from pathlib import Path


SCHEMA = "custodian.operator_art_edit_scope.v1"


@dataclass
class EditScope:
    schema: str
    allowed_layers: list[str]
    allowed_frames_by_layer: dict[str, list[int]]
    allowed_operations: list[str]
    protect_frame_count: bool = True
    protect_frame_size: bool = True
    protect_timing: bool = True
    protect_socket_authority: bool = True

    def to_json(self) -> dict: return asdict(self)


def load(path: Path) -> EditScope | None:
    if not path.exists(): return None
    value=json.loads(path.read_text())
    if value.get("schema") != SCHEMA: raise ValueError("unsupported edit-scope schema")
    return EditScope(**value)


def save(path: Path, allowed: list[dict], operations: list[str]) -> EditScope:
    frames: dict[str,list[int]]={}
    for item in allowed:
        layer=str(item["layer"]); values=sorted(set(int(x) for x in item["frames"]))
        if not values: raise ValueError("edit scope frames cannot be empty")
        frames.setdefault(layer,[]); frames[layer]=sorted(set(frames[layer]+values))
    scope=EditScope(SCHEMA,sorted(frames),frames,sorted(set(operations)))
    path.write_text(json.dumps(scope.to_json(),indent=2)+"\n")
    return scope


def assert_allowed(scope: EditScope | None, operation: str, targets: list[tuple[str,int]]) -> None:
    if scope is None or operation in {"undo"}: return
    if operation not in scope.allowed_operations: raise ValueError(f"operation outside active edit scope: {operation}")
    for layer,frame in targets:
        if layer not in scope.allowed_layers or frame not in scope.allowed_frames_by_layer.get(layer,[]):
            raise ValueError(f"target outside active edit scope: {layer} frame {frame}")
