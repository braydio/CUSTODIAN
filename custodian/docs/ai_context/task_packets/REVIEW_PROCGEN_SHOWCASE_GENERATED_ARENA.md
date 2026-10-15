# Review Procgen Showcase Generated Arena

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-showcase-generated-arena`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-showcase-generated-arena`
- Locks: `procgen-showcase-level`
- Review: `none`
- Review target workstream: `procgen-showcase-generated-arena`
- Review target packet: `custodian/docs/ai_context/task_packets/PROCGEN_SHOWCASE_GENERATED_ARENA.md` (after implementation completion, inspect its archived counterpart instead)
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the actual landed PGA-3 implementation, not its intended prose.
- Reviewed implementation acceptance: One actual ProcGenTilemap, accepted map, named safe spawn, Operator can enter/leave using validated transfer, no overlap/escape/void-spawn; host failure leaves safe gallery; no double active level or camera binding leak.
- Review evidence: Exact landed commit, archived implementation packet/closing summary, changed files, claimed Owner/Review metadata, focused tests and runtime provenance; reuse objective metrics before image capture.
- Correction threshold: Invalid authority, unsafe spawn/nav/camera/world lifecycle, fake semantic exhibit or telemetry, nondeterministic selection, missing validation, incomplete real-Operator integration, or material evidence gap.
- Focused validation: NEW generated arena smoke with real seeded procgen, failed-seed/invalid-spawn test, single-Operator and return; generated_region_route_lifecycle, procgen_playability, existing shell; changed/diff.
- Review focus: Scope, single authority, accepted-map fidelity, real runtime proof, negative controls and bounded performance/capture.
- Acceptance: Findings-first independent receipt with zero blocking defects and zero material evidence gaps to pass; log stable R<cycle>-NN findings, allow bounded correction/re-review per root AGENTS, never modify reviewed implementation as part of review.
- Non-goals: No opportunistic fixes, duplicate new feature code or self-approved subjective aesthetics.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only a durable review receipt, review-packet lifecycle/archive metadata, required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Next Handoff
- Next workstream: `procgen-showcase-generation-controls`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `not-recorded`
- Refresh reason: `Next generated-world/inspection integration must be rederived from newly landed owner and review receipt`
- Next action: `Verify dependency archive and manually refresh only if successor's packet requires it; then run targeted authoring preflight before promotion`
- Blockers or open questions: `none after valid independent review`
