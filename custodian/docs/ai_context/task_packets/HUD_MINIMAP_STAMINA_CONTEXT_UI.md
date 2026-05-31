# HUD MINIMAP STAMINA CONTEXT UI

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-30 06:31 EDT
- Created: 2026-05-30 06:31 EDT
- Last updated: 2026-05-30 06:34 EDT

## Task

Implement focused HUD usability updates: make the minimap toggleable on/off, move stamina to the top-left status stack above health and contract phase, and move context prompts to a centered but low-impact screen position.

## Outcome

The player can hide/show the minimap without losing the existing expand toggle. Stamina, health, and contract phase read as a compact top-left stack. Interaction/context prompts appear near mid-screen without dominating combat visibility.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: user request in current session
- Active runtime/docs files: `custodian/scenes/game.tscn`, `custodian/game/ui/hud/ui.gd`, `custodian/project.godot`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: HUD scene, HUD script, input map, this packet
- Files or folders expected to be read but not changed: minimap controller, UI context docs
- Out-of-scope areas: combat behavior, minimap rendering internals, terminal map preview

## Constraints

- Determinism concerns: none; UI-only behavior.
- Simulation/UI boundary concerns: keep input and visibility handling in HUD/UI surfaces.
- Asset requirements: none.
- Compatibility or migration concerns: preserve existing `M` minimap expand behavior.
- Clarifying questions or assumptions: bind minimap visibility to `N` unless an existing project convention says otherwise.

## Implementation Plan

1. Add minimap visibility input action and HUD handling.
2. Reposition stamina, health, contract phase, and adjacent HUD rows in the main game scene.
3. Reposition/style the interaction label as a centered, nonblocking context prompt.
4. Validate with headless Godot startup and focused diff checks.

## Acceptance

- Runtime behavior: minimap can be shown/hidden separately from expansion.
- Documentation: this packet records scope and validation.
- Path/reference validation: changed scene/script paths remain valid.
- Manual validation: review scene offsets and HUD input routing.
- Automated/headless validation: `godot --headless --quit`.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? No, unless this becomes durable control documentation.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: `N` minimap visibility toggle, preserved `M` minimap expand toggle, compact top-left stamina/health/contract stack, centered semi-transparent interaction prompt.
- Validated: `git diff --check` on changed files; `cd custodian && godot --headless --quit`.
- Deferred: no visual screenshot pass; layout was verified by scene offsets and headless scene load only.

## Next Steps

- Next action: optionally tune exact prompt vertical offset after in-game visual review.
- Best starting files: `custodian/game/ui/hud/ui.gd`, `custodian/scenes/game.tscn`, `custodian/project.godot`
- Required context: current HUD node names and minimap input actions.
- Validation to run: in-game check for preferred prompt placement.
- Blockers or open questions: none.
