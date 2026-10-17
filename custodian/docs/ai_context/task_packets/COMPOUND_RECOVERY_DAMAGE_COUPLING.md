# COMPOUND RECOVERY DAMAGE COUPLING

- Packet schema: custodian.task_packet.v2
- Workstream: compound-recovery-damage-coupling
- Authoring handoff: auto
- Status: `ready`
- Dispatch: `auto`
- Priority: P1
- Depends on: review-compound-archetype-playable-proof
- Locks: compound-recovery
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, visual
- Paired review workstream: review-compound-recovery-damage-coupling
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independently landable cross-system change requiring fresh-context review
- Reviewed main: 9b8ae05581e3194876d8b4763946d1f74d77fa50
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Visual review: conditional
- Goal: Apply physical assault damage to power, defense and fabrication systems with actual service degradation.
- Completion boundary: Apply physical assault damage to power, defense and fabrication systems with actual service degradation. All listed acceptance cases must pass on the real runtime.
- Current measured state: At reviewed baseline, only the original semantic campus is implemented. Archetypes and connected full recovery loop are not shipped; inspect latest main and predecessor review changes before editing.
- Evidence: design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md; existing system files named under Task-specific authority.
- Task-specific authority: custodian/game/infrastructure/infrastructure_structure.gd take_damage()/heal()/get_integrity_modifier()/capture_infrastructure_state(); custodian/game/systems/core/systems/damageable.gd; InfrastructureRegistry and grid components
- Work surface: custodian/game/infrastructure/infrastructure_structure.gd take_damage()/heal()/get_integrity_modifier()/capture_infrastructure_state(); custodian/game/systems/core/systems/damageable.gd; InfrastructureRegistry and grid components; minimal adjacent validation and authoritative documentation.
- Change: Bind one live power, one defense and one fabrication target per archetype to InfrastructureStructure integrity and component output notifications; introduce only a narrow cross-actor Damageable compatibility adapter if required. Single integrity owner per object. Damage reduces generation, available turret effectiveness and service output; on zero destroyed capability unregisters. Revisit restores the correct degraded state; rebuild follows existing structure lifecycle, no healing a destroyed object.
- Preserve: One tile/navigation authority, room IDs and legacy default, player identity, existing infra/power/resource/wave owners, current Carrow routing, 32px grid and approved art.
- Non-goals: No independent simulator, automatic art approval/ingest, unrestricted construction, new faction/monitoring UI, or python-sim migration.
- Acceptance: Equal real damage in each archetype causes deterministic nonzero service loss, correct grid load-shedding, restoration via heal, exact snapshots and no ghost output/double health.
- Validation: Existing infrastructure/capacitor/service smokes and NEW archetype damage/revisit test. New smoke names are proposed, not currently runnable scripts.
- Task overrides: none
- Deferred: Economy balancing, destructible arbitrary walls, distant activity simulation.

## Low-token implementation contract

Bind one live power, one defense and one fabrication target per archetype to InfrastructureStructure integrity and component output notifications; introduce only a narrow cross-actor Damageable compatibility adapter if required. Single integrity owner per object. Damage reduces generation, available turret effectiveness and service output; on zero destroyed capability unregisters. Revisit restores the correct degraded state; rebuild follows existing structure lifecycle, no healing a destroyed object.

## Closeout

Return changed files, measured acceptance, focused test evidence, documentation drift corrections and independent review link. New art is optional until the later human visual gate.
