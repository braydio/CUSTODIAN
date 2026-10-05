# AGENT CORRECTION PACKET TEMPLATE

Use this V2 delta packet only for correction-worthy findings from an
independent post-land review. Pair it with a review packet using
`AGENT_REVIEW_PACKET_TEMPLATE.md`. Keep the correction narrower than the
parent implementation slice and cite the exact stable review finding IDs.

# CORRECTION: [PARENT IMPLEMENTATION / REVIEW]

- Packet schema: `custodian.task_packet.v2`
- Workstream: `<parent-id>-review-corrections-<cycle>`
- Status: `draft`
- Dispatch: `auto`
- Priority: `<P0 | P1 | P2 | P3>`
- Depends on: `<parent-review-workstream>`
- Locks: `<relevant locks or none>`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `<focused modes>`
- Paired review workstream: `review-<parent-id>-review-corrections-<cycle>`
- Review cycle: `<positive cycle number>`
- Max automatic review cycles: `<inherited cap>`
- Reviewed main: `<SHA where this correction contract was verified>`
- Parent implementation: `<implementation workstream and canonical archived packet path>`
- Parent review: `<review workstream and canonical archived packet path>`
- Findings addressed: `<full IDs, for example R0-02, R0-04>`
- Affected acceptance: `<exact original acceptance claim(s) affected>`
- Current defect/evidence: `<confirmed defect or proof gap, with source evidence>`
- Goal: `<specific corrected outcome>`
- Completion boundary: `<smallest correction boundary that resolves the cited findings>`
- Current measured state: `<live defect/proof state>`
- Evidence: `<review finding records and additional focused evidence>`
- Task-specific authority: `<parent authority plus any proven correction authority>`
- Work surface: `<specific implementation owner, consumers, and tests>`
- Required correction: `<observable behavior/proof that changes to resolve each cited finding>`
- Preserve: `<neighboring behavior and authority that must remain intact>`
- Non-goals: `<scope intentionally excluded>`
- Acceptance: `<falsifiable result for every finding ID>`
- Validation: `<focused regressions first; broader closeout checks>`
- Task overrides: `none` or exact justified task-specific exception
- Deferred: `<non-blocking findings deliberately left for later>`

## Delta Rules

- Address only the listed finding IDs. Do not reopen accepted parent scope or
  redesign the feature.
- Each acceptance item maps to one or more `Findings addressed` IDs.
- Keep the original review receipt and IDs stable. The paired re-review reports
  each addressed finding as `fixed`, `unresolved`, or `regressed`; genuinely
  new findings use the current review cycle's next ID.
- If the maximum automatic review cycle is exhausted with correction findings
  still unresolved, stop the loop with `human_required` and name the exact
  decision or missing evidence.

## Execution Feedback

Complete the standard `custodian.task_feedback.v1` receipt before marking this
packet complete. Use the fields and semantics in
`AGENT_TASK_PACKET_TEMPLATE.md`.