"""Deterministic canonical-sample measurement utility for the Operator art profile.

Samples an explicit, hand-chosen set of canonical identities -- never "newest
file", mtime, or directory-order selection -- and reports raw per-layer frame
metrics with full provenance. Every measurement is written with
`accepted: false`; nothing here becomes a QA-enforced threshold until a human
reviews it and flips `accepted` to `true` by hand in operator_art_profile.json.
"""
from __future__ import annotations

import tempfile
from pathlib import Path
from typing import Any

import animation_workbench_model as model

from .metrics import animation_metrics

CANONICAL_SAMPLES: tuple[dict[str, str], ...] = (
    {"profile": "melee_1h", "group": "locomotion", "action": "walk_01", "direction": "e"},
    {"profile": "melee_1h", "group": "locomotion", "action": "walk_01", "direction": "w"},
    {"profile": "melee_1h", "group": "locomotion", "action": "run_01", "direction": "e"},
    {"profile": "melee_1h", "group": "posture", "action": "idle_ready_01", "direction": "e"},
)


def _split_frames(path: Path, frame_width: int, frame_height: int, frame_count: int, output_dir: Path, prefix: str) -> list[Path]:
    from PIL import Image
    output_dir.mkdir(parents=True, exist_ok=True)
    paths = []
    with Image.open(path) as source:
        image = source.convert("RGBA")
        for index in range(frame_count):
            frame = image.crop((index * frame_width, 0, (index + 1) * frame_width, frame_height))
            frame_path = output_dir / f"{prefix}_{index + 1:03d}.png"
            frame.save(frame_path)
            paths.append(frame_path)
    return paths


def measure(
    *,
    samples: tuple[dict[str, str], ...] = CANONICAL_SAMPLES,
    source_root: Path = model.SOURCE_ROOT,
    weapon_root: Path = model.WEAPON_ROOT,
) -> dict[str, Any]:
    index = model.source_index(source_root, weapon_root)
    measurements: dict[str, Any] = {}
    sampled_identities: list[dict[str, str]] = []

    with tempfile.TemporaryDirectory() as scratch:
        work_dir = Path(scratch)
        for sample in samples:
            matched_layers = sorted({
                sid[1] for sid in index
                if sid[0] == "operator"
                and sid[2] == sample["profile"] and sid[3] == sample["group"]
                and sid[4] == sample["action"] and sid[5] == sample["direction"]
            })
            if not matched_layers:
                continue
            sampled_identities.append(sample)
            for layer in matched_layers:
                sid = ("operator", layer, sample["profile"], sample["group"], sample["action"], sample["direction"])
                path, key = index[sid]
                prefix = f"{sample['action']}_{sample['direction']}_{layer}"
                frame_paths = _split_frames(path, key.frame_width, key.frame_height, key.frames, work_dir, prefix)
                frame_data = animation_metrics(frame_paths)["frames"]
                key_prefix = f"{sample['profile']}.{sample['group']}.{sample['action']}.{sample['direction']}.{layer}"
                provenance = {"method": "canonical_sample", "identities": [sample], "sample_count": len(frame_data)}
                series = {
                    "frame_count": [key.frames],
                    "baseline_y": [item["baseline_y"] for item in frame_data if item["baseline_y"] is not None],
                    "height": [item["height"] for item in frame_data if item["height"]],
                    "width": [item["width"] for item in frame_data if item["width"]],
                    "palette_size": [item["palette_size"] for item in frame_data],
                }
                for metric_name, values in series.items():
                    if not values:
                        continue
                    measurements[f"{key_prefix}.{metric_name}"] = {
                        "value": {"min": min(values), "max": max(values), "samples": values},
                        "provenance": provenance,
                        "accepted": False,
                    }

    return {
        "schema": "custodian.operator_art_profile_measurement.v1",
        "sampled_identities": sampled_identities,
        "measurements": measurements,
    }
