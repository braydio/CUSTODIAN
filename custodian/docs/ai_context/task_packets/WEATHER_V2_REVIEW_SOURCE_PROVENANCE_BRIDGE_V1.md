# WEATHER V2 REVIEW SOURCE-PROVENANCE BRIDGE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `weather-v2-review-source-provenance-bridge-v1`
- Category: `agent-ops`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `weather-v2-presentation-contract-v1`
- Locks: `paired-review-source-provenance`
- Kind: `implementation`
- Review: `none`
- Review stage: `post-land`
- Review modes: `none`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Paired review retired 2026-11-12 by owner decision; focused validation is the acceptance gate.`
- Reviewed main: `8e23d8b5418d7298dccc438c430652fe66d96333`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af2865a-62e0-83ea-b08d-d591648b381e
- Visual review: `none`
- Goal: Restore the preserved Weather V2 paired review's ability to authenticate its actual source span from Dispatcher V2 lifecycle receipts and landed Git history.
- Completion boundary: Add and independently validate a read-only provenance compatibility path for the one authenticated Weather V2 source and held review run. The original held review remains unresolved until its own later recovery and real reviewer outcome.
- Current measured state: The Weather V2 implementation is landed at PR #124 merge `495ea3a1ff55f9740692e5d762a385d7aec64440`, its packet archive transition is landed at `2adb9f165328ee9e6176a44b24ee6d513c10cdf6`, and current authoring baseline is `8e23d8b5418d7298dccc438c430652fe66d96333`. The preserved review run `20261110T034810Z-595eb18d9415` is in `host_validation_recovery`; the reviewer was never launched. The legacy source-span resolver fails because exact V2 workstream trace provenance is absent. The host contains the original acquisition, five checkpoint records (one blocked attempt and four published checkpoints), and retirement receipt; public digests and identities are pinned in the required evidence manifest.
- Evidence: `custodian/docs/ai_context/provenance/weather_v2_presentation_contract_v1.json`; archived source packet `custodian/docs/ai_context/task_packets/archived/WEATHER_V2_PRESENTATION_CONTRACT_V1.md`; held review packet `custodian/docs/ai_context/task_packets/REVIEW_WEATHER_V2_PRESENTATION_CONTRACT_V1.md`; the exact host-validation failure on run `20261110T034810Z-595eb18d9415`; and authenticated source, merge, checkpoint, archive, and receipt identities in the manifest. The V2 private receipt files remain host-private and are not copied into Git.
- Task-specific authority: `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/turn_dispatcher_v2.py`; `custodian/tools/agent/test_paired_review_runner.py`; the archived Weather V2 implementation packet and the current owner-exception correction in PR #126.
- Work surface: Integrate a small isolated verifier with the existing source-span resolver in `paired_review_host_validation.py`; keep the existing legacy diagnostic-trace resolver as the default. Add focused tests for the verifier and integration using controlled temporary Git/receipt fixtures. The exact host-only plan check uses the original held run and its genuine private receipts without applying recovery or launching the reviewer.
- Publication inputs: `custodian/docs/ai_context/provenance/weather_v2_presentation_contract_v1.json`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/turn_dispatcher_v2.py`; `custodian/tools/agent/test_paired_review_runner.py`; `custodian/docs/ai_context/task_packets/archived/WEATHER_V2_PRESENTATION_CONTRACT_V1.md`; `custodian/docs/ai_context/task_packets/REVIEW_WEATHER_V2_PRESENTATION_CONTRACT_V1.md`; `custodian/docs/ai_context/turn_handoffs/weather-v2-presentation-contract-v1.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`
- Change: Authenticate the exact manifest-pinned V2 acquisition, all five checkpoint records, retirement, source commit sequence, PR #124 merge (including its exact validation-manifest union with the first parent), final metadata-only checkpoint, and PR #125 archive transition. Resolve private receipt paths from the authenticated Git common directory, hash raw bytes before parsing, validate schemas and identity fields, and never copy or emit raw private receipt contents or absolute host paths. For only `weather-v2-presentation-contract-v1` and held review run `20261110T034810Z-595eb18d9415`, return the exact source-span evidence expected by host validation. Any missing, duplicate, changed, contradictory, mismatched, or unavailable evidence must fail closed. Do not synthesize `trace.jsonl` or any reviewer outcome.
- Preserve: Ordinary legacy trace-backed source-span validation; all existing owner-exception source-scope behavior and tests from PR #126; the actual V2 receipt bytes and protected review run; strict source-path and merge ancestry checks; review-claim ownership; and the distinction between bridge validation and independent review acceptance.
- Non-goals: No Weather runtime or shader changes; no generic V2 provenance redesign; no changes to unrelated owner-exception handling; no release, re-claim, mutation, or reviewer launch for the held Weather review; no synthetic trace, PASS, review receipt, or packet completion; no layered precipitation acquisition.
- Acceptance:
  1. The default legacy trace path behaves unchanged and existing paired-review host-validation tests pass.
  2. The exact Weather bridge verifies all seven pinned host-private records (acquisition, initial blocked checkpoint, four published checkpoints, retirement) using read-only access and hashes; it validates every listed identity and private checkout consistency without writing or disclosing receipt contents.
  3. It admits only the exact linear source commits, 15-path source span, PR #124 merge and validation-manifest union, V2 checkpoint metadata transition, and PR #125 packet/archive transition pinned by the manifest. The d251 checkpoint is not treated as a runtime implementation merge.
  4. The existing PR #126 owner-exception correction remains independently functional and cannot activate or broaden the Weather bridge.
  5. Missing/altered/duplicate receipts, invalid schemas or identities, wrong turn/workstream/branch/review/run, substituted commit/blob/path, changed ancestry, extra source-bearing commit, malformed archive transition, missing host-private data, and cross-workstream replay all fail closed. A Git-only environment cannot silently pass the host-private verification.
  6. A read-only host-validation recovery plan for the exact preserved run resolves the authenticated Weather source span after the bridge is landed. It does not apply recovery, launch the Weather reviewer, change the run, or claim review acceptance.
  7. The existing held claim, worktree, evidence, and original failure record remain intact throughout bridge implementation and its independent paired review.
