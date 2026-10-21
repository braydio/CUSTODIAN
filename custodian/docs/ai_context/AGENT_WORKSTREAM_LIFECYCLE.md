# Agent Workstream Lifecycle

Normal implementation runs use an isolated ephemeral worktree. For queued
packet work, prefer `dispatch.py claim-next --agent <agent-id>` (for example
`--agent claude` or `--agent codex`), or use `dispatch.py claim <id> --agent
<agent-id>` for explicit selection. Omitting `--agent` falls back to the
`CUSTODIAN_AGENT_ID` environment variable, then a neutral `unspecified` —
never a silently assumed agent brand. The dispatcher
reads fetched `origin/main`, checks packet dependencies and locks, then
delegates branch/worktree creation to `workstream.py` under a shared local
assignment mutex and the remote unique-claim protocol. The mutex covers packet
selection, remote temporary-claim CAS, canonical `agent/<id>` publication,
post-start verification, temporary-claim release, and the durable last-claim
receipt. Best-effort diagnostic publication happens only after the mutex is
released. Direct `workstream.py start <id>` uses
that exclusive protocol for manual/unpacketed starts and fails closed if the
branch, claim, or checkout already exists. It never silently adopts existing
state. Truly read-only reviews may stay in
the coordination checkout; paired post-land reviews that commit durable
artifacts use their own workstream worktree. If a worktree cannot be
used, document the reason in the task record. The project-root checkout is not
the default implementation surface.

## Planned crash-safe session recovery (NOT IMPLEMENTED)

Design authority: `custodian/docs/ai_context/AGENT_ORPHAN_RECOVERY_SUPERVISOR_V1.md`.
Two dependency-gated packets (`agent-orphan-recovery-observability-v1`
and `agent-orphan-recovery-fenced-parking-v1`), each with independent review,
propose to distinguish the **execution lease** from the preserved
`agent/<workstream>` Git branch. OR1 will add supervised Codex/review process
identity and a **read-only** orphan inventory; OR2 will add exact-owner
CAS-fenced `PARKED` recovery and optional **user-enabled** host-local
`systemd --user` scanning. A confirmed exited session should release its
execution lock only after its worktree/commits/untracked files and reviewer
outcome are preserved. No existing remote ref/lock is currently governed by
this proposal; the instructions below remain the live supported procedures.

Until both slices pass review: `dispatch.py audit --json` is read-only,
`workstream.py resume` requires a clean worktree, no automatic branch deletion
is permitted, and `paired_review_runner.py post_exit_recovery` remains a
protected manual-resolution state. Do not infer a dead session merely from
elapsed time, or mark a findings-only review passed to release its lock.

### Exact paired-review claim parking pilot

`review_claim_parking.py` and the dispatch integration provide one bounded
parking path for the exact unresolved review named in
`AGENT_PAIRED_REVIEW_EXACT_CLAIM_PARKING_V1.md`. This pilot is not OR1/OR2 and
does not authorize parking another workstream, run, branch, or lock.

Parking appends a `PARKED` record at
`refs/custodian/review-claim-parking/<workstream>`, parented to the pinned
remote `agent/<workstream>` commit. It does not move that agent branch or edit
the protected worktree or run evidence. A later `ACTIVE` record may be appended
once to restore lock occupancy; the transition is one-time and cannot be
parked again. The exact run, claim receipt, continuation evidence manifest,
complete run inventory, remote branch SHA, local-only commit list, attached
worktree state, and authorization scope are verified and bound into the record.

Use `review_claim_parking.py plan --action park` for read-only inspection. A
fresh apply requires the emitted plan digest, a complete local process scan with
no matching owner, and explicit operator attestation for cross-host owner
absence because the historical run has no recorded host/PID identity. A plan
or attestation is not proof of the review's outcome; the review remains
unresolved and cannot satisfy a review dependency.

The dispatcher continues to report the parked review workstream as `claimed`,
so it cannot receive a duplicate claim. It excludes that holder only from lock
conflict calculations, and only while the exact remote branch and append-only
parking record verify. Missing, malformed, stale, changed, or unsupported
parking state retains the original conservative lock. Queue audit exposes
`execution_lock_held`, `parking_state`, and the record SHA separately from
`claimed`. Packet `ready/auto` describes packet readiness; a live lock conflict
is reported as `dependency_lock_blocked` eligibility.

Do not use this pilot to park another claim or to infer cross-host process
absence. Full supervised process identity, generalized leases, automatic
cleanup, and orphan recovery remain outside its authority.

### Bounded legacy execution reset quarantine

`legacy_claim_quarantine.py` records the separate administrative disposition
`legacy_quarantined` for exact stranded claims. This is not `complete`,
`passed`, `released`, `PARKED`, canonical findings, or review acceptance. The
original `dispatch-claims/<id>` and `agent/<id>` refs remain unchanged, the
identity stays claimed to prevent duplicates, and quarantined reviews never
satisfy dependencies.

Before apply, make and verify an external snapshot of the exact refs, selected
worktree contents (including ignored/untracked files and symlinks), workflow
traces, and paired-review evidence. A single-target recovery should use the
versioned workstream scope. It bundles the pinned main and exact target refs,
archives only that worktree and its evidence, and includes only required LFS
objects after verifying their OID and byte size. It estimates storage and
reserves 1 GiB before writing. The verifier safely restores archives into a
temporary directory and checks path, mode, symlink, content, bundle-ref, and
LFS coverage. The historical unscoped V1 mode remains available for existing
manifests; it includes the shared LFS object directory and should not be used
when that broad copy is unnecessary.

