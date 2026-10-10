# HUB MUSTER + CONTINUITY PORT DEPLOYMENT — H5

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-muster-continuity-port-deployment`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-hub-forum-adjudication-contract-prewarm`
- Locks: `hub-runtime, world-lifecycle, contract-bootstrap`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-hub-muster-continuity-port-deployment`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default`
- Reviewed main: `122643ec8d6d`

- Goal: Make Muster Court → ordinary Continuity Port the real campaign departure path, consuming the accepted/prewarmed first Contract without duplicate generation and entering `game.tscn` only when that same Contract is READY.
- Completion boundary: Add Port deployment state/interaction and Hub→Campaign major-context transition. GENERATING holds in Hub; FAILED remains in Hub with deterministic retry; READY stages `game.tscn`, injects/starts the accepted CampaignScenario once, lets `WorldContractProxy/ContractWorldLoader` claim the already-prewarmed map, validates campaign bindings, then releases Hub control. No Campaign return.
- Current measured state: H3/HR3 are landed and reviewed. Production `HubRuntimeHost` owns `HubCampaignSelectionAuthority`, which latches a typed accepted `CampaignScenario` in `HubState` and prewarms it through the persistent `WorldContractBootstrap`; READY, GENERATING, FAILED, accepted seed, and generation count are observable. The bootstrap retains its generated map instance across scene changes. `game.tscn` uses `WorldContractProxy` + `ContractWorldLoader`, which claims the bootstrap map only after spawn, camera, and navigation validation. `WorldSimulationRuntime` has a guarded exactly-once `start_campaign` entry point; its default `_ready()` startup remains available when no scenario was injected. `WorldTransitionManager` owns Awakening→Hub and the H5 Continuity Port Hub→Campaign transaction. Deployment timing is named `mark_deployment_requested` / `prewarm_ready_before_deployment`.
- Evidence: `HUB_FIRST_SET_BLOCKOUT.md`; `WORLD_TRANSITION_SYSTEM.md`; `world_contract_bootstrap.gd`; `world_contract_proxy.gd`; `contract_world_loader.gd`; `scenes/game.tscn`; `world_simulation_runtime.gd`; `world_contract_prewarm_smoke.gd`; startup world entry smoke.
- Task-specific authority: reviewed H3 accepted scenario/prewarm owner; reviewed H2 major-context lifecycle; existing game/proxy/loader contract.
- Work surface: Muster/Port interaction/controller under production Hub host; major-context deploy request; accepted CampaignScenario handoff; `game.tscn`/WorldSimulationRuntime startup seam; deployment-neutral bootstrap timing API; focused Port deployment smoke.
- Change: Read H3 accepted scenario + bootstrap state. GENERATING: no transition and no second `ensure_started`. FAILED: expose explicit retry using the same accepted seed; only a failed generation may trigger a fresh `ensure_started(accepted_seed)`. READY: request Hub→Campaign through the major-context owner, stage `game.tscn`, inject/start exactly the accepted CampaignScenario instead of an unrelated default, and let proxy/loader attach the same bootstrap map. Do not regenerate inside `game.tscn`. Rename/migrate terminal-specific bootstrap request metrics to deployment-neutral semantics; keep compatibility aliases only if live consumers/tests require them.
- Preserve: direct contract-sandbox development mode; bootstrap stale-map guard; ContractWorldLoader placement/binding; one active world authority; accepted seed/scenario identity; H4 independence.
- Non-goals: No Campaign outcome/return; no mission-objective redesign; no full Muster loadout/fabrication suite; no transit cinematic; no terminal destination; no second procgen generator.
- Acceptance: GENERATING/FAILED never load `game.tscn`; FAILED retry keeps the accepted seed and cannot overlap generation; READY loads Campaign once; generation_count remains one for a successful first generation (except an explicit prior FAILED retry); proxy consumes the same live map instance and bootstrap reaches CLAIMED only through loader activation; WorldSimulationRuntime session scenario/seed equals the accepted scenario rather than unrelated default; Operator/camera/navigation are Campaign-bound before input unlock; Hub is inactive during Campaign; startup/prewarm/debug sandbox regressions remain green.
- Validation: Add focused Port deployment smoke with pending/ready/failed fake generators and accepted-scenario fixture. Prove state gating, same-seed retry, no duplicate generation, same map instance, accepted CampaignSession identity, transition rollback, and Hub/Campaign exclusivity. Re-run world_contract_prewarm, startup_world_entry, ContractWorldLoader + WorldSimulation live regressions, H2/H3, changed-file closeout, `git diff --check`.
- Task overrides: `none`
- Deferred: H6 outcome/return; final Muster services/art; deployment interstitial polish.

