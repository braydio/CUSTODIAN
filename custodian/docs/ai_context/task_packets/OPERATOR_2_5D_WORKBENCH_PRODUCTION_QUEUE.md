# OPERATOR 2.5D WORKBENCH PRODUCTION QUEUE

> **PRE-AUTHORED / REFRESH REQUIRED BEFORE IMPLEMENTATION**
>
> Refresh after WB25-3 + paired review land. Consume landed state; do not invent
> another progress database.

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-2-5d-workbench-production-queue`
- Status: `draft`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-operator-2-5d-workbench-review-automation`
- Locks: `operator-workbench-ui, operator-animation-plan`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-operator-2-5d-workbench-production-queue`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `f8ef4c84adf8f332713d4284a4c3aaa89ef51fb0`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Visual review: `none`
- Goal: Turn the landed 2.5D target state into an honest production queue/dashboard with next-action guidance and deterministic generation-brief export while preserving the human-authored plan as priority authority.
- Completion boundary: Migration-aware queue over target/ingress/review state; progress/family closure; filters; next-action explanation; generation-brief bundles; close roadmap. No production runtime cutover.
- Current measured state: pre-authored; exact target counts/state await WB25-1..3.
- Evidence: refresh with live target plan, state projection, review receipts, old UX4.
- Task-specific authority: implementation plan for rank/priority; target projection for coverage/workflow; review receipts for verified state; canonical reference for generation brief.
- Work surface: Queue/Plan UI; service/state projection; Operator generation-brief exporter; roadmap/docs; focused UI/export tests.
- Change:
  1. Filters at least `NEXT, MISSING, INTAKE, EDITING, REVIEW, STALE, FALLBACK/PROJECTED, PUBLISHED, VERIFIED, ALL`.
  2. Preserve authored rank/priority/state. NEXT may skip blocked work only with explanation and may not rewrite the plan.
  3. Show family completion by canonical required directions/layers; fallback/projected never counts.
  4. Family-close tie-break may operate only inside equal authored priority/rank semantics and must expose its reason.
  5. Show stage/priority totals and truthful remaining-work count.
  6. Queue cell selects same identity as tree/matrix.
  7. `Export Generation Brief` bundles canonical direction reference, landmarks/guide overlay, semantic/generation/profile/reference SHA, required layer/frame/timing contract, adjacent reviewed poses/sequence context, relevant presentation event metadata, and concise `PROMPT.txt`/structured brief.
  8. Export is local only: no network/image-generation call and no auto-ingest.
  9. Brief hashes/identity allow returned art to re-associate with exact target leaf.
  10. Stale/blocked packages are separate from missing-art counts.
  11. Supersede `OPERATOR_WORKBENCH_UX_WORK_QUEUE.md` as queue/coverage authority.
  12. Update roadmap with live remaining counts and recommend first production art tranche; do not author runtime cutover.
- Preserve: plan order authority, target/ingress/review state ownership, publication safety, legacy browser.
- Non-goals: autonomous plan mutation, background workers, network generation, runtime cutover, legacy deletion, broad UX polish.
- Acceptance: queue totals exactly reconcile to target projection; no contradictory terminal states; fallback remains incomplete; NEXT explanation reproducible; generation brief correct and stale-safe; tree/matrix/queue identity equivalent; old UX4 cannot claim as competing queue.
- Validation: refresh exact tests; minimum reconciliation/count invariants, blocked NEXT, fallback negative control, brief hash/idempotency, stale-export refusal, identity equivalence, `git diff --check`.
- Task overrides: `none`
- Deferred: production runtime cutover, actual art production packets, later UX polish.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Refresh instruction: `Bring WB25-3 + review evidence and current target counts. Re-derive queue fields, completion math, NEXT tie-breaks, generation-brief inputs, UX4 disposition and validation before ready.`

## Handoff
- Next workstream: `review-operator-2-5d-workbench-production-queue`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Summary backlink: include exact Authoring chat URL
- Refresh reason: `none after refresh`
- Next action: `paired review, then return to this chat for art-production/runtime planning`
- Blockers or open questions: `packet must be refreshed before claim`
