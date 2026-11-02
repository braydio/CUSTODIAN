# REVIEW TRANSIT LIFT RUNTIME FOUNDATION V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-transit-lift-runtime-foundation-v1`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `transit-lift-runtime-foundation-v1`
- Locks: `local-transit-lift, awakening-interaction`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, runtime, architecture`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `fresh-context falsification of reusable local lift lifecycle and Awakening compatibility`
- Review target workstream: `transit-lift-runtime-foundation-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/TRANSIT_LIFT_RUNTIME_FOUNDATION_V1.md`
- Reviewed main: `<fill at claim>`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Prove the extracted local lift is genuinely reusable/cancellation-safe and Awakening has no duplicate or stale transit authority.
- Completion boundary: Reconstruct the landed implementation from main, inspect actual changed owners rather than trusting its summary, run the focused falsification set, and record findings-first disposition.
- Current measured state: Reconstruct from landed main and the archived implementation packet/closing summary.
- Evidence: landed B1 summary/diff, dedicated lift lifecycle smoke, Awakening progression/affordance regressions.
- Task-specific authority: new local-transit owner owns station/cycle state; Operator owns its public control lock seam; AwakeningLayout owns geography; LevelLoader/RouteTraversalManager remain separate transition authorities.
- Work surface: landed implementation files, directly affected tests, and only bounded review artifacts authorized below.
- Change:
  1. Force cancel/reset/tree-exit/actor-free during active phases and prove exactly-once unlock plus no stale station mutation.
  2. Instantiate a 3-station generic fixture independent of Awakening and prove stable station identity/selection.
  3. Inspect Awakening compatibility: same node path, one interactable owner, two affordance mounts, station positions and public signals; prove route-transition lifts were not absorbed.
- Preserve: Awakening progression, Locker→Dust→Undergate route, station positions, one lift gameplay owner, affordance parity, persistent Operator identity, route-transition systems and existing Asset V2 lift families.
- Non-goals: no redesign, unrelated cleanup, preference tuning, or implementation edits inside the review workstream.
- Acceptance:
  1. Generic fixture and production Awakening both satisfy lifecycle/compatibility contracts without stranding control or duplicating authority.
  2. Negative controls fail for the intended reason; no passing fixture is vacuous or presentation-only where runtime behavior is claimed.
  3. No blocking defect or material evidence gap remains.
- Validation: local lift lifecycle + Awakening progression + affordance contract + affected connection geometry + changed-file validation + `git diff --check`.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
- Deferred: Visual/game-feel polish remains the existing `awakening-interactible-locker-lift-presentation-v1`, refresh-gated after B1 review.

## Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Refresh reason: `draft/manual only while automatic authoring handoff validates/promotes this pair; do not manually claim before that succeeds`
- Next action: `If PASS, materially refresh the existing Awakening locker/lift presentation workstream from the landed reusable API.`
- Blockers or open questions: `implementation dependency only`
