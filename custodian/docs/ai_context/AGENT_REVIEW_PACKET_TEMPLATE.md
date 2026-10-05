# AGENT REVIEW PACKET TEMPLATE

Repository defaults are inherited from `custodian/AGENTS.md` and the root
`AGENTS.md`. This template is the paired post-land review counterpart to
`AGENT_TASK_PACKET_TEMPLATE.md`; see `task_packets/README.md` for the full
paired review and correction lifecycle this packet participates in.

Copy this file into `custodian/docs/ai_context/task_packets/` alongside the
implementation packet it pairs with, only when that packet declares
`Review: auto`.

Naming convention:

```text
<IMPLEMENTATION_NAME>.md            workstream: <implementation-id>
REVIEW_<IMPLEMENTATION_NAME>.md     workstream: review-<implementation-id>
```

# REVIEW: [IMPLEMENTATION TASK NAME]

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-<implementation-id>`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `<match or exceed the implementation's priority>`
- Depends on: `<implementation-id>`
- Locks: `<match the implementation's locks that still apply, or none>`
- Review: `none`
- Review target workstream: `<implementation-id>`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/<IMPLEMENTATION_NAME>.md`
- Reviewed main: `<full or short main SHA being reviewed>`
- Authoring chat: `<inherit the implementation packet's exact URL | not-recorded | n/a>`
- Visual review: `<inherit: none | required-if-subjective | required>`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent` | `same-agent-fresh-context`
- Review modes: `<comma-separated: code, architecture, runtime, visual, asset-pipeline, workflow>`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the newly landed implementation against its own
  packet contract and live repository behavior.
- Reviewed implementation acceptance: `<copy or reference the exact acceptance claims from the archived implementation packet>`
- Review evidence: `<durable implementation evidence reused, plus any focused evidence gathered by this review>`
- Correction threshold: Create correction work only for a confirmed acceptance/correctness defect or an evidence gap that prevents confidence in required acceptance. Route non-blocking issues and optional improvements to next-slice/deferred unless separately justified. Escalate unresolved subjective decisions as `human_required`.
- Focused validation: `<smallest relevant validation commands and outcomes; identify proof gaps>`
- Review focus: `<the specific risks this task's design/history calls out>`
- Acceptance: Produce a findings-first independent review of live `main`.
  Record a `passed` receipt or concrete findings. Give each finding a stable
  cycle-scoped ID (`R<cycle>-<NN>`) and the required class, domain, affected
  acceptance, evidence, disposition, and rationale. Blocking defects and
  material acceptance-proof gaps create `<implementation-id>-review-corrections-<n>`
  plus its paired review packet. Do not patch reviewed implementation code.
- Non-goals: Do not redesign the reviewed system, add a pre-land review gate,
  add continuous workers, or fix reviewed implementation directly.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the dependency is complete and archived on `origin/main`.
2. Start from a **fresh reviewer context**. Do not continue the implementation conversation/session or rely on its transient reasoning. A reviewer may be the same model/agent family that implemented the target only when this is a newly started context/workstream that reconstructs the task solely from durable repository evidence. Record `Reviewer context: fresh` and `Reviewer provenance: different-agent | same-agent-fresh-context` in the review packet/receipt. If fresh context cannot be established, stop rather than claiming independent review.
3. Read root/local `AGENTS.md`, this packet, the archived implementation packet, its closing summary, active design authority, `custodian/docs/ai_context/prompts/review_runtime_change.md`, and live implementation files.
4. Review the landed implementation against its original acceptance contract,
   not just style.
5. Report confirmed findings first with file/line references where practical.
6. Assign each finding its cycle-scoped ID and one class (`blocking_defect`,
   `evidence_gap`, `non_blocking_issue`, `optional_improvement`), domain
   (`implementation`, `pipeline`), affected acceptance, evidence, one
   disposition (`correction`, `next_slice`, `deferred`, `human_required`,
   `no_action`), and rationale. An evidence gap is blocking only when it
   prevents confidence in required acceptance.
7. **Do not modify reviewed implementation or runtime code in this
   workstream.** Independent review requires a separate workstream, a fresh
   agent context, and no implementation fixes performed inside it.
8. For visual review, consume the implementation's structured telemetry,
   deterministic probes, image metrics, and targeted crops first. Do not
   regenerate equivalent full-frame evidence merely for reviewer independence.
   Recapture only when evidence is missing, stale, contradictory, or cannot
   establish an acceptance criterion.
