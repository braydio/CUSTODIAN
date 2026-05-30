#!/usr/bin/env python3
"""
CUSTODIAN modular upper/lower combination checker.

Expected source layout:

  source_dir/
  ├── lower/
  │   ├── operator__modular_lower_body__run_01__ne__5f__96.png
  │   ├── operator__modular_lower_body__idle_01__ne__5f__96.png
  │   └── operator__modular_lower_body__walk_01__ne__5f__96.png
  └── upper/
      ├── operator__modular_upper_body__unarmed__run_01__ne__5f__96.png
      └── operator__modular_upper_body__unarmed__fast_strike_01__ne__3f__96.png

Behavior:

  1. Upper locomotion domains pair to matching lower locomotion:
       upper run_01 NE -> lower run_01 NE

  2. Upper non-locomotion/action domains fan out across lower locomotion domains:
       upper fast_strike_01 NE -> lower idle_01 NE
                               -> lower run_01 NE
                               -> lower walk_01 NE

  3. No JSON required if filenames include:
       __5f__96

Output review workspace:

  .ai/operator_modular_combo_check/
  ├── parts/
  ├── combined/
  ├── review/
  ├── gif/
  ├── reports/manifest.json
  └── index.html
"""

from __future__ import annotations

import argparse
import html
import json
import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from PIL import Image, ImageDraw, ImageFont

HASH_SHEET_RE = re.compile(r"__[0-9a-f]{8}__sheet$", re.IGNORECASE)
SHEET_RE = re.compile(r"__sheet$", re.IGNORECASE)

MODULAR_NAME_RE = re.compile(
    r"^(?P<actor>.+?)"
    r"__modular_(?P<part>lower|upper)_body"
    r"__(?P<middle>.+)"
    r"__(?P<direction>ne|nw|se|sw|n|e|s|w)"
    r"__(?P<frames>\d+)f"
    r"__(?P<frame_w>\d+)$",
    re.IGNORECASE,
)

FRAME_META_RE = re.compile(
    r"__(?P<frames>\d+)f__(?P<frame_w>\d+)$",
    re.IGNORECASE,
)


@dataclass
class Sheet:
    source_path: Path
    workspace_path: Path
    actor: str
    part: str
    variant: Optional[str]
    anim_id: str
    direction: str
    frame_count: int
    frame_w: int
    identity: str

    @property
    def domain(self) -> str:
        return animation_domain(self.anim_id)


@dataclass
class PairJob:
    lower: Sheet
    upper: Sheet
    output_id: str
    pair_mode: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Combine modular lower/upper sprite sheets from source_dir/lower and source_dir/upper."
    )

    parser.add_argument(
        "--src",
        type=Path,
        required=True,
        help="Source directory containing lower/ and upper/ subdirectories.",
    )
    parser.add_argument(
        "--check-dir",
        type=Path,
        default=Path(".ai/operator_modular_combo_check"),
        help="Output review workspace.",
    )

    parser.add_argument(
        "--lower-domains",
        default="idle,run,walk",
        help="Comma-separated lower locomotion domains used for action fanout. Default: idle,run,walk",
    )

    parser.add_argument(
        "--output-frame-policy",
        choices=["lower", "upper", "min", "max"],
        default="lower",
        help="Frame count policy for combined preview. Default: lower.",
    )
    parser.add_argument(
        "--upper-frame-repeat",
        choices=["hold", "loop"],
        default="hold",
        help="When output has more frames than upper, hold final frame or loop. Default: hold.",
    )
    parser.add_argument(
        "--lower-frame-repeat",
        choices=["hold", "loop"],
        default="loop",
        help="When output has more frames than lower, hold final frame or loop. Default: loop.",
    )

    parser.add_argument("--scale", type=int, default=4, help="Preview scale for review images/GIFs.")
    parser.add_argument("--duration-ms", type=int, default=120, help="GIF frame duration in ms.")
    parser.add_argument("--clean", action="store_true", help="Delete existing check directory before generating.")
    parser.add_argument("--open", action="store_true", help="Open index.html after generating.")

    parser.add_argument("--upper-offset-x", type=int, default=0)
    parser.add_argument("--upper-offset-y", type=int, default=0)
    parser.add_argument("--lower-offset-x", type=int, default=0)
    parser.add_argument("--lower-offset-y", type=int, default=0)

    return parser.parse_args()


