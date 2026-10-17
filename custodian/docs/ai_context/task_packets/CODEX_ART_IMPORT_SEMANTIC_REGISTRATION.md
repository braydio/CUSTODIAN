# CODEX ART IMPORT SEMANTIC REGISTRATION
- Packet schema: `custodian.task_packet.v2`
- Workstream: `codex-art-import-registration`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-codex-art-import-shared-transform`
- Locks: `sprite-import-core, operator-source-normalization`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-codex-art-import-registration`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `reusable production-art geometry, safety, and authoring semantics require independent falsification`
- Reviewed main: `d099e541941c5f7525f7c9af38f6e36536f9d574`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Normalize visual scale, centering, foot/root baselines and shared registration without erasing intended frame motion or anchoring equipment to the body incorrectly.
- Completion boundary: Stationary actor baseline/root is invariant; intentional 6px jump survives output; no independently computed frame centers/scales; conflicts fail or warn with explicit authorization; accepted Operator anchor unchanged; out-of-range shifts rejected with no partial output; all tests deterministic.
- Current measured state: Operator has accepted 96x96 legacy registration and an accepted 128x128 2.5D root/ground profile, plus landmark reports; generic Asset V2 families have physical canvas but no shared import registration policy. The 128 profile is accepted, yet operator/tools README still calls it provisional.
- Evidence: main@d099e541941c; custodian/tools/art/custodian_pixelart_converter.py; custodian/tools/operator/art_agent/{source_normalization,source_service,registration_profile,mcp_server}.py; custodian/tools/assets/{asset_contract,asset_plan,asset_transaction}.py; custodian/tools/assets/asset_workbench/; current Asset V2 and Operator validation smokes.
- Task-specific authority: design/04_architecture/CODEX_ART_IMPORT_PIPELINE_V1.md; design/04_architecture/ASSET_PIPELINE_V2.md; design/04_architecture/ASSET_WORKBENCH_ROADMAP.md; design/02_features/animation/OPERATOR_ART_AGENT_SYSTEM.md; live AGENTS.
- Work surface: custodian/tools/assets/sprite_import/ registration-plan data/service; custodian/tools/operator/art_agent/registration_profile.py adapter; Asset V2 family/state contract read adapters; focused geometry/registration fixtures and validation.
- Change:
  1. Extend slice-1 plans with an explicit versioned registration-policy block, not magic coordinates. Modes: `keep_canvas` (tiles, already registered strips), `fixed_anchor` (world props, FX), `actor_root` (accepted profile or caller-reviewed root/ground anchors), `shared_alpha_center` only for explicitly non-animated unanchored icons. Asset V2 supplies target WxH/frame count and optional approved placement metadata; do not invent a new field in canonical family schema without contract evolution/review.
  2. Resolve anchors in priority: accepted profile/reference or declared asset placement -> approved source landmark(s) -> an explicitly chosen transparent-bounds heuristic reported as untrusted preview. For actors, ground/foot/world root are distinct evidence; do not conflate alpha bottom with ground. FX preserve authored impact/emission origin; tiles stay pixel-grid exact and cannot be auto-centered.
  3. Compute a single sheet-wide scale, baseline and X registration using cross-frame robust observations (weighted median where authorized), with profile/source hash provenance. Per-frame corrections are explicit integer dx/dy only, bounded by declared profile/policy, clipping-refused, and anchored to plan digest. Never auto-center individual frames or mechanically remove authored airborne/recoil/anticipation displacement. Expose per-frame anchor delta and residual warning; do not silently 'fix' a moving limb or overwrite approved artwork.
  4. For Operator 128x128 preserve accepted (64,106) world root and y=107 ground/shadow provenance; do NOT assign the legacy 96x96 guide to 128px assets. The 128 profile lacks accepted body scale segments: no invented landmark-derived rescale or false equivalence with 96px. Existing approved profile gating/verified crisp replay remains mandatory.
  5. Add fixture cases: an eight-frame actor with a deliberate 6px jump, a static base-anchored 128x160 prop, a six-frame FX whose burst expands asymmetrically, tile grid, conflicting near/far landmarks, missing confidence, and dx/dy causing one frame overflow. Log measured residuals and digest, not subjective quality scores.
- Preserve: Canonical source masters, existing Asset V2 and specialized Operator contract owners, authored frame timing and pose motion, existing accepted profile geometry, no new art-generation authority.
- Non-goals: No production artwork alterations, no new character design, no gameplay/timing/balance changes, no auto-publishing via MCP, no new runtime output naming database, and no repeated per-frame normalization.
- Acceptance: Stationary actor baseline/root is invariant; intentional 6px jump survives output; no independently computed frame centers/scales; conflicts fail or warn with explicit authorization; accepted Operator anchor unchanged; out-of-range shifts rejected with no partial output; all tests deterministic.
- Validation: Run custodian/tools/validation/operator_art_registration_profile_smoke.py, custodian/tools/validation/operator_art_source_smoke.py and custodian/tools/validation/asset_pipeline_plan_smoke.py; add/run focused registration smoke, update validation_manifest.json; then changed-file validation.
- Task overrides: `none`
- Deferred: Objective output QA (slice 3), MCP orchestration (slice 4), reviewed staging (slice 5).

## Focused handoff
- Stage: 2/5; all implementation and review work follows live `AGENTS.md`, isolated worktrees, dispatch claims and reviewed main.
- Review workstream: `review-codex-art-import-registration` in a fresh context after implementation lands.
- Next workstream after passing review: `codex-art-import-quality-gates`.
- Refresh owner: `none`; ChatGPT/user planning refresh required: `no` for objective tooling; human art approval remains separate.
- Current chat URL: `not-recorded`; add the exact user-supplied URL before the next material packet refresh.
- Completion report: changed files, final data/API contract, tests+results, architecture debt/drift, deferred risks only.
