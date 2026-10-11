# Existing Vaultwing Relationship Proof

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-existing-vaultwing-proof`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-vaultwing-runtime-hardening, review-vaultwing-world-spawn-integrity-recovery-v1`
- Locks: `vaultwing-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-npa-showcase-existing-vaultwing-proof`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `b0ff835f8006d5ff6f250e682328512f8aa771d4`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Goal: Make the existing Common Vaultwing a reliable wildlife/relationship demonstration without adding companion commands prematurely.
- Completion boundary: Make the existing Common Vaultwing a reliable wildlife/relationship demonstration without adding companion commands prematurely. Must land scoped real runtime/source changes, focused owned validation and a fresh independent paired review; no diagram-only or proxy closure.
- Current measured state: Common Vaultwing already implements wild hostile flight bands, same-instance allegiance change, bond state and active Asset V2 art; review-vaultwing-runtime-hardening is an active predecessor.
- Evidence: custodian/game/actors/ambient/vaultwing/; custodian/tools/validation/{vaultwing_runtime_smoke,vaultwing_bond_smoke,actor_relationship_contract_smoke}.gd; new arena Vaultwing fixture; design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md; design/05_levels/LORDS_OF_PAIN_TEST_GALLERY.md; NPA-6 reviewed receipts.
- Task-specific authority: Active actor/level/Asset V2 design and live runtime under Work surface; this program's design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md.
- Work surface: custodian/game/actors/ambient/vaultwing/; custodian/tools/validation/{vaultwing_runtime_smoke,vaultwing_bond_smoke,actor_relationship_contract_smoke}.gd; new arena Vaultwing fixture
- Change: After the Vaultwing hardening review lands, use the real Vaultwing species/actor state and public allegiance/bond seam to stage HIGH hostile-but-untargetable, attack/ground hostile-targetable, then operator-allied target-invalid on the SAME instance. Use only dev-local forced scenario requests and truthful labels; no species logic fork, fake bonding or world-state mutation beyond local fixture. If the reviewed interface differs, refresh this packet mechanically before ready promotion.
- Preserve: Existing NPA ability, reaction, death, loot, identity and relationship owners; existing LoP, production Operator/HUD/level loader; current tuning/authoritative signals, unless a demonstrated task-specific regression requires correction.
- Non-goals: No universal NPC class, duplicate combat/command authority, balance overhaul, fake runtime status, global campaign injection, or direct write into Asset V2-generated runtime assets.
- Acceptance: Identity/health/bond status retained through relationship switch, no drone/turret targeting after becoming allied, no HIGH flight target, no general NPA-8 command API introduced.
- Validation: vaultwing_runtime, vaultwing_bond, vaultwing_world_spawn, actor_relationship_contract and new same-instance proof, changed validation.
- Task overrides: `none`
- Deferred: Later showcase slices, NPA-8 species command convergence, unrelated production content.

## Refresh Planning Authority
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh instruction: Refresh actual runtime APIs AFTER review-vaultwing-runtime-hardening archives complete. Its review is currently a ready/auto predecessor.

## Ready/auto dependency and publication contract (2026-10-11)
The original speculative-design hold has been reconciled: this is an implementation-ready, dependency-gated pair, **not user-manual dispatch timing**. Before a claim, the execution coordinator MUST run the repository-local targeted `validate_task_packet_authoring.py` on both this implementation and its paired review, then `task_packet_index.py` and `dispatch.py audit --json`; stop and repair if those authoritative checks fail. Current-main GitHub-only metadata checks do NOT prove Godot or full local authoring validation, nor authorize a bypass of existing locks/claims. New source art, final human art approval, NPA-8 and unrelated H5 are out of scope.

## Current-main measured clarification
Runtime hardening implementation is archived complete, but its reviewer remains on a preserved active claim with an unlanded receipt; real-world Vaultwing spawn implementation/review are still pending. Both reviews must archive PASS before claim. Use live vaultwing.gd, vaultwing_bond_state.gd, ActorRelationshipResolver and the actual npa_showcase_arena level. This proof is not NPA-8 companion commands.
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Handoff
- Next workstream: `npa-showcase-broken-warrant-actor`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: Future reviewed-consumer API reconciliation is execution-agent owned, not a new human design gate.
- Next action: After this pair's independent review, inspect the next roadmap gate and promote only if its realized dependencies are satisfied.
- Blockers or open questions: Preserve original existing review claims and wait for named archived dependency reviews; do not fabricate a PASS.
