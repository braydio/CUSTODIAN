# NPA Full Five Actor Showcase Closeout

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-complete-arena`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `npa-showcase-arena-foundation, npa-showcase-existing-enemy-hardening, npa-showcase-existing-drone-hardening, npa-showcase-existing-vaultwing-proof, npa-showcase-broken-warrant-actor, npa-showcase-escort-frame-m7-actor, npa-showcase-dev-overlays, npa-showcase-artwork-completion-audit`
- Locks: `npa-showcase-level`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-npa-showcase-complete-arena`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `6a5a60ddbf`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `conditional`
- Goal: Deliver the complete, accessible, interactive five-actor NPA arena with final artwork, real runtime authority, overlay proof, world return and independent acceptance.
- Completion boundary: Deliver the complete, accessible, interactive five-actor NPA arena with final artwork, real runtime authority, overlay proof, world return and independent acceptance. Must land scoped real runtime/source changes, focused owned validation and a fresh independent paired review; no diagram-only or proxy closure.
- Current measured state: Live LoP is gallery precedent; the required NPA actor roster and dedicated test arena do not exist yet, and new art/dependency gates remain.
- Evidence: custodian/game/world/levels/authored/dev/npa_actor_showcase/; content level/registry; five actor scenes; scenario manifest and full arena smoke; docs/manifest; design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md; design/05_levels/LORDS_OF_PAIN_TEST_GALLERY.md; NPA-6 reviewed receipts.
- Task-specific authority: Active actor/level/Asset V2 design and live runtime under Work surface; this program's design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md.
- Work surface: custodian/game/world/levels/authored/dev/npa_actor_showcase/; content level/registry; five actor scenes; scenario manifest and full arena smoke; docs/manifest
- Change: Instantiate Broken Warrant (Grunt-based, unique scene/art), Escort Frame M-7 (reviewed Drone/manager), existing Marine, Savage, Common Vaultwing in the real dev level. Bind actual combat, melee/parry/reaction, dash, pounce/chain, damage/death/corpse/loot, command and ally target/rejection, and Vaultwing same-instance hostile/bond/allegiance proof. Stage deterministic lane trigger/reset with no fake result fields; ensure safe spawn/nav, bullet/loot roots, real Operator and camera in wrapper, normal route ingress/reentry, five live overlay cards, asset V2 completion. Demonstrate invalidated target mid-burst and passive Shrumb explicit-order scenario as optional fixture. Update CURRENT_STATE, FILE_INDEX and NPA roadmap to landed truth only after tests pass.
- Preserve: Existing NPA ability, reaction, death, loot, identity and relationship owners; existing LoP, production Operator/HUD/level loader; current tuning/authoritative signals, unless a demonstrated task-specific regression requires correction.
- Non-goals: No universal NPC class, duplicate combat/command authority, balance overhaul, fake runtime status, global campaign injection, or direct write into Asset V2-generated runtime assets.
- Acceptance: All five unique live actor types instanced and exercise/reset successfully, new actor art verified, 5 scenario classes pass, real corpse loot once, allegiance change stops ally fire, no duplicate Operator/AI/route authority, world return/reentry, complete changed-file coverage and passed independent review.
- Validation: new levels/npa_showcase_complete_smoke.gd; all predecessor focused checks; actor_relationship_contract; level ingress/reentry; Asset V2 status/doctor; run_validation.py --changed --json, AI-context/diff; limited real walkaround and justified small objective screenshots.
- Task overrides: `none`
- Deferred: Later showcase slices, NPA-8 species command convergence, unrelated production content.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh instruction: Refresh after every predecessor has passed independent review, especially NPA-7, Vaultwing and real Asset V2 completion. Do not close on stand-ins.

## Program Publication Gate
These packets are authored **draft/manual** on main as a planning series because there is no local Godot checkout/authoring validator in this session. They are not dispatcher-claimable. Execution/promoting agent: inspect main + AGENTS + dispatch audit; run `python3 custodian/tools/agent/validate_task_packet_authoring.py` on each implementation and review pair; reconcile dependency and exact test references; promote mechanically unlocked pairs to ready/auto; rerun validator; regenerate/verify `task_packet_index.py`; land the promotion safely; confirm dispatcher audit/eligibility. A declared implementation dependency also requires its paired review archived complete before consumer claim. Keep external refresh-gated pairs draft until their real evidence is available.

## Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: Refresh after every predecessor has passed independent review, especially NPA-7, Vaultwing and real Asset V2 completion. Do not close on stand-ins.
- Next action: After independent final review, record real five-actor milestone and stop.
- Blockers or open questions: Refresh after every predecessor has passed independent review, especially NPA-7, Vaultwing and real Asset V2 completion. Do not close on stand-ins.
