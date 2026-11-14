# Mapper Dependency Chain Audit

- Audit date: 2026-10-21
- Repository: `braydio/CUSTODIAN`
- Audited revision: `origin/main@8ef500152382c3ac15e161be07ae3d08e74718bc`
- Scope: M1–M7 implementation packets, paired post-land reviews, M1/M2 prerequisite reviews, dispatcher claimability and existing branch ownership.
- Method: Read-only inspection of the active design and task packets; `python3 custodian/tools/agent/dispatch.py audit --json`; remote branch and local worktree inventory. No packet metadata or review workstream was changed.

## Finding

The packet-authoring milestone is complete, but the seven implementation packets are not currently executable. All seven are `ready/auto`; the dispatcher classifies all seven as `dependency_lock_blocked`. Their paired reviews are also blocked behind their target implementations. At audit time only one auto packet was claimable across the entire repository, and it was unrelated to this mapper program.

The two root prerequisite reviews are not unclaimed idle branches:

- `review-awakening-collision-mapper-authoring-bridge-v1` is `claimed`. Its remote branch is `origin/agent/review-awakening-collision-mapper-authoring-bridge-v1` at `bb5dedd62fd0edaf09cab811ec0d585b4f76afdf`. The audit finds its attached worktree at `/home/braydenchaffee/Projects/.custodian-worktrees/review-awakening-collision-mapper-authoring-bridge-v1-20261016T095147Z-2896b41abb29`, dirty and 332 commits behind current main. The dispatcher protects it as `protected_dirty_worktree`; it holds `awakening-runtime` and `authored-level` locks.
- `review-carrow-interior-layout-authoring-v1` is `claimed`. Its remote branch is `origin/agent/review-carrow-interior-layout-authoring-v1` at `099c44353dfd258c233016b88cc50ba2dd502ef1`. There is no attached worktree in the audit inventory; the branch is 181 commits behind current main and classified as `landed_unattached_candidate`. The dispatcher still reports the claim and `carrow-yard-route` lock as occupied.

The existing branches and claims are evidence to recover/inspect those reviews, not authority to create replacement reviews or claim them again. In particular, the Awakening dirty worktree must be preserved. The Carrow claim needs lifecycle/dispatch reconciliation because the claim persists while the branch is unattached and behind main. Do not treat either review as complete until a valid independent review receipt is landed and its packet is archived `complete`.

## Dependency chain

| Slice | Implementation | Current dispatcher result | Dependencies | Paired review |
| --- | --- | --- | --- | --- |
| M1 | `mapper-source-write-safety-v1` | `dependency_lock_blocked` | `review-awakening-collision-mapper-authoring-bridge-v1`; `review-carrow-interior-layout-authoring-v1` | `review-mapper-source-write-safety-v1` |
| M2 | `carrow-mapper-transactional-editing-v1` | `dependency_lock_blocked` | `review-carrow-interior-layout-authoring-v1` | `review-carrow-mapper-transactional-editing-v1` |
| M3 | `mapper-canvas-navigation-v1` | `dependency_lock_blocked` | `review-mapper-source-write-safety-v1`; `review-carrow-mapper-transactional-editing-v1` | `review-mapper-canvas-navigation-v1` |
| M4 | `awakening-mapper-proposal-workflow-v1` | `dependency_lock_blocked` | `review-mapper-canvas-navigation-v1` | `review-awakening-mapper-proposal-workflow-v1` |
| M5 | `carrow-mapper-authoring-workspace-v1` | `dependency_lock_blocked` | `review-mapper-canvas-navigation-v1` | `review-carrow-mapper-authoring-workspace-v1` |
| M6 | `sundered-keep-mapper-input-reliability-v1` | `dependency_lock_blocked` | `review-mapper-canvas-navigation-v1` | `review-sundered-keep-mapper-input-reliability-v1` |
| M7 | `mapper-validation-feedback-v1` | `dependency_lock_blocked` | `review-awakening-mapper-proposal-workflow-v1`; `review-carrow-mapper-authoring-workspace-v1`; `review-sundered-keep-mapper-input-reliability-v1` | `review-mapper-validation-feedback-v1` |

Every paired review is `dependency_lock_blocked` because its implementation is not archived complete. This is an execution-order gate, not missing implementation specification. The active design at `design/04_architecture/AUTHORED_MAPPER_EDITOR_RELIABILITY_V1.md` supplies the same M1–M7 DAG.

## Immediate blockers and safe next actions

1. Recover and finish the existing Awakening review in its current claimed workstream. Preserve the dirty attached worktree and follow the review packet's fresh-context, pinned-target, validation, receipt and lifecycle rules.
2. Reconcile the existing Carrow review claim and unattached branch through dispatcher/workstream recovery procedures. Do not issue a duplicate claim or mark it complete by editing packet metadata.
3. Once both prerequisite review packets are landed and archived `complete`, rerun `python3 custodian/tools/agent/dispatch.py audit`. M1 and M2 should then become candidates, subject to all active locks and live dispatcher gates. M2 only requires the Carrow review; M1 requires both reviews.
4. Complete each implementation and its paired review in the design-defined DAG. M3 waits for both M1 and M2 reviews; M4–M6 wait for M3 review; M7 waits for the M4, M5 and M6 reviews.

## Evidence and limits

- `dispatch.py audit --json` reported the exact dependency blockers above and `execution_lock_held: true` for the two root reviews. Both are classified `claimed`, not eligible.
- Remote refs were confirmed with `git ls-remote`; the audit's remote branch inventory supplied attached worktree, dirty, ancestry and recovery classifications.
- Current main was `8ef500152382c3ac15e161be07ae3d08e74718bc`, matching the revision in the task request.
- This was a dependency/ownership audit, not an independent technical review of either mapper implementation. No mapper Godot validation was run, no review outcome is asserted, and no blocker was cleared by this report.
- The dispatcher audit is a point-in-time snapshot; rerun it immediately before any claim or lifecycle action.
