from __future__ import annotations

import hashlib
import io
import json
import re
from typing import Any

from PIL import Image

from .models import PLAN_SCHEMA, SpriteImportContract, SpriteImportError, SpriteImportPlan, canonical_json, sha256_bytes

# Use the converter's geometry, preparation, candidate and resampling routines.
from custodian.tools.art import custodian_pixelart_converter as converter

MAX_SOURCE_PIXELS = converter.MAX_SOURCE_PIXELS
MAX_OUTPUT_PIXELS = 16_000_000
MAX_PREPARATION_PIXELS = converter.MAX_PREPARATION_PIXELS
_SHA256 = re.compile(r"^[0-9a-f]{64}$")


def _decode_source(source_bytes: bytes, expected_sha256: str, contract: SpriteImportContract) -> tuple[Image.Image, list[Image.Image]]:
    if not isinstance(source_bytes, bytes) or not source_bytes:
        raise SpriteImportError("required source bytes are empty")
    if not _SHA256.fullmatch(expected_sha256) or sha256_bytes(source_bytes) != expected_sha256:
        raise SpriteImportError("source SHA-256 does not match the supplied bytes")
    try:
        opened = Image.open(io.BytesIO(source_bytes))
        if opened.format != "PNG":
            raise SpriteImportError("source must be a PNG")
        width, height = opened.size
        if width <= 0 or height <= 0:
            raise SpriteImportError("source dimensions must be positive")
        if width * height > MAX_SOURCE_PIXELS:
            raise SpriteImportError(f"source exceeds the {MAX_SOURCE_PIXELS}-pixel preparation budget")
        source_mode = opened.mode
        if source_mode not in {"RGBA", "RGB"}:
            raise SpriteImportError(f"source mode {source_mode!r} is unsupported; provide explicit RGBA or RGB PNG")
        if source_mode == "RGB" and contract.alpha_policy != "opaque_tile":
            raise SpriteImportError("RGB source has no alpha channel; only a declared opaque_tile policy may accept it")
        source = opened.convert("RGBA")
    except SpriteImportError:
        raise
    except (OSError, ValueError, Image.DecompressionBombError) as exc:
        raise SpriteImportError(f"could not decode source PNG: {exc}") from exc
    finally:
        try:
            opened.close()
        except UnboundLocalError:
            pass

    expected_size = (contract.columns * contract.source_cell_width,
                     contract.rows * contract.source_cell_height)
    if source.size != expected_size:
        raise SpriteImportError(
            f"source size {source.width}x{source.height} does not match explicit "
            f"{contract.columns}x{contract.rows} grid of "
            f"{contract.source_cell_width}x{contract.source_cell_height} cells"
        )
    if contract.target_width * contract.target_height * contract.frame_count > MAX_OUTPUT_PIXELS:
        raise SpriteImportError(f"expected strip exceeds the {MAX_OUTPUT_PIXELS}-pixel output budget")
    if contract.alpha_mode == "opaque":
        if source.getchannel("A").getextrema() != (255, 255):
            raise SpriteImportError("opaque_tile contract requires every source pixel to be fully opaque")

    geometry = converter.SheetGeometry(
        columns=contract.columns, rows=contract.rows, frame_count=contract.frame_count,
        source_cell=(contract.source_cell_width, contract.source_cell_height),
    )
    frames = converter.split_sheet_frames(source, geometry)
    cutoff = 1 if contract.alpha_mode == "preserve" else 16
    boxes = [converter.alpha_bbox(frame, cutoff) for frame in frames]
    if contract.alpha_mode != "opaque" and any(box is None for box in boxes):
        empty = [str(i + 1) for i, box in enumerate(boxes) if box is None]
        raise SpriteImportError("required source frame(s) have no visible alpha: " + ", ".join(empty))
    return source, frames


def _transform(frames: list[Image.Image], contract: SpriteImportContract) -> tuple[converter.SharedFrameTransform, int]:
    target = (contract.target_width, contract.target_height)
    if contract.alpha_mode == "opaque" and contract.source_cell_width * target[1] != contract.source_cell_height * target[0]:
        raise SpriteImportError("opaque_tile source and target aspect ratios must match; letterbox alpha is refused")
    canvas = converter.automatic_source_canvas(target)
    prep_pixels = canvas[0] * canvas[1] * contract.frame_count
    if prep_pixels > MAX_PREPARATION_PIXELS:
        raise SpriteImportError(
            f"preparation needs {prep_pixels} frame-pixels; maximum is {MAX_PREPARATION_PIXELS}"
        )
    margin = 0 if contract.alpha_mode == "opaque" else converter.automatic_margin(canvas)
    cutoff = 1 if contract.alpha_mode == "preserve" else 16
    anchor = {"base-center": "bottom-center", "origin": "top-left"}.get(contract.anchor, contract.anchor)
    try:
        transform = converter.calculate_shared_frame_transform(
            frames, prepared_cell_size=canvas, margin=margin, alpha_cutoff=cutoff,
            anchor=anchor, union_padding=contract.union_padding, fit=contract.fit,
        )
    except (SystemExit, ValueError) as exc:
        raise SpriteImportError(f"cannot derive shared frame transform: {exc}") from exc
    left, top = transform.destination_offset
    right = left + transform.scaled_union_size[0]
    bottom = top + transform.scaled_union_size[1]
    if left < 0 or top < 0 or right > canvas[0] or bottom > canvas[1]:
        raise SpriteImportError("shared transform overflows the preparation canvas")
    return transform, cutoff


