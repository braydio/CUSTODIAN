# Broken Warrant and M-7 Asset V2 Intake

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-actor-art-intake`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `npa-showcase-broken-warrant-actor, npa-showcase-escort-frame-m7-actor`
- Locks: `asset-pipeline`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, asset-pipeline`
- Paired review workstream: `review-npa-showcase-actor-art-intake`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `6a5a60ddbf`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `conditional`
- Goal: Create real original production sprite families for BOTH new actors through Asset Pipeline V2 and wire their real scene presentation.
- Completion boundary: Create real original production sprite families for BOTH new actors through Asset Pipeline V2 and wire their real scene presentation. Must land scoped real runtime/source changes, focused owned validation and a fresh independent paired review; no diagram-only or proxy closure.
- Current measured state: No new art sources or V2 families exist. Enemy kind is registered; no allied_actor kind schema exists. Grunt donor uses 96x96 and selected 156x156 paired victim assets; droid donor uses 96x96 5f idle/6f run E/W.
- Evidence: custodian/content/metadata/assets/families/{npa_broken_warrant,npa_escort_frame_m7}.asset.json; optional schemas/allied_actor.json; source_work/actors/; inbox/; scene presentation bindings; required_assets.registry.json; art validation smoke; design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md; design/05_levels/LORDS_OF_PAIN_TEST_GALLERY.md; NPA-6 reviewed receipts.
- Task-specific authority: Active actor/level/Asset V2 design and live runtime under Work surface; this program's design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md.
- Work surface: custodian/content/metadata/assets/families/{npa_broken_warrant,npa_escort_frame_m7}.asset.json; optional schemas/allied_actor.json; source_work/actors/; inbox/; scene presentation bindings; required_assets.registry.json; art validation smoke
- Change: After actors land, freeze exact presentation consumers and create V2 family contracts under custodian/content/metadata/assets/families. Register an appropriate supported ally kind or introduce valid allied_actor schema backed by existing sprite ingest, only after source schema check. Warrant original body E/W: idle 5f 480x96, run 6f 576x96, melee 9f 864x96, flinch 5f 480x96, stagger 8f 768x96, death 5f 480x96, all 96px frames; required 156x156 execution victim strips if execution consumer requires them, 12f 1872x156 E/W; reversal 8f 1248x156 only if enabled. M7 E/W 96px: idle 5f 480x96, run 6f 576x96, fire 4f 384x96, hit 3f 288x96, destroyed 5f 480x96, all actual trigger-bound. Artist-reviewed original source `custodian/asset_drop/source_work/actors/<family>/<state>_source.png`, normalized true-alpha strips in `custodian/asset_drop/inbox/<family>/<state>.png`. Use plan/ingest/status/doctor, immutable source checks, generated canonical runtime naming and validated scene bindings. If art input missing, report missing sources and stop, no fake art.
- Preserve: Existing NPA ability, reaction, death, loot, identity and relationship owners; existing LoP, production Operator/HUD/level loader; current tuning/authoritative signals, unless a demonstrated task-specific regression requires correction.
- Non-goals: No universal NPC class, duplicate combat/command authority, balance overhaul, fake runtime status, global campaign injection, or direct write into Asset V2-generated runtime assets.
- Acceptance: All required original states have valid source evidence, true alpha, canonical geometry/timing/ground anchor, catalog import and trigger-bound runtime, zero silent donors; honest unmet requirements remain incomplete until actual art exists.
- Validation: asset.py plan/status/doctor/needs --check; sprite alpha/geometry/frame test, animation trigger test; minimal contact sheets; changed/manifest/diff. Human visual approval where subjective.
- Task overrides: `none`
- Deferred: Later showcase slices, NPA-8 species command convergence, unrelated production content.

## Refresh Planning Authority
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh instruction: Refresh from landed two actor presentation consumers AND actual human-reviewed original art source; source creation is a real outside input and not available at authoring.

## Program Publication Gate
These packets are authored **draft/manual** on main as a planning series because there is no local Godot checkout/authoring validator in this session. They are not dispatcher-claimable. Execution/promoting agent: inspect main + AGENTS + dispatch audit; run `python3 custodian/tools/agent/validate_task_packet_authoring.py` on each implementation and review pair; reconcile dependency and exact test references; promote mechanically unlocked pairs to ready/auto; rerun validator; regenerate/verify `task_packet_index.py`; land the promotion safely; confirm dispatcher audit/eligibility. A declared implementation dependency also requires its paired review archived complete before consumer claim. Keep external refresh-gated pairs draft until their real evidence is available.

## Handoff
- Next workstream: `npa-showcase-artwork-completion-audit`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: Refresh from landed two actor presentation consumers AND actual human-reviewed original art source; source creation is a real outside input and not available at authoring.
- Next action: After this pair's independent review, inspect the next roadmap gate and promote only if its realized dependencies are satisfied.
- Blockers or open questions: Refresh from landed two actor presentation consumers AND actual human-reviewed original art source; source creation is a real outside input and not available at authoring.
