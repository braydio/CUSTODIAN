# WIRE Pilot Exporter Reconciliation V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-wire-pilot-exporter-reconciliation-v1`
- Category: `agent-ops`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `none`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-wire-pilot-exporter-reconciliation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `This work changes how a privacy-sensitive telemetry consumer interprets incomplete detail while relying on complete authority-bearing aggregates, freshness, identity, schema and digest checks. Focused tests do not replace independent verification of the consumer boundary.`
- Reviewed main: `eef8a41f8e82fe47c346002087f52492d945322a`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae98bea-2dfc-83e8-a5ff-863e52d79ac0`
- Visual review: `none`
- Goal: Let the private WIRE pilot accept a valid sanitized observation when raw dispatcher inventory is complete but safe per-packet detail is explicitly partial.
- Completion boundary: Preserve and land the validated exporter reconciliation patch, make the pilot validator accept only schema-valid partial detail backed by complete reconciled raw dispatch aggregates, add adversarial consumer tests and canonical validation registration, run the focused exporter and pilot gates plus the live local doctor, and finish the workstream through the canonical lifecycle. No Dropbox write occurs before successful landing and destination verification.
- Current measured state: At reviewed main `eef8a41f8e82fe47c346002087f52492d945322a`, the exporter work on the persistent coordination checkout has 25 focused tests passing and a green local WIRE doctor, but remains an uncommitted three-file diff on `main`. A fresh offline sanitized observation reports `coverage.active_inventory=partial` and `coverage.raw_dispatch_inventory=complete`; `wire_pilot.validate_observation()` rejects it with `dispatcher inventory is not complete`. No Dropbox operation was invoked.
- Evidence: `custodian/tools/agent/wire_observation_export.py`; `custodian/tools/agent/schemas/wire_observation.v1.schema.json`; `custodian/tools/agent/test_wire_observation_export.py`; `custodian/tools/iteration/wire_pilot.py`; `custodian/tools/validation/validation_manifest.json`; archived exporter authority `custodian/docs/ai_context/task_packets/archived/AGENT_WIRE_OBSERVATION_EXPORT_V1.md`; current offline consumer result in the authoring chat.
- Task-specific authority: `AGENTS.md`; `custodian/AGENTS.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; the archived exporter packet; the strict observation schema and live source implementations.
- Work surface: Existing exporter, schema and exporter tests; `custodian/tools/iteration/wire_pilot.py` and the focused new `custodian/tools/agent/test_wire_pilot.py`; the canonical `custodian/tools/validation/validation_manifest.json` registration; this task packet and its paired review. The implementation may add the `wire_pilot_unit` validation registration required for canonical changed-file coverage.
- Publication inputs: `AGENTS.md`; `custodian/AGENTS.md`; `custodian/project.godot`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/TASK_PACKET_CATEGORIES.json`; `custodian/docs/ai_context/TASK_PACKET_CATEGORY_AUTHORING.md`; `custodian/docs/ai_context/task_packets/README.md`; `custodian/docs/ai_context/worktree_profiles/agent_ops_paired_review_bootstrap_v1.json`; `custodian/tools/agent/task_packet_contract.py`; `custodian/tools/agent/validate_task_packet_authoring.py`; `custodian/tools/agent/check_packet_categories.py`; `custodian/tools/agent/wire_observation_export.py`; `custodian/tools/agent/schemas/wire_observation.v1.schema.json`; `custodian/tools/agent/test_wire_observation_export.py`; `custodian/tools/agent/task_administrator.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/workstream_recovery.py`; `custodian/tools/agent/transient_worktree_gc.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/worktree_provisioning.py`; `custodian/tools/iteration/wire_pilot.py`; `custodian/tools/iteration/dropbox_transport.py`; `custodian/tools/iteration/changed_file_router.py`; `custodian/tools/validation/validation_manifest.json`; `custodian/tools/validation/run_validation.py`; `custodian/tools/godot_project_lock.py`; `custodian/tools/pipelines/godot_import_preflight.py`; `tools/custodian_aliases.sh`; `custodian/docs/ai_context/worktree_profiles/wire_pilot_exporter_reconciliation_v1.json`
- Change: Transfer the preserved exporter patch only after verifying its three-file scope, exact parent blob identities and patch digest. Keep its truthful coverage model: complete raw dispatcher counts and classification totals; distinct raw, managed, identifiable, detailed and aggregate-only populations; no fabricated identities; and the paired-review `none` sentinel normalization with concrete identity equality preserved. Update the pilot consumer to accept `active_inventory` values `complete` or `partial` only when the strict exporter validator confirms the schema, complete `raw_dispatch_inventory`, and all aggregate/limitation reconciliation invariants. Add `custodian/tools/agent/test_wire_pilot.py` for valid partial and complete observations, missing/incomplete raw inventory, aggregate mismatch, invalid schema, unsafe source identity, incomplete source health, bad digest, stale/future evidence and no-publication behavior. Register that test for canonical changed-file validation.
- Preserve: Strict schema validation, complete raw-dispatch coverage, aggregate reconciliation, source revision and health checks, freshness bounds, deterministic digest verification, safe identity checks, exact concrete paired-review equality, read-only collection, private Dropbox boundary, current three-file root diff, its off-root backup, existing claims/reviews/locks, and timer-disabled state.
- Non-goals: Do not relabel partial detail as complete, weaken any source/schema/digest/freshness/identity guard, edit dispatcher or recovery ownership semantics, alter the public WIRE feed, enable a recurring timer, upload before verified landing, modify or release the historical exporter review, or retire protected worktrees/archive evidence.
- Acceptance:
  - The preserved exporter patch is transferred only after byte/digest/scope/baseline verification and all focused exporter tests pass in the canonical worktree.
  - A fresh valid observation with `coverage.active_inventory=partial` and `coverage.raw_dispatch_inventory=complete` passes the local pilot validator without changing the coverage labels.
  - A valid complete observation continues to pass; missing or unreconciled raw inventory, malformed aggregate counts/limitations, invalid schema, unsafe source identity, incomplete source health, invalid digest and stale/future evidence continue to fail closed.
  - Focused adversarial tests prove the partial-detail boundary and confirm validation itself performs no Dropbox or publication call.
  - The validation manifest selects the exporter and pilot tests for all changed implementation files, and canonical changed-file validation reports complete coverage.
  - The live local doctor is green; the implementation lands and archives only through `workstream.py finish`; the paired review remains dependency-gated until implementation completion.
  - Only after verified landing and destination identity confirmation, perform the separately authorized single private Dropbox publish/readback and verify immutable content plus the latest pointer. Do not enable the timer.
- Validation:
  - `python3 -m unittest custodian.tools.agent.test_wire_observation_export -v`
  - Focused pilot-consumer tests in `custodian/tools/agent/test_wire_pilot.py` for valid partial/complete coverage and adversarial integrity failures; register the module in `validation_manifest.json`.
  - Parse the observation schema as JSON and run its existing strict exporter validation cases.
  - `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` with complete changed-file coverage.
  - `git diff --check`
  - `python3 custodian/tools/iteration/wire_pilot.py doctor`
  - Independently call the local observation validator; do not invoke `once`, `publish`, `verify`, rclone, or Dropbox before landing.
- Task overrides: `none`
- Deferred: The single private Dropbox publication/readback is permitted only after verified landing and destination validation. The recurring timer, public feed and ongoing telemetry remain disabled/out of scope.

## Host-private patch transfer prerequisite

This is a host-local transfer artifact, not a repository-published `Publication inputs` dependency. Its owner is the CUSTODIAN host coordinator on archdesk. It is required only to carry the already validated exporter changes into the canonical worktree; preserve the original dirty root diff even after transfer.

- Artifact: `/mnt/windows-drive/custodian-wire-correction-oCbWeK/doctor-ready-root.patch`
- SHA-256: `bfb9390f04097230867e1791cfb0ea5be4d8aef26b93dcc19982962a72138b3a`
- Exact paths: `custodian/tools/agent/schemas/wire_observation.v1.schema.json`; `custodian/tools/agent/test_wire_observation_export.py`; `custodian/tools/agent/wire_observation_export.py`
- Patch base: `394e05469659c9a024c0353bf1a727b83d4a49a5`; the three base blobs are identical at the published `Reviewed main` SHA `eef8a41f8e82fe47c346002087f52492d945322a`.
- Expected base blob IDs: schema `e85652509e3d902fbe09412db9c2a3778526f0fd`; exporter test `37e8a90c35190b6e0dc9c1db61ae225eb80cf34f`; exporter `6802e641a560ae206b556dde61a814147f091eb3`.
- Expected resulting file SHA-256 values: schema `e3c8d7a47dfdbecaf55e3098413536958b1e9db11558ba90fe2e4874b7488959`; exporter test `627019c694c37e29c3f4a4ae0db08ca6155c29f871dd3290c7cfd3487dc119b4`; exporter `ef524fa65a34bad918a5e66d56c7e32cc6000fca2085c40e3071d671265296be`.
- Before applying, verify the patch digest and exact three-path scope, confirm the canonical worktree's three `HEAD:<path>` blob IDs match the expected values, and run `git apply --check`. Stop and preserve all files if the artifact is unavailable or any value differs; do not reconstruct or overwrite the persistent root diff.

## Handoff

- Next workstream: `review-agent-wire-pilot-exporter-reconciliation-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae98bea-2dfc-83e8-a5ff-863e52d79ac0`
- Refresh reason: `none`
- Next action: `After the implementation archives complete on origin/main, start the paired review through the canonical fresh-context runner.`
- Blockers or open questions: `The offline consumer check confirmed the partial-detail rejection; capacity and claim eligibility must be rechecked against the exact published lightweight profile before the named claim.`
