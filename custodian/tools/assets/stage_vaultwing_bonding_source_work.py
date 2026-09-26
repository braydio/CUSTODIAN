#!/usr/bin/env python3
"""Stage numbered Vaultwing bonding sheets as immutable sources and V2 inbox strips."""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image


REPO = Path(__file__).resolve().parents[3]
CUSTODIAN = REPO / "custodian"
SOURCE_WORK = CUSTODIAN / "asset_drop/source_work/fauna/ambient_vaultwing_common"
INBOX = CUSTODIAN / "asset_drop/inbox/ambient_vaultwing_common"
QUARANTINE = CUSTODIAN / "asset_drop/unresolved/vaultwing_bonding_pass_1_matte"
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


def normalize_strip(path: Path, spec: SourceSpec) -> tuple[Image.Image, dict[str, object]]:
    sheet, alpha = source_rgba(path)
    clusters = x_clusters(alpha)
    if len(clusters) != spec.frames:
        raise StageError(f"found {len(clusters)} alpha-X frame clusters; expected {spec.frames}")
    bounds = [frame_bounds(alpha, cluster) for cluster in clusters]
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
        target_source = SOURCE_WORK / f"{spec.semantic_name}_source.png"
        try:
            image, _alpha = source_rgba(source)
        except StageError as error:
            rejected.append(ordinal)
            print(f"REJECT {ordinal} {spec.semantic_name}: {error}")
            if not args.dry_run:
                quarantine = QUARANTINE / f"{spec.semantic_name}_vw{ordinal}.png"
                qhash = copy_immutable(source, quarantine)
                print(f"QUARANTINE {quarantine.relative_to(REPO)} sha256={qhash}")
        else:
            image.close()

        source_hash = sha256(source)
        if not args.dry_run:
            source_hash = copy_immutable(source, target_source)
            print(f"SOURCE {ordinal} {source.name} -> {target_source.relative_to(REPO)} sha256={source_hash}")
            if sha256(target_source) != source_hash:
                raise StageError(f"source_work byte verification failed: {target_source}")
        else:
            print(f"SOURCE-PLAN {ordinal} {source.name} -> {target_source.relative_to(REPO)} sha256={source_hash}")

        if ordinal in rejected:
            if args.remove_root_copies and not args.dry_run:
                remove_root_copy_if_untracked(source, source_hash)
                print(f"REMOVED ROOT COPY {source.name}; verified source_work and quarantine copies retained")
            continue

        strip, info = normalize_strip(source, spec)
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
