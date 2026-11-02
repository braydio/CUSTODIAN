#!/usr/bin/env python3
"""Stage Vaultwing bonding sheets as immutable sources and Asset V2 inbox strips."""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image


REPO = Path(__file__).resolve().parents[3]
CUSTODIAN = REPO / "custodian"
SOURCE_WORK = CUSTODIAN / "asset_drop/source_work/fauna/ambient_vaultwing_common"
INBOX = CUSTODIAN / "asset_drop/inbox/ambient_vaultwing_common"
RUNTIME = CUSTODIAN / "content/sprites/ambient_creatures/vaultwing_common/runtime/body"


@dataclass(frozen=True)
class SourceSpec:
    action: str
    direction: str
    frames: int
    reference_actions: tuple[str, ...]

    @property
    def semantic_name(self) -> str:
        return f"{self.action}_{self.direction}"


SPECS: dict[int, SourceSpec] = {
    1: SourceSpec("notice_bait", "e", 4, ("ground_idle", "perch_idle")),
    2: SourceSpec("notice_bait", "s", 4, ("ground_idle", "perch_idle")),
    3: SourceSpec("notice_bait", "n", 4, ("ground_idle", "perch_idle")),
    4: SourceSpec("guarded_approach", "e", 6, ("ground_walk",)),
    5: SourceSpec("guarded_approach", "s", 6, ("ground_walk",)),
    6: SourceSpec("guarded_approach", "n", 6, ("ground_walk",)),
    7: SourceSpec("inspect_bait", "e", 5, ("ground_idle", "perch_idle")),
    8: SourceSpec("inspect_bait", "s", 5, ("ground_idle", "perch_idle")),
    9: SourceSpec("inspect_bait", "n", 5, ("ground_idle", "perch_idle")),
    10: SourceSpec("feed_accept", "e", 6, ("ground_idle", "perch_idle")),
    11: SourceSpec("feed_accept", "s", 6, ("ground_idle", "perch_idle")),
    12: SourceSpec("feed_accept", "n", 6, ("ground_idle", "perch_idle")),
    13: SourceSpec("watch_player", "e", 6, ("ground_idle", "perch_idle")),
    14: SourceSpec("watch_player", "s", 6, ("ground_idle", "perch_idle")),
    15: SourceSpec("watch_player", "n", 6, ("ground_idle", "perch_idle")),
    16: SourceSpec("bond_greet", "e", 8, ("ground_idle", "perch_idle")),
    17: SourceSpec("bond_greet", "s", 8, ("ground_idle", "perch_idle")),
    18: SourceSpec("bond_greet", "n", 8, ("ground_idle", "perch_idle")),
}

BOND_GREET_DOWNLOADS = {
    "e": "vw_east_facing.png",
    "n": "vw_north_facing.png",
    "s": "vw_south_facing.png",
    "w": "vw_west_facing.png",
}
BOND_GREET_SPEC = SourceSpec("bond_greet", "e", 8, ("ground_idle", "perch_idle"))

CELL = 256
TARGET_ANCHOR = (128, 232)
ALPHA_THRESHOLD = 8
EDGE_GUARD = 8
MAX_MATTE_RATIO = 0.30
MAX_LOW_ALPHA_COVERAGE = 0.10


class StageError(RuntimeError):
    pass


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def find_sources(ordinals: list[int]) -> tuple[dict[int, Path], set[int], list[str]]:
    found: dict[int, Path] = {}
    ambiguous: set[int] = set()
    messages: list[str] = []
    for ordinal in ordinals:
        compact = REPO / f"vw{ordinal}.png"
        underscored = REPO / f"vw_{ordinal}.png"
        candidates = [p for p in (compact, underscored) if p.is_file()]
        if not candidates:
            messages.append(f"MISSING {ordinal}: {compact.name} / {underscored.name}")
            continue
        if len(candidates) == 2:
            left_hash, right_hash = (sha256(path) for path in candidates)
            if left_hash != right_hash:
                ambiguous.add(ordinal)
                messages.append(
                    f"AMBIGUOUS {ordinal}: {compact.name} sha256={left_hash}; "
                    f"{underscored.name} sha256={right_hash}"
                )
                continue
            messages.append(f"DUPLICATE-IDENTICAL {ordinal}: {compact.name}, {underscored.name}")
        found[ordinal] = candidates[0]
    return found, ambiguous, messages


