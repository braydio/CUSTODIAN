# AGENT MISSION CONTROL DATA MODEL V1 (MC1)

- Packet schema: custodian.task_packet.v2
- Workstream: agent-mission-control-data-model-v1
- Status: draft
- Dispatch: manual
- Priority: P1
- Depends on: none
- Locks: agent-workflow
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, workflow
- Paired review workstream: review-agent-mission-control-data-model-v1
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: Snapshot correctness controls the interpretation of dispatch eligibility, independent acceptance and running-agent evidence; requires fresh-context falsification
- Reviewed main: a6043df652a0bdc71dfe3e6fabe3d31d10eac20c
- Authoring chat: not-recorded
- Visual review: none
- Goal: Establish one authoritative, versioned, read-only CUSTODIAN Mission Control workstream/queue snapshot foundation that later TUI, telemetry, events and action components can consume without duplicating the dispatcher.
- Completion boundary: Ship a bounded `python3 custodian/tools/agent/mission_control.py snapshot --json` read-only CLI (or an equivalent coherent module/entrypoint) with schema, canonically parsed packet/workstream family relationships, real dispatcher decision/claimability, independent review/acceptance truth, source health and fail-closed unknown ownership. No UI, token ingestion, event database or mutation actions.
- Current measured state: TUI-first architecture is planned in `custodian/docs/ai_context/AGENT_MISSION_CONTROL_TUI_V1.md`. `dispatch.py` already owns exact packet eligibility/audit and `task_packet_contract.py` owns canonical metadata; README ready/auto block is informational only. `workstream.py`, `workflow_control.py` and `paired_review_runner.py` provide authoritative lifecycle evidence. OR1/OR2 supervisor/lease are separately planned and may remain unavailable. The uploaded usage tracker parses its own packet headers and must not be reused as a competing packet authority.
- Evidence: `custodian/tools/agent/{dispatch.py,task_packet_contract.py,task_packet_index.py,workflow_control.py,workstream.py,paired_review_runner.py,run_trace.py}`; `custodian/docs/ai_context/{AGENT_MISSION_CONTROL_TUI_V1.md,AGENT_WORKSTREAM_LIFECYCLE.md,AGENT_ORPHAN_RECOVERY_SUPERVISOR_V1.md}`; existing agent workflow tests.
- Task-specific authority: Reuse canonical dispatcher decision and packet parser, exact Git refs/receipts and independent review acceptance; do not derive claimability from packet's `Status: ready` or active README. Consumer snapshot cannot release leases/claims or mark pass.
- Work surface: New bounded tool package in `custodian/tools/agent/mission_control/` and thin proposed `custodian/tools/agent/mission_control.py` entrypoint only if no existing equivalent, fixture tests under agent tooling, relevant validation manifest ownership and a concise usage note.
- Change:
  1. Inspect current `origin/main`, AGENTS and existing snapshot/audit JSON entrypoints; reuse and normalize existing authoritative fields instead of reparsing markdown or inventing status.
  2. Define documented `custodian.mission_control.snapshot.v1` JSON: generation timestamp, fetched origin/main SHA and age, collector health/partial errors, canonical packet/family/phase relationships, dispatcher eligibility and reasons, local/remote claim/branch evidence, reviewer target and receipt evidence, dependency edges, per-state mutually exclusive active-queue counts with explicit denominators.
  3. Explicitly distinguish `draft`, `ready-but-blocked`, `eligible`, `claimed`, `landed-review-pending`, `review-findings`, `accepted`, `archived` and `unknown` as necessary without claiming every phase represents packet `Status`; keep implementation/review/correction records distinct with a separate root aggregation. For ambiguous/missing/foreign session evidence report `UNKNOWN`, never verified LIVE from a branch or rollout timestamp.
  4. Record provenance (packet path/blob/ref SHA, dispatcher decision origin, remote snapshot age) for each claimable or accepted statement. Preserve review results and latest correction-cycle gates; no fake acceptance from archived header alone.
  5. Provide bounded deterministic filtered output plus graceful handling of missing checkout, origin unavailable, malformed/duplicate packet, conflicting refs and missing supervised session authority. Do not accidentally mutate checkout, fetch remote without opt-in, read raw Codex prompts or launch agents.
  6. Add fixture-based tests with temporary Git repositories for eligible vs ready-blocked, dependency cycles, claim conflict, landed-but-review-pending, review findings, accepted correction chain, stale snapshot, missing origin/OR1 and clean read-only invocation. Establish the schema that MC2/MC3 can consume.
- Preserve: Existing dispatch eligibility and remote claim ownership, packet schema, branch/finish/review rules, protected user worktrees, OR1/OR2 safety boundaries, root AGENTS and local validation defaults.
- Non-goals: TUI/browser UI, token parser refactor, event database, notification center, executing/claiming packets, automatic parking, new dispatcher, gameplay/UI runtime, artwork or Asset V2 changes.
- Acceptance: A) every eligible packet exactly matches dispatcher decision at the same observed origin SHA; B) README/status alone cannot produce claimable; C) implementation landing never equals review acceptance; D) findings, unreviewed, incomplete correction and ambiguous provenance remain nonaccepted; E) session liveness remains UNKNOWN without verified supervisor evidence; F) all queue totals reconcile to explicit disjoint populations; G) JSON fields are documented, stable and safe for untrusted consumers; H) snapshot mode produces no Git/worktree/packet/process mutations even on failure; I) fixture validation and existing dispatcher/review regressions pass.
- Validation: Targeted `python3 -m unittest` new mission-control snapshot tests plus existing `test_dispatch`, `test_workstream` and review/pairing focused tests; `python3 custodian/tools/agent/check_ai_context.py --json`; `python3 custodian/tools/agent/validate_review_pairing.py`; `python3 custodian/tools/agent/task_packet_index.py`; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; `git diff --check`.
- Task overrides: none
- Deferred: MC2 token telemetry, MC3 event history, MC4 Textual interface, MC5 OR1/OR2 integration, MC6 hardening, MC7 attention and MC8 guarded actions.

## Handoff

- Next workstream: review-agent-mission-control-data-model-v1
- Next packet state: ready/auto, dependent on MC1 implementation archive
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Next action: After exact implementation landing and archival, start the paired fresh-context review; then MC2 and MC3 can use the verified snapshot contract.
- Blockers or open questions: Promote draft/manual to ready/auto only after targeted authoring preflight against this implementation and its review, updated live-main inspection and managed-index check.
