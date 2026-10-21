# Legacy Claim Scoped Preservation Snapshot V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-legacy-claim-scoped-snapshot-v1`
- Authoring handoff: `auto`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `legacy-claim-scoped-snapshot`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-legacy-claim-scoped-snapshot-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `preservation manifests gate release of dispatcher execution locks; independent review must verify exact restoration coverage and fail-closed behavior`
- Reviewed main: `705de22f91430f556485c134d0b085bbd9ac5b31`
- Authoring chat: `not-recorded`
- Visual review: `none`
- Goal: Preserve one exact legacy claim and its reviewer evidence in a verified, independently restorable backup without copying unrelated repository-wide Git LFS objects.
- Completion boundary: Add an explicit target-workstream scoped mode to the existing quarantine snapshot authority, validate and restore-check its versioned manifest, retain V1 manifest verification, and prove adversarial ownership, path, LFS, storage, and race failures. Do not apply quarantine to the live no-op review as part of implementation or review.
- Current measured state: `legacy_claim_quarantine.py::snapshot()` archives the complete shared `.git/lfs/objects` tree for every target. The live shared store is about 9.7 GB, the protected no-op reviewer worktree about 5.5 GB, and available filesystem space about 11 GB. The prior campaign's snapshot therefore could not produce a verified manifest. No active packet or dirty worktree reserves this source file or test file; the protected no-op claim owns a different `paired-review-noop-sync-provenance` lock.
- Evidence: `custodian/tools/agent/legacy_claim_quarantine.py::snapshot,verify_snapshot,_build_plan,_verify_run_binding`; `custodian/tools/agent/test_legacy_claim_quarantine.py`; `custodian/docs/ai_context/PAIRED_REVIEW_CLOSURE_CAMPAIGN_20261020.md` V1.1; `.git/custodian-review-runs/review-agent-paired-review-noop-main-sync-trace-v1/20261019T160124Z-6b87e4307a2b/` and its `continuation-01/`.
- Task-specific authority: The V1.1 continuation amendment; exact workstream claim/run identities; `legacy_claim_quarantine.py` ownership, process-exit, backup, plan-digest, CAS, and dispatcher gates; existing V1 snapshot records and schemas.
- Work surface: `custodian/tools/agent/legacy_claim_quarantine.py`; `custodian/tools/agent/test_legacy_claim_quarantine.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` only for any snapshot-contract guidance made stale by the implementation; `AGENT_LEGACY_CLAIM_SCOPED_SNAPSHOT_V1_CLAUDE_SUMMARY.md`.
- Publication inputs: `custodian/tools/agent/legacy_claim_quarantine.py`; `custodian/tools/agent/test_legacy_claim_quarantine.py`; `custodian/docs/ai_context/PAIRED_REVIEW_CLOSURE_CAMPAIGN_20261020.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/AGENT_TASK_PACKET_TEMPLATE.md`.
- Change: Add a named, versioned, target-workstream scoped snapshot mode in the existing quarantine tool. Pin and preserve only the requested workstream's exact claim, agent, and verified diagnostic refs/ancestry plus the pinned main prerequisite; include complete tracked, dirty, untracked, ignored, and symlink worktree bytes and all exact run/continuation/workflow evidence. Enumerate Git LFS pointer OIDs required to restore those protected refs and bytes. For each OID, prove exact SHA-256 bytes are in the scoped backup (deduplicate when the worktree archive itself contains the matching materialized bytes) or fail closed if the bytes are absent. Do not rely on the shared mutable LFS cache after snapshot creation. Estimate archive and bundle size before writing, include filesystem reserve, and refuse before creating payloads when space is insufficient. Use a separate scoped manifest schema and verifier that proves restoration coverage and exact inventories. Preserve verification of historical V1 manifests and all existing quarantine identities and CAS gates. Never change quarantine owner, ref identity, lock release, or dispatch dependency semantics.
- Preserve: Existing V1 backup manifest verification and legacy records; exact original refs and claim ancestry; complete worktree/run/evidence inventories; symlink targets and modes; immutable original traces; workstream-bound process-exit verification; generation, exact plan digest, compare-and-swap publication, and failure-on-stale/missing/corrupt evidence.
- Non-goals: Rewriting or releasing the protected no-op claim; treating quarantine as an accepted review or dependency completion; broad backup of all worktrees or shared LFS objects; a second quarantine implementation; deleting/moving original files; changing historical review outcomes; changing source-span validation.
- Acceptance: (1) Scoped mode accepts an exact one-workstream target and produces a versioned manifest binding all target refs, pinned main prerequisite, worktree inventory, review-run/continuation and workflow-trace inventories, payload digests, and every required LFS OID/size/SHA-256. (2) Restore verification checks bundle prerequisites and refs, safely extracts to an isolated fixture, verifies every path/mode/symlink/hash and every required LFS object byte, and rejects a missing or mutated payload. (3) V1 manifests and existing quarantine records still verify unchanged. (4) Insufficient space is detected before payload creation using conservative predicted size plus reserve; no partial backup is mistaken for verified. (5) Missing LFS objects, pointer/byte mismatches, duplicate or unsafe paths, symlink traversal, wrong/multiple workstreams, ref/main races, changed worktree/evidence/trace inventories, corrupt manifests, and owner active/unknown/cross-host conditions fail closed. (6) The existing quarantine planner/apply semantics and claim/dependency identity are unchanged. (7) The no-op review claim, branch, worktree, continuation, and source-validator lock are not modified by this workstream.
- Validation: Test-first additions to `custodian/tools/agent/test_legacy_claim_quarantine.py`; run `python3 custodian/tools/agent/test_legacy_claim_quarantine.py`; run `python3 -m py_compile custodian/tools/agent/legacy_claim_quarantine.py custodian/tools/agent/test_legacy_claim_quarantine.py`; run `git diff --check`; run the repository's changed-file selection and packet/index validations required at closeout. Use temporary Git/LFS fixtures only; do not snapshot or mutate the protected no-op claim during implementation.
- Task overrides: `none`
- Deferred: Once this implementation lands, re-run an exact snapshot of the no-op claim and continuation to a new empty external destination, verify the manifest and restore in isolation, then perform a fresh exact-owner quarantine plan/apply only if every amended V1.1 gate still passes. The quarantine remains a separate campaign transition and does not change review acceptance.

## Recommended Implementation Order

1. Write real temporary-repository tests for the versioned scoped snapshot, LFS pointer inventory, worktree/evidence restore coverage, and preflight storage rejection; confirm expected failures before production changes.
2. Implement scope discovery, conservative size estimation, scoped payload creation, manifest binding, and restore verification in the existing authority.
3. Add corruption, race, active/unknown/cross-host owner, V1 compatibility, and quarantine-identity negative controls.
4. Run focused and changed-file validation; record exact outputs and measurements in the root closing summary. Do not apply the live no-op quarantine here.

## Completion Truth

- Claim/run identity verified: pending
- Required source/tests/docs implemented: pending
- Scoped snapshot restore proof: pending
- V1 compatibility and quarantine identity preserved: pending
- Required validation: pending
- Completion status: pending

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: pending
- Friction severity: pending
- What went wrong: pending
- Root cause / contributing factors: pending
- Prevention / pipeline improvement: pending
- Tooling / docs drift discovered: pending
- Follow-up: pending
- What worked: pending

## Handoff

- Next workstream: `review-agent-legacy-claim-scoped-snapshot-v1`
- Next packet state: dependency-gated
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: `After implementation lands and archives, run the paired independent review; then resume the campaign's exact no-op coordinator-closeout/quarantine gate.`
- Blockers or open questions: `none`
