# OPERATOR 2.5D WORKBENCH PRODUCTION QUEUE + GENERATION BRIEFS

> PLANNING REFRESH CANDIDATE (2026-10-10; main@cee646f2)  
> WB25-4 R0-01 correction + fresh re-review complete/passed. Live API and tracked counts were reconciled below. **Keep draft/manual pending updated authoring-chat backlink, paired authoring preflight, queue-index regeneration and main publication.** Never claim the WB25-4 correction again.

- Packet schema: custodian.task_packet.v2
- Workstream: operator-2-5d-workbench-production-queue
- Status: draft
- Dispatch: manual
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
- Reviewed main: cee646f21e5a6dc6fb4cc487f8ec04043c683259
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none
- Goal: Turn the landed 2.5D target/workflow/review state into an honest production queue and deterministic generation-brief exporter so the next animation to author is obvious and returned source-work can re-associate with the exact target.
- Completion boundary: Add queue/dashboard projections, progress/family closure, NEXT explanation, filters, and local generation-brief bundles. Preserve human plan rank/priority. No network generation and no production runtime cutover.
- Current measured state (tracked baseline on 2026-10-10): live v2 plan holds **69 target families/552 required direction leaves**: 1 accepted canonical source family (8 direction-source leaves, awaiting intake), 68 un-authored families (544 direction leaves). Four of the 69 target families have P0 priority and 65 P1. These are SOURCE/PLAN figures, not verified/prod-published counts. Ignored local `.ai/` receipts/sessions are not tracked on GitHub; live VERIFIED and workflow totals are unmeasured here, never presumed zero. `PlanTable` already shows plan coverage; `Operator2DReview.current_receipt()` and `family()` already own effective review/verification. There is still no generation queue/brief exporter. WB25-6 separately owns PUBLISHED.
- Evidence: design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json (v2 audit_summary and 69 rows/552 directions); custodian/tools/operator/operator_animation_targets.py (`target_families`, `project_targets`); custodian/tools/operator/operator_2_5d_review.py (`current_receipt`, `family`, `human_review_evidence_sha`); custodian/tools/operator/ui/service.py (generation target/browser projection); REVIEW_OPERATOR_2_5D_WORKBENCH_REVIEW_AUTOMATION_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md (independent R0-01 fix confirmation).
- Task-specific authority: v2 plan for author-ranked families/directions/layers/frame fields; `operator_animation_targets.target_families()/project_targets()` for target/coverage/workflow/staleness; `Operator2DReview.current_receipt()` (NOT cached persisted `runtime_verified`) and `family()` for QA, human provenance, sandbox and effective verification; canonical Operator profile/reference for brief inputs. Only WB25-6 may assert PUBLISHED after actual runtime promotion; accepted source, CANONICAL_2_5D, or RUNTIME_VERIFIED do not imply publication.
- Work surface: recommended focused custodian/tools/operator/operator_generation_brief.py and a small pure queue projector if needed; ui/service.py, app.py, plan_table.py or a focused queue_table.py; smallest existing operator_2_5d_ingress.py/source-session adapter to link returned brief identity; focused validation modules; active roadmap/current state only for actual behavior changes. No queue/review authority embedded in widgets.
- Change:
  1. Filters at least NEXT, MISSING, INTAKE, EDITING, REVIEW, STALE, FALLBACK/PROJECTED, PUBLISHED, VERIFIED, ALL.
  2. Preserve authored rank/priority/state. Computed workflow never rewrites plan order.
  3. NEXT may skip a blocked item only with a deterministic visible reason.
  4. Show family completion by required canonical directions/layers. Legacy/fallback/projected never count.
  5. Equal-priority family-close tie-break may prefer finishing a nearly complete family, but must expose the reason and may not jump a higher authored priority/rank.
  6. Queue totals reconcile exactly to target projection and review receipts. No independent stored progress counters.
  7. Queue/tree/matrix select the same authoring identity.
  8. Export Generation Brief creates a local immutable bundle under .ai/operator_animation_workbench/generation_briefs/<brief-id>/.
  9. Bundle minimum:
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
  10. Export is deterministic for identical target authority/hashes and fails stale if profile/reference/plan changes.
  11. No network/image-generation API call. The user/agent may take PROMPT + refs to an external generator manually.
  12. When returned art is imported, WB25-2 uses brief identity/hash to associate it; filename alone is never authority.
  13. Supersede OPERATOR_WORKBENCH_UX_WORK_QUEUE.md as migration queue authority without deleting unrelated historical UX guidance.
