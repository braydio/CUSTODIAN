# AGENT TASK PACKET TEMPLATE

This file is the canonical authoring specification and copyable template for new
CUSTODIAN task packets.

Repository defaults are inherited from `custodian/AGENTS.md` and the root
`AGENTS.md`; do not duplicate them here. A packet exists to make one coherent
implementation boundary executable without another exploratory planning pass.

Use the smallest coherent completion boundary. Skip a packet for narrow,
low-risk work that should simply be patched. Sequential migration steps may
share one packet and acceptance gate when they are one architectural change.
Independent, separately landable work should use separate workstreams.

New packets use `Packet schema: custodian.task_packet.v2`. Existing packets
without that field remain valid legacy packets and do not need bulk migration.

Before authoring, inspect current `origin/main`, applicable AGENTS, the relevant
design/runtime authority, current tests, and any existing packet/workstream for
the same semantic task. Reuse a stable Workstream ID when continuing the same
coherent effort.

# [TASK NAME]

- Packet schema: `custodian.task_packet.v2`
- Workstream: `<lowercase-kebab-id>`
- Status: `draft`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `none`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-WORKSTREAM_ID`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial engineering default` or `low-risk exemption: <why paired review adds little value>`
- Reviewed main: `<short SHA>`
- Authoring chat: `<exact ChatGPT conversation URL | not-recorded | n/a>`
- Visual review: `<none | required-if-subjective | required>`
- Goal:
- Completion boundary:
- Current measured state:
- Evidence:
- Task-specific authority:
- Work surface:
- Change:
- Preserve:
- Non-goals:
- Acceptance:
- Validation:
- Task overrides: `none` or list each as `TASK OVERRIDE: ...`
- Deferred:

## Refresh Planning Authority

Include this block when a packet is dependency/refresh-gated or when landed
evidence may require architecture/scope re-derivation before execution:

- Refresh owner: `none | chatgpt-user | execution-agent`
- ChatGPT/user planning refresh required: `yes | no`
- Refresh planning chat: `<Authoring chat URL | not-recorded | n/a>`
- Refresh instruction: `<exact evidence to bring back and what must be re-derived>`

When the user supplied an authoring-chat URL, reuse that same URL for
`Refresh planning chat`; never substitute a different conversation silently.

Status values: `draft`, `ready`, `in_progress`, `blocked`, `complete`.

Executable packets default to `Dispatch: auto`. `Status`, dependencies, locks, and review pairing are the ordinary claim gates, so a `ready/auto` packet with incomplete dependencies remains blocked and becomes claimable automatically when those dependencies archive `complete`. Use `Dispatch: manual` only when the user explicitly wants to decide when an otherwise implementation-ready packet may be claimed. Priority is `P0` (highest)
through `P3` (lowest). Dependencies name workstream IDs that must have complete
archived packets on `origin/main`. Locks are comma-separated narrow ownership
IDs held for the duration of a published claim, or `none`.

## V2 Authoring Contract

A V2 packet is ready only when another capable agent can implement it from live
repository state without reconstructing intent from chat history.

Required quality:

- **Reviewed main** identifies the repository state actually investigated.
- **Authoring chat** preserves the originating design/planning conversation when the user provides its URL. Use `not-recorded` when no durable URL is available and `n/a` only when no chat authored the packet; never invent one.
- **Goal** states the user-visible or architecture outcome, not the implementation
  method.
- **Completion boundary** says exactly what belongs in this workstream and what
  constitutes done.
- **Current measured state** records live facts, counts, observed defects, or
  current behavior. Do not fill it with intended future state.
- **Evidence** names the concrete files/tests/runtime observations supporting the
  packet. Prefer exact paths, states, counts, commands, or known failure modes.
- **Task-specific authority** names only the authorities that materially govern
  this task. Do not paste the generic repository reading list.
- **Work surface** names the primary owner plus expected consumers/tests. It is a
  starting boundary, not permission to ignore a proven dependency.
- **Change** defines behavior/contract to implement. Be exact about externally
  observable behavior and ownership; let Codex choose local private helpers when
  the repository offers a cleaner seam.
- **Preserve** lists adjacent behavior that must stay intact.
- **Non-goals** prevent plausible scope creep. Do not pad this with unrelated
  systems.
- **Acceptance** is measurable and should be strong enough to reject an
  implementation that merely compiles.
