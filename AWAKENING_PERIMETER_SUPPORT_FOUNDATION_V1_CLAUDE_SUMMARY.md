# Awakening Perimeter Support Foundation V1 — Blocked Closeout

**Workstream:** `awakening-perimeter-support-foundation-v1`

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
**Base:** resumed orphaned claim and fast-forwarded from `8c5a50a` to `origin/main@041717c3` before editing.

## Delivered

- Added a scene-owned, collision-free `AwakeningPerimeterSupport` host below canonical floor art. It creates no art, checks `ResourceLoader.exists()` before optional loads, and preserves `AwakeningVoidBackdrop`.
- Added a deterministic 27-state placement description and exact runtime paths for the nine generic zones. Zone 05 remains excluded for Dust Lung V2.
- Registered nine Asset V2 `backdrop` families with state-specific 512×512, 1024×512 and 256×256 frames, plus nine required-assets entries. All 27 states remain honestly unfulfilled: 0/3 required per family, with no source, inbox PNG or runtime art fabricated.
- Added the per-zone camera/plate ledger and its focused validation contract. The report measures all ten live plate bounds, wake, each zone center/entry/exit and all three authored reveals: 34 samples total. Four samples expose two repeated uncovered windows, 704×32 px at wake/Zone01 entry and 704×96 px at the 05→06 join. These are presentation findings; no route, collision, navigation or passage geometry changed.
- Updated the AP0 authority, current-state notes, file index, validation recipe, generated `REQUIRED_ASSETS.md`, and task packet completion/feedback.

## Validation

- Focused perimeter smoke: PASS, 10 zones, 9 families, 27 planned states, 34 camera samples; deterministic ledger; absent-art fallback; no collision authority.
- Existing Awakening scene, geometry, progression, art-registration, lower/upper traversal and lighting smokes: PASS.
- Changed-file validation before current-main sync: PASS, 49/49. After syncing to `origin/main@075025f4`, the focused Awakening-tag suite passed 22/22, but the required full changed-file validation failed twice. `review_pairing_contract` reports 11 unrelated Compound review packets whose target paths are not archived as expected. `godot_import_lfs_preflight` failed in the sweep with “standalone project should not require a Git LFS check”; a direct rerun passed, so that result is inconsistent. The full sweep selected 50 tests, passed 21, failed 2 and skipped 27 due tier gating.
- Asset V2 plans: PASS for all nine families. Status: 0/3 required and unbound for each. `asset needs --check`, JSON parsing and `git diff --check`: PASS.

## Open findings

- Global `asset doctor --json` reports four catalog-hash mismatches in the unchanged `awakening_designation_locker` family. AP0 did not alter those images or catalog records; the new family contracts/status are individually clean.
- Required post-sync changed-file validation is blocked by inherited validation drift: 11 Compound review-pairing fixtures point at target packet locations that the contract considers incorrect, and the standalone LFS preflight result differs between the sweep and direct rerun. These failures are outside AP0; the dependent post-land review cannot run until AP0 lands.
- Asset V2’s `source_pending` flag requires a real staged or receipt-approved source. With no perimeter artwork supplied, the correct state is `needed` with three missing states, not `source_pending`; the task packet wording now reflects this.
- The coverage ledger reports existing visual windows for future presentation work. No gameplay geometry adjustment is authorized by those measurements.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: blocked
- Friction severity: medium
- What went wrong: after main advanced, the mandatory full changed-file sweep failed on inherited checks even though AP0’s 22-test tag suite passed. The direct LFS preflight passed while the same test failed inside the changed-file sweep.
- Root cause / contributing factors: 11 stale Compound review target paths make the global pairing contract fail; the LFS preflight result is inconsistent. Neither failing contract belongs to AP0.
- Prevention / pipeline improvement: fix the inherited pairing fixtures and make the LFS preflight deterministic in a separate task, then rerun changed-file validation before AP0 landing.
- Tooling / docs drift discovered: changed-file validation invokes cross-project checks with stale Compound packet assumptions; the global Asset V2 doctor also continues to report four unchanged designation-locker hash mismatches.
- Follow-up: manual-follow-up
- What worked: using the scene’s live sprite transforms and authored reveal values generated the ledger without duplicating Layout authority.

## Next Handoff

- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
- Refresh reason: none
- Next action: repair inherited changed-file validation failures, rerun the full required suite, then finish AP0 and run its paired fresh-context review.
- Blockers or open questions: 11 Compound review-pairing target-path failures and an inconsistent standalone LFS preflight failure block landing; four unchanged designation-locker hash errors remain separately inherited.
