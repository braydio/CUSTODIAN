from __future__ import annotations

import sys
import math
from statistics import median
from pathlib import Path

import animation_workbench_model as model

ART_TOOLS = model.CUSTODIAN_ROOT / "tools/art"
if str(ART_TOOLS) not in sys.path:
    sys.path.insert(0, str(ART_TOOLS))

from custodian_pixelart_converter import (  # noqa: E402
    SharedFrameTransform,
    compute_shared_frame_transform,
)

from .source_models import FrameRegistration, NormalizationPlan, SourceSession
from .registration_profile import load_profile, weighted_median


def build_plan(
    *,
    session: SourceSession,
    analysis: dict,
    method: str = "balanced",
    anchor: str = "feet",
    global_scale: float | None = None,
    mode: str = "contain",
    landmarks: list[dict] | None = None,
) -> NormalizationPlan:
    if method not in {"crisp", "balanced", "clustered"}:
        raise model.WorkbenchError(f"unsupported normalization method: {method}")
    if anchor not in {"feet", "center", "top-center", "bottom-center"}:
        raise model.WorkbenchError(f"unsupported normalization anchor: {anchor}")
    frame_bboxes = [tuple(item["alpha_bbox"]) if item["alpha_bbox"] else None for item in analysis["frames"]]
    transform = compute_shared_frame_transform(
        frame_size=(session.geometry.source_cell_width, session.geometry.source_cell_height),
        frame_bboxes=frame_bboxes,
        target_size=(session.target_width, session.target_height),
        anchor=anchor,
        fit="contain",
    )
    if mode not in {"contain", "operator_profile"}:
        raise model.WorkbenchError(f"unsupported normalization mode: {mode}")
    loaded_profile = None
    scale_observations: list[dict] = []
    clipping_safe_scale = float(transform.scale)
    plan_scale = float(transform.scale)
    destination_x, destination_y = transform.destination_offset
    registration_basis: dict = {}
    if mode == "operator_profile":
        if (session.target_width, session.target_height) not in {(96, 96), (128, 128)}:
            raise model.WorkbenchError("operator_profile normalization requires 96x96 (legacy_96) or 128x128 (operator_2_5d_128) target frames")
        loaded_profile = load_profile(frame_size=[session.target_width, session.target_height])
        registration = loaded_profile.get("registration")
        if registration is None:
            raise model.WorkbenchError("accepted Operator registration profile is unavailable")
        current = [item for item in (landmarks or []) if item.get("status", "CURRENT") == "CURRENT"]
        minimum_confidence = registration["normalization"]["source_landmark_min_confidence"]
        by_frame: dict[int, dict[str, dict]] = {}
        for item in current:
            if item.get("source_hash") and item["source_hash"] != session.source_sha256:
                raise model.WorkbenchError("source landmark record belongs to a different source")
            by_frame.setdefault(int(item["frame"]), {})[item["name"]] = item
        for segment in registration["normalization"]["scale_segments"]:
            for frame in range(1, session.geometry.frame_count + 1):
                frame_points = by_frame.get(frame, {})
                first, second = frame_points.get(segment["a"]), frame_points.get(segment["b"])
                observation = {"frame": frame, "segment": f"{segment['a']}:{segment['b']}",
                               "target_length": segment["target_length"], "weight": segment["weight"], "accepted": False}
                if not first or not second:
                    observation["reason"] = "landmark_pair_missing"
                    scale_observations.append(observation)
                    continue
                if min(first["confidence"], second["confidence"]) < minimum_confidence:
                    observation["reason"] = "confidence_below_threshold"
                    observation["confidence"] = min(first["confidence"], second["confidence"])
                    scale_observations.append(observation)
                    continue
                distance = math.hypot(first["x"] - second["x"], first["y"] - second["y"])
                if distance <= 0:
                    observation["reason"] = "zero_source_distance"
                    scale_observations.append(observation)
                    continue
                observation.update({
                    "source_distance": distance, "target_length": segment["target_length"],
                    "weight": segment["weight"], "ratio": segment["target_length"] / distance,
                    "confidence": min(first["confidence"], second["confidence"]), "accepted": True,
                })
                scale_observations.append(observation)
        primary = [item for item in scale_observations if item["accepted"] and item["segment"] == "head_center:hip_center"]
        if not primary:
            raise model.WorkbenchError("PROFILE_LANDMARKS_INSUFFICIENT: need a confident head_center and hip_center pair")
        runtime_scale = weighted_median(scale_observations)
        prepared_x = transform.prepared_cell_size[0] / session.target_width
        prepared_y = transform.prepared_cell_size[1] / session.target_height
        if abs(prepared_x - prepared_y) > 1e-9:
            raise model.WorkbenchError("Operator profile requires identical prepared X/Y scale factors")
        plan_scale = runtime_scale * prepared_x
        if plan_scale > clipping_safe_scale + 1e-9:
            raise model.WorkbenchError(
                "PROFILE_REGISTRATION_CLIPS: profile scale exceeds alpha-union clipping-safe scale "
                f"({plan_scale:.6f} > {clipping_safe_scale:.6f})"
            )
        union_x, union_y, union_right, union_bottom = transform.union_bbox
        union_width, union_height = max(1, union_right - union_x), max(1, union_bottom - union_y)
        scaled_width, scaled_height = max(1, round(union_width * plan_scale)), max(1, round(union_height * plan_scale))
        confident_hips = [p["x"] for f in by_frame.values() if (p := f.get("hip_center")) and p["confidence"] >= minimum_confidence]
        if not confident_hips:
            raise model.WorkbenchError("PROFILE_LANDMARKS_INSUFFICIENT: need a confident hip_center for shared placement")
        supports = []
        frame_analysis = {int(item["frame"]): item for item in analysis["frames"]}
        for frame, points in by_frame.items():
            support = [p["y"] for name in ("toe_near", "toe_far") if (p := points.get(name)) and p["confidence"] >= minimum_confidence]
            if support:
                supports.append(max(support))
            elif frame_analysis.get(frame, {}).get("bottom_y") is not None:
                supports.append(frame_analysis[frame]["bottom_y"])
        if not supports:
            supports = [item["bottom_y"] for item in analysis["frames"] if item.get("bottom_y") is not None]
        if not supports:
            raise model.WorkbenchError("PROFILE_LANDMARKS_INSUFFICIENT: no support-foot or alpha baseline evidence")
        step = max(1, round(prepared_x))
        anchor_x, anchor_y = registration["anchor"]
        destination_x = round(((anchor_x * prepared_x) - (median(confident_hips) - union_x) * plan_scale) / step) * step
        destination_y = round(((anchor_y * prepared_y) - (median(supports) - union_y) * plan_scale) / step) * step
        if destination_x < 0 or destination_y < 0 or destination_x + scaled_width > transform.prepared_cell_size[0] or destination_y + scaled_height > transform.prepared_cell_size[1]:
            raise model.WorkbenchError("PROFILE_REGISTRATION_CLIPS: quantized shared anchor placement clips the alpha union")
        registration_basis = {
            "source_landmark_min_confidence": minimum_confidence,
            "median_hip_center_x": median(confident_hips),
            "median_support_y": median(supports),
            "target_anchor": registration["anchor"],
            "quantization_step": step,
        }
    if global_scale is not None and mode == "contain":
        if not isinstance(global_scale, (int, float)) or isinstance(global_scale, bool) or global_scale <= 0.0:
            raise model.WorkbenchError("reviewed global scale must be a positive number")
        if global_scale > transform.scale:
            raise model.WorkbenchError(
                "reviewed global scale exceeds the clipping-safe contain scale "
                f"({global_scale:.6f} > {transform.scale:.6f})"
            )
        union_width = max(1, transform.union_bbox[2] - transform.union_bbox[0])
        union_height = max(1, transform.union_bbox[3] - transform.union_bbox[1])
        scaled_width = max(1, round(union_width * global_scale))
        scaled_height = max(1, round(union_height * global_scale))
        center_x = (transform.prepared_cell_size[0] - scaled_width) // 2
        if anchor in {"feet", "bottom-center"}:
            destination_y = transform.prepared_cell_size[1] - transform.margin - scaled_height
        elif anchor == "top-center":
            destination_y = transform.margin
        else:
            destination_y = (transform.prepared_cell_size[1] - scaled_height) // 2
        transform = SharedFrameTransform(
            union_bbox=transform.union_bbox,
            prepared_cell_size=transform.prepared_cell_size,
            margin=transform.margin,
            scale=float(global_scale),
            scaled_union_size=(scaled_width, scaled_height),
            destination_offset=(center_x, destination_y),
            anchor=transform.anchor,
            fit=transform.fit,
        )
        plan_scale = float(global_scale)
        destination_x, destination_y = transform.destination_offset
    return NormalizationPlan.create(
        source_sha256=session.source_sha256,
        frame_count=session.geometry.frame_count,
        source_cell_width=session.geometry.source_cell_width,
        source_cell_height=session.geometry.source_cell_height,
        target_width=session.target_width,
        target_height=session.target_height,
        shared_union_bbox=list(transform.union_bbox),
        global_scale=float(plan_scale),
        prepared_width=transform.prepared_cell_size[0],
        prepared_height=transform.prepared_cell_size[1],
        destination_x=destination_x,
        destination_y=destination_y,
        anchor=anchor,
        method=method,
        registrations=[FrameRegistration(frame=index + 1) for index in range(session.geometry.frame_count)],
        mode=mode,
        profile_sha256=loaded_profile["sha256"] if loaded_profile else "",
        profile_id=loaded_profile["profile_id"] if loaded_profile else "",
        clipping_safe_scale=clipping_safe_scale,
        scale_observations=scale_observations,
        registration_basis=registration_basis,
    )


def shared_transform_from_plan(plan: NormalizationPlan) -> SharedFrameTransform:
    union = tuple(plan.shared_union_bbox)
    content = (max(1, union[2] - union[0]), max(1, union[3] - union[1]))
    return SharedFrameTransform(
        union_bbox=union,
        prepared_cell_size=(plan.prepared_width, plan.prepared_height),
        margin=0,
        scale=plan.global_scale,
        scaled_union_size=(max(1, round(content[0] * plan.global_scale)), max(1, round(content[1] * plan.global_scale))),
        destination_offset=(plan.destination_x, plan.destination_y),
        anchor=plan.anchor,
        fit="contain",
    )
