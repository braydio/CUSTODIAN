#!/usr/bin/env python3
from __future__ import annotations

import os
import re
import json
from dataclasses import dataclass, asdict
from pathlib import Path
from datetime import datetime

try:
    from PIL import Image
except ImportError:
    raise SystemExit("Install Pillow first: python -m pip install pillow")

ROOT = Path.cwd()
CUSTODIAN = ROOT / "custodian"

SOURCE_DIRS = [
    CUSTODIAN / "assets/sprites/operator/new_operator",
    CUSTODIAN / "assets/sprites/operator/source",
    CUSTODIAN / "assets/sprites/operator/in_progress",
]

RUNTIME_DIRS = [
    CUSTODIAN / "assets/sprites/operator/runtime",
    CUSTODIAN / "content/animations/operator",
]

SCAN_TEXT_EXTS = {".gd", ".tscn", ".tres", ".res", ".import", ".json", ".cfg"}
IMAGE_EXTS = {".png", ".webp"}

FRAME_W = 96
FRAME_H = 96
EXPECTED_DIRECTIONS = ["n", "ne", "e", "se", "s"]
MISSION_CRITICAL = [
    "idle",
    "walk",
    "run",
    "ranged_relaxed",
    "aim",
    "fire",
    "dodge",
    "block",
    "parry",
    "hit",
    "stagger",
    "death",
]

DIRECTION_PATTERNS = {
    "ne": r"(^|[_\-. ])ne($|[_\-. ])|northeast|north_east",
    "nw": r"(^|[_\-. ])nw($|[_\-. ])|northwest|north_west",
    "se": r"(^|[_\-. ])se($|[_\-. ])|southeast|south_east",
    "sw": r"(^|[_\-. ])sw($|[_\-. ])|southwest|south_west",
    "n": r"(^|[_\-. ])n($|[_\-. ])|north",
    "s": r"(^|[_\-. ])s($|[_\-. ])|south",
    "e": r"(^|[_\-. ])e($|[_\-. ])|east",
    "w": r"(^|[_\-. ])w($|[_\-. ])|west",
}

ANIM_TOKENS = [
    "idle",
    "walk",
    "run",
    "ranged_relaxed",
    "relaxed",
    "ready",
    "aim",
    "take_aim",
    "fire",
    "firing",
    "reload",
    "dodge",
    "roll",
    "block",
    "guard",
    "parry",
    "fast_attack",
    "heavy_attack",
    "strike",
    "hit",
    "stagger",
    "death",
]


@dataclass
class Candidate:
    path: str
    inferred_animation: str
    inferred_direction: str | None
    width: int
    height: int
    frame_w: int
    frame_h: int
    frame_count: int
    modified: str
    confidence: int
    flags: list[str]
    suggested_runtime_path: str
    already_referenced: bool


def read_text_corpus() -> str:
    chunks = []
    for p in CUSTODIAN.rglob("*"):
        if p.suffix.lower() in SCAN_TEXT_EXTS and p.is_file():
            try:
                chunks.append(p.read_text(errors="ignore"))
            except Exception:
                pass
    return "\n".join(chunks).lower()


def infer_direction(name: str) -> str | None:
    low = name.lower()
    for d, pat in DIRECTION_PATTERNS.items():
        if re.search(pat, low):
            return d
    return None


def infer_animation(name: str) -> str:
    low = name.lower()
    hits = [t for t in ANIM_TOKENS if t in low]
    if not hits:
        return "unknown"
    hits.sort(key=len, reverse=True)
    anim = hits[0]
    if anim == "relaxed":
        return "ranged_relaxed"
    if anim == "firing":
        return "fire"
    if anim == "guard":
        return "block"
    if anim == "roll":
        return "dodge"
    return anim


def score_candidate(width, height, frame_count, anim, direction, mtime, referenced):
    flags = []
    score = 0

    if width % FRAME_W == 0 and height % FRAME_H == 0:
        score += 30
    else:
        flags.append("SIZE_NOT_DIVISIBLE_BY_96x96")

    if height == FRAME_H:
        score += 20
    else:
        flags.append("MULTI_ROW_OR_NONSTANDARD_HEIGHT")

    if 2 <= frame_count <= 12:
        score += 20
    else:
        flags.append("ODD_FRAME_COUNT")

    if anim != "unknown":
        score += 15
    else:
        flags.append("ANIMATION_NAME_UNKNOWN")

    if direction:
        score += 10
    else:
        flags.append("DIRECTION_UNKNOWN")

    days_old = (datetime.now().timestamp() - mtime) / 86400
    if days_old <= 21:
        score += 5
        flags.append("RECENTLY_MODIFIED")

    if referenced:
        flags.append("ALREADY_REFERENCED")

    return min(score, 100), flags


