# COMPOUND RECOVERY FIELD REPAIR

- Packet schema: custodian.task_packet.v2
- Workstream: compound-recovery-field-repair
- Authoring handoff: auto
- Status: `ready`
- Dispatch: `auto`
- Priority: P1
- Depends on: review-compound-recovery-damage-coupling
- Locks: compound-repair
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, visual
- Paired review workstream: review-compound-recovery-field-repair
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independently landable cross-system change requiring fresh-context review
- Reviewed main: 9b8ae05581e3194876d8b4763946d1f74d77fa50
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Visual review: conditional
- Goal: Repair infrastructure by locally holding the existing Operator repair control and paying finite resources.
- Completion boundary: Repair infrastructure by locally holding the existing Operator repair control and paying finite resources. All listed acceptance cases must pass on the real runtime.
- Current measured state: At reviewed baseline, only the original semantic campus is implemented. Archetypes and connected full recovery loop are not shipped; inspect latest main and predecessor review changes before editing.
- Evidence: design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md; existing system files named under Task-specific authority.
- Task-specific authority: custodian/game/actors/operator/operator.gd existing Hold-R logic; custodian/game/infrastructure/infrastructure_structure.gd heal(); custodian/game/systems/core/systems/damageable.gd; current ResourceLedger API
- Work surface: custodian/game/actors/operator/operator.gd existing Hold-R logic; custodian/game/infrastructure/infrastructure_structure.gd heal(); custodian/game/systems/core/systems/damageable.gd; current ResourceLedger API; minimal adjacent validation and authoritative documentation.
- Change: Resolve nearest valid InfrastructureStructure via the existing repair target path, without per-frame whole-tree search or a second repair mode. Apply heal(rate*delta) only while in range, valid/powered as defined and with paid materials through ResourceLedger. Track sub-HP fractional costs deterministically to avoid FPS/rounding arbitrage. Interrupting retains previous progress; destroyed rejects heal; prompt shows current HP/materials. Do not hardcode incompatible legacy 5/12/15 HP/s assumptions without choosing one current balance value.
- Preserve: One tile/navigation authority, room IDs and legacy default, player identity, existing infra/power/resource/wave owners, current Carrow routing, 32px grid and approved art.
- Non-goals: No independent simulator, automatic art approval/ingest, unrestricted construction, new faction/monitoring UI, or python-sim migration.
- Acceptance: A/B repair changes real grid/service, spends correct resources exactly once, halts when empty, interrupted progress persists, no remote targeting, no destroyed resurrection or double billing.
- Validation: Existing Operator repair plus NEW resource accounting, interrupted/denied and two-profile target tests. New smoke names are proposed, not currently runnable scripts.
- Task overrides: none
- Deferred: Remote repair drones, new repair tool sprite, economy tuning.

## Low-token implementation contract

Resolve nearest valid InfrastructureStructure via the existing repair target path, without per-frame whole-tree search or a second repair mode. Apply heal(rate*delta) only while in range, valid/powered as defined and with paid materials through ResourceLedger. Track sub-HP fractional costs deterministically to avoid FPS/rounding arbitrage. Interrupting retains previous progress; destroyed rejects heal; prompt shows current HP/materials. Do not hardcode incompatible legacy 5/12/15 HP/s assumptions without choosing one current balance value.

## Closeout

Return changed files, measured acceptance, focused test evidence, documentation drift corrections and independent review link. New art is optional until the later human visual gate.
