#!/usr/bin/env python3
"""Build, render and falsify the south Operator Blender 2D candidate rig."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[3]
BUNDLE = ROOT / "custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1"
BUILD = ROOT / "custodian/tools/operator/motion_foundry/blender/build_operator_2d_rig.py"
RENDER = ROOT / "custodian/tools/operator/motion_foundry/blender/render_operator_2d_rig.py"
BLEND = BUNDLE / "blender/operator_south_cutout_rig_v1.blend"
RECEIPT = BUNDLE / "blender/rig_build_receipt.json"
PROOF_DIR = ROOT / ".ai/operator_motion_foundry/blender/south_idle_v1"
SOURCE_IMAGE = BUNDLE / "extracted/source_south_visible_frame.png"
EXPECTED_SOURCE_SHA256 = "61c7518b31a28d7b98af5efdb035316550b769abea7eb33ff0466544040172a3"


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(command: list[str], *, expected: int = 0) -> subprocess.CompletedProcess:
    result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
    if result.returncode != expected:
        raise RuntimeError(
            f"command exit {result.returncode}, expected {expected}: {' '.join(command)}\n"
            f"stdout:\n{result.stdout[-3000:]}\nstderr:\n{result.stderr[-3000:]}"
        )
    return result


def blender_version(blender: str) -> str:
    result = run([blender, "--background", "--factory-startup", "--python-expr", "import bpy; print(bpy.app.version_string)"])
    for line in result.stdout.splitlines():
        if line.strip().endswith(("LTS", ".0", ".1", ".2", ".3", ".4", ".5", ".6", ".7", ".8", ".9")):
            if any(ch.isdigit() for ch in line):
                return line.strip()
    return "unknown"


def builder_command(blender: str, source_root: Path, blend: Path, receipt: Path) -> list[str]:
    return [blender, "--background", "--factory-startup", "--python", str(BUILD), "--",
            "--source-root", str(source_root), "--output", str(blend), "--receipt", str(receipt)]


def render_command(blender: str, blend: Path, out: Path) -> list[str]:
    return [blender, "--background", str(blend), "--python", str(RENDER), "--",
            "--blend", str(blend), "--output-dir", str(out), "--source-root", str(BUNDLE)]


def rgba(path: Path) -> Image.Image:
    with Image.open(path) as image:
        return image.convert("RGBA")


def pixel_hash(image: Image.Image) -> str:
    return hashlib.sha256(image.tobytes()).hexdigest()


def expect_builder_rejects(blender: str, source_root: Path, temp: Path, label: str, reason: str) -> None:
    output = temp / f"{label}.blend"
    result = subprocess.run(
        builder_command(blender, source_root, output, temp / f"{label}.json"),
        cwd=ROOT, text=True, capture_output=True,
    )
    transcript = result.stdout + result.stderr
    if reason not in transcript or output.exists():
        raise RuntimeError(f"builder accepted invalid source fixture: {label}")


def main() -> int:
    blender = shutil.which("blender")
    if not blender:
        raise SystemExit("FAIL: Blender executable is required; this validation cannot be skipped")
    version = blender_version(blender)
    inventory_path = BUNDLE / "bundle_inventory.json"
    inventory = json.loads(inventory_path.read_text())
    actual = {
        p.relative_to(BUNDLE).as_posix(): file_sha(p)
        for p in BUNDLE.rglob("*")
        if p.is_file() and p not in (inventory_path, BLEND, RECEIPT) and "__pycache__" not in p.parts
    }
    if actual != inventory["files"]:
        raise SystemExit("source-work bundle differs from its published inventory")
    if file_sha(BUNDLE / "source/CUSTODIAN_OPERATOR_RUNTIME_REFERENCE_128.aseprite") != EXPECTED_SOURCE_SHA256:
        raise SystemExit("original Operator source hash differs from the pinned source-work receipt")
    rig = json.loads((BUNDLE / "extracted/rig.json").read_text())
    if len(rig.get("parts", [])) != 23 or rig.get("direction") != "s":
        raise SystemExit("expected the exact 23-part south-facing source rig")

    BLEND.parent.mkdir(parents=True, exist_ok=True)
    RECEIPT.parent.mkdir(parents=True, exist_ok=True)
    PROOF_DIR.mkdir(parents=True, exist_ok=True)
    run(builder_command(blender, BUNDLE, BLEND, RECEIPT))

    with tempfile.TemporaryDirectory(prefix="operator_blender_2d_") as tmp_name:
        temp = Path(tmp_name)
        first, second = temp / "render-a", temp / "render-b"
        run(render_command(blender, BLEND, first))
        run(render_command(blender, BLEND, second))

        frame_hashes = []
        frames = []
        for index in range(15):
            first_image = rgba(first / f"frame_{index:03d}.png")
            second_image = rgba(second / f"frame_{index:03d}.png")
            if first_image.size != (128, 128) or pixel_hash(first_image) != pixel_hash(second_image):
                raise SystemExit(f"frame {index} has wrong dimensions or is nondeterministic")
            normalized_path = PROOF_DIR / f"frame_{index:03d}.png"
            first_image.save(normalized_path, format="PNG", optimize=False)
            frame_hashes.append(pixel_hash(first_image))
            frames.append(first_image)

        source = rgba(SOURCE_IMAGE)
        neutral = rgba(first / "neutral.png")
        difference = ImageChops.difference(source, neutral)
        diff_bytes = difference.tobytes()
        mismatch_count = sum(any(diff_bytes[offset : offset + 4]) for offset in range(0, len(diff_bytes), 4))
        if neutral.size != (128, 128) or mismatch_count != 0:
            raise SystemExit(f"Blender neutral render mismatch: {mismatch_count} pixels")
        if neutral.getchannel("A").getbbox() != (40, 20, 89, 105):
            raise SystemExit("neutral silhouette bounds do not match the pinned source")
        if sum(value > 0 for value in neutral.getchannel("A").tobytes()) != 2440:
            raise SystemExit("neutral render does not contain exactly 2,440 visible pixels")
        if pixel_hash(frames[0]) != pixel_hash(neutral) or pixel_hash(frames[-1]) != pixel_hash(neutral):
            raise SystemExit("preview does not cleanly return to its neutral pose")
        if pixel_hash(frames[7]) == pixel_hash(neutral):
            raise SystemExit("the keyed idle preview contains no visible motion")
        for index in range(15):
            feet_source = source.crop((45, 88, 86, 106))
            feet_frame = frames[index].crop((45, 88, 86, 106))
            if pixel_hash(feet_source) != pixel_hash(feet_frame):
                raise SystemExit(f"planted foot region changed in preview frame {index}")

        strip = Image.new("RGBA", (1920, 128), (0, 0, 0, 0))
        for index, frame in enumerate(frames):
            strip.paste(frame, (index * 128, 0))
        strip.save(PROOF_DIR / "idle_preview_15f_128.png", format="PNG", optimize=False)
        neutral.save(PROOF_DIR / "neutral.png", format="PNG", optimize=False)

        # Negative source identity cases must fail before producing a blend.
        invalid_root = temp / "bad-source"
        shutil.copytree(BUNDLE, invalid_root, ignore=shutil.ignore_patterns("blender", "__pycache__"))
        bad_part = invalid_root / "extracted/parts/hood.png"
        bad_part.write_bytes(bad_part.read_bytes() + b"tamper")
        expect_builder_rejects(blender, invalid_root, temp, "altered-part", "source part hash mismatch")
        bad_rig = invalid_root / "extracted/rig.json"
        rig_data = json.loads(bad_rig.read_text())
        rig_data["direction"] = "n"
        bad_rig.write_text(json.dumps(rig_data))
        expect_builder_rejects(blender, invalid_root, temp, "wrong-direction", "expected the pinned south-facing")
        bad_rig.unlink()
        shutil.copy2(BUNDLE / "extracted/rig.json", bad_rig)
        bad_rig.unlink()
        expect_builder_rejects(blender, invalid_root, temp, "missing-rig", "No such file")
        shutil.copy2(BUNDLE / "extracted/rig.json", bad_rig)
        bad_rig.write_text("{")
        expect_builder_rejects(blender, invalid_root, temp, "malformed-rig", "JSONDecodeError")
        shutil.copy2(BUNDLE / "extracted/rig.json", bad_rig)
        (invalid_root / "extracted/parts/hood.png").unlink()
        expect_builder_rejects(blender, invalid_root, temp, "missing-part", "invalid or missing source part")

        # Mutated camera and output dimensions must be refused on readback.
        mutator = temp / "mutate.py"
        mutator.write_text(
            "import bpy,sys\n"
            "mode=sys.argv[sys.argv.index('--')+1]\n"
            "s=bpy.context.scene\n"
            "if mode=='camera': s.camera.data.ortho_scale=127\n"
            "elif mode=='displace':\n"
            " a=next(o for o in s.objects if o.type=='ARMATURE')\n"
            " s.frame_set(1)\n"
            " a.pose.bones['arm_upper_screen_left'].location.x += 1.0\n"
            "else: s.render.resolution_x=127\n"
            "bpy.ops.wm.save_as_mainfile(filepath=sys.argv[sys.argv.index('--')+2])\n"
        )
        displaced = temp / "one-pixel-displacement.blend"
        run([blender, "--background", str(BLEND), "--python", str(mutator), "--", "displace", str(displaced)])
        displaced_frames = temp / "one-pixel-displacement"
        run(render_command(blender, displaced, displaced_frames))
        displaced_neutral = rgba(displaced_frames / "frame_000.png")
        if pixel_hash(displaced_neutral) == pixel_hash(neutral):
            raise SystemExit("a one-pixel bone displacement did not change the rendered image")
        for mode in ("camera", "dimensions"):
            corrupt = temp / f"{mode}.blend"
            run([blender, "--background", str(BLEND), "--python", str(mutator), "--", mode, str(corrupt)])
            if not corrupt.is_file():
                raise RuntimeError(f"failed to create corrupt {mode} test fixture")
            result = subprocess.run(render_command(blender, corrupt, temp / mode), cwd=ROOT, text=True, capture_output=True)
            expected_error = "camera must remain orthographic" if mode == "camera" else "dimensions must remain 128x128"
            if expected_error not in result.stdout + result.stderr:
                raise RuntimeError(f"renderer accepted invalid {mode} fixture")

    receipt = json.loads(RECEIPT.read_text())
    receipt["blender_version"] = version
    receipt["blend_sha256"] = file_sha(BLEND)
    receipt["neutral_render"] = {
        "path": ".ai/operator_motion_foundry/blender/south_idle_v1/neutral.png",
        "mismatched_pixels": 0,
        "visible_pixels": 2440,
        "rgba_pixel_sha256": pixel_hash(neutral),
        "render_bit_depth": 16,
        "normalized_review_bit_depth": 8,
    }
    receipt["preview"]["frame_pixel_sha256"] = frame_hashes
    receipt["preview"]["feet_region_static"] = True
    RECEIPT.write_text(json.dumps(receipt, indent=2) + "\n")
    proof = {
        "schema": "custodian.operator_motion_foundry.blender_proof.v1",
        "candidate_only": True,
        "blender_version": version,
        "neutral_mismatched_pixels": mismatch_count,
        "visible_pixels": 2440,
        "deterministic_render_pairs": 15,
        "idle_frame_changed": True,
        "neutral_reset": True,
        "feet_static": True,
        "negative_controls": [
            "altered_source_part", "malformed_rig", "missing_rig", "wrong_direction",
            "missing_part", "one_pixel_bone_displacement", "wrong_camera", "wrong_dimensions",
        ],
        "preview_only": True,
        "authored_fps": None,
        "runtime_or_asset_v2_modified": False,
        "frame_hashes": frame_hashes,
    }
    (PROOF_DIR / "proof.json").write_text(json.dumps(proof, indent=2) + "\n")
    print(json.dumps(proof, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
