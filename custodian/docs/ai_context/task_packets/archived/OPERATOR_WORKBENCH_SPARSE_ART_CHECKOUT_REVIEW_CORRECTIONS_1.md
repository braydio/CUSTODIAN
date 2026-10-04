# CORRECTION: OPERATOR WORKBENCH SPARSE ART CHECKOUT REVIEW

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-sparse-art-checkout-review-corrections-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-operator-workbench-sparse-art-checkout`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-operator-workbench-sparse-art-checkout-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `dfaf9e269`
- Parent implementation: `operator-workbench-sparse-art-checkout` — `custodian/docs/ai_context/task_packets/archived/OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT.md`
- Parent review: `review-operator-workbench-sparse-art-checkout` — `custodian/docs/ai_context/task_packets/archived/REVIEW_OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT.md`
- Findings addressed: `R0-01`
- Affected acceptance: The sparse profile must support Workbench publication's mandatory Godot modular-layer validation, and missing-resource failures block acceptance.
- Current defect/evidence: The tracked east and west `block_hold_01` FX `.import` sidecars contain `valid=false` and no remap `path`/`dest_files`. Both source PNGs exist and are valid, but Godot fails to load them from the sparse profile; `operator_modular_layers_smoke.gd` then fails while loading the Operator actor.
- Goal: Restore valid Godot import metadata for the two published `block_hold_01` FX textures so the mandatory Workbench validation succeeds from a fresh sparse checkout.
- Completion boundary: Repair only the two affected import records and any directly required import-generation step. Do not change the PNG art, sparse path profile, publication allowlist, or unrelated generated imports.
- Current measured state: Real sparse checkout has 9,665 of 37,307 tracked paths materialized before Godot cache generation. The required modular-layer smoke fails on the two tracked FX texture references; Python Workbench, UI, mirror-publication, compatibility, and contract-report checks pass.
- Evidence: Parent review finding `R0-01`; `custodian/content/sprites/operator/runtime/animations/unarmed/defense/block_hold_01/operator__fx__unarmed__defense__block_hold_01__e__5f__96.png.import`; corresponding west-facing sidecar; `operator_runtime_frames.tres`; `operator_modular_layers_smoke.gd`.
- Task-specific authority: `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`; Godot import metadata and the existing Operator Workbench publication validation contract.
- Work surface: The two named `.import` sidecars, the minimal source/import command needed to produce them, and focused sparse-worktree validation.
- Required correction: Regenerate or repair both import records so they contain valid Godot remap data and resolve to imported textures. Verify that a fresh sparse worktree can import the project and complete `operator_modular_layers_smoke.gd` without missing-resource or Operator script-parse errors.
- Preserve: PNG bytes, canonical source/runtime naming, all other import metadata, worktree-local sparse configuration, exact publish allowlist, safe FF-only synchronization, ignored `.ai` state, and the no-network LFS policy.
- Non-goals: Do not widen sparse patterns to mask invalid import metadata, weaken or skip the modular-layer smoke, edit unrelated `.import`/`.uid` files, or change Operator art/runtime code.
- Acceptance:
  1. Both tracked `.import` sidecars have valid remap metadata and no `valid=false` marker.
  2. On a fresh sparse profile with locally cached required LFS objects, Godot import succeeds and `operator_modular_layers_smoke.gd` exits successfully without missing-resource or Operator script-parse errors.
  3. `operator_art_worktree_smoke.py`, `operator_workbench_ui_smoke.py`, `operator_animation_workbench_smoke.py`, and `operator_workbench_mirror_publish_smoke.py` remain green; no unrelated tracked file is changed by the correction.
- Validation: Run the two focused Operator FX import/actor checks first, then the four named Workbench smokes, compatibility-resource `--check`, animation-contract report, and `git diff --check`. Use only local LFS objects; when a branch has LFS pointer files and the full project-root checkout has the matching payload, copy only files whose bytes match the pointer's SHA-256. Do not fetch LFS content from the network or broaden validation into an actor sweep.
- Task overrides: `none`
- Deferred: none.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: Both tracked FX `.import` sidecars on current `main` contain valid remap paths and `dest_files`, with no `valid=false`; their PNG bytes are unchanged. Godot import preflight passed in the sparse Operator art checkout, project import exited 0 without missing-resource or Operator script-parse errors, and `operator_modular_layers_smoke.gd` passed there. The sparse runtime surface matched `origin/main`. All four named Workbench smokes passed in the resumed task branch after copying 785 hash-matching LFS source payloads from the full project-root checkout; the compatibility-resource smoke and animation-contract report also passed, with zero missing required art. `git diff --check` and changed-file review-pairing validation passed; all copied LFS files and generated imports were restored so no unrelated tracked file remains changed.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: The first sparse import ran while the worktree still had missing LFS payloads and rewrote 1,561 tracked `.import` sidecars; those edits were restored. The UI smoke first ran from coordination `main`, where its expected branch-specific message does not apply; it passed when rerun from the task branch.
- Root cause / contributing factors: I stopped at the shared LFS cache instead of copying matching assets from the full project-root checkout, and ran one checkout-specific UI assertion from the wrong branch context.
- Prevention / pipeline improvement: Copy only pointer-matching LFS payloads from the full root checkout after verifying each pointer SHA-256; run the Workbench UI smoke from the claimed task branch. Preflight before Godot import.
- Tooling / docs drift discovered: The packet's local-only LFS note did not identify the full project-root checkout as a source for matching payloads; this packet now records that exact-hash route.
- Follow-up: `none`
- What worked: Exact-hash copying resolved 785 source payloads without network access; sparse import, modular-layer smoke, and all scoped Workbench checks passed.

## Independent Review

- Status: `passed`
- Review workstream: `review-operator-workbench-sparse-art-checkout-review-corrections-1`
- Reviewed on main: `00f2dbf10d2fd0f21d2164ba4f7328537500bf31`
- Review modes: `code, workflow`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `none`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `none`

### Findings

- **R0-01** (`fixed`, blocking validation): Current east/west `block_hold_01` FX sidecars both contain remap `path` and `dest_files`, with no `valid=false`. The current canonical SpriteFrames import smoke passes every one of the 562 live texture references. The earlier 588 count predates the intentional C2b.3 compatibility cutover (596 runtime outputs to 562); the guard remains dynamic and covers the current resource. The two PNG blobs are unchanged by the import-repair commit and match current `origin/main`. No correction-caused finding or new correction cycle is warranted.

### Verification Performed

- **Current import truth** (reviewed `origin/main` `00f2dbf10d2fd0f21d2164ba4f7328537500bf31`): inspected both sidecars and verified their `res://.godot/imported/*.ctex` remap/destination and source paths; `python3 custodian/tools/validation/operator_runtime_spriteframes_import_smoke.py` PASS, `562 texture imports`. Both runtime PNG Git blob IDs match `origin/main`. Commit `e3d4e7f98` changed only the two `.import` sidecars in this asset directory, not the PNGs.
- **Sparse acceptance**: reused the correction workstream's recorded Godot 4.7.2 sparse import and `operator_modular_layers_smoke.gd` PASS at correction closeout `6f85b09a2`. Its evidence records 785 local LFS payloads copied only after SHA-256 verification against pointer OIDs, followed by restoration; no network LFS fetch was used. Reproduced the sparse proof in a disposable checkout at `92ec91bebf47a777265122a9cd40fe5fbb1f8f62`: 3,263 required LFS payloads (298,008,774 bytes) came only from the shared local cache after SHA-256 and size verification, no network fetch; preflight passed, Godot 4.7.2 project import exited 0 without `ERROR`/`SCRIPT ERROR`, and `operator_modular_layers_smoke.gd` passed. The disposable checkout was removed. Current main `00f2dbf10d2fd0f21d2164ba4f7328537500bf31` differs from that tested head only in packet/index documentation; all sparse-profile, runtime/import, and smoke files remain unchanged. A later sparse-profile commit adds only `.githooks` and `tools/validate_filenames.py`; the current `operator_art_worktree_smoke.py` PASS exercises those hook dependencies, rejects invalid filenames, and continues to omit unrelated reports.
- **Regression boundaries**: no new broad import was run because the current production files match the sparse proof and the current focused guard passes. The prior review's sparse-isolation/publication findings remain covered by unchanged implementation and the passing current fixture.
- **Repository hygiene**: `git diff --check` PASS. No reviewed implementation file was changed.
