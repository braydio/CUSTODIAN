#!/usr/bin/env python3
"""Materialize authored compatibility timing into canonical Operator sidecars.

A renderer cutover replaces a compatibility ``SpriteFrames`` (which carries
hand-authored FPS, loop and per-frame durations) with the generated canonical
resource. Where the canonical source art has no ``.animation.json`` sidecar the
builder falls back to 12 FPS and a loop heuristic, so the cutover silently
retimes the animation. The Operator animation authority requires migration to
preserve frame durations, FPS and loop behavior, not only pixels.

This tool compares every compatibility clip against what the pipeline currently
generates for the identity that clip's *consumer* will request after cutover,
and writes the minimum set of timing sidecars needed to preserve the authored
clock. Dry-run by default.

Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

CUSTODIAN = Path(__file__).resolve().parents[3]
PROJECT_ROOT = CUSTODIAN.parent
sys.path.insert(0, str(CUSTODIAN / "tools/pipelines"))

from operator_asset_schema import is_legacy_action  # noqa: E402

DUMP = PROJECT_ROOT / "reports/operator/operator_compatibility_timing.json"
SOURCE_ROOT = CUSTODIAN / "content/sprites/operator/source/animations"
REPORT_JSON = PROJECT_ROOT / "reports/operator/operator_timing_preservation.json"
REPORT_MD = PROJECT_ROOT / "reports/operator/operator_timing_preservation.md"
TIMING_SCHEMA = "custodian.operator_animation_timing.v1"

#: The pipeline's clock hierarchy. The clock layer's timing is projected onto
#: every sibling layer with the same frame count, and takes precedence over that
#: sibling's own sidecar, so divergent siblings are inexpressible and must be
#: reported rather than silently flattened.
CLOCK_ORDER = ("lower_body", "full_body", "upper_body")

#: Compatibility clips whose pixels were published against the wrong action.
#: C2a-R3 repoints the consumer at the correct canonical art; the *consumer's*
#: authored clock stays the timing authority, so the correction moves timing to
#: the corrected identity rather than leaving it on the mis-published one.
CROSS_ACTION_CORRECTIONS = {
    ("modular_lower_body_sprite", "unarmed_walk_up_right"): ("unarmed", "locomotion", "walk_01", "ne"),
    ("modular_lower_body_sprite", "unarmed_walk_up_left"): ("unarmed", "locomotion", "walk_01", "nw"),
    ("modular_lower_body_sprite", "unarmed_run_up_right"): ("unarmed", "locomotion", "run_01", "ne"),
    ("modular_lower_body_sprite", "unarmed_fast_windup_lower_up"): ("unarmed", "attack", "fast_windup_01", "n"),
}

#: Renderers whose playback path explicitly normalizes speed, so a difference
#: between authored and generated FPS never reaches the screen for them.
#: `_play_first_available_modular_fire_animation` sets
#: `speed_scale = target_fps / source_speed`, and the ranged aim path derives FPS
#: from frame count over a tuned duration.
RUNTIME_NORMALIZED_ACTIONS = {
    ("ranged_2h", "cosmetic", "fire_01"),
    ("ranged_2h", "cosmetic", "aim_01"),
}


def _identity(profile: str, group: str, action: str, direction: str) -> str:
    return "/".join((profile, group, action, direction))


def _source_png(profile: str, group: str, action: str, direction: str,
                layer: str, frames: int, size: str) -> Path:
    name = f"operator__{layer}__{profile}__{group}__{action}__{direction}__{frames}f__{size}.png"
    return SOURCE_ROOT / profile / group / action / name


def _find_source_png(profile: str, group: str, action: str, direction: str,
                     layer: str) -> Path | None:
    folder = SOURCE_ROOT / profile / group / action
    if not folder.is_dir():
        return None
    prefix = f"operator__{layer}__{profile}__{group}__{action}__{direction}__"
    matches = sorted(p for p in folder.glob("*.png") if p.name.startswith(prefix))
    return matches[0] if len(matches) == 1 else (matches[0] if matches else None)


def collect(dump: dict) -> tuple[dict, list[dict]]:
    """Group authored compatibility timing by the canonical identity+layer it feeds."""
    observations: dict[tuple[str, str], list[dict]] = defaultdict(list)
    skipped: list[dict] = []
    for renderer, payload in dump["resources"].items():
        for clip, info in payload["clips"].items():
            art = info.get("art") or {}
            if not art:
                skipped.append({"renderer": renderer, "clip": clip, "why": "no atlas provenance"})
                continue
            profile, group = art["profile"], art["group"]
            action, direction = art["action"], art["direction"]
            layer = art["layer"]
            corrected = CROSS_ACTION_CORRECTIONS.get((renderer, clip))
            if corrected is not None:
                profile, group, action, direction = corrected
            if is_legacy_action(action):
                skipped.append({
                    "renderer": renderer, "clip": clip,
                    "why": f"legacy action {action} has no canonical publication",
                })
                continue
            observations[(_identity(profile, group, action, direction), layer)].append({
                "renderer": renderer,
                "clip": clip,
                "frames": info["frames"],
                "fps": round(float(info["fps"]), 4),
                "loop": bool(info["loop"]),
                "durations": [round(float(d), 4) for d in info["durations"]],
                "corrected": corrected is not None,
            })
    return observations, skipped


def classify(observations: dict, canonical: dict) -> list[dict]:
    rows: list[dict] = []
    for (identity, layer), entries in sorted(observations.items()):
        canonical_name = f"{identity}/{layer}"
        generated = canonical.get(canonical_name)
        distinct = {(e["fps"], e["loop"], tuple(e["durations"])) for e in entries}
        profile, group, action, direction = identity.split("/")
        row = {
            "identity": identity,
            "layer": layer,
            "canonical_animation": canonical_name,
            "consumers": entries,
            "authored": None,
            "generated": None,
            "classification": None,
        }
        if generated is None:
            row["classification"] = "NOT_PUBLISHED"
            rows.append(row)
            continue
        row["generated"] = {
            "fps": round(float(generated["fps"]), 4),
            "loop": bool(generated["loop"]),
            "durations": [round(float(d), 4) for d in generated["durations"]],
            "frames": generated["frames"],
        }
        if len(distinct) > 1:
            row["classification"] = "CONFLICT"
            rows.append(row)
            continue
        fps, loop, durations = next(iter(distinct))
        row["authored"] = {"fps": fps, "loop": loop, "durations": list(durations),
                           "frames": entries[0]["frames"]}
        if entries[0]["frames"] != generated["frames"]:
            row["classification"] = "FRAME_COUNT_MISMATCH"
        elif (fps, loop, list(durations)) == (
            row["generated"]["fps"], row["generated"]["loop"], row["generated"]["durations"]
        ):
            row["classification"] = "MATCH"
        elif (profile, group, action) in RUNTIME_NORMALIZED_ACTIONS:
            row["classification"] = "NORMALIZED_BY_RUNTIME_EXPLICITLY"
        else:
            row["classification"] = "NEEDS_TIMING_SIDECAR"
        if any(e["corrected"] for e in entries) and row["classification"] != "CONFLICT":
            row["semantic_mapping_corrected"] = True
        rows.append(row)
    return rows


def plan_sidecars(rows: list[dict]) -> tuple[list[dict], list[dict]]:
    """Choose the minimum authoritative sidecars, honoring the pipeline clock rule."""
    by_identity: dict[str, dict[str, dict]] = defaultdict(dict)
    for row in rows:
        by_identity[row["identity"]][row["layer"]] = row

    plan: list[dict] = []
    inexpressible: list[dict] = []
    covered: list[dict] = []
    for identity, layers in sorted(by_identity.items()):
        clock_layer = next((name for name in CLOCK_ORDER if name in layers), None)
        needed = {name: row for name, row in layers.items()
                  if row["classification"] in {"NEEDS_TIMING_SIDECAR", "FRAME_COUNT_MISMATCH"}}
        if not needed:
            continue
        for layer, row in sorted(needed.items()):
            if row["authored"] is None:
                continue
            # The clock layer's timing overrides a sibling's own sidecar whenever
            # their frame counts match, so a sibling that needs *different*
            # timing at the same frame count cannot be expressed by this pipeline.
            if (clock_layer is not None and layer != clock_layer
                    and clock_layer in layers
                    and layers[clock_layer]["authored"] is not None
                    and layers[clock_layer]["authored"]["frames"] == row["authored"]["frames"]
                    and layers[clock_layer]["authored"] != row["authored"]):
                inexpressible.append({
                    "identity": identity, "layer": layer, "clock_layer": clock_layer,
                    "clock_authored": layers[clock_layer]["authored"],
                    "layer_authored": row["authored"],
                })
                continue
            # Minimality: the clock layer's sidecar already projects onto every
            # sibling with the same frame count, so an identical sibling sidecar
            # would be redundant duplication of the same authority.
            if (clock_layer is not None and layer != clock_layer
                    and clock_layer in needed
                    and layers[clock_layer]["authored"] == row["authored"]):
                covered.append({"identity": identity, "layer": layer,
                                "covered_by": clock_layer})
                continue
            profile, group, action, direction = identity.split("/")
            png = _find_source_png(profile, group, action, direction, layer)
            plan.append({
                "identity": identity,
                "layer": layer,
                "is_clock_layer": layer == clock_layer,
                "source_png": png.relative_to(PROJECT_ROOT).as_posix() if png else None,
                "sidecar": (png.with_suffix("").with_suffix(".animation.json")
                            .relative_to(PROJECT_ROOT).as_posix()) if png else None,
                "authored": row["authored"],
                "generated": row["generated"],
            })
    return plan, inexpressible, covered


def clock_projection_gaps(plan: list[dict], canonical: dict) -> list[dict]:
    """Layers a planned clock sidecar will NOT reach, because the pipeline only
    projects the clock onto siblings whose frame count matches.

    These keep whatever the builder already generates, so they are not a T1
    regression -- but they are exactly the layers a later renderer cutover
    (notably `animated_sprite`, which owns `full_body`) has to publish for
    itself."""
    gaps: list[dict] = []
    for item in plan:
        frames = item["authored"]["frames"]
        for layer in ("lower_body", "upper_body", "full_body", "weapon", "fx"):
            if layer == item["layer"]:
                continue
            entry = canonical.get(f"{item['identity']}/{layer}")
            if entry is None or entry["frames"] == frames:
                continue
            gaps.append({
                "identity": item["identity"], "layer": layer,
                "clock_layer": item["layer"], "clock_frames": frames,
                "layer_frames": entry["frames"],
                "keeps_generated_fps": round(float(entry["fps"]), 4),
            })
    return gaps


def write_sidecars(plan: list[dict], apply: bool) -> dict:
    created, updated, unchanged, refused = [], [], [], []
    for item in plan:
        if item["sidecar"] is None:
            refused.append({**item, "why": "no canonical source PNG for this layer"})
            continue
        path = PROJECT_ROOT / item["sidecar"]
        payload = {
            "schema": TIMING_SCHEMA,
            "frames": item["authored"]["frames"],
            "fps": item["authored"]["fps"],
            "loop": item["authored"]["loop"],
            "durations": item["authored"]["durations"],
        }
        if path.exists():
            existing = json.loads(path.read_text(encoding="utf-8"))
            comparable = {k: existing.get(k) for k in ("schema", "frames", "fps", "loop", "durations")}
            if comparable == payload:
                unchanged.append(item["sidecar"])
                continue
            refused.append({**item, "why": f"existing sidecar differs: {comparable}"})
            continue
        if apply:
            path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        created.append(item["sidecar"])
    return {"created": created, "updated": updated, "unchanged": unchanged, "refused": refused}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write sidecars (default: dry run)")
    parser.add_argument("--dump", type=Path, default=DUMP)
    args = parser.parse_args(argv)

    dump = json.loads(args.dump.read_text(encoding="utf-8"))
    observations, skipped = collect(dump)
    rows = classify(observations, dump["canonical"])
    plan, inexpressible, covered = plan_sidecars(rows)
    gaps = clock_projection_gaps(plan, dump["canonical"])

    counts: dict[str, int] = defaultdict(int)
    for row in rows:
        counts[row["classification"]] += 1

    conflicts = [r for r in rows if r["classification"] == "CONFLICT"]
    result = write_sidecars(plan, args.apply and not conflicts and not inexpressible)

    report = {
        "schema": "custodian.operator_timing_preservation.v1",
        "counts": dict(sorted(counts.items())),
        "sidecar_plan": plan,
        "inexpressible_sibling_timing": inexpressible,
        "covered_by_clock_projection": covered,
        "clock_projection_gaps": gaps,
        "conflicts": conflicts,
        "skipped": skipped,
        "write_result": result,
        "applied": bool(args.apply and not conflicts and not inexpressible),
        "rows": rows,
    }
    REPORT_JSON.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    lines = ["# Operator timing preservation", "",
             "Authored compatibility timing versus what the canonical pipeline generates.", ""]
    for key in sorted(counts):
        lines.append(f"- {key}: {counts[key]}")
    lines += ["", f"Sidecars planned: {len(plan)}", f"Conflicts: {len(conflicts)}",
              f"Inexpressible sibling timing: {len(inexpressible)}", ""]
    if plan:
        lines += ["## Planned sidecars", "",
                  "| identity | layer | clock | authored | generated |", "|---|---|---|---|---|"]
        for item in sorted(plan, key=lambda i: (i["identity"], i["layer"])):
            a, g = item["authored"], item["generated"]
            lines.append(
                f"| `{item['identity']}` | {item['layer']} | {'yes' if item['is_clock_layer'] else 'no'} "
                f"| {a['fps']} fps loop={a['loop']} | {g['fps']} fps loop={g['loop']} |")
    REPORT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print("operator timing preservation")
    for key in sorted(counts):
        print(f"  {key:38} {counts[key]}")
    print(f"  {'sidecars planned':38} {len(plan)}")
    print(f"  {'covered by clock projection':38} {len(covered)}")
    print(f"  {'clock projection gaps (later slices)':38} {len(gaps)}")
    print(f"  {'conflicts':38} {len(conflicts)}")
    print(f"  {'inexpressible sibling timing':38} {len(inexpressible)}")
    print(f"  {'refused':38} {len(result['refused'])}")
    if args.apply and (conflicts or inexpressible):
        print("REFUSED to write: resolve conflicts and inexpressible timing first")
        return 1
    print(f"{'wrote' if report['applied'] else 'dry run; would write'} {len(result['created'])} sidecars")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
