# TERMINAL NAMING NORMALIZATION

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-10
- Created: 2026-05-10
- Last updated: 2026-05-10

## Task

Normalize terminal prop naming across active docs and sprite pipeline guidance so `command_terminal` is canonical and `fabricator_terminal` is reserved for the future distinct prop sprite family.

## Outcome

Active docs and sprite pipeline guidance refer to `command_terminal` as the current prop family, with `fabricator_terminal` documented as the future split and `computer_terminal` left only as compatibility language where needed.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/terminal/COMMAND_TERMINAL_SPEC.md`
- Active runtime/docs files: `custodian/docs/ASSET_LAYOUT_CONVENTION.md`, `custodian/docs/TERMINAL_VIEW_LOCAL_MODE.md`, `custodian/content/sprites/_pipeline/README.md`, `custodian/content/sprites/README.md`, `custodian/content/ui/terminal/README.md`
- Historical reference only: legacy `computer_terminal` naming

## Work Surface

- Files or folders expected to change: terminal asset docs, sprite pipeline README, terminal local-mode doc
- Files or folders expected to be read but not changed: runtime scripts already wired to support the rename
- Out-of-scope areas: renaming legacy import files or rewriting art assets during this doc sweep

## Constraints

- Determinism concerns: none
- Simulation/UI boundary concerns: none
- Asset requirements: docs-only normalization
- Compatibility or migration concerns: keep legacy `computer_terminal` references only where they clearly indicate fallback compatibility
- Clarifying questions or assumptions: no further art rename is being performed in this slice

## Implementation Plan

1. Normalize the terminal prop naming in active docs and sprite pipeline guidance.
2. Preserve compatibility references only where they document the fallback path.
3. Validate the remaining old-name mentions are intentional.

## Acceptance

- Runtime behavior: unchanged
- Documentation: current docs use `command_terminal` / `fabricator_terminal` as the canonical naming direction
- Path/reference validation: no unintentional old-name references remain in active docs
- Manual validation: `rg` sweep shows only compatibility references or legacy import filenames
- Automated/headless validation: not required for docs-only work

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? No
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No
- Does `custodian/AGENTS.md` need an update? No
- Do any design docs need an update? No

## Completion Notes

- Implemented: updated terminal asset layout guidance, terminal local-mode notes, sprite pipeline intake docs, and supporting terminal UI/sprites README language.
- Validated: grep sweep confirms remaining old terminal-name mentions are compatibility references or legacy import filenames.
- Deferred: renaming the legacy imported files themselves.

## Next Steps

- Next action: decide whether the legacy `computer_terminal` import files should be renamed or left as compatibility artifacts.
- Best starting files: `custodian/content/sprites/_pipeline/README.md`
- Required context: current terminal prop naming direction
- Validation to run: grep sweep only
- Blockers or open questions: none