- Preserve: plan human priority authority; target/review state ownership; legacy browser; Workbench publication; local-only generated briefs.
- Non-goals: no autonomous generation; no plan mutation; no background workers; no runtime cutover; no legacy deletion; no broad UX restyle.
- Acceptance: queue totals equal target projection exactly; NEXT is reproducible; fallback remains incomplete; family completion agrees with matrix; a generation brief for a test idle target contains correct reference/profile/frame hashes and is byte-stable on repeated export; stale authority refuses export; imported source can resolve back to the same target using manifest identity.
- Validation: focused reconciliation/count invariants, blocked NEXT, fallback negative control, family completion, brief idempotency/hash, stale export, target re-association, queue/tree/matrix identity; operator_workbench_ui_smoke.py as needed; changed validation + git diff --check.
- Task overrides: none
- Deferred: runtime cohort promotion; actual art-production automation/network generation.

## Locked Refresh Decisions (2026-10-10)

- **Baseline arithmetic**: exactly 69 distinct 2.5D plan family entries and 552 required direction targets in the tracked v2 plan; eight accepted *source* directions (one family) and 544 baseline not-authored target directions. These are audit/plan provenance, not a computed current count of ingested files or verified receipts. Re-measure effective coverage, workflow, stale, verified and family closure dynamically against the executing checkout/workspace. Display both provenance and current-live metrics explicitly, never coerce an unavailable live count to zero.
- **One authority**: build the dashboard as a derived join of plan families, `project_targets()` leaves and `current_receipt()`/`family()` results. Receipt SHA and `runtime_verified` from stored JSON alone never count. No counter DB, no second QA/human-review policy. `NEEDS_HUMAN_REVIEW` without exact backend-authored Workbench approval bound to current evidence stays unverified; RED is blocked even with approval; GREEN/YELLOW retain the no-approval path. Stale/forged/missing receipt input is unverified.
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

Test (a) 69 families/552 leaves and 8 accepted-source/544 baseline-un-authored provenance, (b) live receipts and staleness separate from plan counts, (c) priority/rank NEXT with visible skipped blocker, (d) family closure and fallback/partial/accepted-source/RED/unapproved/forged-receipt negative controls, (e) all filters and tree/matrix/queue selection identity, (f) deterministic 15f 128x128 idle brief with null FPS preserved, (g) missing frame/unknown FPS non-fabrication, (h) double export byte stability, (i) stale input, malicious path, tampered bundle and overwrite refusal, and (j) re-association through existing ingress with invalid-brief rejection and unbriefed import compatibility. Add focused queue + generation-brief validation owners to the current manifest, run existing target/ingress/review/UI smokes where touched, changed validation and git diff --check.

### Promotion gate

Only after the new chat's precise URL is supplied and updated in implementation/review packets: run paired `validate_task_packet_authoring.py`, promote both packets to ready/auto if clean, rerun authoring validation, regenerate and verify task-packet README index, safely land scoped files on origin/main, verify fetched headers/dispatcher eligibility and only then claim WB25-5. Keep WB25-6 draft/refresh-required until WB25-5 + paired review pass and real cohort evidence exists.

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

- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh instruction: Design/content re-derivation done on 2026-10-10 against main@cee646f2 and accepted WB25-4 correction review. The tracked baseline 69/552/8/544 was measured; ignored local receipts are computed at execution, not guessed. Capture this chat's new authoring URL, update BOTH packet backlinks, run paired authoring preflight, reconcile any concurrent main changes and promote through the repository workflow. Do not use the superseded original WB25-4 findings review.

## Handoff

- Next workstream: review-operator-2-5d-workbench-production-queue
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include exact Authoring chat URL
- Refresh reason: none after refresh/implementation
- Next action: paired review
- Blockers or open questions: packet must be refreshed before claim
