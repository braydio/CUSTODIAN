# OPERATOR 2.5D CANONICAL IDLE FAMILY WORKBENCH INTAKE

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-canonical-idle-workbench-intake
- Status: ready
- Dispatch: manual
- Priority: P1
- Depends on: review-operator-2-5d-workbench-production-queue
- Locks: operator-art-agent, operator-source-normalization, operator-workbench-ui, operator-art-generation-schema
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, asset-pipeline, workflow
- Paired review workstream: review-operator-2-5d-canonical-idle-workbench-intake
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: requires independent byte/provenance/source-validation proof, not visual redirection
- Reviewed main: 6ff9c52b3315c9f3afc2a7ce42576b564df26673
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Visual review: none
- Goal: Turn the previously accepted immutable 8-direction 15-frame Operator 2.5D relaxed-idle source into exactly eight hash-bound editable Workbench direction records through the existing WB25-2 specialized Asset Pipeline V2 ingress, without publishing any production runtime image.
- Completion boundary: Verify and hydrate the exact accepted master, reproducibly extract eight full-row 1920×128 RGBA strips, perform one eight-direction WB25-2 import package against current plan/profile/reference authority, report each direction's actual EDITABLE_WORKBENCH or BLOCKED status, preserve provenance, and prove no runtime/publication mutation. This is **art intake**, not review completion or WB25-6 promotion.
- Current measured state: WB25-5 implementation `69cdfdbf1` / landing `d4efc0234` passed fresh review `cd72b90b1` with zero findings. A current-code measurement of main `f6831452` with populated art checkout `c463a1cf` (824 commits behind main; untouched) found 69 target families/552 directions, **0 current receipt-verified leaves/families**, **0 2.5D Workbench manifests**, no current review receipts. Source-work manifest already exists on main at `custodian/asset_drop/source_work/operator/operator_2_5d_first_animation/unarmed_posture_idle_relaxed_01_full_body_v1_manifest.json`; source PNG is Git LFS-backed and can be a pointer in GitHub's unhydrated tree. The accepted source is already registered; do not regenerate it.
- Evidence: `design/02_features/animation/OPERATOR_2_5D_WORKBENCH_MIGRATION_ROADMAP.md`; `OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT_CLAUDE_SUMMARY.md`; first source-work manifest; `operator_2_5d_ingress.py::create_package/process_package/validate_package`; `ui/service.py::import_2_5d_direction_set`; `operator_animation_targets.py`; `operator_asset_schema.py`; `operator_2_5d_ingress_smoke.py`.
- Task-specific authority: approved `custodian.operator_source_work_manifest.v1` master record, authoritative WB25-1 2.5D target plan, WB25-2 SourceArtService and generation-aware Workbench creation/ingress, WB25-3 polish, WB25-4 effective review. Operator specializes Asset Pipeline V2; do not create a second generic `.asset.json` family for the same animation.
- Work surface: `custodian/tools/operator/` only if a small deterministic one-time extractor is necessary; the existing `custodian/asset_drop/inbox/operator_2_5d/` and `.ai/operator_animation_workbench/` (ignored local source-work/workspace; not runtime); one concise durable source-intake evidence report under `custodian/docs/reports/operator_2_5d/` or an established Operator reporting path; focused import/unit smoke if code added. Do not alter `operator.gd`, selector, runtime sync, runtime PNGs, manifest, catalog, SpriteFrames, active generation policy or completed packets.
- Change:
  1. Read the accepted source-work manifest and verify the physical master against SHA-256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`, **541981 actual PNG bytes**, RGBA `1920×1024`. Refuse a 131-byte (or otherwise unhydrated) Git LFS pointer. Prefer `git lfs pull` for this exact file in a disposable/current checkout; alternatively retrieve immutable `/CUSTODIAN/implementation_inputs/operator_2_5d_unarmed_posture_idle_relaxed_01_full_body_v1_8dir_15f_128.png` and verify its exact SHA before use. Do not fetch from the stale art checkout and silently treat it as current code.
  2. Split by the **explicitly approved master-manifest direction map**, not inferred ordering: row 0=n, 1=ne, 2=e, 3=se, 4=s, 5=sw, 6=w, 7=nw. Each is exactly 15 frames in one horizontal `1920×128` RGBA strip, 128×128 per frame with **real alpha**. Reassemble the strips in declared row order and assert pixel-byte identical `RGBA.tobytes()` to the source before ingress. Preserve original master immutable; no resampling, palette conversion, root shifting, recoloring, image generation, or Aseprite art touch-ups.
  3. Stage all 8 strips through the specialized Operator inbox convention: `custodian/asset_drop/inbox/operator_2_5d/operator_2_5d_128__unarmed__posture__idle_relaxed_01__<direction>__full_body__15f.png`. Use the existing source-work family `operator_2_5d_unarmed_posture_idle_relaxed_01` and specialized `custodian.operator_2_5d_import_package.v1` with exact target hashes; do not register a duplicate generic Asset V2 family.
  4. On a current code checkout with a deliberately selected current 2.5D workspace, construct the eight `AnimationSelection('unarmed','posture','idle_relaxed_01',direction,art_generation='operator_2_5d_128')` records and invoke existing `Operator2DIngress.create_package` / `process_package` or the equivalent reviewed WorkbenchService import. Reuse existing package state/resume instead of recreating conflicting Source Sessions. Stale checkout data must not overwrite current plan/profile/reference contracts; a real collision or unhydrated master fails closed.
  5. Persist the package ID, exact source-master hash, individual strip SHA/dimensions, explicit direction mapping, intended repo/workspace roots and **observed** per-cell status in a small durable evidence report. Each complete cell must resolve to an actual saved, physically valid `workbench.aseprite` plus `workbench.json`; if a tool cannot create saved files automatically, leave those cells BLOCKED with the exact missing step rather than declaring them complete. Record all input/output checks without packaging ignored large binary art in the implementation commit.
  6. Treat plan `fps=null` as **unknown**. Existing creation UI can insert a default FPS for editing; that is **not authored/human-approved timing**, and no inferred frame duration closes later review or runtime promotion. Source-intake success requires editable records and exact pixels only, not invented production clock approval or `RUNTIME_VERIFIED`.
  7. Snapshot and compare runtime manifest, catalog, SpriteFrames and affected legacy PNG hashes before/after; must be unchanged. Re-measure current family/direction statuses via Workbench queue and exact effective review, distinguish `LOCAL CANONICAL` from `RUNTIME_VERIFIED`, and never write `PUBLISHED`.
- Preserve: WB25-4 backend-owned approval provenance; immutable source-master bytes and accepted SHA; current profile and reference hashes; old 96×96 source/runtime; all published runtime outputs and selector; ignored artist workspace state; WB25-6 `draft/manual` promotion hold.
- Non-goals: authoring any new poses/frames, creating runtime policy, promoting even one 2.5D direction, decomposing the modular body, altering gameplay/hit windows, human approving unknown timing, claiming the rest of the 69-family plan, adding a parallel Asset V2/Workbench system.
- Acceptance: 8 deterministic 1920×128 strips from the exact 1920×1024 master with a reconstruction-equality proof; 8 distinct target bindings and all actual saved Workbench documents verified where available; no unexpected source or workspace mutation; exact legacy/runtime hash preservation; per-cell truthful statuses and missing-proof details; no successful promotion claim. If master cannot be hydrated or some cells cannot be saved, record `blocked` with persistent evidence, not a false complete.
- Validation: focused lossless split/reassembly and SHA integrity; `custodian/tools/validation/operator_2_5d_ingress_smoke.py`; `operator_animation_targets_smoke.py`; `operator_workbench_production_queue_smoke.py`; `operator_2_5d_review_smoke.py` if available; compare runtime hashes; run `python3 custodian/tools/validation/run_validation.py --changed --json` only after focused success; `git diff --check`. If code or smoke changes, register focused manifest ownership.
- Task overrides: none
- Deferred: final physical timing approval, per-direction QA/human review/sandbox verification; unarmed cohort dependency closure; WB25-6 production promotion.

## Lifecycle and follow-up

- Implementation executes only in the dispatcher-claimed isolated worktree. Use an explicit `dispatch.py claim operator-2-5d-canonical-idle-workbench-intake --agent codex` because this is a one-time, externally hydrated art-source operation (`ready/manual`), not the global auto queue. Do not claim WB25-6 instead. The existing art workspace may be used read-only until identity/ownership is verified.
- Closing receipt records actual editable vs blocked directions, the portable evidence location, exact original source hash, source-work/drop-inbox schema, and any missing physical documents. If blocked, preserve the workstream and do not report success.
- Once accepted by fresh paired review, the next art iteration is to bring the idle family through WB25-4 physical QA, approved timing and Godot sandbox. No runtime generation switch yet.

## Handoff

- Next workstream: review-operator-2-5d-canonical-idle-workbench-intake
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Summary backlink: include exact Authoring chat URL
- Refresh reason: none for source intake; WB25-6 separately remains user-cohort gated
- Next action: independent byte-exact source intake review
- Blockers or open questions: physical LFS hydration availability checked at execution; no new subjective design choice required for intake
