#!/usr/bin/env python3
"""Derive AP2 Alpine cliff runtime assets from the approved source masters.

This is a deterministic crop/contain normalizer, not an art generator. Source
masters stay immutable; all final payloads are written to the AP2 Asset V2
inboxes and accompanied by a reproducible derivation report/contact sheet.
"""
from __future__ import annotations

import hashlib
import json
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "asset_drop/source_work"
INBOX = ROOT / "asset_drop/inbox"
PREP = ROOT / "asset_drop/production_prep/alpine_cliff_presentation_v1"
ALPHA_CUTOFF = 8

# output state -> (source master, normalized crop box in source pixels, size)
FASCIA = {
    "top_clean_01": ("procgen/procgen_alpine_cliff_contact/contact_clean_granite_master_source.png", (160, 32, 1190, 1062), (32, 32)),
    "top_broken_01": ("procgen/procgen_alpine_cliff_contact/contact_vegetated_broken_master_source.png", (110, 24, 1140, 1054), (32, 32)),
    "top_snow_01": ("procgen/procgen_alpine_cliff_contact/contact_natural_plateau_master_source.png", (80, 32, 1110, 1062), (32, 32)),
    "top_retained_01": ("procgen/procgen_alpine_cliff_contact/contact_industrial_master_source.png", (100, 32, 1130, 1062), (32, 32)),
    "body_strata_01": ("procgen/procgen_alpine_cliff_fascia/body_strata_01_source.png", (220, 300, 1034, 1114), (32, 32)),
    "body_strata_02": ("procgen/procgen_alpine_cliff_fascia/body_strata_02_source.png", (140, 180, 954, 994), (32, 32)),
    "body_cracked_01": ("procgen/procgen_alpine_cliff_fascia/body_cracked_01_source.png", (180, 200, 994, 1014), (32, 32)),
    "body_snow_streak_01": ("procgen/procgen_alpine_cliff_fascia/body_snow_streak_01_source.png", (200, 160, 1014, 974), (32, 32)),
    "body_rooted_01": ("procgen/procgen_alpine_cliff_fascia/body_rooted_01_source.png", (180, 200, 994, 1014), (32, 32)),
    "body_retaining_01": ("procgen/procgen_alpine_cliff_fascia/body_retaining_01_source.png", (160, 180, 974, 994), (32, 32)),
    "bottom_mist_01": ("procgen/procgen_alpine_cliff_fascia/bottom_mist_01_source.png", (180, 160, 994, 974), (32, 32)),
    "bottom_mist_broken_01": ("procgen/procgen_alpine_cliff_fascia/bottom_mist_broken_01_source.png", (240, 200, 1054, 1014), (32, 32)),
}
CONTACT = {
    "south_broad_01": ("procgen/procgen_alpine_cliff_contact/contact_natural_plateau_master_source.png", (0, 0, 1254, 1254), (1024, 512)),
    "south_broken_01": ("procgen/procgen_alpine_cliff_contact/contact_vegetated_broken_master_source.png", (0, 0, 1254, 1254), (1024, 512)),
    "south_rooted_01": ("procgen/procgen_alpine_cliff_contact/contact_vegetated_broken_master_source.png", (0, 0, 1254, 1254), (1024, 512)),
    "east_broad_01": ("procgen/procgen_alpine_cliff_contact/contact_industrial_master_source.png", (0, 0, 1254, 1254), (512, 1024)),
    "west_broad_01": ("procgen/procgen_alpine_cliff_contact/contact_clean_granite_master_source.png", (0, 0, 1254, 1254), (512, 1024)),
    "north_broad_01": ("procgen/procgen_alpine_cliff_contact/contact_clean_granite_master_source.png", (0, 0, 1254, 1254), (1024, 320)),
    "corner_se_01": ("procgen/procgen_alpine_cliff_contact/contact_industrial_master_source.png", (0, 0, 1254, 1254), (768, 768)),
    "corner_sw_01": ("procgen/procgen_alpine_cliff_contact/contact_vegetated_broken_master_source.png", (0, 0, 1254, 1254), (768, 768)),
    "corner_ne_01": ("procgen/procgen_alpine_cliff_contact/contact_clean_granite_master_source.png", (0, 0, 1254, 1254), (768, 768)),
    "corner_nw_01": ("procgen/procgen_alpine_cliff_contact/contact_natural_plateau_master_source.png", (0, 0, 1254, 1254), (768, 768)),
}
CONTACT_ROTATIONS: dict[str, int] = {}
CONTACT_SOCKETS = {
    # Authored pixels on the final canvases. Each socket sits inside the
    # geology, far enough from its frontier-facing silhouette that the art
    # overlaps the playable edge instead of meeting it at a single pixel.
    "south_broad_01": (482, 180),
    "south_broken_01": (474, 180),
    "south_rooted_01": (474, 180),
    "east_broad_01": (75, 400),
    "west_broad_01": (462, 486),
    "north_broad_01": (529, 270),
    "corner_se_01": (152, 126),
    "corner_sw_01": (541, 240),
    "corner_ne_01": (132, 581),
    "corner_nw_01": (716, 674),
}
CONTACT_SOCKET_INWARD_DIRECTIONS = {
    "south_broad_01": ((0, -1),),
    "south_broken_01": ((0, -1),),
    "south_rooted_01": ((0, -1),),
    "east_broad_01": ((-1, 0),),
    "west_broad_01": ((1, 0),),
    "north_broad_01": ((0, 1),),
    "corner_se_01": ((-1, 0), (0, -1)),
    "corner_sw_01": ((1, 0), (0, -1)),
    "corner_ne_01": ((-1, 0), (0, 1)),
    "corner_nw_01": ((1, 0), (0, 1)),
}
MIN_SOCKET_EMBED_PX = 24
SOCKET_EMBED_MIN_BY_STATE = {
    "south_broad_01": 96,
    "south_broken_01": 96,
    "south_rooted_01": 96,
}
DEPTH = {
    "rocky_upland_descending_conifer_ledge": ("procgen/procgen_alpine_cliff_contact/contact_vegetated_broken_master_source.png", (80, 340, 1174, 1044), (896, 576)),
    "rocky_upland_broken_retaining_drop": ("procgen/procgen_alpine_cliff_contact/contact_industrial_master_source.png", (80, 340, 1174, 1044), (896, 576)),
    "rocky_upland_lower_ledge_mist": ("procgen/procgen_alpine_cliff_contact/contact_natural_plateau_master_source.png", (180, 300, 994, 870), (640, 448)),
    "rocky_upland_service_ruin_drop": ("procgen/procgen_alpine_cliff_contact/contact_industrial_master_source.png", (180, 300, 994, 870), (640, 448)),
}
RUNTIME_DOMAINS = {
    "procgen_alpine_cliff_fascia": "tiles/mountain_cliffs/alpine_fascia",
    "procgen_alpine_cliff_contact": "tiles/procgen_macro/runtime/alpine_cliff_contact",
    "procgen_depth_chunks": "backgrounds/procgen/depth_chunks",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def remove_border_connected_background(image: Image.Image, tolerance: int = 24) -> Image.Image:
    """Remove a neutral matte only when it forms a dominant border-connected region.

    Existing transparent alpha is authoritative. Opaque gray rock is preserved
    unless a neutral color occupies a substantial share of the image border and
    is connected to that border.
    """
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    border: list[tuple[int, int, int]] = []
    for x in range(width):
        for y in (0, height - 1):
            r, g, b, a = pixels[x, y]
            if a > ALPHA_CUTOFF and max(r, g, b) - min(r, g, b) <= 24:
                border.append((r, g, b))
    for y in range(1, height - 1):
        for x in (0, width - 1):
            r, g, b, a = pixels[x, y]
            if a > ALPHA_CUTOFF and max(r, g, b) - min(r, g, b) <= 24:
                border.append((r, g, b))
    perimeter = max(1, 2 * width + 2 * height - 4)
    if len(border) < perimeter * 0.40:
        return image

    # Use the median neutral border color and require a connected match. A
    # scattered gray surface texture cannot become a global color key.
    reference = tuple(sorted(channel)[len(border) // 2] for channel in zip(*border))
    tolerance_sq = tolerance * tolerance

    def is_background(x: int, y: int) -> bool:
        r, g, b, a = pixels[x, y]
        if a <= ALPHA_CUTOFF:
            return True
        if max(r, g, b) - min(r, g, b) > 24:
            return False
        return sum((value - target) ** 2 for value, target in zip((r, g, b), reference)) <= tolerance_sq

    queue: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()
    for x in range(width):
        queue.extend(((x, 0), (x, height - 1)))
    for y in range(1, height - 1):
        queue.extend(((0, y), (width - 1, y)))
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not is_background(x, y):
            continue
        seen.add((x, y))
        if x > 0: queue.append((x - 1, y))
        if x + 1 < width: queue.append((x + 1, y))
        if y > 0: queue.append((x, y - 1))
        if y + 1 < height: queue.append((x, y + 1))
    for x, y in seen:
        pixels[x, y] = (0, 0, 0, 0)
    return image


def normalize(
    src_path: Path,
    box: tuple[int, int, int, int],
    size: tuple[int, int],
    irregular_contact: bool = False,
    rotation_degrees: int = 0,
) -> Image.Image:
    with Image.open(src_path) as im:
        source = im.convert("RGBA")
    if box[0] < 0 or box[1] < 0 or box[2] > source.width or box[3] > source.height:
        raise ValueError(f"crop outside source bounds: {src_path.name} {box} vs {source.size}")
    crop = source.crop(box)
    if irregular_contact:
        crop = remove_border_connected_background(crop)
        # These contact masters contain geology, not mist. Make their alpha
        # silhouette solid before scaling so source antialias/feather pixels
        # do not leave translucent granite edges in runtime art.
        crop.putalpha(crop.getchannel("A").point(lambda value: 255 if value >= 128 else 0))
        if rotation_degrees:
            crop = crop.rotate(rotation_degrees, expand=True, resample=Image.Resampling.NEAREST)
        # Retain the source's irregular alpha silhouette and leave 24 px of
        # transparent breathing room on every contact canvas edge.
        bounds = crop.getchannel("A").getbbox()
        if bounds is None:
            raise ValueError(f"contact crop has no visible subject: {src_path.name} {box}")
        crop = crop.crop(bounds)
        target_size = (max(1, size[0] - 32), max(1, size[1] - 32))
    else:
        target_size = size
    scale = min(target_size[0] / crop.width, target_size[1] / crop.height)
    resized_size = (max(1, round(crop.width * scale)), max(1, round(crop.height * scale)))
    resized = crop.resize(resized_size, Image.Resampling.LANCZOS)
    # Contact edges stay opaque and crisp; only depth/mist assets retain
    # authored partial alpha. Nearest-neighbor alpha avoids a soft rock fringe.
    if irregular_contact:
        alpha = crop.getchannel("A").resize(resized_size, Image.Resampling.NEAREST)
    else:
        alpha = resized.getchannel("A").point(lambda value: 0 if value <= ALPHA_CUTOFF else value)
    resized.putalpha(alpha)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2))
    return canvas


def contact_socket(state: str, size: tuple[int, int]) -> tuple[int, int]:
    """Return the declared socket seed, before resolving it to visible alpha."""
    socket = CONTACT_SOCKETS[state]
    if not (0 <= socket[0] < size[0] and 0 <= socket[1] < size[1]):
        raise ValueError(f"{state}: socket {socket} outside canvas {size}")
    return socket


def resolve_contact_socket(image: Image.Image, state: str) -> tuple[int, int]:
    """Snap the authored frontier point to the nearest opaque geology pixel."""
    width, height = image.size
    target = contact_socket(state, (width, height))
    alpha = image.convert("RGBA").getchannel("A")
    pixels = alpha.load()
    nearest: tuple[int, int] | None = None
    best_distance = 1 << 60
    for y in range(height):
        for x in range(width):
            if pixels[x, y] <= ALPHA_CUTOFF:
                continue
            distance = (x - target[0]) ** 2 + (y - target[1]) ** 2
            if distance < best_distance:
                best_distance = distance
                nearest = (x, y)
    if nearest is None:
        raise ValueError(f"{state}: cannot resolve frontier socket on empty alpha")
    if best_distance > round(min(width, height) * 0.45) ** 2:
        raise ValueError(f"{state}: nearest geology is too far from declared frontier socket: {nearest}")
    return nearest


def validate_contact_alpha(image: Image.Image, state: str) -> dict[str, object]:
    """Reject empty, rectangular, or unowned straight crop boundaries."""
    alpha = image.convert("RGBA").getchannel("A")
    width, height = alpha.size
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError(f"{state}: empty contact")
    left, top, right, bottom = bounds
    margins = {"left": left, "top": top, "right": width - right, "bottom": height - bottom}
    if min(margins.values()) < 16:
        raise ValueError(f"{state}: transparent contact margin below 16 px: {margins}")

    # A straight crop wall spans a long, nearly continuous opaque run along
    # the alpha silhouette's bounds. The frontier socket is authored inside
    # the silhouette; unrelated canvas edges must remain irregular.
    pixels = alpha.load()
    socket = resolve_contact_socket(image, state)
    socket_embed_depth: dict[str, int] = {}
    for dx, dy in CONTACT_SOCKET_INWARD_DIRECTIONS[state]:
        depth = 0
        x, y = socket
        while 0 <= x < width and 0 <= y < height and pixels[x, y] > ALPHA_CUTOFF:
            depth += 1
            x += dx
            y += dy
        axis = "x" if dx else "y"
        socket_embed_depth[axis] = depth
        minimum_embed = SOCKET_EMBED_MIN_BY_STATE.get(state, MIN_SOCKET_EMBED_PX)
        if depth < minimum_embed:
            raise ValueError(
                f"{state}: frontier socket only touches the silhouette on {axis}; "
                f"needs {minimum_embed}px opaque overlap, got {depth}px"
            )
    socket_sides: set[str] = set()
    declared_socket = contact_socket(state, (width, height))
    if declared_socket[0] <= 16: socket_sides.add("left")
    if declared_socket[0] >= width - 16: socket_sides.add("right")
    if declared_socket[1] <= 16: socket_sides.add("top")
    if declared_socket[1] >= height - 16: socket_sides.add("bottom")
    edge_coverage: dict[str, float] = {}
    edge_runs: dict[str, int] = {}
    edges = {
        "left": [pixels[left, y] > ALPHA_CUTOFF for y in range(top, bottom)],
        "right": [pixels[right - 1, y] > ALPHA_CUTOFF for y in range(top, bottom)],
        "top": [pixels[x, top] > ALPHA_CUTOFF for x in range(left, right)],
        "bottom": [pixels[x, bottom - 1] > ALPHA_CUTOFF for x in range(left, right)],
    }
    for edge, values in edges.items():
        fraction = sum(values) / max(1, len(values))
        longest = run = 0
        for visible in values:
            run = run + 1 if visible else 0
            longest = max(longest, run)
        edge_coverage[edge] = round(fraction, 6)
        edge_runs[edge] = longest
        if edge not in socket_sides and longest >= max(8, round(len(values) * 0.25)):
            raise ValueError(f"{state}: unowned straight crop wall on {edge} silhouette ({longest}/{len(values)} px)")

    opaque = sum(alpha.histogram()[ALPHA_CUTOFF + 1 :])
    coverage = opaque / (width * height)
    if coverage >= 0.98:
        raise ValueError(f"{state}: contact remains a near-rectangular opaque crop ({coverage:.1%})")
    return {
        "alpha_bounds": list(bounds),
        "transparent_margins": margins,
        "opaque_edge_coverage": edge_coverage,
        "opaque_edge_longest_run_px": edge_runs,
        "socket_sides": sorted(socket_sides),
        "alpha_crop_wall_ok": True,
        "socket_px": list(socket),
        "socket_embed_depth_px": socket_embed_depth,
    }


def main() -> int:
    report: dict[str, object] = {
        "schema": "custodian.alpine_cliff_presentation_derivation.v1",
        "resampling": "Pillow LANCZOS once after authored crop; aspect-preserving contain on transparent canvas",
        "alpha_cutoff": ALPHA_CUTOFF,
        "contact_alpha_rule": "preserve geology-only alpha silhouette; clear only border-connected neutral matte within RGB distance 24; reject unowned opaque canvas-edge spans >=25%; add at least 16 px transparent canvas margin",
        "contact_sockets": CONTACT_SOCKETS,
        "contact_socket_min_embed_px": MIN_SOCKET_EMBED_PX,
        "contact_socket_min_embed_by_state": SOCKET_EMBED_MIN_BY_STATE,
        "source_master_batch": "alpine-cliff-source-family-v1",
        "source_master_zip_sha256": "e804c5d9d55f0610cafde5f4169a6b36438b0e08469b212ac3fff84618b127f3",
        "outputs": [],
    }
    contact_tiles: list[tuple[str, Image.Image]] = []
    for family, spec in (
        ("procgen_alpine_cliff_fascia", FASCIA),
        ("procgen_alpine_cliff_contact", CONTACT),
        ("procgen_depth_chunks", DEPTH),
    ):
        outputs = []
        for state, (source_rel, crop, size) in spec.items():
            source_path = SOURCE / source_rel
            if not source_path.is_file():
                raise FileNotFoundError(source_path)
            target_path = INBOX / family / f"{state}.png"
            target_path.parent.mkdir(parents=True, exist_ok=True)
            rotation = CONTACT_ROTATIONS.get(state, 0) if family == "procgen_alpine_cliff_contact" else 0
            image = normalize(source_path, crop, size, irregular_contact=family == "procgen_alpine_cliff_contact", rotation_degrees=rotation)
            alpha_validation = validate_contact_alpha(image, state) if family == "procgen_alpine_cliff_contact" else {}
            image.save(target_path, format="PNG", compress_level=9)
            runtime_name = f"depth_{state}_v1.png" if family == "procgen_depth_chunks" else f"{state}.png"
            runtime_path = ROOT / "content" / RUNTIME_DOMAINS[family] / runtime_name
            item = {
                "family": family,
                "state": state,
                "source": source_rel,
                "source_sha256": sha(source_path),
                "source_size": list(Image.open(source_path).size),
                "crop_box": list(crop),
                "rotation_degrees": rotation,
                "socket_px": list(alpha_validation["socket_px"]) if alpha_validation else None,
                "inbox_output": target_path.relative_to(ROOT).as_posix(),
                "output": f"custodian/{runtime_path.relative_to(ROOT).as_posix()}",
                "output_size": list(size),
                "output_sha256": sha(target_path),
                "alpha_extrema": list(image.getchannel("A").getextrema()),
                "alpha_bounds": list(image.getchannel("A").getbbox()) if image.getchannel("A").getbbox() else None,
                "alpha_coverage": round(sum(image.getchannel("A").histogram()[1:]) / (size[0] * size[1]), 6),
                **alpha_validation,
            }
            outputs.append(item)
            if family == "procgen_alpine_cliff_contact":
                contact_tiles.append((state, image.copy()))
            print(f"{family}/{state}: {size[0]}x{size[1]} sha256={item['output_sha256']}")
        report["outputs"].extend(outputs)

    PREP.mkdir(parents=True, exist_ok=True)
    (PREP / "derivation_report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    sheet = Image.new("RGBA", (4 * 384, 3 * 300), (28, 34, 39, 255))
    draw = ImageDraw.Draw(sheet)
    for index, (name, image) in enumerate(contact_tiles):
        thumb = image.copy()
        thumb.thumbnail((368, 260), Image.Resampling.LANCZOS)
        x, y = (index % 4) * 384 + 8, (index // 4) * 300 + 28
        sheet.alpha_composite(thumb, (x, y))
        draw.text((x, y - 19), name, fill=(240, 240, 240, 255))
    sheet.convert("RGB").save(PREP / "contact_review.png", compress_level=9)
    print(f"Wrote {len(report['outputs'])} normalized states and derivation report")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
