# Terminal Input Focus Fix

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-27
- Created: 2026-05-27
- Last updated: 2026-05-27

## Task

Fix the in-game command terminal so the command line accepts normal typed input while preserving terminal history, autocomplete, focus, and preview interactions.

## Outcome

When the terminal is open and ready, letter/number/punctuation keys should reach the `LineEdit`; Up/Down should still recall history; Tab should still autocomplete; mouse clicks inside the terminal should keep focus on the command input.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`, `design/02_features/terminal/TERMINAL_PLANET_GLOBE_PREVIEW.md`
- Active runtime/docs files: `custodian/game/ui/hud/ui.gd`, `custodian/scenes/game.tscn`, `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: `custodian/game/ui/hud/ui.gd`, this task packet
- Files or folders expected to be read but not changed: `custodian/scenes/game.tscn`, terminal design docs, validation recipes
- Out-of-scope areas: terminal page rendering, command parser behavior, production terminal art

## Constraints

- Determinism concerns: none; this is UI event routing only.
- Simulation/UI boundary concerns: keep command entry in the HUD terminal and do not route text input into simulation systems directly.
- Asset requirements: none.
- Compatibility or migration concerns: preserve existing history recall and autocomplete behavior.
- Clarifying questions or assumptions: assume the reported symptom is normal typed characters not appearing in the in-game command line.

## Implementation Plan

1. Stop consuming ordinary key events in `TerminalInput`'s `gui_input` handler.
2. Continue accepting only terminal-owned special keys: Up, Down, and Tab.
3. Run headless Godot validation and record results.

## Acceptance

- Runtime behavior: normal typing reaches `TerminalInput`; Up/Down and Tab remain terminal shortcuts.
- Documentation: task packet records scope and validation.
- Path/reference validation: changed files exist under active runtime/context paths.
- Manual validation: playtest command typing if a GUI run is available.
- Automated/headless validation: `cd custodian && godot --headless --quit`

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? No; this is a bug fix to existing terminal behavior, not a new state/ownership change.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: Narrowed `_on_terminal_input_gui_input` so normal typed keys are no longer marked handled before `LineEdit` can insert text; retained terminal-owned handling for mouse focus, history Up/Down, and Tab autocomplete. Added a dedicated terminal input style with smaller vertical content margins and a taller minimum command-line field so accepted text is not clipped by the textured frame.
- Validated: `cd custodian && godot --headless --quit` completed with exit code 0 on 2026-05-27 after both input-routing and input-visibility changes.
- Deferred: Manual GUI typing confirmation is still recommended because headless validation cannot prove physical keyboard text entry behavior.

## Next Steps

- Next action: patch terminal input event handling.
- Best starting files: `custodian/game/ui/hud/ui.gd`
- Required context: `TerminalInput` signal setup and `_on_terminal_input_gui_input`.
- Validation to run: `cd custodian && godot --headless --quit`
- Blockers or open questions: GUI typing still needs manual confirmation after headless validation.
