#!/usr/bin/env python3
"""
CUSTODIAN modular upper/lower combination checker.

Automatic runtime mode:

  python modular_combo_check.py idle --fit-debug --open
  python modular_combo_check.py run --fit-debug --open
  python modular_combo_check.py ne --fit-debug --open

The positional selector resolves either matching lower_body/ and upper_body/
runtime children, or every exact lower/upper runtime pair for a direction. It
stages those sheets automatically. Existing manual --src mode remains available
with this expected layout:

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

  With --fit-debug, each composite frame is also analyzed for:
    - Bounding box overlap/gap (vertical gap between upper and lower)
    - Horizontal centering delta
    - Non-transparent pixel area

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
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
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

DIRECTION_ALIASES = {
    "n": "n",
    "north": "n",
    "ne": "ne",
    "northeast": "ne",
    "north_east": "ne",
    "e": "e",
    "east": "e",
    "se": "se",
    "southeast": "se",
    "south_east": "se",
    "s": "s",
    "south": "s",
    "sw": "sw",
    "southwest": "sw",
    "south_west": "sw",
    "w": "w",
    "west": "w",
    "nw": "nw",
    "northwest": "nw",
    "north_west": "nw",
}


# ── Bounding-box / fit-debug helpers ─────────────────────────────────────────


def alpha_bbox(img: Image.Image) -> Optional[Tuple[int, int, int, int]]:
    """Return (left, top, right, bottom) bounding box of non-transparent pixels,
    or None if the image is fully transparent."""
    alpha = img.convert("RGBA").getchannel("A")
    return alpha.getbbox()


def count_nontransparent_pixels(img: Image.Image) -> int:
    alpha = img.convert("RGBA").getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return 0
    l, t, r, b = bbox
    crop = alpha.crop((l, t, r, b))
    return sum(1 for px in crop.getdata() if px > 0)


def bbox_stats(img: Image.Image) -> Dict:
    bbox = alpha_bbox(img)
    if bbox is None:
        return {
            "bbox": None,
            "nontransparent_width": 0,
            "nontransparent_height": 0,
            "nontransparent_pixels": 0,
        }
    l, t, r, b = bbox
    return {
        "bbox": [l, t, r, b],
        "nontransparent_width": r - l,
        "nontransparent_height": b - t,
        "nontransparent_pixels": sum(
            1 for px in img.convert("RGBA").getchannel("A").crop((l, t, r, b)).getdata() if px > 0
        ),
    }


def row_alpha_ranges(img: Image.Image, rows: List[int]) -> List[Dict]:
    """For each y in `rows`, report the horizontal span of non-transparent pixels."""
    rgba = img.convert("RGBA")
    out = []
    for y in rows:
        if y < 0 or y >= rgba.height:
            continue
        xs = [x for x in range(rgba.width) if rgba.getpixel((x, y))[3] > 0]
        if xs:
            out.append({"y": y, "x_min": min(xs), "x_max": max(xs), "width": max(xs) - min(xs) + 1})
        else:
            out.append({"y": y, "x_min": None, "x_max": None, "width": 0})
    return out


def edge_contact_debug(lower_frame: Image.Image, upper_frame: Image.Image) -> Dict:
    """Analyze how upper and lower frames meet — gap, overlap, horizontal offset."""
    upper_bbox = alpha_bbox(upper_frame)
    lower_bbox = alpha_bbox(lower_frame)

    upper_rows = []
    lower_rows = []
    if upper_bbox:
        _, _, _, upper_bottom = upper_bbox
        upper_rows = [upper_bottom - 3, upper_bottom - 2, upper_bottom - 1]
    if lower_bbox:
        _, lower_top, _, _ = lower_bbox
        lower_rows = [lower_top, lower_top + 1, lower_top + 2]

    vertical_gap = (lower_bbox[1] - upper_bbox[3]) if upper_bbox and lower_bbox else None
    h_delta = (
        ((upper_bbox[0] + upper_bbox[2]) / 2) - ((lower_bbox[0] + lower_bbox[2]) / 2)
        if upper_bbox and lower_bbox
        else None
    )

    return {
        "upper_bbox": bbox_stats(upper_frame),
        "lower_bbox": bbox_stats(lower_frame),
        "upper_lowest_3_rows": row_alpha_ranges(upper_frame, upper_rows),
        "lower_top_3_rows": row_alpha_ranges(lower_frame, lower_rows),
        "vertical_gap_px": vertical_gap,
        "horizontal_center_delta_px": h_delta,
    }


def print_fit_debug(record_id: str, frame_debug: List[Dict]) -> None:
    print()
    print(f"fit debug: {record_id}")
    for item in frame_debug:
        print(f"  frame {item['frame']}:")
        print(f"    upper bbox: {item['upper_bbox']}")
        print(f"    lower bbox: {item['lower_bbox']}")
        print(f"    vertical_gap_px: {item['vertical_gap_px']}")
        print(f"    horizontal_center_delta_px: {item['horizontal_center_delta_px']}")


# ── Original pairing pipeline ────────────────────────────────────────────────


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


@dataclass
class ChainJob:
    """Groups multiple upper phases sequenced on the same lower body."""
    phases: List[PairJob]  # one PairJob per phase, all sharing same lower+dir
    lower: Sheet
    direction: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Combine modular lower/upper sprite sheets. Pass a runtime domain/action "
            "such as 'idle' or 'run', or a direction such as 'ne' or 'south', to "
            "stage matching runtime assets automatically. Use --src for an existing "
            "lower/ + upper/ source workspace."
        ),
        epilog=(
            "Examples:\n"
            "  python modular_combo_check.py idle --fit-debug --open\n"
            "  python modular_combo_check.py run --fit-debug --open\n"
            "  python modular_combo_check.py ne --fit-debug --open\n"
            "  python modular_combo_check.py actions/unarmed/fast_attack/fast_strike_01 --fit-debug --open\n"
            "  python modular_combo_check.py --src .ai/custom_combo_source --lower-domains idle,run,walk"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "domain",
        nargs="?",
        help=(
            "Runtime selector to stage automatically. Direction names/abbreviations "
            "such as ne, south, and w collect every exact lower/upper runtime pair "
            "for that direction. Simple locomotion names "
            "such as idle, walk, and run resolve to locomotion/<name>_01. Relative "
            "runtime paths and uniquely named action directories are also accepted."
        ),
    )
    parser.add_argument(
        "--src",
        type=Path,
        default=None,
        help="Existing source directory containing lower/ and upper/ subdirectories.",
    )
    parser.add_argument(
        "--check-dir",
        type=Path,
        default=None,
        help=(
            "Output review workspace. Auto-domain mode defaults to "
            ".ai/operator_modular_combo_check/<domain>."
        ),
    )
    parser.add_argument(
        "--runtime-root",
        type=Path,
        default=None,
        help=(
            "Runtime module root containing lower_body/ and upper_body/. Default: "
            "<repo>/custodian/content/sprites/operator/runtime/modules/new_operator"
        ),
    )

    parser.add_argument(
        "--lower-domains",
        default=None,
        help=(
            "Comma-separated lower domains used for pairing. In auto-domain mode this "
            "is inferred from the staged lower-body filenames. Existing --src mode "
            "defaults to idle,run,walk."
        ),
    )

    parser.add_argument(
        "--output-frame-policy",
        choices=["lower", "upper", "min", "max"],
        default="min",
        help="Frame count policy for combined preview. Default: min (shorter of the two).",
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

    # ── Fit-debug flags ──────────────────────────────────────────────────
    parser.add_argument(
        "--fit-debug",
        action="store_true",
        help="Run alpha-bbox edge-contact analysis on every composite frame.",
    )
    parser.add_argument(
        "--fit-verbose",
        action="store_true",
        help="Print fit-debug details to stdout for every pairing.",
    )
    parser.add_argument(
        "--fit-gap-threshold",
        type=int,
        default=3,
        help="Flag pairings with vertical gap >= this many pixels (default: 3).",
    )
    parser.add_argument(
        "--fit-report-only",
        action="store_true",
        help="Only run fit-debug on existing pairings in check-dir (no regeneration).",
    )
    parser.add_argument(
        "--fit-center-threshold",
        type=int,
        default=5,
        help="Flag horizontal center deltas at or above this magnitude (default: 5).",
    )

    # ── Prioritized next-actions report ────────────────────────────────
    parser.add_argument(
        "--next-actions",
        action="store_true",
        help="Generate prioritized animation implementation recommendations.",
    )
    parser.add_argument(
        "--next-actions-max",
        type=int,
        default=20,
        help="Maximum number of ranked recommendations.",
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[3],
        help="CUSTODIAN repository root used for runtime discovery, outputs, and contract tooling.",
    )

    # ── Chain flags ──────────────────────────────────────────────────────
    parser.add_argument(
        "--chain",
        type=str,
        default=None,
        help="Comma-separated animation phase names to chain into one motion. "
             "E.g. --chain fast_windup_01,fast_strike_01,fast_recovery_01. "
             "Matches upper anim_id against each phase name.",
    )

    return parser.parse_args()


def parse_lower_domains(value: str) -> List[str]:
    return [x.strip().lower() for x in value.split(",") if x.strip()]


def domain_slug(value: str) -> str:
    slug = sanitize_id(value.strip().lower())
    return slug or "runtime_domain"


def runtime_direction(value: str) -> Optional[str]:
    normalized = value.strip().lower().replace("-", "_").replace(" ", "_")
    return DIRECTION_ALIASES.get(normalized)


def runtime_directory_candidates(layer_root: Path, requested: str) -> List[Path]:
    """Return matching runtime child directories for one body layer.

    Resolution order:
      1. Exact relative path below the layer root.
      2. Locomotion shorthand: idle -> locomotion/idle_01.
      3. Recursive directory-name match, allowing action names such as
         fast_strike_01 or parent groups such as fast_attack.
    """
    raw = requested.strip().strip("/")
    if not raw:
        return []

    exact = layer_root / raw
    if exact.is_dir():
        return [exact.resolve()]

    simple = raw.lower()
    locomotion_name = simple if simple.endswith("_01") else f"{simple}_01"
    locomotion = layer_root / "locomotion" / locomotion_name
    if locomotion.is_dir():
        return [locomotion.resolve()]

    names = {Path(raw).name.lower()}
    if not Path(raw).name.lower().endswith("_01"):
        names.add(f"{Path(raw).name.lower()}_01")

    matches = [
        path.resolve()
        for path in layer_root.rglob("*")
        if path.is_dir() and path.name.lower() in names
    ]
    return sorted(set(matches))


def resolve_runtime_directory(layer_root: Path, requested: str, layer_label: str) -> Path:
    candidates = runtime_directory_candidates(layer_root, requested)
    if not candidates:
        raise RuntimeError(
            f"No {layer_label} runtime directory matched '{requested}' below {layer_root}."
        )
    if len(candidates) > 1:
        choices = "\n".join(f"  - {path}" for path in candidates)
        raise RuntimeError(
            f"Runtime domain '{requested}' is ambiguous for {layer_label}:\n{choices}\n"
            "Pass a relative path such as actions/ranged_2h/aim_01."
        )
    return candidates[0]


def copy_runtime_domain(source: Path, destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    shutil.copytree(
        source,
        destination,
        dirs_exist_ok=True,
        ignore=shutil.ignore_patterns("*.import"),
    )


def copy_runtime_direction(source: Path, destination: Path, direction: str) -> int:
    """Copy canonical PNG/JSON pairs for one direction, preserving runtime paths."""
    copied = 0
    for source_png in sorted(source.rglob("*.png")):
        try:
            meta = parse_modular_png_name(source_png)
        except ValueError:
            continue
        if meta["direction"] != direction:
            continue

        destination_png = destination / source_png.relative_to(source)
        destination_png.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_png, destination_png)
        source_json = raw_json_for_png(source_png)
        if source_json is not None:
            shutil.copy2(source_json, destination_png.with_suffix(".json"))
        copied += 1
    return copied


def inferred_domains_from_pngs(root: Path) -> List[str]:
    domains = set()
    failures = []
    for path in sorted(root.rglob("*.png")):
        try:
            meta = parse_modular_png_name(path)
        except ValueError as exc:
            failures.append(str(exc))
            continue
        domains.add(animation_domain(str(meta["anim_id"])))

    if not domains:
        detail = "" if not failures else "\n" + "\n".join(failures[:8])
        raise RuntimeError(
            f"Could not infer any animation domains from staged lower-body PNGs in {root}.{detail}"
        )
    return sorted(domains)


def stage_runtime_domain(args: argparse.Namespace) -> Tuple[Path, List[str]]:
    repo_root = args.repo_root.expanduser().resolve()
    runtime_root = (
        args.runtime_root.expanduser().resolve()
        if args.runtime_root is not None
        else repo_root
        / "custodian/content/sprites/operator/runtime/modules/new_operator"
    )

    lower_root = runtime_root / "lower_body"
    upper_root = runtime_root / "upper_body"
    if not lower_root.is_dir() or not upper_root.is_dir():
        raise RuntimeError(
            "Runtime module root must contain lower_body/ and upper_body/: "
            f"{runtime_root}"
        )

    lower_source = resolve_runtime_directory(lower_root, args.domain, "lower-body")
    upper_source = resolve_runtime_directory(upper_root, args.domain, "upper-body")

    slug = domain_slug(args.domain)
    stage_root = repo_root / ".ai/operator_modular_combo_sources" / slug
    if stage_root.exists():
        shutil.rmtree(stage_root)

    copy_runtime_domain(lower_source, stage_root / "lower")
    copy_runtime_domain(upper_source, stage_root / "upper")
    inferred = inferred_domains_from_pngs(stage_root / "lower")

    print(f"runtime domain: {args.domain}")
    print(f"lower source:  {lower_source}")
    print(f"upper source:  {upper_source}")
    print(f"staged source: {stage_root}")
    print(f"lower domains: {','.join(inferred)}")

    return stage_root, inferred


def stage_runtime_direction(
    args: argparse.Namespace,
    direction: str,
) -> Tuple[Path, List[str]]:
    repo_root = args.repo_root.expanduser().resolve()
    runtime_root = (
        args.runtime_root.expanduser().resolve()
        if args.runtime_root is not None
        else repo_root
        / "custodian/content/sprites/operator/runtime/modules/new_operator"
    )

    lower_root = runtime_root / "lower_body"
    upper_root = runtime_root / "upper_body"
    if not lower_root.is_dir() or not upper_root.is_dir():
        raise RuntimeError(
            "Runtime module root must contain lower_body/ and upper_body/: "
            f"{runtime_root}"
        )

    stage_root = repo_root / ".ai/operator_modular_combo_sources" / direction
    if stage_root.exists():
        shutil.rmtree(stage_root)

    lower_count = copy_runtime_direction(lower_root, stage_root / "lower", direction)
    upper_count = copy_runtime_direction(upper_root, stage_root / "upper", direction)
    if lower_count == 0 or upper_count == 0:
        raise RuntimeError(
            f"Direction '{direction}' needs runtime PNGs in both body layers; "
            f"found lower={lower_count}, upper={upper_count} below {runtime_root}."
        )

    inferred = inferred_domains_from_pngs(stage_root / "lower")
    print(f"runtime direction: {direction}")
    print(f"lower source:      {lower_root} ({lower_count} sheets)")
    print(f"upper source:      {upper_root} ({upper_count} sheets)")
    print(f"staged source:     {stage_root}")

    return stage_root, inferred


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


def _git_commit(repo_root: Path) -> str:
    completed = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=repo_root,
        check=False,
        capture_output=True,
        text=True,
    )
    return completed.stdout.strip() if completed.returncode == 0 else "unknown"


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
    Modular lower and upper body names may include a loadout/variant before the animation id.

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

    if part in {"lower", "upper"} and len(chunks) >= 2:
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

    if job.pair_mode in {"locomotion_exact", "runtime_direction_exact"}:
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


def find_direction_pair_jobs(
    lower_sheets: List[Sheet],
    upper_sheets: List[Sheet],
) -> Tuple[List[PairJob], List[Dict]]:
    """Pair all runtime sheets for one direction without action fan-out."""
    jobs: List[PairJob] = []
    missing: List[Dict] = []
    matched_lower_ids = set()

    for upper in upper_sheets:
        exact = [
            lower for lower in lower_sheets
            if lower.actor == upper.actor
            and lower.variant == upper.variant
            and lower.anim_id == upper.anim_id
            and lower.direction == upper.direction
            and lower.frame_w == upper.frame_w
        ]
        if not exact:
            missing.append({
                "upper": upper.workspace_path.name,
                "reason": "No exact lower-body runtime counterpart for direction review.",
            })
            continue
        for lower in exact:
            matched_lower_ids.add(id(lower))
            jobs.append(
                PairJob(
                    lower=lower,
                    upper=upper,
                    output_id="",
                    pair_mode="runtime_direction_exact",
                )
            )

    for lower in lower_sheets:
        if id(lower) not in matched_lower_ids:
            missing.append({
                "lower": lower.workspace_path.name,
                "reason": "No exact upper-body runtime counterpart for direction review.",
            })

    return jobs, missing


def find_chain_groups(
    jobs: List[PairJob],
    chain_phases: List[str],
) -> Tuple[List[ChainJob], List[PairJob]]:
    """Group action_fanout jobs into chain sequences where multiple upper
    animation phases share the same lower sheet + direction.

    Returns (chain_groups, remaining_jobs) where remaining_jobs excludes
    the jobs that were absorbed into chains.
    """
    # Build lookup: (lower_identity, direction) -> {phase_index -> PairJob}
    phase_set = {p.lower() for p in chain_phases}
    by_lower_dir: Dict[Tuple[str, str], Dict[int, PairJob]] = {}

    for job in jobs:
        if job.pair_mode != "action_fanout":
            continue
        # Check if this upper anim_id matches a chain phase
        upper_anim = job.upper.anim_id.lower()
        matched_phase = None
        for i, phase in enumerate(chain_phases):
            if phase.lower() in upper_anim or upper_anim == phase.lower():
                matched_phase = i
                break
        if matched_phase is None:
            continue

        key = (job.lower.identity, job.upper.direction)
        if key not in by_lower_dir:
            by_lower_dir[key] = {}
        by_lower_dir[key][matched_phase] = job

    chain_groups: List[ChainJob] = []
    consumed: set = set()

    for (lower_id, direction), phases_dict in by_lower_dir.items():
        # Only chain if we have at least 2 phases
        if len(phases_dict) < 2:
            continue
        sorted_phases = [phases_dict[i] for i in sorted(phases_dict)]
        chain_groups.append(ChainJob(
            phases=sorted_phases,
            lower=sorted_phases[0].lower,
            direction=direction,
        ))
        for job in sorted_phases:
            consumed.add(id(job))

    remaining = [j for j in jobs if id(j) not in consumed]
    return chain_groups, remaining


def composite_chain(
    chain: ChainJob,
    args: argparse.Namespace,
) -> Tuple[Image.Image, List[Image.Image], Dict, Optional[List[Dict]]]:
    """Composite multiple upper phases in sequence on a single lower body."""
    lower_img = Image.open(chain.lower.workspace_path).convert("RGBA")
    lower_count, lower_fw, lower_warnings = sheet_meta(chain.lower.workspace_path, lower_img)

    phase_labels: List[str] = []
    all_frames: List[Image.Image] = []
    all_fit_debug: List[Dict] = []
    all_warnings: List[str] = list(lower_warnings)
    total_frames = 0
    max_canvas_w = 0
    max_canvas_h = 0

    # First pass: composite each phase, collect frame dimensions
    phase_data = []  # list of (frames, fit_debug, meta_for_phase)
    for job in chain.phases:
        strip, frames, meta, fit_debug = composite_pair(job, args)
        phase_data.append((frames, fit_debug, meta))
        total_frames += len(frames)
        max_canvas_w = max(max_canvas_w, meta["frame_width"])
        max_canvas_h = max(max_canvas_h, meta["frame_height"])
        phase_labels.append(job.upper.anim_id)
        all_warnings.extend(meta.get("warnings", []))

    # Second pass: build concatenated strip
    canvas_w = max_canvas_w
    canvas_h = max_canvas_h
    strip = Image.new("RGBA", (canvas_w * total_frames, canvas_h), (0, 0, 0, 0))
    offset = 0

    for phase_idx, (frames, fit_debug, meta) in enumerate(phase_data):
        for frame_i, frame in enumerate(frames):
            # Center if this phase's frame is narrower
            if meta["frame_width"] < canvas_w:
                centered = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
                cx = (canvas_w - meta["frame_width"]) // 2
                cy = (canvas_h - meta["frame_height"]) // 2
                centered.alpha_composite(frame, (cx, cy))
                strip.alpha_composite(centered, (offset * canvas_w, 0))
            else:
                strip.alpha_composite(frame, (offset * canvas_w, 0))
            all_frames.append(frame)

            if fit_debug is not None and frame_i < len(fit_debug):
                fd = dict(fit_debug[frame_i])
                fd["phase"] = phase_idx
                fd["phase_label"] = phase_labels[phase_idx]
                all_fit_debug.append(fd)

            offset += 1

    phase_note = " → ".join(phase_labels)
    chain_id = (
        f"{chain.lower.actor}__modular_combined_body"
        f"__chain_{phase_note}"
        f"__{chain.direction}"
        f"__{total_frames}f"
        f"__{canvas_w}"
    )

    # Build phase upper path dict for review sheet
    phase_upper_paths = {}
    for i, job in enumerate(chain.phases):
        phase_upper_paths[f"_upper_path_{i}"] = str(job.upper.workspace_path)

    return strip, all_frames, {
        "id": chain_id,
        "pair_mode": "chain",
        "lower": chain.lower.workspace_path.name,
        "upper": " + ".join(j.upper.workspace_path.name for j in chain.phases),
        "lower_source_path": str(chain.lower.source_path.resolve()),
        "upper_source_paths": [str(job.upper.source_path.resolve()) for job in chain.phases],
        "lower_anim": chain.lower.anim_id,
        "upper_anim": " → ".join(phase_labels),
        "direction": chain.direction,
        "lower_frame_count": lower_count,
        "upper_frame_count": total_frames,
        "frame_count": total_frames,
        "frame_width": canvas_w,
        "frame_height": canvas_h,
        "chain_phases": phase_labels,
        "chain_phase_frame_counts": [len(f[0]) for f in phase_data],
        "warnings": all_warnings,
        "_lower_path": str(chain.lower.workspace_path),
        **phase_upper_paths,
    }, (all_fit_debug if args.fit_debug else None)


def composite_pair(
    job: PairJob,
    args: argparse.Namespace,
) -> Tuple[Image.Image, List[Image.Image], Dict, Optional[List[Dict]]]:
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
    fit_debug_frames: Optional[List[Dict]] = [] if args.fit_debug else None

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

        if fit_debug_frames is not None:
            fit_debug_frames.append({
                "frame": out_i,
                **edge_contact_debug(lower_frame, upper_frame),
            })

    output_id = build_output_id(job, output_count, canvas_w)

    return strip, frames, {
        "id": output_id,
        "pair_mode": job.pair_mode,
        "lower": job.lower.workspace_path.name,
        "upper": job.upper.workspace_path.name,
        "lower_source_path": str(job.lower.source_path.resolve()),
        "upper_source_path": str(job.upper.source_path.resolve()),
        "lower_anim": job.lower.anim_id,
        "upper_anim": job.upper.anim_id,
        "direction": job.upper.direction,
        "lower_frame_count": lower_count,
        "upper_frame_count": upper_count,
        "frame_count": output_count,
        "frame_width": canvas_w,
        "frame_height": canvas_h,
        "warnings": warnings,
    }, fit_debug_frames


def make_review_sheet(
    job: Optional[PairJob],
    frames: List[Image.Image],
    args: argparse.Namespace,
    chain_meta: Optional[Dict] = None,
) -> Image.Image:
    scale = args.scale
    font = ImageFont.load_default()
    output_count = len(frames)
    frame_w = frames[0].width
    frame_h = frames[0].height

    label_w = 112
    pad = 8
    gap = 6
    cell_w = frame_w * scale + gap
    row_h = frame_h * scale + gap

    if chain_meta:
        # ── Chain mode: show phase labels instead of single upper ──
        phase_labels = chain_meta.get("chain_phases", [])
        phase_counts = chain_meta.get("chain_phase_frame_counts", [])
        # Build phase boundaries for annotation
        phase_boundaries = []
        acc = 0
        for i, cnt in enumerate(phase_counts):
            phase_boundaries.append((acc, acc + cnt, phase_labels[i] if i < len(phase_labels) else f"phase_{i}"))
            acc += cnt

        n_rows = 2 + len(phase_labels)  # lower + combined + one row per phase
        out = Image.new(
            "RGBA",
            (label_w + pad + output_count * cell_w + pad, pad + n_rows * row_h + pad),
            (18, 18, 22, 255),
        )
        draw = ImageDraw.Draw(out)

        # Lower row
        lower_path = chain_meta.get("_lower_path")
        lower_img = None
        lower_count = 0
        lower_fw = 0
        if lower_path:
            lower_img = Image.open(lower_path).convert("RGBA")
            lower_count, lower_fw, _ = sheet_meta(Path(lower_path), lower_img)
        elif job is not None:
            lower_img = Image.open(job.lower.workspace_path).convert("RGBA")
            lower_count, lower_fw, _ = sheet_meta(job.lower.workspace_path, lower_img)
        if lower_img:

            y = pad
            draw.text((pad, y + 6), "lower", fill=(230, 230, 230, 255), font=font)
            for out_i in range(output_count):
                source_i = mapped_frame_index(out_i, lower_count, args.lower_frame_repeat) if lower_count > 0 else 0
                frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
                if lower_fw > 0:
                    crop = lower_img.crop((source_i * lower_fw, 0, (source_i + 1) * lower_fw, lower_img.height))
                    frame.alpha_composite(crop, ((frame_w - lower_fw) // 2, 0))
                preview = on_checker(frame, scale)
                x = label_w + pad + out_i * cell_w
                out.alpha_composite(preview, (x, y))
                draw.rectangle([x, y, x + preview.width - 1, y + preview.height - 1], outline=(150, 150, 150, 255))
                draw.text((x + 3, y + 3), f"{out_i + 1}", fill=(255, 255, 255, 255), font=font)

        # Phase rows
        for phase_idx, (label, cnt) in enumerate(zip(phase_labels, phase_counts)):
            y = pad + (phase_idx + 1) * row_h
            draw.text((pad, y + 6), f"phase {phase_idx + 1}: {label}", fill=(180, 220, 255, 255), font=font)
            # Find the upper sheet for this phase from the chain_meta
            upper_path = chain_meta.get(f"_upper_path_{phase_idx}")
            if upper_path:
                upper_img = Image.open(upper_path).convert("RGBA")
                _, upper_fw, _ = sheet_meta(Path(upper_path), upper_img)
                for out_i in range(output_count):
                    source_i = mapped_frame_index(out_i, cnt, "hold") if cnt > 0 else 0
                    frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
                    if upper_fw > 0 and source_i < cnt and (source_i * upper_fw) < upper_img.width:
                        crop = upper_img.crop((source_i * upper_fw, 0, (source_i + 1) * upper_fw, upper_img.height))
                        frame.alpha_composite(crop, ((frame_w - upper_fw) // 2, 0))
                    preview = on_checker(frame, scale)
                    x = label_w + pad + out_i * cell_w
                    out.alpha_composite(preview, (x, y))
                    draw.rectangle([x, y, x + preview.width - 1, y + preview.height - 1], outline=(100, 140, 180, 255))
                    draw.text((x + 3, y + 3), f"{out_i + 1}:{source_i + 1}", fill=(180, 220, 255, 255), font=font)

        # Combined row (last row)
        y = pad + (len(phase_labels) + 1) * row_h
        draw.text((pad, y + 6), "combined", fill=(255, 230, 180, 255), font=font)
        for out_i in range(output_count):
            frame = frames[out_i]
            preview = on_checker(frame, scale)
            x = label_w + pad + out_i * cell_w
            out.alpha_composite(preview, (x, y))
            draw.rectangle([x, y, x + preview.width - 1, y + preview.height - 1], outline=(200, 180, 140, 255))
            # Show phase boundary labels
            phase_label = ""
            for start, end, plabel in phase_boundaries:
                if start <= out_i < end:
                    phase_label = plabel
                    break
            draw.text((x + 3, y + 3), f"{out_i + 1} [{phase_label}]", fill=(255, 230, 180, 255), font=font)

        return out

    # ── Original single-pair review sheet ──
    if job is None:
        raise ValueError("Need either a PairJob or chain_meta")
    lower_img = Image.open(job.lower.workspace_path).convert("RGBA")
    upper_img = Image.open(job.upper.workspace_path).convert("RGBA")

    lower_count, lower_fw, _ = sheet_meta(job.lower.workspace_path, lower_img)
    upper_count, upper_fw, _ = sheet_meta(job.upper.workspace_path, upper_img)

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


def run_next_actions_report(args: argparse.Namespace, manifest_path: Path) -> None:
    if not args.next_actions:
        return
    helper = (
        args.repo_root.expanduser().resolve()
        / "custodian/tools/operator/operator_next_actions_report.py"
    )
    if not helper.exists():
        raise RuntimeError(f"Next-actions helper is missing: {helper}")
    command = [
        sys.executable,
        str(helper),
        "--combo-manifest",
        str(manifest_path),
        "--repo-root",
        str(args.repo_root.expanduser().resolve()),
        "--fit-gap-threshold",
        str(args.fit_gap_threshold),
        "--fit-center-threshold",
        str(args.fit_center_threshold),
        "--max-actions",
        str(args.next_actions_max),
    ]
    completed = subprocess.run(command, check=False)
    if completed.returncode != 0:
        raise RuntimeError(f"Next-actions report failed with status {completed.returncode}")


def next_actions_html(check_dir: Path) -> str:
    path = check_dir / "reports" / "next_actions.json"
    if not path.exists():
        return ""
    report = json.loads(path.read_text(encoding="utf-8"))
    actions = report.get("actions", [])
    if not actions:
        return """
