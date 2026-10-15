# COMPOUND RECOVERY END TO END PROOF

- Packet schema: custodian.task_packet.v2
- Workstream: compound-recovery-end-to-end-proof
- Authoring handoff: auto
- Status: draft
- Dispatch: manual
- Priority: P1
- Depends on: review-compound-recovery-assault-objectives, review-compound-recovery-field-repair, review-compound-recovery-build-restoration
- Locks: compound-proof
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, visual
- Paired review workstream: review-compound-recovery-end-to-end-proof
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independently landable cross-system change requiring fresh-context review
- Reviewed main: 9b8ae05581e3194876d8b4763946d1f74d77fa50
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Visual review: conditional
- Goal: Verify full defend, damage, resource-choice, repair/build and restoration cycle in both archetypes.
- Completion boundary: Verify full defend, damage, resource-choice, repair/build and restoration cycle in both archetypes. All listed acceptance cases must pass on the real runtime.
- Current measured state: At reviewed baseline, only the original semantic campus is implemented. Archetypes and connected full recovery loop are not shipped; inspect latest main and predecessor review changes before editing.
- Evidence: design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md; existing system files named under Task-specific authority.
- Task-specific authority: Existing EnemyDirector, WaveManager, power/InfrastructureRegistry, Operator repair and construction authorities; NEW deterministic integrated scenario harness
- Work surface: Existing EnemyDirector, WaveManager, power/InfrastructureRegistry, Operator repair and construction authorities; NEW deterministic integrated scenario harness; minimal adjacent validation and authoritative documentation.
- Change: Build seeded A/B scenarios: stage prep, one brief physical-objective assault, degrade real power/defense/fabrication, choose constrained repair OR fabricate and place a Capacitor Bank, restore partial/full capability, prepare next assault, leave/revisit. Log objective/door/layer identity, damage, grid/service deltas, materials spent, construction state and recovery outcome in machine-readable report. Use small screenshots only for human gameplay readability; tests don't self-certify game feel.
- Preserve: One tile/navigation authority, room IDs and legacy default, player identity, existing infra/power/resource/wave owners, current Carrow routing, 32px grid and approved art.
- Non-goals: No independent simulator, automatic art approval/ingest, unrestricted construction, new faction/monitoring UI, or python-sim migration.
- Acceptance: No target bypass, no impossible repairs/ghost builds, resource pressure changes decisions, both strategies create measurable next-attack differences, state and Operator identity persist, deterministic seeds pass and human feel stays unapproved.
- Validation: NEW integrated A/B scenario plus existing wave/power/repair/placement/world-route focused suites. New smoke names are proposed, not currently runnable scripts.
- Task overrides: none
- Deferred: Full offline simulation, persistent world politics, CCTV/radar/drone monitoring and final production art.

## Low-token implementation contract

Build seeded A/B scenarios: stage prep, one brief physical-objective assault, degrade real power/defense/fabrication, choose constrained repair OR fabricate and place a Capacitor Bank, restore partial/full capability, prepare next assault, leave/revisit. Log objective/door/layer identity, damage, grid/service deltas, materials spent, construction state and recovery outcome in machine-readable report. Use small screenshots only for human gameplay readability; tests don't self-certify game feel.

## Closeout

Return changed files, measured acceptance, focused test evidence, documentation drift corrections and independent review link. New art is optional until the later human visual gate.
