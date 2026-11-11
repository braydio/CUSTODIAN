# Review: Game TSCN Operator Startup Integrity Review Corrections 1

Fresh-context paired review of correction commit `0cb2b4d5f` on landed main `d7e4145f7` found R0-01 fixed and no cycle-1 findings. The change addresses the measured post-ready displacement by keeping the command terminal off the selected Operator tile, rejecting a pre-ready physics-shape overlap, and checking the literal production Operator's settled world position and tile against the placement receipt after a physics frame.

## Review evidence

- `game_scene_operator_startup_integrity` passed in 167.468 seconds. It loaded literal `res://scenes/game.tscn` with seed `1773840677`; exactly one player-group identity was `/root/GameRoot/World/Operator`. The receipt and settled Operator both reported tile `(88,180)` and world position `(2832,5776)`. The selected cell was accepted-component recorded, canonical-spawn-valid, runtime-navigation-walkable, outside ingress clearance, painted, and presentation-ready. The install trace preserved ingress → Operator placement → compound connection → Archive Resolve ingress → camera refresh → navigation rebuild → contract ready. Settled velocity was zero and no slide collisions were recorded.
- The legacy-position mutation ran in a separate disposable worktree at the correction commit. The first attempt stopped in cold project import at the runner's 120-second import timeout. After copying the matching warmed `.godot` import cache, the literal startup smoke ran and failed with exit 1 as required: readiness, relocation, placement validation, settled receipt equality, ready snapshot, visibility/process state, and ready ordering assertions failed after the pre-ready placeholder restoration. No files in the reviewed worktree were changed.
- Passed focused owners: `contract_world_operator_spawn_residency`, `contract_world_operator_void_spawn_failsafe`, `contract_world_playable_region_spawn_validity`, `contract_world_ingress_spawn_clearance`, `contract_world_archive_resolve_ingress`, `procgen_archive_resolve_semantic_echo`, and `procgen_archive_resolve_frontier_restraint`.
- Direct S1 quick passed with `determinism_ok=true`; both 48×48 seed-420777 fingerprints were `1773840677`. The registered wrapper's 120-second timeout is shorter than its observed runtime, so the direct script invocation was used.
- `git diff --check` passed. The graph database was absent and a build did not complete within the review window; review proceeded from the archived target packet, prior independent finding, correction commit diff, focused live source, and runtime results.

## Findings

### R0-01 — fixed

The regression now samples after a physics frame and compares the live Operator to the receipt's selected tile and exact world position. On the literal production boot both comparisons held; the safety flags and original install ordering also remained true. In the isolated pre-ready placeholder mutation, the existing placement validation withheld `contract_ready` and the smoke failed. The correction did not weaken the receipt invariant or add a second component query.

No blocking defects, material evidence gaps, non-blocking issues, optional improvements, new cycle-1 findings, or human decisions remain. The spawn-residency fixture emitted a `NavigationSystem not found` warning while passing its explicit assertions. Godot also reported the known exit-time ObjectDB/resource leaks on the production-scene runs; these did not change the validation result.

The review used a fresh reviewer workstream and reconstructed from durable packet/history evidence. The correction and smoke implementation files were not modified in the review worktree. The separate disposable mutation checkout and its generated cache were removed after the negative control.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d

## Next Handoff
- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d
- Refresh reason: none
- Next action: Correction lineage is closed; no further workstream is queued.
- Blockers or open questions: none