def parse_lower_domains(value: str) -> List[str]:
    return [x.strip().lower() for x in value.split(",") if x.strip()]


def ensure_dirs(check_dir: Path, clean: bool) -> Dict[str, Path]:
    if clean and check_dir.exists():
        shutil.rmtree(check_dir)

    dirs = {
        "root": check_dir,
        "parts": check_dir / "parts",
        "parts_lower": check_dir / "parts" / "lower",
        "parts_upper": check_dir / "parts" / "upper",
        "combined": check_dir / "combined",
        "review": check_dir / "review",
        "gif": check_dir / "gif",
        "reports": check_dir / "reports",
    }

    for directory in dirs.values():
        directory.mkdir(parents=True, exist_ok=True)

    return dirs


def strip_export_suffix(stem: str) -> str:
    stem = HASH_SHEET_RE.sub("", stem)
    stem = SHEET_RE.sub("", stem)
    return stem


def sanitize_id(value: str) -> str:
    """
    Normalize unsafe filename characters while preserving double-underscore
    semantic separators.
    """
    value = value.lower()
    value = value.replace("\\", "/")
    value = value.replace("/", "__")
    value = value.replace("-", "_").replace(" ", "_")
    value = re.sub(r"[^a-z0-9_.]+", "_", value)
    value = re.sub(r"_{3,}", "__", value)
    return value.strip("_")


def animation_domain(anim_id: str) -> str:
    """
    Converts:
      run_01           -> run
      idle_01          -> idle
      walk_01          -> walk
      fast_strike_01   -> fast
      aim_raise_01     -> aim
    """
    return anim_id.split("_", 1)[0].lower()


def split_middle_for_upper_variant(part: str, middle: str) -> Tuple[Optional[str], str]:
    """
    Upper body names may include a loadout/variant before the animation id.

    Examples:
      operator__modular_upper_body__unarmed__run_01__ne__5f__96
        variant = unarmed
        anim_id = run_01

      operator__modular_upper_body__unarmed__fast_strike_01__ne__3f__96
        variant = unarmed
        anim_id = fast_strike_01

      operator__modular_upper_body__run_01__ne__5f__96
        variant = None
        anim_id = run_01
    """
    chunks = middle.split("__")

    if part == "upper" and len(chunks) >= 2:
        variant = chunks[0]
        anim_id = "__".join(chunks[1:])
        return variant, anim_id

    return None, middle


def parse_modular_png_name(path: Path) -> Dict:
    clean = strip_export_suffix(path.stem)
    clean = sanitize_id(clean)

    match = MODULAR_NAME_RE.match(clean)
    if not match:
        raise ValueError(
            f"Filename does not match modular naming scheme: {path.name}. "
            f"Expected like: operator__modular_lower_body__run_01__ne__5f__96.png"
        )

    actor = match.group("actor")
    part = match.group("part").lower()
    middle = match.group("middle")
    direction = match.group("direction").lower()
    frames = int(match.group("frames"))
    frame_w = int(match.group("frame_w"))

    variant, anim_id = split_middle_for_upper_variant(part, middle)

    return {
        "identity": clean,
        "actor": actor,
        "part": part,
        "variant": variant,
        "anim_id": anim_id,
        "direction": direction,
        "frames": frames,
        "frame_w": frame_w,
    }


def raw_json_for_png(path: Path) -> Optional[Path]:
    candidate = path.with_suffix(".json")
    return candidate if candidate.exists() else None


def copy_json_if_present(raw_png: Path, dest_png: Path) -> Optional[Path]:
    raw_json = raw_json_for_png(raw_png)
    if raw_json is None:
        return None

    dest_json = dest_png.with_suffix(".json")
    shutil.copy2(raw_json, dest_json)
    return dest_json


