# VEHICLE FIELD SCOUT BUGGY CLASS V1 RECOVERY 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-field-scout-buggy-class-v1-recovery-1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-wreck-restoration-foundation-v1`
- Locks: `vehicle-content, vehicle-runtime-scene`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-vehicle-field-scout-buggy-class-v1-recovery-1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `concrete production class integration over the reviewed wreck-restoration lifecycle`
- Reviewed main: `5020df4b88a2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Ship the Custodian Field Scout Buggy Mk I as the first concrete vehicle class, preserving established handling while making every world-spawned instance begin as a restore-first wreck under the reviewed restoration foundation.
- Completion boundary: Done when stable registry ID `custodian_ground_buggy_scout_light` resolves to semantic `field_scout_buggy_mk1.tscn`, named durability and restoration profiles are data-owned, the live game/registry spawn paths produce the Scout as WRECKAGE, the restored vehicle has the declared seat/footprint/hardpoints and 100-HP durability, existing field repair can operate after restoration, and old `light_buggy` compatibility naming has an explicit exit disposition.
- Current measured state: Lifecycle V1 is complete/reviewed. The pre-restoration class packet was claimed on `agent/vehicle-field-scout-buggy-class-v1` but at this refresh that branch was ahead by zero commits and is superseded. Live main still uses `light_buggy.tscn`, generic exported health, hover-buggy visual kit, and no class durability/restoration-profile identity.
- Evidence: Reviewed wreck-restoration predecessor; `custodian/content/vehicles/{vehicle_archetypes,vehicle_movement_profiles,vehicle_hardpoint_profiles,vehicle_loadouts,vehicle_visual_kits}.json`; live class scene; `game.tscn`; `vehicle_definition.gd`; `design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md`.
- Task-specific authority: `FIELD_SCOUT_BUGGY_MK1.md`; reviewed wreck-restoration API; `VEHICLES.md`.
- Work surface: Vehicle class data/schema; durability profile data; semantic `custodian/game/actors/vehicles/field_scout_buggy_mk1.tscn`; game/registry consumers; class-focused validation.
- Change: Preserve the stable ID and exact `ground_wheeled_light` tuning (175 max speed, 420 acceleration, 520 deceleration, 10 turn response, 0.45 reverse, 0.78 offroad). Set display identity `Custodian Field Scout Buggy Mk I`; add durability profile `light_scout_utility` at 100 max HP and restoration profile `field_scout_recovery_light`. Create/migrate the semantic scene with one driver, 64px entry range after restoration, 2x1 bottom-center footprint, `Hardpoints/FrontLight`, `Hardpoints/RearUtility`, no weapon, and the reviewed restoration interaction plus an ordinary FieldRepairInteraction compatible with >0 HP. Live authored and registry spawn paths must begin as wreckage; restored state begins at 40 HP. Keep loadout `none`. Remove or explicitly alias `light_buggy.tscn` only for proven live consumers. Temporary hover art is compatibility presentation until Asset V2 successor.
- Preserve: Reviewed restoration/lifecycle ownership; stable registry ID; exact movement feel; terrain multiplier; safe exit; procgen placement locations/counts; ResourceLedger authority; unarmed utility role.
- Non-goals: No scanner behavior, fuel, cargo, passengers, weapons, collision damage, handling rebalance, production art, or new stateful subclass unless live behavior genuinely requires one.
- Acceptance: Registry resolves the stable ID to semantic Scout scene/display name; durability max is data-owned 100; restoration profile is exactly 12 scrap/6 alloy/1 power component, 4 sec, 40% health; both live spawn paths start wrecked and non-pilotable; after restore the declared driver/hardpoints/footprint are present and entry works; ordinary field repair can increase health above 40; exact movement values match pre-migration; no stale constant health presentation remains; any `light_buggy` compatibility alias has a named consumer/exit condition.
- Validation: Re-run reviewed wreck-restoration smoke, registry validation, lifecycle and exit smokes. Add/update a focused Scout class/scene smoke for exact movement/durability/restoration values, semantic scene, seat/hardpoints, wreck-first game-scene instantiation, post-restoration entry and field-repair compatibility; register it in validation manifest before closeout.
- Task overrides: `none`
- Deferred: Production wheeled/wreck/restoration art, scanner behavior, mounted combat, additional chassis classes, persistence across world reconstruction.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh instruction: Reconcile landed restoration helper/signal names only. The old claimed class branch is not donor implementation evidence unless new commits appear; do not revive its old pristine-spawn contract.

## Handoff

- Next workstream: `review-vehicle-field-scout-buggy-class-v1-recovery-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Finish normally so paired review gates Asset V2 presentation.
- Blockers or open questions: `none after predecessor review and stale-claim recovery`
