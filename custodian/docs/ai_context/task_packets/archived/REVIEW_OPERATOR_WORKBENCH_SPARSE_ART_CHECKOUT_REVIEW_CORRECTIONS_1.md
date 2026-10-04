# REVIEW: OPERATOR WORKBENCH SPARSE ART CHECKOUT IMPORT CORRECTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-workbench-sparse-art-checkout-review-corrections-1`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-workbench-sparse-art-checkout-review-corrections-1`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Review: `none`
- Review target workstream: `operator-workbench-sparse-art-checkout-review-corrections-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT_REVIEW_CORRECTIONS_1.md`
- Reviewed main: `00f2dbf10d2fd0f21d2164ba4f7328537500bf31`
- Review modes: `code, workflow`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Goal: Independently verify closure of parent finding `R0-01` against current main and the landed correction evidence. The review must not assume the resumed correction authored the bytes that fixed the defect: if later main work already supplied the valid import metadata and regression protection, verify that live state, verify the sparse Workbench acceptance path, and record the finding truthfully as fixed/unresolved/regressed.
- Reviewed implementation acceptance: The east and west `block_hold_01` FX imports resolve correctly; canonical Operator SpriteFrames import coverage remains valid; a disposable/fresh `operator-authoring-v1` sparse validation checkout can satisfy its required local LFS dependencies without network access and run the mandatory modular-layer smoke; the correction does not widen sparse scope, weaken validation, modify Operator pixels/runtime behavior, or introduce unrelated tracked changes.
- Current measured state:
  - Current main already contains the actual import repair from `e3d4e7f98` (`operator block hold fx reimport`). Both tracked east/west `block_hold_01` FX sidecars contain valid remap paths and `dest_files`, with no `valid=false`; the PNG bytes were not changed by that repair.
  - `custodian/tools/validation/operator_runtime_spriteframes_import_smoke.py` dynamically checks every canonical Operator SpriteFrames texture import. The live resource references 562 textures after the deliberate C2b.3 compatibility cutover reduced runtime outputs from 596 to 562; the current check passes 562/562.
  - Reproduced sparse acceptance in disposable checkout `92ec91bebf47a777265122a9cd40fe5fbb1f8f62`: 3,263 profile-present LFS payloads (298,008,774 bytes) were hydrated from shared local cache only after SHA-256 and size verification; no network fetch. Preflight passed, Godot 4.7.2 import exited 0 without `ERROR`/`SCRIPT ERROR`, and `operator_modular_layers_smoke.gd` passed. Current reviewed main `00f2dbf10d2fd0f21d2164ba4f7328537500bf31` differs only in packet/index documentation; all tested runtime, sparse-profile, import, and smoke files are unchanged. Disposable checkout removed after validation.
  - The resumed correction was checkpointed at `21f914e05` with no new runtime repair required. Its remaining blockers were sparse-checkout LFS availability and one stale real-repo UI-smoke wording assertion, not a recurrence of R0-01.
  - Current main now fixes that brittle UI assertion by checking the semantic `isolated art checkout` blocker instead of the obsolete literal branch-name wording.
  - `VALIDATION_RECIPES.md` now makes the local-only hydration order explicit: local/shared LFS object cache first; if the exact object is absent there but a local hydrated checkout has the same repository-relative file, that checkout may donate bytes only after SHA-256 and byte size exactly match the target pointer; otherwise block. No implicit `git lfs pull` or `git lfs fetch`.
  - The completed fast_03 recovery adds a second concrete warning: unscoped `git lfs checkout` can expand sparse-omitted content. Sparse proof must hydrate only required paths already present in the measured profile, whether the bytes come from cache or a verified local donor.
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
  2. Inspect both current FX sidecars and run `python3 custodian/tools/validation/operator_runtime_spriteframes_import_smoke.py`; compare its dynamic count with the live canonical SpriteFrames resource rather than assuming the historical 588 count.
  3. Reuse the correction workstream's sparse proof when it is fresh, commit-identified, and records the LFS source/provenance. The proof is recorded with correction closeout `6f85b09a2`; verify all relevant runtime/import files remain identical on current main. Do not perform a second broad project import merely to duplicate equivalent evidence unless the reviewed head invalidates that proof.
  4. If sparse proof must be reproduced, use a disposable/version-matched sparse checkout. Run `godot_import_preflight.py` first. Hydrate only required paths already present in the sparse checkout from the local object cache; for any object absent from cache, use the verified local-donor procedure in `VALIDATION_RECIPES.md` (same path, target pointer OID/size, donor SHA-256/size exact match, target remains Git-clean). Never run an unscoped `git lfs checkout` that expands omitted content, and never fetch LFS from the network.
  5. After preflight passes, run `godot --headless --path custodian --script res://tools/validation/operator_modular_layers_smoke.gd`. A project-wide import is justified only if the disposable sparse proof actually lacks the generated cache needed for this smoke and all LFS preconditions are already green.
  6. Run `python3 custodian/tools/validation/operator_art_worktree_smoke.py` if the landed correction changed sparse/worktree behavior; otherwise reuse its current-main fixture evidence.
  7. Run the smallest changed-file validation needed for the review artifacts and `git diff --check`.
- Review focus:
  - `R0-01` is judged from current production truth, not from which workstream happened to commit the repair.
  - Exact FX remap integrity and unchanged source/runtime pixels.
  - The dynamic canonical import regression guard covers every current SpriteFrames texture reference (562 on reviewed main); the earlier 588 count predates the intentional C2b.3 output retirement.
  - Sparse proof uses measured profile boundaries and SHA-256/size-verified local-only LFS materialization; no broad sparse widening or network fetch.
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

- Next action: Auto-dispatch `operator-workbench-publish-readiness-recovery` after this review lands; `R0-01` is fixed and no further correction cycle is required.
- Blockers or open questions: none.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The packet's historical 588-texture count was stale after the intentional C2b.3 runtime cutover; the first graph lookup also required a worktree-local index build.
- Root cause / contributing factors: Review assumptions were copied forward across a canonical runtime inventory reduction; this worktree had no initialized code-review graph.
- Prevention / pipeline improvement: Derive the canonical texture count from the live SpriteFrames resource and current smoke output; initialize the graph once when a fresh worktree has none.
- Tooling / docs drift discovered: The packet's current measured import count was 588, while current main has 562 canonical textures; the packet now records the intentional 596-to-562 cutover and dynamic coverage.
- Follow-up: `fixed-in-scope`
- What worked: Reused pointer-verified sparse LFS evidence and ran the current-main worktree fixture without repeating a broad import.
