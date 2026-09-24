#!/usr/bin/env python3
"""Characterize armed-melee compatibility SpriteFrames against canonical identities.

C2b discovered that `_install_weapon_body_frames()` copies a weapon's
`body_frames_resource` animations *into* the canonical
`operator_runtime_frames.tres` object at equip time, so legacy names really are
playable at runtime and the compatibility tail of `_play_melee_anim_resolved()`
could not simply be deleted.

Removing that mutation means proving, per weapon/link/layer, what the
compatibility resource actually plays -- texture, atlas region, frame count, FPS,
loop and per-frame durations -- and which canonical identity carries the same
thing. Animation *names* are not evidence; the migration already has two
documented cases of a name implying the wrong art.

This emits migration evidence only. Nothing in the runtime reads it.

Authority: design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

CUSTODIAN_ROOT = Path(__file__).resolve().parents[3]
PROJECT_ROOT = CUSTODIAN_ROOT.parent
OPERATOR_DIR = CUSTODIAN_ROOT / "game/actors/operator"
RUNTIME_FRAMES = CUSTODIAN_ROOT / "content/sprites/operator/runtime/operator_runtime_frames.tres"
REPORT = PROJECT_ROOT / "reports/operator/operator_armed_melee_canonicalization.json"

SCHEMA = "custodian.operator_armed_melee_canonicalization.v1"

# Classifications, most-preserved first.
EXACT = "EXACT"
SAME_PIXELS_DIFFERENT_TIMING = "SAME_PIXELS_DIFFERENT_TIMING"
PRESERVED_SUBRANGE = "PRESERVED_SUBRANGE"
NO_CANONICAL_EQUIVALENT = "NO_CANONICAL_EQUIVALENT"


def parse_spriteframes(path: Path) -> dict:
    """Return {animation_name: {fps, loop, frames: [{texture, region, duration}]}}.

    Godot `.tres` is a flat INI-ish format: ext_resources are textures,
    sub_resources are AtlasTextures naming an ext_resource plus a region, and the
    SpriteFrames `animations` array references the sub_resources in order.
    """
    text = path.read_text(encoding="utf-8", errors="ignore")

    ext: dict[str, str] = {}
    for m in re.finditer(r'\[ext_resource type="Texture2D"[^\]]*?path="([^"]+)"[^\]]*?id="([^"]+)"\]', text):
        ext[m.group(2)] = m.group(1)

    atlas: dict[str, dict] = {}
    for m in re.finditer(
        r'\[sub_resource type="AtlasTexture" id="([^"]+)"\]\s*\n'
        r'atlas = ExtResource\("([^"]+)"\)\s*\n'
        r'region = Rect2\(([^)]*)\)',
        text,
    ):
        nums = [float(v.strip()) for v in m.group(3).split(",")]
        atlas[m.group(1)] = {
            "texture": ext.get(m.group(2), "?"),
            "region": [int(round(v)) for v in nums],
        }

    animations: dict[str, dict] = {}
    # Each animation block runs from a "frames": [ up to its "speed": value.
    for block in re.finditer(
        r'"frames": \[(.*?)\],\s*"loop": (\w+),\s*"name": &"([^"]+)",\s*"speed": ([0-9.]+)',
        text,
        re.S,
    ):
        frames_raw, loop_raw, name, speed = block.groups()
        frames = []
        for f in re.finditer(r'"duration": ([0-9.]+),\s*"texture": SubResource\("([^"]+)"\)', frames_raw):
            entry = atlas.get(f.group(2), {"texture": "?", "region": None})
            frames.append({
                "texture": entry["texture"],
                "region": entry["region"],
                "duration": float(f.group(1)),
            })
        animations[name] = {
            "fps": float(speed),
            "loop": loop_raw not in ("0", "false", "False"),
            "frames": frames,
        }
    return animations


def _visible_bytes(crop) -> bytes:
    """RGBA bytes with the RGB of fully transparent pixels zeroed.

    The source and published strips for Vigil fast_01/fast_02 are identical
    everywhere a player can see and differ in the RGB channels of 450 fully
    transparent pixels, which is PNG encoder choice, not art. Hashing raw bytes
    calls those strips different; hashing what actually renders calls them the
    same. (`ImageChops.difference().getbbox()` also calls them identical, because
    `getbbox()` keys on alpha for RGBA -- convenient here, and misleading in
    general, so this is explicit instead.)
    """
    raw = bytearray(crop.tobytes())
    for i in range(0, len(raw), 4):
        if raw[i + 3] == 0:
            raw[i] = raw[i + 1] = raw[i + 2] = 0
    return bytes(raw)


_PIXEL_CACHE: dict[tuple, str] = {}


def _res_to_path(res_path: str) -> Path:
    return CUSTODIAN_ROOT / res_path.removeprefix("res://")


def frame_pixels(anim: dict) -> list[str]:
    """The pixel identity of an animation: an ordered hash per frame.

    Hashing decoded pixels rather than comparing `(texture, region)` pairs is the
    whole point. The compatibility resources cite the *source* strip under
    `content/sprites/weapons/<id>/source/.../legacy_*`, while the canonical
    database cites the *published* strip under `.../runtime/.../attack/<action>`.
    Those are different files with different PNG encodings and therefore different
    bytes -- and, for Vigil fast_01/fast_02, identical pixels. A path comparison
    reports those as unrelated art, which is exactly the kind of name-shaped
    evidence this migration has already been burned by twice.
    """
    from PIL import Image

    out: list[str] = []
    for f in anim["frames"]:
        if not f["region"] or f["texture"] == "?":
            out.append("?")
            continue
        key = (f["texture"], tuple(f["region"]))
        cached = _PIXEL_CACHE.get(key)
        if cached is None:
            path = _res_to_path(f["texture"])
            if not path.exists():
                cached = "missing:%s" % f["texture"]
            else:
                x, y, w, h = f["region"]
                with Image.open(path) as im:
                    # `.crop()` is lazy; `.copy()` materializes the region so
                    # `tobytes()` hashes the crop and not the parent image.
                    crop = im.convert("RGBA").crop((x, y, x + w, y + h)).copy()
                    cached = hashlib.sha256(_visible_bytes(crop)).hexdigest()
            _PIXEL_CACHE[key] = cached
        out.append(cached)
    return out


def classify(legacy: dict, canonical: dict) -> tuple[str, str]:
    """Compare a compatibility animation with a canonical one. Returns (class, note)."""
    lp, cp = frame_pixels(legacy), frame_pixels(canonical)
    same_timing = (
        abs(legacy["fps"] - canonical["fps"]) < 1e-6
        and legacy["loop"] == canonical["loop"]
        and [f["duration"] for f in legacy["frames"]] == [f["duration"] for f in canonical["frames"]]
    )
    if lp == cp:
        if same_timing:
            return EXACT, "identical pixels and timing"
        return SAME_PIXELS_DIFFERENT_TIMING, (
            "same %d frames; legacy %.6g fps vs canonical %.6g fps; durations %s vs %s"
            % (
                len(lp), legacy["fps"], canonical["fps"],
                [f["duration"] for f in legacy["frames"]],
                [f["duration"] for f in canonical["frames"]],
            )
        )
    if lp and cp and len(lp) < len(cp) and cp[: len(lp)] == lp:
        return PRESERVED_SUBRANGE, (
            "legacy plays the first %d of %d canonical frames at %.6g fps (canonical %.6g); "
            "legacy durations %s"
            % (len(lp), len(cp), legacy["fps"], canonical["fps"],
               [f["duration"] for f in legacy["frames"]])
        )
    return NO_CANONICAL_EQUIVALENT, (
        "legacy %d frames vs canonical %d; pixel sequences differ" % (len(lp), len(cp))
    )


# Which compatibility resource holds each layer, per weapon.
WEAPONS = {
    "vigil_pattern_dagger": {
        "animation_profile": "melee_1h_dagger",
        "weapon_type": "melee_1h",
        "layers": {
            "full_body": "vigil_pattern_dagger_body_frames.tres",
            "weapon": "vigil_pattern_dagger_melee_overlay_frames.tres",
            "fx": "vigil_pattern_dagger_fx_frames.tres",
        },
        "legacy_names": {
            "full_body": "vigil_dagger_{action}_{side}",
            "weapon": "vigil_dagger_{action}_weapon_{side}",
            "fx": "vigil_dagger_{action}_fx_{side}",
        },
    },
    "sword_cleaver": {
        "animation_profile": "melee_1h_heavy",
        "weapon_type": "melee_1h_heavy",
        "layers": {
            "full_body": "sword_cleaver_body_frames.tres",
            "weapon": "sword_cleaver_weapon_overlay_frames.tres",
            "fx": "sword_cleaver_fx_frames.tres",
        },
        "legacy_names": {
            "full_body": "sword_cleaver_{action}_{side}",
            "weapon": "sword_cleaver_{action}_weapon_{side}",
            "fx": "sword_cleaver_{action}_fx_{side}",
        },
    },
}

ACTIONS = ["fast_01", "fast_02", "fast_03"]
SIDES = {"right": "e", "left": "w"}


# The generic family every armed profile historically borrowed body/FX art from.
GENERIC_FAMILY = "melee_1h"


def canonical_candidates(weapon_id: str, spec: dict, layer: str, action: str, sector: str) -> list[str]:
    """Every identity worth comparing against, most specific first.

    The generic `melee_1h` family is included even for `melee_1h_heavy` weapons
    because that is where the compatibility resources actually point: the Sword
    Cleaver's body and FX resources cite `melee_1h` strips, not `melee_1h_heavy`
    ones. Leaving it out reported all eighteen Cleaver entries as having no
    canonical equivalent, which was an artifact of only asking about the family
    the weapon *should* use.
    """
    identities = [
        "weapon/%s/%s/attack/%s/%s/%s" % (weapon_id, spec["animation_profile"], action, sector, layer),
        "%s/attack/%s/%s/%s" % (spec["weapon_type"], action, sector, layer),
    ]
    generic = "%s/attack/%s/%s/%s" % (GENERIC_FAMILY, action, sector, layer)
    if generic not in identities:
        identities.append(generic)
    return identities


def migration_target(weapon_id: str, spec: dict, layer: str, action: str, sector: str) -> str:
    """The identity this layer will play after canonicalization.

    The semantic contract, not the best pixel match: the weapon layer is owned by
    the weapon, body and FX come from the weapon's own `weapon_type` family.
    """
    if layer == "weapon":
        return "weapon/%s/%s/attack/%s/%s/%s" % (
            weapon_id, spec["animation_profile"], action, sector, layer
        )
    return "%s/attack/%s/%s/%s" % (spec["weapon_type"], action, sector, layer)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--print", action="store_true", help="also print a human summary")
    args = parser.parse_args(argv)

    canonical = parse_spriteframes(RUNTIME_FRAMES)
    entries = []

    for weapon_id, spec in WEAPONS.items():
        for layer, resource_name in spec["layers"].items():
            resource = OPERATOR_DIR / resource_name
            if not resource.exists():
                entries.append({
                    "weapon_id": weapon_id, "layer": layer, "action": None, "sector": None,
                    "legacy_resource": resource_name, "legacy_animation": None,
                    "canonical_identity": None, "classification": "RESOURCE_ABSENT",
                    "note": "compatibility resource no longer on disk",
                })
                continue
            legacy_anims = parse_spriteframes(resource)
            for action in ACTIONS:
                for side, sector in SIDES.items():
                    legacy_name = spec["legacy_names"][layer].format(action=action.replace("fast_0", "fast_0"), side=side)
                    # Legacy names use the weapon's own action spelling.
                    legacy_name = legacy_name.replace("fast_0", "fast_0")
                    if legacy_name not in legacy_anims:
                        continue
                    legacy = legacy_anims[legacy_name]
                    target = migration_target(weapon_id, spec, layer, action, sector)
                    candidates = []
                    for candidate in canonical_candidates(weapon_id, spec, layer, action, sector):
                        if candidate not in canonical:
                            candidates.append({
                                "canonical_identity": candidate,
                                "classification": "IDENTITY_ABSENT",
                                "note": "not published in the canonical database",
                            })
                            continue
                        klass, note = classify(legacy, canonical[candidate])
                        candidates.append({
                            "canonical_identity": candidate,
                            "canonical_frames": len(canonical[candidate]["frames"]),
                            "canonical_fps": canonical[candidate]["fps"],
                            "canonical_durations": [f["duration"] for f in canonical[candidate]["frames"]],
                            "classification": klass,
                            "note": note,
                            "is_migration_target": candidate == target,
                        })
                    order = {EXACT: 0, SAME_PIXELS_DIFFERENT_TIMING: 1,
                             PRESERVED_SUBRANGE: 2, NO_CANONICAL_EQUIVALENT: 3,
                             "IDENTITY_ABSENT": 4}
                    best = min(candidates, key=lambda c: order.get(c["classification"], 9))
                    chosen = next(
                        (c for c in candidates if c.get("is_migration_target")),
                        None,
                    )
                    entries.append({
                        "weapon_id": weapon_id,
                        "layer": layer,
                        "action": action,
                        "sector": sector,
                        "legacy_resource": resource_name,
                        "legacy_animation": legacy_name,
                        "legacy_frames": len(legacy["frames"]),
                        "legacy_fps": legacy["fps"],
                        "legacy_loop": legacy["loop"],
                        "legacy_durations": [f["duration"] for f in legacy["frames"]],
                        "legacy_textures": sorted({f["texture"] for f in legacy["frames"]}),
                        "migration_target": target,
                        "classification": (chosen or best)["classification"],
                        "note": (chosen or best)["note"],
                        "best_available_match": best["canonical_identity"],
                        "best_available_classification": best["classification"],
                        "candidates": candidates,
                    })

    summary: dict[str, int] = {}
    for e in entries:
        summary[e["classification"]] = summary.get(e["classification"], 0) + 1

    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps({
        "schema": SCHEMA,
        "canonical_database": str(RUNTIME_FRAMES.relative_to(PROJECT_ROOT)),
        "summary": summary,
        "entries": entries,
    }, indent=2) + "\n", encoding="utf-8")

    print("wrote %s" % REPORT.relative_to(PROJECT_ROOT))
    for k in (EXACT, SAME_PIXELS_DIFFERENT_TIMING, PRESERVED_SUBRANGE, NO_CANONICAL_EQUIVALENT):
        if k in summary:
            print("  %-30s %d" % (k, summary[k]))
    for k, v in sorted(summary.items()):
        if k not in (EXACT, SAME_PIXELS_DIFFERENT_TIMING, PRESERVED_SUBRANGE, NO_CANONICAL_EQUIVALENT):
            print("  %-30s %d" % (k, v))

    if args.print:
        for e in entries:
            if e["classification"] == EXACT:
                continue
            print("\n%s %s %s/%s" % (e["weapon_id"], e["layer"], e["action"], e["sector"]))
            print("  legacy    %s" % e["legacy_animation"])
            print("  canonical %s" % e["canonical_identity"])
            print("  %s: %s" % (e["classification"], e["note"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
