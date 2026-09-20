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

#: Legacy action ids whose live body art has been promoted, byte-for-byte, into a
#: canonical semantic identity. A promotion preserves behaviour: same pixels, same
#: frame count, same clock. It is not an art change, which is why the newer
#: replacement candidates for these actions stay out of the cutover.
LEGACY_PROMOTIONS = {
    "legacy_operator_body_ranged_2h_reloading": {
        "canonical": "ranged_2h/cosmetic/reload_01/omni/full_body",
        "proof": "row 1 of the 384x192 sheet, which is exactly the region the live "
                 "clip slices (y=0, four 96x96 cells); verified pixel-identical to "
                 "the live clip frame for frame at 4f/10 FPS/non-loop. Row 2 is the "
                 "legacy rifle overlay and is deliberately not published: the target "
                 "is a static socketed carbine, not animated weapon SpriteFrames. "
                 "The 8-frame operator_ranged_body_core_v1 candidate is a post-R4 "
                 "art upgrade under this same identity, not part of preservation.",
    },
}

#: Authoring decisions that have been made. A promotion proves equivalence; these
#: do not, and must not be dressed up as proof. The pixels are deliberately
#: different, or the mechanism is deliberately going away. Recording them as
#: resolved decisions rather than reclassifying them keeps that distinction
#: legible after the cutover, when the legacy clip no longer exists to inspect.
#:
#:   REPLACE -- the clip's intent survives under a chosen canonical identity
#:   RETIRE  -- the clip, or the mechanism that reaches it, should disappear
#:
#: Retirements stay AUTHORING_DECISION rather than moving to RETIRED, because
#: RETIRED in this report is a mechanical finding ("no live consumer reaches
#: this clip"). These have live consumers; dropping them is a judgement call,
#: and collapsing the two would lose exactly the archaeology worth keeping.
RESOLVED_DECISIONS = {
    "idle_long": {
        "kind": "RETIRE",
        "why": "The legacy long-idle artwork is not wanted. No canonical replacement "
               "is authored and none should be; the idle path is unarmed/locomotion/idle_01.",
    },
    "idle_right": {
        "kind": "REPLACE",
        "resolution": "unarmed/locomotion/idle_01/e/full_body",
        "why": "Deliberate visual modernization. The canonical idle supersedes the legacy "
               "body idle; pixels differ on purpose.",
    },
    "run_right": {
        "kind": "REPLACE",
        "resolution": "unarmed/locomotion/run_01/e/full_body",
        "why": "Deliberate visual modernization of the legacy locomotion base.",
    },
    "walk_right": {
        "kind": "REPLACE",
        "resolution": "unarmed/locomotion/walk_01/e/full_body",
        "why": "Deliberate visual modernization of the legacy locomotion base.",
    },
    "walk_down_default": {
        "kind": "REPLACE",
        "resolution": "unarmed/locomotion/walk_01/s/full_body",
        "why": "Deliberate visual modernization of the legacy locomotion base; the "
               "'default' suffix was the old pipeline's name for the south strip.",
    },
    "death": {
        "kind": "REPLACE",
        "resolution": "unarmed/reaction/death_01/omni/full_body",
        "why": "Deliberate new-art replacement, not a pixel-preserving migration. The "
               "re-authored 8f @7 death supersedes the legacy 9f disintegrate, which retires.",
    },
    "melee_2h_fast_1_right": {
        "kind": "RETIRE",
        "why": "A legacy capability probe and runtime-mutation name, not a presentation "
               "identity. Fast-chain capability comes from weapon fast-chain data, not from "
               "has_animation() against the compatibility resource.",
    },
    "melee_2h_fast_2_right": {
        "kind": "RETIRE",
        "why": "Second link of the same legacy capability probe; retires with it.",
    },
    "melee_2h_fast_recovery": {
        "kind": "REPLACE",
        "resolution": "melee_1h_heavy/attack/fast_recovery_01/s/full_body",
        "why": "The canonical fast-recovery body action carries this presentation.",
    },
    "melee_2h_fast_right": {
        "kind": "RETIRE",
        "why": "An unreachable AttackFastState direct-play fallback. The Operator delegates "
               "through start_attack(), so this path never runs in the production actor.",
    },
    "melee_2h_heavy_anticipation": {
        "kind": "REPLACE",
        "resolution": "melee_1h_heavy/attack/heavy_windup_01/s/full_body",
        "why": "The canonical heavy-windup body action carries this presentation.",
    },
    "melee_2h_heavy": {
        "kind": "RETIRE",
        "why": "A generic legacy identity standing in for whatever heavy attack was active. "
               "Heavy presentation comes from semantic attack/profile authority instead: "
               "unarmed resolves unarmed/attack/heavy_01, armed resolves the active weapon "
               "profile's canonical heavy family. Creating a second canonical heavy identity "
               "to receive this name would reintroduce the ambiguity it encodes.",
    },
    "melee_2h_heavy_right": {
        "kind": "RETIRE",
        "why": "The directional spelling of the same generic legacy identity; retires with it "
               "rather than becoming a second canonical heavy action.",
    },
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


def literal_requests(source: str) -> tuple[set[str], set[str], set[str], set[str]]:
    bases = set(re.findall(r'AnimationResolver\.resolve\(\s*"([^"]+)"\s*,[^,]+,\s*animated_sprite', source))
    plays = set(re.findall(r'_animation_player\.play\(\s*animated_sprite\s*,\s*&?"([^"]+)"', source))
    probes = set(re.findall(r'animated_sprite\.sprite_frames\.has_animation\(\s*&?"([^"]+)"', source))
    # Names the actor hardcodes as the weapon-map fallback. These reach
    # animated_sprite through a variable, so the direct-literal patterns above
    # miss them entirely -- and the fallback is what actually ships whenever a
    # weapon definition supplies no animation_map entry, which is the case for
    # the carbine. Counting only the direct literals understated the live
    # surface, the same way it did in R1, R2 and R3.
    weapon_defaults = set(re.findall(
        r'_get_weapon_animation_name\([^()]*,\s*&"([^"]+)"\s*\)', source))
    return bases, plays, probes, weapon_defaults


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


def published_full_body_identities() -> set[str]:
    """Every full-body identity the canonical runtime spine actually publishes."""

    text = CANONICAL_TRES.read_text(encoding="utf-8")
    return {
        name for name in re.findall(r'"name": &"([^"]+)"', text)
        if name.endswith("/full_body")
    }


def main() -> int:
    source = ACTOR.read_text(encoding="utf-8")
    candidates = canonical_full_body()
    published_identities = published_full_body_identities()
    clips = json.loads(CLIPS.read_text(encoding="utf-8"))["clips"]
    baseline = json.loads(FULL_BODY_BASELINE.read_text(encoding="utf-8"))["identities"]

    bases, plays, probes, weapon_defaults = literal_requests(source)
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
    for clip in sorted(weapon_defaults):
        if clip in clips:
            live[clip].append(
                "hardcoded _get_weapon_animation_name fallback; ships whenever the "
                "weapon definition has no animation_map entry")
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
        elif legacy_art and info["art"].get("action") in LEGACY_PROMOTIONS:
            promotion = LEGACY_PROMOTIONS[info["art"]["action"]]
            identity = promotion["canonical"]
            disposition, why = "PROVEN_CANONICAL", (
                "promoted byte-for-byte into %s -- %s" % (identity, promotion["proof"]))
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
        decision = RESOLVED_DECISIONS.get(clip)
        decision_status = resolution = resolution_kind = None
        if disposition == "AUTHORING_DECISION":
            if decision is None:
                decision_status = "OPEN"
            else:
                decision_status = "RESOLVED"
                resolution_kind = decision["kind"]
                resolution = decision.get("resolution")
                why = decision["why"]
                if resolution is not None and resolution not in published_identities:
                    raise ValueError(
                        f"{clip} resolves to {resolution}, which is not published canonically"
                    )
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
                                     if decision_status == "OPEN" else [],
            "promoted": info["art"].get("action") in LEGACY_PROMOTIONS,
            "decision_status": decision_status,
            "resolution_kind": resolution_kind,
            "resolution": resolution,
        })

    counts: dict[str, int] = defaultdict(int)
    live_counts: dict[str, int] = defaultdict(int)
    for row in rows:
        counts[row["disposition"]] += 1
        if row["live"]:
            live_counts[row["disposition"]] += 1

    open_decisions = [r["clip"] for r in rows if r["decision_status"] == "OPEN"]
    unresolved = [r["clip"] for r in rows if r["disposition"] == "UNRESOLVED"]
    report = {
        "schema": "custodian.operator_animated_sprite_cutover_evidence.v1",
        "scope": "animated_sprite only; melee and weapon overlays are separate slices",
        "counts": dict(sorted(counts.items())),
        "live_counts": dict(sorted(live_counts.items())),
        "open_decisions": open_decisions,
        "unresolved": unresolved,
        "cutover_ready": not open_decisions and not unresolved,
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
              "id, so none has a canonical counterpart that evidence alone can establish.",
              "They are decisions, and they are recorded as decisions: a resolved decision is",
              "not the same claim as a proof of equivalence, and is deliberately not filed as",
              "`PROVEN_CANONICAL`. `REPLACE` chooses the canonical identity the intent moves",
              "to, with pixels that differ on purpose. `RETIRE` drops the clip or the",
              "mechanism that reaches it.", ""]
    resolved_rows = [r for r in rows if r["decision_status"] == "RESOLVED"]
    lines += [f"{len(resolved_rows)} resolved, {len(open_decisions)} open.", "",
              "| clip | legacy art | authored | decision | resolution |", "|---|---|---|---|---|"]
    for row in resolved_rows:
        art = row["art"]
        lines.append(f"| `{row['clip']}` | `{art.get('action','?')}` | "
                     f"{row['frames']}f @{row['authored_fps']} | {row['resolution_kind']} | "
                     f"{'`%s`' % row['resolution'] if row['resolution'] else 'no replacement'} |")
    lines += ["", "Rationale:", ""]
    for row in resolved_rows:
        lines.append(f"- `{row['clip']}` — {row['why']}")
    if open_decisions:
        lines += ["", "### Still open", "",
                  "| clip | legacy art | authored | candidates in profile |", "|---|---|---|---|"]
        for row in rows:
            if row["decision_status"] != "OPEN":
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
    print(f"  open decisions: {len(open_decisions)}   unresolved: {len(unresolved)}")
    print(f"  cutover ready: {report['cutover_ready']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