For a coordinated reset, use one batch plan
so every permitted record lands in one atomic remote ref update:

```bash
python3 custodian/tools/agent/legacy_claim_quarantine.py snapshot \
  --scope workstream --workstream <exact-id> \
  --destination <empty-external-directory>
python3 custodian/tools/agent/legacy_claim_quarantine.py verify-snapshot \
  <external-directory>/manifest.json
python3 custodian/tools/agent/legacy_claim_quarantine.py plan-batch \
  --target <exact-id>=<claim-run-id> \
  --target <another-exact-id>=<another-run-id> \
  --snapshot-manifest <external-directory>/manifest.json \
  --output <external-directory>/quarantine-plan.json
python3 custodian/tools/agent/legacy_claim_quarantine.py apply-batch \
  <external-directory>/quarantine-plan.json --plan-sha256 <printed-plan-digest>
```

The read-only plan binds remote and local refs, the recorded run/process and
claim-commit identity, exact published worktree when present, full worktree and
evidence inventories, reset generation, and backup checksum. Apply requires the
exact emitted plan digest, rechecks the full plan under the local dispatcher
mutex, and uses one atomic, non-forcing push that reasserts every existing
original ref at its pinned SHA while publishing the quarantine records. If a
matching local draft record already exists, apply reuses its exact commit; a
mismatched local record or a record already present on the remote fails closed.
Local ref changes use compare-and-swap, and an interrupted push can remove only
refs created by that exact attempt. Any changed ref, worktree, backup,
generation, or run identity invalidates the whole batch.

The dispatcher releases execution-lock occupancy only when the same-host
process identity recorded in the claim trace is verifiably absent and every
pinned ref and backup digest still matches. An active or ambiguous process
cannot be quarantined. Missing process identity or cross-host ambiguity records
an unresolved quarantine while retaining the lock. Dispatch audit reports
`legacy_quarantined`, claim identity, and execution-lock occupancy separately.
Ordinary `workstream.py start`, `resume`, and `finish` refuse a quarantined
identity; reactivation is outside this one-way reset. A changed branch or stale
generation invalidates lock release and restores conservative occupancy.

### Paired-review prelaunch host-validation recovery

The paired-review runner supports a bounded continuation for a run stopped in
`host_validation_recovery`, before any reviewer was launched. This is a
same-claim recovery: it never dispatches a second claim and never edits the
original failed report or run metadata. Start from a clean coordination checkout
on `main` or detached exactly at cached `origin/main`, confirm the supervisor
lock is not held, and inspect a read-only plan:

```bash
python3 custodian/tools/agent/paired_review_runner.py <review-workstream> \
  --continue-run <exact-run-id> --recover-host-validation --plan
```

**Unrelated remote packet publication is a synchronization chore, not a review dependency.**
Automated task-packet authoring/promotion can advance `origin/main` while this
review remains pinned to an earlier commit. Do not change the pinned review SHA,
reclaim the workstream, launch a second review, or demand a packet rewrite just
because other task packets landed. Before reporting a stale-main plan as a
recovery blocker, use the existing guarded persistent-checkout synchronizer
from the coordination repository root:

```bash
python3 custodian/tools/agent/persistent_checkout_sync.py status root
python3 custodian/tools/agent/persistent_checkout_sync.py apply root
```

This may fast-forward only an attached, behind-only coordination
`main` with no tracked edits. **Unrelated untracked files, including a stray
local ZIP, are preserved in place and do not block a fast-forward**; an
incoming tracked path that collides with any such local file still blocks
synchronization. The status report continues to show untracked paths and
`clean=false` without equating them to tracked changes. Ahead, diverged,
detached, tracked-dirty, colliding, and foreign checkouts remain protected.
Never substitute reset, stash, force-push or manual worktree cleanup. If
status/apply reports a genuine blocker, preserve the original run and report
its exact reason. After a successful fast-forward,
rerun the **read-only** recovery plan and obtain a fresh `plan_sha256` before
any separately authorized apply. The pinned implementation SHA and protected
claim/worktree must remain unchanged; source/provenance validation still runs.

The plan pins the run, claim receipt, original worktree/branch, reviewed main,
canonical archived implementation identity, lifecycle-proven source span and
complete original evidence manifest. Apply only the exact freshly emitted
`plan_sha256`, with explicit authorization to launch a new independent reviewer:

```bash
python3 custodian/tools/agent/paired_review_runner.py <review-workstream> \
  --continue-run <exact-run-id> --recover-host-validation --apply \
  --plan-sha256 <exact-plan-sha256> --authorize-fresh-reviewer-context
```

Corrected host validation and reviewer evidence are created exclusively under
`continuation-01/`; a validation failure, interruption, changed parent evidence,
or nonpassing reviewer remains preserved and blocks replay. The canonical
implementation receipt SHA remains the archive-introduction commit. When that
commit contains only packet archival/index changes, the host validates the
separately provenance-pinned source-bearing span immediately preceding it.
Neither a green validation report nor an incomplete continuation is a review
PASS. Inspect the child metadata and artifacts before any further recovery.

