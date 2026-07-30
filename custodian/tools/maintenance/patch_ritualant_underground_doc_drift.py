#!/usr/bin/env python3
"""One-time, idempotent documentation drift patch for the Ritualant migration."""

from __future__ import annotations

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]


def read(path: str) -> str:
    return (REPO_ROOT / path).read_text(encoding="utf-8")


def write(path: str, text: str) -> None:
    (REPO_ROOT / path).write_text(text, encoding="utf-8")


def replace_once(path: str, old: str, new: str) -> bool:
    text = read(path)
    if new in text:
        return False
    if old not in text:
        raise RuntimeError(f"Expected drift anchor not found in {path}")
    write(path, text.replace(old, new, 1))
    return True


def patch_current_state() -> bool:
    path = "custodian/docs/ai_context/CURRENT_STATE.md"
    text = read(path)
    changed = False

    if "Last updated: 2026-07-29" in text:
        text = text.replace("Last updated: 2026-07-29", "Last updated: 2026-07-30", 1)
        changed = True

    old_status = """- The Ash-Bell Forlorn-Ritualant remains a partial encounter foundation, not a
  finished encounter. Its current authority-reservation packet is complete only
  for the procgen footprint claim slice. Live presentation uses south-facing
  128×128 `AnimatedSprite2D` sheets for idle/rise/pin/thread actions, but
  directional locomotion, robust action-state timing, the full attack and
  resolution set, authored silence/audio, persistent rewards, and production
  death/dissolve presentation remain open. `REQUIRED_ASSETS.md` now records
  those live partial contracts instead of the stale 48×64 ColorRect claim.
"""
    new_status = """- The Ash-Bell Forlorn-Ritualant remains a partial encounter foundation, not a
  finished encounter. Its room authority is now a fixed authored Underground
  destination registered as `forlorn_ritualant_underground`; procgen places only
  the exterior cave ingress and no longer inserts, clears, reserves, or reports
  the `35x27` chamber as a special room. The authored `1120x864` wrapper instances
  the existing encounter scene, enters at `Spawn_DescentLanding`, and returns to
  world origin through `return_world`. Live presentation still uses south-facing
  128×128 `AnimatedSprite2D` sheets for idle/rise/pin/thread actions, while
  directional locomotion, robust action-state timing, the full attack and
  resolution set, authored silence/audio, persistent rewards, and production
  death/dissolve presentation remain open.
"""
    if new_status not in text:
        if old_status not in text:
            raise RuntimeError(f"Expected Ritualant status anchor not found in {path}")
        text = text.replace(old_status, new_status, 1)
        changed = True

    runtime_pattern = re.compile(
        r"- The Ash-Bell / Forlorn-Ritualant encounter now has a first authored runtime module.*?"
        r"(?=\n- A Godot-native procedural ruin prop variant foundation)",
        re.DOTALL,
    )
    runtime_replacement = """- The Ash-Bell / Forlorn-Ritualant encounter has a fixed authored Underground
  runtime destination at
  `res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn`.
  Its registered route uses a generated-world cave ingress, enters the named
  `Spawn_DescentLanding`, instances the existing
  `res://game/world/events/ash_bell/forlorn_ritualant_site.tscn`, and exfils through
  `return_world`. The former
  `res://content/procgen/special_rooms/ash_bell_forlorn_ritualant_room.json`
  definition is deleted; `SpecialRoomRuntimeInserter` no longer owns this encounter.
  Manual visual review remains in
  `res://scenes/debug/forlorn_ritualant_site_debug.tscn`, and focused migration
  validation lives at
  `res://tools/validation/levels/forlorn_ritualant_underground_smoke.gd`.
"""
    if runtime_replacement not in text:
        text, count = runtime_pattern.subn(runtime_replacement.rstrip(), text, count=1)
        if count != 1:
            raise RuntimeError(f"Expected long Ritualant runtime anchor not found in {path}")
        changed = True

    old_workflow = (
        "- The Ash-Bell / Forlorn-Ritualant packet is "
        "`custodian/docs/ai_context/task_packets/ASH_BELL_FORLORN_RITUALANT.md`; "
        "its next implementation lane is production asset wiring plus generic "
        "special-room insertion using the live authored-footprint claim API."
    )
    new_workflow = (
        "- The Ash-Bell / Forlorn-Ritualant packet is "
        "`custodian/docs/ai_context/task_packets/ASH_BELL_FORLORN_RITUALANT.md`; "
        "the procgen special-room lane is retired. Its next implementation lane is "
        "the authored cave/lift/lower-landing sequence plus production encounter assets."
    )
    if new_workflow not in text:
        if old_workflow not in text:
            raise RuntimeError(f"Expected Ritualant workflow anchor not found in {path}")
        text = text.replace(old_workflow, new_workflow, 1)
        changed = True

    if changed:
        write(path, text)
    return changed


def patch_file_index() -> bool:
    path = "custodian/docs/ai_context/FILE_INDEX.md"
    text = read(path)
    changed = False
    if "Last updated: 2026-07-26" in text:
        text = text.replace("Last updated: 2026-07-26", "Last updated: 2026-07-30", 1)
        changed = True

    old = (
        "- `custodian/docs/ai_context/task_packets/ASH_BELL_FORLORN_RITUALANT.md` — "
        "packet for the first authored Ash-Bell / Forlorn-Ritualant event implementation "
        "slice and deferred production asset/procgen integration work"
    )
    new = """- `custodian/docs/ai_context/task_packets/ASH_BELL_FORLORN_RITUALANT.md` — completed authority-migration packet for moving the encounter from procgen special-room insertion into a fixed authored Underground route
- `design/05_levels/FORLORN_RITUALANT_UNDERGROUND_MIGRATION.md` — active authority decision, spatial contract, runtime paths, and validation commands for the Underground migration
- `custodian/game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn` — authored `1120x864` Underground wrapper that instances the existing Ritualant encounter scene
- `custodian/content/levels/ash_bell/forlorn_ritualant_underground.json` — registered level definition and lifecycle
- `custodian/content/routes/ash_bell/forlorn_ritualant_underground_route.json` — generated-world cave ingress, ritual-cavern node, and world exfil route
- `custodian/tools/validation/levels/forlorn_ritualant_underground_smoke.gd` — focused migration, spawn, scene-instance, exit, and registry validation"""
    if new not in text:
        if old not in text:
            raise RuntimeError(f"Expected Ritualant index anchor not found in {path}")
        text = text.replace(old, new, 1)
        changed = True

    if changed:
        write(path, text)
    return changed


def patch_detailed_spec() -> bool:
    path = "design/02_features/enemy_objective/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md"
    text = read(path)
    banner = """> **Placement authority update — 2026-07-30:** This document remains encounter-content guidance, but its procgen-room placement language is superseded by `design/05_levels/FORLORN_RITUALANT_UNDERGROUND_MIGRATION.md`. The encounter now lives in a fixed authored Underground route; procgen places only the exterior cave ingress.

"""
    if banner in text:
        return False
    anchor = "Below is a **game scene implementation spec**"
    if not text.startswith(anchor):
        raise RuntimeError(f"Expected detailed-spec opening anchor not found in {path}")
    write(path, banner + text)
    return True


def main() -> int:
    changed = []
    for label, patcher in (
        ("CURRENT_STATE.md", patch_current_state),
        ("FILE_INDEX.md", patch_file_index),
        ("FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md", patch_detailed_spec),
    ):
        if patcher():
            changed.append(label)
    if changed:
        print("Patched: " + ", ".join(changed))
    else:
        print("No changes required; Ritualant documentation drift is already patched.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
