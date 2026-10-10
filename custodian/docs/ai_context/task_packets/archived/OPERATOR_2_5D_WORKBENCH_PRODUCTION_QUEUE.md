# OPERATOR 2.5D WORKBENCH PRODUCTION QUEUE + GENERATION BRIEFS

> WB25-5 design refreshed 2026-10-10 against the accepted WB25-4 correction/re-review and live v2 plan.  
> This packet builds the queue and local generation briefs only; WB25-6 still owns runtime promotion. Never re-claim archived WB25-4 corrections.

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-production-queue
- Status: complete
- Dispatch: auto
- Priority: P1
- Depends on: review-operator-2-5d-workbench-review-automation-review-corrections-1
- Locks: operator-workbench-ui, operator-animation-plan
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-operator-2-5d-workbench-production-queue
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: substantial engineering default
- Reviewed main: e4cf3b99d41583ce7985310b870cd414f88e04a1
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Visual review: none
- Goal: Turn the landed 2.5D target/workflow/review state into an honest production queue and deterministic generation-brief exporter so the next animation to author is obvious and returned source-work can re-associate with the exact target.
- Completion boundary: Add queue/dashboard projections, progress/family closure, NEXT explanation, filters, and local generation-brief bundles. Preserve human plan rank/priority. No network generation and no production runtime cutover.
- Current measured state: Live v2 plan rechecked 2026-10-10: **69 families / 552 required direction leaves; 4 P0 / 65 P1; 1 accepted canonical source family (8 direction source leaves), 68 not-yet-authored families (544 direction leaves); 1 resolved frame-count contract and 68 unresolved**. A read-only probe on older main `ff7d3aec`, using the populated `CUSTODIAN-operator-art` checkout `c463a1cf` (745 commits behind at measurement), reported **0 current receipt-verified leaves / 0 verified families, 0 2.5D workspace manifests, 0 current receipts and 0 sandbox passes**. Its sole relaxed-idle Workbench document is legacy 96×96, five frames, direction `e`, NOT a canonical 128×128 15-frame intake. These 0s characterize that observed workspace only, not every user's machine or future execution; ignored `.ai/` evidence must always be remeasured live. Also confirmed on current main: `Operator2DReview.family()` currently accesses nonexistent `AnimationRecord.coverage`/`.stale` and raises `AttributeError` on real projected records. Existing synthetic review-smoke fixtures mask this mismatch. WB25-5 has not implemented a production queue or brief exporter; WB25-6 separately owns PUBLISHED.
- Evidence: live plan `design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json` (69/552, 1/68 frame contracts); `operator_animation_targets.py::project_targets()` produces `ui/state.py::AnimationRecord` (`coverage_status`, `stale_reference`); `operator_2_5d_review.py::family()` reads nonexistent `coverage`, `stale`; `ui/service.py::review_family()` passes actual browser records to that adapter; `operator_2_5d_review_smoke.py` instead uses `SimpleNamespace(coverage=..., stale=...)`. Read-only external count snapshot reported as `/tmp/WB25-5-counts.json` on the reporting host (not a checked-in or transferable artifact); current review provenance is the clean WB25-4 correction re-review, not its superseded findings review.
- Task-specific authority: v2 plan for author-ranked families/directions/layers/frame fields; `operator_animation_targets.target_families()/project_targets()` for target/coverage/workflow/staleness; `Operator2DReview.current_receipt()` (NOT cached persisted `runtime_verified`) and `family()` for QA, human provenance, sandbox and effective verification; canonical Operator profile/reference for brief inputs. Only WB25-6 may assert PUBLISHED after actual runtime promotion; accepted source, CANONICAL_2_5D, or RUNTIME_VERIFIED do not imply publication.
- Work surface: bounded WB25-4 family-record adapter fix in `custodian/tools/operator/operator_2_5d_review.py::family()`; real-record and `WorkbenchService.review_family()` smoke in `custodian/tools/validation/operator_2_5d_review_smoke.py` (plus new WB25-5 queue smoke); recommended focused `custodian/tools/operator/operator_generation_brief.py` and pure queue projector if needed; `ui/service.py`, `app.py`, `plan_table.py` or `queue_table.py`; smallest existing `operator_2_5d_ingress.py` adapter for returned brief correlation; active docs only when behavior actually lands. Do not add a second review authority or introduce aliases solely to placate outdated mock fixtures.
- Change:
  1. Filters at least NEXT, MISSING, INTAKE, EDITING, REVIEW, STALE, FALLBACK/PROJECTED, PUBLISHED, VERIFIED, ALL.
  2. Preserve authored rank/priority/state. Computed workflow never rewrites plan order.
  3. NEXT may skip a blocked item only with a deterministic visible reason.
  4. Show family completion by required canonical directions/layers. Legacy/fallback/projected never count.
  5. Family-close preference may choose directions within the same equal-priority/equal-rank family; it must not reorder separately ranked families. Expose the reason and any skipped blocked target.
  6. Before constructing family/queue metrics, correct `Operator2DReview.family()` to consume the actual `AnimationRecord.coverage_status` and `.stale_reference` fields (plus existing `.workflow_status`). Use exact current `current_receipt()` evidence; do not add duplicate compatibility aliases, call through fabricated `coverage`/`stale` wrappers, swallow adapter errors as zero progress, or rewrite the underlying schema. Family completion must match the full required direction/layer set from the current plan, not merely the nonempty subset of records presented.
  7. Queue totals reconcile exactly to target projection and review receipts. No independent stored progress counters.
  8. Queue/tree/matrix select the same authoring identity.
  9. Export Generation Brief creates a local immutable bundle under .ai/operator_animation_workbench/generation_briefs/<brief-id>/.
  10. Bundle minimum:
     - manifest.json;
     - PROMPT.txt;
     - exact canonical direction reference;
     - adjacent direction references when useful;
     - profile/registration guide overlay;
     - semantic/art-generation/profile/reference SHA;
     - required frame/layer/timing contract;
     - accepted motion donor/sequence context when available;
     - relevant presentation event metadata;
     - target identity/hash for re-association.
  11. Export is deterministic for identical target authority/hashes and fails stale if profile/reference/plan changes.
  12. No network/image-generation API call. The user/agent may take PROMPT + refs to an external generator manually.
  13. Add an optional exact brief identity/hash validation adapter to the EXISTING WB25-2 ingress seam for returned art. Filename alone is never authority; existing valid unbriefed import stays supported.
  14. Supersede OPERATOR_WORKBENCH_UX_WORK_QUEUE.md as migration queue authority without deleting unrelated historical UX guidance.
