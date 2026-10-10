# Existing Commanded Droid Hardening

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-existing-drone-hardening`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `drone-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-npa-showcase-existing-drone-hardening`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `6a5a60ddbf`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Goal: Qualify CombatDrone, AlliedInfantryDroid, DroneManager and DroneTargeting as a robust, observable baseline for the new M-7 companion.
- Completion boundary: Qualify CombatDrone, AlliedInfantryDroid, DroneManager and DroneTargeting as a robust, observable baseline for the new M-7 companion. Must land scoped real runtime/source changes, focused owned validation and a fresh independent paired review; no diagram-only or proxy closure.
- Current measured state: DroneManager owns squad inputs and state, DroneTargeting uses ActorRelationshipResolver. NPA-7 implementation/review pair has not been published on main. Three existing direct drone smoke scripts are not named validation_manifest IDs.
- Evidence: custodian/game/actors/allies/{combat_drone,allied_infantry_droid}.gd; custodian/game/systems/drone/{drone_manager,drone_targeting,drone_squad_state}.gd; drone_follower_commands_smoke.gd; validation_manifest.json; design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md; design/05_levels/LORDS_OF_PAIN_TEST_GALLERY.md; NPA-6 reviewed receipts.
- Task-specific authority: Active actor/level/Asset V2 design and live runtime under Work surface; this program's design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md.
- Work surface: custodian/game/actors/allies/{combat_drone,allied_infantry_droid}.gd; custodian/game/systems/drone/{drone_manager,drone_targeting,drone_squad_state}.gd; drone_follower_commands_smoke.gd; validation_manifest.json
- Change: AFTER NPA-7 implementation and review land, reread exact target/identity/command APIs, then test follow/hold/guard/recall, fire discipline, replacement inheritance, target release after allegiance change and before each projectile/burst, freed targets, active cap and nav stop. Preserve explicitly ordered passive Shrumb target via drone_command_target while forbidding autonomous passive acquisition. Register existing direct smokes or invoke directly, and give new drone tests focused manifest owners. Do not duplicate NPA-7 engineering.
- Preserve: Existing NPA ability, reaction, death, loot, identity and relationship owners; existing LoP, production Operator/HUD/level loader; current tuning/authoritative signals, unless a demonstrated task-specific regression requires correction.
- Non-goals: No universal NPC class, duplicate combat/command authority, balance overhaul, fake runtime status, global campaign injection, or direct write into Asset V2-generated runtime assets.
- Acceptance: Automatic targeting rejects allied/passive, explicit passive Shrumb still works, shots cease mid-burst on allegiance flip, destroyed/replaced drones inherit state and stale references prune, existing droid unchanged.
- Validation: actor_relationship_contract and allied_drone_navigation_walkability registered; drone_follower_commands_smoke.gd and main_scene_allied_droid_smoke.gd direct until registered; focused burst edge smoke; changed/diff.
- Task overrides: `none`
- Deferred: Later showcase slices, NPA-8 species command convergence, unrelated production content.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh instruction: Refresh required AFTER NPA-7 implementation and independent review land. Resolve their exact main-branch packet IDs; both current runtime and packet pair absent on main at this snapshot. Do not invent a dependency record or implement NPA-7 here.

## Program Publication Gate
These packets are authored **draft/manual** on main as a planning series because there is no local Godot checkout/authoring validator in this session. They are not dispatcher-claimable. Execution/promoting agent: inspect main + AGENTS + dispatch audit; run `python3 custodian/tools/agent/validate_task_packet_authoring.py` on each implementation and review pair; reconcile dependency and exact test references; promote mechanically unlocked pairs to ready/auto; rerun validator; regenerate/verify `task_packet_index.py`; land the promotion safely; confirm dispatcher audit/eligibility. A declared implementation dependency also requires its paired review archived complete before consumer claim. Keep external refresh-gated pairs draft until their real evidence is available.

## Handoff
- Next workstream: `npa-showcase-existing-vaultwing-proof`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: Refresh required AFTER NPA-7 implementation and independent review land. Resolve their exact main-branch packet IDs; both current runtime and packet pair absent on main at this snapshot. Do not invent a dependency record or implement NPA-7 here.
- Next action: After this pair's independent review, inspect the next roadmap gate and promote only if its realized dependencies are satisfied.
- Blockers or open questions: Refresh required AFTER NPA-7 implementation and independent review land. Resolve their exact main-branch packet IDs; both current runtime and packet pair absent on main at this snapshot. Do not invent a dependency record or implement NPA-7 here.
