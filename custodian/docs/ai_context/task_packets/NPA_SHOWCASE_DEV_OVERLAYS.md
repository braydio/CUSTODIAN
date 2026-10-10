# NPA Gallery Debug and Dev Overlays

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-dev-overlays`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `npa-showcase-arena-foundation`
- Locks: `npa-showcase-level`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-npa-showcase-dev-overlays`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `6a5a60ddbf`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `conditional`
- Goal: Add a dev-only, bounded observable actor-state panel and deterministic scenario controls to the playable gallery.
- Completion boundary: Add a dev-only, bounded observable actor-state panel and deterministic scenario controls to the playable gallery. Must land scoped real runtime/source changes, focused owned validation and a fresh independent paired review; no diagram-only or proxy closure.
- Current measured state: LoP exposes static samples and input cycling but not live per-instance NPA diagnostics; DevObservatory and actor public state facades are already present.
- Evidence: custodian/game/world/levels/authored/dev/npa_actor_showcase/npa_showcase_debug_overlay.gd/.tscn; npa_showcase_scenario_controller.gd; focused overlay smoke; design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md; design/05_levels/LORDS_OF_PAIN_TEST_GALLERY.md; NPA-6 reviewed receipts.
- Task-specific authority: Active actor/level/Asset V2 design and live runtime under Work surface; this program's design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md.
- Work surface: custodian/game/world/levels/authored/dev/npa_actor_showcase/npa_showcase_debug_overlay.gd/.tscn; npa_showcase_scenario_controller.gd; focused overlay smoke
- Change: Implement overlay panel for selected live actor instance/class/role, allegiance and target eligibility, current target, health/death/corpse stage, reaction/ability phase if public, drone squad ID/anchor/fire mode, and status N/A when absent. Use semantic public facades or narrow adapters to read state, no parallel mutable state. Add deterministic local buttons/keys for spawn/reset, melee/ability, target/allegiance switch, death/loot and M7 commands through their real owners. Never consume Operator input/DroneManager T/G/J/K, and disable scenario writes outside this registered dev level. Bound event log and avoid per-frame DevObservatory writes.
- Preserve: Existing NPA ability, reaction, death, loot, identity and relationship owners; existing LoP, production Operator/HUD/level loader; current tuning/authoritative signals, unless a demonstrated task-specific regression requires correction.
- Non-goals: No universal NPC class, duplicate combat/command authority, balance overhaul, fake runtime status, global campaign injection, or direct write into Asset V2-generated runtime assets.
- Acceptance: Truthful per-actor cards and transitions, no duplicate gameplay authority, no stale freed-object exceptions, no production control leak, readable responsive UI and deterministic resets.
- Validation: new npa_showcase_overlay_smoke.gd; dev scene wrapper/single-Operator checks; objective layout/ROI crop only when needed; changed/manifest/diff.
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
- Next workstream: `npa-showcase-actor-art-intake`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: normal dependency and latest-main reconciliation
- Next action: After this pair's independent review, inspect the next roadmap gate and promote only if its realized dependencies are satisfied.
- Blockers or open questions: none beyond repo-local authoring validation/promotion.
