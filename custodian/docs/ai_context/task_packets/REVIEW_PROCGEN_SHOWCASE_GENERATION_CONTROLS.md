# Review Procgen Showcase Generation Controls

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-showcase-generation-controls`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-showcase-generation-controls`
- Locks: `procgen-showcase-level`
- Review: `none`
- Review target workstream: `procgen-showcase-generation-controls`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_SHOWCASE_GENERATION_CONTROLS.md`
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the actual landed PGA-4 implementation, not its intended prose.
- Reviewed implementation acceptance: Same request gives identical semantic/world fingerprint; reroll changes explicit seed; failure retains safe prior world or safely returns Operator; no leaked maps, stale callbacks or duplicated Operator/camera.
- Review evidence: Exact landed commit, archived implementation packet/closing summary, changed files, claimed Owner/Review metadata, focused tests and runtime provenance; reuse objective metrics before image capture.
- Correction threshold: Invalid authority, unsafe spawn/nav/camera/world lifecycle, fake semantic exhibit or telemetry, nondeterministic selection, missing validation, incomplete real-Operator integration, or material evidence gap.
- Focused validation: NEW generation-controls smoke including overlapping requests, failure and two identical runs; generated-region lifecycle; shell/arena; changed/diff.
- Review focus: Scope, single authority, accepted-map fidelity, real runtime proof, negative controls and bounded performance/capture.
- Acceptance: Findings-first independent receipt with zero blocking defects and zero material evidence gaps to pass; log stable R<cycle>-NN findings, allow bounded correction/re-review per root AGENTS, never modify reviewed implementation as part of review.
- Non-goals: No opportunistic fixes, duplicate new feature code or self-approved subjective aesthetics.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Preparatory independent review probes (2026-10-15)

**Do not claim this review until its implementation has landed, archived and passed implementation validation.**

- Verify session is the ONLY authority for request tokens and active/staging host identity; PGA-3's host remains the only real-map transfer/teardown owner.
- Fault-inject staggered completion A/B, cancelled active generation, invalid preset/profile, input spam and actor currently in generated arena. Require no old callback to supersede a newer world, no duplicate camera/Operator, and no leaked node/map.
- Compare two complete identical requests using the canonical semantic/world fingerprint, not timings or rendering frame counts. Validate the real PGA-3 host and the existing `generated_region_route_lifecycle` / PGA-1 shell proofs.
- Require a green registered focused smoke and complete changed-file sweep. Review cannot pass solely on unit-model state diagrams or an increased timeout.

## Next Handoff
- Next workstream: `procgen-showcase-runtime-inspector`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Refresh reason: `Next generated-world/inspection integration must be rederived from newly landed owner and review receipt`
- Next action: `Verify dependency archive and manually refresh only if successor's packet requires it; then run targeted authoring preflight before promotion`
- Blockers or open questions: `none after valid independent review`

## Publication Gate
Do not claim this draft review until the matching implementation archives complete and authoring/preflight promotion has made this review ready/auto on live main.
