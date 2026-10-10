# NPA Showcase Arena Foundation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-arena-foundation`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `npa-showcase-level`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-npa-showcase-arena-foundation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `6a5a60ddbf`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `conditional`
- Goal: Deliver an actual registered five-zone authored development level and standalone playtest with real Operator and safe world ingress/return.
- Completion boundary: Deliver an actual registered five-zone authored development level and standalone playtest with real Operator and safe world ingress/return. Must land scoped real runtime/source changes, focused owned validation and a fresh independent paired review; no diagram-only or proxy closure.
- Current measured state: The Lords of Pain gallery is registered with production destination, generated standalone playtest wrapper, Spawn_Main, WorldIngressSite and InteractableLevelExit2D. No NPA showcase level exists.
- Evidence: custodian/game/world/levels/authored/dev/npa_actor_showcase/; custodian/content/levels/dev/npa_actor_showcase/; custodian/content/levels/levels.json; custodian/tools/validation/levels/npa_showcase_arena_foundation_smoke.gd; design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md; design/05_levels/LORDS_OF_PAIN_TEST_GALLERY.md; NPA-6 reviewed receipts.
- Task-specific authority: Active actor/level/Asset V2 design and live runtime under Work surface; this program's design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md.
- Work surface: custodian/game/world/levels/authored/dev/npa_actor_showcase/; custodian/content/levels/dev/npa_actor_showcase/; custodian/content/levels/levels.json; custodian/tools/validation/levels/npa_showcase_arena_foundation_smoke.gd
- Change: Use canonical authored-level scaffolding to register npa_actor_showcase with Spawn_Main and Return_Main, five connected walkable zones: arrival, reaction/parry, dash/pounce, allegiance/orders, death/corpse/loot. Keep production scene free of Operator, camera and PlayerController. Standalone wrapper uses exactly one real Operator, controller, camera, normal Combat/navigation/projectile roots. Ingress/return use existing route manager and retain Operator on re-entry. Provide empty actor sockets and safe dev-only scenario roots; no fabricated actor simulation.
- Preserve: Existing NPA ability, reaction, death, loot, identity and relationship owners; existing LoP, production Operator/HUD/level loader; current tuning/authoritative signals, unless a demonstrated task-specific regression requires correction.
- Non-goals: No universal NPC class, duplicate combat/command authority, balance overhaul, fake runtime status, global campaign injection, or direct write into Asset V2-generated runtime assets.
- Acceptance: All five areas reachable, collision-safe and resettable; level registry/metadata/ingress/return valid; no second Operator/controller/camera in destination; standalone loads and returns with same Operator.
- Validation: levels/lords_of_pain_test_gallery_smoke.gd for precedent; level_registry_contract; authored_level_ingress_return; world_ingress_physics_reentry; new focused arena smoke; changed/manifest/diff checks.
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
- Next workstream: `npa-showcase-existing-enemy-hardening`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: normal dependency and latest-main reconciliation
- Next action: After this pair's independent review, inspect the next roadmap gate and promote only if its realized dependencies are satisfied.
- Blockers or open questions: none beyond repo-local authoring validation/promotion.
