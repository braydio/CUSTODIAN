# Escort Frame M-7 Runtime Actor

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-escort-frame-m7-actor`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-npa-showcase-existing-drone-hardening, review-npa-7-commanded-ally-contracts`
- Locks: `drone-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-npa-showcase-escort-frame-m7-actor`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `b0ff835f8006d5ff6f250e682328512f8aa771d4`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Goal: Create one real M-7 escort unit as a distinct actor skin/profile over reviewed CombatDrone/AlliedInfantryDroid, with manager-owned command identity.
- Completion boundary: Create one real M-7 escort unit as a distinct actor skin/profile over reviewed CombatDrone/AlliedInfantryDroid, with manager-owned command identity. Must land scoped real runtime/source changes, focused owned validation and a fresh independent paired review; no diagram-only or proxy closure.
- Current measured state: NPA-7 and its fresh-context review are archived complete. No M-7 scene exists. AlliedInfantryDroid/CombatDrone and DroneManager/DroneTargeting own donor command/target semantics; existing-drone showcase hardening and review are ready/auto but not complete. Its independently reviewed output is required before M-7 claim.
- Evidence: custodian/docs/ai_context/task_packets/archived/NPA_7_COMMANDED_ALLY_CONTRACTS.md and its passed review; custodian/game/actors/allies/allied_infantry_droid.gd and .tscn; existing DroneManager and DroneTargeting. New npa_escort_frame_m7.tscn and its smoke are proposed outputs.
- Task-specific authority: Active actor/level/Asset V2 design and live runtime under Work surface; this program's design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md.
- Work surface: custodian/game/actors/allies/npa_escort_frame_m7.tscn; focused M7 presentation/profile adapter; scoped dev DroneManager scene option; new m7 smoke
- Change: After NPA-7 independent review, create npa_escort_frame_m7.tscn and only minimal presentation/config to inherit all current command, navigation, damage, projectile and squad identity contract. Provide explicitly scoped dev manager scene selection, distinct role/profile/color and live readable status. No independent raw input, squad, attack-brain or targetability override. Preserve fire-at-will, hold-fire, guard/recall, replacement, and dynamic allegiance. Donor current droid visuals are temporary and tracked for subsequent original-art intake.
- Preserve: Existing NPA ability, reaction, death, loot, identity and relationship owners; existing LoP, production Operator/HUD/level loader; current tuning/authoritative signals, unless a demonstrated task-specific regression requires correction.
- Non-goals: No universal NPC class, duplicate combat/command authority, balance overhaul, fake runtime status, global campaign injection, or direct write into Asset V2-generated runtime assets.
- Acceptance: M-7 and original droid both instantiate; exactly one manager command authority; same target/identity/nav behavior; no unapproved production default replacement; provisional art clearly reported.
- Validation: new m7_commands_smoke.gd; drone_follower_commands_smoke.gd direct; allied_drone_navigation_walkability, actor_relationship_contract, changed/manifest.
- Task overrides: `none`
- Deferred: Later showcase slices, NPA-8 species command convergence, unrelated production content.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh instruction: NPA-7/review are archived complete. Reconcile reviewed showcase drone donor APIs at claim time.

## Ready/auto dependency and publication contract (2026-10-11)
The original speculative-design hold has been reconciled: this is an implementation-ready, dependency-gated pair, **not user-manual dispatch timing**. Before a claim, the execution coordinator MUST run the repository-local targeted `validate_task_packet_authoring.py` on both this implementation and its paired review, then `task_packet_index.py` and `dispatch.py audit --json`; stop and repair if those authoritative checks fail. Current-main GitHub-only metadata checks do NOT prove Godot or full local authoring validation, nor authorize a bypass of existing locks/claims. New source art, final human art approval, NPA-8 and unrelated H5 are out of scope.

## Current-main measured clarification
NPA-7 and independent review are complete, contrary to this packet's older planning snapshot. Await the separately reviewed existing-drone showcase hardening. New M-7 scene and smoke do not yet exist; use real AlliedInfantryDroid, DroneManager and DroneTargeting as owners, with donor art visibly provisional.
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Handoff
- Next workstream: `npa-showcase-dev-overlays`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: Future reviewed-consumer API reconciliation is execution-agent owned, not a new human design gate.
- Next action: After this pair's independent review, inspect the next roadmap gate and promote only if its realized dependencies are satisfied.
- Blockers or open questions: Preserve original existing review claims and wait for named archived dependency reviews; do not fabricate a PASS.
