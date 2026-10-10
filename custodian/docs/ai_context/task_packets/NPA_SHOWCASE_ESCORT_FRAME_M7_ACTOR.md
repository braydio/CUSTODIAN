# Escort Frame M-7 Runtime Actor

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-escort-frame-m7-actor`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `npa-showcase-existing-drone-hardening`
- Locks: `drone-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-npa-showcase-escort-frame-m7-actor`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `6a5a60ddbf`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Goal: Create one real M-7 escort unit as a distinct actor skin/profile over reviewed CombatDrone/AlliedInfantryDroid, with manager-owned command identity.
- Completion boundary: Create one real M-7 escort unit as a distinct actor skin/profile over reviewed CombatDrone/AlliedInfantryDroid, with manager-owned command identity. Must land scoped real runtime/source changes, focused owned validation and a fresh independent paired review; no diagram-only or proxy closure.
- Current measured state: No M-7 scene exists. AlliedInfantryDroid inherits CombatDrone; active idle E/W 5f and run E/W 6f SpriteFrames already work as temporary donor, squad owner is DroneManager.
- Evidence: custodian/game/actors/allies/npa_escort_frame_m7.tscn; focused M7 presentation/profile adapter; scoped dev DroneManager scene option; new m7 smoke; design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md; design/05_levels/LORDS_OF_PAIN_TEST_GALLERY.md; NPA-6 reviewed receipts.
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
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh instruction: Refresh required AFTER NPA-7 implementation and independent review land. Resolve their exact main-branch packet IDs; both current runtime and packet pair absent on main at this snapshot. Do not invent a dependency record or implement NPA-7 here.

## Program Publication Gate
These packets are authored **draft/manual** on main as a planning series because there is no local Godot checkout/authoring validator in this session. They are not dispatcher-claimable. Execution/promoting agent: inspect main + AGENTS + dispatch audit; run `python3 custodian/tools/agent/validate_task_packet_authoring.py` on each implementation and review pair; reconcile dependency and exact test references; promote mechanically unlocked pairs to ready/auto; rerun validator; regenerate/verify `task_packet_index.py`; land the promotion safely; confirm dispatcher audit/eligibility. A declared implementation dependency also requires its paired review archived complete before consumer claim. Keep external refresh-gated pairs draft until their real evidence is available.

## Handoff
- Next workstream: `npa-showcase-dev-overlays`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: Refresh required AFTER NPA-7 implementation and independent review land. Resolve their exact main-branch packet IDs; both current runtime and packet pair absent on main at this snapshot. Do not invent a dependency record or implement NPA-7 here.
- Next action: After this pair's independent review, inspect the next roadmap gate and promote only if its realized dependencies are satisfied.
- Blockers or open questions: Refresh required AFTER NPA-7 implementation and independent review land. Resolve their exact main-branch packet IDs; both current runtime and packet pair absent on main at this snapshot. Do not invent a dependency record or implement NPA-7 here.
