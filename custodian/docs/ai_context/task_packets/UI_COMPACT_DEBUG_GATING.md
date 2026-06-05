# UI Compact Debug Gating Task Packet

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-03
- Created: 2026-06-03
- Last updated: 2026-06-03

## Task

Reduce blocking normal-play HUD footprint and move unformatted/debug runtime text to debug-only visibility.

## Outcome

Normal gameplay uses compact vitals/objective/prompt UI. Diagnostic camera/phase/director/power/weapon/ammo/cooldown controls are hidden unless debug HUD is explicitly enabled.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/20_features/in_progress/BLACK_RELIQUARY_UI.md`, `design/03_architecture/HOME_CUSTODIAN_FIELD_TERMINAL.md`
- Active runtime/docs files: `custodian/game/ui/hud/`, `custodian/scenes/game.tscn`, `custodian/docs/ai_context/*`
- Historical reference only: legacy Python runtime

## Work Surface

- Files or folders expected to change: `custodian/game/ui/hud/custodian_hud.tscn`, `custodian/game/ui/hud/custodian_hud.gd`, `custodian/game/ui/hud/ui.gd`, AI context docs.
- Files or folders expected to be read but not changed: Sundered Keep/Home HUD consumers and existing validation scripts.
- Out-of-scope areas: final visual QA screenshots, global HUD replacement, legacy Python runtime.

## Constraints

- Determinism concerns: UI visibility/presentation only.
- Simulation/UI boundary concerns: no gameplay state should move into UI.
- Asset requirements: no new assets required.
- Compatibility or migration concerns: keep existing HUD APIs used by Sundered Keep and Home.
- Clarifying questions or assumptions: "debug screen only" means old diagnostic HUD text remains available through the existing debug HUD toggle/F12/dev-console path but is hidden in normal play.

## Implementation Plan

1. Make Black Reliquary vitals a slim header-style strip instead of a large panel.
2. Reduce normal-play panel footprint for objective, minimap, prompts, and status plaque.
3. Gate legacy main-HUD diagnostic containers and labels behind `_debug_hud_visible`.
4. Update docs/task packet and run focused Godot validation.

## Acceptance

- Runtime behavior: normal HUD no longer shows large vitals panel or unformatted diagnostic labels.
- Documentation: AI context notes the compact/debug-gated HUD direction.
- Path/reference validation: HUD scenes and scripts load.
- Manual validation: code inspection confirms debug nodes are hidden unless `_debug_hud_visible` is true.
- Automated/headless validation: Black Reliquary UI smoke and touched scripts pass.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Yes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes, packet index entry added.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, Black Reliquary UI behavior rules now call out compact vitals and debug gating.

## Completion Notes

- Implemented: compacted Black Reliquary vitals/objective/minimap/prompt/status surfaces, reduced prompt/minimap component minimum sizes, shortened vitals copy, moved legacy diagnostic HUD containers behind the debug HUD toggle, and kept Home witness-contact archive copy out of the HUD debug overlay.
- Validated: touched HUD scripts check-only, Black Reliquary UI smoke, Home beginning smoke, and Sundered Keep asset smoke.
- Deferred: final in-editor visual screenshot pass.

## Next Steps

- Next action: in-editor visual pass for final pixel tuning.
- Best starting files: `custodian/game/ui/hud/custodian_hud.tscn`, `custodian/game/ui/hud/ui.gd`
- Required context: Black Reliquary HUD and legacy command-terminal HUD visibility logic.
- Validation to run: optional visual/manual check in the Godot editor; rerun `cd custodian && godot --headless --script res://tools/validation/black_reliquary_ui_smoke.gd` after future HUD edits.
- Blockers or open questions: none.
