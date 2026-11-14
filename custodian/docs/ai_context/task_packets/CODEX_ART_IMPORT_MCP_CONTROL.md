# CODEX ART IMPORT MCP CONTROL
- Packet schema: `custodian.task_packet.v2`
- Workstream: `codex-art-import-mcp`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `review-codex-art-import-quality-gates`
- Locks: `sprite-import-mcp, sprite-import-core`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-codex-art-import-mcp`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `reusable production-art geometry, safety, and authoring semantics require independent falsification`
- Reviewed main: `d099e541941c5f7525f7c9af38f6e36536f9d574`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Give Codex a discoverable, low-token, safe MCP interface to inspect, normalize, register, preview and QA source sheets using the single shared import service.
- Completion boundary: Codex can discover exact tool schemas and run a deterministic inspection→plan→preview→QA flow without editing production; unauthorized paths and stale revisions fail closed; each tool delegates to typed service; Operator legacy server behaves unchanged; documented start/config command works in test.
- Current measured state: The existing operator-art stdio MCP wraps ArtAgentService/SourceArtService and has specialized source_* tools, but not a generic non-Operator Asset V2 import endpoint; Artist/Workbench mutators stay in ignored .ai sessions. Generic Asset Workbench is a distinct backend by design.
- Evidence: main@d099e541941c; custodian/tools/art/custodian_pixelart_converter.py; custodian/tools/operator/art_agent/{source_normalization,source_service,registration_profile,mcp_server}.py; custodian/tools/assets/{asset_contract,asset_plan,asset_transaction}.py; custodian/tools/assets/asset_workbench/; current Asset V2 and Operator validation smokes.
- Task-specific authority: design/04_architecture/CODEX_ART_IMPORT_PIPELINE_V1.md; design/04_architecture/ASSET_PIPELINE_V2.md; design/04_architecture/ASSET_WORKBENCH_ROADMAP.md; design/02_features/animation/OPERATOR_ART_AGENT_SYSTEM.md; live AGENTS.
- Work surface: new thin custodian/tools/assets/sprite_import/mcp_server.py wrapping same typed source-import service; adjacent CLI or launcher and MCP README/config instructions; existing custodian/tools/operator/art_agent/mcp_server.py only if compatibility tests need a small adapter; focused MCP validation.
- Change:
  1. Implement a dedicated thin stdio JSON-RPC MCP adapter named `custodian-art-import` above shared import plan/QA services, not a second backend and not a generic extension of Operator pixel-painting authority. Provide tools `custodian_art_import_open`, `inspect`, `plan`, `set_registration`, `preview`, `qa`, `status`, `close`; return compact structured JSON and artifact paths, versioned schemas, actionable error codes and low-context summaries. Register each MCP tool with strict argument schemas; reject extra keys, invalid method/type and malformed messages. Tools must be discoverable by Codex via exact local setup instructions and a read-only doctor/capabilities output.
  2. Sessions are disposable under .ai, keyed by strong opaque session IDs, source and contract SHA256 fingerprints, revision/generation counters and an operation journal. Read source only inside approved asset-drop source_work/inbox or an explicitly verified local handoff root. Refuse symlink escape, traversal, absolute arbitrary paths, stale contracts, duplicate unsafe idempotency keys, simultaneous writes, unsupported source formats and out-of-range pixel/offset arguments.
  3. Expose approval boundary: preview/QA cannot mutate approved source or canonical runtime; `set_registration` invalidates previous QA/proof; `plan` produces digest; rendering only creates ignored derived evidence. Do not expose shell/git/publish/runtime rebuild or arbitrary filesystem writes from MCP. Add bounded previews and pagination/summary for long sheets to keep Codex token usage modest.
  4. Operator semantic requests must be explicitly routed to the existing `operator-art` Source Session and `pixelart --choose 1` production rule, not silently handled by generic family policy. Document one client decision table (Operator vs Asset V2) and sample Codex requests. No MCP mutation changes source masters or generates a new Asset V2 family by itself.
  5. Add protocol tests for tool-list/schema, normal 6f/8f flow, unknown method, malformed JSON, duplicate operation, concurrent sessions, stale source/plan, path/symlink escape, digest replay, cancel/close and no runtime/source writes.
- Preserve: Canonical source masters, existing Asset V2 and specialized Operator contract owners, authored frame timing and pose motion, existing accepted profile geometry, no new art-generation authority.
- Non-goals: No production artwork alterations, no new character design, no gameplay/timing/balance changes, no auto-publishing via MCP, no new runtime output naming database, and no repeated per-frame normalization.
- Acceptance: Codex can discover exact tool schemas and run a deterministic inspection→plan→preview→QA flow without editing production; unauthorized paths and stale revisions fail closed; each tool delegates to typed service; Operator legacy server behaves unchanged; documented start/config command works in test.
- Validation: Run custodian/tools/validation/operator_art_agent_mcp_smoke.py, custodian/tools/validation/asset_pipeline_cli_ux_smoke.py and custodian/tools/validation/asset_workbench_review_smoke.py; add/run focused generic MCP smoke, register ownership; then changed-file validation.
- Task overrides: `none`
- Deferred: Generic reviewed inbox handoff and Asset V2 lifecycle integration (slice 5); no remote services, no automatic publication.

## Focused handoff
- Stage: 4/5; all implementation and review work follows live `AGENTS.md`, isolated worktrees, dispatch claims and reviewed main.
- Review workstream: `review-codex-art-import-mcp` in a fresh context after implementation lands.
- Next workstream after passing review: `codex-art-import-asset-v2-handoff`.
- Refresh owner: `none`; ChatGPT/user planning refresh required: `no` for objective tooling; human art approval remains separate.
- Current chat URL: `not-recorded`; add the exact user-supplied URL before the next material packet refresh.
- Completion report: changed files, final data/API contract, tests+results, architecture debt/drift, deferred risks only.
