# Turn-Scoped Dispatcher V2 — Stage 3A Integration Readiness

**Status:** Stage 3A implementation candidate; opt-in only. No production cutover.
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0
**Parent specification:** [TURN_SCOPED_DISPATCHER_V2.md](TURN_SCOPED_DISPATCHER_V2.md)

## Definition acquisition

The V2 acquisition layer distinguishes three cases:

| Case | Identity source | Authentication and provenance | Execution behavior |
|---|---|---|---|
| Published packet | Exactly one packet with the requested `Workstream:` in fetched `origin/main` | Packet path, main commit, and packet-content SHA are recorded. A conflicting or malformed identity fails closed. | Normal and historical modes use the authenticated packet. Old status, dispatch, lock, claim, and dependency metadata do not gate V2 selection. Explicit current user-design holds remain holds. |
| Explicit owner-authorized new work | Caller supplies a canonical workstream plus an exact ChatGPT conversation URL and SHA-256 of the authorizing instruction | The private acquisition receipt records the URL/digest and labels identity verification `false`; this is caller authorization provenance, not a signature or a claim of independent identity verification. Local files alone cannot authorize this mode. | A fresh `agent/<workstream>` branch can be created from authenticated current main. If a published packet appears after acquisition, checkpoint blocks and requires re-acquisition against that packet. When the repository authoring policy requires a packet before execution, publish it through the normal reviewed workflow first. |
| Historical task | Exactly one current or archived published task definition on fetched `origin/main` | Current task-definition bytes are authenticated as above; prior branch and archive data remain optional historical evidence and each source must verify independently. | Reuse an exact reachable historical branch when safe; record ancestry in both directions relative to current main. Missing or unverifiable history falls back to authenticated current main. No archive byte is consumed by the Stage 3A CLI unless its manifest verifies. |

No mode infers a review PASS, owner decision, task completion, or authorization from an old dispatcher status. A missing definition is not silently filled with a fabricated packet. An unresolved design hold found in a published packet blocks acquisition. Owner-authorized metadata is private and should not be treated as a durable task definition; publish the packet through normal review when project policy requires one.

## Intentional behavior differences

| Concern | Legacy dispatcher | V2 Stage 3A behavior | Must remain true |
|---|---|---|---|
| Packet status and dispatch flag | Determines queue eligibility | Not a task-identity gate | Packet bytes and identity still authenticate against advertised main. |
| Dependencies and `Locks:` | May block a claim | Not a V2 selection gate | Correctness prerequisites are handled in scope; no legacy claim is released or rewritten. |
| Existing execution claim/session | Prevents another claim or requires resume | Not V2 ownership authority | Concurrent publication remains non-forcing; losers retain their data and reconcile. |
| Human design hold | Prevents work where explicitly open | Still blocks acquisition | No assistant may synthesize a decision or PASS. |
| Historical branch absent | Often requires lifecycle repair or a new claim | Falls back to authenticated main and records the source gap | Never overwrite an advertised or racing branch. |
| Historical source not based on current main | Lifecycle-specific recovery | V2 records the ancestry result and preserves the exact source commit | No merge, reset, or forced synchronization is implied by acquisition. |
| Missing LFS bytes | May be hidden by a pointer-only checkout | Acquisition blocks and retains the checkout | No fallback may conceal failed source hydration. |
| Unknown ignored or unique local bytes | Existing lifecycle preservation gates | V2 inventories identity and retains the checkout | No ignored file is discarded based on its directory name. |

## Production consumer migration map (prepared; not activated)

| Consumer | Current responsibility | Required cutover treatment |
|---|---|---|
| `custodian/tools/agent/dispatch.py` | Queue, eligibility, dependencies/locks, assignment claim | Replace invocation authority only after reviewed compatibility mapping; do not let its old eligibility result gate V2 task identity. Preserve any non-scheduling validation/acceptance contract explicitly. |
| `custodian/tools/agent/workstream.py` | Persistent checkout start/resume, checkpoint, finish/land, teardown | Migrate start/resume/checkpoint/retirement call sites as one reviewed unit. Keep feature landing, acceptance, review receipts, and rollback gates separate from V2 checkpoint publication. |
| `custodian/tools/agent/paired_review_runner.py` and host-validation helpers | Fresh reviewer context, target pinning, review receipt, recovery | Update reviewer checkout acquisition and return receipts only after review-specific invariants have an explicit V2 mapping. Never let implementation-session context satisfy fresh-review requirements. |
| Root `AGENTS.md` and `custodian/AGENTS.md` | Mandatory assignment, worktree, dispatch, and finish instructions | Update both atomically at cutover. Until then they continue to name legacy tools as authority. |
| `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md` and `CURRENT_STATE.md` | Operational lifecycle and live-state descriptions | Rewrite command recipes/state at cutover; keep rollback instructions until post-cutover validation. |
| `custodian/docs/ai_context/task_packets/README.md`, task packet template, `task_packet_index.py`, `task_packet_contract.py` | Packet authoring and derived queue views/validation | Separate immutable task identity and acceptance metadata from legacy dispatch readiness. Do not change managed indexes or packet contracts during this Stage 3A candidate. |
| `.github/workflows/packet-authoring-handoff.yml` and other automation | Packet authoring and CI validation | Inventory workflow consumers; authoring may publish packet definitions but must not itself claim or execute V2 work. |
| launch shortcuts, skills, service/timer definitions, shell wrappers | Human/agent launch surface | Search and inventory every launcher before cutover; update or retire atomically. Stage 3A adds no service/timer and does not install a sync loop. |

This is a cutover map, not permission to change any listed production entrypoint. Candidate-only CLI and fixture tests may evolve while the old system remains the documented authority.

## Stage 3A evidence boundary

Stage 3A may prove published-packet selection and fresh-process resume using an isolated synthetic remote seeded with authenticated packet bytes from current `origin/main`. It may prove owner-authorized acquisition using explicit conversation/digest provenance in a private receipt. Historical tests use synthetic pinned branch/archive fixtures only. Do not target a real feature branch, alter the private archive, run the legacy dispatcher to claim work, or activate a service. The unresolved host archive inventory and external evidence coverage remain explicit blockers to archive-backed retirement.

The completed normal-mode pilot copied `AGENT_ORPHAN_RECOVERY_FENCED_PARKING_V1.md` from fetched `origin/main@52e09813cd0993fe0c8c03065938e21115f782f3` (packet SHA-256 `640f2e5aae49d301e0b91a46ef88defb05d9089ad8d4b51353bfcd316c282d18`) into a disposable bare remote. This packet has legacy dependency and lock metadata; V2 selected it without reading dispatcher claim state. Synthetic main was `fde811594a3a7cf1e0c14c2d9820fa37d66d887f`. The bounded checkpoint advertised `5f601c6f419e54362b70a33dd370972c8168e9e2`; exact retirement retry returned idempotent success, and a second fresh CLI process rehydrated that SHA. The synthetic remote was removed with its temporary directory; no real feature branch was modified.
