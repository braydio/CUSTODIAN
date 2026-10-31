#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from custodian.tools.assets.asset_contract import load_family
from custodian.tools.assets.sprite_import import (
    SpriteImportContract,
    SpriteImportError,
    build_plan,
    contract_from_asset_family,
    contract_from_operator_profile,
    render_plan,
)


def png_bytes(image: Image.Image) -> bytes:
    import io
    stream = io.BytesIO()
    image.save(stream, format="PNG", optimize=False, compress_level=9)
    return stream.getvalue()


def contract(*, frame_count: int, columns: int, rows: int, cell: tuple[int, int],
             target: tuple[int, int], layout: str, policy: str = "pixel_crisp",
             resampler: str = "nearest", anchor: str = "center",
             semantic: dict[str, str] | None = None, digest: str = "a" * 64) -> SpriteImportContract:
    return SpriteImportContract(
        semantic_identity=semantic or {"kind": "fixture", "name": "shared-transform"},
        contract_sha256=digest, frame_count=frame_count, columns=columns, rows=rows,
        source_cell_width=cell[0], source_cell_height=cell[1],
        target_width=target[0], target_height=target[1], layout=layout,
        alpha_policy=policy, resampler=resampler, anchor=anchor,
    )


def colored_sheet(columns: int, rows: int, cell: tuple[int, int]) -> Image.Image:
    sheet = Image.new("RGBA", (columns * cell[0], rows * cell[1]), (0, 0, 0, 0))
    colors = [(220, 30 + i * 20, 40, 255) for i in range(columns * rows)]
    for index, color in enumerate(colors):
        frame = Image.new("RGBA", cell, (0, 0, 0, 0))
        ImageDraw.Draw(frame).rectangle((8, 8, cell[0] - 9, cell[1] - 9), fill=color)
        sheet.alpha_composite(frame, ((index % columns) * cell[0], (index // columns) * cell[1]))
    return sheet


def main() -> int:
    # Eight-frame horizontal golden: each cell uses one shared transform.
    source = png_bytes(colored_sheet(8, 1, (512, 512)))
    source_sha = hashlib.sha256(source).hexdigest()
    eight = contract(frame_count=8, columns=8, rows=1, cell=(512, 512),
                    target=(128, 128), layout="horizontal_strip")
    plan_a = build_plan(source, source_sha256=source_sha, contract=eight)
    plan_b = build_plan(source, source_sha256=source_sha, contract=eight)
    assert plan_a.to_json() == plan_b.to_json()
    doc = plan_a.to_dict()
    assert doc["geometry"]["expected_strip_wh"] == [1024, 128]
    assert doc["geometry"]["global_scale"] > 0
    assert doc["registrations"] == [{"frame": i, "dx": 0, "dy": 0} for i in range(8)]
    assert all(item["frame_order"] == list(range(8)) for item in [doc["input"]])
    out_a = render_plan(source, source_sha256=source_sha, contract=eight, plan=plan_a)
    out_b = render_plan(source, source_sha256=source_sha, contract=eight, plan=plan_a.to_json())
    assert hashlib.sha256(out_a).digest() == hashlib.sha256(out_b).digest()
    import io
    with Image.open(io.BytesIO(out_a)) as result:
        assert result.size == (1024, 128)
        centers = [result.getpixel((i * 128 + 64, 64)) for i in range(8)]
        assert [pixel[1] for pixel in centers] == [30 + i * 20 for i in range(8)]
        assert {pixel[3] for pixel in result.get_flattened_data()} <= {0, 255}

    # Six-frame row-major grid is emitted as one exact horizontal strip.
    grid_bytes = png_bytes(colored_sheet(3, 2, (256, 256)))
    grid_sha = hashlib.sha256(grid_bytes).hexdigest()
    six = contract(frame_count=6, columns=3, rows=2, cell=(256, 256),
                   target=(128, 128), layout="grid")
    six_plan = build_plan(grid_bytes, source_sha256=grid_sha, contract=six)
    six_png = render_plan(grid_bytes, source_sha256=grid_sha, contract=six, plan=six_plan)
    with Image.open(io.BytesIO(six_png)) as result:
        assert result.size == (768, 128)
        assert [result.getpixel((i * 128 + 64, 64))[1] for i in range(6)] == [30 + i * 20 for i in range(6)]

    # One-frame prop geometry is rectangular and exact.
    prop = Image.new("RGBA", (128, 160), (0, 0, 0, 0))
    ImageDraw.Draw(prop).polygon([(22, 12), (100, 25), (88, 140), (40, 150)], fill=(20, 120, 210, 255))
    prop_bytes = png_bytes(prop); prop_sha = hashlib.sha256(prop_bytes).hexdigest()
    prop_contract = contract(frame_count=1, columns=1, rows=1, cell=(128, 160),
                             target=(128, 160), layout="single_image", anchor="base-center")
    prop_plan = build_plan(prop_bytes, source_sha256=prop_sha, contract=prop_contract)
    prop_png = render_plan(prop_bytes, source_sha256=prop_sha, contract=prop_contract, plan=prop_plan)
    with Image.open(io.BytesIO(prop_png)) as result:
        assert result.size == (128, 160)

    # The declared illustrated soft preset retains intermediate edge alpha;
    # the same source under the legacy pixel-crisp preset stays binary.
    fine = Image.new("RGBA", (128, 160), (0, 0, 0, 0))
    draw = ImageDraw.Draw(fine)
    draw.polygon([(11, 12), (117, 31), (22, 148)], fill=(230, 180, 90, 255))
    for x in range(12, 118, 3):
        draw.line((x, 15, x + 1, 145), fill=(245, 220, 160, 96), width=1)
    fine_bytes = png_bytes(fine); fine_sha = hashlib.sha256(fine_bytes).hexdigest()
    soft = contract(frame_count=1, columns=1, rows=1, cell=(128, 160), target=(32, 40),
                    layout="single_image", policy="illustrated_structure_soft", resampler="lanczos")
    soft_plan = build_plan(fine_bytes, source_sha256=fine_sha, contract=soft)
    soft_png = render_plan(fine_bytes, source_sha256=fine_sha, contract=soft, plan=soft_plan)
    crisp = contract(frame_count=1, columns=1, rows=1, cell=(128, 160), target=(32, 40),
                     layout="single_image", policy="pixel_crisp", resampler="nearest")
    crisp_plan = build_plan(fine_bytes, source_sha256=fine_sha, contract=crisp)
    crisp_png = render_plan(fine_bytes, source_sha256=fine_sha, contract=crisp, plan=crisp_plan)
    with Image.open(io.BytesIO(soft_png)) as soft_result, Image.open(io.BytesIO(crisp_png)) as crisp_result:
        alpha = set(soft_result.getchannel("A").get_flattened_data())
        assert any(0 < value < 255 for value in alpha)
        assert set(crisp_result.getchannel("A").get_flattened_data()) <= {0, 255}

    # Explicit family and Operator adapters bind semantic identity/digest.
    family = load_family(ROOT / "custodian/content/metadata/assets/families/carrow_machine_house_floor.asset.json")
    family_contract = contract_from_asset_family(
        family, state_id="slab_plain_01", direction="omni", source_cell=(32, 32),
        alpha_policy="opaque_tile", resampler="nearest", anchor="center",
    )
    assert family_contract.semantic_identity["state"] == "slab_plain_01"
    profile_doc = json.loads((ROOT / "custodian/content/data/operator/authoring/operator_art_profile.json").read_text())
    op_contract = contract_from_operator_profile(
        profile_doc, profile_id="operator_2_5d_128", frame_count=8, columns=8, rows=1,
        source_cell=(128, 128), layout="horizontal_strip", target_size=(128, 128),
    )
    assert op_contract.alpha_policy == "pixel_crisp"
    assert op_contract.contract_sha256 == profile_doc["profiles"]["operator_2_5d_128"]["profile_sha256"]

    # Opaque tile policy is explicit and cannot letterbox or accept transparency.
    opaque = png_bytes(Image.new("RGB", (32, 32), (80, 70, 60)))
    opaque_sha = hashlib.sha256(opaque).hexdigest()
    tile = build_plan(opaque, source_sha256=opaque_sha, contract=family_contract)
    tile_png = render_plan(opaque, source_sha256=opaque_sha, contract=family_contract, plan=tile)
    with Image.open(io.BytesIO(tile_png)) as result:
        assert result.size == (32, 32) and result.getchannel("A").getextrema() == (255, 255)

    # Ambiguous grids, malformed source dimensions, empty sources and digest mismatches fail closed.
    try:
        contract(frame_count=5, columns=3, rows=2, cell=(4, 4), target=(4, 4), layout="grid")
    except SpriteImportError as exc:
        assert "capacity" in str(exc)
    else:
        raise AssertionError("ambiguous grid capacity accepted")
    try:
        build_plan(grid_bytes, source_sha256=grid_sha,
                   contract=contract(frame_count=6, columns=3, rows=2, cell=(255, 256),
                                     target=(128, 128), layout="grid"))
    except SpriteImportError as exc:
        assert "does not match explicit" in str(exc)
    else:
        raise AssertionError("uneven source-cell division accepted")
    empty = png_bytes(Image.new("RGBA", (8, 8), (0, 0, 0, 0))); empty_sha = hashlib.sha256(empty).hexdigest()
    try:
        build_plan(empty, source_sha256=empty_sha,
                   contract=contract(frame_count=1, columns=1, rows=1, cell=(8, 8),
                                     target=(8, 8), layout="single_image"))
    except SpriteImportError as exc:
        assert "no visible alpha" in str(exc)
    else:
        raise AssertionError("empty required source accepted")
    try:
        contract(frame_count=1, columns=1, rows=1, cell=(8, 8), target=(0, 8), layout="single_image")
    except SpriteImportError as exc:
        assert "positive integer" in str(exc)
    else:
        raise AssertionError("nonpositive target dimension accepted")
    try:
        build_plan(source, source_sha256="0" * 64, contract=eight)
    except SpriteImportError as exc:
        assert "does not match" in str(exc)
    else:
        raise AssertionError("mismatched source digest accepted")

    # Resource ceilings and unsupported single-image converter plans fail before output writes.
    small = png_bytes(Image.new("RGBA", (16, 1), (10, 20, 30, 255))); small_sha = hashlib.sha256(small).hexdigest()
    costly = contract(frame_count=16, columns=16, rows=1, cell=(1, 1), target=(512, 512), layout="horizontal_strip")
    try:
        build_plan(small, source_sha256=small_sha, contract=costly)
    except SpriteImportError as exc:
        assert "preparation needs" in str(exc)
    else:
        raise AssertionError("excessive preparation allocation accepted")

    with tempfile.TemporaryDirectory(prefix="sprite-import-smoke-") as directory:
        root = Path(directory); source_path = root / "source.png"; source_path.write_bytes(prop_bytes)
        before = source_path.read_bytes()
        converter_path = ROOT / "custodian/tools/art/custodian_pixelart_converter.py"
        same = subprocess.run([sys.executable, str(converter_path), str(source_path), str(source_path),
                               "--size", "128x160", "--force"], text=True, capture_output=True)
        assert same.returncode != 0 and "refusing to overwrite the source" in (same.stderr + same.stdout).lower()
        assert source_path.read_bytes() == before
        plan_path = root / "unsupported-plan.json"; plan_path.write_text(prop_plan.to_json())
        output_path = root / "single-output.png"
        ignored = subprocess.run([sys.executable, str(converter_path), str(source_path), str(output_path),
                                  "--size", "128x160", "--normalization-plan", str(plan_path)],
                                 text=True, capture_output=True)
        assert ignored.returncode != 0 and "refusing to ignore" in ignored.stderr
        assert not output_path.exists()

    print("PASS sprite_import_shared_transform: canonical plans, 8f/6f geometry, prop, alpha policies, adapters, refusal controls")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
