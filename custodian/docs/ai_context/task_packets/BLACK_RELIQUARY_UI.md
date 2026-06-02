# BLACK RELIQUARY UI TASK PACKET

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-06-02
- Created: 2026-06-02
- Last updated: 2026-06-02

## Task

Implement the extracted Black Reliquary UI kit as the current CUSTODIAN gothic/brass HUD style for the active Godot runtime, centered on reusable theme/catalog/components and Sundered Keep prompt/status integration.

## Outcome

Sundered Keep uses a local reusable `CustodianHUD` scene with Black Reliquary panels, prompt plaque, minimap frame, status plaques, and clean in-world text. Runtime UI art loads from `res://content/ui/black_reliquary/`, prompt text stays as Godot labels, and missing art falls back without crashing.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/20_features/in_progress/BLACK_RELIQUARY_UI.md`
- Active runtime/docs files: `custodian/game/ui/`, `custodian/game/world/sundered_keep/sundered_keep_map.gd`, `custodian/docs/ai_context/*`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/game/ui/theme/`, `custodian/game/ui/components/`, `custodian/game/ui/hud/custodian_hud.*`, `custodian/game/world/sundered_keep/sundered_keep_map.gd`, `custodian/tools/validation/black_reliquary_ui_smoke.gd`, active design/docs context files.
- Files or folders expected to be read but not changed: `custodian/content/ui/black_reliquary/`, existing terminal HUD/minimap files, Sundered Keep assets/validation.
- Out-of-scope areas: legacy Python runtime, production asset renames, full global HUD replacement outside Sundered Keep.

## Constraints

- Determinism concerns: UI must not own or mutate simulation state except explicit interaction calls already owned by Sundered Keep.
- Simulation/UI boundary concerns: HUD reads operator/status state and renders prompts; gate/key/siege state remains in `sundered_keep_map.gd`.
- Asset requirements: use existing extracted Black Reliquary PNGs; support `prompt/` and `prompts/`.
- Compatibility or migration concerns: keep local HUD easy to replace with a global HUD instance later.
- Clarifying questions or assumptions: assume a local Sundered Keep HUD is acceptable because no global Black Reliquary HUD pattern exists yet.

## Implementation Plan

1. Add palette, style helpers, and centralized asset catalog.
2. Add reusable panel, icon label, prompt, minimap frame, and HUD scenes/scripts.
3. Wire Sundered Keep interaction/key/gate/siege state into the HUD API and hide normal world-space debug text.
4. Add a Black Reliquary smoke validation script and update active docs/context.
5. Run requested asset and Godot validation commands.

## Acceptance

- Runtime behavior: Sundered Keep return mooring, main gate, key pickup, and gate status use the new HUD prompt/status APIs.
- Documentation: design doc and AI context pack describe Black Reliquary UI ownership and usage.
- Path/reference validation: required UI asset paths and scenes resolve.
- Manual validation: local HUD scene layout is readable and fallback-safe.
- Automated/headless validation: `black_reliquary_ui_smoke.gd` and existing Sundered Keep smoke pass when Godot is available.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Yes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, add Black Reliquary UI implementation spec.

## Completion Notes

- Implemented: Added Black Reliquary palette/styles/catalog, reusable panel/icon-label/prompt/minimap components, `CustodianHUD`, Sundered Keep local HUD integration, prompt mapping, fallback-safe asset loading, imported Black Reliquary PNG sidecars, and UI smoke coverage.
- Validated: Asset find/Python required-path check, targeted Godot script checks for the new HUD and Sundered Keep map, `res://tools/validation/black_reliquary_ui_smoke.gd`, and Godot import.
- Deferred: Full global replacement of the command-terminal HUD remains outside this slice; Sundered Keep owns a local HUD instance until a global gameplay HUD pattern is introduced.

## Next Steps

- Next action: Review in-game visual placement in a normal Godot run.
- Best starting files: `custodian/game/world/sundered_keep/sundered_keep_map.gd`, `custodian/game/ui/`.
- Required context: `custodian/content/ui/black_reliquary/` asset listing and game32 panel metadata.
- Validation to run: `cd custodian && godot` for manual visual QA.
- Blockers or open questions: None.
