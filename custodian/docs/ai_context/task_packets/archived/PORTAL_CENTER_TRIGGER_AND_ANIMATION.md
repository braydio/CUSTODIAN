# PORTAL CENTER TRIGGER AND ANIMATION

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-09
- Created: 2026-05-09
- Last updated: 2026-05-09

## Task

Tighten procgen portal teleport activation so only the portal center triggers teleport, not the surrounding stone frame, and define the animation assets needed for portal activation.

## Outcome

Portal teleport uses a small center trigger aligned to the `portal_ring_01` visual center. Animation asset needs are documented with exact save paths for follow-up art.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`
  - `custodian/game/world/procgen/portal_teleporter.gd`
  - `custodian/docs/ai_context/task_packets/README.md`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/content/props/ruins/data/prop_definitions/portal_ring_01.tres`
  - `custodian/content/props/ruins/extracted/portal_ring_01.png`
- Out-of-scope areas:
  - creating production portal animation art
  - cross-planet portal travel
  - full teleport VFX state machine

## Constraints

- Determinism concerns: trigger behavior remains physics-frame based.
- Simulation/UI boundary concerns: activation stays in world runtime.
- Asset requirements: user needs to provide portal center/activation animation sheets.
- Compatibility or migration concerns: existing portal prop art remains unchanged.
- Clarifying questions or assumptions: portal visual center is derived from the current `193x130` extracted PNG and `anchor_offset = Vector2(0, 65)`, so local center is approximately `Vector2(0, -65)`.

## Implementation Plan

1. Add a small trigger radius export on procgen portal wiring.
2. Move the portal trigger from the lower frame area to the portal visual center.
3. Validate scripts.
4. Provide exact animation asset list.

## Acceptance

- Runtime behavior: touching portal rocks alone should not teleport the player.
- Runtime behavior: entering the center of the portal teleports the player.
- Documentation: packet records asset request and validation.
- Automated/headless validation: targeted script checks pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? No broad runtime state change beyond the portal feature already listed.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Not for this tuning slice.

## Completion Notes

- Implemented: moved procgen portal teleport triggers to the portal visual center and reduced the default trigger radius to avoid activating from the surrounding stone frame.
- Validated: `godot --headless --check-only --script res://game/world/procgen/portal_teleporter.gd`; `godot --headless --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`.
- Deferred: production portal activation animation art and playback wiring.

## Next Steps

- Next action: provide portal animation assets and then wire visual playback.
- Best starting files: `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/game/world/procgen/proc_gen_tilemap.gd`
- Required context: `portal_ring_01` prop definition and current trigger center.
- Validation to run: targeted script checks, then in-editor portal walk-through test.
- Blockers or open questions: production portal activation art is not present yet.
