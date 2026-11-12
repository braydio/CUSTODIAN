# Review Procgen Showcase Runtime Inspector

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-showcase-runtime-inspector`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-showcase-runtime-inspector`
- Locks: `procgen-showcase-inspector`
- Review: `none`
- Review target workstream: `procgen-showcase-runtime-inspector`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_SHOWCASE_RUNTIME_INSPECTOR.md`
- Reviewed main: `1326220d8172cee9322363b7a5c020acaf41f64c`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the actual landed PGA-5 implementation, not its intended prose.
- Reviewed implementation acceptance: Overlay counts/fingerprints agree with map owners; disabled costs near zero; opaque/missing fields say unavailable; teardown and seed swap cannot show stale data.
- Review evidence: Exact landed commit, archived implementation packet/closing summary, changed files, claimed Owner/Review metadata, focused tests and runtime provenance; reuse objective metrics before image capture.
- Correction threshold: Invalid authority, unsafe spawn/nav/camera/world lifecycle, fake semantic exhibit or telemetry, nondeterministic selection, missing validation, incomplete real-Operator integration, or material evidence gap.
- Focused validation: NEW inspector smoke with real fixed-seed snapshot/overlay toggles and stale teardown; directly affected existing procgen debug/playability tests; changed/diff.
- Review focus: Scope, single authority, accepted-map fidelity, real runtime proof, negative controls and bounded performance/capture.
- Acceptance: Findings-first independent receipt with zero blocking defects and zero material evidence gaps to pass; log stable R<cycle>-NN findings, allow bounded correction/re-review per root AGENTS, never modify reviewed implementation as part of review.
- Non-goals: No opportunistic fixes, duplicate new feature code or self-approved subjective aesthetics.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Preparatory independent review probes (2026-10-15)

**Do not claim this review until its implementation has landed, archived and passed implementation validation.**

- Independently compare every displayed counter/overlay to `ProcGenAcceptedWorldExport` detached level data and the accepted live map; verify the inspector never samples an unrelated SceneTree procgen node.
- Mutate a returned snapshot and prove the authoritative world/candidate fingerprint cannot change; assert missing fields render N/A rather than inferred true/false.
- Prove disabled overlay performs no repeated world scan and host teardown/seed switch invalidates all old data.
- Validate real PGA-2 catalog provenance and PGA-4 session ownership, followed by registered inspector smoke, directly affected production export/semantic tests and complete changed-file sweep.

## Next Handoff
- Next workstream: `procgen-showcase-exemplar-search`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad01323-a574-83ea-9cdc-68d43870d06e`
- Refresh reason: `Next generated-world/inspection integration must be rederived from newly landed owner and review receipt`
- Next action: `Verify dependency archive and manually refresh only if successor's packet requires it; then run targeted authoring preflight before promotion`
- Blockers or open questions: `none after valid independent review`

## Publication Gate
Do not claim this draft review until the matching implementation archives complete and authoring/preflight promotion has made this review ready/auto on live main.
