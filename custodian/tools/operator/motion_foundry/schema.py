"""Shared schema and hashing helpers for Motion Foundry V1."""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any

RIG_SCHEMA = "custodian.motion_foundry.rig.v1"
MOTION_SCHEMA = "custodian.motion_foundry.motion.v1"
REPORT_SCHEMA = "custodian.motion_foundry.report.v1"
RECEIPT_SCHEMA = "custodian.motion_foundry.candidate.v1"
HEX = re.compile(r"^[0-9a-f]{64}$")
DIRECTIONS = {"n", "ne", "e", "se", "s", "sw", "w", "nw"}


def canonical_json(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(Path(path).read_bytes())


def read_json(path: Path) -> dict[str, Any]:
    value = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"expected JSON object: {path}")
    return value


def confined_path(raw: str, root: Path) -> Path:
    if not isinstance(raw, str) or not raw:
        raise ValueError("source path must be a non-empty string")
    candidate = Path(raw)
    if candidate.is_absolute():
        resolved = candidate.resolve(strict=True)
    else:
        resolved = (root / candidate).resolve(strict=True)
    base = root.resolve(strict=True)
    try:
        resolved.relative_to(base)
    except ValueError as exc:
        raise ValueError(f"source path escapes declared root: {raw}") from exc
    if not resolved.is_file():
        raise ValueError(f"source is not a regular file: {raw}")
    return resolved


def integer_pair(value: Any, label: str) -> tuple[int, int]:
    if (not isinstance(value, list) or len(value) != 2
            or any(isinstance(v, bool) or not isinstance(v, int) for v in value)):
        raise ValueError(f"{label} must be a pair of integers")
    return value[0], value[1]


def inside(point: tuple[int, int], size: tuple[int, int]) -> bool:
    return 0 <= point[0] < size[0] and 0 <= point[1] < size[1]