- **Validation** gives focused falsification first and the required closeout
  gate. Avoid broad sweeps when focused tests prove the slice.
- Validation script references may use repository paths (`custodian/tools/...`
  or `tools/...`) or Godot resource paths (`res://tools/...`). A `tools/...`
  reference resolves to the exact root entrypoint when present, then to its
  `custodian/tools/...` counterpart. Keep future implementation-created smoke
  scripts described generically until the file exists; add its exact live path
  to the packet before closeout.
- **Visual evidence economy** applies whenever acceptance touches presentation.
  Name the code/state/geometry/asset/pixel-metric checks that run before model
  vision, justify any full-frame or motion capture that remains necessary, and
  minimize renderer evidence to the smallest ROI/keyframe set that can falsify
  the defect. Reuse durable implementation evidence in paired review instead of
  recapturing equivalent frames. Subjective visual acceptance stays human-owned.
  When a material subjective decision remains after objective checks, instruct
  the execution agent to publish one compact Dropbox handoff with
  `custodian/tools/iteration/publish_review_artifacts.py --important --reason ...`,
  include exact reviewer questions, return the emitted manifest path, and stop
  rather than self-critiquing the art. Reference
  `custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md` instead of restating its
  remote/setup rules.
- **External implementation inputs** belong in a task packet's provenance/evidence
  section as an exact workstream, immutable handoff ID, and manifest path under
  `CUSTODIAN/implementation_inputs/`. Fetch them with
  `custodian/tools/iteration/implementation_handoff.py`; Dropbox is transient
  transport, and verified staging remains untrusted input until the owning task
  and Asset Pipeline V2 authorize promotion. Never use Dropbox as a repository
  mirror or direct runtime source. See
  `custodian/docs/ai_context/IMPLEMENTATION_HANDOFF.md` for the manifest and
  upload contract.
- **Deferred** records intentional omissions so they are not rediscovered as
  accidental incompleteness.

Do not promote a packet to `ready` while its implementation contract still
contains unresolved design choices that require the user's judgment. Keep it
`draft`. Use `Dispatch: manual` only when the contract is otherwise ready but
the user explicitly wants to control claim timing.

Do not encode duplicate technical truth already owned by a schema/resource.
Reference the authority and state the closure condition.

### Authoring Quality Gate

Before setting `Status: ready`:

```text
[ ] Latest main was reviewed and Reviewed main is populated.
[ ] Authoring chat is recorded when the user supplied a durable conversation URL.
[ ] When an Authoring chat URL is supplied, Summary backlink requires that exact URL in every durable implementation/review/correction/recovery summary and final Next Handoff.
[ ] This is one coherent completion boundary.
[ ] Existing Workstream identity was reused when appropriate.
[ ] Current measured state and Evidence are factual, not speculative.
[ ] Task-specific authority and Work surface identify the real owners.
[ ] Change, Preserve, and Non-goals bound the blast radius.
[ ] Acceptance is measurable.
[ ] Validation names focused checks before broad checks.
[ ] Visual evidence is minimized and justified; non-visual alternatives are named first when presentation is in scope.
[ ] If subjective visual judgment remains material, the packet routes one compact handoff through publish_review_artifacts.py and gives the external reviewer specific questions instead of asking the coding agent for aesthetic critique.
[ ] Dependencies and Locks reflect actual ordering/contention.
[ ] Review intent is explicit; substantial/risky work defaults to paired `auto` review.
[ ] `Review: none` carries a concrete `Review rationale: low-risk exemption: ...` rather than convenience/queue avoidance.
[ ] Deferred work is intentional and visible.
[ ] Repository-default workflow boilerplate is not duplicated.
[ ] Acceptance actually proves the stated Goal and Completion boundary, not a
    narrower local optimization that only partially satisfies them.
[ ] An architecture/migration packet names the specific old authority or code
    path whose removal, or intentional preservation, is what proves closure.
[ ] Current measured state was re-derived against live repository state, not
    carried over stale from an earlier packet, before any destructive
    migration step.
[ ] A macro-level architecture goal is not declared complete by a packet
    whose actual change is a narrower local optimization; the Goal is scoped
    to match what this packet truly closes.
```

These four checks are objective closure facts, not subjective prose scoring:
each either names a concrete authority/state or it does not.

