# PORTAL FX PLAYBACK WIRING

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-09
- Created: 2026-05-09
- Last updated: 2026-05-09

## Task

Wire the ingested portal teleport FX sheets into runtime portal behavior.

## Outcome

Each paired procgen portal now builds one runtime `PortalStateSprite` from the ingested portal sheets: idle loops continuously, activation replaces idle at the source portal, teleport resolves on activation frame 10 by default, and arrival replaces idle at the destination portal before returning to idle so the full sequence reads for about 2 seconds.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active runtime/docs files: `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/content/sprites/effects/runtime/portal_ring/`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/docs/ai_context/*`, this packet.
- Files or folders expected to be read but not changed: `custodian/content/sprites/effects/runtime/portal_ring/`.
- Out-of-scope areas: moving attack animation composition and cross-planet portal transition.

## Constraints

- Determinism concerns: teleport authority remains physics-frame/collision based; FX playback is presentation only.
- Simulation/UI boundary concerns: FX is owned by the portal world component, not HUD/UI.
- Asset requirements: uses current `161x98` portal FX strips.
- Compatibility or migration concerns: no scene resource dependency was added; frames are built at runtime from PNG strips.
- Clarifying questions or assumptions: teleport should be delayed until activation frame 10 and the destination arrival FX should stay visible for the remaining sequence buffer.

## Completion Notes

- Implemented: `PortalTeleporter` now creates one `PortalStateSprite`, loads the portal idle/activate/arrival runtime strips, loops idle, plays activation at source, delays the actual teleport until activation frame 10, extends the player cooldown through the sequence buffer, and holds arrival playback at the destination for the remaining sequence time before returning to idle.
- Validated: `godot --headless --check-only --script res://game/world/procgen/portal_teleporter.gd`; `godot --headless --check-only --script res://game/world/procgen/proc_gen_tilemap.gd`.
- Deferred: in-editor tuning for FX z-index, frame rate, center alignment, and whether teleport should wait for an activation frame.

## Next Steps

- Next action: playtest portal entry in editor and tune `portal_trigger_radius`, `portal_trigger_local_offset`, FX frame rates, and arrival offset.
- Best starting files: `custodian/game/world/procgen/portal_teleporter.gd`, `custodian/game/world/procgen/proc_gen_tilemap.gd`
- Required context: current portal prop anchor and `effects/runtime/portal_ring/` sheets.
- Validation to run: `cd custodian && godot`, enter a generated portal, confirm idle/activate/arrival playback.
- Blockers or open questions: none.