## Start or resume

Derive one stable lowercase kebab-case ID for a coherent task. Run from the
repository coordination checkout:

```bash
python3 custodian/tools/agent/workstream.py start <workstream-id>
```

Existing task state requires the explicit recovery command after inspection:

```bash
python3 custodian/tools/agent/workstream.py resume <workstream-id>
```

Before closeout, an attached workstream can preview the locally knowable finish
gates without changing Git or lifecycle state:

```bash
python3 custodian/tools/agent/workstream.py preflight <workstream-id> \
  --validation-report <green-validation.json> --json
```

The report checks packet/archive state, literal Completion Truth, authoring-chat
backlinks, managed-index residue, untracked artifacts, review receipts and
provenance, branch drift, and the supplied validation report. It uses cached
refs only: it does not fetch, create a trace, take the workflow lock, synchronize,
or alter files/refs/worktrees. `post_sync.status` is always `unknown`; latest-main
synchronization, any required after-sync validation, and landing are still
proved only by `workstream.py finish`. A ready preview is guidance to attempt
finish, never evidence that the task landed.

`resume` preserves dirty checkouts and only proceeds with a clean attached
checkout or an explicitly selected published `origin/agent/<id>` branch. A
remote claim without that branch is interrupted recovery state; ordinary
start will not clear it. After verifying no live claimant, an operator may
explicitly remove the `dispatch-claims/<id>` ref. Every start/claim/finish
records a local trace under the Git common directory and best-effort publishes
diagnostics under `agent-diagnostics/<id>/<run-id>`. Inspect with
`python3 custodian/tools/agent/run_trace.py list` or
`python3 custodian/tools/agent/run_trace.py export <run-id> --json`.
Diagnostics contain lifecycle metadata only and cannot be landed as task code.
Diagnostic `ls-remote`, fetch, and push operations have a bounded timeout;
failure is recorded locally and cannot invalidate an otherwise successful task
claim.

A checkpointed branch may already contain a main synchronization merge when
`resume` emits `worktree_resumed`: resume synchronizes the clean checkout before
recording its resulting HEAD. That event proves the resumed checkout's state;
it does not retroactively create a `main_sync(changed=true)` event. Any source
review that accepts such an intermediate merge must prove the exact checkpoint
parent, the uniquely matching later resume event on the same run, branch, and
absolute worktree, and a deterministic two-parent merge tree. It must also keep
the first-parent workstream commits as the owned source inventory, so upstream
files imported by synchronization do not become authored task changes. An
untraced merge or an ambiguous checkpoint/resume sequence remains invalid.

### Run-pinned checkout interruption recovery (operator-only)

The one-run helper `custodian/tools/agent/custodian_claim_checkout_recovery_v1.sh` addresses an interrupted checkout for
`agent-paired-review-source-bearing-archive-gate-v1` under
`20261018T073442Z-9f32a80a4938`. It is not generic claim recovery or
a substitute for `workstream.py resume`. The default `--audit` examines
original refs, worktree registration, capacity and potential protected storage
without deleting anything. The explicit `--release` requires an operator
no-live-claimant attestation, 9 GiB free by default, clean coordination
checkout, original local branch SHA `83bdbd1e`, original remote claim
SHA `34a947cf`, and no attached/partial/remote canonical worktree or branch.
Release acquires dispatch and per-workstream locks before repeat verification
and exact-SHA local branch and remote claim deletion. It preserves diagnostics
and all protected reviewer runs. It never starts a new claim or worktree.

Capacity must first be reclaimed from independently inspected, unprotected
storage, never active worktrees or preserved evidence. For a different run,
SHA, or already-published agent branch, use normal recovery procedures, not
this run-bound helper.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad41ae1-c654-83ea-ba9f-2b4dc4dde401

### Local dispatcher contention

The shared `dispatch.lock` is scoped to assignment-critical work and ordinary
claims fail fast if another process sharing the same Git common directory owns
it. A caller that intentionally wants a short bounded wait may pass
`--lock-wait-seconds N` to `dispatch.py claim` or `claim-next`; the default is
zero seconds. Never delete the lock file or terminate its holder to obtain the
mutex. `flock` protects the file's inode, so unlinking it while held can split
serialization across two inodes.

Keep these conditions distinct:

1. **`LOCAL DISPATCH BUSY`** means a local process is in the assignment-critical
   section. Retry after it finishes; this says nothing about packet eligibility.
2. **Packet logical lock conflict** means a selected packet's `Locks:` value
   overlaps a different claimed packet. The selected packet is not eligible.
3. **Remote recovery claim** means `dispatch-claims/<id>` exists without its
   canonical `agent/<id>` branch. Inspect and recover it explicitly; it is not
   evidence that the local mutex is busy.

The dispatcher fetches packet truth from `origin/main`, so a stale local `main`
checkout is not by itself a dispatcher blocker. Dispatch does not pull or
otherwise move the user's local branch.

Queued packet front door:

```bash
python3 custodian/tools/agent/dispatch.py status
python3 custodian/tools/agent/dispatch.py claim-next --agent <agent-id>
python3 custodian/tools/agent/dispatch.py claim <workstream-id> --agent <agent-id>
python3 custodian/tools/agent/dispatch.py claim-next --agent <agent-id> --lock-wait-seconds 5
```

