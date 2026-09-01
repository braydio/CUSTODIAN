"""Semantic Operator animation preview and disposable review sequences."""
from __future__ import annotations

import hashlib
import json
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Literal

from PIL import Image

PreviewSource = Literal["workbench", "canonical", "runtime"]
PLAN_SCHEMA = "custodian.operator_animation_implementation_plan.v1"
SEQUENCE_SCHEMA = "custodian.operator_animation_review_sequence.v1"


@dataclass(frozen=True)
class SemanticIdentity:
    profile: str; group: str; action: str; direction: str

    @property
    def key(self) -> str:
        return f"{self.profile}/{self.group}/{self.action}/{self.direction}"


@dataclass(frozen=True)
class Preview:
    identity: SemanticIdentity
    source: PreviewSource
    frames: tuple[Image.Image, ...]
    frame_size: tuple[int, int]
    fingerprint: str
    paths: tuple[str, ...]


@dataclass
class TimelineClip:
    profile: str; group: str; action: str; direction: str
    review_fps: float = 8.0
    loops: int = 1
    start_frame: int | None = None
    end_frame: int | None = None

    @property
    def identity(self) -> SemanticIdentity:
        return SemanticIdentity(self.profile, self.group, self.action, self.direction)


@dataclass
class ReviewSequence:
    name: str
    clips: list[TimelineClip] = field(default_factory=list)
    schema: str = SEQUENCE_SCHEMA

    def to_json(self) -> dict:
        return {"schema": self.schema, "name": self.name, "clips": [asdict(clip) for clip in self.clips]}

    @classmethod
    def from_json(cls, value: dict) -> "ReviewSequence":
        if value.get("schema") != SEQUENCE_SCHEMA:
            raise ValueError(f"unsupported review sequence schema: {value.get('schema')}")
        return cls(str(value["name"]), [TimelineClip(**item) for item in value.get("clips", ())])


