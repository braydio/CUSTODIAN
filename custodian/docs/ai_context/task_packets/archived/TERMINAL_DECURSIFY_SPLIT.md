# TERMINAL DECURSIFY SPLIT

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-04
- Created: 2026-05-04
- Last updated: 2026-05-04

## Task

Split the command terminal's mixed HUD logic into smaller Godot scripts and prepare the terminal UI surface for future PNG asset ingestion.

## Outcome

The active HUD terminal should keep its current scene layout and runtime behavior while delegating command routing, game-state snapshot aggregation, map preview rendering, and planet preview generation to dedicated modules.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`, `design/01_systems/TERMINAL_COMMAND_INTERFACE.md`
- Active runtime/docs files: `custodian/game/ui/hud/ui.gd`, new `custodian/game/ui/terminal/*` scripts, `custodian/docs/ai_context/*`
- Historical reference only: `python-sim/game/`, `python-sim/custodian-terminal/`

## Work Surface

- Files or folders expected to change: `custodian/game/ui/hud/ui.gd`, `custodian/game/ui/terminal/`, `custodian/content/ui/terminal/`, `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`, `custodian/docs/ai_context/*`
- Files or folders expected to be read but not changed: `custodian/scenes/game.tscn`, `custodian/docs/ai_context/VALIDATION_RECIPES.md`
- Out-of-scope areas: legacy Python terminal, wholesale `.tscn` rebuild, production art creation

## Constraints

- Determinism concerns: command execution can mutate runtime systems, but preview/rendering code must remain presentation-only.
- Simulation/UI boundary concerns: snapshot modules read runtime state; they must not become simulation authority.
- Asset requirements: add documented placeholder directories for terminal PNGs but do not invent production assets.
- Compatibility or migration concerns: preserve existing terminal node paths and command behavior during the split.
- Clarifying questions or assumptions: proceed with the existing HUD terminal as the active scene; deeper `.tscn`/Theme migration is a follow-up.

## Implementation Plan

1. Add terminal helper scripts for command routing, snapshots, map preview, and planet preview.
2. Wire `ui.gd` to instantiate/delegate to those helpers while preserving existing UI behavior.
3. Add terminal PNG asset intake placeholders and update active docs/context indexes.
4. Run Godot headless validation.

## Acceptance

- Runtime behavior: terminal opens, commands route through `TerminalCommandRouter`, local snapshots route through `TerminalSnapshot`, minimap rendering routes through `TerminalMapPreview`, and planet preview texture generation routes through `TerminalPlanetPreview`.
- Documentation: active terminal design and AI context docs identify the new modules and asset paths.
- Path/reference validation: new paths exist and are indexed.
- Manual validation: deferred unless headless validation exposes visual/runtime blockers.
- Automated/headless validation: `cd custodian && godot --headless --quit`

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Yes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes, terminal implementation spec.

## Completion Notes

- Implemented: Added terminal helper modules for command routing, snapshot aggregation, map preview state/click conversion, and planet preview state/input; wired the HUD terminal through those helpers; added `res://content/ui/terminal/README.md` for future PNG terminal assets; updated terminal design and AI context docs.
- Validated: `cd custodian && godot --headless --quit` completed with exit code 0.
- Deferred: Full page renderer extraction, full command-handler migration out of the legacy HUD method, `.tres` Theme/StyleBoxTexture migration, and production PNG art ingestion.

## Next Steps

- Next action: migrate page renderers and theme/style overrides into dedicated terminal resources.
- Best starting files: `custodian/game/ui/hud/ui.gd`, `custodian/game/ui/terminal/`
- Required context: terminal design spec and validation recipe.
- Validation to run: `cd custodian && godot --headless --quit`
- Blockers or open questions: none for this conservative split.
