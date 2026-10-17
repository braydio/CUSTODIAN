# Awakening Perimeter Support Foundation V1

**Workstream:** `awakening-perimeter-support-foundation-v1`

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
**Prior authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
**Base:** preserved recovery branch `d3358181`; lifecycle resume merged current `origin/main@3e84bb10845fd708b2ab58ff17237817cca3b912` as `5397fa93` before the final validation pass.

## Delivered

- Added a scene-owned, collision-free `AwakeningPerimeterSupport` host below canonical floor art. It creates no art, checks `ResourceLoader.exists()` before optional loads, and preserves `AwakeningVoidBackdrop`.
- Added a deterministic 27-state placement description and exact runtime paths for the nine generic zones. Zone 05 remains excluded for Dust Lung V2.
- Registered nine Asset V2 `backdrop` families with state-specific 512×512, 1024×512 and 256×256 frames, plus nine required-assets entries. All 27 states remain honestly unfulfilled: 0/3 required per family, with no source, inbox PNG or runtime art fabricated.
- Added the per-zone camera/plate ledger and its focused validation contract. The report measures all ten live plate bounds, wake, each zone center/entry/exit and all three authored reveals: 34 samples total. Four samples expose two repeated uncovered windows, 704×32 px at wake/Zone01 entry and 704×96 px at the 05→06 join. These are presentation findings; no route, collision, navigation or passage geometry changed.
- Updated the AP0 authority, current-state notes, file index, validation recipe, generated `REQUIRED_ASSETS.md`, and task packet completion/feedback.

## Validation

- Focused perimeter smoke: PASS, 10 zones, 9 families, 27 planned states, 34 camera samples; deterministic ledger; absent-art fallback; no collision authority.
- Existing Awakening scene, geometry, progression, art-registration, lower/upper traversal and lighting smokes: PASS.
- `validate_review_pairing.py`: PASS, 102/102 auto-review packets.
- `godot_import_lfs_preflight`: PASS, 1/1.
- Awakening tag suite: PASS, 22/22, 0 failed, 0 skipped.
- Changed-file validation after current-main sync: PASS, 50/50, 0 failed, 0 skipped, complete coverage. Report: `/tmp/awakening-changed-validation-resumed.json`.
- Asset V2 plans: PASS for all nine families. Status: 0/3 required and unbound for each. `asset needs --check`, JSON parsing and `git diff --check`: PASS.

## Open findings

- Global `asset doctor --json` still reports four `awakening_designation_locker` catalog/runtime hash mismatches. Audit: the `job_20261007T205424Z_80b02bf4` publication receipt and generated catalog carry the original output hashes; current runtime bytes differ for all four states, and commits `6775cc844` / `eb3cdc9e9` changed those runtime PNGs afterward. The current source-work images match neither the changed runtime PNGs nor a newer publication receipt. Pixel comparisons against the archived publication outputs show substantial changes (8,738 closed, 14,794 empty, 14,707 open_loaded, and 64,024 authorize_open pixels). No catalog hashes were changed. A provenance-backed Asset V2 re-publication is separate from AP0.
- The initial post-sync sweep was blocked by inherited Compound and LFS-fixture defects. Mainline correction `b9c94e6677f3a73b38fc1cd438d1c19a438be305` fixed all 11 Compound review targets and the standalone LFS fixture; the requested validators and full changed-file sweep now pass.
- Asset V2’s `source_pending` flag requires a real staged or receipt-approved source. With no perimeter artwork supplied, the correct state is `needed` with three missing states, not `source_pending`; the task packet wording now reflects this.
- The coverage ledger reports existing visual windows for future presentation work. No gameplay geometry adjustment is authorized by those measurements.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: main advanced while AP0 was blocked, so finish required reconciliation and a fresh full sweep. The later mainline correction resolved the stale pairing and LFS fixture failures. The separate locker doctor errors stem from runtime edits after its recorded Asset V2 publication.
- Root cause / contributing factors: inherited mainline validation drift was corrected at `b9c94e667`; the locker catalog still describes the prior four-state publication while its runtime PNGs were edited in subsequent commits without updated source-work inputs or Asset V2 receipt.
- Prevention / pipeline improvement: require runtime art edits to travel through source-work/inbox and Asset V2 publication so catalog, receipt, and actual bytes stay aligned.
- Tooling / docs drift discovered: four locker runtime files have no matching current approved-source/publication evidence; `asset doctor` correctly reports the mismatch. This remains a separate provenance follow-up; AP0’s nine family plans/statuses and needs check are clean.
- Follow-up: manual-follow-up
- What worked: using the scene’s live sprite transforms and authored reveal values generated the ledger without duplicating Layout authority.

## Next Handoff

- Next workstream: review-awakening-perimeter-support-foundation-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Refresh reason: none
- Next action: land AP0 through `workstream.py finish`, then initiate the paired fresh-context post-land review.
- Blockers or open questions: four designation-locker catalog/runtime hash mismatches remain; no new provenance-backed Asset V2 publication exists for the edited runtime bytes.
