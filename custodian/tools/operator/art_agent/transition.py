from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from animation_transition import analyze_transition, legacy_handoff_metrics

from .render import make_animation_gif, make_contact_sheet, make_onion_skin, make_silhouette_sheet


def compare(target: list[Image.Image], reference: list[Image.Image], out: Path, *, tail: int = 2, head: int = 2, landmarks: list[dict] | None = None) -> dict:
    analysis = analyze_transition(target, reference, tail=tail, head=head)
    out.mkdir(parents=True, exist_ok=True)
    paths = []
    for index, image in enumerate(analysis.frames, 1):
        path = out / f"frame_{index:03d}.png"
        image.save(path)
        paths.append(path)

    metrics = legacy_handoff_metrics(analysis.metrics)
    marks = landmarks or []
    for name in ("head_center", "hip_center", "knee_near", "knee_far", "toe_near", "toe_far", "weapon_grip", "weapon_tip"):
        target_landmark = next((item for item in marks if item.get("phase") == "target" and item.get("name") == name), None)
        reference_landmark = next((item for item in marks if item.get("phase") == "reference" and item.get("name") == name), None)
        metrics[f"{name}_delta"] = ([reference_landmark["x"] - target_landmark["x"], reference_landmark["y"] - target_landmark["y"]] if target_landmark and reference_landmark else None)

    make_contact_sheet(paths, out / "transition_contact_sheet.png")
    make_animation_gif(paths, out / "transition.gif", fps=12)
    make_silhouette_sheet(paths, out / "transition_silhouette.png")
    make_onion_skin(paths, out / "transition_onion_skin.png")
    value = {
        "target_frames": list(analysis.target_frames),
        "reference_frames": list(analysis.reference_frames),
        "handoff_metrics": metrics,
        "artifacts": {key: str((out / filename).resolve()) for key, filename in {
            "contact_sheet": "transition_contact_sheet.png",
            "animation": "transition.gif",
            "silhouette": "transition_silhouette.png",
            "onion_skin": "transition_onion_skin.png",
        }.items()},
    }
    metrics_path = out / "transition_metrics.json"
    metrics_path.write_text(json.dumps(value, indent=2) + "\n")
    value["artifacts"]["metrics"] = str(metrics_path.resolve())
    return value
