# NPA Showcase Arena Foundation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-arena-foundation`
- Status: `complete`
- Dispatch: `auto`
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
- Current measured state: The Lords of Pain gallery is the registered precedent. The NPA Showcase Arena is now registered with a five-zone production destination, full standalone playtest wrapper, Spawn_Main, default WorldIngressSite ingress and explicit InteractableLevelExit2D return.
- Evidence: `design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md`; `design/05_levels/LORDS_OF_PAIN_TEST_GALLERY.md`; current `AuthoredLevel2D`, `WorldIngressSite`, level registry and lifecycle smoke contracts; completed NPA-6/NPA-7 review evidence.
- Task-specific authority: Active actor/level/Asset V2 design and live runtime under Work surface; this program's design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md.
- Work surface: `custodian/game/world/levels/authored/dev/npa_showcase_arena/`; `custodian/content/levels/dev/npa_showcase_arena/`; `custodian/content/levels/levels.json`; `custodian/tools/validation/validation_manifest.json`; `custodian/tools/validation/levels/npa_showcase_arena_foundation_smoke.gd`; `design/05_levels/NPA_SHOWCASE_ARENA.md`; `design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md`; `custodian/docs/ai_context/CURRENT_STATE.md`.
- Change: Used the canonical authored-level scaffold to register npa_showcase_arena with Spawn_Main and Return_Main, five physically-connected walkable zones: arrival, reaction/parry, dash/pounce, allegiance/orders, death/corpse/loot. Production scene is free of Operator, camera and PlayerController. Standalone wrapper instantiates exactly one real Operator, controller, camera and normal Combat/navigation/projectile roots. Default WorldIngressSite and explicit return use the existing route manager and retain Operator on re-entry. Empty actor sockets and disabled dev-only scenario roots contain no fabricated actor simulation.
- Preserve: Existing NPA ability, reaction, death, loot, identity and relationship owners; existing LoP, production Operator/HUD/level loader; current tuning/authoritative signals, unless a demonstrated task-specific regression requires correction.
- Non-goals: No universal NPC class, duplicate combat/command authority, balance overhaul, fake runtime status, global campaign injection, or direct write into Asset V2-generated runtime assets.
- Acceptance: All five areas reachable, collision-safe and resettable; level registry/metadata/ingress/return valid; no second Operator/controller/camera in destination; standalone loads and returns with same Operator.
- Validation: `level_registry_contract`; `authored_level_ingress_return`; `world_ingress_physics_reentry`; `lords_of_pain_test_gallery`; focused `npa_showcase_arena_foundation`; changed/manifest/diff checks.
- Task overrides: `none`
- Deferred: Later showcase slices, NPA-8 species command convergence, unrelated production content.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md`; `design/05_levels/LORDS_OF_PAIN_TEST_GALLERY.md`; current `AuthoredLevel2D`, `WorldIngressSite`, level registry and lifecycle smoke contracts; completed NPA-6/NPA-7 review evidence.

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The first canonical generator run emitted noisy in-process parse errors while validating newly generated resources; the first focused smoke also used a node search overload incorrectly.`
- Root cause / contributing factors: `Generator resource validation ran against project global-class state in the same process that created the resources; the test helper filtered by type instead of recursively counting names.`
- Prevention / pipeline improvement: `Run generated-level checks from a fresh validation process and use explicit recursive ownership counts in scene-contract tests.`
- Tooling / docs drift discovered: `The NPA showcase program note still said NPA-7 was absent and that no packet had been promoted; both notes are reconciled to current main and the current packet lifecycle.`
- Follow-up: `review-npa-showcase-arena-foundation`
- What worked: `Canonical authored-level generator, existing level registry, WorldIngressSite and route manager.`

## Validation Evidence
- `npa_showcase_arena_foundation`: passed 1/1.
- `level_registry_contract`, `authored_level_ingress_return`, `world_ingress_physics_reentry`, and `lords_of_pain_test_gallery`: passed 1/1 each when run individually.
- Final `--changed --json` report: `/tmp/npa-showcase-changed-final.json`.
- `task_packet_index.py` / validation manifest parse and `git diff --check`: passed.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh instruction: Verify latest main, actual changed file and test identities; run targeted authoring preflight on this implementation and review before promotion.

## Program Publication Gate
These packets are authored **draft/manual** on main as a planning series because there is no local Godot checkout/authoring validator in this session. They are not dispatcher-claimable. Execution/promoting agent: inspect main + AGENTS + dispatch audit; run `python3 custodian/tools/agent/validate_task_packet_authoring.py` on each implementation and review pair; reconcile dependency and exact test references; promote mechanically unlocked pairs to ready/auto; rerun validator; regenerate/verify `task_packet_index.py`; land the promotion safely; confirm dispatcher audit/eligibility. A declared implementation dependency also requires its paired review archived complete before consumer claim. Keep external refresh-gated pairs draft until their real evidence is available.

## Next Handoff
- Next workstream: `review-npa-showcase-arena-foundation`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `none`
- Next action: `Run the paired fresh-context review; after it passes, reconcile npa-showcase-existing-enemy-hardening against current main and perform its required authoring promotion if eligible.`
- Blockers or open questions: `none`

## Independent Review
- Schema: `custodian.paired_review.v1`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Nonblocking findings: `0`
- Optional findings: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Reviewed main: `456cc9e1d392f01978742728ba145a135678ac04`
- Findings: `none`
- Focused validation: `level_registry_contract`, `authored_level_ingress_return`, `world_ingress_physics_reentry`, `npa_showcase_arena_foundation`, and `lords_of_pain_test_gallery` all passed individually. Changed-file validation passed 37/37 with complete coverage; `git diff --check HEAD^ HEAD`, manifest JSON parsing, and task-packet index validation passed.
- Fault checks: `The arena smoke crossed all four divider openings and confirmed the outer perimeter collision prevents escape. It also checked exact zone/socket counts, empty disabled scenario roots, no Operator/controller/camera in the destination, and exactly one production Operator/controller/camera in the playtest wrapper.`
- Review conclusion: `The landed arena uses the existing AuthoredLevel2D, level registry, WorldIngressSite, InteractableLevelExit2D, route manager, and lifecycle loader seams. Five bounded zones and doorway-separated collision are runtime checked; the registered default ingress targets Spawn_Main; explicit return and reset-on-entry preserve actor identity through the lifecycle fixture. The production scene owns no player runtime, while the standalone wrapper references the real Operator scene once and disables debug auto-spawn. No blocking defect or material acceptance-proof gap remains.`
- Visual disposition: `No art was generated; this is a labeled development blockout. Objective geometry, visibility structure, collision and ownership are covered by deterministic scene/runtime checks; no subjective art-direction gate is applicable.`
- Reviewed implementation commit: `456cc9e1d392f01978742728ba145a135678ac04`
- Follow-up workstream: `none`

## Handoff
- Next workstream after paired review: `npa-showcase-existing-enemy-hardening`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `normal dependency and latest-main reconciliation`
- Next action: `After the pair passes, inspect the next roadmap gate and promote only if realized dependencies are satisfied.`
- Blockers or open questions: `none beyond the next packet's repo-local authoring validation/promotion.`
