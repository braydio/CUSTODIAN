# DROPBOX ASSET LIFECYCLE RECONCILER V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `dropbox-asset-lifecycle-reconciler-v1`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `asset-pipeline, dropbox-handoff`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline`
- Paired review workstream: `review-dropbox-asset-lifecycle-reconciler-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new cross-system source/review/runtime reconciliation and safety-critical no-auto-ingest boundary`
- Reviewed main: `76c86f4fd52eac4546139925d4c70a50725ed2a0`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: `none`
- Goal: Independently harden, validate on real Dropbox and close out the already-landed audit/source-stage/report-publish toolchain against its approved lifecycle authority, without duplicate implementations or silent ingestion.
- Completion boundary: Fresh-main code inspection, targeted suite + real read-only rclone audit, controlled report publish with immutable receipt where credentials/authorization exist, bounded corrections and post-land reviewer receipt. Do not count existing code as validated without tests. Source package intake stays separately approval-gated.
- Current measured state: Audit scanner, explicit SHA-pinned source-work staging and pixel-art normalization gate, and opt-in immutable audit-run/current index publisher have landed on main. GitHub focused offline tests are wired to Validate Repository; follow latest CI run. Historical Dropbox upload index remains stale (last updated 2026-10-07). Git source-review registry is initially empty by design. No live rclone remote publication nor Asset V2 ingest is confirmed.
- Evidence: `design/04_architecture/DROPBOX_ASSET_LIFECYCLE_RECONCILIATION_V1.md`; `custodian/docs/ai_context/asset_audits/DROPBOX_ASSET_FAMILY_BASELINE_20261013.json`; `custodian/docs/ai_context/DROPBOX_ASSET_BATCH_REGISTRY.md`; `custodian/tools/iteration/dropbox_transport.py`; `custodian/tools/assets/asset.py`; `custodian/content/metadata/assets/required_assets.registry.json`.
- Task-specific authority: Existing Dropbox registry determines immutable batch identity/discovery; Git design/spec/manual review receipt determines approvals; Asset V2 catalog/status/requirements determine actual ingest/consumer state; current dispatcher governs claimability.
- Work surface: `custodian/tools/assets/dropbox_asset_audit.py` and one focused helper/schema if needed; `custodian/tools/assets/test_dropbox_asset_audit.py`; optional small source-review receipt schema; `custodian/AGENTS.md` short routing instruction; `custodian/docs/ai_context/DROPBOX_ASSET_BATCH_REGISTRY.md` and validation recipe.
- Change:
  1. Before edits, check fresh main and existing `DROPBOX_ASSET_BATCH_REGISTRY.md`, rclone remote resolution, Asset V2 status/catalog and already-implemented inbound handoff; reuse their code, no second Dropbox credential or runtime ledger.
  2. Add `scan --json` across `asset_batches`, `implementation_inputs`, `generated_asset_batches` with complete pagination, offline fixture support and deterministic output. Treat `visual_review` as evidence only.
  3. Parse the old registry/index and optional per-batch receipts, classify unindexed ZIPs, orphaned refs, superseded/duplicate source, unknown family IDs, bad manifests and conflicting hashes. Preserve unverified statuses as `unknown` or `needs_review`.
  4. Read existing family contracts, generated Asset V2 catalog and `required_assets.registry.json`; report source-review status and *independently computed* source_pending/art_present/imported/bound/runtime_verified per concrete state, including evidence paths.
  5. Define source review receipts for explicit approved/rejected/superseded decisions tied to exact immutable ZIP SHA-256/family/state/reviewer/backlink; no implicit approval by Dropbox presence or conversation inference.
  6. Add `report --format markdown` and stable machine-readable finding IDs; status-by-family table, batches missing receipts, approved-but-uningested states, requirements drift and next-action queue.
  7. Add tests for a known 8-ZIP `asset_batches` fixture, all newer Ash-Bell packages, unknown binary manifest, duplicate sources, existing but not new states, offline/missing Dropbox, and privilege boundary; prepare one real remote read-only smoke if rclone is configured.
  8. Add a concise AGENTS link to this verified CLI and design after it exists; check and repair only directly affected documentation drift. Do not modify unrelated lifecycle/queue packets.
- Preserve: `asset.py` as ingest authority, `asset_status.py` catalog proof, existing required_assets registry, file integrity logic, special Operator pipeline, bidirectional Dropbox handoff and all immutable Dropbox packages.
- Non-goals: NO remote upload/rename/delete; no ZIP download in normal scan; no generation; no normalization/staging or inbox/runtime writes; no automatic ingest, auto-claim, timing daemon, background watch, batch approvals, global AGENTS restructuring or broad queue rewrite.
- Acceptance: Known unindexed packages detected; the four existing approved Alpine batch records preserved; six+six ritual static states do not double-count closeout source; lift V2 remains source-only; correct last-known and current statuses are distinct; scan/report deterministic and read-only; source/ingest/runtime never collapsed; tests green.
- Validation: `python3 -m unittest custodian.tools.assets.test_dropbox_asset_audit` (or correct runnable module path), `python3 custodian/tools/assets/asset.py needs --check`, `python3 custodian/tools/assets/asset.py doctor`, scoped AI docs validation where applicable; real `rclone lsf` read-only if available. Confirm clean checkout after read-only scan with `git status --porcelain` excluding intentionally ignored cache only.
- Task overrides: `none`
- Deferred: Auto-claim-on-upload, background watching, automatic review approval, automatic Asset V2 ingest, broad migration of older Dropbox packages. Source downloads/staging/publish commands now exist, but first real remote application is pending.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Refresh instruction: Inspect fresh main to avoid duplicate implementation and validate this pair against the current task-packet authoring preflight before promotion from draft/manual.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Next action: Codex performs focused fresh-branch review and corrects failures, runs real Dropbox read-only audit, and publishes first derived lifecycle index explicitly after verifying remote configuration and current approval records.
- Blockers or open questions: Requires target repo targeted preflight and real local rclone connectivity checks, no user lore questions.