def copy_immutable(source: Path, target: Path) -> str:
    target.parent.mkdir(parents=True, exist_ok=True)
    source_hash = sha256(source)
    if target.exists():
        if sha256(target) != source_hash:
            raise StageError(f"refusing to overwrite different source master: {target}")
    else:
        shutil.copy2(source, target)
    if sha256(target) != source_hash:
        raise StageError(f"source_work hash mismatch after copy: {target}")
    return source_hash


def preserve_candidate(source: Path, spec: SourceSpec, ordinal: int, *, apply: bool) -> tuple[bool, str, str]:
    """Validate before assigning canonical provenance; rejected candidates stay local."""
    source_hash = sha256(source)
    try:
        image, _alpha = source_rgba(source)
        image.close()
    except StageError as error:
        return False, source_hash, str(error)

    target = SOURCE_WORK / f"{spec.semantic_name}_source.png"
    if apply:
        copy_immutable(source, target)
    elif target.exists() and sha256(target) != source_hash:
        raise StageError(f"refusing to overwrite different source master: {target}")
    return True, source_hash, ""


def source_rgba(path: Path) -> tuple[Image.Image, np.ndarray]:
    image = Image.open(path).convert("RGBA")
    rgba = np.asarray(image)
    alpha = rgba[:, :, 3]
    nontransparent_ratio = float(np.count_nonzero(alpha > ALPHA_THRESHOLD)) / float(alpha.size)
    low_alpha_coverage = float(np.count_nonzero((alpha > 0) & (alpha <= ALPHA_THRESHOLD))) / float(alpha.size)
    if nontransparent_ratio > MAX_MATTE_RATIO or low_alpha_coverage > MAX_LOW_ALPHA_COVERAGE:
        raise StageError(
            f"nontransparent background/matte detected: {nontransparent_ratio:.1%} "
            f"pixels exceed alpha {ALPHA_THRESHOLD}, {low_alpha_coverage:.1%} have alpha 1.."
            f"{ALPHA_THRESHOLD} (limits {MAX_MATTE_RATIO:.0%} and {MAX_LOW_ALPHA_COVERAGE:.0%})"
        )
    return image, alpha


def x_clusters(alpha: np.ndarray) -> list[tuple[int, int]]:
    projection = np.count_nonzero(alpha > ALPHA_THRESHOLD, axis=0)
    active = projection >= max(4, round(alpha.shape[0] * 0.003))
    indices = np.flatnonzero(active)
    if indices.size == 0:
        return []
    clusters: list[tuple[int, int]] = []
    start = previous = int(indices[0])
    for value in indices[1:]:
        x = int(value)
        if x - previous > 1:
            clusters.append((start, previous))
            start = x
        previous = x
    clusters.append((start, previous))
    merged: list[tuple[int, int]] = []
    for left, right in clusters:
        if merged and left - merged[-1][1] <= 3:
            merged[-1] = (merged[-1][0], right)
        else:
            merged.append((left, right))
    return merged


def frame_bounds(alpha: np.ndarray, cluster: tuple[int, int]) -> tuple[int, int, int, int]:
    left, right = cluster
    ys, local_xs = np.where(alpha[:, left:right + 1] > ALPHA_THRESHOLD)
    if not len(local_xs):
        raise StageError(f"empty detected frame cluster {cluster}")
    bounds = (left + int(local_xs.min()), int(ys.min()), left + int(local_xs.max()), int(ys.max()))
    x0, y0, x1, y1 = bounds
    if x0 <= 1 or y0 <= 1 or x1 >= alpha.shape[1] - 2 or y1 >= alpha.shape[0] - 2:
        raise StageError(f"source frame touches sheet edge and may be clipped: bounds={bounds}")
    return bounds


def support_anchor(alpha: np.ndarray, bounds: tuple[int, int, int, int]) -> tuple[float, float]:
    x0, y0, x1, y1 = bounds
    width, height = x1 - x0 + 1, y1 - y0 + 1
    cx = (x0 + x1) / 2.0
    core_half_width = max(5.0, width * 0.18)
    band_y0 = y0 + int(height * 0.66)
    band = alpha[band_y0:y1 + 1, max(0, int(cx - core_half_width)):min(alpha.shape[1], int(cx + core_half_width) + 1)]
    ys, xs = np.where(band > ALPHA_THRESHOLD)
    if not len(xs):
        raise StageError(f"cannot find grounded support in central lower region: bounds={bounds}")
    anchor_y = float(band_y0 + int(ys.max()))
    bottom = xs[ys >= max(0, int(ys.max()) - 5)]
    x_start = max(0, int(cx - core_half_width))
    anchor_x = float(x_start + np.median(bottom))
    return anchor_x, anchor_y


