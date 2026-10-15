# Review Procgen Showcase Exhibit Catalog

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-showcase-exhibit-catalog`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `procgen-showcase-exhibit-catalog`
- Locks: `procgen-showcase-catalog`
- Review: `none`
- Review target workstream: `procgen-showcase-exhibit-catalog`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_SHOWCASE_EXHIBIT_CATALOG.md`
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the actual landed PGA-2 implementation, not its intended prose.
- Reviewed implementation acceptance: Every available exhibit resolves real provenance; duplicates/missing refs rejected or explicitly N/A; five wings render truthful entries; selection does not alter generation or global game state; LoP/NPA unchanged.
- Review evidence: Exact landed commit, archived implementation packet/closing summary, changed files, claimed Owner/Review metadata, focused tests and runtime provenance; reuse objective metrics before image capture.
- Correction threshold: Invalid authority, unsafe spawn/nav/camera/world lifecycle, fake semantic exhibit or telemetry, nondeterministic selection, missing validation, incomplete real-Operator integration, or material evidence gap.
- Focused validation: NEW exhibit-catalog smoke using real catalog/runtime reference fixtures and manifest registration; existing Asset V2 status/catalog checks only where touched; shell smoke; changed/diff.
- Review focus: Scope, single authority, accepted-map fidelity, real runtime proof, negative controls and bounded performance/capture.
- Acceptance: Findings-first independent receipt with zero blocking defects and zero material evidence gaps to pass; log stable R<cycle>-NN findings, allow bounded correction/re-review per root AGENTS, never modify reviewed implementation as part of review.
- Non-goals: No opportunistic fixes, duplicate new feature code or self-approved subjective aesthetics.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Next Handoff
- Next workstream: `procgen-showcase-generated-arena`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `not-recorded`
- Refresh reason: `Next generated-world/inspection integration must be rederived from newly landed owner and review receipt`
- Next action: `Verify dependency archive and manually refresh only if successor's packet requires it; then run targeted authoring preflight before promotion`
- Blockers or open questions: `none after valid independent review`

## Publication Gate
Do not claim this draft review until the matching implementation archives complete and authoring/preflight promotion has made this review ready/auto on live main.
