# Exact paired-review claim parking — implementation handoff

Workstream: `agent-paired-review-exact-claim-parking-v1`

The implementation adds a read-only, plan-pinned parking tool restricted in code to the exact unresolved declared-documentation review claim, run, claim receipt, target packet, lock, and branch SHAs in the packet. Parking appends a `PARKED` commit to a dedicated remote ref using create-only fast-forward semantics; one `ACTIVE` child can restore the lock. Neither transition moves the original `agent/<workstream>` branch or edits the protected worktree or run evidence.

The parking record binds the run evidence manifest and full run inventory digests, local-only commit inventory, worktree file inventory (including ignored files, with bounded hashing), exact remote/local SHAs, authorization scope, attestation, and transition identity. The local process scan includes same-user ancestors and blocks on a matching process or incomplete scan. Because the historical run has no recorded process/host identity, cross-host absence remains an explicit operator attestation; the tool does not claim machine verification of other hosts.

Dispatch now separates identity from lock occupancy. A valid exact `PARKED` record leaves the review `claimed` and prevents a duplicate claim, while releasing only its declared lock. Missing, malformed, stale, changed, or unsupported state keeps the prior lock behavior. Queue audit reports `execution_lock_held`, `parking_state`, and the record SHA separately. The parked review remains unresolved and cannot satisfy a review dependency.

## Validation

- `python3 -m unittest test_review_claim_parking test_dispatch` — 103 tests passed, including two-clone append race, stale-plan and changed-evidence rejection, ignored-file inventory change, active/incomplete process scan negatives, exact lock release and restore, duplicate-claim protection, invalid-record fallback, and unresolved dependency gating.
- `python3 -m unittest test_paired_review_runner test_review_outcome test_review_contract test_paired_review_findings_closeout` — 167 tests passed.
- Combined focused rerun after final record validation changes: all 268 tests passed.
- Targeted packet authoring preflight, packet index write/check, review-pair validation, AI-context validation, Python compile checks, and `git diff --check` passed.
- The source-bearing held review run, its branch/worktree/evidence, other held review claims, and persistent root checkout were not changed. No parking transition was applied.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: an initial ancestor-excluding process scan could have missed an active owning session; the first dispatch integration test loaded a second parking module instance and did not share the fixture's exact authorization scope
- Root cause / contributing factors: owner scanning initially prioritized avoiding self-matches over detecting active parents; the test loader used a noncanonical module name
- Prevention / pipeline improvement: include same-user ancestor processes in owner scans; load the parking module under its canonical import name and test dispatch against a real temporary parked record
- Tooling / docs drift discovered: the general OR1/OR2 parking supervisor remains proposed, so the lifecycle guide now distinguishes this exact-claim pilot and its narrow limitations
- Follow-up: review-agent-paired-review-exact-claim-parking-v1
- What worked: temporary bare remotes exercised append-only fencing and competing clones without touching live claims

## Next Handoff
- Next workstream: review-agent-paired-review-exact-claim-parking-v1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Run the fresh independent paired review. After a genuine PASS, re-audit the exact original review claim, process ownership, remote/local SHAs, and protected evidence before considering the one authorized parking transition.
- Blockers or open questions: Cross-host owner absence cannot be inferred from the local process scan; an explicit auditable operator attestation is required. Do not apply parking during the paired review.
