from __future__ import annotations

from uuid import uuid4

from .masks import PartMask


def draft_operation(kind: str, mask: PartMask, *, destination_frame: int | None = None, dx: int = 0, dy: int = 0, axis_x: int | None = None) -> dict:
    if kind not in {"shift", "copy", "replace", "mirror"}:
        raise ValueError(f"unsupported draft kind: {kind}")
    draft_id = f"__ART_DRAFT__{mask.part}__f{destination_frame or mask.frame:03d}__{uuid4().hex[:8]}"
    operation = {"type": f"draft_{kind}_part", "draft_id": draft_id, "layer": mask.layer, "source_frame": mask.frame, "destination_frame": destination_frame or mask.frame, "dx": dx, "dy": dy, "spans": [{"y": x.y, "x0": x.x0, "x1": x.x1} for x in mask.spans]}
    if axis_x is not None: operation["axis_x"] = axis_x
    return operation
