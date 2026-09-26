#!/usr/bin/env python3
"""Build the locked 04→05 connector full plate from approved source regions."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "custodian/asset_drop/source_work/awakening/awakening_reliquary_dust_lung_connector/full_plate_source.png"
OUTPUT = ROOT / "custodian/asset_drop/inbox/awakening_reliquary_dust_lung_connector/full_plate.png"

# Pixel-edge boxes, measured on the 1374×1145 generated master. Each box follows
# one coherent arm and is independently reduced with Lanczos; dark stone stays.
REGIONS = {
    "dust_lung": ((143, 370, 357, 530), (0, 0, 128, 96)),
    "east_hall": ((250, 530, 1137, 691), (64, 96, 768, 224)),
    "reliquary": ((1030, 691, 1244, 958), (704, 224, 832, 384)),
}


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    if source.size != (1374, 1145):
        raise SystemExit(f"unexpected source dimensions {source.size}; refusing guessed crop")
    plate = Image.new("RGBA", (832, 384), (0, 0, 0, 0))
    for name, (crop_box, target_box) in REGIONS.items():
        crop = source.crop(crop_box)
        target_size = (target_box[2] - target_box[0], target_box[3] - target_box[1])
        scale = min(target_size[0] / crop.width, target_size[1] / crop.height)
        scaled_size = (round(crop.width * scale), round(crop.height * scale))
        if abs(scaled_size[0] - target_size[0]) > 1 or abs(scaled_size[1] - target_size[1]) > 1:
            raise SystemExit(f"{name} aspect mismatch: source {crop.size}, target {target_size}")
        normalized = crop.resize(scaled_size, Image.Resampling.LANCZOS)
        # Integer-cell rounding may leave one pixel on an edge. Center-crop or
        # pad that subpixel rounding only; the creature/architecture scale is
        # uniform and no source content is independently stretched.
        if scaled_size != target_size:
            cell = Image.new("RGBA", target_size, (0, 0, 0, 0))
            cell.alpha_composite(normalized, ((target_size[0] - scaled_size[0]) // 2,
                                               (target_size[1] - scaled_size[1]) // 2))
            normalized = cell
        plate.alpha_composite(normalized, (target_box[0], target_box[1]))
        print(f"{name}: crop={crop_box} {crop.width}x{crop.height}; "
              f"target={target_box} {target_size[0]}x{target_size[1]}; "
              f"uniform_scale={scale:.4f}; rounded={scaled_size}")

    # The master has a baked dark field. These crops are wholly inside the
    # authored passage, so retain every dark stone pixel and make only the
    # exterior of the locked dogleg transparent.
    alpha = Image.new("L", plate.size, 0)
    from PIL import ImageDraw
    draw = ImageDraw.Draw(alpha)
    for _, target_box in REGIONS.values():
        draw.rectangle(target_box, fill=255)
    plate.putalpha(alpha)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    plate.save(OUTPUT)
    print(f"wrote {OUTPUT}: {plate.size} {plate.mode}; transparent outside three authored regions")


if __name__ == "__main__":
    main()