def reference_height(action: str, direction: str, ref_actions: tuple[str, ...]) -> float:
    heights: list[int] = []
    for reference in ref_actions:
        matches = list(RUNTIME.rglob(
            f"vaultwing_common__body__*__{reference}__{direction}__*__256.png"
        ))
        if len(matches) != 1:
            raise StageError(f"expected one approved {reference}/{direction} reference, found {len(matches)}")
        image = Image.open(matches[0]).convert("RGBA")
        alpha = np.asarray(image.getchannel("A"))
        frame_heights: list[int] = []
        for frame in range(image.width // CELL):
            cell = alpha[:, frame * CELL:(frame + 1) * CELL]
            ys, _ = np.where(cell > ALPHA_THRESHOLD)
            if len(ys):
                frame_heights.append(int(ys.max() - ys.min() + 1))
        if frame_heights:
            heights.append(round(float(np.median(frame_heights))))
    if not heights:
        raise StageError(f"no usable reference height for {action}/{direction}")
    return float(max(heights))


def resize_premultiplied(frame: Image.Image, size: tuple[int, int]) -> Image.Image:
    rgba = np.asarray(frame.convert("RGBA"), dtype=np.float32)
    alpha = rgba[:, :, 3] / 255.0
    channels: list[np.ndarray] = []
    for channel in range(3):
        premul = Image.fromarray(rgba[:, :, channel] * alpha, mode="F")
        resized = np.asarray(premul.resize(size, Image.Resampling.LANCZOS), dtype=np.float32)
        channels.append(resized)
    alpha_image = Image.fromarray(rgba[:, :, 3], mode="F")
    resized_alpha = np.asarray(alpha_image.resize(size, Image.Resampling.LANCZOS), dtype=np.float32)
    out = np.zeros((size[1], size[0], 4), dtype=np.uint8)
    safe_alpha = np.clip(resized_alpha, 0.0, 255.0)
    for channel in range(3):
        unpremultiplied = np.divide(
            channels[channel] * 255.0,
            safe_alpha,
            out=np.zeros_like(safe_alpha),
            where=safe_alpha > 0.5,
        )
        out[:, :, channel] = np.clip(unpremultiplied, 0, 255).astype(np.uint8)
    out[:, :, 3] = safe_alpha.astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def normalize_strip(
    path: Path, spec: SourceSpec, *, fixed_cells: bool = False
) -> tuple[Image.Image, dict[str, object]]:
    sheet, alpha = source_rgba(path)
    if fixed_cells:
        if sheet.width % spec.frames:
            raise StageError(
                f"sheet width {sheet.width} is not divisible into {spec.frames} equal frame cells"
            )
        cell_width = sheet.width // spec.frames
        if sheet.height != cell_width:
            raise StageError(
                f"expected square {cell_width}x{cell_width} frame cells; got sheet {sheet.size}"
            )
        seams = [
            int(np.count_nonzero(alpha[:, boundary - 1:boundary + 1] > ALPHA_THRESHOLD))
            for boundary in range(cell_width, sheet.width, cell_width)
        ]
        if any(seams):
            raise StageError(f"fixed-cell boundaries intersect visible pixels: {seams}")
        bounds = []
        for index in range(spec.frames):
            left = index * cell_width
            local = alpha[:, left:left + cell_width]
            ys, xs = np.where(local > ALPHA_THRESHOLD)
            if not len(xs):
                raise StageError(f"empty fixed frame cell {index}")
            box = (left + int(xs.min()), int(ys.min()), left + int(xs.max()), int(ys.max()))
            x0, y0, x1, y1 = box
            if x0 <= left + 1 or y0 <= 1 or x1 >= left + cell_width - 2 or y1 >= sheet.height - 2:
                raise StageError(f"source frame {index} touches its cell edge and may be clipped: {box}")
            bounds.append(box)
        clusters: list[tuple[int, int]] = []
        layout = "fixed_equal_cells"
    else:
        clusters = x_clusters(alpha)
        if len(clusters) != spec.frames:
            raise StageError(f"found {len(clusters)} alpha-X frame clusters; expected {spec.frames}")
        bounds = [frame_bounds(alpha, cluster) for cluster in clusters]
        layout = "alpha_x_clusters"
    anchors = [support_anchor(alpha, box) for box in bounds]
    anchor_x = float(np.median([point[0] for point in anchors]))
    anchor_y = float(np.median([point[1] for point in anchors]))
    widths = [box[2] - box[0] + 1 for box in bounds]
    heights = [box[3] - box[1] + 1 for box in bounds]
    ref_h = reference_height(spec.action, spec.direction, spec.reference_actions)
    scale = min(ref_h / float(np.median(heights)), 1.0)
    max_left = max(point[0] - box[0] for point, box in zip(anchors, bounds))
    max_right = max(box[2] - point[0] for point, box in zip(anchors, bounds))
    max_up = max(point[1] - box[1] for point, box in zip(anchors, bounds))
    max_down = max(box[3] - point[1] for point, box in zip(anchors, bounds))
    fit_caps = (
        120.0 / max(max_left, 1.0),
        120.0 / max(max_right, 1.0),
        (TARGET_ANCHOR[1] - EDGE_GUARD) / max(max_up, 1.0),
        (CELL - EDGE_GUARD - TARGET_ANCHOR[1]) / max(max_down, 1.0),
    )
    scale = min(scale, *fit_caps)
    if scale <= 0.0:
        raise StageError(f"nonpositive shared strip scale {scale}")

    strip = Image.new("RGBA", (CELL * spec.frames, CELL), (0, 0, 0, 0))
    normalized_bounds: list[tuple[int, int, int, int]] = []
    for index, (box, frame_anchor) in enumerate(zip(bounds, anchors)):
        x0, y0, x1, y1 = box
        crop = sheet.crop((x0, y0, x1 + 1, y1 + 1))
        target_size = (max(1, round(crop.width * scale)), max(1, round(crop.height * scale)))
        resized = resize_premultiplied(crop, target_size)
        paste_x = round(TARGET_ANCHOR[0] + (x0 - frame_anchor[0]) * scale)
        paste_y = round(TARGET_ANCHOR[1] + (y0 - frame_anchor[1]) * scale)
        strip.alpha_composite(resized, (index * CELL + paste_x, paste_y))
        cell_alpha = np.asarray(strip.getchannel("A"))[:, index * CELL:(index + 1) * CELL]
        ys, xs = np.where(cell_alpha > ALPHA_THRESHOLD)
        actual = (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))
        if actual[0] < EDGE_GUARD or actual[1] < EDGE_GUARD or actual[2] > CELL - EDGE_GUARD - 1 or actual[3] > CELL - EDGE_GUARD - 1:
            raise StageError(f"normalized frame {index} violates cell-edge guard: {actual}")
        normalized_bounds.append(actual)

    info = {
        "source_dimensions": list(sheet.size),
        "source_layout": layout,
        "source_alpha_bounds": bounds,
        "source_frame_x_clusters": clusters,
        "source_frame_anchor_medians": [anchor_x, anchor_y],
        "source_frame_anchors": anchors,
        "reference_height_px": ref_h,
        "shared_scale": scale,
        "target_dimensions": list(strip.size),
        "target_frame_bounds": normalized_bounds,
    }
    return strip, info


