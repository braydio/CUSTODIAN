# Awakening Perimeter Support Foundation V1

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
- Changed-file validation: PASS, 49/49.
- Asset V2 plans: PASS for all nine families. Status: 0/3 required and unbound for each. `asset needs --check`, JSON parsing and `git diff --check`: PASS.

## Open findings

- Global `asset doctor --json` reports four catalog-hash mismatches in the unchanged `awakening_designation_locker` family. AP0 did not alter those images or catalog records; the new family contracts/status are individually clean.
- Asset V2’s `source_pending` flag requires a real staged or receipt-approved source. With no perimeter artwork supplied, the correct state is `needed` with three missing states, not `source_pending`; the task packet wording now reflects this.
- The coverage ledger reports existing visual windows for future presentation work. No gameplay geometry adjustment is authorized by those measurements.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: one early registry-generation invocation targeted the coordination checkout; only its own generated registry/view edits were restored, and the unrelated dirty packet was preserved. The changed manifest selected 49 checks through its existing ownership fan-out.
- Root cause / contributing factors: one invocation omitted the claimed-worktree path; validation manifest ownership intentionally fans out across many tests.
- Prevention / pipeline improvement: use the absolute scoped-worktree path for every write and check status before staging.
- Tooling / docs drift discovered: `source_pending` means source is present and awaiting fulfillment; absent source remains `needed`. Global doctor has four inherited designation-locker hash mismatches.
- Follow-up: manual-follow-up
- What worked: using the scene’s live sprite transforms and authored reveal values generated the ledger without duplicating Layout authority.

## Next Handoff

- Next workstream: review-awakening-perimeter-support-foundation-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
- Refresh reason: none
- Next action: land AP0, then run the paired fresh-context post-land review.
- Blockers or open questions: inherited global Asset V2 doctor errors for unchanged `awakening_designation_locker` catalog hashes; paired review should confirm these are outside AP0.
