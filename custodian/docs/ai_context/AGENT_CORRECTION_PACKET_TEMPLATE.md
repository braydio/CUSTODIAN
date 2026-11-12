# AGENT CORRECTION PACKET TEMPLATE

> Retired paired review: use this V2 delta packet only for a confirmed
> defect or proof gap found by focused validation or by the owner. Do not
> pair it with a review packet — paired review was retired 2026-11-12.
> Keep the correction narrower than the parent implementation slice and
> cite the exact defect/evidence it fixes.

Use the exact parent implementation category in `- Category:` after Workstream.
Read `TASK_PACKET_CATEGORIES.json` and check this header before publication.

# CORRECTION: [PARENT IMPLEMENTATION / REVIEW]

- Packet schema: `custodian.task_packet.v2`
- Workstream: `<parent-id>-review-corrections-<cycle>`
- Category: `<choose-id-from-TASK_PACKET_CATEGORIES.json>`
- Status: `draft`
- Dispatch: `auto`
- Priority: `<P0 | P1 | P2 | P3>`
- Depends on: `<parent implementation workstream>`
- Locks: `<relevant locks or none>`
- Kind: `correction`
- Review: `none`
- Review stage: `post-land`
- Review modes: `none`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `<full 40-character immutable main commit SHA>`
- Parent implementation: `<implementation workstream and canonical archived packet path>`
- Parent review: `none (paired review retired 2026-11-12)`
- Findings addressed: `<defect/evidence IDs, for example R0-02, R0-04, or none>`
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
- If a correction still leaves findings unresolved, stop with a human decision
  and name the exact decision or missing evidence. There is no automatic
  re-review cycle.

## Execution Feedback

Complete the standard `custodian.task_feedback.v1` receipt before marking this
packet complete. Use the fields and semantics in
`AGENT_TASK_PACKET_TEMPLATE.md`.