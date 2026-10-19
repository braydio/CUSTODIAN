# AGENT PAIRED REVIEW EXACT CLAIM PARKING V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-exact-claim-parking-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `paired-review-claim-parking`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-exact-claim-parking-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `claim ownership and lock release must remain separate without falsifying reviewer disposition or risking recoverable work`
- Reviewed main: `94948f36c2c86137930ab4b225380510861302e3`
- Authoring chat: `not-recorded`
- Authoring handoff: `auto`
- Visual review: `none`
- Goal: Preserve the unresolved declared-documentation review claim and its recoverable work while allowing its unrelated execution lock to be parked only under exact, independently verifiable authority.
- Completion boundary: Add a versioned, fenced PARKED record and read-only plan/apply/unpark path for the one authorized review claim `review-agent-paired-review-declared-doc-archive-gate-v1` / run `20261019T104055Z-522c04f5260b`; update dispatch so that a valid PARKED record keeps that review identity claimed while releasing only its `paired-review-source-provenance` lock. Do not make general orphan recovery or any other live claim parkable.
- Current measured state: At `origin/main@628d403d2629a3f568b003096e4d94585721399f`, `dispatch.py` treats every published `agent/<workstream>` branch as both claim identity and logical lock occupancy. The target review remains unresolved in `post_exit_recovery`, its continuation is at `coordinator_closeout`, and its remote branch is `f3a225c426a51736551b88c91ea2b786a69e8f5a`; the protected local worktree is at `ad2009ca91a8afec457c8b21c202f1b10b7ca086` and is one commit ahead. No canonical review verdict or findings IDs exist. The lifecycle document describes the broader OR2 mechanism as proposed/not implemented.
- Evidence: `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/paired_review_runner.py`; `custodian/tools/agent/test_dispatch.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_ORPHAN_RECOVERY_SUPERVISOR_V1.md`; exact local run evidence under `.git/custodian-review-runs/review-agent-paired-review-declared-doc-archive-gate-v1/20261019T104055Z-522c04f5260b/`.
- Task-specific authority: Root and `custodian/AGENTS.md`; `AGENT_WORKSTREAM_LIFECYCLE.md`; `AGENT_ORPHAN_RECOVERY_SUPERVISOR_V1.md`; the target review packet and original run metadata. The dispatcher remains the only packet-claim authority; this packet does not alter the target review's acceptance state.
- Work surface: `custodian/tools/agent/review_claim_parking.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/test_review_claim_parking.py`; `custodian/tools/agent/test_dispatch.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; one root closing summary.
- Publication inputs: `none`
- Change:
  1. Add a read-only exact-claim inspector and plan that verify the pinned target workstream/run, original evidence manifest, remote branch SHA, local branch/worktree SHA and file inventory, claim identity, and available process/host evidence. The plan must identify any unprovable owner or cross-host state as unknown and refuse apply while it is unknown.
  2. Add a narrow append-only PARKED record under a dedicated `refs/custodian/review-claim-parking/<workstream>` ref. Bind schema/version, exact review workstream and run, unchanged remote branch SHA, local SHA and inventory digest, original run-evidence manifest digest, explicit authorization scope, and transition identity. Use create-only/fast-forward CAS; never delete or rewrite the `agent/<workstream>` branch or its claim ref. Store only a redacted inventory, not worktree/run contents.
  3. Provide plan-pinned park and unpark transitions. Park requires a clean, independently reverified plan, intact evidence, exact expected refs, no active local owner, and explicit operator attestation for any owner fact that cannot be machine-proven. Cross-host ambiguity without an explicit, auditable owner attestation fails closed. Unpark appends an ACTIVE state and restores conservative lock occupancy. Repeated, stale, malformed, mismatched, or concurrent transitions fail closed.
  4. Separate dispatcher `claimed` identity from logical-lock occupancy. A PARKED record is recognized only for the exact authorized claim/run and exact branch SHA; the parked review remains claimed against duplicate identity, and its packet remains unaccepted. Missing, stale, malformed, unsupported, or mismatched records keep the old branch-derived lock behavior.
  5. Document the bounded contract and its limits in `AGENT_WORKSTREAM_LIFECYCLE.md`; explicitly distinguish `ready/auto` packet state from live `dependency_lock_blocked` eligibility.
- Preserve: Original run and continuation files byte-for-byte; original review verdict as unresolved; remote branch at its audited SHA; local branch, commit and attached worktree; strict-authority packet lock declaration; existing assignment/temporary claim CAS; all unparked branch-derived lock behavior; accepted-review dependency gates; persistent root checkout; unrelated review claims and worktrees.
- Non-goals: Parking any claim other than the exact pinned review; creating a reviewer PASS/findings outcome; editing target or review packets as a substitute for review; cleaning, deleting, force-updating, rebasing or landing the held review branch; generic OR1/OR2 supervisor implementation; auto-timers or background recovery; automatic cross-host takeover; changing review acceptance/dependency semantics.
- Acceptance:
  1. A read-only plan identifies exact pinned run/remote/local identities and hashes without writing Git refs or run evidence.
  2. Exact authorized state can be parked using an append-only CAS record while remote `agent/<id>` and local branch/worktree remain unchanged and recoverable.
  3. A valid parked review remains `claimed` for its own workstream, cannot be claimed twice, does not block unrelated work on its released lock, and does not satisfy any accepted-review dependency.
  4. Unpark restores lock occupancy without changing claim identity or verdict.
  5. Negative tests reject active owners, unresolved cross-host ownership, wrong workstream/run/SHA, changed evidence manifest or worktree inventory, duplicate or malformed records, missing record, stale plan digest, changed remote branch, concurrent park/unpark races, and any attempt to target a different claim.
  6. Existing dispatcher claim/lock and paired-review receipt/acceptance behavior remains unchanged for legacy/unparked branches and malformed parking state.
  7. The exact original run directory, local-only commit and remote branch have identical pre/post hashes/SHAs; no PASS, canonical findings disposition, or target receipt is synthesized.
- Validation: Run `python3 -m unittest test_review_claim_parking test_dispatch` from `custodian/tools/agent`; run focused existing `test_paired_review_runner` and review receipt acceptance tests; exercise two clones against a temporary bare Git remote for create-only and concurrent append races; run targeted task-packet authoring validation for this pair, `task_packet_index.py --write` then check, packet pairing, AI-context checks, complete changed-file coverage, and `git diff --check`. After landing, require a fresh independent paired review before any live park command.
- Task overrides: `none`
- Deferred: General execution leases, process supervision, automated host-exit detection, and all other orphan recovery remain with the existing OR1/OR2 architecture and its dependency DAG.

## Handoff

- Next workstream: `review-agent-paired-review-exact-claim-parking-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: Claim through dispatch only when both declared ownership locks are eligible; implement and validate the bounded exact-claim transition, then obtain a fresh independent review.
- Blockers or open questions: The existing `agent-workflow` lock may remain occupied by another unresolved review; dispatcher eligibility must be rechecked after publication. The target run does not contain a process identity, so any cross-host liveness ambiguity must remain a fail-closed gate unless explicit auditable owner attestation resolves it.