def _encoded_png(image: Image.Image) -> bytes:
    stream = io.BytesIO()
    image.save(stream, format="PNG", optimize=True)
    return stream.getvalue()


def stage_downloads_batch(downloads: Path, *, dry_run: bool) -> dict[str, object]:
    """Preflight the named four-direction greeting batch before creating any outputs."""
    if not downloads.is_dir():
        raise StageError(f"Downloads directory does not exist: {downloads}")
    sources: dict[str, Path] = {direction: downloads / name for direction, name in BOND_GREET_DOWNLOADS.items()}
    missing = [str(path) for path in sources.values() if not path.is_file()]
    if missing:
        raise StageError("missing named batch inputs: " + ", ".join(missing))
    hashes = {direction: sha256(path) for direction, path in sources.items()}
    if len(set(hashes.values())) != len(hashes):
        raise StageError("named batch inputs are not unique; duplicate source hashes detected")

    plans: list[dict[str, object]] = []
    prepared: list[tuple[Path, bytes, Path, bytes, dict[str, object]]] = []
    for direction, source in sources.items():
        spec = SourceSpec(
            BOND_GREET_SPEC.action,
            direction,
            BOND_GREET_SPEC.frames,
            BOND_GREET_SPEC.reference_actions,
        )
        try:
            strip, geometry = normalize_strip(source, spec, fixed_cells=True)
        except (OSError, ValueError) as error:
            raise StageError(f"{source.name}: could not decode/normalize: {error}") from error
        except StageError as error:
            raise StageError(f"{source.name}: {error}") from error
        if sha256(source) != hashes[direction]:
            raise StageError(f"{source.name}: source changed during preflight")
        encoded = _encoded_png(strip)
        source_target = SOURCE_WORK / f"bond_greet_{direction}_source.png"
        inbox_target = INBOX / f"bond_greet__{direction}.png"
        source_bytes = source.read_bytes()
        if hashlib.sha256(source_bytes).hexdigest() != hashes[direction]:
            raise StageError(f"{source.name}: source changed while reading immutable source bytes")
        for target, content, label in (
            (source_target, source_bytes, "source master"),
            (inbox_target, encoded, "inbox strip"),
        ):
            if target.exists() and sha256(target) != hashlib.sha256(content).hexdigest():
                raise StageError(f"refusing to overwrite conflicting {label}: {target}")
        needs_write = not (source_target.exists() and inbox_target.exists())
        item = {
            "local_path": str(source),
            "sha256": hashes[direction],
            "direction": direction,
            "source_dimensions": geometry["source_dimensions"],
            "normalized_dimensions": geometry["target_dimensions"],
            "normalized_frame_bounds": geometry["target_frame_bounds"],
            "source_frame_bounds": geometry["source_alpha_bounds"],
            "shared_scale": geometry["shared_scale"],
            "source_work_target": str(source_target.relative_to(REPO)),
            "inbox_target": str(inbox_target.relative_to(REPO)),
            "disposition": "planned" if dry_run and needs_write else ("staged" if needs_write else "already_staged"),
        }
        plans.append(item)
        prepared.append((source_target, source_bytes, inbox_target, encoded, item))

    if not dry_run:
        temporary_paths: list[Path] = []
        created_paths: list[Path] = []
        try:
            for source_target, source_bytes, inbox_target, inbox_bytes, _item in prepared:
                for target, data in ((source_target, source_bytes), (inbox_target, inbox_bytes)):
                    if target.exists():
                        continue
                    target.parent.mkdir(parents=True, exist_ok=True)
                    with tempfile.NamedTemporaryFile(dir=target.parent, prefix=f".{target.name}.", delete=False) as stream:
                        stream.write(data)
                        temp_path = Path(stream.name)
                    if sha256(temp_path) != hashlib.sha256(data).hexdigest():
                        raise StageError(f"temporary write verification failed: {target}")
                    temporary_paths.append(temp_path)
                    os.replace(temp_path, target)
                    temporary_paths.remove(temp_path)
                    created_paths.append(target)
        except Exception:
            for path in temporary_paths:
                path.unlink(missing_ok=True)
            for path in created_paths:
                path.unlink(missing_ok=True)
            raise

    return {
        "schema": "custodian.vaultwing_bond_greet_stage.v1",
        "profile": "bond_greet_downloads_named_directions",
        "dry_run": dry_run,
        "requirements": plans,
        "next_commands": [
            "python3 custodian/tools/assets/asset.py plan ambient_vaultwing_common",
            "python3 custodian/tools/assets/asset.py status ambient_vaultwing_common",
            "python3 custodian/tools/assets/asset.py ingest ambient_vaultwing_common",
        ],
    }


