# Review Procgen Showcase Exemplar Search

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-showcase-exemplar-search`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-showcase-exemplar-search`
- Locks: `procgen-showcase-exemplar`
- Review: `none`
- Review target workstream: `procgen-showcase-exemplar-search`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_SHOWCASE_EXEMPLAR_SEARCH.md`
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the actual landed PGA-6 implementation, not its intended prose.
- Reviewed implementation acceptance: Positive fixture reproduces same matching seed and actual in-world semantic proof; negative fixture stops with NOT_FOUND and no map mutation; cancellation releases work; unsupported entries remain truthful unavailable.
- Review evidence: Exact landed commit, archived implementation packet/closing summary, changed files, claimed Owner/Review metadata, focused tests and runtime provenance; reuse objective metrics before image capture.
- Correction threshold: Invalid authority, unsafe spawn/nav/camera/world lifecycle, fake semantic exhibit or telemetry, nondeterministic selection, missing validation, incomplete real-Operator integration, or material evidence gap.
- Focused validation: NEW exemplar-smoke with bounded positive/negative/cancel and actual accepted-map identity; candidate evaluator/materializer and playability focused tests; changed/diff.
- Review focus: Scope, single authority, accepted-map fidelity, real runtime proof, negative controls and bounded performance/capture.
- Acceptance: Findings-first independent receipt with zero blocking defects and zero material evidence gaps to pass; log stable R<cycle>-NN findings, allow bounded correction/re-review per root AGENTS, never modify reviewed implementation as part of review.
- Non-goals: No opportunistic fixes, duplicate new feature code or self-approved subjective aesthetics.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Next Handoff
- Next workstream: `procgen-showcase-seed-comparison`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `not-recorded`
- Refresh reason: `Next generated-world/inspection integration must be rederived from newly landed owner and review receipt`
- Next action: `Verify dependency archive and manually refresh only if successor's packet requires it; then run targeted authoring preflight before promotion`
- Blockers or open questions: `none after valid independent review`

## Publication Gate
Do not claim this draft review until the matching implementation archives complete and authoring/preflight promotion has made this review ready/auto on live main.
