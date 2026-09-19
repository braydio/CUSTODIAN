#!/usr/bin/env python3
"""C2a-R4 evidence: what `animated_sprite` actually plays, and what it would become.

The compatibility resource carries 135 clips, but existing there does not mean a
clip is live. This walks the consumer graph in `operator.gd` instead, expands each
request through `AnimationResolver`'s real resolution order, and reports the clips
those consumers can actually reach.

Scope is `animated_sprite` alone. The melee and weapon overlays are still
compatibility renderers and belong to their own later slices.

Authority: design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md
"""

from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

CUSTODIAN = Path(__file__).resolve().parents[3]
PROJECT_ROOT = CUSTODIAN.parent
ACTOR = CUSTODIAN / "game/actors/operator/operator.gd"
#: `_animation_state_machine.sprite = animated_sprite`, so every name a state
#: plays through the state machine is a live request against this renderer. The
#: actor file alone does not see them, and a clip reached only from here would be
#: wrongly reported as dead residue.
STATES = CUSTODIAN / "game/actors/operator/animations/states"
CLIPS = PROJECT_ROOT / "reports/operator/operator_animated_sprite_clips.json"
FULL_BODY_BASELINE = PROJECT_ROOT / "reports/operator/operator_full_body_compatibility_timing.json"
OUT_JSON = PROJECT_ROOT / "reports/operator/operator_animated_sprite_cutover_evidence.json"
OUT_MD = PROJECT_ROOT / "reports/operator/operator_animated_sprite_cutover_evidence.md"
CANONICAL_TRES = CUSTODIAN / "content/sprites/operator/runtime/operator_runtime_frames.tres"

#: AnimationResolver's suffixes, in the order it tries them.
SUFFIXES = ("up", "up_right", "right", "down_right", "down", "down_left", "left", "up_left")

#: Bases reached through a variable, traced to the literals their callers pass.
#: Recorded here rather than guessed, with the call path that proves each one.
TRACED_BASES = {
    "unarmed_parry": "_play_parry_animation via guard controller parry windup",
    "unarmed_parry_success": "_play_parry_animation via parry contact success",
    "unarmed_parry_success_01": "_play_parry_animation via guard_enter_post_parry_neutral",
    "unarmed_block_enter": "_play_block_animation phase key",
    "unarmed_block_hold": "_play_block_animation phase key",
    "unarmed_block_hitreact": "_play_block_animation phase key",
    "unarmed_block_exit": "_play_block_animation phase key",
}

#: Requests whose base comes from a resource field rather than a literal. The
#: clip cannot be enumerated statically; the data authority is the proof source.
DATA_DRIVEN_BASES = {
    "_get_weapon_animation_name(...unarmed_light_hitreact...)":
        "OperatorWeaponDefinition animation_map; the damage-reaction base is a "
        "weapon-definition field, not a literal in the actor",
    "_get_authored_melee_body_stance_animation()":
        "melee posture resolver / weapon definition; the stance base is authored "
        "per weapon rather than named in the actor",
}

#: Consumers outside the actor that read this renderer's animation name or frame.
EXTERNAL_CONSUMERS = {
    "instant_replay_recorder.gd": {
        "kind": "observability",
        "detail": "captures `sprite.animation` and restores it on playback. In-memory "
                  "only with no checked-in fixtures, so it round-trips whatever names "
                  "are live; a replay captured before a cutover cannot be restored after one.",
    },
    "animation_state_machine.gd": {
        "kind": "presentation",
        "detail": "`current_animation()` returns `sprite.animation` and "
                  "`is_animation_playing(name)` compares it. The comparison helper has "
                  "zero callers, so no gameplay state keys off the clip name today.",
    },
    "hit_recoil_state.gd": {
        "kind": "gameplay-semantic",
        "detail": "detects reaction completion by comparing `sprite.animation` against "
                  "the name it played. Survives renaming only because both sides move "
                  "together; it must keep comparing the same string the state played.",
    },
    "operator_presentation_rig_2d.gd": {
        "kind": "presentation",
        "detail": "mirrors `animated.animation = source_animated.animation` onto a preview "
                  "rig, so the rig needs the same SpriteFrames the source renderer uses.",
    },
    "operator.gd::_apply_knight_test_skin_if_requested": {
        "kind": "observability",
        "detail": "swaps `animated_sprite.sprite_frames` for a debug Knight skin built "
                  "under legacy clip names, caching the production resource to restore. "
                  "After canonicalization the skin's own names no longer match what "
                  "consumers request, so the debug skin needs its own disposition.",
    },
}