## Claim-Time Dependency Refresh

This packet is intentionally `ready/auto` while its declared dependencies may still be incomplete. The dispatcher must keep it non-claimable until every `Depends on` workstream is archived `complete`. Once claimed, the execution agent must reconstruct the landed predecessor seams from current `main`, archived implementation/review summaries, and live public APIs before mutation. Reconcile private helper names and bounded implementation drift while preserving this packet's Goal, Completion boundary, Preserve, Non-goals, and Acceptance. Update directly stale packet/docs facts inside the workstream when needed. Do not stop for a ChatGPT/user refresh unless current evidence exposes a genuine unresolved design choice that existing authority cannot answer.
## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes; the Forum accepted-scenario flow now reaches Campaign only through READY-gated Continuity Port deployment.
- Completion boundary satisfied: implementation and rollback boundary are implemented; landing is pending the changed-validation blocker documented in the closing summary.
- Acceptance satisfied: focused pending/failed/ready, same-seed retry, same-map activation, exact CampaignSession identity, rollback, and exclusive authority checks pass; changed-file closeout is blocked only by the unrelated global review-pairing contract.
- Superseded/legacy production path disposition: `n/a`
- Evidence: Current `origin/main` contains Vaultwing import repair `ed433103`; its 15 `.png.import` files now pass Godot import. LFS fsck, `godot_import_preflight.py`, full Godot import, task packet index, all 61 review pairings, and AI-context (zero findings) pass. All seven H5-focused Port, transition, prewarm, startup, and loader regressions pass. `game_scene_operator_startup_integrity` passes in 162876 ms with generation seed 1773840677 and 151630 ms prewarm. Fresh complete `--changed --base origin/main --json` report is at `/tmp/h5-current-changed-validation.json`: 43 selected, complete coverage, 40 passed, 1 failed, 1 timed out, 1 skipped. `vaultwing_world_spawn` fails with five production-spawner/population assertions and repeated `_prune_spawned` typed-array/lambda errors. `procgen_ambient_enemy_real_world_spawn` times out at 180 seconds after generation seed 3348744079 completes in 18064 ms, with no stderr. `awakening_late_seams_v1` is skipped because the integration tier failed. `git diff --check origin/main...HEAD` passes.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: high
- What went wrong: the prior 42-test JSON report was not retained in the worktree or searched temporary-report directories, so its two historical failure IDs cannot be verified. A fresh current-main report is retained at `/tmp/h5-current-changed-validation.json`. It has one reproducible Vaultwing spawn failure and one real-world ambient-spawn timeout; the startup integrity timeout did not reproduce and now passes.
- Root cause / contributing factors: Vaultwing import metadata is repaired, but the current runtime smoke still finds missing production-spawner wiring and `_prune_spawned` type errors. Ambient world generation completes in about 18 seconds, after which loader/spawn processing consumes a CPU core until the 180-second timeout. H5's loader diff adds activation-result signaling/wait/rollback APIs and does not change the ambient-candidate algorithm; attribution of that timeout to the mainline loader path is an evidence-based inference, not a confirmed root cause.
- Prevention / pipeline improvement: keep the validation gates intact; route Vaultwing runtime wiring and ambient-spawn timeout diagnosis to their owning lanes, then rerun the full changed suite.
- Tooling / docs drift discovered: the older aggregate validation output was not saved as JSON. The new report and focused reports are saved under `/tmp`; preserve their findings in this handoff. Current main synchronization, import preflight, full import, packet-index, pairing, and AI-context checks all completed successfully.
- Follow-up: manual-follow-up

## Next Handoff
- Next workstream: `review-hub-muster-continuity-port-deployment`
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: resolve the Vaultwing runtime failure and ambient-spawn timeout in their owning lanes, then rerun complete changed-file validation. After a green report, set exact completion truth values, archive the implementation packet, finish H5, and launch the paired review in fresh context.
- Blockers or open questions: current changed-file validation remains red (1 failed, 1 timed out, 1 skipped). `game_scene_operator_startup_integrity` now passes; do not adjust its timeout. Keep the implementation packet active and paired review dependency-gated. Do not weaken validation or edit unrelated lanes inside H5.