def should_consider_png(path: Path) -> bool:
    name = path.name.lower()

    if name.endswith(".png.import"):
        return False

    if not name.endswith(".png"):
        return False

    return True


def gather_part_pngs(
    src_root: Path,
    expected_part: str,
    dest_dir: Path,
) -> Tuple[List[Sheet], List[str]]:
    part_root = src_root / expected_part
    warnings: List[str] = []
    sheets: List[Sheet] = []

    if not part_root.exists():
        warnings.append(f"Missing required directory: {part_root}")
        return sheets, warnings

    for raw_png in sorted(part_root.rglob("*.png")):
        if not should_consider_png(raw_png):
            continue

        try:
            meta = parse_modular_png_name(raw_png)
        except ValueError as exc:
            warnings.append(str(exc))
            continue

        actual_part = meta["part"]
        if actual_part != expected_part:
            warnings.append(
                f"Part mismatch: {raw_png} is inside {expected_part}/ but filename says {actual_part}_body."
            )

        if raw_png.name.lower().startswith("perator__"):
            warnings.append(f"Probable typo: {raw_png.name} starts with 'perator__', expected 'operator__'.")

        if "mocular" in raw_png.name.lower():
            warnings.append(f"Probable typo: {raw_png.name} contains 'mocular', expected 'modular'.")

        identity = meta["identity"]
        dest_png = dest_dir / f"{identity}.png"

        if dest_png.exists():
            collision_suffix = abs(hash(str(raw_png))) % 100000
            dest_png = dest_dir / f"{identity}__collision_{collision_suffix}.png"
            warnings.append(f"Name collision for {raw_png}; copied to {dest_png.name}")

        shutil.copy2(raw_png, dest_png)
        copy_json_if_present(raw_png, dest_png)

        sheets.append(
            Sheet(
                source_path=raw_png,
                workspace_path=dest_png,
                actor=meta["actor"],
                part=meta["part"],
                variant=meta["variant"],
                anim_id=meta["anim_id"],
                direction=meta["direction"],
                frame_count=meta["frames"],
                frame_w=meta["frame_w"],
                identity=identity,
            )
        )

    return sheets, warnings


def meta_from_json(path: Path) -> Optional[Tuple[int, int]]:
    json_path = path.with_suffix(".json")
    if not json_path.exists():
        return None

    try:
        data = json.loads(json_path.read_text(encoding="utf-8"))
    except Exception:
        return None

    frames = data.get("frames")
    if not frames:
        return None

    if isinstance(frames, dict):
        frame_items = list(frames.values())
    elif isinstance(frames, list):
        frame_items = frames
    else:
        return None

    if not frame_items:
        return None

    first = frame_items[0]
    frame_box = first.get("frame", {})
    frame_count = len(frame_items)

    try:
        frame_w = int(frame_box.get("w", 0))
    except Exception:
        return None

    if frame_count <= 0 or frame_w <= 0:
        return None

    return frame_count, frame_w


def sheet_meta(path: Path, img: Image.Image) -> Tuple[int, int, List[str]]:
    warnings: List[str] = []

    json_meta = meta_from_json(path)
    if json_meta is not None:
        return json_meta[0], json_meta[1], warnings

    clean = strip_export_suffix(path.stem)
    match = FRAME_META_RE.search(clean)

    if match:
        frame_count = int(match.group("frames"))
        frame_w = int(match.group("frame_w"))

        expected_width = frame_count * frame_w
        if img.width != expected_width:
            warnings.append(
                f"{path.name}: image width {img.width} != {frame_count} * {frame_w} "
                f"({expected_width}); using filename metadata anyway."
            )

        return frame_count, frame_w, warnings

    raise ValueError(
        f"Cannot infer frame metadata for {path.name}. "
        f"Need JSON or filename ending like __5f__96.png."
    )


