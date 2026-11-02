#!/usr/bin/env python3
"""One-off bridge from the Baby Opossum source-work collection into the family inbox.

This is deliberately narrow. It exists because ``asset_drop/source_work/baby_opossum/``
holds raw artist renders at assorted canvas sizes that pre-date the Asset V2 family,
and part of that collection was staged into ``asset_drop/inbox/ambient_baby_opossum/``
with the wrong frame grid. This tool

  * audits every staged inbox strip for the 96px production cell contract,
  * quarantines staged strips whose poses are sliced across cell boundaries,
  * stages the small set of source-work renders that sit on a provably uniform pose
    grid, using a transform measured from an already-approved sibling strip.

It never writes into ``content/sprites/`` (that is the Asset Pipeline's job, run
``asset.py ingest`` afterwards) and never modifies ``source_work/``.

Default mode is a dry run; pass ``--apply`` to write.
"""

from __future__ import annotations

import argparse
import hashlib
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

try:
    import numpy as np
    from PIL import Image
    from scipy import ndimage as ndi
except ImportError as error:  # pragma: no cover - environment guard
    sys.exit(f"stage_baby_opossum_source_work: missing dependency ({error})")

CUSTODIAN = Path(__file__).resolve().parents[2]
SOURCE_WORK = CUSTODIAN / "asset_drop/source_work/baby_opossum"
INBOX = CUSTODIAN / "asset_drop/inbox/ambient_baby_opossum"
QUARANTINE = CUSTODIAN / "asset_drop/unresolved/ambient_baby_opossum"
CELL = 96
ALPHA_FLOOR = 8


@dataclass(frozen=True)
class StagePlan:
    """A source render that sits on a uniform pose grid.

    ``scale``/``offset_x``/``offset_y`` map source-cell pixels into the 96x96
    production cell. They are measured from ``reference`` — an inbox strip that is
    already approved and shares the source render's canvas and camera — so a newly
    staged clip lands at the same character scale and baseline as its siblings
    rather than at a scale invented here.
    """

    source: str
    state: str
    direction: str
    frames: int
    scale: float
    offset_x: float
    offset_y: float
    reference: str


