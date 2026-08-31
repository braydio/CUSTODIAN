from __future__ import annotations

from uuid import uuid4

from .masks import PartMask


def _spans_json(mask: PartMask) -> list[dict[str, int]]:
    return [{"y": span.y, "x0": span.x0, "x1": span.x1} for span in mask.spans]


def draft_operation(
    kind: str,
    mask: PartMask,
    *,
    destination_frame: int | None = None,
    destination_mask: PartMask | None = None,
    dx: int = 0,
    dy: int = 0,
    axis_x: int | None = None,
) -> dict:
    if kind not in {"shift", "copy", "replace", "mirror"}:
        raise ValueError(f"unsupported draft kind: {kind}")

    if kind == "replace":
        if destination_mask is None:
            raise ValueError("replace draft requires a destination_mask")
        if destination_mask.layer != mask.layer:
            raise ValueError("replace draft requires source_layer == destination_layer")
        if destination_frame not in (None, destination_mask.frame):
            raise ValueError("replace destination_frame must match the destination mask's frame")
        destination_frame = destination_mask.frame
    else:
        if destination_mask is not None:
            raise ValueError(f"{kind} draft does not accept a destination_mask")
        if kind in ("shift", "mirror"):
            if destination_frame not in (None, mask.frame):
                raise ValueError(f"{kind} draft requires destination_frame == source_frame")
            destination_frame = mask.frame
        else:
            destination_frame = destination_frame or mask.frame

    if kind == "mirror" and axis_x is None:
        raise ValueError("mirror draft requires axis_x")
    if kind != "mirror" and axis_x is not None:
        raise ValueError(f"{kind} draft does not accept axis_x")

    draft_id = f"__ART_DRAFT__{mask.part}__f{destination_frame:03d}__{uuid4().hex[:8]}"
    operation = {
        "type": f"draft_{kind}_part",
        "draft_id": draft_id,
        "layer": mask.layer,
        "source_frame": mask.frame,
        "destination_frame": destination_frame,
        "dx": dx,
        "dy": dy,
        "spans": _spans_json(mask),
    }
    if axis_x is not None:
        operation["axis_x"] = axis_x
    if destination_mask is not None:
        operation["destination_mask_spans"] = _spans_json(destination_mask)
    return operation