def choose_output_frame_count(lower_count: int, upper_count: int, policy: str) -> int:
    if policy == "lower":
        return lower_count
    if policy == "upper":
        return upper_count
    if policy == "min":
        return min(lower_count, upper_count)
    if policy == "max":
        return max(lower_count, upper_count)
    raise ValueError(f"Unknown output frame policy: {policy}")


def mapped_frame_index(i: int, frame_count: int, repeat: str) -> int:
    if frame_count <= 0:
        raise ValueError("frame_count must be positive")

    if i < frame_count:
        return i

    if repeat == "loop":
        return i % frame_count

    return frame_count - 1


def make_checker(w: int, h: int, cell: int = 8) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    for y in range(0, h, cell):
        for x in range(0, w, cell):
            fill = (40, 40, 45, 255) if ((x // cell + y // cell) % 2 == 0) else (72, 72, 80, 255)
            draw.rectangle([x, y, x + cell - 1, y + cell - 1], fill=fill)

    return img


def on_checker(src: Image.Image, scale: int) -> Image.Image:
    scaled = src.resize((src.width * scale, src.height * scale), Image.Resampling.NEAREST)
    bg = make_checker(scaled.width, scaled.height, max(4, scale * 2))
    bg.alpha_composite(scaled)
    return bg


def build_output_id(job: PairJob, output_frame_count: int, frame_w: int) -> str:
    lower = job.lower
    upper = job.upper

    variant_piece = f"__{upper.variant}" if upper.variant else ""

    if job.pair_mode == "locomotion_exact":
        return (
            f"{lower.actor}__modular_combined_body"
            f"{variant_piece}"
            f"__{upper.anim_id}"
            f"__{upper.direction}"
            f"__{output_frame_count}f"
            f"__{frame_w}"
        )

    return (
        f"{lower.actor}__modular_combined_body"
        f"{variant_piece}"
        f"__{upper.anim_id}"
        f"__on_{lower.anim_id}"
        f"__{upper.direction}"
        f"__{output_frame_count}f"
        f"__{frame_w}"
    )


def find_pair_jobs(
    lower_sheets: List[Sheet],
    upper_sheets: List[Sheet],
    lower_domains: List[str],
) -> Tuple[List[PairJob], List[Dict]]:
    jobs: List[PairJob] = []
    missing: List[Dict] = []

    lower_domains_set = set(lower_domains)

    for upper in upper_sheets:
        same_direction_candidates = [
            lower for lower in lower_sheets
            if lower.actor == upper.actor
            and lower.direction == upper.direction
            and lower.frame_w == upper.frame_w
            and lower.domain in lower_domains_set
        ]

        if upper.domain in lower_domains_set:
            exact = [
                lower for lower in same_direction_candidates
                if lower.anim_id == upper.anim_id
            ]

            if exact:
                for lower in exact:
                    jobs.append(
                        PairJob(
                            lower=lower,
                            upper=upper,
                            output_id="",
                            pair_mode="locomotion_exact",
                        )
                    )
                continue

            same_domain = [
                lower for lower in same_direction_candidates
                if lower.domain == upper.domain
            ]

            if same_domain:
                for lower in same_domain:
                    jobs.append(
                        PairJob(
                            lower=lower,
                            upper=upper,
                            output_id="",
                            pair_mode="locomotion_domain",
                        )
                    )
                continue

            missing.append({
                "upper": upper.workspace_path.name,
                "reason": f"No lower locomotion match for domain '{upper.domain}' direction '{upper.direction}'.",
            })
            continue

        # Non-locomotion upper/action overlay:
        # fan out across all lower idle/run/walk sheets for same actor/direction/frame width.
        if same_direction_candidates:
            for lower in same_direction_candidates:
                jobs.append(
                    PairJob(
                        lower=lower,
                        upper=upper,
                        output_id="",
                        pair_mode="action_fanout",
                    )
                )
        else:
            missing.append({
                "upper": upper.workspace_path.name,
                "reason": (
                    f"No lower base sheets for action fanout. "
                    f"Need lower domains {lower_domains} for direction '{upper.direction}' and frame width {upper.frame_w}."
                ),
            })

    return jobs, missing


def composite_pair(
    job: PairJob,
    args: argparse.Namespace,
) -> Tuple[Image.Image, List[Image.Image], Dict]:
    lower_img = Image.open(job.lower.workspace_path).convert("RGBA")
    upper_img = Image.open(job.upper.workspace_path).convert("RGBA")

    lower_count, lower_fw, lower_warnings = sheet_meta(job.lower.workspace_path, lower_img)
    upper_count, upper_fw, upper_warnings = sheet_meta(job.upper.workspace_path, upper_img)

    warnings = lower_warnings + upper_warnings

    output_count = choose_output_frame_count(
        lower_count=lower_count,
        upper_count=upper_count,
        policy=args.output_frame_policy,
    )

    if lower_count != upper_count:
        warnings.append(
            f"Frame count mismatch: lower={lower_count}, upper={upper_count}; "
            f"output policy '{args.output_frame_policy}' -> {output_count} frames."
        )

    canvas_w = max(lower_fw, upper_fw)
    canvas_h = max(lower_img.height, upper_img.height)

    strip = Image.new("RGBA", (canvas_w * output_count, canvas_h), (0, 0, 0, 0))
    frames: List[Image.Image] = []

    for out_i in range(output_count):
        lower_i = mapped_frame_index(out_i, lower_count, args.lower_frame_repeat)
        upper_i = mapped_frame_index(out_i, upper_count, args.upper_frame_repeat)

        frame = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))

        lower_frame = lower_img.crop((lower_i * lower_fw, 0, (lower_i + 1) * lower_fw, lower_img.height))
        upper_frame = upper_img.crop((upper_i * upper_fw, 0, (upper_i + 1) * upper_fw, upper_img.height))

        lower_x = ((canvas_w - lower_fw) // 2) + args.lower_offset_x
        upper_x = ((canvas_w - upper_fw) // 2) + args.upper_offset_x

        frame.alpha_composite(lower_frame, (lower_x, args.lower_offset_y))
        frame.alpha_composite(upper_frame, (upper_x, args.upper_offset_y))

        strip.alpha_composite(frame, (out_i * canvas_w, 0))
        frames.append(frame)

    output_id = build_output_id(job, output_count, canvas_w)

    return strip, frames, {
        "id": output_id,
        "pair_mode": job.pair_mode,
        "lower": job.lower.workspace_path.name,
        "upper": job.upper.workspace_path.name,
        "lower_anim": job.lower.anim_id,
        "upper_anim": job.upper.anim_id,
        "direction": job.upper.direction,
        "lower_frame_count": lower_count,
        "upper_frame_count": upper_count,
        "frame_count": output_count,
        "frame_width": canvas_w,
        "frame_height": canvas_h,
        "warnings": warnings,
    }


def make_review_sheet(
    job: PairJob,
    frames: List[Image.Image],
    args: argparse.Namespace,
) -> Image.Image:
    lower_img = Image.open(job.lower.workspace_path).convert("RGBA")
    upper_img = Image.open(job.upper.workspace_path).convert("RGBA")

    lower_count, lower_fw, _ = sheet_meta(job.lower.workspace_path, lower_img)
    upper_count, upper_fw, _ = sheet_meta(job.upper.workspace_path, upper_img)

    output_count = len(frames)
    frame_w = frames[0].width
    frame_h = frames[0].height

    scale = args.scale
    font = ImageFont.load_default()

    label_w = 112
    pad = 8
    gap = 6
    cell_w = frame_w * scale + gap
    row_h = frame_h * scale + gap

    out = Image.new(
        "RGBA",
        (label_w + pad + output_count * cell_w + pad, pad + 3 * row_h + pad),
        (18, 18, 22, 255),
    )
    draw = ImageDraw.Draw(out)

    rows = [
        ("lower", lower_img, lower_fw, lower_count, args.lower_frame_repeat),
        ("upper", upper_img, upper_fw, upper_count, args.upper_frame_repeat),
        ("combined", None, frame_w, output_count, "hold"),
    ]

    for row_i, (label, source, fw, count, repeat) in enumerate(rows):
        y = pad + row_i * row_h
        draw.text((pad, y + 6), label, fill=(230, 230, 230, 255), font=font)

        for out_i in range(output_count):
            if label == "combined":
                frame = frames[out_i]
                source_i = out_i
            else:
                source_i = mapped_frame_index(out_i, count, repeat)
                frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
                crop = source.crop((source_i * fw, 0, (source_i + 1) * fw, source.height))
                frame.alpha_composite(crop, ((frame_w - fw) // 2, 0))

            preview = on_checker(frame, scale)
            x = label_w + pad + out_i * cell_w

            out.alpha_composite(preview, (x, y))
            draw.rectangle(
                [x, y, x + preview.width - 1, y + preview.height - 1],
                outline=(150, 150, 150, 255),
            )
            draw.text(
                (x + 3, y + 3),
                f"{out_i + 1}:{source_i + 1}",
                fill=(255, 255, 255, 255),
                font=font,
            )

    return out


def make_gif(frames: List[Image.Image], path: Path, args: argparse.Namespace) -> None:
    gif_frames = [
        on_checker(frame, args.scale).convert("P", palette=Image.Palette.ADAPTIVE)
        for frame in frames
    ]

    gif_frames[0].save(
        path,
        save_all=True,
        append_images=gif_frames[1:],
        duration=args.duration_ms,
        loop=0,
        optimize=False,
        disposal=2,
    )


def write_html(
    check_dir: Path,
    records: List[Dict],
    warnings: List[str],
    missing: List[Dict],
) -> None:
    warning_items = warnings[:]
    warning_items.extend(json.dumps(item, ensure_ascii=False) for item in missing)

    warning_html = ""
    if warning_items:
        warning_html = "<h2>Warnings / unpaired sheets</h2><ul>"
        warning_html += "".join(f"<li>{html.escape(item)}</li>" for item in warning_items)
        warning_html += "</ul>"

    cards = []

    for record in records:
        pair_warnings = ""
        if record.get("warnings"):
            pair_warnings = "<ul>"
            pair_warnings += "".join(f"<li>{html.escape(w)}</li>" for w in record["warnings"])
            pair_warnings += "</ul>"

        cards.append(f"""
<section class="card">
  <h2>{html.escape(record["id"])}</h2>
  <p><b>mode:</b> <code>{html.escape(record["pair_mode"])}</code></p>
  <p><b>lower:</b> {html.escape(record["lower"])}</p>
  <p><b>upper:</b> {html.escape(record["upper"])}</p>
  <p><b>lower anim:</b> <code>{html.escape(record["lower_anim"])}</code> |
     <b>upper anim:</b> <code>{html.escape(record["upper_anim"])}</code> |
     <b>direction:</b> <code>{html.escape(record["direction"])}</code></p>
  <p><b>frames:</b> output {record["frame_count"]} |
     lower {record["lower_frame_count"]} |
     upper {record["upper_frame_count"]} |
     <b>frame:</b> {record["frame_width"]}x{record["frame_height"]}</p>
  {pair_warnings}
  <div class="grid">
    <div>
      <h3>GIF</h3>
      <img src="{html.escape(record["gif"])}">
    </div>
    <div>
      <h3>Review Sheet</h3>
      <img src="{html.escape(record["review"])}">
    </div>
  </div>
</section>
""")

    (check_dir / "index.html").write_text(f"""<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>Operator Modular Combo Check</title>
<style>
body {{
  background:#111216;
  color:#eee;
  font-family:system-ui,sans-serif;
  margin:24px;
}}
.card {{
  background:#1a1c22;
  border:1px solid #333844;
  border-radius:12px;
  padding:16px;
  margin-bottom:24px;
}}
img {{
  image-rendering:pixelated;
  max-width:100%;
  border:1px solid #444;
}}
.grid {{
  display:grid;
  grid-template-columns:minmax(180px,320px) 1fr;
  gap:18px;
  align-items:start;
}}
li {{
  color:#ffcf78;
}}
code {{
  background:#252832;
  padding:2px 5px;
  border-radius:4px;
}}
</style>
</head>
<body>
<h1>Operator Modular Combo Check</h1>
<p>
  Source layout: <code>source_dir/lower</code> + <code>source_dir/upper</code>.
  Action uppers fan out across matching-direction lower idle/run/walk sheets.
</p>
{warning_html}
{''.join(cards)}
</body>
</html>
""", encoding="utf-8")


def main() -> int:
    args = parse_args()

    src = args.src.expanduser().resolve()
    check_dir = args.check_dir.expanduser().resolve()
    lower_domains = parse_lower_domains(args.lower_domains)

    if not src.exists():
        print(f"ERROR: source directory does not exist: {src}")
        return 2

    lower_dir = src / "lower"
    upper_dir = src / "upper"

    if not lower_dir.exists() or not upper_dir.exists():
        print("ERROR: source directory must contain lower/ and upper/ subdirectories.")
        print(f"Expected lower: {lower_dir}")
        print(f"Expected upper: {upper_dir}")
        return 2

    dirs = ensure_dirs(check_dir, args.clean)

    lower_sheets, lower_warnings = gather_part_pngs(src, "lower", dirs["parts_lower"])
    upper_sheets, upper_warnings = gather_part_pngs(src, "upper", dirs["parts_upper"])

    warnings = lower_warnings + upper_warnings

    jobs, missing = find_pair_jobs(
        lower_sheets=lower_sheets,
        upper_sheets=upper_sheets,
        lower_domains=lower_domains,
    )

    records: List[Dict] = []

    for job in jobs:
        try:
            strip, frames, meta = composite_pair(job, args)
            review = make_review_sheet(job, frames, args)
        except Exception as exc:
            missing.append({
                "lower": job.lower.workspace_path.name,
                "upper": job.upper.workspace_path.name,
                "error": str(exc),
            })
            continue

        output_id = meta["id"]

        combined_path = dirs["combined"] / f"{output_id}.png"
        review_path = dirs["review"] / f"{output_id}_review.png"
        gif_path = dirs["gif"] / f"{output_id}.gif"

        strip.save(combined_path)
        review.save(review_path)
        make_gif(frames, gif_path, args)

        record = {
            **meta,
            "combined": str(combined_path.relative_to(dirs["root"])),
            "review": str(review_path.relative_to(dirs["root"])),
            "gif": str(gif_path.relative_to(dirs["root"])),
        }
        records.append(record)

    manifest = {
        "schema": "custodian.operator_modular_combo_check.lower_upper_dirs.v4_action_fanout",
        "src": str(src),
        "lower_dir": str(lower_dir),
        "upper_dir": str(upper_dir),
        "check_dir": str(check_dir),
        "lower_domains": lower_domains,
        "output_frame_policy": args.output_frame_policy,
        "upper_frame_repeat": args.upper_frame_repeat,
        "lower_frame_repeat": args.lower_frame_repeat,
        "lower_count": len(lower_sheets),
        "upper_count": len(upper_sheets),
        "job_count": len(jobs),
        "pair_count": len(records),
        "warnings": warnings,
        "missing_or_unpaired": missing,
        "records": records,
    }

    manifest_path = dirs["reports"] / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    write_html(check_dir, records, warnings, missing)

    print(f"lower sheets: {len(lower_sheets)}")
    print(f"upper sheets: {len(upper_sheets)}")
    print(f"pair jobs:    {len(jobs)}")
    print(f"wrote reviews:{len(records)}")
    print(f"index:        {check_dir / 'index.html'}")
    print(f"manifest:     {manifest_path}")

    if missing:
        print()
        print("unpaired/problem sheets:")
        for item in missing:
            print(f"  - {item}")

    if warnings:
        print()
        print("warnings:")
        for warning in warnings:
            print(f"  - {warning}")

    if args.open:
        subprocess.run(["xdg-open", str(check_dir / "index.html")], check=False)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
