# AWAKENING INTERACTIBLE CLEAN ROOM PLATES V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-interactible-clean-room-plates-v1`
- Category: `assets-art`
- Status: `complete`
- Dispatch: `auto`
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
- Reviewed main: `3f19fc4c2e6ac9bc474a7afdac906f721a33e5e9`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Publication inputs: `custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106/underlay_source.png`; `custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106/foreground_source.png`; `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_PRECLAIM_SOURCE_RECEIPT_20261106.md`; `custodian/docs/ai_context/CRECHE_PRECLAIM_SOURCE_PUBLICATION_V1.md`
- Visual review: `required`
- Goal: `Source-only preparation of the approved 1464×1074 Crèche floor and foreground pair; Undergate is a separately owned deferred source`
- Completion boundary: `Validate and record the two exact approved PNG SHA-256 values, alpha and same-canvas registration; replace only canonical source_work masters with rollback evidence; defer inbox, family, runtime, scene, geometry and gameplay changes to the downstream Crèche room/console cutover`
- Current measured state: `Approved canonical Crèche source_work masters are 1464×1074 RGBA with exact hashes and recorded alpha bounds; existing Asset V2 family/runtime remain 960×704 and inbox remains absent pending the atomic room/console cutover`
- Evidence: `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_CANONICAL_SOURCE_STAGING_20261106.md`, `custodian/scenes/awakening_first_return.tscn`, `custodian/game/world/awakening/awakening_first_return.gd`, registered backdrop families, `design/04_architecture/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md`.
- Task-specific authority: `design/04_architecture/AWAKENING_INTERACTIBLE_CLEAN_ROOM_PLATES_V1.md` defines user-approved separation; registered Asset V2 backdrop family schemas and existing room geometry, interactions, lighting, scene and prop families retain authority.
- Work surface: `custodian/asset_drop/source_work/awakening/awakening_creche_environment/{underlay,foreground}_source.png` and source-registration/rollback receipt; no inbox, family, runtime, scene, geometry, or gameplay files
- Change: `Replace only the canonical Crèche source_work underlay/foreground masters with the exact approved floor `/home/braydenchaffee/Downloads/03aaa288-64d9-4641-ae95-74d919e738d8.png` SHA256 `9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a` and wall `/home/braydenchaffee/Downloads/8611c23f-9419-435c-9b69-c9f725a4eadb.png` SHA256 `515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc`; record preimage LFS OIDs, rollback anchor, alpha extents and same-canvas registration. Defer inbox and all family/runtime/scene/geometry edits to the Crèche room/console cutover. Undergate stays with its existing Port owner.`
- Preserve: One existing Crèche gameplay owner, one damaged Port status owner, route/collisions, scene centers/transforms, original source LFS objects for rollback, foreground alpha/occlusion, production lighting, existing 8f activation FX; no inbox promotion or temporary empty-machine deployment.
- Non-goals: `No Undergate source or Port implementation, no inbox/family update/Asset V2 ingest/runtime or gameplay changes, no source redesign or independently paired Codex reviewer`
- Acceptance: `Exact SHA-256 and 1464×1074 RGBA approved sources replace only the canonical source_work masters; source-grid registration, alpha metrics, preimage LFS OIDs and rollback anchor are recorded; inbox remains absent, the 960×704 family/runtime remain untouched, and in-engine fit/gameplay review is downstream`
- Validation: Verify original and canonical SHA-256, PNG/RGBA dimensions, alpha-zero/alpha≥128 extents, no-resample same-canvas registration, existing scene-anchor coordinate mapping, old LFS rollback objects, changed-file ownership, and the non-mutating Asset V2 plan result against the still-960×704 family. Do not create inbox files or ingest; defer in-engine composite, geometry and gameplay-scale review to the runtime cutover.
- Task overrides: `none`
- Deferred: `Atomic Crèche V2 family/scene/Layout+console cutover in awakening-creche-console-sprite-reauthor-v1; Undergate art and Port under its own blocked workstream`

## Source-only closeout scope (2026-11-06 coordinator control)

The authoring chat resolved the source/inbox mismatch for this claimed workstream: replace only the two canonical `source_work` masters, preserve old Git LFS identities as rollback evidence, and defer both inbox files because the approved 1464×1074 sources do not fit the still-live 960×704 Asset V2 family. Do not promote these inputs to `RUNTIME_READY`, bypass `asset_handoff_installer.py`, modify the family, or claim runtime installation. The matching inbox/family/Asset V2/Godot/geometry/console work belongs to the downstream room/console cutover packet. See `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_CANONICAL_SOURCE_STAGING_20261106.md` and the exact current control conversation URL in that receipt.