- Preserve: plan human priority authority; target/review state ownership; legacy browser; Workbench publication; local-only generated briefs.
- Non-goals: no autonomous generation; no plan mutation; no background workers; no runtime cutover; no legacy deletion; no broad UX restyle.
- Acceptance: Queue totals equal 69/552 tracked plan projection, and the observed 0/0 current verification baseline is reported truthfully for the specified authoring workspace without inventing global zero; NEXT is reproducible; fallbacks/accepted source cannot appear verified; family projection works on real `AnimationRecord` values from `WorkbenchService.review_family()` and on sparse/missing-input controls without `AttributeError`; family closure matches the full required plan directions/layers and current verified receipts. Verify the original 96×96 five-frame east legacy idle never masquerades as the 128×128 15-frame 2.5D accepted-source target. Generation brief for canonical idle retains correct profile/reference/contract hashes and repeats byte-stably; stale authority refuses export and returned source re-associates to the same exact target.
- Validation: first update `operator_2_5d_review_smoke.py` with **actual `AnimationRecord`** objects from `ui.state` (not mock `coverage`/`stale` fields), plus an end-to-end `WorkbenchService.review_family()`/`project_targets()` fixture to prove no adapter exception, exact directions, and fail-closed missing/stale/forged receipt behavior. Preserve the existing adversarial WB25-4 approval suite. Next run focused queue/brief smokes for 69/552 baseline, 0/0 observed provenance (not hardcoded), rank NEXT, accepted-source-vs-legacy negative controls, complete family directions, bundle idempotency/stale/path validation, source re-association and UI identity; register new validation owners. Rerun existing target/ingress/review/Workbench UI smokes where touched, then --changed and git diff --check.
- Task overrides: none
- Deferred: runtime cohort promotion; actual art-production automation/network generation.

