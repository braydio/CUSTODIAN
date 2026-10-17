# COMPOUND INTERIOR TRAVERSAL INTEGRATION

- Packet schema: custodian.task_packet.v2
- Workstream: compound-interior-traversal-integration
- Authoring handoff: auto
- Status: `ready`
- Dispatch: `auto`
- Priority: P1
- Depends on: review-compound-walled-yard-blockout, review-compound-connected-bunker-blockout-review-corrections-1
- Locks: compound-traversal
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, visual
- Paired review workstream: review-compound-interior-traversal-integration
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independently landable cross-system change requiring fresh-context review
- Reviewed main: 9b8ae05581e3194876d8b4763946d1f74d77fa50
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Visual review: conditional
- Goal: Integrate the two reviewed archetypes with real persistent-world entry/return and environment behavior, reusing Type B vertical transfer from its accepted correction.
- Completion boundary: Type A gains independently enterable/returnable room transitions; Type B's already-reviewed surface/subsurface transfer is consumed by canonical world systems without a second transfer owner. Same Operator, state, layer, environment and reentry invariants proven.
- Current measured state: At 934805e71ac4e82c4588365f5e7e1dddea912eaa: Type A and Type B geometry are implemented. The Type A independent review remains active; Type B parent review concluded with R0-01 (unconsumed vertical-entry anchors) and R0-02 (missing collision/navigation/camera proof). The existing `compound-connected-bunker-blockout-review-corrections-1` correction and paired `review-compound-connected-bunker-blockout-review-corrections-1` own both defects, and its `agent/` branch is already published. All later traversal/security/assault/recovery gameplay is unimplemented or unaccepted; do not duplicate that correction or bypass either review.
- Evidence: `design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md`; archived Type A/B blockouts; archived Type B findings `REVIEW_COMPOUND_CONNECTED_BUNKER_BLOCKOUT.md`; correction `custodian/docs/ai_context/task_packets/COMPOUND_CONNECTED_BUNKER_BLOCKOUT_REVIEW_CORRECTIONS_1.md`; live `ContractWorldLoader`/`WorldPlacementContext`.
- Task-specific authority: `custodian/game/systems/core/systems/contract_world_loader.gd` and `custodian/game/world/placement/world_placement_context.gd` own contract-world placement/return; `custodian/game/world/procgen/proc_gen_tilemap.gd` owns geometry/layer metadata; `custodian/game/world/camera.gd` owns camera bounds; Carrow's `gothic_compound_map.gd` is READ-ONLY donor. After correction review, Type B's vertical-entry controller is canonical for its transfer; do not replace it.
- Work surface: `custodian/game/systems/core/systems/contract_world_loader.gd`; `custodian/game/world/placement/world_placement_context.gd`; narrowly necessary existing camera/minimap/environment consumers; focused validation. Read-only donor: `custodian/game/world/gothic_compound/gothic_compound_map.gd`. Do not edit the still-claimed Type B correction files or archived implementation.
- Change: After `review-compound-connected-bunker-blockout-review-corrections-1` PASSES, first inspect its accepted transfer and camera contract. Type A: register stable building-to-interior threshold/return identities and reversible enter/exit from at least three different rooms using existing world placement/route authority; never copy Carrow's router. Type B: call/observe the reviewed vertical-entry controller, do not implement a second trigger, bounce-lockout, layer state or camera clamp. Wire its `layer_changed`/actual active layer through ContractWorldLoader, environment/lighting/weather, minimap and interactions as needed. Preserve one Operator instance, position/inventory/simulation state and safe reentry. Missing or blocked endpoints fail closed without moving the Operator.
- Preserve: One tile/navigation authority, room IDs and legacy default, player identity, existing infra/power/resource/wave owners, current Carrow routing, 32px grid and approved art.
- Non-goals: No independent simulator, automatic art approval/ingest, unrestricted construction, new faction/monitoring UI, or python-sim migration.
- Acceptance: A: enter and return from three different buildings with correct exterior anchors and no double router. B: use both reviewed housing transfers in both directions, walk across >=3 subsurface rooms without teleport, no duplicate transfer/camera ownership or bounce. Repeated world/room returns preserve ONE Operator, inventory, positions, damage and correct layer-specific camera/lighting/weather/minimap; invalid anchors never move the Operator. `legacy` stays identical.
- Validation: Run existing `compound_walled_yard_smoke.gd`, `compound_connected_bunker_smoke.gd`, `persistent_compound_runtime_smoke.gd` from `custodian/tools/validation/`; actual Carrow/contract-world focused manifest entries discovered on latest main; add ONE narrow new layer/return/revisit smoke only if unproven. Validate once after merge with changed-file suite, AI context and review pairing.
- Task overrides: none
- Deferred: Seamless Z travel, CCTV/radar/drone feeds, authored large-room visual approval and any new infrastructure/economy.

## Low-token implementation contract

**No transfer reimplementation:** `review-compound-connected-bunker-blockout-review-corrections-1` owns Type B's paired-anchor trigger, bounce suppression, actual collision/navigation validation and camera bounds. After it passes, reuse its controller and signals. This packet owns only A building interior returns and cross-world integration of the accepted A/B contract.

After `review-compound-connected-bunker-blockout-review-corrections-1` PASSES, first inspect its accepted transfer and camera contract. Type A: register stable building-to-interior threshold/return identities and reversible enter/exit from at least three different rooms using existing world placement/route authority; never copy Carrow's router. Type B: call/observe the reviewed vertical-entry controller, do not implement a second trigger, bounce-lockout, layer state or camera clamp. Wire its `layer_changed`/actual active layer through ContractWorldLoader, environment/lighting/weather, minimap and interactions as needed. Preserve one Operator instance, position/inventory/simulation state and safe reentry. Missing or blocked endpoints fail closed without moving the Operator.

## Closeout

Return changed files, measured acceptance, focused test evidence, documentation drift corrections and independent review link. New art is optional until the later human visual gate.

## Planning refresh (2026-10-17)

- Evidence main: `934805e71ac4e82c4588365f5e7e1dddea912eaa`; status references are time-bounded and must be rechecked before claim.
- Reconciles the parent Type B review's R0-01/R0-02 with its already-authored correction; no new packet or duplicate controller.
- Preserve the existing `Depends on` review IDs. Do not change claims or the original authoring-chat backlink.
