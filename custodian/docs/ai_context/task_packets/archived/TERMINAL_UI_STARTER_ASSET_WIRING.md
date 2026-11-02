# Terminal UI Starter Asset Wiring

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-19
- Created: 2026-05-19
- Last updated: 2026-05-19

## Task

Wire the starter terminal UI resource assets under `custodian/content/ui/terminal/` into the live Godot terminal interface.

## Outcome

The terminal keeps its existing layout and command behavior, but uses the starter PNG resource set for panel frames, header bars, navigation tabs, command-line input, action buttons, overlays, and terminal page/action icons.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/`
- Active runtime/docs files: `custodian/game/ui/hud/ui.gd`, `custodian/content/ui/terminal/README.md`, `custodian/docs/ai_context/CURRENT_STATE.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/game/ui/hud/ui.gd`, this task packet, `custodian/docs/ai_context/CURRENT_STATE.md`
- Files or folders expected to be read but not changed: `custodian/content/ui/terminal/`, `custodian/scenes/game.tscn`
- Out-of-scope areas: terminal command semantics, simulation state, production art creation

## Constraints

- Determinism concerns: none; this is UI presentation only.
- Simulation/UI boundary concerns: do not move terminal command or snapshot authority into asset styling code.
- Asset requirements: use existing starter PNGs; do not invent missing production art.
- Compatibility or migration concerns: keep the current scene node paths and dynamic fabrication tab.
- Clarifying questions or assumptions: assume the provided starter assets are ready for runtime skinning through `StyleBoxTexture` and button icons.

## Implementation Plan

1. Add terminal asset preloads and small style/icon helper functions to `ui.gd`.
2. Replace the terminal flat stylebox wiring with starter asset-backed 9-slice styles.
3. Re-apply asset styles when terminal page theme changes so fabrication mode does not revert to flat panels.
4. Update AI context and validate with Godot headless checks.

## Acceptance

- Runtime behavior: terminal opens, page tabs/actions still work, and no command routing changes are introduced.
- Documentation: packet and current state mention terminal starter asset wiring.
- Path/reference validation: asset paths are preloaded from `res://content/ui/terminal/...`.
- Manual validation: not required for this side task unless headless checks expose UI setup errors.
- Automated/headless validation: run a narrow Godot syntax/script check and project boot/import check as feasible.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No new behavior; runtime presentation only.

## Completion Notes

- Implemented: wired starter terminal PNG resources into the live HUD terminal theme via asset preloads, `StyleBoxTexture` helpers, terminal overlays, tab/action button skins, command-line frame, map/panel frames, and page/action icons. Follow-up visual tuning lowered scanline/noise opacity, added a dark whole-terminal backing layer, tuned nav/action 9-slice margins to `10px`, dimmed dense panel frames, capped compact summary body heights, and lowered inactive nav icon contrast.
- Validated: `godot --headless --path custodian --check-only --script res://game/ui/hud/ui.gd`; `godot --headless --path custodian --quit`; `git diff --check` on touched files.
- Deferred: visual in-editor/playtest pass for final spacing, opacity, and icon choices.

## Next Steps

- Next action: review the terminal visually in-game and tune overlay opacity/icon choices if needed.
- Best starting files: `custodian/game/ui/hud/ui.gd`, `custodian/content/ui/terminal/README.md`
- Required context: existing terminal theme hooks and starter asset paths.
- Validation to run: optional in-editor visual pass.
- Blockers or open questions: none.
