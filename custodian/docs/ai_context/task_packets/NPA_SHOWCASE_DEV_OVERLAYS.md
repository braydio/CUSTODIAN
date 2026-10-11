# NPA Gallery Debug and Dev Overlays

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-dev-overlays`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-npa-showcase-arena-foundation`
- Locks: `npa-showcase-level`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-npa-showcase-dev-overlays`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `b0ff835f8006d5ff6f250e682328512f8aa771d4`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `conditional`
- Goal: Add a dev-only, bounded observable actor-state panel and deterministic scenario controls to the playable gallery.
- Completion boundary: Add a dev-only, bounded observable actor-state panel and deterministic scenario controls to the playable gallery. Must land scoped real runtime/source changes, focused owned validation and a fresh independent paired review; no diagram-only or proxy closure.
- Current measured state: NPA showcase arena foundation/paired review archived complete; real root is custodian/game/world/levels/authored/dev/npa_showcase_arena/; DevObservatory/actor facades exist, but no showcase overlay/scenario controller exists. Uncreated M-7/Warrant actors must show N/A/disabled in controls until instantiated.
- Evidence: custodian/game/world/levels/authored/dev/npa_showcase_arena/npa_showcase_arena.gd and .tscn, npa_showcase_arena_playtest.tscn; archived NPA_SHOWCASE_ARENA_FOUNDATION.md and paired review; existing DevObservatory. New overlay/controller and smoke are proposed outputs, not already-present code.
- Task-specific authority: Active actor/level/Asset V2 design and live runtime under Work surface; this program's design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md.
- Work surface: custodian/game/world/levels/authored/dev/npa_showcase_arena/npa_showcase_debug_overlay.gd/.tscn; npa_showcase_scenario_controller.gd; focused overlay smoke
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

## Ready/auto dependency and publication contract (2026-10-11)
The original speculative-design hold has been reconciled: this is an implementation-ready, dependency-gated pair, **not user-manual dispatch timing**. Before a claim, the execution coordinator MUST run the repository-local targeted `validate_task_packet_authoring.py` on both this implementation and its paired review, then `task_packet_index.py` and `dispatch.py audit --json`; stop and repair if those authoritative checks fail. Current-main GitHub-only metadata checks do NOT prove Godot or full local authoring validation, nor authorize a bypass of existing locks/claims. New source art, final human art approval, NPA-8 and unrelated H5 are out of scope.

## Current-main measured clarification
Actual registered arena lives at custodian/game/world/levels/authored/dev/npa_showcase_arena/, NOT the nonexistent npa_actor_showcase/ path. Arena foundation/review are complete. Missing M-7/Warrant state must show disabled/N/A without synthesizing actor controls; ensure no global gameplay input leak.
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Handoff
- Next workstream: `npa-showcase-actor-art-intake`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: normal dependency and latest-main reconciliation
- Next action: After this pair's independent review, inspect the next roadmap gate and promote only if its realized dependencies are satisfied.
- Blockers or open questions: none beyond repo-local authoring validation/promotion.