## Human art decision
- Exact floor and foreground source identities have been explicitly approved by the user, with SHA-256 and corrected file roles recorded below. This identity approval is sufficient for source-only preparation; the next gate is objective source validation and durable staging. A user/ChatGPT visual verdict on in-game fit remains required in the runtime cutover; no paired Codex review is required.
- Canonical visual review handoff: `/CUSTODIAN/visual_review/awakening-interactible-clean-room-plates-v1/`. Questions: Is each room architecturally identical enough to preserve traversal? Are all interactible machines absent from the plate? Does each independently composited prop fit its socket? Are foreground/shadows and scene lighting coherent?
- Source work: `custodian/asset_drop/source_work/awakening/awakening_creche_environment/underlay_source.png` and `custodian/asset_drop/source_work/awakening/awakening_undergate_environment/underlay_source.png`.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_CANONICAL_SOURCE_STAGING_20261106.md; Asset V2 plan dry-run recorded in that receipt; exact source hashes verified before/after replacement; packet, source masters and receipt committed in the closing workstream commit`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The prior packet demanded inbox staging while the current family remains 960×704 and the approved sources are 1464×1074; the handoff installer correctly forbids inbox promotion for SOURCE_READY_NEEDS_TUNE.`
- Root cause / contributing factors: `Packet completion scope predated the current source dimensions and conflated source_work preparation with runtime-ready Asset V2 intake.`
- Prevention / pipeline improvement: `Keep source identity publication, canonical source_work replacement, inbox readiness, family/schema migration, and runtime ingestion as separate explicit gates; record the family/inbox relationship at dispatch.`
- Tooling / docs drift discovered: `asset.py plan reports the Asset V2 inbox only (source_count=0 when absent); it does not inspect source_work. The expected missing-inbox warning is not source validation.`
- Follow-up: `awakening-creche-console-sprite-reauthor-v1`
- What worked: `Immutable published source inputs, exact SHA-256 checks, atomic source replacement with parent-commit LFS rollback, and same-canvas alpha/registration evidence enabled a safe source-only closeout.`

## Next Handoff
- Next workstream: `awakening-creche-console-sprite-reauthor-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `Local verified source pair needs durable Asset V2 workstream staging; no independent Crèche review`
- Next action: `Refresh and dispatch the Crèche console/room cutover after this source-only closeout; it owns inbox/family/runtime/scene/geometry changes and direct user/ChatGPT gameplay review, without a paired Codex review gate`
- Blockers or open questions: `No source-stage blockers. The downstream runtime cutover must update family/inbox/scene/geometry and obtain direct user/ChatGPT gameplay-scale review; no paired Codex review is required for this Crèche item.`

## Source selection correction and direct-review exception (2026-11-06)

The user explicitly approved the two Downloads files as the production source pair and corrected their **reversed earlier labels**. Floor/underlay: `/home/braydenchaffee/Downloads/03aaa288-64d9-4641-ae95-74d919e738d8.png` (SHA-256 `9ce70dff57e7678234ff423643d255840ca66cf855067948763f73b2b426d77a`, 1464×1074 8-bit RGBA; alpha≥128 bbox x=47..1417, y=242..980). Wall/foreground: `/home/braydenchaffee/Downloads/8611c23f-9419-435c-9b69-c9f725a4eadb.png` (SHA-256 `515b287f877cf4cd940c11aeab6bfa05370ff651f06927ba46e13c212a252bfc`, 1464×1074 8-bit RGBA; alpha≥128 bbox x=11..1452, y=8..1063). The prior chat floor SHA-256 `00f7cdda4ef266ca688fe1396321fcb137ee74e80c133bfffcda0ef8d5405381` is superseded, **not** a reason to download/regenerate artwork. These hashes are a user-approved local source-identity receipt, not a claim that in-engine registration has passed. Obtain exact original bytes from the known Downloads paths and validate against these hashes before staging; no CDP/browser extraction needed.

The user also expressly withdrew the independent Codex **paired-review requirement for the Crèche clean-source preparation and Crèche room+console runtime cutover only**. Existing reviewer packets are withdrawn, not recorded as passed; user and ChatGPT conduct gameplay-scale visual review on Codex's captured output. Asset V2 provenance, alpha, floor collision/nav, 01→02 traversal, console/FX and Godot validation **remain mandatory**. The unrelated Undergate/Port implementation and its paired review are unchanged. Crèche workstreams remain `draft/manual` until the approved sources are durably staged for the executing workstream and all ordinary packet readiness checks pass; local Downloads alone are not portable publication evidence. No runtime scene has been changed by this documentation correction.

The pre-claim source input publication completed before the first claim at `origin/main` commit `fd706097f245274d5458bf920cef82f7dd2f3b83`, publishing the two approved PNGs to immutable paths `custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106/underlay_source.png` and `custodian/asset_drop/source_work/awakening/awakening_creche_environment/preclaim_20261106/foreground_source.png`, with receipt `custodian/docs/ai_context/asset_audits/AWAKENING_CRECHE_PRECLAIM_SOURCE_RECEIPT_20261106.md`. In that commit this existing packet was atomically promoted to `ready/auto`. The completed procedure remains below as publication provenance and must not be rerun. It used `asset_handoff_installer.py` in `SOURCE_READY_NEEDS_TUNE` / `install_source=true` / `install_inbox=false` mode; this pre-claim operation did not claim a workstream or ingest runtime assets.

**Once claimed by dispatch**, this source-only packet verifies published hashes then replaces the two canonical source_work masters with rollback evidence under its claim. The inbox states are deferred because the approved 1464×1074 sources do not fit the still-live 960×704 family; do not label them `RUNTIME_READY`, bypass the installer guard, change the family, or publish runtime art. The downstream Crèche console packet owns the family update, inbox files, Asset V2 plan/ingest, scene and geometry cutover and remains dependency-gated until source closeout. Preserve direct user/ChatGPT gameplay review and the Crèche-only paired-review exemption.
