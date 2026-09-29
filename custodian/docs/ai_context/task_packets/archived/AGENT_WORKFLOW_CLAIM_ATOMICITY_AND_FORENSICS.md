# AGENT WORKFLOW CLAIM ATOMICITY AND FORENSICS

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-workflow-claim-atomicity-forensics`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `agent-workflow`
- Kind: `correction`
- Review: `manual`
- Reviewed main: `bfbe96a761e9862f68e5ebd8aa83dfc800232821`
- Goal: Make every CUSTODIAN workstream start exclusive at the lifecycle layer and add operator-facing run forensics, so two terminals cannot begin the same workstream through `workstream.py start` and lifecycle failures can be reconstructed without relying on terminal scrollback.
- Completion boundary: Close the direct-start race below `dispatch.py`, unify claim acquisition so dispatcher and direct lifecycle entrypoints cannot disagree about ownership, separate ordinary claim from explicit recovery/resume, and add automatic control-plane traces for dispatch → workstream → validation handoff → landing/teardown. Diagnostics must stay outside implementation history and `main`; normal agents emit them automatically but do not consume them during ordinary task execution.
- Current measured state:
  - A real `agent-task-dispatch` bootstrap incident exposed `agent/agent-task-dispatch` attached to a dirty local worktree while `origin/agent/agent-task-dispatch` was still absent. The checkout simultaneously appeared to contain repository-wide tracked deletions. This is consistent with a second process observing the worktree during another process's `git worktree add` population window.
  - Historical `workstream.py@3156fb691` started a new workstream as fetch/check → `git worktree add -b agent/<id> ... origin/main` → `git push -u origin agent/<id>`, with no common-dir mutex or remote unique-claim step.
  - Later dispatcher corrections added a unique remote `dispatch-claims/<id>` compare-and-set before `workstream.start()`, so current `dispatch.py claim` / `claim-next` are protected across independent clones.
  - Current `workstream.py start` still has no equivalent mutex/remote claim. It may create/reuse a local checkout before publishing `agent/<id>`, and current lifecycle docs still describe direct `workstream.py start <id>` as valid.
  - `test_workstream.py` has no concurrent same-ID direct-start test. Dispatcher tests do cover dispatcher races, but that does not protect direct callers.
  - Lifecycle evidence is currently split between console output, refs, ephemeral validation JSON, packets and summaries. There is no run-level machine-readable trace covering claim/start/sync/finish/landing decisions.
- Evidence: user-reported bootstrap incident; historical `custodian/tools/agent/workstream.py` at `3156fb69137ffd83076395800818a99fbae75928`; current `workstream.py`, `dispatch.py`, `land_main.py`, `test_workstream.py`, `test_dispatch.py`; `AGENT_TASK_DISPATCH_REVIEW_CORRECTIONS_CLAUDE_SUMMARY.md`; archived `AGENT_TASK_DISPATCH_REVIEW_CORRECTIONS.md`; lifecycle docs.
- Task-specific authority: `custodian/tools/agent/workstream.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/land_main.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/README.md`.
- Work surface: agent control-plane tooling under `custodian/tools/agent/`, focused temporary-repository tests, lifecycle/validation/file-index docs, and branch-hygiene handling for diagnostic refs. Prefer one small shared claim/trace helper rather than duplicating Git ownership logic.
- Change:
  1. Share one unique remote claim primitive between `dispatch.py` and `workstream.py`. Do not maintain separate claim algorithms.
  2. Add a Git-common-directory per-workstream local mutex around direct start/create/recovery inspection and mutation. Same-repository processes must not enter the same workstream creation window concurrently.
  3. For a new direct start, acquire the unique remote claim before mutating local branch/worktree state. The safe order is `local mutex → fetch/recheck → remote unique claim → create worktree/branch → publish agent branch → post-verify → release temporary claim`.
  4. A losing claimant exits without creating, restoring, deleting, or modifying the winner's worktree.
  5. Separate assignment from recovery/resume. Ordinary `workstream.py start <id>` must not silently adopt an already claimed `origin/agent/<id>`. Preserve a bounded explicit recovery/resume path, but make ownership intent explicit rather than inferred from a matching branch name.
  6. A local-only attached worktree with no canonical agent branch is recovery state, not claim authority. Automatic recovery must never reset, restore, stash, clean, or otherwise rewrite its contents.
  7. Preserve current dispatcher receipts as packet-assignment authority. If direct start remains valid for unpacketed/manual bootstrap work, emit a compatible structured receipt so assignment is machine-verifiable.
  8. Add automatic operator-facing tracing through one reusable helper. Local trace data lives under the Git common directory, outside every worktree, with one stable run ID propagated through dispatch/workstream/landing.
  9. Record append-only structured events for tool/schema version; timestamp/duration/process/host; workstream/run ID; packet metadata; mutex acquisition; remote claim acquisition/release; fetched main SHA and relevant refs; worktree records before/after; branch/worktree/HEAD/upstream; create/resume/recovery disposition; clean/dirty summary; checkpoint/finish/artifact-preflight; validation report summary/hash; main-sync/landing attempts and SHAs; conflicts; branch publication/deletion; worktree teardown; and blocked/error exits.
  10. Control-plane subprocess events may retain sanitized argv, return code, duration and bounded output needed to diagnose Git/lifecycle failures. Do not record repository file contents, chat/model transcripts, full process environments, or authentication material. Add redaction tests.
  11. Publish trace snapshots automatically to a dedicated non-main diagnostic ref namespace, for example `refs/heads/agent-diagnostics/<workstream-id>/<run-id>`. The exact namespace may differ, but it must never match `agent/<id>`, never count as a task claim, never be landed/replayed onto main, contain diagnostics only, and survive task-branch teardown until explicit cleanup.
  12. Trace publication is best-effort and non-authoritative. A trace-export failure must not change task success/failure or hide the primary lifecycle error. On caught blockers/errors, attempt one final trace snapshot; a hard process termination may leave only the local common-dir copy.
  13. Provide an operator inspection surface such as `run_trace.py list [--workstream <id>]` and `run_trace.py export <run-id-or-ref> --json`. Ordinary implementation instructions must not require agents to read these traces.
  14. Add the trace run ID/ref to the structured claim receipt and useful blocked/finish output so a later reviewer can retrieve the exact run.
  15. Teach `branch_hygiene.py` and other ref scanners to classify/ignore the diagnostic namespace explicitly. Do not auto-expire unresolved diagnostics in this slice.
  16. Update workflow docs so dispatcher claim is the normal assignment front door for packeted work, direct start cannot bypass exclusivity, and recovery/resume is explicit.
- Preserve: current packet priority/dependency/lock semantics; dispatcher remote-claim behavior; structured claim receipt and `last-claim`; push-first recovery; clean-worktree protection; no reset/stash/force-push policy; artifact finalization; green validation gates; serialized landing; idempotent already-landed closeout; dirty-root preservation; packet/review lifecycle; compact normal agent output.
- Non-goals: No daemon, external service/database, heartbeat/TTL lease, automatic stale-claim deletion, arbitrary model/shell activity recorder, chat logging, repository-content snapshots, gameplay/runtime telemetry, task-priority redesign, or diagnostic files on `main`.
- Acceptance:
  - Two simultaneous direct starts for one ID sharing a Git common directory cannot both create/mutate the checkout; exactly one wins and the loser leaves the winner untouched.
  - Two independent clones direct-starting the same new ID cannot both succeed; exactly one acquires the remote claim and publishes `agent/<id>`.
  - Fault injection after remote claim acquisition but before/during worktree creation leaves visible recovery state; another ordinary start fails closed without touching the partial checkout.
  - A pre-existing `origin/agent/<id>` is not silently adopted by ordinary start; recovery/resume is explicit.
  - Existing dispatcher separate-clone race and receipt tests remain green using the shared claim primitive.
  - Successful claim/start, blocked direct start, failed finish and successful finish each produce an inspectable trace without agent intervention.
  - Diagnostic refs contain diagnostics only and never appear in the `main` landing path or task-claim namespace.
  - Ref scanners do not classify `agent-diagnostics/**` as active task work.
  - Redaction tests prove authentication material and full environment data are absent from exported diagnostics.
  - One trace export reconstructs claim/start/publish/sync/finish/landing stage order, SHAs, outcomes and blocker reason without terminal history.
  - Normal implementation agents are not required to read trace data.
- Validation: Add focused `test_workstream.py` coverage for same-common-dir and separate-clone direct-start races plus interrupted-create recovery. Reuse/extend `test_dispatch.py` for shared-claim and receipt regression. Add focused trace tests for non-main publication, redaction, event ordering, failure persistence and ref isolation. Run existing agent workflow tests (`test_dispatch`, `test_workstream`, `test_workstream_artifacts`, `test_land_main`, `test_branch_hygiene`, review-pairing/agent workflow smoke) before one changed-file closeout. Use temporary bare remotes/worktrees only; tests must not create diagnostic refs in the developer's live repository.
- Task overrides: `none`
- Deferred: Cross-host liveness/heartbeat, TTL leases, automatic stale-claim recovery, centralized telemetry service, automatic diagnostics retention policy, and capture outside repository control-plane tools.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The summary used the packet title's `AND` token rather than the workstream-ID-derived canonical filename; finish reported the expected filename missing before completing.
- Root cause / contributing factors: The packet title and stable workstream slug differ, and the completion review checked the title-derived name instead of the lifecycle's slug-derived contract.
- Prevention / pipeline improvement: Derive the summary filename from the stable workstream ID and verify its exact path before invoking finish.
- Tooling / docs drift discovered: The finish path emitted a fatal-looking missing-file probe while continuing; the final artifact gate did not make this mismatch obvious.
- Follow-up: fixed-in-scope
- What worked: Shared remote claim CAS and common-dir locks serialize new starts; diagnostic traces remain outside task/main refs.

## Incident Model

The failure sequence to make impossible is:

```text
terminal A                          terminal B
----------                          ----------
fetch / sees no branch
git worktree add -b agent/X
  branch/worktree become visible
  checkout still populating       -> sees attached X
                                   -> origin/agent/X absent
                                   -> checkout looks dirty/partial
                                   -> inspects/repairs/adopts it
git push -u origin agent/X
```

The durable exclusive claim must exist before the local checkout becomes a shared observable implementation surface.

## Handoff

- Next action: Claim this P0 correction through the current dispatcher, reproduce the direct-start race in temporary repositories, then harden claim ownership before adding trace publication.
- Best starting files: `workstream.py`, `dispatch.py`, `test_workstream.py`, `test_dispatch.py`, `land_main.py`, `branch_hygiene.py`, `AGENT_WORKSTREAM_LIFECYCLE.md`.
- Blockers or open questions: None. Diagnostics are operator/reviewer evidence and must remain outside `main` and outside normal agent-reading flow.
