# COMPOUND RECOVERY BUILD RESTORATION

- Packet schema: custodian.task_packet.v2
- Workstream: compound-recovery-build-restoration
- Authoring handoff: auto
- Status: `ready`
- Dispatch: `auto`
- Priority: P1
- Depends on: review-compound-recovery-damage-coupling
- Locks: compound-construction
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, visual
- Paired review workstream: review-compound-recovery-build-restoration
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independently landable cross-system change requiring fresh-context review
- Reviewed main: 9b8ae05581e3194876d8b4763946d1f74d77fa50
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Visual review: conditional
- Goal: Place and commission an existing Capacitor Bank as additional infrastructure through valid sites in either compound.
- Completion boundary: Place and commission an existing Capacitor Bank as additional infrastructure through valid sites in either compound. All listed acceptance cases must pass on the real runtime.
- Current measured state: At 934805e71ac4e82c4588365f5e7e1dddea912eaa: Type A and Type B geometry are implemented. The Type A independent review remains active; Type B parent review concluded with R0-01 (unconsumed vertical-entry anchors) and R0-02 (missing collision/navigation/camera proof). The existing `compound-connected-bunker-blockout-review-corrections-1` correction and paired `review-compound-connected-bunker-blockout-review-corrections-1` own both defects, and its `agent/` branch is already published. All later traversal/security/assault/recovery gameplay is unimplemented or unaccepted; do not duplicate that correction or bypass either review.
- Evidence: design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md; existing system files named under Task-specific authority.
- Task-specific authority: custodian/game/infrastructure/construction_placement_controller.gd attempt_commit_at(); construction_placement_validator.gd; construction_catalog.gd; BuildInventory; InfrastructureStructure; InfrastructureRegistry
- Work surface: custodian/game/infrastructure/construction_placement_controller.gd attempt_commit_at(); construction_placement_validator.gd; construction_catalog.gd; BuildInventory; InfrastructureStructure; InfrastructureRegistry; minimal adjacent validation and authoritative documentation.
- Change: Extend current construction-zone anchors with archetype-specific valid yards (A) and approved underground service bays or surface pads (B); add layer-aware floor/reservation validation before token commit, preserving atomic remove/refund semantics. Use existing Capacitor Bank ready-build ID and its current +250 reserve on commissioning, never raw material subtraction in placement or separate power grid. Test recovery after damage and exit/revisit with stable structure ID. No additional structure catalog needed.
- Preserve: One tile/navigation authority, room IDs and legacy default, player identity, existing infra/power/resource/wave owners, current Carrow routing, 32px grid and approved art.
- Non-goals: No independent simulator, automatic art approval/ingest, unrestricted construction, new faction/monitoring UI, or python-sim migration.
- Acceptance: Both types: valid token spends once, invalid/gate/blocked/cross-layer placement spends zero, capacity changes only on commissioning, destroyed removes service, reentry restores exactly same object without ghost reserve.
- Validation: Existing placement/validator/capacitor/registry tests plus NEW A/B layer-site, atomicity and persistence smoke. New smoke names are proposed, not currently runnable scripts.
- Task overrides: none
- Deferred: Unrestricted wall/roof construction, new big structures/art, NPC workforce.

## Low-token implementation contract

Extend current construction-zone anchors with archetype-specific valid yards (A) and approved underground service bays or surface pads (B); add layer-aware floor/reservation validation before token commit, preserving atomic remove/refund semantics. Use existing Capacitor Bank ready-build ID and its current +250 reserve on commissioning, never raw material subtraction in placement or separate power grid. Test recovery after damage and exit/revisit with stable structure ID. No additional structure catalog needed.

## Closeout

Return changed files, measured acceptance, focused test evidence, documentation drift corrections and independent review link. New art is optional until the later human visual gate.

## Planning refresh (2026-10-17)

- Source snapshot: `934805e71ac4e82c4588365f5e7e1dddea912eaa`. Keep all existing post-land review dependencies; verify newer actual `origin/main` and accepted review receipts before implementation.
- Only `custodian/docs/ai_context/task_packets/COMPOUND_INTERIOR_TRAVERSAL_INTEGRATION.md` and B correction own cross-layer entrance mechanics. This packet must not introduce a duplicate transit controller or independent structural/power state.