Codex convenience routing is versioned in
`.agents/skills/custodian-next/SKILL.md`. Invoke it directly as
`$custodian-next`, or type `/skills` and choose **CUSTODIAN Next**. Enabled
skills may also surface in the slash picker. The skill continues an already-active
current workstream; otherwise it prefers the durable same-series `Next Handoff`,
stops on refresh/dependency/manual gates, and only then falls back to global
`claim-next`. It is a skill front end over the existing dispatcher, not a
second scheduler.

A successful claim ends with `CLAIMED` and one
`CUSTODIAN_DISPATCH_RESULT_JSON:{...}` line: the receipt is the assignment
authority. For packeted work the receipt also carries the exact recorded
`authoring_chat`, `visual_review` mode, canonical
`/CUSTODIAN/visual_review/<workstream>/` root, and default
`visual_review_retention` so autonomous workers do not have to rediscover the
human-review route. For packeted work the receipt also carries the exact recorded
`authoring_chat`, `visual_review` mode, canonical
`/CUSTODIAN/visual_review/<workstream>/` root, and default
`visual_review_retention` so autonomous workers do not have to rediscover the
human-review route. Never infer ownership from worktree creation, terminal activity,
branch existence, or another task being active. Before entering the checkout,
verify the receipt's workstream/branch/worktree; if stdout was lost, recover
with:

```bash
python3 custodian/tools/agent/dispatch.py last-claim
python3 custodian/tools/agent/dispatch.py last-claim --json
```

`last-claim` is read-only recovery: it reports whether the receipt still looks
current (worktree present, on the expected branch, remote branch still
published) or stale, but never re-claims or recreates anything. Do not require
agents to manually re-run these checks when the dispatcher already reports
`verified: true`; the commands above are recovery/debug proof, not normal
duplicate ceremony. When verification is needed:

```bash
git -C <returned-worktree> branch --show-current
python3 custodian/tools/agent/dispatch.py status
```

Use `python3 custodian/tools/agent/dispatch.py audit` when resolving a queue
discrepancy. The JSON audit is ordered and includes the packet class, the same
eligibility decision used by a named claim, dependency and pairing identity,
remote claims, and local/remote branch ancestry plus attached-worktree dirtiness.
`landed_unattached_candidate` is evidence for review, not a deletion command.
Attached, dirty, unique, or ownership-uncertain work remains protected until
the established lifecycle proves cleanup safe.

The branch must equal `agent/<returned-workstream>`, and status must recognize
that same ID as claimed.

The tool fetches and prunes `origin`, then creates or resumes
`agent/<workstream-id>` in a sibling `.custodian-worktrees/` directory. An
existing remote branch is canonical. It is synchronized with `origin/main` by
fast-forward or a normal merge; published workstream history is never rebased.
If the branch is attached to a dirty worktree, stop and preserve it.

Before creating a workstream, `dispatch.py` atomically acquires the remote
`refs/heads/dispatch-claims/<workstream-id>` ref using a unique claimant commit
and a normal create-only push. Once `agent/<workstream-id>` is confirmed
published, it explicitly deletes the temporary claim. A temporary claim without
the agent branch means acquisition was interrupted: status marks it blocked and
prints the ref to inspect and a normal explicit-delete recovery command. Verify
there is no live claimant before deleting; V1 never expires claims by age. If
both refs exist, the workstream branch is canonical and the temporary claim is
cleanup residue.

Run implementation, validation, asset ingest, generated-file review, packet and
documentation edits, and the required `<TASK>_CLAUDE_SUMMARY.md` inside that
worktree. Commit only scoped task files. The task branch is pushed before
landing, providing a remote recovery ref.

### Run-artifact contract

A worktree is disposable; its unresolved artifacts are not. If a task packet is
used, give it the stable `Workstream` ID. Before finish, the associated packet
must be `complete`, moved to `task_packets/archived/`, and absent from the
packet README's active/recently-complete sections. The root closing summary is
durable and committed. Its `## Process Feedback` receipt records execution
friction/prevention for every normal implementation. For V2 task packets, mirror
the same receipt into `## Execution Feedback` before marking the packet complete
and archiving it. Validation JSON is normally an ephemeral input to finish
unless the task specifically needs it retained. Temporary logs/caches/previews
may be deleted deliberately. Dropbox visual-review evidence is transient by
default: after ChatGPT/user review, run the manifest's emitted cleanup command so
`delete-after-review` purges the exact reviewed run and any matching `LATEST.json`
pointer. Use `retain` only when the user/packet explicitly requires future cloud
review value. Asset Pipeline V2 `source_work/` and `inbox/` material is
never disposable merely because it was created during a run.

`workstream.py finish` runs an artifact preflight before synchronization and
again after synchronizing latest main. Any untracked file blocks teardown and is
classified as task-packet, closing-summary, Asset V2 source, review evidence,
disposable candidate, or unclassified. The agent must explicitly commit durable
material or remove disposable material; ambiguous files are never silently
removed.

## Bounded Successor Continuation

