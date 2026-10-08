# REVIEW GAME TSCN OPERATOR STARTUP INTEGRITY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-game-tscn-operator-startup-integrity-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `game-tscn-operator-startup-integrity-v1`
- Locks: `contract-world-loader, game-scene-startup, procgen-spawn-integrity`
- Kind: `review`
- Review: `none`
- Review target workstream: `game-tscn-operator-startup-integrity-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/GAME_TSCN_OPERATOR_STARTUP_INTEGRITY_V1.md`
- Review stage: `post-land`
- Review modes: `code, runtime, architecture`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `fresh-context verification that the literal production game.tscn startup, not only production-shaped fixtures, now proves canonical Operator relocation and fail-closed startup integrity`
- Reviewed main: `<fill at claim>`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable review/correction/closeout summary and final `## Next Handoff`.
- Goal: Independently prove that ordinary production `game.tscn` boot can no longer publish a ready world with the canonical Operator left at the authored legacy coordinates, and that the implementation's root-cause fix, placement receipt, identity contract, diagnostics, and regressions are narrow and truthful.
- Completion boundary: Pass only if a fresh reviewer reproduces the implementation's production-scene startup proof on landed main, verifies the real canonical Operator identity/placement/ready ordering and failure behavior from live code rather than summary prose, mutation-checks the literal-scene regression, and finds no material gap that could let a future startup silently keep or restore the authored placeholder position.
- Current measured state: Reconstruct from landed main and archived implementation packet at claim time. Treat the pre-fix user Dev Observatory evidence as the failure baseline: real `game.tscn`, active generated ProcGenMap, registered ingresses, but player position matching `Vector2(717.45905,-485.33954)`.
- Evidence: archived `GAME_TSCN_OPERATOR_STARTUP_INTEGRITY_V1.md`; implementation closing summary; live `game.tscn`; ContractWorldLoader; ProcGenTilemap spawn authority; Dev Observatory; new production-scene startup smoke; existing spawn and AR3/AR4 regressions.
- Task-specific authority: Review the landed implementation against the implementation packet and current live authorities. The reviewer may not replace the production-scene proof with a hand-built fixture.
- Work surface: Read/re-run implementation and tests. Do not edit reviewed implementation. Review may commit only the durable review receipt/summary/lifecycle metadata and bounded correction/re-review packets required by confirmed findings.
- Change:
  1. Re-run the literal `game.tscn` startup regression from fresh context and verify it genuinely loads the production scene/ContractMap/ContractWorldLoader path.
  2. Verify the implementation records the real pre-fix root cause with evidence: placement skipped, post-placement clobber, wrong player identity, or another precisely demonstrated cause.
  3. Verify exactly one canonical production player identity is accepted after successful boot and it is `/root/GameRoot/World/Operator`.
  4. Verify the placement receipt is owned by ContractWorldLoader, generation-scoped/bounded, read-only to diagnostics, and not a second spawn authority.
  5. Verify the pre-ready invariant does not re-run expensive/main-component ownership computation, does not move the Operator, and fails through existing contract-failure authority when the current live Operator diverges from the accepted placement.
  6. Verify the authored legacy position remains only scene/editor bootstrap data and cannot be used as a success fallback.
  7. Verify real ordering: registered ingress -> Operator placement -> compound connection -> Archive Resolve ingress -> camera refresh -> navigation -> contract ready.
  8. Verify genuine no-safe and presentation-realization failures still leave the Operator non-playable and do not publish contract ready.
  9. Inspect any generation/install de-duplication added by the implementation and require direct evidence it fixes a reproduced race rather than papering over ordinary regeneration.
  10. Verify Dev Observatory startup evidence is transition-level/bounded, includes canonical identity + placement receipt + terminal phase, and does not create per-frame event spam or gameplay dependency.
  11. Verify startup phase timing is diagnostic only and does not become a new performance manager.
  12. Mutation-check at least the placement-skip or pre-ready-clobber case and require the literal-scene regression to fail.
- Preserve: no Archive Resolve retuning; no procgen topology change; no vehicle/camera redesign; no generic player registry unless the implementation demonstrated a real identity defect; no gameplay dependence on Dev Observatory; S1 determinism and streaming/lifecycle authorities.
- Non-goals: Aesthetic/game-feel review; general startup architecture rewrite; performance optimization of the separate unclassified hitch; new loading UI.
- Acceptance:
  - Literal production-scene startup proof passes on reviewed main.
  - Canonical Operator identity is unique and matches `/root/GameRoot/World/Operator`.
  - Final Operator position differs from authored legacy coordinates and matches the recorded selected tile/world position after canonical round-trip.
  - Placement receipt and pre-ready consistency gate are narrow, generation-bounded and fail-closed.
  - Mutation proof demonstrates the new regression is capable of catching the original failure class.
  - No-safe and presentation-realization failure paths remain fail-closed.
  - AR3/AR4 ingress/camera ordering and existing spawn regressions remain green.
  - Dev Observatory evidence is sufficient to diagnose startup placement/identity from one exported session without noisy per-frame telemetry.
  - S1 quick remains deterministic or any intentional benchmark change is independently justified.
  - `git diff --check`, focused validation and changed-file review checks pass, with unrelated pre-existing failures separated.
- Validation:
  - new literal production-scene startup smoke;
  - `contract_world_operator_spawn_residency`;
  - `contract_world_operator_void_spawn_failsafe`;
  - `contract_world_playable_region_spawn_validity`;
  - `contract_world_ingress_spawn_clearance`;
  - `contract_world_archive_resolve_ingress`;
  - `procgen_archive_resolve_semantic_echo`;
  - `procgen_archive_resolve_frontier_restraint`;
  - affected streaming/lifecycle/runtime-health and vehicle lifecycle owners;
  - S1 quick;
  - implementation mutation proof;
  - `python3 custodian/tools/validation/run_validation.py --changed --json`;
  - `git diff --check`.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
- Deferred: Resume the user's Archive Resolve live playtest after this review passes.

## Review Receipt

- Status: `pending`
- Reviewed main: `<fill at review>`
- Reviewer context: `fresh`
- Reviewer provenance: `<fill>`
- Blocking defects: `<fill>`
- Material evidence gaps: `<fill>`
- Non-blocking issues: `<fill>`
- Optional improvements: `<fill>`
- Correction finding IDs: `<fill>`
- Next-slice finding IDs: `<fill>`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_GAME_TSCN_OPERATOR_STARTUP_INTEGRITY_V1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `<fill>`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: `If passed, close the P0 startup blocker and resume the deferred Archive Resolve playtest. If findings exist, author only bounded corrections tied to those findings.`
- Blockers or open questions: `implementation dependency only`