def literal_requests(source: str) -> tuple[set[str], set[str], set[str]]:
    bases = set(re.findall(r'AnimationResolver\.resolve\(\s*"([^"]+)"\s*,[^,]+,\s*animated_sprite', source))
    plays = set(re.findall(r'_animation_player\.play\(\s*animated_sprite\s*,\s*&?"([^"]+)"', source))
    probes = set(re.findall(r'animated_sprite\.sprite_frames\.has_animation\(\s*&?"([^"]+)"', source))
    return bases, plays, probes


def reachable(base: str, clips: dict) -> list[str]:
    """Clips `AnimationResolver.resolve(base, ...)` can return, over all directions."""
    hits = []
    for suffix in SUFFIXES:
        candidate = f"{base}_{suffix}"
        if candidate in clips and clips[candidate]["frames"] > 0:
            hits.append(candidate)
    for fallback in (f"{base}_left", f"{base}_right", base):
        if fallback in clips and clips[fallback]["frames"] > 0 and fallback not in hits:
            hits.append(fallback)
    return hits


def canonical_full_body() -> dict[str, set[str]]:
    """Published canonical full-body actions, grouped by profile.

    Grouped by PROFILE rather than profile/group on purpose: the legacy baked
    strips were filed under whatever group the old pipeline used, so
    `legacy_walking_base` sits in `unarmed/cosmetic` while its obvious semantic
    home is `unarmed/locomotion`. Offering only same-group candidates would hide
    the real counterpart.
    """
    text = CANONICAL_TRES.read_text(encoding="utf-8")
    by_profile: dict[str, set[str]] = defaultdict(set)
    for name in re.findall(r'"name": &"([^"]+)"', text):
        parts = name.split("/")
        if len(parts) == 5 and parts[4] == "full_body" and "legacy" not in parts[2]:
            by_profile[parts[0]].add(f"{parts[1]}/{parts[2]}")
    return by_profile