<section class="card next-actions">
  <h2>Recommended Next Actions</h2>
  <p>No recommendations generated.</p>
</section>
"""
    rows = []
    for action in actions[:12]:
        sources = action.get("source_files", [])
        source_path = sources[0].get("repo_path", "") if sources else ""
        rows.append(
            "<li>"
            f"<b>{html.escape(str(action.get('priority', 'P3')))}</b> "
            f"{html.escape(str(action.get('title', 'Untitled recommendation')))}"
            f"<br><code>{html.escape(source_path)}</code>"
            "</li>"
        )
    return f"""
<section class="card next-actions">
  <h2>Recommended Next Actions</h2>
  <p>
    <a href="reports/NEXT_ACTIONS.md">Full implementation report</a>
    |
    <a href="reports/next_actions.json">JSON</a>
  </p>
  <ol>{''.join(rows)}</ol>
</section>
"""


def canonical_part_path(
    candidates: List[Path],
    workspace_candidate: Path,
    workspace_name: str,
    part: str,
    anim_id: str,
    direction: str,
) -> Optional[Path]:
    if workspace_candidate.exists():
        return workspace_candidate.resolve()
    exact = [path for path in candidates if path.name == workspace_name]
    if exact:
        return exact[0].resolve()
    part_token = "lower_body" if part == "lower" else "upper_body"
    semantic = [
        path for path in candidates
        if part_token in path.name
        and f"__{anim_id}__" in path.name
        and f"__{direction}__" in path.name
    ]
    return semantic[0].resolve() if semantic else None


def write_html(
    check_dir: Path,
    records: List[Dict],
    warnings: List[str],
    missing: List[Dict],
    args: argparse.Namespace,
) -> None:
    recommendations_html = next_actions_html(check_dir)
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

        # Fit-debug annotation
        fit_html = ""
        if record.get("fit_debug"):
            gap_threshold = args.fit_gap_threshold
            center_threshold = args.fit_center_threshold
            flagged = [
                d for d in record["fit_debug"]
                if (d.get("vertical_gap_px") is not None and abs(d["vertical_gap_px"]) >= gap_threshold)
                or (d.get("horizontal_center_delta_px") is not None and abs(d["horizontal_center_delta_px"]) >= center_threshold)
            ]
            fit_summary_lines = []
            for d in record["fit_debug"]:
                gap = d.get("vertical_gap_px")
                hdelta = d.get("horizontal_center_delta_px")
                flag = "⚠️" if (
                    (gap is not None and abs(gap) >= gap_threshold)
                    or (hdelta is not None and abs(hdelta) >= center_threshold)
                ) else ""
                hdelta_text = "n/a" if hdelta is None else f"{hdelta:+.0f}"
                fit_summary_lines.append(
                    f"frame {d['frame']}: gap={gap}px h-center={hdelta_text}px "
                    f"upper={d['upper_bbox']['nontransparent_height']}px×{d['upper_bbox']['nontransparent_width']}px "
                    f"lower={d['lower_bbox']['nontransparent_height']}px×{d['lower_bbox']['nontransparent_width']}px {flag}"
                )
            fit_html = '<div class="fit-debug"><h4>Fit Analysis</h4>'
            if flagged:
                fit_html += f'<p style="color:#ff6b6b">{len(flagged)}/{len(record["fit_debug"])} frames exceed gap/center thresholds (±{gap_threshold}px / ±{center_threshold}px)</p>'
            fit_html += "<pre>" + "\n".join(html.escape(l) for l in fit_summary_lines) + "</pre></div>"

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
  {fit_html}
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
.fit-debug {{
  background:#0d1117;
  border:1px solid #30363d;
  border-radius:8px;
  padding:8px 12px;
  margin:8px 0;
}}
.fit-debug pre {{
  font-size:11px;
  line-height:1.5;
  margin:4px 0;
  color:#8b949e;
}}
</style>
</head>
<body>
<h1>Operator Modular Combo Check</h1>
<p>
  Source layout: <code>source_dir/lower</code> + <code>source_dir/upper</code>.
  Action uppers fan out across matching-direction lower idle/run/walk sheets.
</p>
{recommendations_html}
{warning_html}
{''.join(cards)}
</body>
</html>
""", encoding="utf-8")


