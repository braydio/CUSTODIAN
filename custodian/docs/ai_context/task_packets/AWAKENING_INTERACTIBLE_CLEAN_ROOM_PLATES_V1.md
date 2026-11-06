# AWAKENING INTERACTIBLE CLEAN ROOM PLATES V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-interactible-clean-room-plates-v1`
- Category: `assets-art`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-awakening-creche-console-idle-fx-binding-v1`
- Locks: `awakening-interaction-presentation, awakening-interactible-asset-contracts`
- Kind: `implementation`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, visual, asset-pipeline`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Explicit user authorization for direct user/ChatGPT Crèche review, retaining tests and provenance`
- Reviewed main: `52f11a85a04ebd6401160ee2c33ebdf9763e9b04`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Publication inputs: `custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106/underlay_source.png`; `custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106/foreground_source.png`; `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_PRECLAIM_SOURCE_RECEIPT_20261106.md`; `custodian/docs/ai_context/CRECHE_PRECLAIM_SOURCE_PUBLICATION_V1.md`
- Visual review: `required`
- Goal: `Source-only preparation of the approved 1464×1074 Crèche floor and foreground pair; Undergate is a separately owned deferred source`
- Completion boundary: `Validate/record the two exact approved PNG SHA-256 values and alpha/registration, stage source_work and inbox for Crèche, with no runtime scene or gameplay changes`
- Current measured state: `Crèche live family still 960×704; the approved two 1464×1074 RGBA sources are in local Downloads with roles corrected and hashes stated in the 2026-11-06 addendum`
- Evidence: `custodian/scenes/awakening_first_return.tscn`, `custodian/game/world/awakening/awakening_first_return.gd`, registered backdrop families, `design/04_architecture/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md`, current inspection handoff.
- Task-specific authority: `design/04_architecture/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md` defines user-approved separation; registered Asset V2 backdrop family schemas and existing room geometry, interactions, lighting, scene and prop families retain authority.
- Work surface: ``custodian/asset_drop/source_work/awakening/awakening_creche_environment/{underlay,foreground}_source.png`, `custodian/asset_drop/inbox/awakening_creche_environment/{underlay,foreground}.png`, reproducible source QA; no runtime files`
- Change: `Use floor `/home/braydenchaffee/Downloads/03aaa288-64d9-4641-ae95-74d919e738d8.png` SHA256 `9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a` and foreground `/home/braydenchaffee/Downloads/8611c23f-9419-435c-9b69-c9f725a4eadb.png` SHA256 `515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc`; preserve full-resolution original bytes; stage in the existing Crèche V2 underlay/foreground states, verify alpha, pixel registration, scene-space anchors and source receipts, do not ingest. Undergate stays with existing Port owner.`
- Preserve: One existing Crèche gameplay owner, one damaged Port status owner, route/collisions, scene centers/transforms, original source plates for rollback, foreground alpha/occlusion, production lighting, existing 8f activation FX; no temporary empty-machine deployment.
- Non-goals: `No Undergate source or Port implementation, no Godot/runtime mutation, no source redesign or independently paired Codex reviewer`
- Acceptance: `Exact SHA-256, RGBA and full-resolution matching floor/wall sources with registration evidence, recorded source provenance, no runtime changes; final game-scale human review is downstream`
- Validation: PNG dimensions/alpha/registration and native-size comparison; temporary composite using independent hero art; exact source hash/Asset V2 plan dry-run; visually check remaining room details/lighting and original foreground overlay; changed-file ownership where applicable; no runtime ingest.
- Task overrides: `none`
- Deferred: `Atomic Crèche V2 family/scene/Layout+console cutover in awakening-creche-console-sprite-reauthor-v1; Undergate art and Port under its own blocked workstream`

## Human art decision
- Exact floor and foreground source identities have been explicitly approved by the user, with SHA-256 and corrected file roles recorded below. The next gates are objective source validation/durable staging, then a user/ChatGPT visual verdict on real gameplay captures; no paired Codex review is required.
- Canonical visual review handoff: `/CUSTODIAN/visual_review/awakening-interactible-clean-room-plates-v1/`. Questions: Is each room architecturally identical enough to preserve traversal? Are all interactible machines absent from the plate? Does each independently composited prop fit its socket? Are foreground/shadows and scene lighting coherent?
- Source work: `custodian/asset_drop/source_work/awakening/awakening_creche_environment/underlay_source.png` and `custodian/asset_drop/source_work/awakening/awakening_undergate_environment/underlay_source.png`.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `Current baked-room underlays retained until separate reviewed atomic cutovers`
- Evidence: `<fill at closeout>`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `<fill>`
- Root cause / contributing factors: `<fill>`
- Prevention / pipeline improvement: `<fill>`
- Tooling / docs drift discovered: `<fill>`
- Follow-up: `awakening-creche-console-sprite-reauthor-v1`
- What worked: `<fill>`

## Next Handoff
- Next workstream: `awakening-creche-console-sprite-reauthor-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `Local verified source pair needs durable Asset V2 workstream staging; no independent Crèche review`
- Next action: `Stage/publish the checked source pair, then continue directly to the Crèche console/room atomic cutover without any paired-review gate`
- Blockers or open questions: `Only durable source staging and registration proof; neither a missing download nor a separate reviewer`

