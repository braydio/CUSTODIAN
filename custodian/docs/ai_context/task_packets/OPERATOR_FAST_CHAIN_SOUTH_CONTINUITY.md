# OPERATOR FAST CHAIN SOUTH CONTINUITY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-fast-chain-south-continuity`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-assets, operator-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, runtime, visual`
- Paired review workstream: `review-operator-fast-chain-south-continuity`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial Operator production-art/runtime change with semantic fallback, registration, and visual-chain continuity risk`
- Reviewed main: `b57ab98db06b697bdb300e397feb67e02c1563fe`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac323e0-c600-83ea-bb5c-c706c785cf73`
- Summary backlink: Include this exact Authoring chat URL in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Finish the authored south-facing Fists fast-chain presentation so Fast 01 → Fast 02 → Fast 03 → Fast 04 reads as one stable combat-ready chain without the current Fast 02-04 east-facing fallback, scale/pelvis/cloth discontinuity, registration jump, or directional FX mismatch.
- Completion boundary: Done when Fast 02, Fast 03, and Fast 04 each have reviewed canonical south `lower_body`, `upper_body`, and direction-appropriate `fx` identities at the existing 96×96-cell / 6f, 7f, 8f contracts; runtime selection resolves exact south for all four links; the existing Fast 01 south source/runtime remains unchanged unless an objective defect is proven; gameplay timing/hit windows/order are untouched; focused Operator asset/runtime validation is green; and the final chained south playback is handed to the user/ChatGPT through the compact visual-review lane for subjective acceptance.
- Current measured state:
  - Fast 01 South is already exact-authored and live as synchronized 6-frame 96×96 lower/upper modular layers; `OPERATOR_FAST_01_SOUTH_MODULAR_CLAUDE_SUMMARY.md` records byte-identical recomposition.
  - Fast 02-04 South still resolve through east fallback. Current main has no canonical `operator__{lower_body,upper_body}__unarmed__attack__fast_0{2,3,4}__s__...` source files.
  - Current canonical E/W modular body layers exist for Fast 02/03/04 at 6/7/8 frames and 96×96 cells, and E/W directional FX exists for those links.
  - The recovered immutable high-resolution Fast 01 South generation/source master is now preserved at `custodian/asset_drop/source_work/operator/unarmed/attack/fast_01/south/fast_1_south.png` with LFS SHA-256 `9b079688917b620d6fd46102e0ec5d6d36896fef416b7c676da36cc7a5a5723f`.
  - The accepted normalized Fast 01 South full-body strip remains `576×96`, 6 frames, 96×96 each, SHA-256 `d28913bff81f9ae63d8f215a752ba4ece4e89413c46f0c943239c6597ad614b2`.
  - Existing Fast 02 E source layer examples are `...fast_02__e__6f__96.png`; Fast 03 uses 7f; Fast 04 uses 8f. Preserve those contracts rather than reviving stale historical frame counts.
- Evidence:
  - `OPERATOR_FAST_01_SOUTH_MODULAR_CLAUDE_SUMMARY.md`
  - `custodian/tools/validation/operator_fast01_south_decomposition_smoke.py`
  - `custodian/tools/validation/operator_unarmed_fast_chain_smoke.gd`
  - `custodian/tools/operator/build_fast01_south_modular_layers.py`
  - `custodian/tools/operator/unarmed_fast_chain_prepare.py`
  - `custodian/content/sprites/operator/runtime/operator_runtime_manifest.generated.json`
  - `custodian/content/data/operator/operator_animation_reachability.json`
  - current canonical Fast 02/03/04 E/W source/runtime layers under `custodian/content/sprites/operator/{source,runtime}/animations/unarmed/attack/`
  - `design/02_features/animation/OPERATOR_ART_AGENT_SYSTEM.md`
  - `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`
  - `custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`
