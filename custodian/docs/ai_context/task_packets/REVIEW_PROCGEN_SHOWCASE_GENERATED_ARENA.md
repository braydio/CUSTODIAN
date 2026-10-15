# Review Procgen Showcase Generated Arena

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-showcase-generated-arena`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `procgen-showcase-generated-arena`
- Locks: `procgen-showcase-level`
- Review: `none`
- Review target workstream: `procgen-showcase-generated-arena`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_SHOWCASE_GENERATED_ARENA.md`
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
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
- Review focus: Scope, single authority, accepted-map fidelity, real runtime proof, negative controls and bounded performance/capture. Independently prove the PGA-1 threshold rail remains collision-sealed while deliberate interactive transfer is possible; validate real `GeneratedRegionLevel` map/spawn/nav without nested LevelLoader; same Operator/camera/outer-gallery identity and rollback on failed/cancelled/duplicate activation; no geometry overlap or state leak.
- Acceptance: Findings-first independent receipt with zero blocking defects and zero material evidence gaps to pass; log stable R<cycle>-NN findings, allow bounded correction/re-review per root AGENTS, never modify reviewed implementation as part of review.
- Non-goals: No opportunistic fixes, duplicate new feature code or self-approved subjective aesthetics.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Post-PGA-1 architecture refresh (2026-10-15)
- Independently reconstruct from the archived PGA-1 implementation/review and the verified runtime owners `procgen_showcase_gallery.gd/.tscn`, `generated_region_level.gd`, `level_loader.gd`, `camera.gd`.
- Validate exact expected shell rail count/position and preserve all PGA-1 smoke assumptions; ensure any new portal is interactive and cannot implicitly let the Operator cross an unsafe or unloaded boundary.
- Treat any missing final generated-world proof, incomplete cleanup, map/nav camera inconsistency or red changed-file validation as a blocking/material gap, not a conditional pass.

## Next Handoff
- Next workstream: `procgen-showcase-generation-controls`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Refresh reason: `Next generated-world/inspection integration must be rederived from newly landed owner and review receipt`
- Next action: `Verify dependency archive and manually refresh only if successor's packet requires it; then run targeted authoring preflight before promotion`
- Blockers or open questions: `none after valid independent review`

## Publication Gate
Do not claim this draft review until the matching implementation archives complete and authoring/preflight promotion has made this review ready/auto on live main.
