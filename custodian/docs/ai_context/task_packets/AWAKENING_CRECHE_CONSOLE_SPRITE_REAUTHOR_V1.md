# AWAKENING CRÈCHE CONSOLE SPRITE REAUTHOR V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-creche-console-sprite-reauthor-v1`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-awakening-creche-console-idle-fx-binding-v1, review-awakening-interactible-clean-room-plates-v1`
- Locks: `awakening-interaction-presentation, awakening-interactible-asset-contracts`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual, asset-pipeline`
- Paired review workstream: `review-awakening-creche-console-sprite-reauthor-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `visual/Asset V2 production change merits independent review`
- Reviewed main: `956cf2114458`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `required`
- Goal: Author a production Crèche terminal sprite with a true readable machine silhouette and custom fit to the existing activation VFX.
- Completion boundary: One human-approved new 128×128 RGBA idle image replaces the existing `awakening_creche_console/idle` V2 state through source_work/inbox and checked `--replace`, retains exactly one visible machine and reviewed screen anchor.
- Current measured state: `AwakeningFirstReturn._build_console_activation_presentation()` adds FX at `_marker_position(&"zone01_creche","creche_console")` without instantiating the existing 128×128 idle hero; FX is 8×128×128 at 8 FPS.
- Evidence: `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/content/metadata/assets/families/awakening_creche_console.asset.json`; `custodian/content/metadata/assets/families/awakening_creche_console_activation_fx.asset.json`; `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_OVERLAY_V1.md`.
- Task-specific authority: `AwakeningFirstReturn` visual presentation, original `CrecheConsole` interaction owner, existing canonical V2 families, Layout marker, current root and custodian AGENTS art/review rules.
- Work surface: `custodian/asset_drop/source_work/awakening/awakening_creche_console/idle_source.png`; `custodian/asset_drop/inbox/awakening_creche_console/idle.png`; existing console/FX family; `custodian/game/world/awakening/awakening_first_return.gd`; focused screenshot and smoke.
- Change: 1. Read real LFS art/Crèche room underlay and existing 8-frame FX. Measure idle computer silhouette and screen rectangle first; inspect at gameplay scale, not just isolated PNG. User reports current terminal presentation is unacceptable, so do not treat a binding-only patch as aesthetic completion.
2. Design one industrial-Gothic civic **128×128 RGBA, 1-frame** authored sprite with strong usable-face silhouette, graphite/stone composite, low brass details, inset cyan screen fitting the **existing FX's 8 frames of 128×128 at 8 FPS**; avoid generic kiosk/neon and preserve camera oblique projection. Keep original activation FX as-is unless measured fit is impossible; then stop and request separate FX source authorization.
3. New source at `custodian/asset_drop/source_work/awakening/awakening_creche_console/idle_source.png`; normalized input at `custodian/asset_drop/inbox/awakening_creche_console/idle.png` (128×128 true alpha). Keep `custodian/content/metadata/assets/families/awakening_creche_console.asset.json` family/state, no new `awakening_interact_terminal` hero.
4. Codex may perform deterministic crop/alpha cleanup/palette/offset work only on copied/staged source with backup and diff/ROI metrics. Dry-run `python3 custodian/tools/assets/asset.py plan awakening_creche_console --json`; `ingest awakening_creche_console --replace --yes` only after exact human-approved source SHA and conflict check; then `status --json`, `doctor --json`, receipts/catalog/import/LFS verification. Never edit generated runtime directly or hide other-family catalog errors.
5. Re-measure reviewed `ScreenAnchor` relative to changed body; run HUD-hidden gameplay still + compact activation capture, and publish single visual handoff for explicit user approval. Stop if quality is not accepted.
- Preserve: Existing `CrecheConsole` gameplay, first-use acknowledgement and repeat readout, HUD prompt, exact Layout marker (112,144), no duplicated body, original FX frames/fps.
- Non-goals: No new interaction owner, no second asset family for the hero, no general editor, no speculative room/route changes, no direct runtime PNG modification.
- Acceptance: Verified single new hero idle PNG visually recognizable before prompt; source→inbox→V2 receipt and exact SHA, 8 FX frames screen-contained, no duplicate body, objective smokes green and recorded human approval.
- Validation: Asset V2 plan/status/doctor; PNG alpha/ROI + pixels/frame geometry; updated screen anchor, progression and art registration smokes; import/LFS; --changed and diff --check; human visual handoff.
- Task overrides: `none`
- Deferred: All other support/Port/Locker/Lift art remains in its pre-existing packet.

## Art authorization gate

This packet stays draft/manual until a human-approved authored image, exact checksum, and Asset V2 source handoff are available. Existing `asset_handoff_installer.py` permits dry-run verified staging; it does **not** approve image quality or publish runtime output. Publisher must use `custodian/tools/iteration/publish_review_artifacts.py --important --reason ...`, preserving external visual decision. Do not ask Codex to invent an artistic acceptance verdict.

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
- Follow-up: `review-awakening-creche-console-sprite-reauthor-v1`
- What worked: `<fill at closeout>`

## Next Handoff
- Next workstream: `review-awakening-creche-console-sprite-reauthor-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `Explicit human art-source and visual approval required`
- Next action: After implementation lands, start paired fresh-context review.
- Blockers or open questions: No newly approved source/visual verdict yet; do not claim.

## Clean room-plate cutover authority (2026-10-11)

**User design decision:** all live interactible machine bodies must be independently rendered, not baked in the new room plates. Consume reviewed source state `awakening_creche_environment/underlay` (960×704) from `awakening-interactible-clean-room-plates-v1` and human-approved new `awakening_creche_console/idle` (128×128); their **runtime cutover is atomic in this Crèche implementation**, with Asset V2 replacement receipts for both. The old `CrecheConsoleBody` Node2D-with-baked-source metadata must become a true `Sprite2D` or own a child Sprite2D; measure physical pivot at existing scene (105,118) and screen anchor/FX offset at 8 FPS. Do not change `CrecheConsole` gameplay interaction (112,144) or `awakening_creche_foreground`. Do not remove baked body before approved hero is shown in same scene transaction. Source-work inbox per `design/04_architecture/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md`; use `asset.py plan`, guarded `--replace`, status/doctor, and a normal-gameframe composited screenshot. The old permissive rule to keep a baked visible console is **superseded** by this explicitly approved architecture; prior baseline review is historical only. Preserve exact size/origin and route surfaces.
