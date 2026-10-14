# REVIEW PROCGEN ARCHIVE RESOLVE PLAYTEST POLISH V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-procgen-archive-resolve-playtest-polish-v1`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `procgen-archive-resolve-playtest-polish-v1`
- Locks: `procgen-archive-resolve-presentation, procgen-world-presentation`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, runtime, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `paired post-land fresh-context review of a substantial presentation/layering change; this review packet itself does not spawn another paired review`
- Review target workstream: `procgen-archive-resolve-playtest-polish-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_ARCHIVE_RESOLVE_PLAYTEST_POLISH_V1.md`
- Reviewed main: `<fill at claim>`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Visual review: `required`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently verify the post-playtest Archive Resolve polish preserves AR1-AR4 authority while fixing the actual gameplay composition: graphite unresolved world-space, readable slower registration/dither, no world props/mobs/structures/cliffs floating over unresolved cells, and ordinary settled world presentation afterward.
- Completion boundary: Pass only when a fresh reviewer proves the landed implementation uses the existing Archive Resolve owner rather than a parallel scheduler, objectively verifies effective world layering and cliff companion coverage, reruns the focused AR/streaming/cliff/determinism contracts, confirms the human visual decision was recorded from the exact Authoring chat, and finds no material path where gameplay authority depends on presentation visibility.
- Current measured state: Reconstruct from landed main at claim time. The pre-fix human baseline is the 2026-10-09 literal Contract sandbox playtest: black-square unresolved read, weak/too-fast VFX, props/mobs/structures above unresolved space, and cliff/fascia outside the effect.
- Evidence:
  - archived implementation packet and closing summary for `procgen-archive-resolve-playtest-polish-v1`;
  - live Archive Resolve owner/shader/scene wiring;
  - live cliff presentation owner and any new read-only coverage API;
  - focused AR/cliff/streaming/runtime-health/S1 results;
  - compact Dropbox review manifest under `/CUSTODIAN/visual_review/procgen-archive-resolve-playtest-polish-v1/`;
  - explicit human/ChatGPT visual disposition in the exact Authoring chat.
- Task-specific authority: `STREAMING_REVEAL_PRESENTATION_V1.md`, `ProcGenRevealPresentation`, `ProcGenTilemap`, and `ProcgenVoidCliffFace` read-only presentation mapping. Gameplay lifecycle/collision/navigation/actors remain upstream authority.
- Work surface: Review only the landed implementation, its focused tests/evidence, directly changed presentation docs, and the recorded human visual decision. Do not edit reviewed implementation code.
- Change:
  1. Reconstruct the before/after composition from live code and durable evidence rather than accepting the implementation summary.
  2. Verify there is still exactly one Archive Resolve presentation state/timing owner. If multiple render primitives exist, prove they consume one shared slot/state/timing authority and cannot diverge.
  3. Verify unresolved concealment uses explicit effective z/coverage rather than fragile sibling ordering. Representative terrain, wall/front presentation, cliff/fascia, props/items and enemies must be covered where unresolved; Operator/HUD readability must remain intact through the safety pocket rather than a broad actor-layer exemption.
  4. Inspect cliff integration carefully. Archive Resolve may consume only the existing cliff owner's read-only painted-cell/frontier mapping. Any duplicate cliff classification, semantic mutation, or image-alpha inference is a finding.
  5. Verify the approved 2026-10-10 distance/cascade refinement, not the superseded AR4 11-tile numeric baseline: target radius 18 (bounded 16–20 after visual review), fringe 2, canonical wall LOS, camera relevance, safe mask rebuild profiling, time-based starts and reacquisition shorter than first resolve. Distinguish visual distance cap from LOS; any through-wall start is a finding.
  6. Verify the shader still uses pause-safe `presentation_time`, one shared material path, bounded batched instances, no per-cell node/tween/material growth, and reduced-effects/disabled parity. Confirm revised per-instance/wave parameter encoding retains cell hash, reacquisition identity and semantic echo, and that intermediate progress frames show coherent boundaries without 32 px tile seams or repeated sketched lattices.
  7. Re-run/falsify the updated layering regression. A mutation that restores the old actor-above-veil invariant or disables cliff companion coverage must make the relevant focused test fail.
  8. Verify the required external visual handoff used the exact Authoring chat URL and the human explicitly answered the six revised packet questions with a minimal motion clip (distance, cascades, unresolved field, VFX, complete world masking, clean settlement). The reviewer may verify that decision exists; it may not replace or reinterpret the human aesthetic judgment.
  9. Independently trace a deterministic LOS-seeded wave through live `ProcGenRevealPresentation` code: 1–3 bounded origins, connected READY/committed local traversal, nearest-wave late neighbor participation, deterministic 30–90 ms near-neighbor staggering, safe isolated fallback, shared token budget, and no new lifecycle/spawn/collision authority. A fixture must fail under a mutation restoring the old rotating independent READY-queue scan.
  10. Verify that the unresolved NOT REQUESTED state has restrained continuous world-space abstract motion without inventing terrain/landmarks; REQUESTED but uncommitted tiles remain opaque, and committed/settled states are not misrepresented. Inspect camera edges, map bounds, pause, reduced/disabled paths and content leaks.
  11. Re-run visible-corner, occluded corridor, disconnected pocket, turn, late commit, unload/reacquire, high-speed motion and safety-halo tests. Ensure the enlarged 18-tile cached LOS window does not introduce a main-thread hotspot.
