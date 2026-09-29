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
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `none`
- Locks: `none`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `<short SHA>`
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

Status values: `draft`, `ready`, `in_progress`, `blocked`, `complete`.

Dispatch defaults safely to `manual`; only explicitly marked `auto` packets
can be selected by `dispatch.py claim-next`. Priority is `P0` (highest)
through `P3` (lowest). Dependencies name workstream IDs that must have complete
archived packets on `origin/main`. Locks are comma-separated narrow ownership
IDs held for the duration of a published claim, or `none`.

## V2 Authoring Contract

A V2 packet is ready only when another capable agent can implement it from live
repository state without reconstructing intent from chat history.

Required quality:

- **Reviewed main** identifies the repository state actually investigated.
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
- **Deferred** records intentional omissions so they are not rediscovered as
  accidental incompleteness.

Do not promote a packet to `ready` while its implementation contract still
contains unresolved design choices that require the user's judgment. Use
`draft` or `Dispatch: manual` instead.

Do not encode duplicate technical truth already owned by a schema/resource.
Reference the authority and state the closure condition.

### Authoring Quality Gate

Before setting `Status: ready`:

```text
[ ] Latest main was reviewed and Reviewed main is populated.
[ ] This is one coherent completion boundary.
[ ] Existing Workstream identity was reused when appropriate.
[ ] Current measured state and Evidence are factual, not speculative.
[ ] Task-specific authority and Work surface identify the real owners.
[ ] Change, Preserve, and Non-goals bound the blast radius.
[ ] Acceptance is measurable.
[ ] Validation names focused checks before broad checks.
[ ] Dependencies and Locks reflect actual ordering/contention.
[ ] Review intent is explicit.
[ ] Deferred work is intentional and visible.
[ ] Repository-default workflow boilerplate is not duplicated.
```

### Review Metadata

For substantial implementation work, decide review intent when the packet is
created:

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

Safe defaults keep historical packets valid without this section: missing
`Kind` is `implementation`; missing `Review` is `none`; missing
`Review stage` defaults to `post-land` only when `Review` is `auto`;
missing `Review cycle` is `0`; missing `Max automatic review cycles` is
`2`.

When `Review: auto` is selected, also create a paired review packet on
`main` using `AGENT_REVIEW_PACKET_TEMPLATE.md`, and set this packet's
`Paired review workstream` to its ID. The review-pairing consistency guard
fails closed if the pair is missing or malformed; see `task_packets/README.md`
for the full paired review/correction lifecycle.

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

### Handoff

- Next action:
- Best starting files:
- Blockers or open questions:
