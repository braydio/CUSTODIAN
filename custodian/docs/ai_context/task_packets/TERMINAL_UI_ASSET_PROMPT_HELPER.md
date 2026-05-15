# TERMINAL UI ASSET PROMPT HELPER

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-14
- Created: 2026-05-14
- Last updated: 2026-05-14

## Task

Add a local helper script for generating terminal UI art prompts, referencing existing generated assets, and saving generated clipboard PNGs into the correct `custodian/content/ui/terminal/` paths.

## Outcome

The user can run a script with a target asset key, paste the copied prompt into an image generator, optionally attach/open a style reference from existing terminal assets, then press Enter after copying the generated image so the script saves it to the correct runtime path.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `custodian/docs/design/TERMINAL_UI_ASSETS.md`
- Active runtime/docs files: `custodian/content/ui/terminal/`, `custodian/tools/`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change:
  - `custodian/tools/ui/terminal_asset_prompt_helper.py`
  - this packet
- Files or folders expected to be read but not changed:
  - `custodian/content/ui/terminal/`
  - `custodian/docs/design/TERMINAL_UI_ASSETS.md`
- Out-of-scope areas:
  - Generating the actual art assets.
  - Wiring terminal UI assets into Godot scenes/themes.

## Constraints

- Determinism concerns: none; this is local tooling and asset file placement only.
- Simulation/UI boundary concerns: generated PNGs remain UI skins/overlays, not terminal behavior.
- Asset requirements: existing terminal assets are used only as optional style references.
- Compatibility or migration concerns: script should avoid new Python dependencies and use existing clipboard command-line tools.
- Clarifying questions or assumptions: "attach an image reference" is implemented as opening/copying a reference PNG for manual attachment because browser image generators do not expose a universal CLI attachment API.

## Implementation Plan

1. Add a dependency-free Python script with known missing terminal asset prompts.
2. Support listing missing assets, copying prompts, opening/copying a reference PNG, and saving clipboard PNG output.
3. Validate syntax and dry-run/list behavior.

## Acceptance

- Runtime behavior: none.
- Documentation: packet records usage and validation.
- Path/reference validation: script targets `custodian/content/ui/terminal/` and uses existing reference PNGs.
- Manual validation: real clipboard image save remains user-driven.
- Automated/headless validation: Python compile plus CLI dry-run/list checks.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? No.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? No.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? No.

## Completion Notes

- Implemented: added `custodian/tools/ui/terminal_asset_prompt_helper.py` with missing terminal asset prompts, existing terminal PNG references, prompt-copy support, optional reference-image copy/open support, and clipboard PNG save support.
- Usage: `python3 custodian/tools/ui/terminal_asset_prompt_helper.py --list`; then `python3 custodian/tools/ui/terminal_asset_prompt_helper.py panels/panel_frame_medium_9slice.png`; paste the copied prompt into the generator, optionally attach the shown reference image, copy the generated PNG, and press Enter to save it.
- Validated: `rtk proxy python3 -m py_compile custodian/tools/ui/terminal_asset_prompt_helper.py`; `rtk proxy python3 custodian/tools/ui/terminal_asset_prompt_helper.py --list`; `rtk proxy python3 custodian/tools/ui/terminal_asset_prompt_helper.py panels/panel_frame_medium_9slice.png --dry-run`.
- Deferred: real clipboard image save against a generated image.

## Next Steps

- Next action: validate script commands.
- Best starting files: `custodian/tools/ui/terminal_asset_prompt_helper.py`
- Required context: `custodian/docs/design/TERMINAL_UI_ASSETS.md`
- Validation to run: `python3 -m py_compile custodian/tools/ui/terminal_asset_prompt_helper.py`; dry-run a known asset.
- Blockers or open questions: none.
