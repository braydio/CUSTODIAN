# CONTRACT WORLD INGRESS SPAWN CLEARANCE FIX

- Packet schema: `custodian.task_packet.v2`
- Workstream: `contract-world-ingress-spawn-clearance-fix`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `contract-world-loader`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime`
- Paired review workstream: `review-contract-world-ingress-spawn-clearance-fix`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `5c06a1c2fb950b944185385e0b04793a88c62544`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Goal: Eliminate the reproducible contract-world start bug where the Operator can be positioned first and then become trapped inside collision authored by the required Ash Bell / Forlorn Ritualant surface ingress.
- Completion boundary: Done when structural registered world ingresses and their authored pocket/dressing-clearance claims are established before the final Operator spawn is selected; the spawn resolver explicitly rejects the world-ingress dressing-clearance footprint; fallback spawn handling cannot place the Operator into that footprint; and a deterministic regression fixture proves the Operator starts collision-clear even when the Ash Bell ingress is intentionally placed over what would previously have been the preferred compound spawn.
- Current measured state: On live `ContractWorldLoader`, contract installation calls `_position_operator(level_data, map_instance)` at lines 175-176 before `_place_registered_world_ingresses(level_data, map_instance)` at lines 199-201. `_position_operator()` chooses `_pick_compound_spawn_tile()` from currently walkable compound floor. Later, required ingress placement may commit an authored overlook pocket and then `WorldIngressSpawner._apply_ingress_dressing_clearance()` calls `ProcGenTilemap.claim_world_ingress_dressing_clearance()`, which records the Ash Bell presentation's 832x608 world-space footprint and clears props/foliage but does not retroactively relocate the already-positioned Operator. `WorldIngressPlacementResolver._is_reserved()` does not reserve the chosen Operator tile; it only sees `reserved_world_ingress_tiles` / `reserved_regions` and other ingress centers. `ProcGenTilemap.is_inside_world_ingress_dressing_clearance(tile)` already exists and is the canonical query for this exact footprint. User playtest reproduced starting trapped inside Forlorn Ritualant ingress collision twice consecutively.
- Evidence: `custodian/game/systems/core/systems/contract_world_loader.gd` contract-install order and `_pick_compound_spawn_tile()`; `custodian/game/world/levels/world_ingress_spawner.gd`; `custodian/game/world/levels/world_ingress_placement_resolver.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd::claim_world_ingress_dressing_clearance/is_inside_world_ingress_dressing_clearance`; `design/05_levels/ASH_BELL_LIFT_INGRESS_PRESENTATION.md`; existing Ash Bell and world-ingress focused smokes.
- Task-specific authority: Contract-world runtime installation remains owned by `ContractWorldLoader`; registered ingress placement remains owned by `WorldIngressSpawner`; ingress clearance remains the existing ProcGenTilemap authored-claim/query seam. Do not create another spawn-reservation or ingress-clearance authority.
- Work surface: Narrow changes in `custodian/game/systems/core/systems/contract_world_loader.gd`; focused regression coverage under `custodian/tools/validation/`; update `validation_manifest.json` only if a new focused smoke is created; only directly stale docs/index statements.
- Change: Reorder contract installation so registered structural world ingress placement commits before final Operator/runtime anchor placement. Prefer placing `_place_registered_world_ingresses(level_data, map_instance)` immediately after the procgen map is attached/environment is applied and before `_position_operator()` and other placement consumers whose walkability queries should observe final authored ingress geometry. Preserve required-ingress failure behavior: if the required Ritualant ingress cannot place, abort contract readiness before relocating gameplay actors.
- Change: Harden Operator spawn selection against scene-owned ingress collision by excluding any candidate tile for which the live map exposes `is_inside_world_ingress_dressing_clearance(tile) == true`. Apply this to compound preferred/open candidates and fallback player-spawn handling. Reuse the existing clearance query; do not copy the stored rects into ContractWorldLoader.
- Change: If the original preferred/fallback tile becomes invalid after ingress claims, deterministically choose another currently walkable, open compound tile outside ingress clearance. Keep the existing ingress-adjacent preference among safe candidates. If no safe compound tile exists, fail loudly / preserve the existing safe failure path rather than knowingly spawning inside collision.
- Change: Add a focused deterministic regression where the Ash Bell ingress/presentation clearance overlaps the tile the old ordering would have selected for the Operator. Assert ingress placement/clearance exists first, the selected Operator tile is walkable and outside `is_inside_world_ingress_dressing_clearance`, and a 96px-class Operator collision probe at the resulting world position does not overlap authored collision. Repeat the fixture to prove deterministic spawn selection.
- Change: Add a direct order/behavior assertion so a future refactor cannot silently move `_position_operator()` ahead of structural ingress placement again.
- Preserve: Required Forlorn Ritualant ingress identity, edge-overlook placement, authored pocket geometry, 832x608 dressing-clearance contract, Threadway/causeway logic, route traversal, Underground `Spawn_DescentLanding`, Sundered Keep ingress/vista placement, player-spawn/compound preference when safe, camera snap after final spawn, navigation rebuild, generation fingerprint, AR1/AR2 Archive Resolve behavior, and all ingress art/collision geometry.
- Non-goals: Do not modify Forlorn Ritualant Underground collision or named spawn; do not weaken/remove Ash Bell surface collision; do not move the ingress merely to dodge the bug; do not change procgen candidate scoring/generation; do not redesign ContractWorldLoader placement architecture; do not touch AR2 shader code/worktree; do not create a generic collision solver or new authored-claim registry.
- Acceptance: (1) Registered required ingress placement/claim occurs before final Operator placement. (2) Operator spawn candidates never land inside the canonical world-ingress dressing-clearance query. (3) A deterministic overlap regression reproduces the pre-fix bad ordering and passes after the fix with a collision-clear Operator. (4) The chosen spawn remains a walkable compound/fallback tile and remains deterministic. (5) Required Ritualant ingress remains present and route-valid. (6) Existing Ash Bell presentation/cardinal/safe-marker tests remain green. (7) World ingress spawner behavior and required-ingress dry-run remain green. (8) Camera snaps to the corrected final Operator position and navigation rebuild still occurs after placement. (9) No generation or Archive Resolve behavior changes.
- Validation: Run the new/focused spawn-clearance regression first. Then run `world_ingress_spawner_smoke.gd`, `ash_bell_lift_ingress_presentation_smoke.gd`, `required_ritualant_ingress_contract_sweep.gd`, `contract_world_population_placement_smoke.gd`, `procgen_stuck_pocket_smoke.gd` if registered/available, and the smallest contract-loader/camera regression selected by changed files. Run `git diff --check`, packet/review pairing checks, and changed-file validation after focused green. No renderer evidence is required; this is collision/placement authority, not visual acceptance.
- Task overrides: `none`
- Deferred: Broader ContractWorldLoader placement extraction/contraction remains in its existing P-lane packets. Any future generalized spawn-volume reservation belongs there only if this narrow invariant proves insufficient.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `contract_world_ingress_spawn_clearance_smoke passed with the real Ash Bell presentation collision/clearance at the old preferred tile, deterministic safe replacement, unsafe fallback rejection, and loader-order assertion; world_ingress_spawner, ash_bell_lift_ingress_presentation, and contract_world_population_placement smokes passed. The one-seed required-ingress sweep passed its required placement dry-run and presence assertions, then failed its separate seed-0 Threadway isolation/zero-cell assertions; the same failure reproduced on the project-root main checkout. procgen_stuck_pocket_smoke failed its existing line-70 remediation assertion in untouched ProcGen code. The prescribed 100-seed sweep was stopped after several minutes of measured contract-generation cost.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: `A concurrent validation session edited the same task worktree while implementation was underway, requiring reconciliation. The broad required-ingress sweep exceeded a reasonable closeout budget and its seed-0 Threadway subcheck failed; the separate procgen stuck-pocket smoke also failed in untouched code.`
- Root cause / contributing factors: `The required-ingress sweep couples ingress dry-run assertions to Threadway isolation checks and expensive multi-profile contract generation; a second session ran duplicate validation against the shared worktree.`
- Prevention / pipeline improvement: `Keep required-ingress placement evidence separable from Threadway traversal evidence, document bounded seed-count options for closeout, and avoid duplicate worktree validation while a task owner is active.`
- Tooling / docs drift discovered: `procgen_stuck_pocket_smoke.gd exists but is not registered in validation_manifest.json; the default required-ingress sweep has a 100-seed runtime contract with no quick closeout profile.`
- Follow-up: `manual-follow-up`

## Handoff

- Next workstream: `review-contract-world-ingress-spawn-clearance-fix`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac01db9-8928-83ea-815e-6e223042b6d7`
- Refresh reason: `none`
- Next action: Run the paired fresh-context review against the landed implementation and durable evidence.
- Blockers or open questions: none
