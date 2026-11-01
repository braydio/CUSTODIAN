# Review: Paired-review unaccepted supersession lifecycle

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-unaccepted-supersession-v1`
- Category: `agent-ops`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-paired-review-unaccepted-supersession-v1`
- Locks: `legacy-claim-scoped-snapshot`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `agent-paired-review-unaccepted-supersession-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_UNACCEPTED_SUPERSESSION_V1.md`
- Reviewed main: `979cb454454554c1a1dedc9a506a36ec831407a1`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently determine whether the landed supersession planning and synthetic recovery tooling can preserve a stranded review claim without accepting its historical PASS or weakening canonical dispatcher/review invariants.
- Completion boundary: Review the exact landed implementation, archived target packet, tests, validation evidence, and preservation of protected records. Write only the permitted durable review artifacts and bounded correction/re-review packet if findings require correction. Never execute live supersession or launch a reviewer for a protected run.
- Current measured state: The protected historical review has an unaccepted PASS and held claim/lock. The supersession implementation is dependency-gated behind `review-agent-legacy-claim-scoped-snapshot-v1`, which owns overlapping source paths. No plan/apply against live protected state is authorized.
- Evidence: Exact implementation commit and parent; archived implementation packet; synthetic repository tests and crash-injection reports; original reviewer artifact immutability checks; dispatcher dependency tests; upstream scoped-snapshot review completion and lock release; exact-head CI.
- Task-specific authority: The archived implementation packet; RC-125 authorization; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/tools/agent/paired_review_supersession.py`; `custodian/tools/agent/legacy_claim_quarantine.py`; dispatcher and workstream lifecycle source; review-outcome and receipt authorities.
- Work surface: Read-only review of the exact landed implementation, its tests, related lifecycle hooks and the archived target. Only the canonical review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and a bounded correction/re-review packet may be written. Never edit the reviewed implementation, original reviewer evidence, upstream claimed review, protected worktree, branch, claim, or lock.
- Publication inputs: `custodian/tools/agent/paired_review_supersession.py`; `custodian/tools/agent/test_paired_review_supersession.py`; `custodian/tools/agent/legacy_claim_quarantine.py`; `custodian/tools/agent/test_legacy_claim_quarantine.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/review_outcome.py`; `custodian/tools/agent/review_receipt_delta.py`; `custodian/tools/agent/paired_review_host_validation.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_UNACCEPTED_SUPERSESSION_V1.md`.
- Review focus: Verify exact deterministic plan identity and complete inventory/hash/mode/symlink coverage; durable-backup size includes all Git and required LFS data; published-ref fallback is authenticated by original trace, structured receipt or established safe resolver, worktree-published event and exact local checkout; missing, unrelated, ambiguous, forged, replayed, changed, active-owner and foreign-owner cases fail closed; apply requires exact plan SHA, independently reviewed plan, verified durable backup, separate authorization, and repeated host/ref/process/lock checks; ref updates are exact CAS and crash-safe/idempotent; both historical tips and reviewer-authored artifacts remain byte-for-byte preserved; administrative unaccepted status is distinct from reviewer verdict; historical PASS cannot satisfy dependencies or alter status; no `review-...-v2` alias or live target operation exists; tests cover all listed adversarial and injected-crash states; existing quarantine, finish, dispatch, and review receipt contracts remain intact; upstream dependency and shared lock were resolved before implementation claim.
- Acceptance: PASS only with independent evidence for every implementation acceptance claim, exact-head tests/CI, unchanged protected evidence, synthetic-only apply validation, and no weakening of claim/lock/dispatcher/review authority. A green test suite alone is insufficient. Any ambiguity about real-host owners, backup restorability, original evidence, or review-status semantics is a blocking finding. Do not execute a real plan/apply as part of this review.
- Validation: Independently inspect the exact landed diff and archive identity; run the focused supersession test module created by the implementation, `python3 custodian/tools/agent/test_legacy_claim_quarantine.py`, and the focused dispatcher/workstream tests; inspect crash/retry/readback evidence; run `git diff --check`; verify exact-head CI; confirm all protected live identities, claims, locks and evidence remain untouched. No live snapshot, plan, apply, reviewer launch, or claim release.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933`
- Refresh instruction: `none`
- Next action: After independent PASS and normal closeout, a future exact live plan may be authored/read-only reviewed. Do not snapshot, apply, release claims/locks, detach the original worktree, or launch any reviewer without a new exact-plan authorization.
- Blockers or open questions: None for this review packet beyond normal dependency resolution and implementation landing. Future real recovery remains a separate authorization boundary.