## 2026-10-10 Count Probe + Family Adapter Findings

- Read-only report provenance: review logic at `CUSTODIAN@ff7d3aec`, populated authoring checkout `CUSTODIAN-operator-art@c463a1cf` (then 745 commits behind), both reported clean. The external probe JSON was written to `/tmp/WB25-5-counts.json` on that machine, but that absolute temporary path is not repository evidence and need not be present in the Codex worktree. Recreate its numbers with read-only calls at implementation start; never copy transient JSON to tracked source, manufacture receipts, or mutate either checkout just to count.
- Baseline observation: `69 / 552` planned families/directions, `4 P0 / 65 P1`, `1` canonical source accepted but not intaken, `1 / 68` resolved/unresolved frame contracts, `0 / 0` effective current receipt-verified directions/families, `0` actual 2.5D workspace manifests, `0` current receipts, `0` sandbox passes **in the sampled authoring workspace**. Ignore local legacy publishing hints for verification.
- Disambiguation: `unarmed/posture/idle_relaxed_01` plans `8 × 15f @ 128×128` direction targets and an accepted canonical source; the *observed workspace* still has an old `e` Workbench document at `5f @ 96×96`. Neither that document nor the plan's `canonical_2_5d` migration verdict constitutes validated WB25-2 intake, saved 128px direction workspaces, WB25-4 receipt verification or WB25-6 publication.
- **Pre-queue correctness fix, within this packet**: `Operator2DReview.family()` references `record.coverage` and `record.stale`; current `ui.state.AnimationRecord` produced by `operator_animation_targets.project_targets()` exposes `coverage_status` and `stale_reference`. `WorkbenchService.review_family()` passes real browser records, so the review-panel family path presently raises `AttributeError`. Previous `operator_2_5d_review_smoke.py` used `SimpleNamespace` fixtures with the nonexistent names and falsely passed. Correct the consumer to the existing record contract before WB25-5 queue relies on family completeness, and replace synthetic fixtures with actual record objects; keep the clean WB25-4 approval gate and receipt validation unchanged.
- **Fail-closed measurement**: inability to access the local authoring workspace or a family projection exception is a diagnostic `UNAVAILABLE / ERROR` state, not verified `0`. A sampled genuine zero requires a successful live projection + effective `current_receipt()` checks. Incomplete supplied family leaves cannot report a completed family even if all *visible* leaves are verified.
- WB25-5 stays `ready/auto` because the bounded adapter change and tests are fully specified and own no new user design decision. This finding does **not** reactivate archived WB25-4 correction, greenlight the art, or initiate a claim.

## Locked Refresh Decisions (2026-10-10)

