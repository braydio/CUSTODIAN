# CONTRACT WORLD OPERATOR SPAWN RESIDENCY CORRECTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-operator-spawn-residency-correction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-contract-world-operator-void-spawn-failsafe-correction`
- Locks: `contract-world-loader, procgen-streaming, procgen-playability`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime`
- Paired review workstream: `review-contract-world-operator-spawn-residency-correction`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Parent implementation: `contract-world-operator-void-spawn-failsafe-correction`
- Parent review: `review-contract-world-operator-void-spawn-failsafe-correction`
- Reviewed main: `0f0ccc439f53ff4ee198dab9c5e97cfc179b69d0`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Goal: Fix the still-reproducible normal-load state where the Operator is invisible and immobile because the contract spawn selector rejects canonically playable main-component cells solely because their streaming presentation has not been painted yet. Decouple gameplay spawn authority from presentation residency, then explicitly make the chosen canonical spawn presentation-ready before enabling the Operator.
- Completion boundary: Done when a normal production contract may choose a canonically valid/runtime-walkable/main-component tile even if its chunk is currently UNSEEN/UNPAINTED, a narrow ProcGenTilemap seam synchronously makes the chosen spawn tile presentation-resident without changing canonical topology or discovery authority, final placement verifies the chosen tile is painted before restoring Operator visibility/control, and a real production-style boot can no longer fall into the invisible/frozen failure state merely because the accepted playable component is not yet painted.
- Current measured state: A new direct user playtest on current main loads into a state where the Operator cannot be seen or moved and vehicle exit does nothing. This is not vehicle possession: production vehicle entry occurs only from PlayerController's interact path and there is no auto-enter-on-load path. The observed state matches `ContractWorldLoader._on_contract_generation_failed()`, which calls `_disable_operator_until_safe_placement()` and sets `operator.visible=false` plus `process_mode=DISABLED`. The reviewed parent correction already recorded one generated real-world fixture with an accepted main playable component of 72 tiles but `safe_component_tile_count=0`, and classified that as an expected catastrophic failure. Live code now explains the discrepancy: `ProcGenTilemap.get_main_playable_component()` explicitly uses canonical `is_valid_spawn_cell()` + `is_runtime_navigation_walkable()` and “never painted-tile visibility”, while `ContractWorldLoader._is_safe_operator_spawn_tile()` first calls `_is_walkable_floor_tile()`, which requires a currently painted `floor_tilemap` cell. Therefore canonical gameplay-safe cells can all be rejected solely because streaming presentation is not resident yet.
- Evidence: `contract_world_loader.gd::_is_safe_operator_spawn_tile/_is_walkable_floor_tile/_position_operator/_disable_operator_until_safe_placement`; `proc_gen_tilemap.gd::get_main_playable_component/is_valid_spawn_cell/is_runtime_navigation_walkable/_prepare_streaming_reveal/_prime_streaming_chunks/_reveal_chunk_immediately/_commit_tile_reveal_record`; archived parent implementation/review closeout recording accepted component 72 / safe cells 0; direct user live repro; `PlayerController` proving vehicle entry is interaction-only.
- Task-specific authority: Canonical spawn/gameplay validity remains `ProcGenTilemap.is_valid_spawn_cell()`, `is_runtime_navigation_walkable()`, and membership in the accepted main playable component. Streaming/presentation residency remains `ProcGenTilemap` lifecycle/payload/reveal authority. ContractWorldLoader owns spawn selection/orchestration only.
- Work surface: `custodian/game/systems/core/systems/contract_world_loader.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd` only for one narrow public spawn-presentation readiness seam; focused validation and manifest ownership; concise current-state/roadmap updates. Do not touch vehicle lifecycle, AR4 frontier tuning, procgen topology generation, or authored claim extraction.
- Change: Split canonical spawn eligibility from presentation readiness. Spawn candidate filtering must no longer require `floor_tilemap.get_cell_source_id(tile) >= 0`. A canonical safe Operator tile is one that is outside ingress dressing clearance, passes `is_valid_spawn_cell()`, passes `is_runtime_navigation_walkable()`, and belongs to the already-computed accepted main playable component. For non-ProcGen fallback maps preserve the existing painted-floor check.
- Change: Add one narrow public `ProcGenTilemap` seam, name chosen to match live conventions, equivalent to `ensure_spawn_presentation_ready(tile: Vector2i) -> bool`. It may synchronously request/reveal the selected tile's existing canonical chunk through the current lifecycle/payload/reveal machinery and perform the minimum required visual/collision/navigation flush already used by immediate startup reveal. It must not mutate generated floor/wall topology, invent cells, change the accepted component, bypass M5/M6 cache/lifecycle state, or become a general-purpose reveal API.
- Change: The readiness seam must be idempotent. If the tile is already painted/resident it returns success without duplicate realization. If the selected tile is canonically floor but currently UNSEEN/UNLOADED, it must make the selected chunk presentation-resident using the existing deterministic payload/commit path. After the seam returns success, the selected tile must be visibly painted floor and not a painted wall. Existing Archive Resolve cover/semantic presentation may still obscure it visually as designed; this requirement concerns underlying world realization, not bypassing Archive Resolve.
- Change: `ContractWorldLoader._position_operator()` must select from canonical-safe candidates first (compound -> exported player_spawn -> main-component fallback), then ask the map to make only the selected spawn presentation-ready, then verify both canonical safety and realized floor at that exact tile before setting/restoring the Operator. Do not iterate over all component tiles merely to find one already painted. If the first selected canonical-safe tile cannot be realized despite canonical data, emit a precise install-trace failure with tile, lifecycle/residency state, and reason; a deterministic next-candidate retry is allowed only if implemented from the already-ranked canonical candidate set without changing authority rules.
- Change: Keep the catastrophic no-canonical-safe-cell path fail-closed. This correction does not simply make the hidden Operator visible at stale coordinates. If the accepted component is genuinely empty or contains no canonical-safe tile, activation may still abort and keep the Operator non-playable. The new distinction is explicit diagnostics between `no_canonical_safe_spawn` and `spawn_presentation_realization_failed`; ordinary unpainted residency is not catastrophic.
- Change: Add a production-shaped regression that creates a real generated ProcGenTilemap with a non-empty accepted main component, deliberately removes/withholds TileMap paint for the selected spawn chunk while leaving canonical generated state/lifecycle valid, then drives the real `_on_contract_generated()`. It must prove precondition: accepted component > 0 and the chosen canonical spawn tile is initially unpainted; after install: contract reaches ready, readiness seam was used, Operator is visible/process-enabled, final tile is painted floor, canonical-safe, in the accepted component, and camera/AR ingress happen only after successful realization.
- Change: Mutation-check the regression by restoring the old painted-floor condition in candidate filtering or by disabling the spawn-presentation readiness seam; the test must reproduce the invisible/frozen activation failure or fail at its readiness assertions.
- Change: Re-run the exact parent no-safe-cell test and preserve its fail-closed behavior. Also add a diagnostic assertion that PlayerController has no `current_vehicle` during this failure, preventing future triage from confusing contract failure with vehicle possession.
- Preserve: preferred spawn ordering; ingress clearance; canonical accepted-component ownership; D1/D2 authority boundaries; M3-M6 streaming/lifecycle/payload semantics; AR1-AR4 presentation ownership and cover behavior; Operator/vehicle lifecycle; camera handoff ordering; S1 determinism; no hidden exposure of genuinely uncommitted terrain.
- Non-goals: No vehicle fix; no map topology repair/regeneration; no map-size change; no ingress relocation; no Archive Resolve/frontier retune; no loading-screen or failure-UI redesign; no broad public chunk-reveal API; no bypass of canonical spawn validity.
- Acceptance: (1) ProcGen spawn selection no longer uses current painted-floor visibility as gameplay eligibility. (2) Canonical safety remains valid-spawn + runtime-walkable + accepted-main-component + outside ingress clearance. (3) One narrow idempotent ProcGenTilemap spawn-readiness seam realizes an unpainted selected spawn through existing lifecycle/payload/commit machinery. (4) Operator visibility/process is restored only after the exact selected tile is canonically safe and underlying floor presentation is resident/painted. (5) A fixed real generated case with accepted component > 0 and selected spawn initially unpainted reaches contract-ready rather than hidden/frozen failure. (6) Mutation restoring painted-floor filtering or disabling readiness makes the regression fail. (7) Genuine no-canonical-safe-cell failure remains fail-closed and cannot masquerade as vehicle possession. (8) No new general reveal authority or duplicate topology authority is introduced. (9) M5/M6, Archive Resolve ingress/frontier, spawn-clearance, camera, navigation, vehicle lifecycle and S1 regressions remain green.
- Validation: Run the new spawn-residency regression first plus mutation control. Then run `contract_world_operator_void_spawn_failsafe`, `contract_world_playable_region_spawn_validity`, `contract_world_ingress_spawn_clearance`, `contract_world_archive_resolve_ingress`, `world_ingress_spawner`, `procgen_chunk_lifecycle`, `procgen_chunk_payload_cache`, `procgen_distant_chunk_unload`, `procgen_pause_aware_streaming`, `procgen_walkable_boundary`, navigation elevation/runtime health, `vehicle_runtime_lifecycle`, S1 quick, changed-file validation, packet/review pairing, and `git diff --check`.
- Task overrides: `none`
- Deferred: If a future production map truly generates zero canonical-safe cells, map-generation retry/rescue UX remains a separate problem. This packet closes only the false catastrophic failure caused by presentation residency.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `all 14 focused packet regressions including S1 quick pass; the residency mutation fails as expected; task_packet_index and git diff checks pass. The changed-file sweep selected 50 tests: 16 passed, the repository-wide review_pairing_contract unit failed on two unrelated visual-review-question-answer-capture-v1 packets, and 33 higher tiers were skipped. This task's review pair was not reported by the pairing guard.`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `the exact Archive Resolve install-phase assertion and trace-index reads needed adjustment for the new readiness phase; the original fail-closed fixture requires a fully painted setup, so residency coverage was separated into a generated streaming smoke. The broad changed-file sweep is blocked by unrelated repository-wide review-pairing drift. Main synchronization also conflicted in the task-packet README because main added packet-index entries in the same area; the resolution preserved those main entries and regenerated the managed index for this archived packet.`
- Root cause / contributing factors: `one test encoded fixed trace positions; the existing fail-closed fixture intentionally disables streaming; unrelated active visual-review packets contain pairing metadata drift; main advanced the same packet README during this run.`
- Prevention / pipeline improvement: `keep phase-order checks synchronized with named install phases; isolate streamed presentation preconditions from fully painted ingress fixtures; repair the unrelated review-pairing drift in its owning workstream.`
- Tooling / docs drift discovered: `changed-file validation reaches an unrelated failing review_pairing_contract unit and skips higher tiers after that unit failure.`
- Follow-up: `manual-follow-up`
- What worked: `a deterministic generated seed provided an initially unpainted canonical tile in an UNSEEN/UNLOADED chunk.`

## Handoff

- Next workstream: `review-contract-world-operator-spawn-residency-correction`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh reason: `none`
- Next action: Claim and perform the paired fresh-context code/runtime review; then resume AR4 playtest only after review disposition.
- Blockers or open questions: none.
