# OPERATOR 2.5D WORKBENCH PRODUCTION QUEUE + GENERATION BRIEFS

> PRE-AUTHORED / REFRESH REQUIRED BEFORE IMPLEMENTATION  
> Refresh after the WB25-4 R0-01 correction + fresh paired re-review land. Consume only the accepted final target/review state; do not invent another progress database.

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
- Reviewed main: e56a75cfb76cdb5a3a430b21be267b1b4e20ed6e
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Visual review: none
- Goal: Turn the landed 2.5D target/workflow/review state into an honest production queue and deterministic generation-brief exporter so the next animation to author is obvious and returned source-work can re-associate with the exact target.
- Completion boundary: Add queue/dashboard projections, progress/family closure, NEXT explanation, filters, and local generation-brief bundles. Preserve human plan rank/priority. No network generation and no production runtime cutover.
- Current measured state: PlanTable exists and OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json owns rank/priority; WB25-4 implementation is landed but its first paired review found blocking R0-01 in required-human approval truth. Cycle-1 correction/re-review now gate the final accepted receipt contract. Workbench still has no generation-aware production queue or source-generation brief bundle; exact final verified counts must be re-measured only after that correction lineage passes.
- Evidence: custodian/tools/operator/ui/widgets/plan_table.py; custodian/tools/operator/ui/service.py; design/02_features/animation/OPERATOR_ANIMATION_IMPLEMENTATION_PLAN.json; landed target/review receipts after dependency.
- Task-specific authority: v2 implementation plan for rank/priority; target projection for coverage/workflow; only current receipts accepted under the clean WB25-4 correction re-review for review/RUNTIME_VERIFIED truth; canonical reference/profile for brief input. `PUBLISHED` remains a separate later authority and must not be inferred from review verification.
- Work surface: recommended custodian/tools/operator/operator_generation_brief.py; ui/service.py; app.py; plan_table.py or recommended queue_table.py; target/review owner modules from predecessors; roadmap/current-state docs where live behavior changes.
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
  "frame_contract": {"frames": 15, "frame_size": [128,128]},
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
- Refresh instruction: Bring the WB25-4 correction + fresh re-review receipt and live target/review counts to this chat. Re-derive final queue fields/counts, NEXT tie-break, brief inputs, old UX4 disposition and tests before ready. Do not refresh from the original WB25-4 findings review.

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
