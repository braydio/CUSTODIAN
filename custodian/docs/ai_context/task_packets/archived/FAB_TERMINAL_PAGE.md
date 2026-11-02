# Fab Terminal Page

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-10
- Created: 2026-05-10
- Last updated: 2026-05-10

## Task

Add a dedicated fabrication-only terminal page inside the existing HUD terminal shell, reusing the current terminal source sheets for now but styling the mode distinctly and routing the in-terminal fab commands to the live fabrication autoloads.

## Outcome

The HUD terminal exposes a `FABRICATION` page with its own visual treatment, the page can be opened via `FAB` or `SET FAB`, and `FAB STATUS`, `FAB RECIPES`, `FAB GRANT`, and `FAB START` operate against the live `ResourceLedger` and `FabPipeline`.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/resource_fabrication/RESOURCE_FABRICATION_SYSTEM.md`, `design/RESOURCE_FAB_PIPELINE_ADD.md`
- Active runtime/docs files: `custodian/game/ui/hud/ui.gd`, `custodian/autoload/resource_ledger.gd`, `custodian/autoload/fab_pipeline.gd`, `custodian/content/resources/resource_defs.json`, `custodian/content/fabrication/fab_recipes.json`
- Historical reference only: older queue-only fab command behavior

## Work Surface

- Files or folders expected to change: `custodian/game/ui/hud/ui.gd`, AI context docs
- Files or folders expected to be read but not changed: fabrication autoloads, command terminal scene layout
- Out-of-scope areas: separate fab scene, new art production, save/load, world placement integration

## Constraints

- Determinism concerns: page rendering should not alter simulation state
- Simulation/UI boundary concerns: UI queries the fabricator autoloads; it does not own fabrication state
- Asset requirements: reuse the existing terminal source sheets for now
- Compatibility or migration concerns: keep the existing command terminal shell intact and add the fab page alongside it
- Clarifying questions or assumptions: treat the HUD terminal page as the temporary fab terminal UI surface until dedicated art/layout exists

## Implementation Plan

1. Add the fab page and page-specific terminal styling.
2. Route in-terminal fab commands to the live autoload pipeline.
3. Update the active state docs and packet index.

## Acceptance

- Runtime behavior: `FABRICATION` page opens in the HUD terminal and shows live fab data
- Documentation: active state and task packet index mention the fab terminal page
- Path/reference validation: the HUD script loads successfully
- Manual validation: fab commands can be entered from the in-terminal shell
- Automated/headless validation: a script load check for `custodian/game/ui/hud/ui.gd`

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes
- Does `custodian/AGENTS.md` need an update? No
- Do any design docs need an update? No

## Completion Notes

- Implemented: added a dynamic `FABRICATION` terminal page, page-specific styling, live fabrication data rendering, and in-terminal fab command routing to the autoload pipeline.
- Validated: `load("res://game/ui/hud/ui.gd")` and `load("res://autoload/resource_ledger.gd")` both succeeded in a headless script.
- Deferred: separate fab scene/art pass.

## Next Steps

- Next action: open the fab page in-editor and confirm the layout reads distinctly enough for the current art pass
- Best starting files: `custodian/game/ui/hud/ui.gd`
- Required context: current terminal HUD layout and fabrication autoloads
- Validation to run: headless script load plus in-editor open/command smoke test
- Blockers or open questions: none