- **Baseline arithmetic**: exactly 69 distinct 2.5D plan family entries and 552 required direction targets in the tracked v2 plan; eight accepted *source* directions (one family) and 544 baseline not-authored target directions. These are audit/plan provenance, not a computed current count of ingested files or verified receipts. Re-measure effective coverage, workflow, stale, verified and family closure dynamically against the executing checkout/workspace. Display both provenance and current-live metrics explicitly, never coerce an unavailable live count to zero.
- **One authority**: first reconcile `family()` against real `AnimationRecord` fields, then build the dashboard as a derived join of plan families, `project_targets()` leaves and `current_receipt()`/`family()` results. Receipt SHA and `runtime_verified` from stored JSON alone never count. No counter DB, no second QA/human-review policy. `NEEDS_HUMAN_REVIEW` without exact backend-authored Workbench approval bound to current evidence stays unverified; RED is blocked even with approval; GREEN/YELLOW retain the no-approval path. Stale/forged/missing receipt input is unverified.
- **Progress semantics**: separate plan `state` and priority/rank, source/coverage status, workspace workflow, QA/human state, current sandbox verification, and later runtime publication. Treat source-accepted idle as authorable/intake-pending, not reviewed, verified or published. Family closure is derived from ALL required canonical direction/layer leaves being nonstale and effectively runtime-verified; use the existing review family owner, with no competing completion formula. Fallback, projected, partial or a merely accepted 8-direction source never close a family.
- **NEXT precedence**: order by plan priority tier (P0 ahead of P1), then ascending authored `rank`, then stable canonical identity. Expose the higher-priority blocked target(s) and deterministic skip reason whenever NEXT advances; never mutate plan rank/priority. Family-close preference applies only to direction choices *within the same family* at the same authored priority/rank, never between differently ranked families. Display the reason and current necessary action.
- **Filters**: NEXT, MISSING, INTAKE, EDITING, REVIEW, STALE, FALLBACK/PROJECTED, VERIFIED, PUBLISHED, ALL. Diagnostic filters may overlap; use unique target identities for totals and separate disjoint primary-coverage breakdowns. Until a real WB25-6 publication authority exists, PUBLISHED is empty/not-yet-supported, not inferred. All views share an identical generation-aware target selection.
- **Generation brief**: generate an immutable local content-addressed bundle under `.ai/operator_animation_workbench/generation_briefs/<brief-id>/` from canonical serialization of exact target identity, current required contract, plan fingerprint, profile/reference and included donor/sequence hashes. Stable input means byte-identical manifest, prompt, copied reference assets and id across repeated exports. No timestamps or nondeterministic ordering in signed contents. Never overwrite an existing same-id bundle whose bytes differ.
- **Bundle contract**: manifest.json, PROMPT.txt, exact direction reference and useful existing adjacent references, current registration/profile instructions/overlay if available, plan/profile/reference/bundled-file SHA-256, target identity + re-association digest, required directions/layers, exact frame canvas/count/loop/FPS/durations where authoritative, optional motion donors and presentation event metadata only when actually present. Validate file paths within permitted authority roots, actual source hashes, clean alpha and direction applicability. Mark unavailable optional context explicitly; never invent it.
- **Unknown frames/timing**: live plan includes rows with frame count, FPS and loop set null. Such fields remain UNKNOWN until an accepted per-target contract exists. Do not invent a 15-frame or 8-fps default for other actions; export can be a planning brief clearly marked non-generation-ready, or refuse generation-ready export for a required unknown field. Rank-1 unarmed relaxed idle is an explicit positive fixture: 15 frames, each 128x128, loop true, FPS null.
- **Staleness/security**: fail closed if target, profile, canonical reference, plan or bundled input bytes change during generation; prevent path traversal and symlink escape; hash content actually copied; clean an incomplete temp folder on error; publish only an atomically complete bundle. A stale or tampered existing bundle cannot be reused as current.
- **Inbound correlation**: returned art must traverse the existing WB25-2 Source Session/ingress authority (then Asset Pipeline V2 as applicable), not a new ingestion or runtime route. Add a bounded optional brief-id + hash + manifest check at that ingress seam: exact generation/profile/group/action/direction and source lineage must match. Reject wrong-direction, stale, forged and mismatched bundles; keep legitimate existing unbriefed imports/legacy workflows working. Filename is never provenance.
- **UX4 disposition**: supersede OPERATOR_WORKBENCH_UX_WORK_QUEUE.md only as a competing 2.5D migration queue; retain unrelated hierarchy/UX guidance, do not delete UX history. No broad Workbench redesign, autonomous generator, network call, stored progress service, publication or runtime selector changes.

### Focused falsification