def run_fit_debug_on_existing(args: argparse.Namespace) -> int:
    """Re-run fit analysis on already-generated combined sheets without regenerating."""
    check_dir = args.check_dir.expanduser().resolve()
    manifest_path = check_dir / "reports" / "manifest.json"
    if not manifest_path.exists():
        print(f"ERROR: no manifest found at {manifest_path}")
        return 2

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    updated = []
    repo_root = args.repo_root.expanduser().resolve()
    operator_roots = [
        repo_root / "custodian/content/sprites/operator/new_operator/modular",
        repo_root / "custodian/content/sprites/operator/runtime/modules/new_operator",
    ]
    canonical_candidates = [
        path
        for root in operator_roots
        if root.exists()
        for path in root.rglob("*.png")
    ]

    for record in manifest.get("records", []):
        combined_rel = record.get("combined")
        if not combined_rel:
            continue
        combined_path = check_dir / combined_rel
        if not combined_path.exists():
            continue

        # Find the lower/upper source sheets in parts
        lower_name = record.get("lower")
        upper_name = record.get("upper")
        lower_path = check_dir / "parts" / "lower" / lower_name if lower_name else None
        upper_path = check_dir / "parts" / "upper" / upper_name if upper_name else None

        if not lower_path or not lower_path.exists() or not upper_path or not upper_path.exists():
            print(f"  Skipping {record['id']}: source parts not found")
            continue

        lower_img = Image.open(lower_path).convert("RGBA")
        upper_img = Image.open(upper_path).convert("RGBA")

        lower_count, lower_fw, _ = sheet_meta(lower_path, lower_img)
        upper_count, upper_fw, _ = sheet_meta(upper_path, upper_img)

        output_count = choose_output_frame_count(lower_count, upper_count, args.output_frame_policy)

        fit_debug_frames = []
        for out_i in range(output_count):
            lower_i = mapped_frame_index(out_i, lower_count, args.lower_frame_repeat)
            upper_i = mapped_frame_index(out_i, upper_count, args.upper_frame_repeat)

            lf = lower_img.crop((lower_i * lower_fw, 0, (lower_i + 1) * lower_fw, lower_img.height))
            uf = upper_img.crop((upper_i * upper_fw, 0, (upper_i + 1) * upper_fw, upper_img.height))

            fit_debug_frames.append({
                "frame": out_i,
                **edge_contact_debug(lf, uf),
            })

        record["fit_debug"] = fit_debug_frames
        source_lower = canonical_part_path(
            canonical_candidates,
            args.src.expanduser().resolve() / "lower" / lower_name,
            lower_name,
            "lower",
            str(record.get("lower_anim", "")),
            str(record.get("direction", "")),
        )
        source_upper = canonical_part_path(
            canonical_candidates,
            args.src.expanduser().resolve() / "upper" / upper_name,
            upper_name,
            "upper",
            str(record.get("upper_anim", "")),
            str(record.get("direction", "")),
        )
        if source_lower is not None:
            record["lower_source_path"] = str(source_lower)
        if source_upper is not None:
            record["upper_source_path"] = str(source_upper)
        updated.append(record)

        if args.fit_verbose:
            print_fit_debug(record["id"], fit_debug_frames)

    manifest["records"] = updated
    manifest["fit_gap_threshold"] = args.fit_gap_threshold
    manifest["fit_center_threshold"] = args.fit_center_threshold
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    run_next_actions_report(args, manifest_path)
    # Re-generate HTML with fit data and recommendations.
    write_html(check_dir, updated, manifest.get("warnings", []), manifest.get("missing_or_unpaired", []), args)

    # Summary
    threshold = args.fit_gap_threshold
    center_threshold = args.fit_center_threshold
    bad_pairs = []
    for r in updated:
        fd = r.get("fit_debug", [])
        flagged = [
            d for d in fd
            if (d.get("vertical_gap_px") is not None and abs(d["vertical_gap_px"]) >= threshold)
            or (d.get("horizontal_center_delta_px") is not None and abs(d["horizontal_center_delta_px"]) >= center_threshold)
        ]
        if flagged:
            bad_pairs.append((r["id"], len(flagged), len(fd), flagged))

    print(f"\nFit-debug complete: {len(updated)} pairings analyzed")
    if bad_pairs:
        print(f"\n⚠️  {len(bad_pairs)} pairings exceed gap/center thresholds (±{threshold}px / ±{center_threshold}px):")
        for pid, n_flagged, n_total, frames in sorted(bad_pairs):
            gaps = ", ".join(f"f{d['frame']}={d['vertical_gap_px']}px" for d in frames)
            print(f"  {pid}")
            print(f"    {n_flagged}/{n_total} frames flagged: {gaps}")
    else:
        print(f"✅ All pairings within gap/center thresholds (±{threshold}px / ±{center_threshold}px)")

    return 0


