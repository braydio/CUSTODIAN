# Review: Game TSCN Operator Startup Integrity V1

Fresh-context review of landed `main` at `579121331d74f754daf86cc1009617a2934f89b4` found one material acceptance evidence gap, recorded as `R0-01`. The review did not modify reviewed runtime implementation; a temporary pre-ready position mutation was removed and the worktree is clean with respect to runtime files.

## Finding R0-01 — settled Operator position diverges from placement receipt

- Class: `evidence_gap`
- Domain: `implementation`
- Affected acceptance: the successful production boot's final Operator position must round-trip to the placement receipt's selected tile/world position.
- Evidence: an independent run of `game_scene_operator_startup_integrity` passed in 164.062 seconds and loaded the literal `res://scenes/game.tscn` with the real ContractMap/ContractWorldLoader path. The receipt and `contract_ready` snapshot recorded tile `(88,180)` at world `(2832,5776)`. The smoke's terminal live-state snapshot recorded the canonical Operator at `(2832,5793.039)`, which round-tripped to `(88,181)`. The smoke checks the receipt's round-trip and the earlier ready snapshot, but does not compare the terminal live position to the receipt.
- Disposition: correction. The one-tile displacement may still leave the Operator on safe floor, but current evidence does not establish the packet's required final-position/receipt correspondence or detect later divergence.

## Review evidence

- The literal production-scene startup regression passed. It established one `/root/GameRoot/World/Operator` player identity, a generation-scoped receipt, successful presentation and walkability flags, and the expected ingress → placement → compound → Archive Resolve → camera → navigation → ready ordering.
- A temporary mutation restored the legacy placeholder position immediately before `_validate_operator_placement_before_ready`. The literal-scene regression failed (exit 1) on the ready, relocation, placement-consistency, ready-snapshot, visibility/process, and ordering assertions. The mutation was removed.
- `contract_world_operator_spawn_residency`, `contract_world_operator_void_spawn_failsafe`, `contract_world_playable_region_spawn_validity`, `contract_world_ingress_spawn_clearance`, `contract_world_archive_resolve_ingress`, `procgen_archive_resolve_semantic_echo`, `procgen_archive_resolve_frontier_restraint`, `procgen_pause_aware_streaming`, `procgen_chunk_lifecycle`, `procgen_chunk_payload_cache`, `procgen_runtime_health`, and `vehicle_runtime_lifecycle` all exited successfully.
- Direct S1 quick completed with `determinism_ok=true`; both 48×48 seed-420777 fingerprints were `1773840677`. The registered 120-second validation timeout is shorter than the observed direct runtime, so this was run directly.
- The code review graph covered the worktree; its normal diff auto-detection targeted the latest unrelated merge, so review proceeded from the archived task contract, implementation summary, startup-specific source, direct runtime output, and targeted validations.

## Conclusion

The startup repair is materially supported and the original legacy-coordinate failure is caught by the pre-ready mutation. The remaining acceptance gap is the live position moving off the receipt tile after ready. A bounded correction packet and paired re-review packet are available as `game-tscn-operator-startup-integrity-v1-review-corrections-1` and `review-game-tscn-operator-startup-integrity-v1-review-corrections-1`.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: the terminal smoke snapshot differed from the receipt and ready-time snapshot by 17.039 pixels and one tile.
- Root cause / contributing factors: runtime physics had an opportunity to move the restored Operator after the loader's pre-ready consistency check; the smoke asserts only the earlier receipt/ready snapshots.
- Prevention / pipeline improvement: sample and assert the literal-scene Operator after a physics step; keep ready/receipt authority consistent with the settled safe placement.
- Tooling / docs drift discovered: none
- Follow-up: game-tscn-operator-startup-integrity-v1-review-corrections-1
- What worked: the production-scene boot and legacy-position mutation exercised the real startup path.

## Next Handoff
- Next workstream: game-tscn-operator-startup-integrity-v1-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d
- Refresh reason: none
- Next action: implement the bounded R0-01 correction and run its paired fresh-context review.
- Blockers or open questions: determine why the live Operator settles on tile (88,181) after the receipt records tile (88,180), then prove the final settled tile/position remains safe and truthful.
