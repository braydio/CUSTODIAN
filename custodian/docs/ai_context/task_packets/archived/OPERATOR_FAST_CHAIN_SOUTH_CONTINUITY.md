# OPERATOR FAST CHAIN SOUTH CONTINUITY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-fast-chain-south-continuity`
- Status: `complete`
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
- Goal: Intake the approved Operator Fists Fast 01 North and Fast 02-04 North/South full-body source masters, normalize at 96×96 cells, derive exact modular body layers, and seed transparent editable FX tracks only for missing Fast 02-04 North/South identities. Preserve the existing Fast 01 South body/FX and Fast 01 North FX authorities; do not represent transparent FX placeholders as finished VFX.
- Completion boundary: Done when the seven approved body strips are preserved byte-for-byte, normalized using the repository pixelart alias at 96×96 cells and split into `lower_body` / `upper_body` such that every nontransparent full-body source pixel is owned by exactly one semantic body layer and recomposition is exact; missing Fast 02-04 North/South FX source identities exist as true-alpha-zero strips through the specialized Operator pipeline; existing Fast 01 South body/FX and Fast 01 North FX hashes are unchanged; current 6/6/7/8 gameplay timing/profile values are unchanged; and focused Operator ingest/schema/selector/chain validation is green. Visual review must identify FX placeholders as intentionally empty and exclude VFX-completion claims.
- Current measured state:
  - Fast 01 South is exact-authored and live as synchronized 6-frame 96×96 lower/upper modular layers; `OPERATOR_FAST_01_SOUTH_MODULAR_CLAUDE_SUMMARY.md` records byte-identical recomposition.
  - Fast 01 North currently has full-body and FX sources; Fast 01 South has full-body, lower/upper, and FX sources. Preserve the existing Fast 01 North/South FX source/runtime files and Fast 01 South body/source/runtime.
  - Fast 02-04 North/South full-body sources are supplied by the Dropbox handoff; Fast 02-04 North/South canonical body and FX sources are absent on current main.
  - Current East/West canvas contracts are mixed (Fast 02 is 128×128; Fast 03/04 are 96×96). The explicit user override below sets all new authored North/South body and FX art to 96×96; this does not migrate existing East/West art.
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
- Work surface: Dropbox handoff source masters and immutable `asset_drop/source_work` copies; 96×96 whole-strip normalization; Fast 01 North plus Fast 02-04 North/South full-body/lower/upper sources and runtime outputs; missing Fast 02-04 North/South transparent FX tracks; generated Operator runtime catalog/reachability; focused validation; one compact visual-review handoff.
- Change:
  1. Re-audit current canonical Fast 01-04 directional identities before editing. Treat 6/6/7/8 frame counts as locked. Apply the user-supplied 96×96 override to every new North/South body and FX identity even where East/West currently uses 128×128.
  2. Preserve the recovered high-resolution Fast 01 South source master as immutable donor/reference evidence. Do not normalize it again merely because it was newly restored to main, and do not overwrite the accepted Fast 01 South canonical strip/layers without objective defect proof.
  3. Preserve the seven approved Dropbox source masters byte-for-byte in their packaged `source_work` destinations. Normalize Fast 01 North and Fast 02-04 North/South using one shared strip transform per animation and crisp pixelart method 1. Derive exact `lower_body` / `upper_body` layers without recoloring or synthesizing pixels.
  4. Maintain chain continuity across the Fast 01→02 boundary and through 03/04: stable foot baseline, character scale, pelvis/leg proportion, garment/loin-cloth continuity, body center/origin, and readable distinct attack silhouettes. Motion should advance through the chain rather than making 02-04 near-duplicates of Fast 01.
  5. Required new North/South body contracts: Fast 01 = 6 frames/576×96; Fast 02 = 6/576×96; Fast 03 = 7/672×96; Fast 04 = 8/768×96; all with 96×96 cells and exact lower/upper recomposition. All remain non-looping.
     - true RGBA alpha, stable registration, no cross-cell bleed. Runtime-ready production art must satisfy the repository's no-cleanup/import-ready rule.
  6. Use current Operator registration/profile tooling. If starting from a high-resolution candidate, use a Source Session with one shared crop/scale/placement across the entire strip and the required crisp converter path; do not hand-resize individual frames independently.
  7. Publish through the specialized Operator pipeline only. Do not hand-wire `asset_drop` paths or hand-author generated catalog entries. Publish supplied strips and blank FX through the existing specialized Operator inbox/ingest/runtime-build pipeline; subsequently authored VFX must use the guarded OPUI/Aseprite Workbench REPLACE transaction.
  8. Seed blank FX only if the exact North/South identity is currently absent: Fast 02 N/S 6f, Fast 03 N/S 7f, Fast 04 N/S 8f. Each placeholder must be true RGBA, all alpha zero, and ingested through the specialized Operator pipeline. Never replace Fast 01 N/S FX or claim VFX completion from blank tracks.
  9. Ensure exact North/South lower/upper/FX identities resolve for the new tracks while preserving unrelated fallback behavior.
  10. Do not change Fists gameplay timing, attack profiles, commit/contact frames, drive, damage, stamina, hit windows, four-link ordering, buffering, or target selection.
  11. Objective validation precedes visual review: exact dimensions/frame counts, alpha bounds, no boundary clipping, stable shared registration, lower+upper composition completeness, zero-alpha placeholder proof, selector identity, synchronized layer clocks, and chain playback timing.
  12. After objective checks are green, run the smallest useful Fast 01→04 North/South playback and publish one compact review handoff. Ask about body scale/pelvis/cloth continuity, distinctness/readability, and grounded registration. Clearly label Fast 02-04 North/South FX tracks as intentionally transparent placeholders; do not ask reviewers to assess finished VFX or approve them as complete.
- Preserve: Current Fast 01 South pixels and modular decomposition; current E/W Fast 01-04 assets; specialized Operator source/runtime ownership; current fast-chain gameplay profiles/timing; current Workbench isolated-publish safety; unrelated Operator animations and loadouts.
- Non-goals: No fast-chain gameplay retune. No heavy attacks. No guard/blocking work. No broad Operator runtime refactor. No existing East/West canvas migration. No VFX authoring or completion claims for transparent placeholders. No automatic subjective art approval. No unrelated feature work.
- Acceptance:
  - all supplied Fast 01 North and Fast 02-04 North/South body strips are preserved, normalized to 96×96 cells, and decomposed exactly;
  - missing Fast 02-04 North/South FX identities are zero-alpha editable tracks, while Fast 01 North/South FX remain unchanged;
  - runtime selector resolves exact North/South body and FX identities for affected links with synchronized body-layer clocks;
  - lower+upper composition is complete with no clipping, missing garment pixels, scale jump, baseline drift, or cell bleed;
  - Fast 01 canonical South hashes/pixels are unchanged unless an objective defect and explicit replacement receipt justify a change;
  - Fists gameplay timing/profile values are byte/semantic-equivalent before vs after;
  - focused Operator asset/schema/selector/fast-chain tests pass;
  - one compact external visual handoff describes authored body art and accurately labels blank FX placeholders;
  - no VFX requirement is marked complete from placeholder tracks and documentation/generated reachability truth does not overstate VFX coverage.
- Validation: Start with exact image/hash/registration checks and the current Operator animation contract report. Run `operator_fast01_south_decomposition_smoke.py`, `operator_unarmed_fast_chain_smoke.gd -- --selection-only` for exact directional layer/clock validation, `operator_modular_fast_attack_smoke.gd`, `operator_modular_layers_smoke.gd`, and the specialized Operator pipeline/schema checks. Also run the full chain gameplay smoke and compare any unrelated carry-fixture failures against baseline; Fast 02-04 North/South FX tracks are intentionally transparent authoring placeholders, not completed VFX. Run the smallest changed-file closeout only after focused tests pass. Use Moment Forge/evidence only if runtime-scale chain timing/readability cannot be proven by the existing preview/telemetry path; never use repeated full-frame captures.
- Task overrides: `USER OVERRIDE (2026-10-05): all new authored Operator body/FX art is 96×96 cells via the repository pixelart alias, crisp method 1, using one shared whole-strip transform; preserve Fast 01 South body/FX and existing Fast 01 North FX; split approved N/S full-body strips into exact lower/upper layers; create zero-alpha FX placeholders only for missing Fast 02-04 N/S identities; ingest those tracks through the specialized Operator pipeline; placeholders are not VFX completion; later VFX edits use guarded OPUI/Aseprite REPLACE publication.`
- Deferred: diagonal authored Fast 02-04 expansion; real Fast 02-04 North/South VFX authoring in OPUI/Aseprite Workbench using the canonical placeholder tracks and guarded REPLACE publication; any chain gameplay retune; the three baseline carry interruption/collision smoke failures.

## Handoff

- Next action: Paired post-land review of the North/South body art and registration; keep blank FX explicitly labeled as authoring placeholders.
- Best starting files: `OPERATOR_FAST_CHAIN_SOUTH_CONTINUITY_CLAUDE_SUMMARY.md`, this packet, and the compact review artifact manifest.
- Blockers or open questions: Subjective body scale, pelvis/cloth continuity, silhouette distinctness, and grounding remain human-owned; the six Fast 02-04 N/S FX tracks are intentionally transparent authoring placeholders; three broad-chain carry interruption/collision assertions remain baseline-equivalent and are deferred outside this art slice.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `handoff strip widths for Fast 03/04 were not divisible by their frame counts. An initial per-run packing attempt conflicted with the shared-transform override and was discarded. The full chain smoke retains three carry interruption/collision failures also present on baseline.`
- Root cause / contributing factors: `the supplied masters have non-divisible whole-strip widths for Fast 03/04; the test camera probe was created after actor dependency capture, and the carry assertions also fail on baseline.`
- Prevention / pipeline improvement: `crop only the whole strip to frame-count divisibility, apply one converter transform to the strip, and run the shared runtime rebuild across all profiles after profile-scoped source intake.`
- Tooling / docs drift discovered: `the chain smoke encoded Fast 02-04 South as East fallback despite this packet introducing exact South assets; removed that stale expectation. Injected the camera dependency in its fixture so camera checks run correctly. The remaining three carry interruption/collision assertions fail identically on baseline commit 16566c48 and on this branch; gameplay production code is untouched.`
- Follow-up: `manual-follow-up`
- What worked: `pixelart method 1, exact recomposition, and the specialized Operator ingest created canonical 96-cell layers and transparent FX bindings without gameplay edits.`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: seven byte-exact approved masters, seven shared-strip 96×96 conversions, 1:1 lower/upper partition and exact recomposition proofs, six true RGBA alpha-zero FX tracks through Operator source/runtime/catalog, protected Fast 01 South body/FX and Fast 01 North FX hashes unchanged, strict contract report with no missing required entries, focused selector smoke and modular asset smokes pass, no gameplay source/profile changes, compact Dropbox visual-review manifest uploaded. Full chain smoke retains three carry-interruption/collision fixture failures also present on baseline commit `16566c48`.