A successful packet finish is a pair boundary, not an unlimited continuation
signal. The default CUSTODIAN Next invocation completes at most one
implementation plus its required fresh-context paired review (including bounded
corrections/re-reviews), then stops. An explicitly requested `continuous-chain`
may continue only with a positive finite pair budget and any user-designated
scope. The pure policy helper is
`custodian/tools/agent/next_execution_boundary.py`; it consumes caller-supplied
facts but does not select packets or claim work. `dispatch.py` remains the claim
authority. Record structured per-workstream receipts in the existing RunTrace.

For each pair:

1. Commit the root `<TASK>_CLAUDE_SUMMARY.md` with the packet's substantive
   completion and `Next Handoff` before finish.
2. Resolve only the exact immediate successor named in `Next Handoff`. For a
   named dependency chain, claim only dispatcher-confirmed eligible predecessors.
   Do not substitute a globally convenient packet.
3. Continue only when the invocation's remaining budget permits and there is no
   planning refresh, human visual/design/canon decision, manual-dispatch hold,
   failed validation, or unresolved safety/ownership blocker. `Refresh owner:
   execution-agent` is autonomous only while it exposes no new human decision.
4. A paired review is part of its implementation pair and always uses a fresh
   context. Once eligible, invoke
   `python3 custodian/tools/agent/paired_review_runner.py <review-workstream-id>`
   from the coordination checkout. The runner preflights Codex, claims the exact
   review through dispatch, and launches `codex exec --ephemeral` in the receipt's
   worktree. The launch also grants writable access to the exact CUSTODIAN
   validation cache roots used by `GodotJobBudget` and the isolated Godot HOME;
   shared Git metadata remains restricted. A failed fetch or incomplete receipt
   is recoverable and does not count as completion. Preserve claimed branches,
   worktrees, and evidence after runner failure.
5. At the accepted review boundary, record the landing SHA, review status,
   elapsed time, validation summary, pair count, and next eligibility. The
   default one-pair mode stops here even if a successor is ready. Explicit
   continuous mode follows only an eligible named successor within scope and
   budget. An explicitly general-next invocation may use one global eligible
   implementation at a boundary; it must not bypass an unresolved review or gate.

Do not jump to an unrelated global queue item just because a named chain ends.
Stop and report the exact planning/human gate or technical blocker. Use the
compact human unblock card below for planning refreshes.

### Human unblock card

When the stop condition is a ChatGPT/user planning refresh, the full execution
summary already lives in the committed `<TASK>_CLAUDE_SUMMARY.md`. Do not make
the user shuttle that whole recap between tools. End with a compact card:

```text
PLANNING REFRESH REQUIRED
Authoring Chat: <exact recorded URL>
Workstream: <workstream-id>
Persistent Summary: <repo-relative *_CLAUDE_SUMMARY.md path>
```

The intended user action is only: open **Authoring Chat**, paste the exact
`Workstream` value, and let that conversation recover the durable packet,
summary, predecessor evidence, and live-main state needed to unblock it.

For a subjective visual gate, use the same compact pattern plus the exact
Dropbox `REVIEW_MANIFEST.json` path and reviewer question. For a non-human
technical blocker, report `BLOCKED` with the exact reason and persistent
summary path; do not mislabel it as a planning refresh.

## Human / ChatGPT Visual Review Pause

A required subjective visual decision is a pause inside the **current**
workstream, not completion and not permission to claim unrelated work.

1. Finish objective validation and publish the smallest Dropbox handoff through
   `publish_review_artifacts.py`, passing the exact packet authoring-chat URL.
2. Return the emitted `REVIEW_MANIFEST.json` path and reviewer questions to that
   authoring conversation. ChatGPT web should use the connected Dropbox source to
   inspect that exact path.
3. Stop implementation at the subjective decision boundary. `$custodian-next`
   must report the human-review blocker while this workstream remains active.
4. When the decision returns, resume the same workstream, record the decision in
   durable task evidence, and execute the emitted reviewed-evidence cleanup
   command unless the manifest says `retain`.
5. Continue validation/finish only after the human decision and cleanup/retention
   result are resolved.

The cleanup path is programmatic and path-confined by
`custodian/tools/iteration/publish_review_artifacts.py --reviewed-manifest ...`.
Do not manually delete broad Dropbox directories.

## Human / ChatGPT Visual Review Pause

A required subjective visual decision is a pause inside the **current**
workstream, not completion and not permission to claim unrelated work.

1. Finish objective validation and publish the smallest Dropbox handoff through
   `publish_review_artifacts.py`, passing the exact packet authoring-chat URL.
2. Return the emitted `REVIEW_MANIFEST.json` path and reviewer questions to that
   authoring conversation. ChatGPT web should use the connected Dropbox source to
   inspect that exact path.
3. Stop implementation at the subjective decision boundary. `$custodian-next`
   must report the human-review blocker while this workstream remains active.
4. When the decision returns, resume the same workstream, record the decision in
   durable task evidence, and execute the emitted reviewed-evidence cleanup
   command unless the manifest says `retain`.
5. Continue validation/finish only after the human decision and cleanup/retention
   result are resolved.

The cleanup path is programmatic and path-confined by
`custodian/tools/iteration/publish_review_artifacts.py --reviewed-manifest ...`.

## Default Execution Economy

These are repository-default execution steps for claimed packet work; do not
copy this list into individual task packets.

1. Read the current packet.
2. If it contains a bounded `## Context Pack`, generate that Repomix pack once
   from the **current claimed worktree** with `scripts/ai/pack-context.sh task`.
   Do not generate a whole-repository pack as routine startup work.
3. Read the immediate predecessor closing summary when the task depends on an
   architecture-shifting predecessor.
4. Use code-review-graph opportunistically. In a linked worktree, use the
   persistent coordination-root graph only for baseline orientation. If the
   first graph call reports missing/not-ready/empty/stale/unmapped coverage,
   immediately use targeted worktree reads; do not cold-build a local graph.
5. Search exact symbols/paths before reading large files. For large files,
   prefer targeted symbol/range retrieval over a default whole-file read.
6. Read direct callers/callees only as needed.
7. Treat the current worktree and its `git diff` as implementation/review truth;
   neither a coordination-root graph nor a Repomix snapshot proves branch-local
   behavior.
8. Do not reread completed packets or broad roadmaps unless a concrete
   contradiction requires it.
9. Reuse landed benchmark/validation evidence instead of rediscovering it.
10. Run the highest-risk focused falsification first, then one normal closeout
    sweep.

A packet's `Status: complete` is not itself proof that its stated Goal/
Completion boundary hold; see `AGENT_TASK_PACKET_TEMPLATE.md`'s `## Completion
Truth` receipt, which `workstream.py finish` enforces for current V2
`implementation`/`correction` packets before teardown.

## Subagent/Fork Safety

Default to a single agent implementing one packet. Use research forks/subagents
only when the work is genuinely independent and parallelism materially reduces
wall time.

- A read-only research fork must not share writable authority over the parent
  implementation worktree. Use tool restrictions or a separate isolated
  checkout/context; if the platform cannot enforce read-only mutation, do the
  targeted research in the parent instead.
- Never allow two implementation-capable forks to concurrently edit the same
  worktree without an explicitly scoped multi-writer task contract.
- If a fork stalls and the parent can obtain the fact with a few targeted
  reads/searches, stop the fork rather than waiting/polling repeatedly.
- Verify fork claims against live code before implementation when the result
  names APIs/paths not already known; a fork's summary describes what it
  intended to do, not necessarily what it verified.

This is instruction/contract hardening, not a requirement to build a general
subagent manager.

## Paired review outcomes and administrative closeout

`paired_review_runner.py` runs the canonical changed-file validation from the
trusted coordinator before starting its restricted fresh reviewer. The base is
the exact parent of the pinned implementation commit, and validation runs in
the claimed review worktree under `run_validation.py`'s normal Godot project
lock and job budget. The run evidence stores the raw report and coordinator
provenance; the reviewer inspects that report and authors an independent
`passed`, `findings`, or `human_required` disposition. The coordinator verifies
the report digest, pinned identities, and implementation source fingerprint
again before closeout. A green report is necessary evidence, never a substitute
for reviewer judgment. If host validation fails or evidence changes, preserve
the claim and worktree for recovery.

A paired review concludes with exactly one outcome: `passed`, `findings` or
`human_required`. The outcome is a flat `## Review Outcome` section in the archived
*review* packet (`custodian/tools/agent/review_outcome.py` is the only parser). It is
bound to the review workstream, reviewed target, pinned reviewed main, immutable
implementation commit, originating run ID, review cycle and stable finding IDs
(`R<cycle>-NN`). A missing, duplicate, malformed or unbound section fails closed.

- **Accepted-review dependencies.** An archived review releases an ordinary
  `Depends on:` successor only when it is a verified `passed` (a `passed` outcome plus
  exactly one canonical passing receipt in the target, or, for reviews archived before
  this section existed, an unambiguous flat pass in the target). `findings`,
  `human_required`, malformed or contradictory outcomes and ambiguous legacy reviews
  never release it. `archived complete` alone does not mean accepted. The dispatcher
  applies this identically in `status`, `audit` and `claim`. Only the explicitly linked
  next bounded correction (`<root>-review-corrections-<N+1>`, with `Findings addressed`
  IDs the review recorded) may consume a concluded `findings` review.
- **Nonpassing closeout.** `paired_review_runner.coordinator_finish_nonpassing_review`
  lands a findings/human_required review without ever touching the reviewed target
  packet: it must stay byte-identical to its pinned baseline and gains no receipt. Only
  the review packet (active and archived), the index and the canonical closing summary
  may change. The validation report is a closeout-**integrity** report; it makes no
  claim about the behavior under review, and the failing-behavior evidence stays in the
  review as findings. `workstream.py finish` applies the matching gate.
- **Same-run recovery of a stranded review.**
  `paired_review_runner.py recover-closeout <review-workstream> --run-id <id>
  --outcome findings|human_required --finding-ids R0-01[,...] --provenance <p>
  --isolated-checkout <path> (--plan | --apply) [--release-claim]`. `--plan` changes
  no worktree, branch, journal or run evidence (it only refreshes remote-tracking refs
  and the review lock file). `--apply` works only in a recovery-branch checkout at the
  exact published tip, never in the original worktree. Every commit the review branch
  made since its merge-base with `origin/main` must stay inside the bounded paths
  (review packet active/archived, index, canonical summary) before anything is written
  and again before anything is published. It journals each stage atomically in the
  original run directory (`closeout-journal.json` and `closeout-integrity.json` are the
  only files added there), converges on retry, never calls `dispatch.py claim`, and
  refuses a dirty coordination checkout. The original claim is read from the structured
  dispatcher receipt; if an older run stored `claim.stdout` truncated mid-JSON, only that
  parse failure falls back to the plain `CLAIMED` header lines, which must match
  `metadata.json` exactly on workstream, branch, worktree and packet and are then
  verified in Git (a receipt that parses but does not verify never falls back). The original claim, branch, worktree and run
  evidence are preserved; the original worktree's modified and untracked files are
  verified by SHA-256 before and after (ignored files, file modes and symlink targets
  are not covered by that inventory). The claim (the remote `agent/<id>` branch) is
  released only with `--release-claim`, either during apply or later on a completed
  recovery, only while the protected original is unchanged, only after every commit on
  it is on `origin/main`, and the delete is conditional on the exact verified SHA. A
  pass is never recovered this way.

### Fresh reviewer continuation of one protected post-exit run

When the original ephemeral reviewer session is gone but the exact claimed
review needs a new independent disposition, use:

```bash
python3 custodian/tools/agent/paired_review_runner.py <review-workstream> \
  --continue-run <exact-original-run-id> --authorize-fresh-reviewer-context
```

Both flags are required. This starts a new fresh reviewer context attached to
the same preserved claim and checkout; it does not restore the old Codex
session, dispatch another claim, or resume a workstream. The command requires a
clean coordinator checkout on `main`, the exact original structured claim
receipt/worktree/branch, the pinned archived target and SHA, and immutable,
green coordinator host-validation evidence. It holds the same nonblocking
per-review runner lock, writes continuation evidence only under a new exclusive
`continuation-01/` child of the original run, and verifies hashes of all
preexisting run files before and after the reviewer. Existing reviewer notes,
summaries and reports are copied byte-for-byte into that child before the
reviewer starts. Findings, human-required outcomes, interruptions, and any
ambiguous closeout leave the claim and branch protected. A PASS alone may enter
the existing exact receipt verification and coordinator finish path.
Repeating a completed run independently verifies the landed receipt and returns
success; an incomplete continuation is never replayed automatically. New
ordinary review claims persist the full structured receipt in
`claim-receipt.json` because the human-readable `claim.stdout` is length-limited.

### Exact continuation after missing archived disposition

One additional recovery is authorized only for
`review-agent-paired-review-checkpoint-resume-merge-provenance-v1-review-corrections-1`,
run `20261020T114129Z-536181b31d70`. It requires the original run to remain in
`post_exit_recovery` and `continuation-01` to record exactly
`missing_archived_disposition` with reviewer `exit_code: 0`. The original run
manifest, structured claim, exact worktree/branch/head, pinned target and green
host-validation evidence must still verify. Use all three exact arguments:

```bash
python3 custodian/tools/agent/paired_review_runner.py \
  review-agent-paired-review-checkpoint-resume-merge-provenance-v1-review-corrections-1 \
  --continue-run 20261020T114129Z-536181b31d70 \
  --recover-missing-archived-disposition --authorize-fresh-reviewer-context
```

This holds the original nonblocking review lock, creates only
`continuation-02`, and records complete SHA-256 manifests for the original run
and all of `continuation-01`. Both evidence sets are rechecked after the fresh
reviewer exits; neither is rewritten. The reviewer stays on the original claim
and worktree. Its prompt names the exact active review packet, canonical
archived review packet, pinned implementation target and receipt location, and
root summary. A PASS in a prior message is not evidence. Only a new canonical
archived packet and run-bound Review Outcome, exactly one valid target receipt,
the exact root summary and coordinator verification can enter the ordinary
race-safe closeout. Findings, human-required outcomes, missing artifacts and
interruption remain preserved. An incomplete continuation-02 cannot launch
again; a completed PASS may retry coordinator verification/closeout without a
second reviewer. No other run or phase is covered by this exception.

## Exit paths

For blocked, paused, or review-pending work, make intentional commits, ensure
the worktree is clean, and run:

```bash
python3 custodian/tools/agent/workstream.py checkpoint <workstream-id>
```

This pushes and verifies the branch while retaining it as active. Optional
`--remove-worktree` removes only its clean checkout; the local and remote branch
remain.

Paired post-land review workstreams are review-only with respect to the target implementation and must start from a **fresh reviewer context**. Do not continue the implementation session/conversation into its paired review. The same model/agent family is allowed only when a new reviewer context/workstream reconstructs the task from durable repository evidence; record provenance as `same-agent-fresh-context`. A different agent/context records `different-agent`. If a fresh context is unavailable, the result is ad hoc self-review and does not satisfy the paired-review contract. The review packet may authorize a bounded repository-artifact commit. When that exact override is present, the reviewer stages only the
archived target's `Independent Review` receipt, the required review closing
summary, the review packet's lifecycle/archive metadata, and bounded correction
plus re-review packets. The reviewer never stages reviewed implementation files
or unrelated work. A clean or non-blocking-only result completes, pushes, and
lands these artifacts through the ordinary checkpoint/finish lifecycle without
a routine user-authorization prompt. Stop for user judgment only when the
receipt is `human_required`. An ad hoc/read-only review without this paired
packet override remains uncommitted and must say so explicitly.