### Review Policy — Risk-Based Default

For newly authored or materially re-derived V2 implementation packets, paired
post-land review is the default when an independent second pass can materially
increase confidence. Because narrow low-risk work should usually be patched
without a packet at all, a packeted engineering slice should normally begin
with `Review: auto`.

Use `Review: auto` by default for any of the following:

- runtime behavior, state machines, streaming, persistence, save/load, lifecycle,
  concurrency, scheduling, or authority changes;
- architecture extraction, migration, decomplexification, ownership transfer,
  compatibility cutover, or removal of an old production path;
- production asset-pipeline or authoring-tool changes that write, normalize,
  ingest, publish, or mutate runtime assets;
- tooling that writes production code/data, dispatch/workstream lifecycle,
  validation infrastructure, or safety/rollback behavior;
- performance work whose correctness depends on preserving semantics while
  changing batching, residency, caching, rendering, or execution order;
- substantial bug fixes where a green test could still be vacuous, fixture-bound,
  or narrower than the claimed acceptance;
- multi-system or hard-to-reverse changes where the implementing agent's own
  evidence would benefit from an adversarial acceptance check;
- objective technical presentation work such as registration, layering,
  clipping, visibility, deterministic state correspondence, batching, or
  disabled-mode parity. Subjective aesthetic approval remains human-owned.

`Review: none` is an explicit low-risk exemption, not the normal packet
default. It is appropriate when an independent review is unlikely to add useful
signal, for example:

- documentation-only truth repair with no behavioral contract change;
- a tiny mechanical patch with an obvious local effect, narrow blast radius,
  and direct focused regression;
- temporary/non-production probes or disposable diagnostics;
- simple data/text changes whose correctness is directly inspectable and that
  do not move runtime or pipeline authority.

When using `Review: none`, fill `Review rationale` with
`low-risk exemption: ...` and name the concrete reason. Do not use
`Review: none` merely to shorten the queue or avoid writing a paired packet.

Use `Review: manual` only when a review is useful but cannot truthfully be
auto-completed because it requires a specific external environment, hardware,
credentialed system, or human-owned decision that the normal paired reviewer
cannot resolve. Do not use manual review as a substitute for the ordinary
`human_required` outcome inside an otherwise automatic technical review.

Corrections created from independent-review findings remain `Review: auto`
by default through `AGENT_CORRECTION_PACKET_TEMPLATE.md`.

Legacy packets are not bulk-retrofitted. When new work materially relies on an
older implementation that lacks V2 feedback or independent review, treat its
packet as historical evidence rather than current proof: re-check the surviving
live authority and focused behavior during authoring. If that legacy seam is
high-risk, unclear, or central to the new acceptance contract, the new packet
should use paired review.

Regardless of review intent, every completed V2 implementation/correction still
writes `custodian.task_feedback.v1` Execution Feedback and mirrors it in the
closing summary. Paired review is an additional correctness/evidence layer, not
a replacement for implementation feedback.

### Review Metadata

Record the chosen review intent when the packet is created:

```text
- Kind: `implementation` | `review` | `correction`
- Review: `auto` | `manual` | `none`
- Review stage: `post-land`
- Review modes: comma-separated `code, architecture, runtime, visual,
  asset-pipeline, workflow`, or `none`
- Paired review workstream: `<id>` or `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
```

Parser defaults keep historical packets valid without this section: missing
`Kind` is `implementation`; missing `Review` is `none`; this compatibility rule
is not the authoring default for new/materially refreshed V2 packets. Missing
`Review stage` defaults to `post-land` only when `Review` is `auto`;
missing `Review cycle` is `0`; missing `Max automatic review cycles` is
`2`.

When `Review: auto` is selected, also create a paired review packet on
`main` using `AGENT_REVIEW_PACKET_TEMPLATE.md`, and set this packet's
`Paired review workstream` to its ID. The review-pairing consistency guard
fails closed if the pair is missing or malformed; see `task_packets/README.md`
for the full paired review/correction lifecycle. Auto review packets must carry
the exact bounded review-artifact mutation override from that template; the
dispatcher checks it before claim. Their explicit validation script paths must
resolve to live scripts before an auto claim is allowed.

## Completion Truth

Required before a V2 `implementation` or `correction` packet may be set to
`Status: complete`. `workstream.py finish` enforces this receipt at teardown
time and fails closed if it is missing, malformed, or contains any `no` —
even when validation is green. It is checked again after main-sync if the
packet's bytes changed. Review packets are exempt: they verify someone
else's claim rather than making one. This does not retroactively apply to
already-archived historical packets.

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes | no`
- Completion boundary satisfied: `yes | no`
- Acceptance satisfied: `yes | no`
- Superseded/legacy production path disposition: `removed | intentionally-preserved | n/a`
- Evidence: concrete proof for each `yes` above (exact files/tests/runtime
  observations); a `no` requires the same precision about what remains open

