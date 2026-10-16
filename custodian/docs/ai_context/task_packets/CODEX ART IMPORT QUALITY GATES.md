# CODEX ART IMPORT QUALITY GATES
- Packet schema: `custodian.task_packet.v2`
- Workstream: `codex-art-import-quality-gates`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-codex-art-import-registration`
- Locks: `sprite-import-core, sprite-import-qa`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-codex-art-import-quality-gates`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `reusable production-art geometry, safety, and authoring semantics require independent falsification`
- Reviewed main: `d099e541941c5f7525f7c9af38f6e36536f9d574`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Make production-readiness observable and fail-closed with structural/pixel evidence, preview artifacts and stable quality reports before any handoff.
- Completion boundary: Every blocking corruption fixture is rejected with stable reason; allowed jump is not auto-corrected; byte-repeat reports stable; no extra pixels/layers in output; 0 bypass paths from preview to handoff; focus tests and existing review regression green.
- Current measured state: Converter offers alpha checks, bbox reports and comparison candidates; Art Agent has QA/render/review; Asset Workbench has read-only contact/playback. There is no unified generic import QA receipt tied to source, approved plan and output digests.
- Evidence: main@d099e541941c; custodian/tools/art/custodian_pixelart_converter.py; custodian/tools/operator/art_agent/{source_normalization,source_service,registration_profile,mcp_server}.py; custodian/tools/assets/{asset_contract,asset_plan,asset_transaction}.py; custodian/tools/assets/asset_workbench/; current Asset V2 and Operator validation smokes.
- Task-specific authority: design/04_architecture/CODEX_ART_IMPORT_PIPELINE_V1.md; design/04_architecture/ASSET_PIPELINE_V2.md; design/04_architecture/ASSET_WORKBENCH_ROADMAP.md; design/02_features/animation/OPERATOR_ART_AGENT_SYSTEM.md; live AGENTS.
- Work surface: custodian/tools/assets/sprite_import/ qa and report owners; reuse converter, Art Agent and Asset Workbench read-only review helpers where possible; focused synthetic source/expected-output fixtures.
- Change:
  1. Implement a stable versioned per-frame/strip QA report with statuses PASS/WARN/FAIL, machine-readable issue IDs, source+profile+plan+output SHA256s, exact geometry, frame bounds, alpha coverage and registered-anchor residuals. Zero success-by-default when an input is unavailable.
  2. Blocking gates: wrong frame count/order/WxH/grid, opaque background when family requires alpha, nonzero matte contamination/border-connected backdrop, inter-cell bleed, clipping of visible pixels, insufficient transparent safety margin when required by profile, invalid output alpha, or stale/edited plan/output hash. Alpha-empty frames fail for required visible states unless explicitly declared by a sanctioned animation schema. Opaque tiles are checked by their declared tile policy, not the transparency rule for actors/props.
  3. Advisory metrics: outline/palette drift, abrupt occupied-area jumps, empty margins, frame-over-frame translation, near-duplicate adjacent frames and inconsistent body/pivot measurements. Advisory visual style cannot become automatic publication approval or an invented art standard.
  4. Produce a compact pixel-nearest-neighbor contact sheet, alpha/silhouette view, anchor overlay, optional animated GIF and structured difference report in disposable .ai/reports directory. No guides or checkerboard enter deliverable PNG. Human visual approval needed only for subjective art decisions; ship minimal question-oriented evidence via existing review handoff when warranted.
  5. Golden negative fixtures: fully opaque fake alpha, checkerboard-as-pixels, premultiplied/color matte, a 1px cell-edge bleed, a clipped weapon tip, a deliberately airborne frame, a one-pixel pivot drift, duplicate frames, altered output after approval and an all-alpha required state. Assert correct fail/warn distinctions and no source/inbox mutation.
- Preserve: Canonical source masters, existing Asset V2 and specialized Operator contract owners, authored frame timing and pose motion, existing accepted profile geometry, no new art-generation authority.
- Non-goals: No production artwork alterations, no new character design, no gameplay/timing/balance changes, no auto-publishing via MCP, no new runtime output naming database, and no repeated per-frame normalization.
- Acceptance: Every blocking corruption fixture is rejected with stable reason; allowed jump is not auto-corrected; byte-repeat reports stable; no extra pixels/layers in output; 0 bypass paths from preview to handoff; focus tests and existing review regression green.
- Validation: Run custodian/tools/validation/pixelart_colors_smoke.py, custodian/tools/validation/asset_workbench_review_smoke.py and custodian/tools/validation/operator_art_source_smoke.py; add/run focused import QA smoke, register ownership; then changed-file validation.
- Task overrides: `none`
- Deferred: Agent-facing MCP actions (slice 4) and reviewed Asset V2 handoff (slice 5).

## Focused handoff
- Stage: 3/5; all implementation and review work follows live `AGENTS.md`, isolated worktrees, dispatch claims and reviewed main.
- Review workstream: `review-codex-art-import-quality-gates` in a fresh context after implementation lands.
- Next workstream after passing review: `codex-art-import-mcp`.
- Refresh owner: `none`; ChatGPT/user planning refresh required: `no` for objective tooling; human art approval remains separate.
- Current chat URL: `not-recorded`; add the exact user-supplied URL before the next material packet refresh.
- Completion report: changed files, final data/API contract, tests+results, architecture debt/drift, deferred risks only.
