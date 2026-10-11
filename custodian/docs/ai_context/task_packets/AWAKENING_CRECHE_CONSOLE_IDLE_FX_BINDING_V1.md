# AWAKENING CRÈCHE CONSOLE IDLE/FX BINDING V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-creche-console-idle-fx-binding-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `awakening-interaction-presentation, awakening-interactible-asset-contracts`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual, asset-pipeline`
- Paired review workstream: `review-awakening-creche-console-idle-fx-binding-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `visual/Asset V2 production change merits independent review`
- Reviewed main: `956cf2114458`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `conditional`
- Goal: Bind the already-published idle computer and its activation VFX as one convincing screen-local scene object.
- Completion boundary: Existing 128×128 idle hero is actually instantiated unless doing so would duplicate baked underlay; 8f at 8fps activation becomes a measured child of the visible screen, not a floor-anchored sprite.
- Current measured state: `AwakeningFirstReturn._build_console_activation_presentation()` adds FX at `_marker_position(&"zone01_creche","creche_console")` without instantiating the existing 128×128 idle hero; FX is 8×128×128 at 8 FPS.
- Evidence: `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/content/metadata/assets/families/awakening_creche_console.asset.json`; `custodian/content/metadata/assets/families/awakening_creche_console_activation_fx.asset.json`; `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_OVERLAY_V1.md`.
- Task-specific authority: `AwakeningFirstReturn` visual presentation, original `CrecheConsole` interaction owner, existing canonical V2 families, Layout marker, current root and custodian AGENTS art/review rules.
- Work surface: `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/scenes/awakening_first_return.tscn`; new `custodian/tools/validation/awakening_creche_console_screen_anchor_smoke.gd`; `custodian/tools/validation/validation_manifest.json`. 
- Change: 1. Measure native Crèche underlay, actual LFS-pulled idle PNG, and existing FX alpha/ROI; determine sole visible computer. If not already visibly baked, add `CrecheConsoleBody: Sprite2D` under `Zone01_Creche/SetPieces`, from `res://content/sprites/environment/props/awakening/awakening_creche_console/runtime/body/awakening_creche_console__body__interaction__idle__omni__1f__128.png` (no new PNG).
2. In `_build_console_activation_presentation()` add `ScreenAnchor: Node2D` under the actual body and parent the existing `CrecheConsoleActivation` to it; place relative to measured alpha screen window, never directly at `_marker_position()`. Keep `_build_console_activation_frames()` exactly 8×128×128 at 8 FPS, `_play_console_activation()`, animation_finished, repeat and `_reset_console_activation()`.
3. Add `awakening_creche_console_screen_anchor_smoke.gd` with negative floor-anchor mutation, body/FX parent and scene assertions, real first interaction/repeat/reset. Register precise validation ownership. If body is baked in underlay, prove unique visible silhouette and named anchor instead of layering another identical hero.
- Preserve: Existing `CrecheConsole` gameplay, first-use acknowledgement and repeat readout, HUD prompt, exact Layout marker (112,144), no duplicated body, original FX frames/fps.
- Non-goals: No new interaction owner, no second asset family for the hero, no general editor, no speculative room/route changes, no direct runtime PNG modification.
- Acceptance: Exactly one visible console and FX inside its actual screen, no floor flash, no gameplay/geometry change, existing V2 assets retained.
- Validation: focused new screen anchor smoke; awakening_first_return_progression; awakening_art_registration; exact pixel ROI, --changed, diff --check.
- Task overrides: `none`
- Deferred: Human source-art reauthor tracked separately.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `No gameplay owner replaced; one visible Crèche console.`
- Evidence: `<fill at closeout>`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `review-awakening-creche-console-idle-fx-binding-v1`
- What worked: `<fill at closeout>`

## Next Handoff
- Next workstream: `review-awakening-creche-console-idle-fx-binding-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `none`
- Next action: After implementation lands, start paired fresh-context review.
- Blockers or open questions: Only declared predecessor/review dependencies.