def remove_root_copy_if_untracked(source: Path, expected_hash: str) -> None:
    relative = source.relative_to(REPO)
    tracked = subprocess.run(
        ["git", "ls-files", "--error-unmatch", str(relative)],
        cwd=REPO,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    ).returncode == 0
    if tracked:
        raise StageError(f"refusing to remove tracked source image: {relative}")
    if sha256(source) != expected_hash:
        raise StageError(f"refusing to remove source changed since verified copy: {relative}")
    source.unlink()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="analyze only; do not copy or write")
    parser.add_argument(
        "--downloads-batch",
        nargs="?",
        const=str(Path.home() / "Downloads"),
        metavar="DIRECTORY",
        help="preflight and stage named vw_{east,north,south,west}_facing.png greeting sheets",
    )
    parser.add_argument("--json", action="store_true", help="emit stable structured JSON")
    parser.add_argument(
        "--remove-root-copies",
        action="store_true",
        help="after verified copies, remove only matching untracked root input files",
    )
    parser.add_argument(
        "--ordinals",
        nargs="+",
        type=int,
        default=list(range(1, 11)),
        help="source ordinals to stage (default: Pass 1, 1 through 10; use 11 through 18 for Pass 2)",
    )
    args = parser.parse_args()
    if args.json and args.downloads_batch is None:
        parser.error("--json requires --downloads-batch")
    if args.downloads_batch is not None:
        if args.remove_root_copies:
            parser.error("--remove-root-copies is only available for numbered root inputs")
        try:
            result = stage_downloads_batch(Path(args.downloads_batch).expanduser().resolve(), dry_run=args.dry_run)
        except StageError as error:
            if args.json:
                print(json.dumps({"schema": "custodian.vaultwing_bond_greet_stage.v1", "error": str(error)}, sort_keys=True, separators=(",", ":")))
            else:
                print(f"stage_vaultwing_bonding_source_work: ERROR: {error}", file=sys.stderr)
            return 2
        if args.json:
            print(json.dumps(result, sort_keys=True, separators=(",", ":")))
        else:
            print(json.dumps(result, indent=2, sort_keys=True))
            print("\nAsset V2 next commands:")
            for command in result["next_commands"]:
                print(f"  {command}")
        return 0
    if args.dry_run and args.remove_root_copies:
        parser.error("--remove-root-copies cannot be combined with --dry-run")
    if len(args.ordinals) != len(set(args.ordinals)) or any(value not in SPECS for value in args.ordinals):
        parser.error("--ordinals must contain unique values from 1 through 18")

    selected_ordinals = sorted(args.ordinals)
    found, ambiguous, messages = find_sources(selected_ordinals)
    for message in messages:
        print(message)
    missing = sorted(set(selected_ordinals) - set(found) - ambiguous)
    accepted = 0
    rejected: list[int] = []
    runtime_intended: list[str] = []

    for ordinal in sorted(found):
        if ordinal in ambiguous:
            continue
        source = found[ordinal]
        spec = SPECS[ordinal]
        try:
            strip, info = normalize_strip(source, spec)
        except (StageError, OSError, ValueError) as error:
            rejected.append(ordinal)
            print(f"REJECT {ordinal} {spec.semantic_name}: {error}")
            print(f"LEFT LOCAL {source.name}; no source_work, inbox, runtime, or quarantine file created")
            continue

        is_accepted, source_hash, rejection_reason = preserve_candidate(
            source, spec, ordinal, apply=not args.dry_run
        )
        if not is_accepted:
            rejected.append(ordinal)
            print(f"REJECT {ordinal} {spec.semantic_name}: {rejection_reason}")
            print(f"LEFT LOCAL {source.name}; no source_work, inbox, runtime, or quarantine file created")
            continue

        target_source = SOURCE_WORK / f"{spec.semantic_name}_source.png"
        if not args.dry_run:
            if sha256(target_source) != source_hash:
                raise StageError(f"source_work byte verification failed: {target_source}")
            print(f"SOURCE {ordinal} {source.name} -> {target_source.relative_to(REPO)} sha256={source_hash}")
        else:
            print(f"SOURCE-PLAN {ordinal} {source.name} -> {target_source.relative_to(REPO)} sha256={source_hash}")

        inbox_path = INBOX / f"{spec.action}__{spec.direction}.png"
        if not args.dry_run:
            inbox_path.parent.mkdir(parents=True, exist_ok=True)
            strip.save(inbox_path, format="PNG", optimize=True)
            print(f"INBOX {inbox_path.relative_to(REPO)} {info['target_dimensions']} shared_scale={info['shared_scale']:.5f}")
        else:
            print(f"INBOX-PLAN {inbox_path.relative_to(REPO)} {info['target_dimensions']} shared_scale={info['shared_scale']:.5f}")
        print("  geometry " + json.dumps(info, separators=(",", ":")))
        accepted += 1
        runtime_intended.append(f"{spec.action}:{spec.direction}" + ("/w-mirror" if spec.direction == "e" else ""))

        if args.remove_root_copies and not args.dry_run:
            remove_root_copy_if_untracked(source, source_hash)
            print(f"REMOVED ROOT COPY {source.name}; verified source_work copy retained")

    if missing:
        print("MISSING ORDINALS: " + ", ".join(map(str, missing)))
    if ambiguous:
        print("AMBIGUOUS ORDINALS: " + ", ".join(map(str, sorted(ambiguous))))
    print(f"SUMMARY accepted={accepted} rejected={len(rejected)} missing={len(missing)} ambiguous={len(ambiguous)}")
    print("INTENDED RUNTIME: " + (", ".join(runtime_intended) if runtime_intended else "none"))
    if rejected or ambiguous:
        return 2
    return 0 if accepted else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except StageError as error:
        print(f"stage_vaultwing_bonding_source_work: ERROR: {error}", file=sys.stderr)
        raise SystemExit(2)
