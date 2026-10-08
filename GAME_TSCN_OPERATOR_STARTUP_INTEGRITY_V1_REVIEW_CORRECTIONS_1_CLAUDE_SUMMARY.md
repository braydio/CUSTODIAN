# GAME TSCN OPERATOR STARTUP INTEGRITY V1 REVIEW CORRECTIONS 1

## Result

Fixed review finding R0-01. The production Operator was pushed from `(2832, 5776)` to `(2832, 5793.039)` by `/World/CommandTerminal/Body`: the contract loader positioned the terminal on the same tile after selecting the Operator spawn. The loader now keeps the terminal off that tile, using a 32-pixel horizontal fallback only when the compound offers no alternate terminal tile. Its pre-ready placement check also rejects a physics-shape overlap before publishing `contract_ready`.

The literal-scene smoke waits through a physics step and checks that the live Operator remains at the receipt world position and on its selected tile. A fresh run passed with live position `(2832, 5776)`, tile `(88, 180)`, velocity `(0, 0)`, and no slide collisions. Canonical spawn validity, runtime walkability, ingress clearance, accepted-component receipt, and startup ordering all remained valid.

## Validation

- `game_scene_operator_startup_integrity`: passed via `run_validation.py --test ... --json` (236938 ms).
- Legacy-position mutation: forced the Operator to the authored placeholder immediately before the placement gate; smoke exited nonzero and the loader reported `operator_placement_diverged_before_ready`. Mutation was removed and source restored.
- `contract_world_operator_spawn_residency`, `contract_world_operator_void_spawn_failsafe`, `contract_world_playable_region_spawn_validity`, `contract_world_ingress_spawn_clearance`, and `contract_world_archive_resolve_ingress`: passed.
- `procgen_archive_resolve_semantic_echo`, `procgen_archive_resolve_frontier_restraint`, `procgen_pause_aware_streaming`, `procgen_chunk_lifecycle`, `procgen_runtime_health`, `vehicle_exit_clearance`, `vehicle_runtime_lifecycle`, and `vehicle_wreck_restoration`: passed.
- `procgen_performance_baseline_quick`: passed directly with `determinism_ok=true` in 151 seconds. Its registered 120-second timeout was insufficient on this host.
- `git diff --check`: passed.

The first asynchronous implementation experiment broke synchronous installer fixtures and was reverted. The first alternate-terminal selection did not resolve the collision when no alternate compound tile was available; the fallback was added and then confirmed by the literal smoke. A prior unrelated two-minute `--changed` validation was already running in another process; it was left untouched. The documented ambient-spawn and Sundered Keep baselines were not part of this correction's focused validation.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: the asynchronous readiness experiment broke synchronous fixtures; S1 exceeded its registered runner timeout
- Root cause / contributing factors: terminal and Operator spawn shared one tile; the old smoke did not assert live position against the receipt after physics
- Prevention / pipeline improvement: check spawn/terminal body overlap before readiness and retain the post-physics production assertion; reconsider the 120-second S1 wrapper timeout
- Tooling / docs drift discovered: registered S1 quick timeout is shorter than the observed direct runtime
- Follow-up: none
- What worked: structured slide-collision evidence identified the exact collider quickly

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d

## Next Handoff
- Next workstream: review-game-tscn-operator-startup-integrity-v1-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d
- Refresh reason: none
- Next action: start a fresh reviewer context and claim the paired post-land review
- Blockers or open questions: paired review must not continue in this implementation context
