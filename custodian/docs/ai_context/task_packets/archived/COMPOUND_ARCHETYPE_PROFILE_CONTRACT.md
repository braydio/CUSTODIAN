# COMPOUND ARCHETYPE PROFILE CONTRACT

- Packet schema: custodian.task_packet.v2
- Workstream: compound-archetype-profile-contract
- Authoring handoff: auto
- Status: `complete`
- Dispatch: `auto`
- Priority: P1
- Depends on: none
- Locks: compound-layout
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, visual
- Paired review workstream: review-compound-archetype-profile-contract
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independently landable cross-system change requiring fresh-context review
- Reviewed main: 9b8ae05581e3194876d8b4763946d1f74d77fa50
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Visual review: conditional
- Goal: Select deterministic walled_yard or connected_bunker profile without changing the current legacy layout by default.
- Completion boundary: Select deterministic walled_yard or connected_bunker profile without changing the current legacy layout by default. All listed acceptance cases must pass on the real runtime.
- Current measured state: At reviewed baseline, only the original semantic campus is implemented. Archetypes and connected full recovery loop are not shipped; inspect latest main and predecessor review changes before editing.
- Evidence: design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md; existing system files named under Task-specific authority.
- Task-specific authority: custodian/game/world/compound/rooms/persistent_compound_layout_planner.gd; custodian/game/world/compound/rooms/graphs/persistent_compound_layout_v1.json; custodian/game/world/procgen/proc_gen_tilemap.gd; custodian/game/world/procgen/custodian_contract_map.gd
- Work surface: custodian/game/world/compound/rooms/persistent_compound_layout_planner.gd; custodian/game/world/compound/rooms/graphs/persistent_compound_layout_v1.json; custodian/game/world/procgen/proc_gen_tilemap.gd; custodian/game/world/procgen/custodian_contract_map.gd; minimal adjacent validation and authoritative documentation.
- Change: Extend existing load_default_graph()/generate_layout(seed, compound_rect, ingress) via an optional verified profile argument/config loaded from one PROPOSED profile JSON. Keep one RNG and one graph owner. Add validated immutable archetype_id/layer metadata to level_data and retain current rooms/connections/corridor_cells/courtyard_cells/anchors, Sector IDs, minimap and old callers; unknown ID fails closed. Do not change existing default output.
- Preserve: One tile/navigation authority, room IDs and legacy default, player identity, existing infra/power/resource/wave owners, current Carrow routing, 32px grid and approved art.
- Non-goals: No independent simulator, automatic art approval/ingest, unrestricted construction, new faction/monitoring UI, or python-sim migration.
- Acceptance: For each of seeds 1,2,3,10,42,99,1337, unchanged legacy output, repeatable selected-profile output, invalid ID rejects, no duplicate room IDs or existing connector mismatch.
- Validation: Existing persistent_compound_layout_smoke and persistent_compound_runtime_smoke plus NEW focused profile determinism test; create new tests before invoking them as file references. New smoke names are proposed, not currently runnable scripts.
- Task overrides: none
- Deferred: New physical layers, production art and runtime security.

## Low-token implementation contract

Extend existing load_default_graph()/generate_layout(seed, compound_rect, ingress) via an optional verified profile argument/config loaded from one PROPOSED profile JSON. Keep one RNG and one graph owner. Add validated immutable archetype_id/layer metadata to level_data and retain current rooms/connections/corridor_cells/courtyard_cells/anchors, Sector IDs, minimap and old callers; unknown ID fails closed. Do not change existing default output.

## Closeout

Return changed files, measured acceptance, focused test evidence, documentation drift corrections and independent review link. New art is optional until the later human visual gate.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: All seven required seeds passed repeatability and unchanged-topology checks for the three profiles; invalid IDs failed closed; room and connector identities remained consistent. `compound_archetype_profile_smoke`, `persistent_compound_layout_smoke`, `persistent_compound_runtime_smoke`, and the 74-check changed-file sweep passed. The runtime smoke reports three Godot resources still in use at process exit after its pass result.
- Landed implementation: pending `workstream.py finish`.

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: initial coordination checkout was 52 commits behind with a dirty unrelated packet; an early `last-claim` observation referred to a review packet absent from current `origin/main`; the first changed-file sweep correctly caught a stale accepted-world export hash/key-count fixture after the three metadata fields were added.
- Root cause / contributing factors: claim state was inspected before fetching current `origin/main`; the accepted-world export parity contract intentionally pins the full data hash and exact key count.
- Prevention / pipeline improvement: fetch before resolving dispatch state; keep the parity fixture update coupled to additive level-data schema changes.
- Tooling / docs drift discovered: the stale review receipt did not resolve to an active packet, and `paired_review_runner.py` correctly failed closed; no code or packet change was needed for that stale claim.
- Follow-up: none
- What worked: isolated dispatcher worktree, fixed-seed equality checks, and single-owner ProcGen level-data export.

## Next Handoff
- Next workstream: `review-compound-archetype-profile-contract`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Refresh reason: none
- Next action: after implementation lands and archives complete, launch the fresh-context paired review through `paired_review_runner.py`.
- Blockers or open questions: none; physical walled-yard geometry, subsurface bunker travel, and gameplay remain deferred to downstream packets.

## Independent Review

### Review Receipt: review-compound-archetype-profile-contract
- Schema: `custodian.paired_review.v1`
- Review workstream: `review-compound-archetype-profile-contract`
- Review target workstream: `compound-archetype-profile-contract`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Reviewed main: `b414f16e9e61e78ed9bcc0dbcee99372698e2869`
- Reviewed implementation commit: `4e9d9feaa0eea6d4ea3824efaf6c2a1c9783cfc6`