# Only renders whose pose grid is provably uniform (see --audit output) are listed.
# Everything else in source_work is reported as unmapped rather than guessed at.
STAGE_PLANS = (
    StagePlan("opossum_groom_s_v1.png", "groom", "s", 6,
              0.19388, 12.78, -23.06, "approach_wary__s.png"),
    StagePlan("opossum_scratch_s_v1.png", "scratch", "s", 6,
              0.19388, 12.78, -23.06, "approach_wary__s.png"),
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


# A cell of a well-formed strip holds one pose. Slicing a strip on the wrong grid
# leaves a piece of the neighbouring pose behind (a large secondary blob) and makes
# the pose march sideways from frame to frame instead of holding its position.
# Measured across the approved Baby Opossum strips: secondary blob ratio tops out at
# 0.04 and drift at 19.5px when the grid is right; the lowest mis-sliced strip sits at
# 0.075 / 22.0px. The thresholds below sit in that gap.
MAX_SECONDARY_BLOB_RATIO = 0.06
MAX_POSE_DRIFT_PX = 22.0


def _frame_blobs(mask: "np.ndarray") -> list[tuple[float, int, int]]:
    """(area, x_min, x_max) of each connected content blob, largest first."""
    labels, count = ndi.label(mask)
    if not count:
        return []
    areas = np.asarray(ndi.sum(mask, labels, range(1, count + 1)))
    blobs = []
    for index in np.argsort(areas)[::-1]:
        xs = np.nonzero(labels == index + 1)[1]
        blobs.append((float(areas[index]), int(xs.min()), int(xs.max())))
    return blobs


def audit_strip(path: Path) -> tuple[int, list[str]]:
    """Validate one staged strip against the production cell contract."""
    problems: list[str] = []
    image = Image.open(path)
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    if image.height != CELL:
        problems.append(f"height {image.height} != {CELL}")
    if image.width % CELL:
        problems.append(f"width {image.width} not a multiple of {CELL}")
    frames = max(1, image.width // CELL)
    alpha = np.asarray(image.getchannel("A"))
    if alpha.min() > ALPHA_FLOOR:
        problems.append("no transparent pixels (matte or opaque background)")

    content = alpha > ALPHA_FLOOR
    centres: list[float] = []
    for index in range(frames):
        cell = content[:, index * CELL:(index + 1) * CELL]
        blobs = _frame_blobs(cell)
        if not blobs:
            problems.append(f"frame {index} is empty")
            continue
        main_area, x_min, x_max = blobs[0]
        centres.append((x_min + x_max) / 2.0)
        if len(blobs) > 1:
            ratio = blobs[1][0] / main_area
            if ratio >= MAX_SECONDARY_BLOB_RATIO:
                problems.append(
                    f"frame {index} holds a second pose fragment "
                    f"({ratio:.0%} of the main pose) — sliced on the wrong frame grid"
                )
    if len(centres) > 1:
        drift = max(centres) - min(centres)
        if drift >= MAX_POSE_DRIFT_PX:
            problems.append(
                f"pose drifts {drift:.0f}px across the strip — frame width does not "
                "match the source pose spacing"
            )
    return frames, problems


def render(source: Path, plan: StagePlan) -> Image.Image:
    image = Image.open(source).convert("RGBA")
    width, height = image.size
    out = Image.new("RGBA", (CELL * plan.frames, CELL), (0, 0, 0, 0))
    for index in range(plan.frames):
        x0 = round(index * width / plan.frames)
        x1 = round((index + 1) * width / plan.frames)
        cell = image.crop((x0, 0, x1, height))
        scaled = cell.resize(
            (max(1, round(cell.width * plan.scale)), max(1, round(cell.height * plan.scale))),
            Image.LANCZOS,
        )
        frame = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
        frame.alpha_composite(scaled, (round(plan.offset_x), round(plan.offset_y)))
        out.alpha_composite(frame, (index * CELL, 0))
    return out


def run(apply: bool) -> int:
    mode = "APPLY" if apply else "DRY RUN"
    print(f"Baby Opossum source-work staging · {mode}")
    failures = 0

    print("\nSTAGED INBOX AUDIT")
    quarantined: list[str] = []
    for path in sorted(INBOX.glob("*.png")):
        frames, problems = audit_strip(path)
        if not problems:
            print(f"  ok       {path.name:28} {frames}f")
            continue
        quarantined.append(path.name)
        print(f"  QUARANTINE {path.name:26} {frames}f · {problems[0]}")
        for extra in problems[1:]:
            print(f"             {'':26}    {extra}")
        if apply:
            QUARANTINE.mkdir(parents=True, exist_ok=True)
            shutil.move(str(path), str(QUARANTINE / path.name))

    print("\nSOURCE-WORK STAGING")
    for plan in STAGE_PLANS:
        source = SOURCE_WORK / plan.source
        target = INBOX / f"{plan.state}__{plan.direction}.png"
        if not source.exists():
            print(f"  MISSING  {plan.source}")
            failures += 1
            continue
        if not (INBOX / plan.reference).exists() and not (QUARANTINE / plan.reference).exists():
            print(f"  BLOCKED  {plan.state}: transform reference {plan.reference} is absent")
            failures += 1
            continue
        staged = render(source, plan)
        tmp = target.with_suffix(".staging.png")
        staged.save(tmp)
        _, problems = audit_strip(tmp)
        if problems:
            tmp.unlink()
            print(f"  BLOCKED  {plan.state}: {problems[0]}")
            failures += 1
            continue
        if target.exists():
            if sha256(target) == sha256(tmp):
                tmp.unlink()
                print(f"  same     {target.name} (byte-identical, skipped)")
                continue
            tmp.unlink()
            print(f"  CONFLICT {target.name} already staged with different bytes; refusing to overwrite")
            failures += 1
            continue
        if apply:
            tmp.rename(target)
        else:
            tmp.unlink()
        print(f"  stage    {target.name:28} {plan.frames}f  from {plan.source}")

    mapped = {p.source for p in STAGE_PLANS}
    unmapped = [p.name for p in sorted(SOURCE_WORK.glob("*.png")) if p.name not in mapped]
    print(f"\nUNMAPPED SOURCE-WORK ({len(unmapped)})")
    print("  These renders are already staged, or their poses are not on a uniform")
    print("  grid and need an artist re-export before they can be staged:")
    for name in unmapped:
        print(f"    {name}")

    if quarantined:
        print(f"\n{len(quarantined)} staged strip(s) quarantined to {QUARANTINE.relative_to(CUSTODIAN)}")
        if not apply:
            print("  (dry run — nothing was moved)")
    print("\nNext: python tools/assets/asset.py plan ambient_baby_opossum")
    return 1 if failures else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write changes (default is a dry run)")
    return run(parser.parse_args().apply)


if __name__ == "__main__":
    raise SystemExit(main())