- Preserve:
  - AR1-AR4 lifecycle/frontier contracts;
  - procgen streaming/collision/navigation/topology;
  - AP2/AP3 ownership;
  - gameplay actor simulation independent of presentation;
  - S1 determinism fingerprint authority.
- Non-goals: No new tuning based on reviewer taste; no AP2/AP3 implementation; no performance rewrite; no actor AI changes; no screen-texture architecture proposal unless the landed implementation already crossed that boundary and requires a finding.
- Acceptance:
  - fresh-context code inspection finds one Archive Resolve owner/state machine and one shared cascade scheduler that only emits presentation starts;
  - effective-z/coverage evidence proves no representative unresolved-world presentation leak for cliffs, props/items or enemies;
  - Operator safety/readability and HUD isolation remain correct;
  - cliff coverage is read-only/adapted from the existing cliff owner;
  - focused AR1-AR4, cliff, cascade wavefront, enlarged LOS mask, streaming/runtime-health and S1 validations pass;
  - mutation proofs catch reintroduced world-layering/cliff-coverage leaks and reintroduction of isolated READY-queue starts;
  - human visual disposition exists and explicitly passes the revised six questions (including perceived front distance, connected currents, abstract distant field) or documents a bounded correction need;
  - no material evidence gap remains.
- Validation:
  - `procgen_archive_resolve_shader`
  - `procgen_archive_resolve_frontier_restraint` (18-tile radius, occlusion, camera bounds, bounded mask rebuild)
  - `procgen_reveal_presentation` (connected cascade, late neighbor, true singleton, pause, deterministic token budget)
  - `procgen_archive_resolve_semantic_echo`
  - `contract_world_archive_resolve_ingress`
  - `procgen_void_cliff_face`
  - `procgen_void_cliff_wall_integration`
  - affected streaming/lifecycle/cache/unload/runtime-health owners
  - S1 quick
  - cascade/isolated-queue mutation proof, plus implementation composition mutation proof
  - `python3 custodian/tools/validation/run_validation.py --changed --json`
  - `git diff --check`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
- Deferred: Any additional purely subjective polish after a human pass is a new human-directed tuning slice, not an automatic review finding.

## 2026-10-14 Split Execution Refresh

Do not claim this broad review. Its acceptance is now distributed across the four focused implementation/review pairs ending in `review-procgen-archive-resolve-smooth-front-v1`.

## Review Receipt

- Status: `pending`
- Review target workstream: `procgen-archive-resolve-playtest-polish-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/PROCGEN_ARCHIVE_RESOLVE_PLAYTEST_POLISH_V1.md`
- Reviewed main: `<fill at review>`
- Reviewer context: `fresh`
- Reviewer provenance: `<fill>`
- Blocking defects: `<fill>`
- Material evidence gaps: `<fill>`
- Non-blocking issues: `<fill>`
- Optional improvements: `<fill>`
- Correction finding IDs: `<fill>`
- Next-slice finding IDs: `<fill>`
- Human-decision finding IDs: `<fill>`
- Detailed review summary: `REVIEW_PROCGEN_ARCHIVE_RESOLVE_PLAYTEST_POLISH_V1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `<fill>`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Refresh reason: `none`
- Next action: `If passed, Archive Resolve post-playtest presentation is closed. If objective findings exist, author only bounded corrections tied to those findings.`
- Blockers or open questions: `implementation dependency and required human visual disposition only`
