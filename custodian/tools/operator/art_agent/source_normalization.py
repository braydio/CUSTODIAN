from __future__ import annotations

import sys
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


def build_plan(
    *,
    session: SourceSession,
    analysis: dict,
    method: str = "balanced",
    anchor: str = "feet",
    global_scale: float | None = None,
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
    if global_scale is not None:
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
    return NormalizationPlan.create(
        source_sha256=session.source_sha256,
        frame_count=session.geometry.frame_count,
        source_cell_width=session.geometry.source_cell_width,
        source_cell_height=session.geometry.source_cell_height,
        target_width=session.target_width,
        target_height=session.target_height,
        shared_union_bbox=list(transform.union_bbox),
        global_scale=float(transform.scale),
        prepared_width=transform.prepared_cell_size[0],
        prepared_height=transform.prepared_cell_size[1],
        destination_x=transform.destination_offset[0],
        destination_y=transform.destination_offset[1],
        anchor=anchor,
        method=method,
        registrations=[FrameRegistration(frame=index + 1) for index in range(session.geometry.frame_count)],
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
