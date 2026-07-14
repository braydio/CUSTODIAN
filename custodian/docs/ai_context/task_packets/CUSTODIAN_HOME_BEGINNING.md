# CUSTODIAN Home Beginning Task Packet

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-02
- Created: 2026-06-02
- Last updated: 2026-06-02

## Task

Move `design/CUSTODIAN_BEGINS.md` into a durable Home design document and implement the first playable beginning slice where the Custodian traces a degraded Custodian-band frequency to a Field Terminal and establishes witness contact.

## Outcome

The Home beginning has an active design home, a Godot scene/runtime script, Black Reliquary HUD presentation, a reusable field-terminal interactable, validation coverage, and required production asset asks recorded without touching legacy Python runtime.

## Authority

- Root routing: `/home/braydenchaffee/Projects/CUSTODIAN/AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/03_architecture/HOME_CUSTODIAN_FIELD_TERMINAL.md`, `design/03_architecture/HUB_DOCTRINE.md`, `design/03_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md`
- Active runtime/docs files: `custodian/game/world/home/`, `custodian/scenes/home_custodian_begin.tscn`, `custodian/game/ui/hud/custodian_hud.gd`, `custodian/docs/ai_context/*`
- Historical reference only: legacy Python runtime

## Work Surface

- Files or folders expected to change: `design/03_architecture/`, `custodian/game/world/home/`, `custodian/scenes/`, `custodian/tools/validation/`, `custodian/docs/ai_context/`, `REQUIRED_ASSETS.md`
- Files or folders expected to be read but not changed: existing hub prototype, command terminal, operator, camera, and HUD components
- Out-of-scope areas: legacy Python runtime, contract/procgen scene ownership, final production art/audio generation

## Constraints

- Determinism concerns: the slice is authored and distance-driven; no nondeterministic gameplay state is introduced.
- Simulation/UI boundary concerns: objective text, prompts, and signal status are HUD/UI presentation; no simulation authority is moved into UI.
- Asset requirements: existing Road of Witnesses map and command-terminal compatibility art are used; bespoke Field Terminal, signal FX/audio, and terminal-chamber dressing remain production asset needs.
- Compatibility or migration concerns: `res://scenes/game.tscn` remains the active main scene; the Home beginning is a dedicated scene for integration into boot flow later.
- Clarifying questions or assumptions: `design/CUSTODIAN_BEGIN.md` was a typo for `design/CUSTODIAN_BEGINS.md`; “move it to a home document” means a canonical Home/Field Terminal design document under `design/03_architecture/`.

## Implementation Plan

1. Move and revise the beginning design into a Home document.
2. Add Home beginning runtime scene, controller, and Field Terminal interactable using existing art fallbacks.
3. Extend the reusable Black Reliquary HUD only where needed for generic Home status/location rows.
4. Add smoke validation and update AI context plus required asset trackers.
5. Run focused Godot validation.

## Acceptance

- Runtime behavior: Home beginning scene loads, shows Road of Witnesses, operator, Field Terminal, Black Reliquary HUD, distance-based signal objective state, and witness interaction.
- Documentation: design and AI context docs point to the new Home beginning surface.
- Path/reference validation: moved design path is indexed and old root path is no longer canonical.
- Manual validation: code inspection confirms no legacy Python edits.
- Automated/headless validation: `res://tools/validation/custodian_home_begin_smoke.gd` passes.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Yes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, moved Home design doc.

## Completion Notes

- Implemented: moved the design source to `design/03_architecture/HOME_CUSTODIAN_FIELD_TERMINAL.md`; added `home_custodian_begin.tscn`, `CustodianHomeBegin`, and `FieldTerminalInteractable`; extended `CustodianHUD` with generic location/status APIs; added Home smoke validation; updated required asset trackers and AI context docs.
- Validated: `cd custodian && godot --headless --script res://tools/validation/custodian_home_begin_smoke.gd`; `cd custodian && godot --headless --check-only --script res://game/world/home/custodian_home_begin.gd`; `cd custodian && godot --headless --check-only --script res://game/world/home/field_terminal_interactable.gd`; `cd custodian && godot --headless --check-only --script res://game/ui/hud/custodian_hud.gd`; `cd custodian && godot --headless --script res://tools/validation/black_reliquary_ui_smoke.gd`; required asset copies compared with `cmp`.
- Deferred: production Field Terminal art, signal audio/FX, terminal-chamber environmental dressing, and boot-flow promotion.

## Next Steps

- Next action: decide when to promote `home_custodian_begin.tscn` into boot/default flow.
- Best starting files: `custodian/scenes/home_custodian_begin.tscn`, `custodian/game/world/home/custodian_home_begin.gd`
- Required context: Home beginning doc and Black Reliquary HUD API.
- Validation to run: rerun `cd custodian && godot --headless --script res://tools/validation/custodian_home_begin_smoke.gd` after any Home scene, Field Terminal, or HUD API edit.
- Blockers or open questions: none for the V1 slice.
