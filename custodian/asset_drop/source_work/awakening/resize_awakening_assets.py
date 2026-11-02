#!/usr/bin/env python3
from pathlib import Path
from PIL import Image
import shutil
import sys

ROOT = Path.cwd()
BACKUP_ROOT = ROOT / "_orig_backup"


def ensure_backup(src: Path):
    backup = BACKUP_ROOT / src.relative_to(ROOT)
    backup.parent.mkdir(parents=True, exist_ok=True)
    if not backup.exists():
        shutil.copy2(src, backup)


def resize_exact(src: Path, dst: Path, size: tuple[int, int]):
    ensure_backup(src)
    img = Image.open(src).convert("RGBA")
    out = img.resize(size, Image.Resampling.LANCZOS)
    out.save(dst)


def repack_grid_to_strip(
    src: Path,
    dst: Path,
    src_cols: int,
    src_rows: int,
    frame_count: int,
    target_frame_size: tuple[int, int],
):
    ensure_backup(src)
    img = Image.open(src).convert("RGBA")
    sw, sh = img.size

    if sw % src_cols != 0 or sh % src_rows != 0:
        raise ValueError(
            f"{src} cannot be evenly divided into {src_cols}x{src_rows} grid "
            f"(source size {sw}x{sh})"
        )

    cell_w = sw // src_cols
    cell_h = sh // src_rows

    frames = []
    for row in range(src_rows):
        for col in range(src_cols):
            if len(frames) >= frame_count:
                break
            left = col * cell_w
            top = row * cell_h
            frame = img.crop((left, top, left + cell_w, top + cell_h))
            frame = frame.resize(target_frame_size, Image.Resampling.LANCZOS)
            frames.append(frame)

    if len(frames) != frame_count:
        raise ValueError(
            f"Expected {frame_count} frames, got {len(frames)} from {src_cols}x{src_rows} grid"
        )

    fw, fh = target_frame_size
    strip = Image.new("RGBA", (fw * frame_count, fh), (0, 0, 0, 0))

    for i, frame in enumerate(frames):
        strip.paste(frame, (i * fw, 0), frame)

    strip.save(dst)


def must_exist(path: Path) -> Path:
    if not path.exists():
        print(f"Missing required file: {path}", file=sys.stderr)
        sys.exit(1)
    return path


def main():
    # Resolve creche idle source:
    # Prefer existing creche_recovery_alcove/idle.png if present,
    # otherwise fall back to top-level creche_recovery_alcove.png.
    creche_dir = ROOT / "creche_recovery_alcove"
    dust_dir = ROOT / "dust_lung_lift"
    gate_dir = ROOT / "gate_of_dust"

    creche_idle_dst = creche_dir / "idle.png"
    if creche_idle_dst.exists():
        creche_idle_src = creche_idle_dst
    else:
        creche_idle_src = must_exist(ROOT / "creche_recovery_alcove.png")
        creche_dir.mkdir(parents=True, exist_ok=True)

    creche_wake = must_exist(creche_dir / "wake.png")
    dust_idle = must_exist(dust_dir / "idle.png")

    gate_body = must_exist(gate_dir / "body_idle_sealed.png")
    gate_west = must_exist(gate_dir / "west_pylon.png")
    gate_east = must_exist(gate_dir / "east_pylon.png")
    gate_aperture = must_exist(gate_dir / "sealed_aperture.png")
    gate_rest = must_exist(gate_dir / "rest_threshold.png")

    # 1) Creche idle
    resize_exact(creche_idle_src, creche_idle_dst, (192, 256))

    # 2) Creche wake
    # Current source 2172x724 strongly indicates 4x2 grid => 8 frames
    repack_grid_to_strip(
        creche_wake,
        creche_wake,
        src_cols=4,
        src_rows=2,
        frame_count=8,
        target_frame_size=(192, 256),
    )

    # 3) Dust Lung lift
    resize_exact(dust_idle, dust_idle, (192, 256))

    # 4) Gate package
    resize_exact(gate_body, gate_body, (768, 512))
    resize_exact(gate_west, gate_west, (256, 512))
    resize_exact(gate_east, gate_east, (256, 512))
    resize_exact(gate_aperture, gate_aperture, (512, 512))
    resize_exact(gate_rest, gate_rest, (128, 160))

    print("Done.")
    print(f"Backups saved under: {BACKUP_ROOT}")


if __name__ == "__main__":
    main()