def main() -> int:
    args = parse_args()
    repo_root = args.repo_root.expanduser().resolve()
    selected_direction = runtime_direction(args.domain) if args.domain else None

    if args.domain and args.src is not None:
        print("ERROR: pass either a runtime domain argument or --src, not both.")
        return 2

    slug = domain_slug(selected_direction or args.domain) if args.domain else None
    if args.check_dir is None:
        check_dir = repo_root / ".ai/operator_modular_combo_check"
        if slug:
            check_dir = check_dir / slug
    else:
        check_dir = args.check_dir.expanduser().resolve()
    args.check_dir = check_dir

    # Fit-report-only mode: don't regenerate, just analyze existing. The generated
    # parts workspace is sufficient when no explicit source directory is supplied.
    if args.fit_report_only:
        if args.src is None:
            args.src = check_dir / "parts"
        return run_fit_debug_on_existing(args)

    try:
        if args.domain:
            if selected_direction:
                src, inferred_domains = stage_runtime_direction(args, selected_direction)
            else:
                src, inferred_domains = stage_runtime_domain(args)
            lower_domains = (
                parse_lower_domains(args.lower_domains)
                if args.lower_domains
                else inferred_domains
            )
            # Auto-domain mode is intended to be one-command/reproducible; stale
            # parts and collision copies would invalidate its output.
            args.clean = True
        elif args.src is not None:
            src = args.src.expanduser().resolve()
            lower_domains = parse_lower_domains(args.lower_domains or "idle,run,walk")
        else:
            print("ERROR: pass a runtime domain such as 'idle' or 'run', or provide --src.")
            return 2
    except RuntimeError as exc:
        print(f"ERROR: {exc}")
        return 2

    args.src = src

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

    if selected_direction:
        jobs, missing = find_direction_pair_jobs(lower_sheets, upper_sheets)
    else:
        jobs, missing = find_pair_jobs(
            lower_sheets=lower_sheets,
            upper_sheets=upper_sheets,
            lower_domains=lower_domains,
        )

    # ── Chain grouping ───────────────────────────────────────────────────
    chain_phases: List[str] = []
    if args.chain:
        chain_phases = [p.strip() for p in args.chain.split(",") if p.strip()]
        print(f"chain phases: {chain_phases}")

    if chain_phases:
        chain_groups, remaining = find_chain_groups(jobs, chain_phases)
        print(f"chain groups: {len(chain_groups)} (from {len(jobs) - len(remaining)} paired jobs, "
              f"{len(remaining)} individual jobs remaining)")
    else:
        chain_groups = []
        remaining = jobs

    records: List[Dict] = []

    # Process chain groups first
    for chain in chain_groups:
        try:
            strip, frames, meta, fit_debug = composite_chain(chain, args)
            review = make_review_sheet(None, frames, args, chain_meta=meta)
        except Exception as exc:
            import traceback
            missing.append({
                "chain": " → ".join(j.upper.workspace_path.name for j in chain.phases),
                "lower": chain.lower.workspace_path.name,
                "error": str(exc),
                "traceback": traceback.format_exc(),
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
        if fit_debug is not None:
            record["fit_debug"] = fit_debug
            if args.fit_verbose:
                print_fit_debug(output_id, fit_debug)
        records.append(record)

    # Process remaining individual jobs
    for job in remaining:
        try:
            strip, frames, meta, fit_debug = composite_pair(job, args)
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

        if fit_debug is not None:
            record["fit_debug"] = fit_debug
            if args.fit_verbose:
                print_fit_debug(output_id, fit_debug)

        records.append(record)

    manifest = {
        "schema": "custodian.operator_modular_combo_check.lower_upper_dirs.v5_actionable_paths",
        "notice": "Generated artifact—not project authority.",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "commit_sha": _git_commit(args.repo_root.expanduser().resolve()),
        "repo_root": str(args.repo_root.expanduser().resolve()),
        "src": str(src),
        "lower_dir": str(lower_dir),
        "upper_dir": str(upper_dir),
        "check_dir": str(check_dir),
        "runtime_selection_kind": "direction" if selected_direction else ("domain" if args.domain else "manual"),
        "runtime_selection": selected_direction or args.domain,
        "lower_domains": lower_domains,
        "output_frame_policy": args.output_frame_policy,
        "upper_frame_repeat": args.upper_frame_repeat,
        "lower_frame_repeat": args.lower_frame_repeat,
        "fit_debug": args.fit_debug,
        "fit_gap_threshold": args.fit_gap_threshold,
        "fit_center_threshold": args.fit_center_threshold,
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

    run_next_actions_report(args, manifest_path)
    write_html(check_dir, records, warnings, missing, args)

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

    # Fit summary
    if args.fit_debug:
        threshold = args.fit_gap_threshold
        center_threshold = args.fit_center_threshold
        bad_pairs = []
        for r in records:
            fd = r.get("fit_debug", [])
            flagged = [
                d for d in fd
                if (d.get("vertical_gap_px") is not None and abs(d["vertical_gap_px"]) >= threshold)
                or (d.get("horizontal_center_delta_px") is not None and abs(d["horizontal_center_delta_px"]) >= center_threshold)
            ]
            if flagged:
                bad_pairs.append((r["id"], len(flagged), len(fd)))
        if bad_pairs:
            print(f"\n⚠️  Fit-debug: {len(bad_pairs)}/{len(records)} pairings exceed gap/center thresholds (±{threshold}px / ±{center_threshold}px):")
            for pid, n, total in sorted(bad_pairs)[:20]:
                print(f"  {pid}: {n}/{total} frames flagged")
            if len(bad_pairs) > 20:
                print(f"  ... and {len(bad_pairs) - 20} more")
        else:
            print(f"\n✅ Fit-debug: all {len(records)} pairings within gap/center thresholds (±{threshold}px / ±{center_threshold}px)")

    if args.open:
        subprocess.run(["xdg-open", str(check_dir / "index.html")], check=False)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
