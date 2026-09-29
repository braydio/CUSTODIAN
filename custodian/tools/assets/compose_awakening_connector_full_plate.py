#!/usr/bin/env python3
"""Compose the locked 04→05 connector from its approved flattened master.

All source pixels remain unchanged. The three route anchors use uniform
transforms; expanded, authored silhouette masks retain architecture around the
walkable footprint without treating near-black pixels as a color key.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "custodian/asset_drop/source_work/awakening/awakening_reliquary_dust_lung_connector/full_plate_source.png"
OUTPUT = ROOT / "custodian/asset_drop/inbox/awakening_reliquary_dust_lung_connector/full_plate_underlay.png"
REVIEW_DIR = ROOT / "reports/awakening_connector_04_05"
CANVAS = (1024, 576)

# (source anchor, destination anchor, uniform scale, expanded source crop,
#  authored silhouette polygon in source coordinates). The first three source
# rectangles in NORMALIZATION.md are route-registration anchors, not crops.
PIECES = [
    {
        "name": "eastward_hall",
        "anchor_source": (250, 530),
        "anchor_target": (160, 192),
        "scale": 704 / 887,
        "crop": (140, 400, 1374, 850),
        "silhouette": [
            (216, 530), (242, 496), (278, 476), (316, 456), (344, 433),
            (370, 418), (432, 411), (520, 412), (650, 409), (780, 413),
            (920, 410), (1060, 414), (1180, 410), (1284, 414), (1368, 420),
            (1370, 780), (1334, 798), (1288, 803), (1240, 812), (1186, 819),
            (1120, 812), (1044, 826), (960, 824), (872, 819), (786, 816),
            (700, 821), (616, 816), (532, 808), (460, 798), (405, 786),
            (360, 768), (322, 740), (288, 704), (260, 666), (242, 624),
            (232, 582),
        ],
    },
    {
        "name": "dust_lung_elbow",
        "anchor_source": (143, 370),
        "anchor_target": (96, 96),
        "scale": 128 / 214,
        "crop": (0, 204, 520, 650),
        "silhouette": [
            (0, 204), (444, 204), (478, 220), (494, 250), (486, 312),
            (466, 360), (434, 404), (418, 454), (420, 492), (444, 520),
            (480, 540), (508, 570), (520, 612), (490, 640), (0, 640),
        ],
    },
    {
        "name": "reliquary_landing",
        "anchor_source": (1030, 691),
        "anchor_target": (800, 320),
        "scale": 128 / 214,
        "crop": (860, 600, 1374, 1145),
        "silhouette": [
            (1004, 638), (1080, 630), (1156, 644), (1212, 668),
            (1250, 706), (1276, 752), (1296, 800), (1330, 824),
            (1372, 842), (1374, 1144), (700, 1144), (700, 1048),
            (744, 1014), (796, 986), (840, 954), (884, 930),
            (924, 904), (956, 874), (978, 836), (992, 794),
            (1000, 748), (1004, 700),
        ],
    },
]

TRAVERSAL_RECTS = [
    (96, 96, 224, 192),
    (160, 192, 864, 320),
    (800, 320, 928, 480),
]

# Exact registered room-underlay pixels are copied into the visual bleed. The
# live room plates render above this connector and crossfade near their Layout
# envelopes; matching their source pixels here prevents a doubled stair/landing
# when those plates and this underlay are simultaneously visible.
ROOM_OVERLAPS = [
    {
        "name": "dust_lung_room_overlap",
        "path": ROOT / "custodian/content/levels/awakening/05_dust_lung/awakening_dust_lung_underlay_1216x1216.png",
        "source_box": (448, 1056, 1216, 1216),
        "destination": (0, 0),
    },
    {
        "name": "reliquary_room_overlap",
        "path": ROOT / "custodian/content/levels/awakening/04_locker_reliquary/awakening_locker_reliquary_underlay_704x704.png",
        "source_box": (0, 0, 512, 160),
        "destination": (512, 416),
    },
]
ROOM_OVERLAP_FEATHER_PX = 32


def _piece_image(source: Image.Image, spec: dict[str, object]) -> tuple[Image.Image, tuple[int, int]]:
    left, top, right, bottom = spec["crop"]  # type: ignore[misc]
    crop = source.crop((left, top, right, bottom)).convert("RGBA")
    scale = float(spec["scale"])
    out_size = (round(crop.width * scale), round(crop.height * scale))
    rgb = crop.resize(out_size, Image.Resampling.LANCZOS)

    # Rasterize the manually authored outer silhouette at 4x to antialias only
    # its edge. This is geometric masking; source luminance is never examined.
    ss = 4
    mask_hi = Image.new("L", (crop.width * ss, crop.height * ss), 0)
    points = [((x - left) * ss, (y - top) * ss) for x, y in spec["silhouette"]]  # type: ignore[union-attr]
    ImageDraw.Draw(mask_hi).polygon(points, fill=255)
    mask = mask_hi.resize(crop.size, Image.Resampling.LANCZOS)
    mask = mask.resize(out_size, Image.Resampling.LANCZOS)
    rgb.putalpha(mask)

    source_anchor = spec["anchor_source"]  # type: ignore[assignment]
    target_anchor = spec["anchor_target"]  # type: ignore[assignment]
    origin = (
        round(target_anchor[0] - source_anchor[0] * scale),
        round(target_anchor[1] - source_anchor[1] * scale),
    )
    # Crop origin is part of the transform from source coordinates to target.
    origin = (origin[0] + round(left * scale), origin[1] + round(top * scale))
    return rgb, origin


def _feather_overlap_edges(region: Image.Image, feather_px: int) -> Image.Image:
    """Blend rectangular room crops into the connector without a canvas edge."""
    if feather_px <= 1:
        return region
    alpha = region.getchannel("A")
    feather = Image.new("L", region.size, 0)
    source_pixels = alpha.load()
    feather_pixels = feather.load()
    width, height = region.size
    denominator = feather_px - 1
    for y in range(height):
        for x in range(width):
            edge_distance = min(x, y, width - 1 - x, height - 1 - y)
            edge_weight = min(255, round(edge_distance * 255 / denominator))
            feather_pixels[x, y] = source_pixels[x, y] * edge_weight // 255
    region.putalpha(feather)
    return region


def main() -> None:
    source = Image.open(SOURCE)
    if source.size != (1374, 1145) or source.mode != "RGB":
        raise SystemExit(f"unexpected source contract {source.size} {source.mode}; refusing guessed transforms")

    plate = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    # The hall is the base. The two elbows/landings overlay it so their full
    # source architecture remains continuous around the exact route anchors.
    for spec in PIECES:
        piece, origin = _piece_image(source, spec)
        plate.alpha_composite(piece, dest=origin)
        print(
            f"{spec['name']}: crop={spec['crop']} anchor={spec['anchor_source']}"
            f"->{spec['anchor_target']} uniform_scale={spec['scale']:.8f}"
            f" output={piece.size} origin={origin}"
        )

    for overlap in ROOM_OVERLAPS:
        room_path = overlap["path"]
        if not room_path.is_file():
            raise SystemExit(f"registered room-overlap source missing: {room_path}")
        room = Image.open(room_path).convert("RGBA")
        left, top, right, bottom = overlap["source_box"]
        region = room.crop((left, top, right, bottom))
        if region.size != (right - left, bottom - top):
            raise SystemExit(f"invalid room overlap crop for {overlap['name']}: {region.size}")
        _feather_overlap_edges(region, ROOM_OVERLAP_FEATHER_PX)
        plate.alpha_composite(region, dest=overlap["destination"])
        print(
            f"{overlap['name']}: source={room_path.relative_to(ROOT)}"
            f" crop={overlap['source_box']} destination={overlap['destination']}"
            f" edge_feather={ROOM_OVERLAP_FEATHER_PX}px"
        )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)
    plate.save(OUTPUT)

    # A separate diagnostic preview marks the locked walkable rectangles.
    # These marks are not included in the runtime texture.
    preview = plate.copy()
    draw = ImageDraw.Draw(preview)
    for rect in TRAVERSAL_RECTS:
        draw.rectangle(rect, outline=(255, 48, 48, 255), width=2)
    preview.save(REVIEW_DIR / "underlay_registration_preview.png")
    print(f"wrote {OUTPUT}: {plate.size} {plate.mode}")
    print(f"diagnostic registration preview: {REVIEW_DIR / 'underlay_registration_preview.png'}")
    print("Foreground extraction is not attempted from the flattened RGB master; see task report.")


if __name__ == "__main__":
    main()
