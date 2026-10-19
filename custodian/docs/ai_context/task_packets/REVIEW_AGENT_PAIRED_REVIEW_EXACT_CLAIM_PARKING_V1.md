# REVIEW: AGENT PAIRED REVIEW EXACT CLAIM PARKING V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-exact-claim-parking-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-exact-claim-parking-v1`
- Locks: `agent-workflow, paired-review-claim-parking`
- Review: `none`
- Review target workstream: `agent-paired-review-exact-claim-parking-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_EXACT_CLAIM_PARKING_V1.md`
- Reviewed main: `628d403d2629a3f568b003096e4d94585721399f`
- Authoring chat: `not-recorded`
- Authoring handoff: `auto`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently prove that exact-claim parking separates execution-lock occupancy from preserved claim identity without losing the unresolved review or weakening dispatch acceptance.
- Reviewed implementation acceptance: Verify every acceptance item in the archived implementation packet and reproduce the park/unpark behavior using a temporary bare remote and at least two independent clones.
- Review evidence: Exact run/claim identity and evidence manifests; source diff; append-only parking record format; temporary remote race and stale-plan reports; dispatcher audit/claim output; before/after target branch, local worktree and immutable run checksums.
- Correction threshold: Any way for malformed, stale, arbitrary or mismatched parking data to release a lock; any duplicate same-workstream claim; any change to protected branch/worktree/run evidence; any conflation of PARKED with accepted review; any false claim of cross-host process verification is blocking.
- Focused validation: Re-run the exact supported tests from the implementation packet; independently inspect ref CAS and two-clone races; verify branch-derived fallback on missing/corrupt state; verify parked identity still blocks same-ID claim and never satisfies review dependency; compare pinned local/remote SHAs and evidence hashes.
- Review focus: Authorization boundary, remote ref fencing, evidence binding, cross-host uncertainty, dispatcher classification, error recovery, append-only unpark, preservation of the three state dimensions (claim identity, execution lock, review acceptance).
- Acceptance: Zero blocking findings and zero material evidence gaps. A passing implementation review does not itself apply the live parking transition; the exact live claim must be re-audited and the already-granted one-time authorization conditions reverified first.
- Non-goals: Applying the transition during review; changing the held review's verdict; authoring a PASS receipt; general OR2 acceptance; editing the strict-authority implementation packet or its lock.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

Use `custodian/docs/ai_context/AGENT_REVIEW_PACKET_TEMPLATE.md`. Start a fresh reviewer context. Keep all race/process/evidence fixtures isolated from the live held worktrees and remotes. After review, stop before applying any live parking transition.

## Handoff

- Next workstream: `agent-paired-review-strict-work-surface-authority-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: After a genuine independent PASS, re-audit and park only the exact authorized review claim; then rerun dispatch eligibility and claim the named strict-authority implementation if eligible.
- Blockers or open questions: A missing process identity or unverifiable cross-host owner remains a live apply blocker; no transition is authorized on an assumption.