def main() -> int:
    source = ACTOR.read_text(encoding="utf-8")
    candidates = canonical_full_body()
    clips = json.loads(CLIPS.read_text(encoding="utf-8"))["clips"]
    baseline = json.loads(FULL_BODY_BASELINE.read_text(encoding="utf-8"))["identities"]

    bases, plays, probes = literal_requests(source)
    state_plays: dict[str, str] = {}
    for path in sorted(STATES.glob("*.gd")):
        text = path.read_text(encoding="utf-8")
        for name in re.findall(r'play_animation\(\s*&"([a-z0-9_]+)"', text):
            state_plays[name] = path.name
        for name in re.findall(r'can_play_animation\(\s*&"([a-z0-9_]+)"', text):
            state_plays.setdefault(name, path.name)
    requests: dict[str, str] = {}
    for base in sorted(bases):
        requests[base] = "literal base in operator.gd"
    for base, why in TRACED_BASES.items():
        requests.setdefault(base, why)

    live: dict[str, list[str]] = defaultdict(list)
    for base, why in requests.items():
        for clip in reachable(base, clips):
            live[clip].append(f"resolver base `{base}` ({why})")
    for clip in sorted(plays):
        if clip in clips:
            live[clip].append("played directly by name")
    for clip in sorted(probes):
        if clip in clips:
            live[clip].append("guarded by a has_animation probe")
    for clip, origin in sorted(state_plays.items()):
        if clip in clips:
            live[clip].append(f"played by {origin} through the animation state machine")

    rows = []
    for clip in sorted(clips):
        info = clips[clip]
        consumers = live.get(clip, [])
        identity = info["canonical_identity"]
        published = info["canonical_published"]
        legacy_art = "legacy" in identity
        timing = baseline.get(identity)
        if not consumers:
            disposition, why = "RETIRED", "no live consumer reaches this clip"
        elif legacy_art:
            disposition, why = "AUTHORING_DECISION", (
                "draws art published only under a legacy action id; it has no canonical "
                "identity to migrate to without an authoring decision")
        elif not identity:
            disposition, why = "UNRESOLVED", "no atlas provenance; the art it draws is unknown"
        elif not published:
            disposition, why = "UNRESOLVED", f"art maps to {identity}, which is not published canonically"
        else:
            disposition, why = "PROVEN_CANONICAL", "art provenance maps to a published canonical identity"
        rows.append({
            "clip": clip,
            "consumers": consumers,
            "live": bool(consumers),
            "frames": info["frames"],
            "authored_fps": info["fps"],
            "authored_loop": info["loop"],
            "art": info["art"],
            "canonical_identity": identity,
            "canonical_published": published,
            "timing_preserved": bool(timing) and not timing.get("unpreservable"),
            "disposition": disposition,
            "why": why,
            "canonical_candidates": sorted(candidates.get(info["art"].get("profile", ""), []))
                                     if disposition == "AUTHORING_DECISION" else [],
        })

    counts: dict[str, int] = defaultdict(int)
    live_counts: dict[str, int] = defaultdict(int)
    for row in rows:
        counts[row["disposition"]] += 1
        if row["live"]:
            live_counts[row["disposition"]] += 1

    report = {
        "schema": "custodian.operator_animated_sprite_cutover_evidence.v1",
        "scope": "animated_sprite only; melee and weapon overlays are separate slices",
        "counts": dict(sorted(counts.items())),
        "live_counts": dict(sorted(live_counts.items())),
        "data_driven_bases": DATA_DRIVEN_BASES,
        "external_consumers": EXTERNAL_CONSUMERS,
        "rows": rows,
    }
    OUT_JSON.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    lines = ["# Operator `animated_sprite` cutover evidence", "",
             "Scope is `animated_sprite` alone. The melee and weapon overlays remain",
             "compatibility renderers and belong to their own later slices.", "",
             f"{len(rows)} clips in the compatibility resource; "
             f"{sum(1 for r in rows if r['live'])} are reachable by a live consumer.", "",
             "| disposition | all clips | live only |", "|---|---|---|"]
    for key in sorted(counts):
        lines.append(f"| {key} | {counts[key]} | {live_counts.get(key, 0)} |")
    lines += ["", "## Live clips", "",
              "| clip | canonical identity | published | timing | disposition |", "|---|---|---|---|---|"]
    for row in rows:
        if not row["live"]:
            continue
        lines.append(f"| `{row['clip']}` | `{row['canonical_identity'] or '-'}` | "
                     f"{'yes' if row['canonical_published'] else 'NO'} | "
                     f"{'preserved' if row['timing_preserved'] else '-'} | {row['disposition']} |")
    lines += ["", "## Authoring decisions", "",
              "Each of these is a live clip drawing art published only under a legacy action",
              "id. The reachability contract covers canonical entries only, so none of them",
              "carry a recorded status; candidates are published full-body actions in the",
              "same profile, listed across groups because the legacy strips were filed by",
              "the old pipeline's grouping rather than their semantics.", "",
              "| clip | legacy art | authored | candidates in profile |", "|---|---|---|---|"]
    for row in rows:
        if row["disposition"] != "AUTHORING_DECISION" or not row["live"]:
            continue
        art = row["art"]
        lines.append(f"| `{row['clip']}` | `{art.get('action','?')}` | "
                     f"{row['frames']}f @{row['authored_fps']} | "
                     f"{', '.join('`%s`' % c for c in row['canonical_candidates']) or '-'} |")
    lines += ["", "## Data-driven bases", ""]
    for name, why in DATA_DRIVEN_BASES.items():
        lines.append(f"- `{name}` — {why}")
    lines += ["", "## External name/frame consumers", ""]
    for name, info in EXTERNAL_CONSUMERS.items():
        lines.append(f"- `{name}` ({info['kind']}) — {info['detail']}")
    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print("operator animated_sprite cutover evidence")
    print(f"  clips: {len(rows)}   live: {sum(1 for r in rows if r['live'])}")
    for key in sorted(counts):
        print(f"  {key:22} {counts[key]:4}  (live {live_counts.get(key, 0)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
