# NPA Artwork Completion Audit

- Packet schema: `custodian.task_packet.v2`
- Workstream: `npa-showcase-artwork-completion-audit`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `npa-showcase-actor-art-intake`
- Locks: `asset-pipeline`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, asset-pipeline`
- Paired review workstream: `review-npa-showcase-artwork-completion-audit`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial actor/showcase integration; independent correctness and source-ownership review`
- Reviewed main: `6a5a60ddbf`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `conditional`
- Goal: Independently fail closed on unfinished art and produce an actionable completion matrix before final gallery closeout.
- Completion boundary: Independently fail closed on unfinished art and produce an actionable completion matrix before final gallery closeout. Must land scoped real runtime/source changes, focused owned validation and a fresh independent paired review; no diagram-only or proxy closure.
- Current measured state: The source masters, catalog entries, new family statuses and bound runtime state coverage do not yet exist; donor art is not original art.
- Evidence: two family contracts, required_assets.registry.json, runtime sprite resources, live animation selectors, art validator and focused review evidence; design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md; design/05_levels/LORDS_OF_PAIN_TEST_GALLERY.md; NPA-6 reviewed receipts.
- Task-specific authority: Active actor/level/Asset V2 design and live runtime under Work surface; this program's design/04_architecture/NPA_ACTOR_SHOWCASE_PROGRAM.md.
- Work surface: two family contracts, required_assets.registry.json, runtime sprite resources, live animation selectors, art validator and focused review evidence
- Change: Audit each required family/state/direction against real source_work/inbox provenance, catalog, imported SpriteFrames, alpha geometry, frame count/dimensions/FPS/ground anchor, live semantic selection and any required parry victim strips. Record source bytes/hash and objective preview ROIs. Do not infer artistic approval from generated images or scripts; route meaningful visual judgment through one human/ChatGPT review manifest and record decision. For every missing art state create exact filepath/pixels/frame/FPS and required remediation, and remain blocked until corrected. Keep required_assets.registry and family status honest.
- Preserve: Existing NPA ability, reaction, death, loot, identity and relationship owners; existing LoP, production Operator/HUD/level loader; current tuning/authoritative signals, unless a demonstrated task-specific regression requires correction.
- Non-goals: No universal NPC class, duplicate combat/command authority, balance overhaul, fake runtime status, global campaign injection, or direct write into Asset V2-generated runtime assets.
- Acceptance: Zero missing required art, zero improper donor fallbacks, all scenes runtime verified for actual visual transitions; explicit human approval where necessary, completion evidence linked.
- Validation: asset.py status/doctor/needs --check; per-cell integrity and live state smoke, ROI review evidence, changed/manifest checks.
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
- Next workstream: `npa-showcase-complete-arena`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: Refresh from landed two actor presentation consumers AND actual human-reviewed original art source; source creation is a real outside input and not available at authoring.
- Next action: After this pair's independent review, inspect the next roadmap gate and promote only if its realized dependencies are satisfied.
- Blockers or open questions: Refresh from landed two actor presentation consumers AND actual human-reviewed original art source; source creation is a real outside input and not available at authoring.