## Source selection correction and direct-review exception (2026-11-06)

The user explicitly approved the two Downloads files as the production source pair and corrected their **reversed earlier labels**. Floor/underlay: `/home/braydenchaffee/Downloads/03aaa288-64d9-4641-ae95-74d919e738d8.png` (SHA-256 `9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a`, 1464×1074 8-bit RGBA; alpha≥128 bbox x=47..1417, y=242..980). Wall/foreground: `/home/braydenchaffee/Downloads/8611c23f-9419-435c-9b69-c9f725a4eadb.png` (SHA-256 `515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc`, 1464×1074 8-bit RGBA; alpha≥128 bbox x=11..1452, y=8..1063). The prior chat floor SHA-256 `00f7cdda4ef266ca688fe1396321fcb137ee74e80c133bfffcda0ef8d5405381` is superseded, **not** a reason to download/regenerate artwork. These hashes are a user-approved local source-identity receipt, not a claim that in-engine registration has passed. Obtain exact original bytes from the known Downloads paths and validate against these hashes before staging; no CDP/browser extraction needed.

The user also expressly withdrew the independent Codex **paired-review requirement for the Crèche clean-source preparation and Crèche room+console runtime cutover only**. Existing reviewer packets are withdrawn, not recorded as passed; user and ChatGPT conduct gameplay-scale visual review on Codex's captured output. Asset V2 provenance, alpha, floor collision/nav, 01→02 traversal, console/FX and Godot validation **remain mandatory**. The unrelated Undergate/Port implementation and its paired review are unchanged. Crèche workstreams remain `draft/manual` until the approved sources are durably staged for the executing workstream and all ordinary packet readiness checks pass; local Downloads alone are not portable publication evidence. No runtime scene has been changed by this documentation correction.

## Pre-claim publication sequence (2026-11-06 authoritative refresh)

This packet remains `draft/manual` until a restricted, owner-approved **source input publication** brings the two approved PNGs to immutable paths `custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106/underlay_source.png`, `custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106/foreground_source.png`, with source receipt `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_PRECLAIM_SOURCE_RECEIPT_20261106.md`, then atomically flips this **existing** packet to `ready/auto`. Run the exact pre-claim instructions in [CRECHE_PRECLAIM_SOURCE_PUBLICATION_V1.md](../CRECHE_PRECLAIM_SOURCE_PUBLICATION_V1.md). The installer is `custodian/tools/assets/asset_handoff_installer.py` and MUST be used `SOURCE_READY_NEEDS_TUNE` / `install_source=true` / `install_inbox=false` in preclaim. The two old canonical source masters already exist as different LFS objects; never overwrite them preclaim. This action is not a packet claim, does not use `workstream.py start`, and does not ingest Godot/runtime. Do not switch to ready if exact source objects+receipt are not durably published on main.

**Once claimed by dispatch**, this source-only packet verifies published hashes then replaces/stages the two canonical source_work masters and source inbox states with rollback evidence under its claim. It does not publish runtime art. The downstream Crèche console packet remains `draft/manual` until the claimed source packet's completion and other real prerequisites. Preserve direct user/ChatGPT gameplay review and the Crèche-only paired-review exemption.
