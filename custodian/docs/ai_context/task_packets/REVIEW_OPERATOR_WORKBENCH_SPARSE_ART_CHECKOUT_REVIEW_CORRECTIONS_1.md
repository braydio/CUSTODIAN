# REVIEW: OPERATOR WORKBENCH SPARSE ART CHECKOUT IMPORT CORRECTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-sparse-art-checkout-review-corrections-1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-workbench-sparse-art-checkout-review-corrections-1`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-sparse-art-checkout-review-corrections-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT_REVIEW_CORRECTIONS_1.md`
- Reviewed main: `48cbed0b8d`
- Review modes: `code, workflow`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Goal: Independently verify closure of parent finding `R0-01` against current main and the landed correction evidence. The review must not assume the resumed correction authored the bytes that fixed the defect: if later main work already supplied the valid import metadata and regression protection, verify that live state, verify the sparse Workbench acceptance path, and record the finding truthfully as fixed/unresolved/regressed.
- Reviewed implementation acceptance: The east and west `block_hold_01` FX imports resolve correctly; canonical Operator SpriteFrames import coverage remains valid; a disposable/fresh `operator-authoring-v1` sparse validation checkout can satisfy its required local LFS dependencies without network access and run the mandatory modular-layer smoke; the correction does not widen sparse scope, weaken validation, modify Operator pixels/runtime behavior, or introduce unrelated tracked changes.
- Current measured state:
  - Current main already contains the actual import repair from `e3d4e7f98` (`operator block hold fx reimport`). Both tracked east/west `block_hold_01` FX sidecars contain valid remap paths and `dest_files`, with no `valid=false`; the PNG bytes were not changed by that repair.
  - `custodian/tools/validation/operator_runtime_spriteframes_import_smoke.py` now guards all 588 canonical Operator texture imports and is registered in the validation manifest.
  - Durable repair evidence records a clean project import, 588/588 import-smoke pass, and `operator_modular_layers_smoke.gd` exit 0 after local-only LFS hydration.
  - The resumed correction was checkpointed at `21f914e05` with no new runtime repair required. Its remaining blockers were sparse-checkout LFS availability and one stale real-repo UI-smoke wording assertion, not a recurrence of R0-01.
  - Current main now fixes that brittle UI assertion by checking the semantic `isolated art checkout` blocker instead of the obsolete literal branch-name wording.
  - `VALIDATION_RECIPES.md` now makes the local-only hydration order explicit: local/shared LFS object cache first; if the exact object is absent there but a local hydrated checkout has the same repository-relative file, that checkout may donate bytes only after SHA-256 and byte size exactly match the target pointer; otherwise block. No implicit `git lfs pull` or `git lfs fetch`.
- Review evidence:
  - parent review finding `R0-01` in archived `REVIEW_OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT.md`;
  - archived correction packet and its closing summary after the dependency lands;
  - `OPERATOR_BLOCK_HOLD_FX_REIMPORT_CLAUDE_SUMMARY.md`;
  - current east/west `block_hold_01` FX `.png.import` sidecars;
  - `custodian/tools/validation/operator_runtime_spriteframes_import_smoke.py`;
  - `custodian/tools/validation/operator_modular_layers_smoke.gd`;
  - `custodian/tools/validation/operator_art_worktree_smoke.py`;
  - `custodian/docs/ai_context/VALIDATION_RECIPES.md`.
- Correction threshold: Create another correction cycle only if `R0-01` is unresolved/regressed, the sparse profile cannot satisfy the mandatory validation path despite canonical local LFS payloads being available, or the correction weakened sparse/publish safety. Do not open another correction merely because a stale/unrelated test assertion or environment issue exists; route that to its actual owner unless the reviewed correction caused it.
- Focused validation:
  1. Inspect the archived correction packet/summary and the exact diff that landed. Establish whether it changed production files or merely closed evidence/lifecycle around the already-landed `e3d4e7f98` repair.
  2. Inspect both current FX sidecars and run `python3 custodian/tools/validation/operator_runtime_spriteframes_import_smoke.py`.
  3. Reuse the correction workstream's sparse proof when it is fresh, commit-identified, and records the LFS source/provenance. Do not perform a second broad project import merely to duplicate equivalent evidence.
  4. If sparse proof must be reproduced, use a disposable/version-matched sparse checkout. Run `godot_import_preflight.py` first. Hydrate required LFS paths from the local object cache; for any object absent from cache, use the verified local-donor procedure in `VALIDATION_RECIPES.md` (same path, target pointer OID/size, donor SHA-256/size exact match, target remains Git-clean). Never fetch LFS from the network.
  5. After preflight passes, run `godot --headless --path custodian --script res://tools/validation/operator_modular_layers_smoke.gd`. A project-wide import is justified only if the disposable sparse proof actually lacks the generated cache needed for this smoke and all LFS preconditions are already green.
  6. Run `python3 custodian/tools/validation/operator_art_worktree_smoke.py` if the landed correction changed sparse/worktree behavior; otherwise reuse its current-main fixture evidence.
  7. Run the smallest changed-file validation needed for the review artifacts and `git diff --check`.
- Review focus:
  - `R0-01` is judged from current production truth, not from which workstream happened to commit the repair.
  - Exact FX remap integrity and unchanged source/runtime pixels.
  - 588-texture canonical import regression protection remains live.
  - Sparse proof uses measured profile boundaries and local-only LFS materialization; no broad sparse widening or network fetch.
  - Local donor bytes are accepted only when they cryptographically match the target LFS pointer and leave the target checkout Git-clean.
  - Do not treat generated `.import` churn from an unsafe persistent-checkout import as review evidence; preserve/revert it and use disposable validation.
  - The old UI-smoke branch-name assertion is superseded on current main and is not an R0-01 blocker.
- Acceptance: Produce a findings-first independent review of live main. Retain finding ID `R0-01` and report it as `fixed`, `unresolved`, or `regressed`; assign any genuinely new correction-caused finding the next cycle-scoped ID. A clean result should record `R0-01 = fixed`, zero new blocking findings, and no additional correction work. Do not patch reviewed implementation code.
- Non-goals: Do not redesign the sparse profile, modify art, redesign Workbench publish/readiness, add network LFS acquisition, recapture equivalent import evidence unnecessarily, or reopen unrelated Operator pipeline behavior.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after `operator-workbench-sparse-art-checkout-review-corrections-1` completes and archives on `origin/main`.
2. Read the archived correction packet/summary and parent `R0-01` receipt, then inspect current sidecars and the landed diff.
3. Reuse fresh implementation sparse/import evidence whenever it proves the acceptance above; reproduce only missing proof with the bounded local-only hydration procedure.
4. Record the independent review receipt in the archived correction packet, write the required review closing summary, archive this review packet, and finish normally.
5. If `R0-01` is fixed with no blocking findings, allow `operator-workbench-publish-readiness-recovery` to become eligible immediately.

## Handoff

- Next action: Auto-dispatch after the correction lands; expected fast path is current-sidecar/import-smoke inspection plus reuse of the correction's fresh disposable sparse proof.
- Blockers or open questions: none in the review contract. Missing local LFS content is an environment blocker only after both local-cache and exact verified local-donor paths are exhausted.
