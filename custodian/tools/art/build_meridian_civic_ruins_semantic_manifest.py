#!/usr/bin/env python3
"""Build the authored Meridian catastrophe semantic/runtime manifest.

The extractor remains geometry authority. This builder merges authored
semantics, copies exact native crops into the content runtime domain, and adds
only the presentation fields consumed by SemanticNativeProp2D. No source image
is resized, resampled, rotated, or mirrored.
"""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path
from typing import Any

from PIL import Image


def _project_root(output: Path) -> Path:
    for candidate in (output.resolve().parent, *output.resolve().parents):
        if (candidate / "project.godot").is_file():
            return candidate
    raise RuntimeError("cannot locate custodian project root from output path")


def _record_list(raw: dict[str, Any]) -> list[dict[str, Any]]:
    records = raw.get("sprites") or raw.get("records") or raw.get("entries")
    if not isinstance(records, list):
        raise RuntimeError("raw extract manifest has no sprites/records/entries list")
    return records


def _sprite_offset(crop_size: list[int], anchor: list[float]) -> list[float | int]:
    values = [crop_size[0] / 2.0 - float(anchor[0]), crop_size[1] / 2.0 - float(anchor[1])]
    return [int(value) if value.is_integer() else value for value in values]


def build(raw_path: Path, annotation_path: Path, output_path: Path) -> dict[str, Any]:
    raw = json.loads(raw_path.read_text(encoding="utf-8"))
    annotations = json.loads(annotation_path.read_text(encoding="utf-8"))
    expected = int(annotations["expected_extracted_count"])
    annotation_by_id = {int(entry["source_id"]): entry for entry in annotations["entries"]}
    records = _record_list(raw)
    if len(records) != expected or len(annotation_by_id) != expected:
        raise RuntimeError(
            f"expected {expected} raw/semantic records, got "
            f"raw={len(records)} semantic={len(annotation_by_id)}"
        )

    project = _project_root(output_path)
    source_root = raw_path.parent / "sprites"
    runtime_root = project / "content/sprites/environment/props/meridian_civic/ruins_native"
    merged_entries: list[dict[str, Any]] = []
    seen_ids: set[int] = set()
    seen_addresses: set[tuple[str, str]] = set()

    for raw_record in records:
        source_id = int(raw_record["id"])
        if source_id in seen_ids:
            raise RuntimeError(f"duplicate raw source id {source_id}")
        seen_ids.add(source_id)
        semantic = annotation_by_id.get(source_id)
        if semantic is None:
            raise RuntimeError(f"no semantic annotation for source id {source_id}")

        source_file = str(raw_record["filename"])
        source_path = source_root / source_file
        if not source_path.is_file():
            raise RuntimeError(f"missing extracted source {source_path}")
        crop_size = [int(value) for value in raw_record["crop_size"]]
        with Image.open(source_path) as image:
            if image.mode != "RGBA" or list(image.size) != crop_size:
                raise RuntimeError(
                    f"source contract mismatch for {source_id}: "
                    f"mode={image.mode} size={image.size} expected=RGBA/{tuple(crop_size)}"
                )

        runtime_family = str(semantic["runtime_family"])
        variant_key = str(semantic["semantic_name"])
        address = (runtime_family, variant_key)
        if address in seen_addresses:
            raise RuntimeError(f"duplicate semantic address {runtime_family}/{variant_key}")
        seen_addresses.add(address)

        destination = runtime_root / runtime_family / source_file
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_path, destination)
        anchor = [float(value) for value in raw_record["suggested_anchor_px"]]
        y_sort = bool(semantic.get("y_sort", False))
        anchor_mode = str(semantic.get("anchor_mode", "floor_contact"))
        entry = dict(raw_record)
        entry.update(semantic)
        entry.update(
            {
                "id": source_id,
                "source_id": source_id,
                "source_file": source_file,
                "variant_key": variant_key,
                "native_size": [int(value) for value in raw_record["native_content_size"]],
                "extract_anchor_px": anchor,
                "canvas_size": crop_size,
                "sprite_position": _sprite_offset(crop_size, anchor),
                "texture_path": "res://" + destination.relative_to(project).as_posix(),
                "native_scale": 1.0,
                "collision_profile": str(semantic.get("collision_hint", "none_visual_only")),
                "collision_is_authoritative": False,
                "role": "floor_overlay" if anchor_mode == "floor_center" and not y_sort else "physical_prop",
                "runtime_strategy": str(semantic.get("usage_policy", "semantic_variant")),
            }
        )
        merged_entries.append(entry)

    expected_ids = set(range(1, expected + 1))
    if seen_ids != expected_ids:
        raise RuntimeError(
            f"extracted ids are not contiguous 1..{expected}; "
            f"missing={sorted(expected_ids - seen_ids)} extra={sorted(seen_ids - expected_ids)}"
        )

    final = {
        "schema": "custodian.semantic_ruins_manifest.v1",
        "family_id": annotations["family_id"],
        "source_master": {
            "path": annotations["source_master_path"],
            "raw_extract_manifest": annotations["raw_extract_manifest_path"],
            "extracted_count": expected,
        },
        "runtime_root": "res://" + runtime_root.relative_to(project).as_posix(),
        "runtime_contract": annotations["runtime_contract"],
        "runtime_families": sorted({entry["runtime_family"] for entry in merged_entries}),
        "entries": merged_entries,
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(final, indent=2) + "\n", encoding="utf-8")
    return final


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("raw_extract_manifest", type=Path)
    parser.add_argument("annotations", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    result = build(args.raw_extract_manifest, args.annotations, args.output)
    print(f"WROTE {args.output}")
    print(f"entries={len(result['entries'])}")
    print(f"review_required={sum(bool(entry.get('review_required')) for entry in result['entries'])}")
    print(f"runtime_families={len(result['runtime_families'])}")


if __name__ == "__main__":
    main()
