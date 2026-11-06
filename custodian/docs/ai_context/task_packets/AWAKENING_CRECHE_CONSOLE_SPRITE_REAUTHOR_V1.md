# AWAKENING CRÈCHE CONSOLE SPRITE REAUTHOR V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-creche-console-sprite-reauthor-v1`
- Category: `assets-art`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-awakening-creche-console-idle-fx-binding-v1, awakening-interactible-clean-room-plates-v1`
- Locks: `awakening-interaction-presentation, awakening-interactible-asset-contracts`
- Kind: `implementation`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, runtime, visual, asset-pipeline`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Explicit user authorization for direct user/ChatGPT Crèche review, retaining tests and provenance`
- Reviewed main: `52f11a85a04ebd6401160ee2c33ebdf9763e9b04`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `required`
- Goal: `Atomic 1464×1074 Crèche floor+foreground replacement, measured Zone01 walkability, and exactly one separate playable Crèche console with its screen-local FX`
- Completion boundary: `Approved 1464×1074 underlay+foreground pair V2-ingested and scene-bound with updated authored Zone01 walkability, preserved 01→02 route, correct console/8-frame FX, technical Godot validation and direct user/ChatGPT gameplay-scale visual verdict`
- Current measured state: `Live Crèche remains 960×704 at legacy sprite positions; approved 1464×1074 floor and foreground sources are available locally but not yet ingested or registered in Godot`
- Evidence: `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/content/metadata/assets/families/awakening_creche_console.asset.json`; `custodian/content/metadata/assets/families/awakening_creche_console_activation_fx.asset.json`; `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_OVERLAY_V1.md`.
- Task-specific authority: `AwakeningFirstReturn` visual presentation, original `CrecheConsole` interaction owner, existing canonical V2 families, Layout marker, current root and custodian AGENTS art/review rules.
- Work surface: ``custodian/content/metadata/assets/families/awakening_creche_environment.asset.json`, Crèche V2 source_work/inbox underlay+foreground, `custodian/game/world/awakening/awakening_layout.gd`, `custodian/scenes/awakening_first_return.tscn`, `custodian/game/world/awakening/awakening_first_return.gd`, existing console/FX and focused tests`
- Change: 1. Read real LFS art/Crèche room underlay and existing 8-frame FX. Measure idle computer silhouette and screen rectangle first; inspect at gameplay scale, not just isolated PNG. User reports current terminal presentation is unacceptable, so do not treat a binding-only patch as aesthetic completion.
2. Design one industrial-Gothic civic **128×128 RGBA, 1-frame** authored sprite with strong usable-face silhouette, graphite/stone composite, low brass details, inset cyan screen fitting the **existing FX's 8 frames of 128×128 at 8 FPS**; avoid generic kiosk/neon and preserve camera oblique projection. Keep original activation FX as-is unless measured fit is impossible; then stop and request separate FX source authorization.
3. New source at `custodian/asset_drop/source_work/awakening/awakening_creche_console/idle_source.png`; normalized input at `custodian/asset_drop/inbox/awakening_creche_console/idle.png` (128×128 true alpha). Keep `custodian/content/metadata/assets/families/awakening_creche_console.asset.json` family/state, no new `awakening_interact_terminal` hero.
4. Codex may perform deterministic crop/alpha cleanup/palette/offset work only on copied/staged source with backup and diff/ROI metrics. Dry-run `python3 custodian/tools/assets/asset.py plan awakening_creche_console --json`; `ingest awakening_creche_console --replace --yes` only after exact human-approved source SHA and conflict check; then `status --json`, `doctor --json`, receipts/catalog/import/LFS verification. Never edit generated runtime directly or hide other-family catalog errors.
5. Re-measure reviewed `ScreenAnchor` relative to changed body; run HUD-hidden gameplay still + compact activation capture, and publish single visual handoff for explicit user approval. Stop if quality is not accepted.
- Preserve: Existing `CrecheConsole` gameplay, first-use acknowledgement and repeat readout, HUD prompt, exact Layout marker (112,144), no duplicated body, original FX frames/fps.
- Non-goals: `No paired Codex reviewer, no duplicate hero/interactable, no direct runtime PNG overwrite, no Undergate changes or making the entire transparent canvas walkable`
- Acceptance: `Both approved source hashes, 1464×1074 RGBA pair registration, Asset V2 receipts for both states, correct collision/walkability and 01→02 seam, one physical console, screen-local 8-frame FX, objective Godot smokes and direct user/ChatGPT visual signoff`
- Validation: `Asset V2 plan/guarded --replace/status/doctor, LFS/import checks, awakening_first_return_geometry_smoke.gd, awakening_collision_mapper_bridge_smoke.gd, awakening_art_registration_smoke.gd, awakening_first_return_progression_smoke.gd, awakening_creche_console_screen_anchor_smoke.gd, awakening_first_return_smoke.gd, gameplay-scale captures, git diff --check`
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
- Follow-up: `direct-user-chatgpt-visual-verdict`
- What worked: `<fill at closeout>`

## Next Handoff
- Next workstream: `none`
- Next packet state: `awaiting-direct-user-chatgpt-visual-review`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `Direct human/ChatGPT review of actual Godot gameplay evidence; no paired Codex reviewer`
- Next action: `When checked source prep is durable, atomically implement both 1464×1074 states, Layout and independent console; publish actual gameplay captures for user/ChatGPT verdict`
- Blockers or open questions: `Portable approved source/registration proof and Godot integration; no paired-review dependency`

## Clean room-plate cutover authority (2026-10-11)

**User design decision:** all live interactible machine bodies must be independently rendered, not baked in the new room plates. Consume approved source states `awakening_creche_environment/underlay` AND `/foreground` (both 1464×1074) from `awakening-interactible-clean-room-plates-v1` and human-approved new `awakening_creche_console/idle` (128×128); their **runtime cutover is atomic in this Crèche implementation**, with Asset V2 replacement receipts for both. The old `CrecheConsoleBody` Node2D-with-baked-source metadata must become a true `Sprite2D` or own a child Sprite2D; measure physical pivot at existing scene (105,118) and screen anchor/FX offset at 8 FPS. Preserve `CrecheConsole` gameplay interaction (112,144), and replace the foreground with the approved 1464×1074 wall while preserving measured occlusion. Do not remove baked body before approved hero is shown in same scene transaction. Source-work inbox per `design/04_architecture/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md`; use `asset.py plan`, guarded `--replace`, status/doctor, and a normal-gameframe composited screenshot. The old permissive rule to keep a baked visible console is **superseded** by this explicitly approved architecture; prior baseline review is historical only. Preserve exact size/origin and route surfaces.

## Source selection correction and direct-review exception (2026-11-06)

The user explicitly approved the two Downloads files as the production source pair and corrected their **reversed earlier labels**. Floor/underlay: `/home/braydenchaffee/Downloads/03aaa288-64d9-4641-ae95-74d919e738d8.png` (SHA-256 `9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a`, 1464×1074 8-bit RGBA; alpha≥128 bbox x=47..1417, y=242..980). Wall/foreground: `/home/braydenchaffee/Downloads/8611c23f-9419-435c-9b69-c9f725a4eadb.png` (SHA-256 `515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc`, 1464×1074 8-bit RGBA; alpha≥128 bbox x=11..1452, y=8..1063). The prior chat floor SHA-256 `00f7cdda4ef266ca688fe1396321fcb137ee74e80c133bfffcda0ef8d5405381` is superseded, **not** a reason to download/regenerate artwork. These hashes are a user-approved local source-identity receipt, not a claim that in-engine registration has passed. Obtain exact original bytes from the known Downloads paths and validate against these hashes before staging; no CDP/browser extraction needed.

The user also expressly withdrew the independent Codex **paired-review requirement for the Crèche clean-source preparation and Crèche room+console runtime cutover only**. Existing reviewer packets are withdrawn, not recorded as passed; user and ChatGPT conduct gameplay-scale visual review on Codex's captured output. Asset V2 provenance, alpha, floor collision/nav, 01→02 traversal, console/FX and Godot validation **remain mandatory**. The unrelated Undergate/Port implementation and its paired review are unchanged. Crèche workstreams remain `draft/manual` until the approved sources are durably staged for the executing workstream and all ordinary packet readiness checks pass; local Downloads alone are not portable publication evidence. No runtime scene has been changed by this documentation correction.
