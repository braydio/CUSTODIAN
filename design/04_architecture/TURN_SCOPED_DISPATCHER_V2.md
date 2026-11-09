# Turn-Scoped Dispatcher V2

**Status:** Stage 1 implementation candidate; opt-in only. It does not replace current repository execution guidance.
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0
**Implementation plan:** [TURN_SCOPED_DISPATCHER_V2_IMPLEMENTATION_PLAN.md](TURN_SCOPED_DISPATCHER_V2_IMPLEMENTATION_PLAN.md)

## Operating contract

V2 offers two acquisition modes over a durable task identity:

- **Normal** selects a task with one valid definition on fetched `origin/main`, creates or resumes its non-forcing remote agent branch, and makes a fresh temporary checkout with verified Git LFS content.
- **Historical** uses prior branch and handoff state when it can be verified. If that evidence is absent or cannot be recovered, it records the gap and starts fresh from current `origin/main`. Historical work is reference material; old sessions, statuses, claims, locks, dependency chains, or worktrees cannot veto new execution.

V2 readiness depends on a valid task identity, an available task definition, safe branch/checkout creation, and no explicit unresolved user-owned design decision. Existing task packet status, dispatcher eligibility, execution locks/claims, and dependency chains are not V2 selection gates. Implementable prerequisites become part of the execution scope. Validation, independent review, owner approval, and data-integrity checks remain acceptance controls after or alongside implementation, not scheduling controls.

Each turn follows:

`Acquire → Execute → Checkpoint → Commit and push → Verify remote SHA → Retire exact temporary checkout → Rehydrate on a later turn`

The temporary checkout uses a unique local `turn/<workstream>/...` branch and publishes to the workstream's remote branch with a non-forcing push. A conflicting writer must be preserved and reconciled; the tool never force-pushes. Each checkpoint includes implementation work and a durable handoff at `custodian/docs/ai_context/turn_handoffs/<workstream>.md` with:

- `Original goal:`
- `Implemented:`
- `Remaining:`
- `Validation:`
- `Sources/evidence:`
- `Resume:`

The checkpoint adds a versioned metadata block with task identity, authenticated task-definition path and main SHA, remote branch, and checkpoint base. The receipt identifies the exact published commit SHA. The handoff must also describe outstanding acceptance and next action. A checkpoint does not claim task completion or review acceptance.

## Preservation and failure behavior

Tracked changes and explicitly inventoried non-ignored untracked source are committed with the handoff. Known reproducible caches may be classified for disposal. Unknown ignored data, suspected secrets, nested repositories, missing LFS objects, a failed push, a mismatched advertised SHA, or a changed checkout blocks retirement and emits a machine-readable local recovery receipt. The checkout remains available for recovery. Never use blanket `git add -A`, force-push, recursive pool cleanup, or age-based deletion.

The remote Git commit and retrievable LFS objects are durable implementation state. A remote pointer alone does not prove that the LFS payload is available. Non-Git evidence needed for future work must have an explicit content-addressed, independently verified preservation path before the checkout is retired. The private historical archive is optional reference material; archive completeness and restore evidence must be verified before any implementation relies on it.

## Stage 1 command examples

From a trusted coordination clone with `origin` configured and Git LFS installed when task files use LFS (`git lfs install --local`):

```bash
python3 custodian/tools/agent/turn_dispatcher_v2.py inspect <workstream> --mode normal
python3 custodian/tools/agent/turn_dispatcher_v2.py begin <workstream> --mode normal
python3 custodian/tools/agent/turn_dispatcher_v2.py begin <workstream> --mode historical
python3 custodian/tools/agent/turn_dispatcher_v2.py checkpoint <workstream> \
  --checkout <exact-turn-checkout> --handoff <handoff.md> \
  --message "checkpoint and handoff"
```

The default pool is `~/Projects/.custodian-turns`, separate from historical worktree storage. `inspect` is read-only with respect to branches and checkouts, though it fetches `origin/main` to authenticate the task definition. `begin` and `checkpoint` return JSON. A blocked mutation prints a JSON failure; if an exact checkout exists, it is retained and the receipt records its recovery location.

## Scope and remaining gates

Stage 1 supplies opt-in normal/historical selection, remote task-definition authentication, safe branch initialization, temporary worktree creation, LFS hydration/verification, durable handoff/checkpoint, non-forcing publish, exact remote verification, inspect output, and receipts. It does not change the old dispatcher, remove historical worktrees, edit the private archive, configure a sync service, or change repository-wide default instructions.

Before production use, Stage 2 must validate historical archive manifests and recovery of ignored/untracked/LFS evidence, then automate only individually verified checkout retirement. Stage 3 must publish an intentional old/new behavior-difference matrix (not require eligibility parity), validate integration and failure recovery, update every execution entrypoint, complete fresh-context independent review, verify a rollback route, and only then cut over from the old dispatcher.