Answer each satisfied field about the packet's own stated Goal/Completion
boundary/Acceptance as authored, not about the work actually delivered post
hoc. If delivered work fell short, say so honestly with `no` and record what
remains in Deferred or a follow-up workstream; do not narrow the Goal
retroactively to make a partial result read as complete.

## Execution Feedback

Complete this section before a V2 packet becomes `Status: complete`. This is a
pipeline/process receipt, not a second implementation recap. Be concise and
specific. "What worked" is optional; failure/friction and prevention matter more.

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `none` or concrete failures/near-misses
- Root cause / contributing factors: `none` or concise cause
- Prevention / pipeline improvement: `none` or the smallest repeatable fix
- Tooling / docs drift discovered: `none` or exact stale/missing authority
- Follow-up: `none | fixed-in-scope | <workstream-id> | manual-follow-up`
- What worked: optional, one short line at most

If a repeatable medium/high-severity workflow problem is discovered, do not bury
it in prose. Fix it in-scope when the correction is small and safe; otherwise
name or create the follow-up workstream before completing the packet.

For packeted work, the required closing summary uses the same feedback fields.
Do not write two divergent narratives; mirror the concise receipt.

## Handoff

Complete this section before a V2 implementation/correction packet becomes
`Status: complete`. Report the **immediate successor in this packet's own
program/DAG**, not an arbitrary globally eligible dispatcher candidate.

- Next workstream: `<workstream-id | none>`
- Next packet state: `ready | dependency-gated | refresh-required | human-required | none`
- Refresh owner: `none | chatgpt-user | execution-agent`
- ChatGPT/user planning refresh required: `yes | no`
- Authoring chat: `<ChatGPT conversation URL | not-recorded | n/a>`
- Summary backlink: `<include the exact Authoring chat URL in every durable summary and final Next Handoff | n/a>`
- Refresh reason: `none | <what must be re-derived/decided before the next packet runs>`
- Next action: `<one concrete action>`
- Blockers or open questions: `none | <exact blocker>`

Use `Refresh owner: chatgpt-user` only when a successor requires a genuine architecture, design, canon, art-direction, or other human-owned choice that existing authority cannot resolve and the user must decide before claim. Do not use it merely because predecessor APIs are not landed yet. Execution agents may report live-code drift and recommendations, but must not silently reinterpret an unresolved human-owned boundary.

When `Refresh owner: chatgpt-user` and an authoring-chat URL is recorded in the next packet or current packet history, surface that exact URL in the closing summary and user-facing reply. If the URL is not recorded, write `Authoring chat: not-recorded` and explicitly ask the user to provide the originating ChatGPT chat link to ChatGPT before refresh if available. Never invent a conversation URL.

Use `Refresh owner: execution-agent` for normal dependency-driven refreshes where predecessor behavior is already bounded by design/packet authority and the claiming agent only needs to reconcile landed public APIs, private helper names, measured state, exact file names/SHAs, or validation paths before mutation. If current evidence introduces a genuinely new material judgment about scope, ownership, sequencing, visuals, lore, or acceptance, stop and escalate to `chatgpt-user`.

The required closing summary **and user-facing completion reply** must mirror
these fields under `## Next Handoff`. If refresh is required, do not imply the
next packet is safe to claim.

## Optional Full-Packet Expansion

Add these only when they preserve task-specific information needed for
high-risk, multi-session, architecture, ownership, migration, or handoff work.

### Ownership And Timing

- Owner:
- Agent/session:
- Created:
- Last updated:

### Plan

Use only when ordering is non-obvious. Prefer implementation contracts over
pseudo-diffs.

1.
2.
3.

### Additional Handoff Notes

- Best starting files:
- Optional operator note: