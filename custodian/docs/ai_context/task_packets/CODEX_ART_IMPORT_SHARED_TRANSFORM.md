# CODEX ART IMPORT SHARED TRANSFORM
- Packet schema: `custodian.task_packet.v2`
- Workstream: `codex-art-import-shared-transform`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-operator-art-registration-profile-review-corrections-1-r1`
- Locks: `sprite-import-core, operator-source-normalization`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-codex-art-import-shared-transform`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `reusable production-art geometry, safety, and authoring semantics require independent falsification`
- Reviewed main: `d099e541941c5f7525f7c9af38f6e36536f9d574`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Provide one deterministic, reusable source-sheet geometry and conversion-plan API for both generic Asset V2 and specialized Operator intake without introducing a second resize engine.
- Completion boundary: Same verified source+contract+options yield byte-identical plan and derived geometry; 8f and 6f golden dimensions exact; one global scale in every frame; no mixed-frame resizes, no clip, no smoothing; missing/ambiguous contracts fail; Operator existing tests remain green; no new publishing authority.
- Current measured state: pixelart converter already supplies split_sheet_frames, compute_shared_frame_transform, make_sheet_candidates, integer translation; Operator SourceArtService uses shared geometry but is Operator-specific; Asset Workbench V1 has read-only review and no generic normalization service.
- Evidence: main@d099e541941c; custodian/tools/art/custodian_pixelart_converter.py; custodian/tools/operator/art_agent/{source_normalization,source_service,registration_profile,mcp_server}.py; custodian/tools/assets/{asset_contract,asset_plan,asset_transaction}.py; custodian/tools/assets/asset_workbench/; current Asset V2 and Operator validation smokes.
- Task-specific authority: design/04_architecture/CODEX_ART_IMPORT_PIPELINE_V1.md; design/04_architecture/ASSET_PIPELINE_V2.md; design/04_architecture/ASSET_WORKBENCH_ROADMAP.md; design/02_features/animation/OPERATOR_ART_AGENT_SYSTEM.md; live AGENTS.
- Work surface: custodian/tools/art/custodian_pixelart_converter.py; new focused custodian/tools/assets/sprite_import/ package for immutable plans and adapters; custodian/tools/operator/art_agent/source_normalization.py (only for narrow adapter compatibility); focused fixture/test ownership.
- Change:
  1. Factor/reuse converter core as a side-effect-free geometry service, not a copied algorithm. Inputs: source bytes+SHA256; explicit rows/columns/frame count and cell width/height; explicit family/state/direction or Operator profile; exact target WxH; orientation/layout; alpha policy; one animation-wide crop, uniform scale, placement and output horizontal-strip contract. Inference is advisory: ambiguous grids, uneven division, invalid alpha, bad RGBA, unknown target geometry and missing semantic identity fail with actionable diagnostics; never guess frames by filename alone.
  2. Return a versioned canonical JSON plan with source digest, semantic/family or Operator profile digest, input layout/cell geometry, frame order, alpha-union bbox, one shared scale, global placement, target frame WxH, frame count, candidate method, expected strip WxH, per-frame integer registration initialized at [0,0], plan SHA256, and no write side effects. Canonicalize digest input deterministically with stable key order.
  3. Reuse current nearest-neighbor crisp engine for production-sized pixel art. Constrain all output to exact fixed cells; no independent per-frame alpha crop, scaling, smoothing, intelligent relayout or transparent-color bleeding. Preserve fully transparent RGB semantics/true alpha; reject clipping rather than shrink a single frame. Allow fully opaque tiles only when declared by an Asset V2 contract, not by fallback guess.
  4. Keep Operator's required `source tools/custodian_aliases.sh; pixelart <source> --choose 1 --normalization-plan ...` production pathway; generic callers may use the reusable Python core. Do not change 96px legacy profiles, accepted 128px profile, accepted plan-digest rules, Workbench publication or runtime sources.
  5. Add deterministic tests using 8x512 source to 8x128 strip (1024x128), 3x2 of 256x256 cells to six 128x128 strip (768x128), a 128x160 1-frame prop, uneven/ambiguous input, repeated replay hashes and overflow refusal. Register focused ownership in validation_manifest.json.
- Preserve: Canonical source masters, existing Asset V2 and specialized Operator contract owners, authored frame timing and pose motion, existing accepted profile geometry, no new art-generation authority.
- Non-goals: No production artwork alterations, no new character design, no gameplay/timing/balance changes, no auto-publishing via MCP, no new runtime output naming database, and no repeated per-frame normalization.
- Acceptance: Same verified source+contract+options yield byte-identical plan and derived geometry; 8f and 6f golden dimensions exact; one global scale in every frame; no mixed-frame resizes, no clip, no smoothing; missing/ambiguous contracts fail; Operator existing tests remain green; no new publishing authority.
- Validation: Run existing custodian/tools/validation/operator_art_source_smoke.py and custodian/tools/validation/operator_art_registration_profile_smoke.py, plus custodian/tools/validation/pixelart_colors_smoke.py and custodian/tools/validation/asset_pipeline_plan_smoke.py; add/run focused new geometry smoke and register it; then changed-file validation.
- Task overrides: `none`
- Deferred: Landmarks and registration policy (slice 2), QA (slice 3), MCP (slice 4), production handoff (slice 5).

## Focused handoff
- Stage: 1/5; all implementation and review work follows live `AGENTS.md`, isolated worktrees, dispatch claims and reviewed main.
- Review workstream: `review-codex-art-import-shared-transform` in a fresh context after implementation lands.
- Next workstream after passing review: `codex-art-import-registration`.
- Refresh owner: `none`; ChatGPT/user planning refresh required: `no` for objective tooling; human art approval remains separate.
- Current chat URL: `not-recorded`; add the exact user-supplied URL before the next material packet refresh.
- Completion report: changed files, final data/API contract, tests+results, architecture debt/drift, deferred risks only.