For completed validated work, provide a green focused validation JSON report:

```bash
python3 custodian/tools/agent/workstream.py finish <workstream-id> \
  --validation-report /path/to/validation.json
```

If the implementation packet declared `Review: auto`, its paired independent
review is a separate follow-on workstream that becomes eligible once this one
lands and archives — it is never a condition of `finish` itself. `finish`
closes this worktree normally regardless of review outcome; see
`task_packets/README.md`'s Paired Review And Correction section for the full
post-land review and correction lifecycle.

If finish merges newer main into the published branch, provide a second green
report with `--validation-report-after-sync`. Finish pushes before landing,
uses `land_main.py` internally for serialized/race-safe landing, verifies the
landing by ancestry from freshly fetched `origin/main`, then deletes the remote
branch and tears down the local worktree/branch. `land_main.py` refuses
destructive direct invocation outside this finish handoff; the reviewed
Operator art publisher has a separately scoped explicit argument accepted only
for `workbench/operator-art` to `origin/main`. `--dry-run` remains available
for inspection. Before that proof, every failure retains
the recovery branch and worktree. Root checkout synchronization is attempted
through `custodian/tools/agent/persistent_checkout_sync.py` after landing. The
shared helper fetches fresh `origin/main` and fast-forwards only the attached,
clean `main` checkout when it is strictly behind. Dirty, untracked, ahead,
diverged, detached, and wrong-branch states remain untouched and are reported
as pending without reset, stash, rebase, clean, or branch switching. The same
authority serves `csync`, OPUI startup, and Operator-art coordination sync. Run
`csync status` for read-only inspection, `csync root` or `csync art` for one
checkout, or bare `csync` for both.

### Explicit root-sync deferral for the invalid-disposition recovery

The paired-review invalid-disposition recovery packet authorizes root
synchronization to remain pending for exactly these support workstreams:
`agent-paired-review-invalid-disposition-recovery-v1` and
`review-agent-paired-review-invalid-disposition-recovery-v1`. Use
`workstream.py finish <id> --defer-root-sync`; the lifecycle verifies the
archived implementation packet carries the bounded deferral override before
landing. The persistent root checkout is left byte-for-byte unchanged and the
finish trace records `root_sync_deferred`.

For the one recovered historical review
`review-agent-paired-review-prevalidation-recovery-plan-v1`, the same option
also requires `--defer-root-sync-evidence` pointing to its exact
`20261019T055243Z-1d73c6a01b1e/continuation-01/metadata.json`. The runner first
lands the review with `--defer-teardown`, verifies the independent PASS and
target receipt on fresh `origin/main`, then invokes finish again to release the
existing claim and remove that worktree. No other review run can use this
exception. Root synchronization remains pending after teardown.

### Already-landed closeout

The closing-summary and reachability checks are independent of any diff
against `origin/main`. Once a task's exact HEAD is already an ancestor of
`origin/main` — a prior `finish` landed it but was interrupted before
teardown, or `land_main.py` reported "already up to date" after a lost push
response — `finish` proves the artifact gate, the summary (via `git cat-file
-e HEAD:<summary>`, not a moving diff), and green validation exactly as
normal, then skips `sync_main`/`land_main.py` entirely and goes straight to
verified teardown. It never rewrites or remerges already-landed history. A
task branch with additional commits beyond an already-landed point is not
mistaken for finished; the normal synchronize → land path still applies to
the remainder.

Re-running `finish` after teardown already completed (no attached worktree,
no remote branch) reports a clear already-finished result rather than an
error, provided the closing summary is durably present on `origin/main`;
otherwise it fails closed rather than guessing. It never encourages
recreating a worktree just to clean up.

`workstream.py gc` runs fetch/prune and emits the branch hygiene report.
`branch_hygiene.py` is report-only by default. Its classifications are based on
ancestry and commit counts; unique `agent/*` refs classify as `ACTIVE`, and the
tool never age-deletes. `--apply` deletes branches fully contained by main and
archive-tags unique history before deleting the branch. Protected refs cannot
be deleted. Archive tags use
`archive/<sanitized-branch>-<YYYYMMDD>` and are recorded in
`BRANCH_ARCHIVE.md`.

`workstream.py status` also prints a read-only storage report. Validation scratch
defaults to `~/.cache/custodian/` (override with `CUSTODIAN_SCRATCH_DIR`), and
the isolated Godot home is stored under that root. The report identifies
registered worktrees whose mount is `tmpfs` or `ramfs` and lists protected
reasons such as claimed workstream, dirty state, and unpushed commits. It reports
scratch filesystem usage and never removes worktrees, scratch, or evidence.

For an explicitly operator-approved stale `agent/*` ref, use the repeatable
`--retire-approved BRANCH=SHA` option with the exact reviewed remote head. This
path fetches before acting, rejects a changed head, protected/diagnostic refs,
and dirty or mismatched attached worktrees, then reuses the archive-tag and
ledger machinery. Remote deletion is leased to the approved SHA. Default
reporting and `--apply` remain conservative and never age-delete divergent
agent refs.

Never force-push, reset user work, or stash automatically. Branches are active
work queues; tags retain unique retired history.