def collect_candidates():
    corpus = read_text_corpus()
    out = []

    for src in SOURCE_DIRS:
        if not src.exists():
            continue

        for p in src.rglob("*"):
            if not p.is_file() or p.suffix.lower() not in IMAGE_EXTS:
                continue

            try:
                with Image.open(p) as im:
                    width, height = im.size
            except Exception:
                continue

            rel = p.relative_to(ROOT).as_posix()
            name = p.stem
            anim = infer_animation(name)
            direction = infer_direction(name)
            frame_count = (
                (width // FRAME_W) * max(1, height // FRAME_H)
                if width >= FRAME_W and height >= FRAME_H
                else 0
            )
            referenced = rel.lower() in corpus or p.name.lower() in corpus

            score, flags = score_candidate(
                width,
                height,
                frame_count,
                anim,
                direction,
                p.stat().st_mtime,
                referenced,
            )

            direction_part = direction or "unknown_dir"
            suggested = (
                CUSTODIAN
                / "assets/sprites/operator/runtime"
                / anim
                / f"operator_{anim}_{direction_part}.png"
            )

            out.append(
                Candidate(
                    path=rel,
                    inferred_animation=anim,
                    inferred_direction=direction,
                    width=width,
                    height=height,
                    frame_w=FRAME_W,
                    frame_h=FRAME_H,
                    frame_count=frame_count,
                    modified=datetime.fromtimestamp(p.stat().st_mtime).isoformat(
                        timespec="seconds"
                    ),
                    confidence=score,
                    flags=flags,
                    suggested_runtime_path=suggested.relative_to(ROOT).as_posix(),
                    already_referenced=referenced,
                )
            )

    return sorted(
        out,
        key=lambda c: (
            c.already_referenced,
            -c.confidence,
            c.inferred_animation,
            c.path,
        ),
    )


def group_status(candidates):
    groups = {}
    for c in candidates:
        if c.inferred_animation == "unknown":
            continue
        groups.setdefault(c.inferred_animation, set())
        if c.inferred_direction:
            groups[c.inferred_animation].add(c.inferred_direction)

    almost = []
    for anim, dirs in groups.items():
        missing = [d for d in EXPECTED_DIRECTIONS if d not in dirs]
        if 0 < len(missing) <= 2:
            almost.append(
                {
                    "animation": anim,
                    "present": sorted(dirs),
                    "missing": missing,
                }
            )
    return almost


def priority_list(candidates):
    unwired = [c for c in candidates if not c.already_referenced and c.confidence >= 60]
    by_anim = {
        c.inferred_animation: c for c in unwired if c.inferred_animation != "unknown"
    }
    result = []
    for anim in MISSION_CRITICAL:
        if anim in by_anim:
            result.append(
                {
                    "animation": anim,
                    "reason": "runtime-ready candidate exists and is mission-critical",
                    "example": by_anim[anim].path,
                }
            )
    return result


def main():
    candidates = collect_candidates()
    report = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "frame_assumption": f"{FRAME_W}x{FRAME_H}",
        "likely_runtime_ready_unwired": [
            asdict(c)
            for c in candidates
            if not c.already_referenced and c.confidence >= 60
        ],
        "possible_new_improved_or_review": [
            asdict(c)
            for c in candidates
            if c.confidence >= 50 and "RECENTLY_MODIFIED" in c.flags
        ],
        "almost_complete_groups": group_status(candidates),
        "noisy_or_invalid": [
            asdict(c)
            for c in candidates
            if c.confidence < 60 or "SIZE_NOT_DIVISIBLE_BY_96x96" in c.flags
        ],
        "minimal_runtime_priority": priority_list(candidates),
    }

    out_dir = ROOT / "reports"
    out_dir.mkdir(exist_ok=True)
    out_json = out_dir / "operator_animation_ingest_audit.json"
    out_md = out_dir / "operator_animation_ingest_audit.md"

    out_json.write_text(json.dumps(report, indent=2), encoding="utf-8")

    lines = ["# Operator Animation Ingest Audit", ""]
    for section in [
        "likely_runtime_ready_unwired",
        "possible_new_improved_or_review",
        "almost_complete_groups",
        "noisy_or_invalid",
        "minimal_runtime_priority",
    ]:
        lines += [f"## {section.replace('_', ' ').title()}", ""]
        items = report[section]
        if not items:
            lines += ["None.", ""]
            continue
        for item in items:
            lines += [f"- `{item.get('path', item.get('animation'))}`"]
            if "confidence" in item:
                lines += [f"  - confidence: {item['confidence']}"]
                lines += [
                    f"  - anim/dir: {item['inferred_animation']} / {item['inferred_direction']}"
                ]
                lines += [
                    f"  - size/frame_count: {item['width']}x{item['height']} / {item['frame_count']}"
                ]
                lines += [f"  - suggested: `{item['suggested_runtime_path']}`"]
                lines += [f"  - flags: {', '.join(item['flags']) or 'none'}"]
            else:
                lines += [f"  - {item}"]
        lines.append("")

    out_md.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out_json}")
    print(f"Wrote {out_md}")


if __name__ == "__main__":
    main()
