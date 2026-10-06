# OPERATOR 2.5D WORKBENCH REVIEW AUTOMATION

> **PRE-AUTHORED / REFRESH REQUIRED BEFORE IMPLEMENTATION**
>
> Refresh after WB25-2 + paired review land.

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-2-5d-workbench-review-automation`
- Status: `draft`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-operator-2-5d-workbench-ingress`
- Locks: `operator-workbench-ui, operator-art-agent, operator-review-automation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow, visual`
- Paired review workstream: `review-operator-2-5d-workbench-review-automation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `f8ef4c84adf8f332713d4284a4c3aaa89ef51fb0`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Visual review: `conditional`
- Goal: Make canonical anti-drift checks, sequence/transition review and a non-production runtime sandbox proof one guided review path so 2.5D art can be accepted quickly.
- Completion boundary: Project canonical visual-contract QA into Workbench; harden stale-reference guards; add plan-driven review sequences and one-click family/chain review; add debug runtime proof for selected 2.5D art without production cutover. Do not create new measurement authorities.
- Current measured state: pre-authored. Canonical visual contract should expose structured QA; REVIEW/SEQUENCE/MOTION already exist. Exact ingress state awaits refresh.
- Evidence: refresh with current canonical QA, Timeline/transition/Motion, WB25-2 receipts.
- Task-specific authority: canonical visual-contract measurements; existing Preview/Timeline/Motion; Workbench session state; gameplay timing/contact data.
- Work surface: UI state/service; review/sequence controls; QA projection; debug motion/runtime request path; focused UI/preview/motion tests.
- Change:
  1. Show canonical QA for selected direction: registration, geometry/proportion, palette/brightness, silhouette/outline and reference SHA.
  2. Consume structured `HARD_FAIL / STRUCTURAL_WARN / ART_DIRECTION_WARN / INFO` findings; do not reimplement measurements.
  3. Stale profile/reference SHA blocks 2.5D review completion/publication until explicit refresh.
  4. Permit generation A/B preview; legacy is comparison evidence, never conformance authority.
  5. Add optional review-sequence declarations to plan/schema or equivalent; reuse existing sequence engine.
  6. Minimum presets when actions exist: idle→walk→idle, relaxed→draw→ready, fast01→02→03→04→ready, block enter→hold→hit→hold, dodge→recovery.
  7. Use real timing/contact/motion events, not hard-coded combat windows.
  8. `REVIEW FAMILY/CHAIN` opens existing sequence surface with current direction/generation.
  9. Add debug runtime/sandbox proof through existing Motion calibration or a bounded debug owner; it may load selected 2.5D source/workbench art but cannot mutate production runtime selectors/catalog.
  10. Record a structured per-leaf review receipt distinguishing `PUBLISHED` from `RUNTIME_VERIFIED`.
  11. Subjective unresolved art direction uses one compact visual-review handoff only after objective checks.
- Preserve: production runtime Operator, timeline/motion ownership, gameplay timing, canonical QA authority, legacy review.
- Non-goals: runtime cutover, combat timing changes, new metrics engine, automatic visual approval/generation.
- Acceptance: stale SHA fixture blocks; intentional pose motion does not create false anatomy hard-fail; sequence presets preserve timing; sandbox shows selected 2.5D pixels without production file mutation; same target projection receives review status.
- Validation: refresh exact tests; minimum stale-hash, pose negative control, sequence resolution, fast-chain timing/order, sandbox source-isolation and production-runtime no-diff proof.
- Task overrides: `none`
- Deferred: throughput ranking, generation briefs, final dashboard, production runtime cutover.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Refresh instruction: `Bring WB25-2 + review evidence and live QA/ingress APIs. Re-derive receipt shape, sequence schema, sandbox seam and tests before ready.`

## Handoff
- Next workstream: `review-operator-2-5d-workbench-review-automation`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Summary backlink: include exact Authoring chat URL
- Refresh reason: `none after refresh`
- Next action: `paired review`
- Blockers or open questions: `packet must be refreshed before claim`
