# Agent Dispatch Claim Receipt Hardening Summary

## Delivered

- **Structured claim receipt.** A successful `dispatch.py claim`/`claim-next`
  now builds one `custodian.dispatch.claim.v1` result object (schema, result,
  workstream, prior_status, branch, worktree, packet, checkout, verified,
  agent) and prints it as a single stable
  `CUSTODIAN_DISPATCH_RESULT_JSON:{...}` line after the human `CLAIMED` banner.
  Both derive from the same object, so they cannot drift apart.
- **Durable local recovery.** The same receipt is persisted at
  `<git-common-dir>/custodian-dispatch/last-claim.json` (outside the worktree,
  so it is never committed) via an atomic write-then-replace. New
  `dispatch.py last-claim` / `last-claim --json` read it back, refresh
  remote-tracking refs to judge whether it still looks `current` or `stale`
  (worktree gone, branch changed, remote branch removed), and print the exact
  `cd <worktree>` continuation — without ever re-claiming, recreating, or
  mutating anything. No receipt yet returns a clear nonzero "no-receipt"
  result rather than inventing state.
- **Post-start identity verification.** Before anything is printed/persisted
  as `CLAIMED`, the dispatcher now verifies, in order: the returned worktree
  path exists; its checked-out branch is exactly `agent/<selected.workstream>`;
  the remote `origin/agent/<id>` is published; and the dispatcher's own
  claimed-state logic (`_claimed()`) now recognizes that workstream. Any
  failure raises `dispatch: BLOCKED` with the specific mismatch and leaves the
  recovery claim ref (`refs/heads/dispatch-claims/<id>`) intact for inspection
  — nothing is auto-deleted or reset.
- **Created/resumed disposition without breaking `workstream.py`'s contract.**
  `workstream.start()` gained one additive, keyword-only `report: dict | None
  = None` parameter; when supplied, `start()` sets `report["checkout"]` to
  `"created"` or `"resumed"` on the same code path it already uses to decide
  between those two cases, and its return type and every other caller
  (`workstream.py`'s own CLI, `test_workstream.py`) are unchanged.
  `dispatch.py`'s new `_start_workstream()` helper probes
  `inspect.signature(module.start)` for a `report` parameter before passing
  one, so the many existing tests that mock `_load_workstream` with a plain
  `(work_id, repo)` callable keep working unmodified — no test double had to
  change its call signature.
- **Already-claimed diagnostics.** An explicit `claim <id>` on a workstream
  already present in `_claimed()` now raises `ALREADY CLAIMED` with the
  canonical `agent/<id>` branch and, when a local worktree is attached to that
  branch, its path (`not attached locally` otherwise). This is diagnostic
  only; `claim-next`'s exclude-and-continue behavior for already-claimed tasks
  is untouched.
- **Agent handshake rule.** Added to
  `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`: the receipt is
  the assignment authority, never infer ownership from worktree/branch/terminal
  activity, and how to recover with `last-claim` when stdout was lost — plus
  the optional verification commands, explicitly not required when the
  dispatcher already reports `verified: true`.
- Updated `custodian/docs/ai_context/FILE_INDEX.md` and
  `custodian/docs/ai_context/task_packets/README.md`'s Dispatch section to
  describe the new receipt/`last-claim` surface; left
  `AGENT_AUTOMATION_BACKLOG.md` and `VALIDATION_RECIPES.md` untouched since
  neither makes a now-false claim or is a natural home for a recovery CLI.

## Validation

- `python3 custodian/tools/agent/test_dispatch.py`: **38 passed** (29
  pre-existing + 9 new). New tests cover: the reported incident fixture
  (claim-next selects the READY task despite an unrelated already-claimed
  workstream's attached worktree, and the receipt names only the selected
  task); claim-next not blocking on a higher-priority already-claimed task;
  full V1 schema field presence and human/JSON identity agreement; `created`
  disposition (real `workstream.start`); `resumed` disposition for a clean
  local-only attached worktree (real `workstream.start`); `last-claim`
  recovering a current receipt, reporting no-receipt, and reporting `stale`
  after the worktree/branch are torn down — while leaving refs untouched;
  the already-claimed explicit diagnostic; and a mocked `workstream.start`
  returning the wrong branch, which fails closed with no branch published, the
  recovery claim ref preserved, and no receipt written.
- `python3 -m unittest custodian.tools.agent.test_workstream`: **9 passed** (8
  pre-existing + 1 new, proving `report["checkout"]` is `"created"` then
  `"resumed"` across two `start()` calls for the same ID).
- `python3 custodian/tools/validation/agent_workflow_smoke.py`: **passed**
  (includes its own internal re-run of `test_dispatch.py`, also green).
- `git diff --check`: clean.
- `python3 -m py_compile custodian/tools/agent/dispatch.py
  custodian/tools/agent/workstream.py`: clean.
- Closeout: `run_validation.py --changed --base origin/main --json` — all
  selected tests passed (agent workflow contract plus this task's own new
  additions; no Godot runtime sweep required for this workflow-only
  correction, consistent with `custodian/AGENTS.md`).

## Awkward Parts And Deferred Work

- The existing shared test fixture `publish_workstream` (and one inline
  `fake_start` closure) previously faked a `start()` return by creating a
  branch and pushing it, then returning a path that was never actually
  created as a directory or git worktree. The new post-start "worktree
  exists" / "branch matches" checks correctly exposed that as unrealistic:
  seven pre-existing tests failed until both fixtures were changed to do a
  real `git worktree add`. This was a deliberate, minimal fixture fix (not a
  scope change) — the old fakes were already a gap the new verification is
  specifically meant to catch.
- `receipt["checkout"]` is `null` for the handful of pre-existing tests that
  still mock `_load_workstream` with a plain 2-arg callable (e.g. the schema
  test uses `publish_workstream` via a bare `mock.Mock()`, whose `.start` has
  the generic `(*args, **kwargs)` signature, so `inspect.signature` correctly
  does not detect a `report` parameter there and no disposition is reported).
  This is expected and intentional: those tests exist to check other
  properties (selection order, cleanup-failure handling, coordination-checkout
  delegation, and so on), not disposition; the two dedicated disposition tests
  use the real `workstream.start` and correctly get `"created"`/`"resumed"`.
- `AGENT_TASK_PACKET_TEMPLATE.md`/older archived `AGENT_TASK_DISPATCH*.md`
  packets were left untouched as historical evidence, per the packet's own
  instruction not to rewrite archived dispatcher packets.
- Everything the packet explicitly deferred remains deferred: cross-host
  liveness beyond existing Git refs, a historical claim log beyond the single
  latest local receipt, continuous workers, and any UI/dashboard.
