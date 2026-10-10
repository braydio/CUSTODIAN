# Existing Grunt Marine Savage Hardening

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-existing-enemy-hardening`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `enemy-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-npa-showcase-existing-enemy-hardening`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `6a5a60ddbf`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Goal: Prove and improve the existing standard-combat-agent stack as production-grade, deterministic arena fixtures before creating a derivative hostile actor.
- Completion boundary: Prove and improve the existing standard-combat-agent stack as production-grade, deterministic arena fixtures before creating a derivative hostile actor. Must land scoped real runtime/source changes, focused owned validation and a fresh independent paired review; no diagram-only or proxy closure.
- Current measured state: Grunt, Marine and Savage have live scenes with NPA-1 through NPA-6 extracted abilities, reactions, parry-critical and EnemyLifecycle. NPA-6 landed at 4fda2ffa and zero-finding review at a9b4e0b9.
- Evidence: custodian/game/actors/enemies/{enemy_grunt,enemy_marine,enemy_savage}.tscn; existing ability and lifecycle components; new custodian/tools/validation/npa_showcase_existing_enemy_smoke.gd; design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md; design/05_levels/LORDS_OF_PAIN_TEST_GALLERY.md; NPA-6 reviewed receipts.
- Task-specific authority: Active actor/level/Asset V2 design and live runtime under Work surface; this program's design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md.
- Work surface: custodian/game/actors/enemies/{enemy_grunt,enemy_marine,enemy_savage}.tscn; existing ability and lifecycle components; new custodian/tools/validation/npa_showcase_existing_enemy_smoke.gd
- Change: Create a semantic dev scenario fixture using real actors and public ability requests, not private timer mutations. Validate Grunt ordinary melee/stagger/parry-critical/lethal corpse, Marine Dash contact and recovery, Savage pounce/two-hit chain, and loot once-only. Harden only proven bugs with before/after tests; preserve existing tuning and ownership. Keep production factory/wave behavior unchanged except narrow optional dev registration if demanded by actual fixture.
- Preserve: Existing NPA ability, reaction, death, loot, identity and relationship owners; existing LoP, production Operator/HUD/level loader; current tuning/authoritative signals, unless a demonstrated task-specific regression requires correction.
- Non-goals: No universal NPC class, duplicate combat/command authority, balance overhaul, fake runtime status, global campaign injection, or direct write into Asset V2-generated runtime assets.
- Acceptance: Each actor has a reproducible real semantic lifecycle path, accurate reaction/death and no shadow authority; any corrected defect has a failing regression first; focused manifest coverage.
- Validation: enemy_reaction_posture, grunt_parry_critical, standard_enemy_melee, lootable_corpse_beacon, enemy_lifecycle_config, Marine/Savage focused checks, new fixture and changed/manifest/diff.
- Task overrides: `none`
- Deferred: Later showcase slices, NPA-8 species command convergence, unrelated production content.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh instruction: Verify latest main, actual changed file and test identities; run targeted authoring preflight on this implementation and review before promotion.

## Program Publication Gate
These packets are authored **draft/manual** on main as a planning series because there is no local Godot checkout/authoring validator in this session. They are not dispatcher-claimable. Execution/promoting agent: inspect main + AGENTS + dispatch audit; run `python3 custodian/tools/agent/validate_task_packet_authoring.py` on each implementation and review pair; reconcile dependency and exact test references; promote mechanically unlocked pairs to ready/auto; rerun validator; regenerate/verify `task_packet_index.py`; land the promotion safely; confirm dispatcher audit/eligibility. A declared implementation dependency also requires its paired review archived complete before consumer claim. Keep external refresh-gated pairs draft until their real evidence is available.

## Handoff
- Next workstream: `npa-showcase-existing-drone-hardening`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: normal dependency and latest-main reconciliation
- Next action: After this pair's independent review, inspect the next roadmap gate and promote only if its realized dependencies are satisfied.
- Blockers or open questions: none beyond repo-local authoring validation/promotion.