def _plan_body(source_sha256: str, contract: SpriteImportContract,
               transform: converter.SharedFrameTransform, cutoff: int) -> dict[str, Any]:
    return {
        "schema": PLAN_SCHEMA,
        "source_sha256": source_sha256,
        "semantic_identity": dict(contract.semantic_identity),
        "contract_sha256": contract.contract_sha256,
        "semantic_sha256": contract.contract_sha256,
        "input": {
            "layout": contract.layout,
            "orientation": "row_major",
            "columns": contract.columns,
            "rows": contract.rows,
            "frame_count": contract.frame_count,
            "source_cell_wh": [contract.source_cell_width, contract.source_cell_height],
            "source_wh": [contract.columns * contract.source_cell_width,
                          contract.rows * contract.source_cell_height],
            "frame_order": list(range(contract.frame_count)),
        },
        "geometry": {
            "alpha_union_bbox_ltrb": list(transform.union_bbox),
            "prepared_cell_wh": list(transform.prepared_cell_size),
            "global_scale": round(float(transform.scale), 12),
            "scaled_union_wh": list(transform.scaled_union_size),
            "global_placement_xy": list(transform.destination_offset),
            "target_frame_wh": [contract.target_width, contract.target_height],
            "expected_strip_wh": [contract.frame_count * contract.target_width, contract.target_height],
        },
        "conversion": {
            "candidate_method": contract.resampler,
            "alpha_policy": contract.alpha_policy,
            "alpha_mode": contract.alpha_mode,
            "alpha_cutoff": cutoff,
            "fit": contract.fit,
            "anchor": contract.anchor,
            "output_layout": "horizontal_strip",
        },
        "operator_profile_sha256": (contract.contract_sha256
                                     if contract.semantic_identity.get("kind") == "operator_profile" else None),
        "family_contract_sha256": (contract.contract_sha256
                                   if contract.semantic_identity.get("kind") == "asset_family" else None),
        "registrations": [{"frame": index, "dx": 0, "dy": 0}
                          for index in range(contract.frame_count)],
    }


def build_plan(source_bytes: bytes, *, source_sha256: str,
               contract: SpriteImportContract) -> SpriteImportPlan:
    """Build a versioned canonical plan without writing files or changing pixels."""
    _source, frames = _decode_source(source_bytes, source_sha256, contract)
    transform, cutoff = _transform(frames, contract)
    body = _plan_body(source_sha256, contract, transform, cutoff)
    digest = sha256_bytes(canonical_json(body).encode("utf-8"))
    document = {**body, "plan_sha256": digest}
    text = canonical_json(document)
    return SpriteImportPlan(canonical_text=text, plan_sha256=digest)


def plan_from_json(value: str | bytes | dict[str, Any] | SpriteImportPlan) -> SpriteImportPlan:
    if isinstance(value, SpriteImportPlan):
        document = value.to_dict()
    else:
        try:
            document = json.loads(value) if isinstance(value, (str, bytes)) else dict(value)
        except (json.JSONDecodeError, UnicodeDecodeError, TypeError, ValueError) as exc:
            raise SpriteImportError(f"normalization plan is not valid JSON: {exc}") from exc
    if not isinstance(document, dict) or document.get("schema") != PLAN_SCHEMA:
        raise SpriteImportError("normalization plan has an unsupported schema")
    supplied = document.get("plan_sha256")
    body = {key: item for key, item in document.items() if key != "plan_sha256"}
    actual = sha256_bytes(canonical_json(body).encode("utf-8"))
    if not isinstance(supplied, str) or supplied != actual:
        raise SpriteImportError("normalization plan digest does not match its canonical contents")
    return SpriteImportPlan(canonical_text=canonical_json(document), plan_sha256=actual)


def render_plan(source_bytes: bytes, *, source_sha256: str, contract: SpriteImportContract,
                plan: str | bytes | dict[str, Any] | SpriteImportPlan) -> bytes:
    """Verify and replay a plan into deterministic PNG bytes, with no filesystem writes."""
    supplied = plan_from_json(plan)
    expected = build_plan(source_bytes, source_sha256=source_sha256, contract=contract)
    if supplied.plan_sha256 != expected.plan_sha256:
        raise SpriteImportError("plan does not match this source, semantic contract, or conversion options")
    document = supplied.to_dict()
    _source, frames = _decode_source(source_bytes, source_sha256, contract)
    transform, cutoff = _transform(frames, contract)
    prep = converter.prepare_sheet_frames(
        frames, transform,
        prepare_filter=contract.resampler,
        alpha_cutoff=cutoff,
        binary_alpha_during_prepare=contract.alpha_mode == "binary",
    )
    reduced = converter.resize_shared_sheet_frames(
        prep, (contract.target_width, contract.target_height),
        resample=contract.resampler, alpha_mode=contract.alpha_mode, alpha_cutoff=cutoff,
    )
    output_geometry = converter.SheetGeometry(
        columns=contract.frame_count, rows=1, frame_count=contract.frame_count,
        source_cell=(contract.target_width, contract.target_height),
    )
    strip = converter.reassemble_sheet(reduced, output_geometry,
                                       (contract.target_width, contract.target_height))
    expected_size = tuple(document["geometry"]["expected_strip_wh"])
    if strip.size != expected_size:
        raise SpriteImportError(f"renderer produced {strip.width}x{strip.height}, expected {expected_size[0]}x{expected_size[1]}")
    if contract.alpha_mode == "binary" and not converter.binary_alpha_is_valid(strip):
        raise SpriteImportError("pixel_crisp output contains intermediate alpha")
    buffer = io.BytesIO()
    strip.save(buffer, format="PNG", optimize=False, compress_level=9)
    return buffer.getvalue()
