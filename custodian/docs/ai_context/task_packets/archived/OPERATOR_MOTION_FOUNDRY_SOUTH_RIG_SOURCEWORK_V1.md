# OPERATOR MOTION FOUNDRY SOUTH RIG SOURCE-WORK INTEGRATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-motion-foundry-south-rig-sourcework-v1`
- Kind: `implementation`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-south-rig-sourcework`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, asset-pipeline, workflow`
- Paired review workstream: `review-operator-motion-foundry-south-rig-sourcework-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `pixel-perfect source archive intake and preservation of Operator 2.5D production authority require independent byte/provenance verification`
- Reviewed main: `306c7da688a9026e88a26231442a2fb529014d66`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Visual review: `none`
- Goal: Make the user-supplied South Operator pixel-extraction addendum available as a reproducible, validated, reviewable **source-work-only rig** on `origin/main`, with its actual extraction script and tests tracked in the repo and no canonical art changes.
- Completion boundary: Retrieve the pinned Dropbox ZIP by immutable path+SHA, prove 41-member inventory and source hash, install the complete self-contained extraction/review source-work tree and a reusable repo-owned extractor/test entrypoint, run its exact lossless reconstruction checks, register narrow test ownership, land only unapproved source-work/tool changes.
- Current measured state: MF1 renderer exists under `custodian/tools/operator/motion_foundry/` but its paired review `review-operator-motion-foundry-core-v1` remains a separate protected dependency; MF2 source bridge is still review-dependent. No `operator_south_visible_surface_v1` repo source-work or extractor is present at reviewed main. A user-created 197858-byte external ZIP is already uploaded to Dropbox, sha `ea039bbbf945da4172c61d43a61beea793bf92a0f807c73d363cd7877673bf94`, and its local seven extraction tests passed.
- Evidence: `custodian/docs/ai_context/asset_audits/OPERATOR_MOTION_FOUNDRY_SOUTH_RIG_ADDENDUM_20261019.md` (pinned paths, SHA, safe transport, 41-member layout); `design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md`; `design/02_features/animation/CUSTODIAN_MOTION_FOUNDRY_V1.md`; `custodian/tools/operator/motion_foundry/{rig,motion,render,qa,cli}.py` existing code only; `custodian/docs/ASSET_LAYOUT_CONVENTION.md` and specialized Operator V2 schema.
- Task-specific authority: The approved Operator 128px art/reference/root contract and existing `operator_2_5d` source/ingress family; `custodian.tools.operator.motion_foundry.rig/motion` schemas for *data shape only*; `custodian/docs/ai_context/IMPLEMENTATION_HANDOFF.md` for Dropbox-as-transport; no second asset family or publication path.
- Work surface: `custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/`; `custodian/tools/assets/operator_south_rig_extract.py` (new extraction adapter or straightforward reviewed copy); `custodian/tools/validation/operator_south_rig_extract_smoke.py` (new owned smoke); `custodian/tools/validation/validation_manifest.json` (narrow owner/selection); one exact `-text -diff !eol` rule in `custodian/.gitattributes` for the bundled CRLF pixel ledger so its pinned payload hash survives Git storage and fresh clone. The ledger is validated by its inventory hash and regression tests instead of a normalized text diff. Existing `custodian/tools/operator/motion_foundry/` is **read-only** this slice to avoid changing MF1 while its review is preserved.
- Publication inputs: `custodian/docs/ai_context/asset_audits/OPERATOR_MOTION_FOUNDRY_SOUTH_RIG_ADDENDUM_20261019.md`
- Change:
  1. Confirm dispatch ownership/clean claimed worktree and exact external ZIP via the tracked source-lock note. Resolve the connected rclone remote safely; use **read-only** fetch into disposable staging and verify exact ZIP SHA/size, single top-level root, no traversal/symlink/duplicate entries, all 41 file hashes from `bundle_inventory.json`, and original `source/CUSTODIAN_OPERATOR_RUNTIME_REFERENCE_128.aseprite` SHA `61c7518b31a28d7b98af5efdb035316550b769abea7eb33ff0466544040172a3`. Fail closed on missing/changed host input. Do not use a chat download.
  2. Stage the exact unpacked self-contained bundle under the specified source-work target. If target already exists, compare every byte and refuse conflicting writes; no overwrites, no unrelated source/art changes. Preserve all 41 members so tests and independent visual-review surfaces are available on main. Follow current Git LFS rules for binary Aseprite and PNG where required; verify actual hydrated bytes rather than LFS pointers.
  3. Make the bundle's Python extractor reusable from the separate `custodian/tools/assets/` seam, without moving authority into MF1's protected core modules. Add a focused validation smoke that runs the existing seven supplied tests through this tracked extractor, with correct cwd/PYTHONPATH, and register exact path ownership. Prefer a minimal wrapper importing the source-work script if that is safe and maintainable; do not fork/mutate the algorithm silently.
  4. Assert selected source is **south frame index 4 of eight viewing directions**, 128x128; precisely **2440 visible pixels** assigned once to **23** original-coordinate RGBA layers (**18** with pixels, **5** intentionally blank); PNG, CSV and native `.aseprite` one-frame/23-layer neutral reassembly identical in RGBA bytes to original. Record 494 4-connected seam-adjacent pixels, 23 fallback assignments, and the non-approved hierarchy/pivot/occlusion warnings as review evidence, not automatic art approval. Run tests twice for determinism and mutate one source byte to verify fail-closed.
  5. Do **not** run MF1 render/check/plan or MF2 source-work bridge as an acceptance requirement while MF1's independent review remains unresolved. The delivered static 15f `motion_static_proof.json` is source-work reference only, `fps=null`, no motion synthesized. Capture status truth in a concise source-work README/receipt and publish a minimal cropped seam review if subjective approval is later requested, using existing opt-in visual review procedure; no art approval in this packet.
- Preserve: The approved 2.5D source and 15f idle master, eight independent directional identities, profile hash/root/floor, original 8-frame Aseprite bytes, MF1 renderer's implementation/review worktree, both protected review recoveries, MF2 dependency, enemy 96px cutout system, normalized references, accepted canonical source/Runtime/Asset V2 surfaces.
- Non-goals: No learned or invented hidden geometry, no rig rotations/IK, no dynamic animation, no rendering source-work into runtime, no Workbench publication, no `asset_drop/inbox/operator_2_5d` write, no automatic Asset V2 ingest, no generated cosmetic AI images, no reviewer/claim recovery.
- Acceptance: (A) Exact SHA-verified external source+41 members become tracked self-contained source_work (or no claim if remote source unavailable) and survive a fresh clone. (B) 7/7 bundled tests and registered smoke pass. (C) 2440/2440 original RGBA pixels, 23 unique full-canvas layers, 18 populated, five empty, Aseprite single frame and byte-perfect neutral recomposition; source mutation/corrupt ZIP refuses. (D) Deterministic re-extraction produces identical per-file SHA, with no canonical/runtime/inbox bytes touched. (E) Source manifest explicitly says `source_work_only_unapproved_rig_candidate`, and no accepted animation/timing claim or new v2 family. (F) Workstream summary records source inputs/bytes and unchanged approvals.
- Validation: bundled `python3 scripts/test_extract_operator_south_rig.py`; newly added focused `operator_south_rig_extract_smoke.py` run directly and via `run_validation.py --test <registered-id> --json` when ID exists; `operator_2_5d_canonical_visual_contract_smoke.py` only if asset/reference paths change; `run_validation.py --changed --json` after narrow tests; CRLF-aware `git -c core.whitespace=cr-at-eol diff --check`; `git lfs ls-files` if LFS used. Check exact source-work hash inventory and no Git untracked artifact leaks.
- Task overrides: `none`
- Deferred: MF1 accepted independent review, MF2 explicit candidate-to-Source Session bridge, human seam correction and hidden underpaint, real motion presets and IK.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `The exact 197858-byte Dropbox object was fetched by read-only rclone from file ID id:8NXqdXuW6GUAAAAAAAAEfA and verified at SHA-256 ea039bbbf945da4172c61d43a61beea793bf92a0f807c73d363cd7877673bf94. All 41 bundle members match bundle_inventory.json; source SHA is 61c7518b31a28d7b98af5efdb035316550b769abea7eb33ff0466544040172a3. The registered source-work smoke and bundled seven-test suite pass, with exact 2440-pixel RGBA and native Aseprite reconstruction. No runtime or Asset V2 inbox files changed.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: `The required changed-file sweep reported an unrelated operator_unarmed_fast_chain_north_vfx_contract failure (source pixels differ from inbox); 24 downstream tests were consequently skipped. The focused source-work test and registered smoke both passed.`
- Root cause / contributing factors: `Editing the global validation manifest selects all tests that declare it as an owner, and the sweep includes an existing Operator source/inbox mismatch outside this packet's work surface.`
- Prevention / pipeline improvement: `Keep the new source-work test narrowly registered and report global-manifest-triggered failures separately from the focused owner test; repair the unrelated Operator source/inbox mismatch in its owning workstream.`
- Tooling / docs drift discovered: `The candidate bundle was published as a flat Dropbox ZIP, so the packet correctly uses its pinned read-only rclone path rather than implementation_handoff.py.`
- Follow-up: `manual-follow-up`
- What worked: `The immutable file ID, payload digest, and per-member hashes made the external asset input reproducible without importing unreviewed art into runtime.`

## Next Handoff

- Next workstream: `review-operator-motion-foundry-south-rig-sourcework-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Refresh reason: `none`
- Next action: `Perform fresh independent source/ledger/binary audit. Keep artistic approval deferred.`
- Blockers or open questions: `The global changed-file sweep found an unrelated Operator source/inbox mismatch in operator_unarmed_fast_chain_north_vfx_contract; the focused source-work validation is green. MF1 acceptance and artistic approval remain separate deferred gates.`
