from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from typing import Any

PLAN_SCHEMA = "custodian.sprite_import_plan.v1"
MAX_FRAMES = 512
_SHA256 = re.compile(r"^[0-9a-f]{64}$")


class SpriteImportError(ValueError):
    """Invalid source or an incomplete/ambiguous conversion contract."""


def canonical_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False)


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


@dataclass(frozen=True)
class SpriteImportContract:
    semantic_identity: dict[str, str]
    contract_sha256: str
    frame_count: int
    columns: int
    rows: int
    source_cell_width: int
    source_cell_height: int
    target_width: int
    target_height: int
    layout: str
    alpha_policy: str
    resampler: str
    anchor: str
    fit: str = "contain"
    union_padding: int = 0

    def __post_init__(self) -> None:
        if not isinstance(self.semantic_identity, dict) or not self.semantic_identity:
            raise SpriteImportError("explicit semantic identity is required")
        if any(not isinstance(k, str) or not isinstance(v, str) or not v.strip()
               for k, v in self.semantic_identity.items()):
            raise SpriteImportError("semantic identity must contain named, non-empty string values")
        if not _SHA256.fullmatch(self.contract_sha256):
            raise SpriteImportError("contract digest must be a lowercase SHA-256")
        for name in ("frame_count", "columns", "rows", "source_cell_width", "source_cell_height",
                     "target_width", "target_height"):
            value = getattr(self, name)
            if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                raise SpriteImportError(f"{name} must be a positive integer")
        if self.frame_count > MAX_FRAMES:
            raise SpriteImportError(f"frame_count exceeds the {MAX_FRAMES}-frame preparation limit")
        if self.columns * self.rows != self.frame_count:
            raise SpriteImportError("grid capacity must exactly equal frame_count; unused or guessed cells are refused")
        if self.layout not in {"single_image", "horizontal_strip", "vertical_strip", "grid"}:
            raise SpriteImportError("layout must be an explicit single_image, horizontal_strip, vertical_strip, or grid")
        if self.layout == "single_image" and (self.frame_count, self.columns, self.rows) != (1, 1, 1):
            raise SpriteImportError("single_image layout requires exactly one 1x1 cell")
        if self.layout == "horizontal_strip" and self.rows != 1:
            raise SpriteImportError("horizontal_strip layout requires one row")
        if self.layout == "vertical_strip" and self.columns != 1:
            raise SpriteImportError("vertical_strip layout requires one column")
        if self.layout == "grid" and (self.rows == 1 or self.columns == 1):
            raise SpriteImportError("grid layout must declare multiple rows and columns")
        if self.fit != "contain":
            raise SpriteImportError("this plan supports contain only; unapproved crop/overflow is refused")
        if self.union_padding < 0:
            raise SpriteImportError("union_padding must be zero or greater")
        if self.anchor not in {"feet", "center", "top-center", "bottom-center", "base-center",
                               "top-left", "top-right", "bottom-left", "bottom-right", "origin"}:
            raise SpriteImportError("anchor must be explicitly declared and supported")
        if self.alpha_policy == "pixel_crisp":
            if self.resampler != "nearest":
                raise SpriteImportError("pixel_crisp requires nearest resampling")
        elif self.alpha_policy == "illustrated_structure_soft":
            if self.resampler not in {"box", "lanczos"}:
                raise SpriteImportError("illustrated_structure_soft requires an explicit box or lanczos filter")
        elif self.alpha_policy == "illustrated_structure_hard":
            if self.resampler not in {"nearest", "box"}:
                raise SpriteImportError("illustrated_structure_hard requires nearest or box resampling")
        elif self.alpha_policy == "opaque_tile":
            if self.resampler not in {"nearest", "box", "lanczos"}:
                raise SpriteImportError("opaque_tile requires an explicit supported resampler")
        else:
            raise SpriteImportError(f"unapproved alpha policy: {self.alpha_policy!r}")

    @property
    def alpha_mode(self) -> str:
        return {"pixel_crisp": "binary", "illustrated_structure_hard": "binary",
                "illustrated_structure_soft": "preserve", "opaque_tile": "opaque"}[self.alpha_policy]


@dataclass(frozen=True)
class SpriteImportPlan:
    """Immutable wrapper; canonical JSON is the sole plan representation."""

    canonical_text: str
    plan_sha256: str

    def to_json(self) -> str:
        return self.canonical_text

    def to_dict(self) -> dict[str, Any]:
        return json.loads(self.canonical_text)
