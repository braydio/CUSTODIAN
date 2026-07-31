#!/usr/bin/env python3
"""Archive and remove retired static visual ops from Sundered Keep production."""

from __future__ import annotations

import json
import os
from collections import Counter
from pathlib import Path
from tempfile import NamedTemporaryFile
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[2]
LEVEL_PATH = (
    PROJECT_ROOT
    / "content"
    / "levels"
    / "sundered_keep"
    / "sundered_keep_front_gate_large.json"
)
ARCHIVE_PATH = (
    PROJECT_ROOT
    / "content"
    / "levels"
    / "sundered_keep"
    / "archive"
    / "sundered_keep_front_gate_legacy_visual_ops.json"
)

REMOVE_VISUAL_TYPES = {
    "fill_rect",
    "fill_weighted_rect",
    "paint_cells",
    "stamp_wall",
    "stamp_prop",
    "stamp_prefab",
}

RETAIN_FUNCTIONAL_TYPES = {
    "blocker_rect",
    "interactable",
    "marker",
    "stamp_module",
}

ARCHIVE_SCHEMA = "custodian.sundered_keep.legacy_visual_ops.v1"
ARCHIVE_REASON = (
    "Removed so the authored underlay is the visual base and future visual "
    "placement is mapper-authored."
)


def _read_json(path: Path) -> dict[str, Any]:
    try:
        parsed = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise SystemExit(f"Missing required JSON: {path}") from error
    except json.JSONDecodeError as error:
        raise SystemExit(f"Invalid JSON at {path}: {error}") from error
    if not isinstance(parsed, dict):
        raise SystemExit(f"Expected a JSON object at {path}")
    return parsed


def _write_json_atomic(path: Path, document: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    serialized = json.dumps(document, indent=2, ensure_ascii=False) + "\n"
    with NamedTemporaryFile(
        "w",
        encoding="utf-8",
        dir=path.parent,
        prefix=f".{path.name}.",
        suffix=".tmp",
        delete=False,
    ) as temporary:
        temporary.write(serialized)
        temporary_path = Path(temporary.name)
    os.replace(temporary_path, path)


def _print_counts(
    heading: str,
    counts: Counter[str],
    classified_types: set[str],
) -> None:
    print(heading)
    for op_type in sorted(classified_types):
        print(f"  {op_type}: {counts.get(op_type, 0)}")


def main() -> int:
    level = _read_json(LEVEL_PATH)
    placements = level.get("mapper_placements")
    if not isinstance(placements, list):
        raise SystemExit("mapper_placements must exist as an array")
    if placements:
        raise SystemExit(
            "Refusing migration: mapper_placements is non-empty "
            f"({len(placements)} record(s))"
        )

    ops = level.get("ops")
    if not isinstance(ops, list):
        raise SystemExit("ops must exist as an array")

    removed: list[dict[str, Any]] = []
    retained: list[dict[str, Any]] = []
    unknown_types: Counter[str] = Counter()
    removed_counts: Counter[str] = Counter()
    retained_counts: Counter[str] = Counter()

    for index, raw_op in enumerate(ops):
        if not isinstance(raw_op, dict):
            raise SystemExit(f"ops[{index}] is not an object")
        op_type = raw_op.get("type")
        if not isinstance(op_type, str) or not op_type:
            raise SystemExit(f"ops[{index}] has no valid type")
        if op_type in REMOVE_VISUAL_TYPES:
            removed.append(raw_op)
            removed_counts[op_type] += 1
        elif op_type in RETAIN_FUNCTIONAL_TYPES:
            retained.append(raw_op)
            retained_counts[op_type] += 1
        else:
            unknown_types[op_type] += 1

    if unknown_types:
        details = ", ".join(
            f"{op_type}={count}"
            for op_type, count in sorted(unknown_types.items())
        )
        raise SystemExit(f"Refusing migration: unclassified op type(s): {details}")

    _print_counts(
        "Removed visual op counts:",
        removed_counts,
        REMOVE_VISUAL_TYPES,
    )
    _print_counts(
        "Retained functional op counts:",
        retained_counts,
        RETAIN_FUNCTIONAL_TYPES,
    )

    if not removed:
        print("No legacy visual ops removed; production JSON is already clean.")
        return 0

    archive = {
        "schema": ARCHIVE_SCHEMA,
        "source_level": "sundered_keep_front_gate_large",
        "runtime_authority": False,
        "reason": ARCHIVE_REASON,
        "ops": removed,
    }
    if ARCHIVE_PATH.exists():
        existing_archive = _read_json(ARCHIVE_PATH)
        if existing_archive != archive:
            raise SystemExit(
                "Refusing to overwrite a different legacy visual-op archive: "
                f"{ARCHIVE_PATH}"
            )
    else:
        _write_json_atomic(ARCHIVE_PATH, archive)

    level["ops"] = retained
    level["mapper_placements"] = []
    _write_json_atomic(LEVEL_PATH, level)
    print(f"Archived {len(removed)} visual op(s) to {ARCHIVE_PATH}")
    print(f"Retained {len(retained)} functional op(s) in {LEVEL_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
