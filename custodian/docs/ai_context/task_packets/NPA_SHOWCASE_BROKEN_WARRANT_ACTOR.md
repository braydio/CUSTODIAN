# Broken Warrant Runtime Actor

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-broken-warrant-actor`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `npa-showcase-existing-enemy-hardening`
- Locks: `enemy-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-npa-showcase-broken-warrant-actor`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `6a5a60ddbf`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Goal: Create one distinctive Broken Warrant hostile archetype with real melee/reactions/death/corpse/loot and no duplicate Enemy mechanics.
- Completion boundary: Create one distinctive Broken Warrant hostile archetype with real melee/reactions/death/corpse/loot and no duplicate Enemy mechanics. Must land scoped real runtime/source changes, focused owned validation and a fresh independent paired review; no diagram-only or proxy closure.
- Current measured state: No Broken Warrant actor or asset family exists. EnemyGrunt has configurable NPA melee, reaction, parry-critical, lifecycle, behavior and optionally Grunt Falcon Punch.
- Evidence: custodian/game/actors/enemies/npa_broken_warrant.tscn; enemy configs/behavior resources; thin archetype script only if necessary; dev actor scenario registration; focused actor smoke; design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md; design/05_levels/LORDS_OF_PAIN_TEST_GALLERY.md; NPA-6 reviewed receipts.
- Task-specific authority: Active actor/level/Asset V2 design and live runtime under Work surface; this program's design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md.
- Work surface: custodian/game/actors/enemies/npa_broken_warrant.tscn; enemy configs/behavior resources; thin archetype script only if necessary; dev actor scenario registration; focused actor smoke
- Change: New npa_broken_warrant.tscn derives from/reuses the live Grunt/Enemy composition with own typed archetype configs and identity. Prefer a close-range measured ceremonial enforcer with reactive posture and standard melee; Grunt-only Falcon Punch is disabled unless explicitly requested and fully implemented. Wire authoritative hostile relationship, navigation, melee, dodge/parry reactions, critical execution, stats/events/loot exactly once. Only dev-spawn registration initially, no normal wave/distribution change. Use explicitly provisional Grunt donor visuals and record missing original family. Avoid adding a bespoke AI/controller.
- Preserve: Existing NPA ability, reaction, death, loot, identity and relationship owners; existing LoP, production Operator/HUD/level loader; current tuning/authoritative signals, unless a demonstrated task-specific regression requires correction.
- Non-goals: No universal NPC class, duplicate combat/command authority, balance overhaul, fake runtime status, global campaign injection, or direct write into Asset V2-generated runtime assets.
- Acceptance: Scene instantiates without parse errors, attacks using existing authority, can be parried and killed once, valid corpse loot once, observability and collision work, no mandatory placeholder falsely called finished art.
- Validation: new npa_broken_warrant_smoke.gd; standard_enemy_melee, enemy_reaction_posture, grunt_parry_critical, lootable_corpse_beacon, scene/manifest/changed checks.
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
- Next workstream: `npa-showcase-escort-frame-m7-actor`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: normal dependency and latest-main reconciliation
- Next action: After this pair's independent review, inspect the next roadmap gate and promote only if its realized dependencies are satisfied.
- Blockers or open questions: none beyond repo-local authoring validation/promotion.
