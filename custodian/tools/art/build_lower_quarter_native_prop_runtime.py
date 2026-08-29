#!/usr/bin/env python3
"""Build padded, native-scale Meridian prop runtime families and static catalog."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
PROJECT = ROOT / "custodian"

MANIFEST = PROJECT / "content/metadata/assets/meridian_civic_props_native.semantic.json"

SOURCE = PROJECT / "content/sprites/environment/props/meridian_civic/native"

RUNTIME = PROJECT / "content/sprites/environment/props/meridian_civic/runtime"

CATALOG = (
    PROJECT / "game/world/levels/presentation/"
    "meridian_civic_native_prop_catalog.generated.gd"
)


# These are preferred family canvas sizes, not immutable crop boxes.
#
# Individual variants may grow by a pixel for anchor parity or grow farther
# when their native source crop cannot physically fit inside the preferred
# canvas. Source art itself is never resized.
CANVASES = {
    "meridian_civic_structure": (80, 96),
    "meridian_civic_lighting": (64, 96),
    "meridian_civic_signage": (80, 112),
    "meridian_civic_terminal": (64, 96),
    "meridian_civic_utility": (80, 96),
    "meridian_civic_security": (64, 96),
    "meridian_civic_bench": (144, 80),
    "meridian_civic_waste": (48, 80),
    "meridian_civic_traffic_control": (176, 160),
    "meridian_civic_worksite": (64, 160),
    "meridian_civic_floor_hardware": (96, 96),
    "meridian_civic_industrial_module": (128, 160),
    "meridian_civic_basin": (96, 96),
    "meridian_civic_planter": (144, 96),
    "meridian_civic_debris": (160, 96),
    "meridian_civic_crate": (96, 80),
    "meridian_civic_container": (80, 80),
}


EPSILON = 1e-9


def _is_integer_pixel(value: float) -> bool:
    return abs(value - round(value)) < EPSILON


def _anchor_is_half_pixel(value: float) -> bool:
    """
    Return True when an authored anchor sits on N + 0.5.

    The semantic extraction data currently uses integer and half-integer
    anchors. Anything else is rejected because it cannot be represented by
    native integer-pixel padding without introducing subpixel rendering.
    """

    fractional = value - int(value)

    if abs(fractional) < EPSILON:
        return False

    if abs(abs(fractional) - 0.5) < EPSILON:
        return True

    raise RuntimeError(
        f"unsupported extraction anchor coordinate {value}; "
        "expected integer or half-integer pixel"
    )


def _resolve_canvas_axis(
    *,
    preferred_size: int,
    source_size: int,
    anchor: float,
) -> int:
    """
    Choose the smallest legal runtime canvas axis.

    Requirements:
      1. source crop must physically fit
      2. canvas center and authored anchor must share pixel parity

    Matching parity guarantees that, after an integer crop placement,
    Sprite2D's compensation offset is also integer-aligned.
    """

    size = max(preferred_size, source_size)

    anchor_half = _anchor_is_half_pixel(anchor)

    # Even canvas -> integer center.
    # Odd canvas  -> half-integer center.
    canvas_half = bool(size % 2)

    if canvas_half != anchor_half:
        size += 1

    return size


def _clamp_int(value: int, minimum: int, maximum: int) -> int:
    if maximum < minimum:
        raise RuntimeError(f"invalid clamp range {minimum}..{maximum}")

    return max(minimum, min(value, maximum))


def _resolve_horizontal_paste(
    *,
    canvas_width: int,
    source_width: int,
    anchor_x: float,
) -> int:
    """
    Place the source as close as possible to having its authored anchor at
    canvas center.

    Crucially, asymmetric crops are allowed. If centering the anchor would
    overflow one side of the canvas, shift the entire crop by an integer pixel
    amount and compensate later with Sprite2D.position.
    """

    desired_left_float = canvas_width / 2.0 - anchor_x

    if not _is_integer_pixel(desired_left_float):
        raise RuntimeError(
            "internal horizontal parity failure: "
            f"canvas_width={canvas_width}, anchor_x={anchor_x}, "
            f"desired_left={desired_left_float}"
        )

    desired_left = int(round(desired_left_float))

    max_left = canvas_width - source_width

    return _clamp_int(
        desired_left,
        0,
        max_left,
    )


def _resolve_vertical_paste(
    *,
    canvas_height: int,
    source_height: int,
    anchor_y: float,
    anchor_mode: str,
) -> int:
    """
    Resolve vertical crop placement.

    floor_contact:
      Bottom-align the entire extracted crop. This preserves intentional
      extraction padding below the floor-contact anchor.

    other modes:
      Prefer authored-anchor centering, but clamp when an asymmetric source
      would overflow.
    """

    max_top = canvas_height - source_height

    if anchor_mode == "floor_contact":
        return max_top

    desired_top_float = canvas_height / 2.0 - anchor_y

    if not _is_integer_pixel(desired_top_float):
        raise RuntimeError(
            "internal vertical parity failure: "
            f"canvas_height={canvas_height}, anchor_y={anchor_y}, "
            f"desired_top={desired_top_float}"
        )

    desired_top = int(round(desired_top_float))

    return _clamp_int(
        desired_top,
        0,
        max_top,
    )


def _validate_source_anchor(
    *,
    family: str,
    variant: str,
    source_width: int,
    source_height: int,
    anchor_x: float,
    anchor_y: float,
) -> None:
    """
    Make sure the authored extraction anchor actually refers to the source
    crop rather than silently accepting corrupt semantic metadata.
    """

    if not 0.0 <= anchor_x <= float(source_width):
        raise RuntimeError(
            f"anchor X outside source for {family}/{variant}: "
            f"anchor_x={anchor_x}, width={source_width}"
        )

    if not 0.0 <= anchor_y <= float(source_height):
        raise RuntimeError(
            f"anchor Y outside source for {family}/{variant}: "
            f"anchor_y={anchor_y}, height={source_height}"
        )

    # Also validates that coordinates use supported pixel parity.
    _anchor_is_half_pixel(anchor_x)
    _anchor_is_half_pixel(anchor_y)


def _sprite_position(
    *,
    canvas_width: int,
    canvas_height: int,
    paste_left: int,
    paste_top: int,
    anchor_x: float,
    anchor_y: float,
) -> list[int]:
    """
    Calculate Sprite2D offset required to make the authored source anchor land
    exactly on the SemanticNativeProp2D origin.

    Texture is centered by Sprite2D, so:

      texture-space target
          = paste position + source anchor

      sprite offset
          = texture center - target

    Canvas parity is selected so both resulting values are integer pixels.
    """

    target_x = paste_left + anchor_x
    target_y = paste_top + anchor_y

    offset_x = canvas_width / 2.0 - target_x
    offset_y = canvas_height / 2.0 - target_y

    if not _is_integer_pixel(offset_x) or not _is_integer_pixel(offset_y):
        raise RuntimeError(
            "subpixel runtime sprite offset after parity resolution: "
            f"canvas={(canvas_width, canvas_height)}, "
            f"paste={(paste_left, paste_top)}, "
            f"anchor={(anchor_x, anchor_y)}, "
            f"offset={(offset_x, offset_y)}"
        )

    return [
        int(round(offset_x)),
        int(round(offset_y)),
    ]


def _validate_paste(
    *,
    family: str,
    variant: str,
    canvas_width: int,
    canvas_height: int,
    source_width: int,
    source_height: int,
    paste_left: int,
    paste_top: int,
) -> None:
    right = paste_left + source_width
    bottom = paste_top + source_height

    if (
        paste_left < 0
        or paste_top < 0
        or right > canvas_width
        or bottom > canvas_height
    ):
        raise RuntimeError(
            f"canvas overflow {family}/{variant}: "
            f"paste={(paste_left, paste_top)}, "
            f"source={(source_width, source_height)}, "
            f"bounds={(right, bottom)}, "
            f"canvas={(canvas_width, canvas_height)}"
        )


def main() -> None:
    if not MANIFEST.is_file():
        raise RuntimeError(f"semantic manifest does not exist: {MANIFEST}")

    data = json.loads(MANIFEST.read_text(encoding="utf-8"))

    entries = data.get("entries", [])

    if not isinstance(entries, list):
        raise RuntimeError(f"{MANIFEST}: entries must be a list")

    catalog: dict[str, dict] = {}

    for entry in entries:
        family = str(entry["runtime_family"])
        variant = str(entry["variant_key"])

        if family not in CANVASES:
            raise RuntimeError(
                f"unknown runtime family {family!r} " f"for {family}/{variant}"
            )

        preferred_width, preferred_height = CANVASES[family]

        source_file = str(entry["source_file"])

        src = SOURCE / family / source_file

        if not src.is_file():
            raise RuntimeError(f"missing source for {family}/{variant}: " f"{src}")

        with Image.open(src) as image:
            rgba = image.convert("RGBA")

        source_width = rgba.width
        source_height = rgba.height

        anchor_x, anchor_y = map(
            float,
            entry["extract_anchor_px"],
        )

        anchor_mode = str(
            entry.get(
                "anchor_mode",
                "floor_contact",
            )
        )

        _validate_source_anchor(
            family=family,
            variant=variant,
            source_width=source_width,
            source_height=source_height,
            anchor_x=anchor_x,
            anchor_y=anchor_y,
        )

        canvas_width = _resolve_canvas_axis(
            preferred_size=preferred_width,
            source_size=source_width,
            anchor=anchor_x,
        )

        canvas_height = _resolve_canvas_axis(
            preferred_size=preferred_height,
            source_size=source_height,
            anchor=anchor_y,
        )

        paste_left = _resolve_horizontal_paste(
            canvas_width=canvas_width,
            source_width=source_width,
            anchor_x=anchor_x,
        )

        paste_top = _resolve_vertical_paste(
            canvas_height=canvas_height,
            source_height=source_height,
            anchor_y=anchor_y,
            anchor_mode=anchor_mode,
        )

        _validate_paste(
            family=family,
            variant=variant,
            canvas_width=canvas_width,
            canvas_height=canvas_height,
            source_width=source_width,
            source_height=source_height,
            paste_left=paste_left,
            paste_top=paste_top,
        )

        sprite_position = _sprite_position(
            canvas_width=canvas_width,
            canvas_height=canvas_height,
            paste_left=paste_left,
            paste_top=paste_top,
            anchor_x=anchor_x,
            anchor_y=anchor_y,
        )

        output = Image.new(
            "RGBA",
            (
                canvas_width,
                canvas_height,
            ),
            (0, 0, 0, 0),
        )

        output.alpha_composite(
            rgba,
            (
                paste_left,
                paste_top,
            ),
        )

        dst = RUNTIME / family / f"{variant}.png"

        dst.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        output.save(
            dst,
            optimize=True,
        )

        item = dict(entry)

        item.update(
            {
                "texture_path": ("res://" + dst.relative_to(PROJECT).as_posix()),
                "canvas_size": [
                    canvas_width,
                    canvas_height,
                ],
                "sprite_position": sprite_position,
            }
        )

        catalog_key = f"{family}/{variant}"

        if catalog_key in catalog:
            raise RuntimeError(f"duplicate runtime catalog key: {catalog_key}")

        catalog[catalog_key] = item

    CATALOG.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    payload = json.dumps(
        catalog,
        indent=2,
        sort_keys=True,
    )

    CATALOG.write_text(
        (
            "# Generated by "
            "build_lower_quarter_native_prop_runtime.py; "
            "do not edit.\n"
            "class_name MeridianCivicNativePropCatalog\n"
            "extends RefCounted\n\n"
            "const ENTRIES := " + payload + "\n"
        ),
        encoding="utf-8",
    )

    print(f"built {len(catalog)} variants " f"in {len(CANVASES)} runtime families")


if __name__ == "__main__":
    main()