9. Keep objective technical visual review separate from subjective art direction.
   Registration, clipping, alpha, visibility, layering, duplicate/missing
   presentation, and deterministic state correspondence may be decided from
   machine evidence. Baseline aesthetics, composition preference, game feel,
   and art-direction acceptance remain human-owned.
10. If that human-owned decision is material and the implementation did not
   already publish adequate compact evidence, use
   `custodian/tools/iteration/publish_review_artifacts.py --important --reason ...`
   after the objective review is complete. Publish only the minimum ROI/contact
   sheet/keyframes needed, include exact reviewer questions, and report both the
   inherited exact `Authoring chat` and Dropbox manifest path. The authoring
   ChatGPT conversation is the review endpoint and should inspect the connected
   Dropbox path. Set the unresolved subjective decision to `human_required`.
   After its verdict returns, run the emitted `--cleanup-reviewed` command unless
   retention was explicitly requested. Do not perform the aesthetic decision
   inside the coding/review agent.
11. Separate implementation findings from pipeline/process findings. Record
   pipeline friction through `custodian.task_feedback.v1`; fix a small safe
   workflow issue in-scope or name a follow-up for repeatable medium/high
   severity.
12. Append or refresh the archived implementation packet's `## Independent
   Review` receipt (see `task_packets/README.md` for the exact shape).
13. If correction-worthy findings exist, create a delta packet from
   `AGENT_CORRECTION_PACKET_TEMPLATE.md` that references exact finding IDs, plus
   its paired review packet. Do not restate the feature design.
14. At `Max automatic review cycles`, set the receipt status to
   `human_required` instead of scaffolding another automatic correction.
15. If clean or only non-blocking findings remain, record the dispositions and
   set the receipt to `passed` or `findings` as appropriate; create no
   correction packet.
16. Complete/archive this review packet through the normal workstream
    lifecycle. Do not mark the reviewed implementation's own packet complete
    again; implementation completion and independent review are separate
    truths.

## Reviewer Independence Gate

Paired review means independent **context**, not necessarily a different vendor
or model family. The same agent/model family may review its own prior
implementation only when all of the following are true:

- the implementation session/context is ended and not continued;
- the review starts as a fresh workstream/context with no transient
  implementation reasoning carried forward;
- the reviewer reconstructs intent from the archived packet, closing summary,
  live code, tests, design authority, and fresh traces/mutations;
- the durable receipt records `Reviewer context: fresh` and provenance as
  `same-agent-fresh-context`;
- the reviewer treats the implementation summary as a claim to verify, not as
  evidence by itself.

A different agent/context should use `Reviewer provenance: different-agent`.
If the platform cannot provide a fresh context, the result is an ad hoc
self-review, not the paired independent review required by this contract.

Fresh context does not require a different model family. Different-family review
can improve diversity, but the contract optimizes for reproducible evidence and
context separation rather than vendor identity.

## Human Decision Gate

Do not auto-approve genuinely subjective choices such as visual baselines, art
direction, game-feel tradeoffs not locked by design, or unresolved canon/design
interpretation. For these, finish technical review, set the receipt to
`human_required`, and identify the exact decision/evidence without guessing
the user's preference. Objective technical defects in the same task still
become corrections automatically.

## Handoff

Complete this section in the durable review receipt/summary after the review
verdict is known. Report the immediate successor in the reviewed program/DAG,
not an arbitrary globally eligible packet.

- Next workstream: `<workstream-id | none>`
- Next packet state: `ready | dependency-gated | refresh-required | human-required | none`
- Refresh owner: `none | chatgpt-user | execution-agent`
- ChatGPT/user planning refresh required: `yes | no`
- Authoring chat: `<ChatGPT conversation URL | not-recorded | n/a>`
- Refresh reason: `none | <what live review result means the next packet must reconsider>`
- Next action: `<one concrete action>`
- Blockers or open questions: `none | <exact blocker>`

For architecture/design-sensitive refreshes, use `Refresh owner: chatgpt-user`.
The reviewer supplies the live evidence and exact drift but does not rewrite the
next packet's architecture unless its own review override explicitly authorizes
that packet mutation. If an authoring-chat URL is recorded, surface it exactly
so the user can provide that conversation to ChatGPT for refresh. If absent,
say `not-recorded`; never invent one.

The closing summary and user-facing reply must include the same fields under
`## Next Handoff`.