- Validation: Run the focused new provenance-verifier tests added by this workstream; `python3 custodian/tools/agent/test_paired_review_runner.py`; `python3 custodian/tools/agent/validate_task_packet_authoring.py` for this packet pair; `python3 custodian/tools/agent/check_packet_categories.py` for both packets; `python3 custodian/tools/agent/validate_review_pairing.py`; `python3 custodian/tools/agent/check_ai_context.py --json`; `python3 custodian/tools/agent/task_packet_index.py`; `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`; the exact-run host recovery `--plan` only after the bridge lands; and `git diff --check`. Do not run recovery `--apply` from this workstream.
- Task overrides: `none`
- Deferred: General V2 review-provenance publication and interoperability improvements; actual recovery and completion of the held Weather review after this bridge's independent review accepts; Weather layered precipitation until the original Weather review is genuinely accepted.

## Implementation notes

This workstream repairs a **pre-review host-validation interoperability failure**. It does not address findings from an independent Weather review because that reviewer has not launched. It creates a strictly bounded provenance verification capability and remains subject to its own independent paired review.

The evidence manifest records only public commit/tree/blob identities and hashes/schema/expected identities of host-private receipts. The bridge implementation must treat those digests as necessary but not sufficient: verify receipt bytes, semantic fields, Git object relationships, path modes/blobs, and uniqueness. Never publish the private receipt JSON, private checkout paths, ignored-file inventory, or raw host-validation logs.

A legacy queue audit may report the shared `paired-review-source-provenance` lock held by `review-agent-operator-chassis-seal-source-scope-attestation-v1`; that classification is diagnostic and does not gate canonical V2 acquisition. Current V2 `dispatch.py claim` authenticates the packet from fetched `origin/main` and does not consult legacy `Locks`, `Depends on`, `Status`, or `Dispatch` fields. Do not describe a legacy `dependency_lock_blocked` result as proof of V2 ineligibility.

As of 2026-11-10, orchestration has placed an explicit human hold on acquiring this workstream while the separate Operator Chassis review remains unresolved and its recorded claim, run, and remote branch are preserved. This hold is external to V2's automatic eligibility checks: no claim is authorized until orchestration explicitly lifts it. Do not release or modify the Chassis claim, or infer its release from missing process or worktree state.

## Authoring handoff

Do not claim from this temporary `draft/manual` publication state. The pair is explicitly opted into the atomic authoring handoff; after both packets and the evidence manifest land on `origin/main`, the handoff must validate and promote both packets to `ready/auto`. `ready/auto` and legacy audit classifications are authoring/reporting metadata, not V2 acquisition gates. After the explicit orchestration hold recorded above is lifted, use the supported V2 `dispatch.py claim` path against current `origin/main`; do not require the legacy audit classification to change first. Preserve the legacy `Locks:` metadata and the separate owner's claim/evidence. No packet-level human design decision is pending; the orchestration hold above is separate from packet design approval.
