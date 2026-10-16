# CODEX ART IMPORT ASSET V2 HANDOFF
- Packet schema: `custodian.task_packet.v2`
- Workstream: `codex-art-import-asset-v2-handoff`
- Kind: `implementation`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-codex-art-import-mcp`
- Locks: `asset-pipeline, sprite-import-core, sprite-import-mcp`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-codex-art-import-asset-v2-handoff`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `reusable production-art geometry, safety, and authoring semantics require independent falsification`
- Reviewed main: `d099e541941c5f7525f7c9af38f6e36536f9d574`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Finish the reusable source_work→normalized inbox→Asset V2 plan/status/doctor interface with verified artifacts and provenance while preserving the Operator-specific publication route.
- Completion boundary: Single command/safe MCP sequence can stage synthetic fixture family as correctly routed inbox with provenance; 0 silent replacements; fails closed on wrong frame count/missing approval/altered digest; deterministic output+QA; existing Asset V2 status truth unchanged until actual ingest; Operator specialized handoff and tests pass; README/roadmap/current state report reality.
- Current measured state: Asset Pipeline V2 already owns schema-driven routing, canonical names, transactions and catalog; the handoff ZIP installer is path-confined; generic Asset Workbench roadmap Slice 6 still plans source creation/intake. SourceArtService already stages specialized Operator inbox sheets separately.
- Evidence: main@d099e541941c; custodian/tools/art/custodian_pixelart_converter.py; custodian/tools/operator/art_agent/{source_normalization,source_service,registration_profile,mcp_server}.py; custodian/tools/assets/{asset_contract,asset_plan,asset_transaction}.py; custodian/tools/assets/asset_workbench/; current Asset V2 and Operator validation smokes.
- Task-specific authority: design/04_architecture/CODEX_ART_IMPORT_PIPELINE_V1.md; design/04_architecture/ASSET_PIPELINE_V2.md; design/04_architecture/ASSET_WORKBENCH_ROADMAP.md; design/02_features/animation/OPERATOR_ART_AGENT_SYSTEM.md; live AGENTS.
- Work surface: custodian/tools/assets/sprite_import/ handoff orchestration; custodian/tools/assets/{asset_contract,asset_plan,asset_transaction,asset_handoff_installer}.py read adapters; generic Asset Workbench source-intake seam; MCP thin handoff extension and CLI entrypoint; design/04_architecture/ASSET_WORKBENCH_ROADMAP.md scoped state reconciliation; current tool README/CURRENT_STATE/FILE_INDEX drift checks.
- Change:
  1. Add read-only `handoff-plan` and explicit transactional `handoff --dry-run/--apply` service/CLI (and thin MCP access only where safely authorized). It must accept a source+contract+approved-plan+QA receipt digest and derive exact family/state/direction semantic inbox filename from live Asset V2 contract/request authority. Do not handcraft runtime filenames. Require PASS objective QA, matching source/plan/output hashes, exact frame-count and WxH, explicit same-identity replace decision, and transactional rollback on failure.
  2. For generic Asset V2 families, preserve immutable masters at `custodian/asset_drop/source_work/<AREA>/<FAMILY_ID>/<STATE_ID>_source.png` (direction-qualified where needed). Stage the normalized alpha-clean strip at `custodian/asset_drop/inbox/<FAMILY_ID>/<STATE_ID>[__DIRECTION].png` only when that exact filename is obtained from the family contract/Asset V2 request. Record SHA256 and size in machine-readable intake receipt; never put guides/review PNGs in inbox. Leave Asset V2 `plan`, `ingest`, `status`, `doctor` and runtime catalog as sole downstream authorities; do not auto-ingest on an MCP preview or claim runtime-verified when only staged.
  3. For Operator, delegate to existing `operator art source-handoff` and specialized pipeline; obey approved profile and mandatory crisp `pixelart --choose 1` verification; do not treat Operator as Asset V2 generic family. Preserve exact semantic identity/replacement preview and existing Workbench publish gate.
  4. Provide a self-contained Codex recipe including inspect → explicit family contract → authoring source_work → shared plan → register → normalize/preview → QA → reviewed promotion → Asset V2 plan/ingest/status/doctor or Operator specialized ingest. Reuse Asset Workbench Slice 6 as UI consumer, not a parallel UI/publisher. Reconcile roadmap status/ownership without claiming Slice 6 complete merely for underlying primitives; fix the stale '128 profile provisional' assertion in custodian/tools/operator/README.md against accepted live profile while preserving future-looking universal-envelope caveat.
  5. End-to-end synthetic golden flows: eight frames of 512x512 to 1024x128 8f actor strip; 3x2 input of 256x256 to 768x128 6f effect strip; rectangular 128x160 prop; tile policy as needed; 12f 156x156 example must yield 1872x156. Verify no silent stretch, output diff on second unchanged run zero, explicit replacement, interrupted write rollback, no runtime mutation until existing ingest invoked. No real production art changes are authorized.
- Preserve: Canonical source masters, existing Asset V2 and specialized Operator contract owners, authored frame timing and pose motion, existing accepted profile geometry, no new art-generation authority.
- Non-goals: No production artwork alterations, no new character design, no gameplay/timing/balance changes, no auto-publishing via MCP, no new runtime output naming database, and no repeated per-frame normalization.
- Acceptance: Single command/safe MCP sequence can stage synthetic fixture family as correctly routed inbox with provenance; 0 silent replacements; fails closed on wrong frame count/missing approval/altered digest; deterministic output+QA; existing Asset V2 status truth unchanged until actual ingest; Operator specialized handoff and tests pass; README/roadmap/current state report reality.
- Validation: Run custodian/tools/validation/asset_pipeline_v21_production_smoke.py, custodian/tools/validation/asset_pipeline_transaction_smoke.py, custodian/tools/validation/asset_pipeline_plan_smoke.py, custodian/tools/validation/operator_art_source_smoke.py and custodian/tools/validation/operator_art_agent_mcp_smoke.py; add/run an end-to-end import handoff smoke, register focused validation; then changed-file validation and asset doctor/needs check.
- Task overrides: `none`
- Deferred: Actual asset generation and human aesthetic signoff remain distinct; Asset Workbench Design Mode/creation UI stays on its own roadmap; no gameplay/art changes.

## Focused handoff
- Stage: 5/5; all implementation and review work follows live `AGENTS.md`, isolated worktrees, dispatch claims and reviewed main.
- Review workstream: `review-codex-art-import-asset-v2-handoff` in a fresh context after implementation lands.
- Next workstream after passing review: `none`.
- Refresh owner: `none`; ChatGPT/user planning refresh required: `no` for objective tooling; human art approval remains separate.
- Current chat URL: `not-recorded`; add the exact user-supplied URL before the next material packet refresh.
- Completion report: changed files, final data/API contract, tests+results, architecture debt/drift, deferred risks only.
