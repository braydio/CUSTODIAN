# Broken Warrant Runtime Actor

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-broken-warrant-actor`
- Status: `blocked`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-npa-showcase-existing-enemy-hardening`
- Locks: `enemy-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-npa-showcase-broken-warrant-actor`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `b0ff835f8006d5ff6f250e682328512f8aa771d4`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Goal: Create one distinctive Broken Warrant hostile archetype with real melee/reactions/death/corpse/loot and no duplicate Enemy mechanics.
- Completion boundary: Create one distinctive Broken Warrant hostile archetype with real melee/reactions/death/corpse/loot and no duplicate Enemy mechanics. Must land scoped real runtime/source changes, focused owned validation and a fresh independent paired review; no diagram-only or proxy closure.
- Current measured state: No Broken Warrant actor or asset family exists. EnemyGrunt has configurable NPA melee, reaction, parry-critical, lifecycle, behavior and optionally Grunt Falcon Punch.
- Evidence: archived/NPA_SHOWCASE_EXISTING_ENEMY_HARDENING.md plus its independently passed review; custodian/game/actors/enemies/enemy_grunt.tscn; existing Enemy melee/reaction/lifecycle owners; design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md. Broken Warrant scene and smoke are planned outputs, not existing evidence.
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

## Ready/auto dependency and publication contract (2026-10-11)
The original speculative-design hold has been reconciled: this is an implementation-ready, dependency-gated pair, **not user-manual dispatch timing**. Before a claim, the execution coordinator MUST run the repository-local targeted `validate_task_packet_authoring.py` on both this implementation and its paired review, then `task_packet_index.py` and `dispatch.py audit --json`; stop and repair if those authoritative checks fail. Current-main GitHub-only metadata checks do NOT prove Godot or full local authoring validation, nor authorize a bypass of existing locks/claims. New source art, final human art approval, NPA-8 and unrelated H5 are out of scope.

## Current-main measured clarification
Existing-enemy showcase hardening and independent review are complete. Broken Warrant, its proposed scene and its new validation smoke do not exist yet. Reuse EnemyGrunt combat/reaction/death authority, disable optional Falcon Punch, and explicitly label donor art provisional.
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Handoff
- Next workstream: `npa-showcase-escort-frame-m7-actor`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: normal dependency and latest-main reconciliation
- Next action: After this pair's independent review, inspect the next roadmap gate and promote only if its realized dependencies are satisfied.
- Blockers or open questions: none beyond repo-local authoring validation/promotion.

## Execution Feedback
- Outcome: partial; implementation and focused actor checks are present, but required changed-file sweep did not pass.
- Validation evidence: changed-file sweep selected 42 checks, passed 38, timed out `command_terminal_tutorial`, `terminal_page_order_regression`, and `terminal_sensors_layout` at 120 seconds, skipped downstream `awakening_late_seams_v1`, and reported complete coverage with no uncovered files. Focused Broken Warrant and shared-authority tests passed independently.
- Blocker: existing procgen-backed checks remain over the runner's 120-second timeout in this environment. The attempted timeout increase did not resolve it and has been reverted; no broad timeout policy change is retained.
- Tooling / docs drift discovered: none; the runner reported the changed files and coverage correctly.
- Recovery: preserve this branch and rerun the changed sweep after the procgen checks or execution environment can complete within their configured budget.
