# QUEUE EXECUTION FRONTIER RESTORATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `queue-execution-frontier-restoration-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `queue-frontier-restoration`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-queue-execution-frontier-restoration-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Queue truth and recovery recommendations must independently demonstrate no claim theft, lost work, or fabricated acceptance.`
- Reviewed main: `9bc75ec7efdfb9c20e946aded3c5beb90f5f2bfd`
- Authoring chat: https://chatgpt.com/share/6ad55849-ccfc-83e9-bc13-882d6d04b12c?ogimg=plain
- Visual review: `none`
- Goal: `Restore a trustworthy, actionable P0 execution frontier despite the existing blocked queue, and enable the highest-impact safe original-owner recoveries rather than adding another dependency chain.`
- Completion boundary: `Make the live dispatcher audit and a bounded read-only frontier report usable by the execution owner; identify the actual top roots on refreshed origin/main; resolve only independently proven safe metadata/index/tooling defects in this slice; publish an ordered existing-claim recovery handoff for protected cases without unapproved claim mutation.`
- Current measured state: `2026-10-17 host audit: 342 active Markdown, 280 managed, 197 dependency/lock blocked, 65 invalid_recovery, 34 claimed, 45 drafts, 1 claimable. Latest main directory holds 353 active Markdown files; this is NOT a refreshed dispatcher census. Static Ready/Auto README is metadata, not actual eligibility. W1 census review and W2/W5 are still gated; original claims and dirty/unique worktrees remain protected.`
- Evidence: `custodian/docs/ai_context/WORKTREE_BACKLOG_RECOVERY_20261017_LEDGER.md; custodian/tools/agent/dispatch.py; custodian/tools/agent/task_packet_index.py; custodian/tools/agent/queue_frontier.py; custodian/tools/agent/test_queue_frontier.py; archived W1 review and current correction packets.`
- Task-specific authority: `custodian/tools/agent/dispatch.py remains sole claim/lock/dependency authority; task_packet_contract.py owns packet grammar; existing workstream/review/host-recovery contracts own recovery and actual reviewer acceptance.`
- Work surface: `custodian/tools/agent/queue_frontier.py; custodian/tools/agent/test_queue_frontier.py; custodian/tools/agent/dispatch.py; custodian/tools/agent/task_packet_index.py; custodian/docs/ai_context/task_packets/README.md; narrowly relevant agent guidance/tests if demonstrated necessary.`
- Publication inputs: `custodian/tools/agent/queue_frontier.py, custodian/tools/agent/test_queue_frontier.py` (both published in the same main commit as this packet and its review; no chat-only dependency).
- Change: `1. In a safe coordinator, run dispatch.py audit --json and queue_frontier.py --json, pin the refreshed origin/main SHA and capture full per-root blocker evidence. 2. Expose Executable Now versus static Ready/Auto metadata clearly, without making a generated README or this analyzer selection authority. 3. Sort blocked roots by distinct downstream reach, then identify exact stale-index/schema bugs, active protected claims, invalid-recovery facts and required reviews. 4. Apply only fixes that the current authorizing rules already allow, using bounded tests and normal landing; leave unresolved host-only/foreign-owner cases protected and give their original owner the exact next supported action. 5. Publish the resulting claimable count, root delta, and next eligible P0 workstream; fail explicitly if no safe one exists. 6. Treat this P0 packet as independently dispatchable regardless of W1-W5 ordering, without altering their recorded review or recovery gates.`
- Preserve: `All original dirty/staged/untracked work, branch/HEAD and claim refs, user coordination checkout, original reviewer verdicts and immutable run artifacts; task_packets/README index generator scope, no duplicate selection authority.`
- Non-goals: `No bulk Status edits, dependency deletion, invented pass, forced unlock, new blanket preemption API, dead-process inference from checkout age, general dispatch replacement, gameplay/art changes, or unauthorized cleanup of W1-W5 and other owners.`
- Acceptance: `A1. This packet is P0 ready/auto, has Depends on none and its own narrow lock; dispatcher eligibility (or exact externally held conflict) is demonstrated against live main. A2. Analyzer and focused fixtures shipped in the SAME original main commit as the packet; future required implementation aids must likewise be committed with their packet. A3. Live audit and generated frontier reconcile packet totals, eligible IDs, invalid and claimed categories; root counts are never summed across overlapping dependencies. A4. No preexisting worktree/ref/claim or unaccepted review is changed solely to improve eligibility. A5. Report before/after true claimable count and at least the five largest root fronts, with exact original-owner recovery path for unresolved cases. A6. Index clearly differentiates authored ready metadata from live dispatcher claimability. A7. Focused regressions, pairing/queue/index validators and changed-file validation green; independent paired review required.`
- Validation: `python3 -m unittest custodian.tools.agent.test_queue_frontier custodian.tools.agent.test_dispatch custodian.tools.agent.test_task_packet_index -v; python3 custodian/tools/agent/validate_review_pairing.py; python3 custodian/tools/agent/task_packet_index.py; python3 custodian/tools/agent/check_ai_context.py; python3 custodian/tools/validation/run_validation.py --changed --json; git diff --check.`
- Task overrides: `none`
- Deferred: `Host-only recovery apply, W1 verdict, W2 preservation, W5 invalid claims and any sensitive/owner-ambiguous cleanup remain separately owned, evidence-gated tasks. This workstream supersedes their priority for queue diagnostics, not their factual or safety authority.`

## Execution start

From a clean coordination checkout run `python3 custodian/tools/agent/dispatch.py audit --json > /tmp/custodian-queue-audit.json` then `python3 custodian/tools/agent/queue_frontier.py /tmp/custodian-queue-audit.json --json > /tmp/custodian-queue-frontier.json`. If the dispatcher marks this P0 packet eligible, claim it normally with `python3 custodian/tools/agent/dispatch.py claim queue-execution-frontier-restoration-v1 --agent codex`, and do all edits only in the returned isolated worktree. Never treat this procedure as permission to claim over an original owner.

## Handoff

- Next workstream: `review-queue-execution-frontier-restoration-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/share/6ad55849-ccfc-83e9-bc13-882d6d04b12c?ogimg=plain
- Refresh reason: `none`
- Next action: `Complete focused validation and normal finish/land, then run fresh independent paired review; resume each protected owner only under its existing contract.`
- Blockers or open questions: `Host-local current claims, status and liveness require on-host audit; this packet does not assert authority to alter them.`