- Task-specific authority: Current Operator Workbench/Art Agent + specialized Operator publication path; `operator_art_profile.json` registration contract; canonical generated runtime manifest/reachability; live Fists fast-chain timing/profile data. Historical `agent/operator-fast-chain-continuity` packet prose is donor evidence only and is not executable authority.
- Work surface: Operator source-work/Source Session evidence for this chain; isolated `workbench/operator-art` authoring checkout where required; Fast 02/03/04 south lower/upper/FX source and runtime outputs; generated Operator runtime catalog/reachability; selector/presentation seams only as needed to remove south fallback; focused validation; one compact visual-review handoff.
- Change:
  1. Re-audit current canonical Fast 01-04 south/east/west identities before editing. Treat 6/6/7/8 frame counts and 96×96 runtime cells as locked unless current live authority explicitly proves otherwise.
  2. Preserve the recovered high-resolution Fast 01 South source master as immutable donor/reference evidence. Do not normalize it again merely because it was newly restored to main, and do not overwrite the accepted Fast 01 South canonical strip/layers without objective defect proof.
  3. Author or reconstruct **Fast 02 South, Fast 03 South, and Fast 04 South** through the current Operator Workbench/Art Agent path. Prefer current reviewed chain pixels and established semantic layer ownership over freehand redesign. Do not simply rotate/mirror East into South.
  4. Maintain chain continuity across the Fast 01→02 boundary and through 03/04: stable foot baseline, character scale, pelvis/leg proportion, garment/loin-cloth continuity, body center/origin, and readable distinct attack silhouettes. Motion should advance through the chain rather than making 02-04 near-duplicates of Fast 01.
  5. Required normalized/canonical south contracts:
     - `fast_02`: 6 frames, `576×96` total, `96×96` cells, lower + upper + FX, non-looping.
     - `fast_03`: 7 frames, `672×96` total, `96×96` cells, lower + upper + FX, non-looping.
     - `fast_04`: 8 frames, `768×96` total, `96×96` cells, lower + upper + FX, non-looping.
     - true RGBA alpha, stable registration, no cross-cell bleed. Runtime-ready production art must satisfy the repository's no-cleanup/import-ready rule.
  6. Use current Operator registration/profile tooling. If starting from a high-resolution candidate, use a Source Session with one shared crop/scale/placement across the entire strip and the required crisp converter path; do not hand-resize individual frames independently.
  7. Publish through the specialized Operator pipeline only. Do not hand-wire `asset_drop` paths, hand-author generated catalog entries, or bypass the reviewed Workbench publication transaction.
  8. Make exact South selection succeed for lower/upper/FX on Fast 02-04. Remove only the now-obsolete South→East fallback for identities that become complete; preserve fallback behavior for genuinely missing unrelated directions/actions.
  9. Do not change Fists gameplay timing, attack profiles, commit/contact frames, drive, damage, stamina, hit windows, four-link ordering, buffering, or target selection.
  10. Objective validation precedes visual review: exact dimensions/frame counts, alpha bounds, per-frame silhouette/clipping, registration/baseline metrics, lower+upper composition completeness, selector identity, synchronized layer clocks, and chain playback timing.
  11. After objective checks are green, run the smallest useful south Fast 01→04 runtime sequence and publish **one compact Dropbox review handoff** with tight gameplay-scale crops/contact sheet and the exact questions: (a) does 01→02 preserve body scale/pelvis/cloth continuity, (b) do 02→03→04 remain distinct/readable while sharing one grounded registration, and (c) are directional FX readable without overpowering the Operator? Do not let the coding agent self-approve the subjective baseline.
  12. If no viable South art can be produced from current repository-authorized inputs/tooling without inventing/redesigning the character, checkpoint with the precise missing source/art decision and keep current production fallback intact. Do not publish a weak substitute merely to satisfy coverage.
- Preserve: Current Fast 01 South pixels and modular decomposition; current E/W Fast 01-04 assets; specialized Operator source/runtime ownership; current fast-chain gameplay profiles/timing; current Workbench isolated-publish safety; unrelated Operator animations and loadouts.
- Non-goals: No fast-chain gameplay retune. No heavy attacks. No guard/blocking work. No broad Operator runtime refactor. No canvas-size migration to 128 for this chain. No automatic subjective art approval. No changes to Twin Solaria, Awakening, Vaultwing, procgen, or branch-hygiene tooling.
- Acceptance:
  - canonical South Fast 02/03/04 lower+upper+FX assets exist at exact 6/7/8-frame 96×96 contracts;
  - runtime selector resolves exact South for Fast 01-04 with synchronized visible lower/upper/FX clocks and no East fallback for those complete identities;
  - lower+upper composition is complete with no clipping, missing garment pixels, scale jump, baseline drift, or cell bleed;
  - Fast 01 canonical South hashes/pixels are unchanged unless an objective defect and explicit replacement receipt justify a change;
  - Fists gameplay timing/profile values are byte/semantic-equivalent before vs after;
  - focused Operator asset/schema/selector/fast-chain tests pass;
  - one compact external visual handoff is published and the human/ChatGPT baseline decision is recorded before final art acceptance;
  - documentation/generated reachability truth describes exact South coverage without stale fallback claims.
- Validation: Start with exact image/hash/registration checks and the current Operator animation contract report. Run `operator_fast01_south_decomposition_smoke.py`, the focused selector tests, `operator_unarmed_fast_chain_smoke.gd`, specialized Operator pipeline smoke/schema checks, and a current south modular preview/combo check. Run the smallest changed-file closeout only after focused tests pass. Use Moment Forge/evidence only if runtime-scale chain timing/readability cannot be proven by the existing preview/telemetry path; never use repeated full-frame captures.
- Task overrides: `none`
- Deferred: North/diagonal authored Fast 02-04 expansion; any chain gameplay retune; optional additional VFX redesign beyond making current South directional FX coherent.

## Handoff

- Next action: Claim this packet in an Operator-art-capable environment, reconstruct current chain truth, then author Fast 02-04 South candidates through the isolated Workbench/Art Agent path.
- Best starting files: `OPERATOR_FAST_01_SOUTH_MODULAR_CLAUDE_SUMMARY.md`, current Fast 02-04 E/W canonical layers, `operator_unarmed_fast_chain_smoke.gd`, Workbench/Art Agent docs and source-session tooling.
- Blockers or open questions: Final subjective chain baseline remains human-owned. Technical implementation may proceed immediately; weak/unreviewable art must fail closed to the current fallback rather than land.