def _digest(paths: list[Path]) -> str:
    digest = hashlib.sha256()
    for path in paths:
        digest.update(str(path.resolve()).encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


def _file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def split_strip(path: Path, frames: int, frame_size: tuple[int, int]) -> list[Image.Image]:
    with Image.open(path) as opened:
        image = opened.convert("RGBA")
    width, height = frame_size
    if image.size != (width * frames, height):
        raise ValueError(f"strip contract mismatch: {path} is {image.size}, expected {(width * frames, height)}")
    return [image.crop((index * width, 0, (index + 1) * width, height)) for index in range(frames)]


def split_image(image: Image.Image, frame_size: tuple[int, int]) -> list[Image.Image]:
    """Split an RGBA strip using its real rectangular frame contract."""
    width, height = frame_size
    count = max(1, image.width // width)
    return [image.convert("RGBA").crop((index * width, 0, (index + 1) * width, height)) for index in range(count)]


def composite_layers(layers: list[tuple[Path, int, tuple[int, int]]]) -> tuple[tuple[Image.Image, ...], tuple[int, int]]:
    if not layers:
        raise ValueError("animation has no previewable layers")
    frame_count = max(item[1] for item in layers)
    canvas = (max(item[2][0] for item in layers), max(item[2][1] for item in layers))
    output = [Image.new("RGBA", canvas, (0, 0, 0, 0)) for _ in range(frame_count)]
    for path, count, size in layers:
        source = split_strip(path, count, size)
        x, y = (canvas[0] - size[0]) // 2, (canvas[1] - size[1]) // 2
        for index, frame in enumerate(source):
            output[index].alpha_composite(frame, (x, y))
    return tuple(output), canvas


class AnimationPreviewProvider:
    def __init__(self, *, repo_root: Path, catalog_path: Path, source_index, workspace_root: Path):
        self.repo_root = Path(repo_root); self.catalog_path = Path(catalog_path)
        self.source_index = source_index; self.workspace_root = Path(workspace_root)
        self.cache_root = self.workspace_root / "preview_cache"

    def _catalog_layers(self, identity: SemanticIdentity) -> list[tuple[Path, int, tuple[int, int]]]:
        payload = json.loads(self.catalog_path.read_text())
        entry = payload.get("animations", {}).get(identity.key)
        if not entry:
            raise ValueError(f"animation absent from generated catalog: {identity.key}")
        rows = []
        for layer in entry.get("layers", {}).values():
            raw = str(layer["path"])
            path = self.repo_root / "custodian" / raw.removeprefix("res://") if raw.startswith("res://") else self.repo_root / raw
            rows.append((path, int(layer["frames"]), tuple(layer["frame_size"])))
        return rows

    def _canonical_layers(self, identity: SemanticIdentity) -> list[tuple[Path, int, tuple[int, int]]]:
        rows = []
        for sid, (path, key) in self.source_index().items():
            if sid[0] == "operator" and tuple(sid[2:6]) == (identity.profile, identity.group, identity.action, identity.direction):
                rows.append((Path(path), int(key.frames), (int(key.frame_width), int(key.frame_height))))
        if not rows:
            raise ValueError(f"animation absent from canonical source: {identity.key}")
        return rows

    def _workbench_layers(self, identity: SemanticIdentity) -> list[tuple[Path, int, tuple[int, int]]]:
        workspace = self.workspace_root / identity.profile / identity.group / identity.action / identity.direction
        manifest_path = workspace / "workbench.json"
        if not manifest_path.exists():
            raise ValueError(f"workbench absent: {identity.key}")
        manifest = json.loads(manifest_path.read_text())
        document = Path(manifest.get("aseprite", {}).get("path", workspace / "workbench.aseprite"))
        exported = workspace / "exports" / f"preview_{_file_sha(document)[:16]}" / "normalized" if document.exists() else None
        rows = []
        for binding in manifest.get("layers", ()): 
            candidate = exported / f"{binding['binding_id']}.png" if exported else None
            path = candidate if candidate is not None and candidate.exists() else Path(binding.get("input_path", ""))
            contract = binding.get("workspace_contract", {})
            size = tuple(binding.get("frame_size", (0, 0)))
            if path.exists() and size != (0, 0): rows.append((path, int(contract.get("frames", binding.get("frames", 0))), size))
        if not rows:
            raise ValueError(f"workbench has no saved preview export: {identity.key}")
        return rows

    def load(self, identity: SemanticIdentity, source: PreviewSource = "runtime") -> Preview:
        layers = self._workbench_layers(identity) if source == "workbench" else self._canonical_layers(identity) if source == "canonical" else self._catalog_layers(identity)
        paths = [item[0] for item in layers]
        fingerprint = _digest(paths)
        frames, size = composite_layers(layers)
        return Preview(identity, source, frames, size, fingerprint, tuple(str(path) for path in paths))


def validate_plan(payload: dict, catalog: dict | None = None) -> list[dict]:
    if payload.get("schema") != PLAN_SCHEMA: raise ValueError("unsupported implementation-plan schema")
    items = payload.get("items")
    if not isinstance(items, list): raise ValueError("implementation plan items must be a list")
    ranks, ids, results = set(), set(), []
    allowed_states = {"planned", "active", "blocked", "deferred", "complete"}
    animations = (catalog or {}).get("animations", {})
    for item in items:
        if item["rank"] in ranks: raise ValueError(f"duplicate plan rank: {item['rank']}")
        if item["id"] in ids: raise ValueError(f"duplicate plan id: {item['id']}")
        if item["state"] not in allowed_states: raise ValueError(f"invalid plan state: {item['state']}")
        ranks.add(item["rank"]); ids.add(item["id"])
        covered = 0; layer_coverage = {}; covered_directions = []
        for direction in item["directions"]:
            entry = animations.get(f"{item['profile']}/{item['group']}/{item['action']}/{direction}", {})
            present = set(entry.get("layers", {})); required = set(item["required_layers"])
            ok = required <= present or ("full_body" in present and required == {"lower_body", "upper_body"})
            covered += int(ok); layer_coverage[direction] = sorted(present)
            if ok: covered_directions.append(direction)
        results.append({**item, "coverage": covered, "coverage_total": len(item["directions"]), "covered_directions": covered_directions, "layer_coverage": layer_coverage})
    return sorted(results, key=lambda item: item["rank"])


def save_sequence(sequence: ReviewSequence, root: Path) -> Path:
    if not sequence.name or any(char not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-" for char in sequence.name):
        raise ValueError("sequence name must contain only letters, numbers, underscore, or hyphen")
    root.mkdir(parents=True, exist_ok=True); path = root / f"{sequence.name}.json"
    path.write_text(json.dumps(sequence.to_json(), indent=2) + "\n"); return path


def load_sequence(path: Path) -> ReviewSequence:
    return ReviewSequence.from_json(json.loads(path.read_text()))


def flatten_sequence(sequence: ReviewSequence, provider: AnimationPreviewProvider, source: PreviewSource = "runtime") -> list[tuple[int, int, Image.Image]]:
    flattened = []
    for clip_index, clip in enumerate(sequence.clips):
        preview = provider.load(clip.identity, source)
        start = 0 if clip.start_frame is None else clip.start_frame
        end = len(preview.frames) - 1 if clip.end_frame is None else clip.end_frame
        if not 0 <= start <= end < len(preview.frames): raise ValueError(f"invalid frame trim for clip {clip_index + 1}")
        for _loop in range(clip.loops):
            flattened.extend((clip_index, index, preview.frames[index]) for index in range(start, end + 1))
    return flattened
