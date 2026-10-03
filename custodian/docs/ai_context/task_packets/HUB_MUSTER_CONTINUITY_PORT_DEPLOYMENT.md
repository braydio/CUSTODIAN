# HUB MUSTER + CONTINUITY PORT DEPLOYMENT — H5

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-muster-continuity-port-deployment`
- Status: `blocked`
- Dispatch: `manual`
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
- Reviewed main: `348d00eea51e`

- Goal: Make Muster Court → ordinary Continuity Port the real campaign departure path, consuming the accepted/prewarmed first Contract without duplicate generation and entering `game.tscn` only when that same Contract is READY.
- Completion boundary: Add Port deployment state/interaction and Hub→Campaign major-context transition. GENERATING holds in Hub; FAILED remains in Hub with deterministic retry; READY stages `game.tscn`, injects/starts the accepted CampaignScenario once, lets `WorldContractProxy/ContractWorldLoader` claim the already-prewarmed map, validates campaign bindings, then releases Hub control. No Campaign return.
- Current measured state: `WorldContractBootstrap` owns IDLE/GENERATING/READY/FAILED/CLAIMED and retains generated map instances across scene change. `game.tscn` uses `WorldContractProxy` + `ContractWorldLoader`, while `WorldSimulationRuntime` currently auto-starts `DefaultCampaignScenarioFactory.create_scenario()` when no session is injected. Bootstrap's unused deployment timing seam is still terminal-named (`mark_terminal_requested`, terminal metrics). H3 has not yet created accepted-scenario ownership.
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

## Temporary Refresh Gate — REMOVE WHEN REFRESHED

After `review-hub-forum-adjudication-contract-prewarm` passes, inspect the exact accepted-scenario owner/seed contract, H2 major-context deploy API, H3 bootstrap retry/status API, and current `game.tscn`/WorldSimulationRuntime startup behavior. Reconcile parallel runtime changes, remove this section, and set ready/auto. Refresh in place.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill at closeout>`
- Friction severity: `<fill at closeout>`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `<fill at closeout>`

## Handoff

- Next action: Refresh after HR3; H4 may proceed independently.
- Best starting files: reviewed H3 coordinator; reviewed H2 lifecycle owner; WorldContractBootstrap/Proxy/Loader; game.tscn; WorldSimulationRuntime.
- Blockers or open questions: accepted-scenario injection and deploy API are predecessor outputs.
