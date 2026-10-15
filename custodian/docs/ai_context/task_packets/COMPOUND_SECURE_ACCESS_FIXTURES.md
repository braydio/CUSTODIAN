# COMPOUND SECURE ACCESS FIXTURES

- Packet schema: custodian.task_packet.v2
- Workstream: compound-secure-access-fixtures
- Authoring handoff: auto
- Status: `ready`
- Dispatch: `auto`
- Priority: P1
- Depends on: review-compound-interior-traversal-integration
- Locks: compound-security
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, visual
- Paired review workstream: review-compound-secure-access-fixtures
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independently landable cross-system change requiring fresh-context review
- Reviewed main: 9b8ae05581e3194876d8b4763946d1f74d77fa50
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Visual review: conditional
- Goal: Introduce one shared functional secure threshold/access-panel fixture for both archetypes.
- Completion boundary: Introduce one shared functional secure threshold/access-panel fixture for both archetypes. All listed acceptance cases must pass on the real runtime.
- Current measured state: At reviewed baseline, only the original semantic campus is implemented. Archetypes and connected full recovery loop are not shipped; inspect latest main and predecessor review changes before editing.
- Evidence: design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md; existing system files named under Task-specific authority.
- Task-specific authority: custodian/game/world/procgen/proc_gen_tilemap.gd; custodian/game/infrastructure/infrastructure_structure.gd; existing grid power components; design/02_features/stealth/STEALTH_PERCEPTION_AND_ALARM_SYSTEM.md
- Work surface: custodian/game/world/procgen/proc_gen_tilemap.gd; custodian/game/infrastructure/infrastructure_structure.gd; existing grid power components; design/02_features/stealth/STEALTH_PERCEPTION_AND_ALARM_SYSTEM.md; minimal adjacent validation and authoritative documentation.
- Change: Add PROPOSED small component custodian/game/world/compound/security/secured_threshold.gd with stable ID, room/layer, allowed-actor/access policy and closed/open/locked/breached physical state; bind an adjacent access panel and local powered light. Request real tile/collision/nav updates from ProcGenTilemap (do not disable only visual). Define per-threshold fail-safe/secure behavior plus emergency Operator egress; source-tagged local security observation/event only, no global alarm or third sensing bus. Existing turret hardpoints remain existing turret owner.
- Preserve: One tile/navigation authority, room IDs and legacy default, player identity, existing infra/power/resource/wave owners, current Carrow routing, 32px grid and approved art.
- Non-goals: No independent simulator, automatic art approval/ingest, unrestricted construction, new faction/monitoring UI, or python-sim migration.
- Acceptance: In A and B: closed gate physically blocks, authorized open passes, denied access stays closed, power loss has deterministic defined outcome with safe egress, breached remains physically passable until repaired, local event source is correct.
- Validation: NEW threshold collision/power/egress tests plus existing power/nav and security receiver regression. New smoke names are proposed, not currently runnable scripts.
- Task overrides: none
- Deferred: Video feeds, radar, new faction credential authority, global alert UI.

## Low-token implementation contract

Add PROPOSED small component custodian/game/world/compound/security/secured_threshold.gd with stable ID, room/layer, allowed-actor/access policy and closed/open/locked/breached physical state; bind an adjacent access panel and local powered light. Request real tile/collision/nav updates from ProcGenTilemap (do not disable only visual). Define per-threshold fail-safe/secure behavior plus emergency Operator egress; source-tagged local security observation/event only, no global alarm or third sensing bus. Existing turret hardpoints remain existing turret owner.

## Closeout

Return changed files, measured acceptance, focused test evidence, documentation drift corrections and independent review link. New art is optional until the later human visual gate.