Test (a) 69 families/552 leaves, one resolved frame contract/68 unresolved, and 8 accepted-source/544 baseline-un-authored provenance; (a2) real `AnimationRecord`/`review_family()` integration, no `AttributeError`, and a missing family leaf prevents closure; (b) live receipts and staleness separate from plan counts, (c) priority/rank NEXT with visible skipped blocker, (d) family closure and fallback/partial/accepted-source/RED/unapproved/forged-receipt negative controls, (e) all filters and tree/matrix/queue selection identity, (f) deterministic 15f 128x128 idle brief with null FPS preserved, (g) missing frame/unknown FPS non-fabrication, (h) double export byte stability, (i) stale input, malicious path, tampered bundle and overwrite refusal, and (j) re-association through existing ingress with invalid-brief rejection and unbriefed import compatibility. Add focused queue + generation-brief validation owners to the current manifest, run existing target/ingress/review/UI smokes where touched, changed validation and git diff --check.

### Promotion gate

Planning refresh and exact current-chat backlinks were resolved on 2026-10-10. Before any claim, the paired authoring validator, README managed index, and fetched origin/main/dispatcher gates must pass; WB25-6 stays draft/refresh-required until WB25-5 + paired review pass and real cohort evidence exists.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: intentionally-preserved
- Evidence: Live queue reports 69 families / 552 planned direction leaves and preserves plan rank/priority; sampled workspace counts remain provenance-scoped. Real-record review-family integration, generation brief identity/hash validation through WB25-2 ingress, unknown-contract preservation, deterministic bundle checks, and queue/UI identity have focused passing regressions. The changed-file run passed 36/36 with complete coverage; focused checks are recorded in the closing summary.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Shared Godot validation lock was contended by concurrent changed-file sweeps from other worktrees; two queued attempts were stopped and checks passed after serialization. The standalone validation owner was initially mistyped during selection, and a malformed one-line EDITING-filter expression was caught by py_compile and corrected before final validation.
- Root cause / contributing factors: Multiple independent worktrees launched repository-wide validation concurrently against the shared Godot project lock; a compact filter expression obscured bracket structure.
- Prevention / pipeline improvement: Serialize Godot-backed validation across worktrees, select tests by exact manifest IDs, and keep edited Python expressions multiline before compiling.
- Tooling / docs drift discovered: The supplied count-probe script was unavailable in this checkout; counts were remeasured from live plan/projection authority and the unavailable legacy browser projection is reported diagnostically, never as verified zero.
- Follow-up: review-operator-2-5d-workbench-production-queue
- What worked: Focused queue/brief falsification, current receipt authority reuse, and exact brief correlation through existing ingress.

## Recommended brief manifest

~~~json
{
  "schema": "custodian.operator_generation_brief.v1",
  "brief_id": "...",
  "target": {
    "art_generation": "operator_2_5d_128",
    "profile": "unarmed",
    "group": "posture",
    "action": "idle_relaxed_01",
    "direction": "ne",
    "layer": "full_body"
  },
  "frame_contract": {"frames": 15, "frame_size": [128,128], "loop": true, "fps": null},
  "canonical_profile_sha256": "...",
  "canonical_reference_sha256": "...",
  "plan_fingerprint": "...",
  "motion_donor": {"identity": "...", "sha256": "..."}
}
~~~

## Refresh Planning Authority

- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Refresh instruction: Refreshed again in this same authoring chat after a read-only 0/0 current-VERIFIED sample exposed the `Operator2DReview.family()`/`AnimationRecord` adapter mismatch. Fix the adapter and its false-positive mock smoke **inside WB25-5** before queue integration; remeasure live ignored-workspace counts. The checkouts and ephemeral `/tmp` JSON are observation provenance only; no fresh human planning decision or WB25-4 re-claim is necessary.

## Handoff

- Next workstream: review-operator-2-5d-workbench-production-queue
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acaa3ac-a358-83e8-ace1-c21ad7ab3e38
- Summary backlink: include exact Authoring chat URL
- Refresh reason: none after refresh/implementation
- Next action: paired review
- Blockers or open questions: none after publication and dispatcher preflight

## Independent Review

- Status: `passed`
- Review workstream: `review-operator-2-5d-workbench-production-queue`
- Reviewed on main: `d4efc0234` (implementation commit `69cdfdbf1`)
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `none`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_OPERATOR_2_5D_WORKBENCH_PRODUCTION_QUEUE_CLAUDE_SUMMARY.md`
- Follow-up workstream: `none`
