# PERSISTENT CHECKOUT SYNC HARDENING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `persistent-checkout-sync-hardening`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `agent-workflow, operator-workbench-publish`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-persistent-checkout-sync-hardening`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `this changes persistent Git checkout mutation policy across the coordination root and the Operator art checkout; independent review should verify fail-closed behavior, race safety, and absence of destructive recovery shortcuts`
- Reviewed main: `a7fabe3c9bf4de09b1d1e573d9c85247e5c90a32`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Give the user one safe, repeatable way to keep the persistent coordination checkout at `~/Projects/CUSTODIAN/` and the persistent OPUI `workbench/operator-art` checkout synchronized with fresh `origin/main` whenever synchronization is provably non-destructive, while preserving all local work and making blocked/diverged states immediately actionable.
- Completion boundary: Done when one shared persistent-checkout synchronization authority owns inspect/apply policy for both long-lived checkouts; user-facing helpers can safely sync either or both; normal workstream finish reuses that authority for the project root; OPUI launch opportunistically synchronizes the art checkout before authoring when safe; dirty/ahead/diverged/recovery/editor-open states are preserved and reported without reset/stash/rebase/branch switching; focused fixtures prove race and byte-preservation behavior.
- Current measured state:
  - `~/Projects/CUSTODIAN/` is the intended persistent coordination `main` checkout. Root `AGENTS.md` requires post-land `pull --ff-only origin main`, and `workstream.py::_teardown_workstream()` performs a best-effort clean-`main` fast-forward after task teardown. There is no standalone user-facing helper for synchronizing the root outside a successful workstream finish.
  - `operator_art_worktree.best_effort_coordination_sync()` independently reimplements a second root-sync policy after Operator publication, so coordination-main mutation rules currently exist in more than one owner.
  - `tools/custodian_aliases.sh` exports `CUSTODIAN_REPO="$HOME/Projects/CUSTODIAN"` and `opui()` routes through the persistent `workbench/operator-art` checkout, but exposes no general root/art synchronization command.
  - Existing OPUI startup is deliberately read-only after the art checkout exists: `ensure_art_worktree()` does not fetch/synchronize on reuse. Safe art fast-forward exists in `_ensure_sparse_and_current()` and `prepare_publish_checkout()`, but ordinary authoring sessions can therefore begin from an art branch that has fallen behind `origin/main` until Publish preparation is entered.
  - `prepare_publish_checkout()` already proves the correct destructive-safety baseline for the art checkout: it fast-forwards only when the checkout is clean, has no `LAND PENDING` or active recovery transaction, is on `workbench/operator-art`, and has zero local commits ahead. Ahead/diverged/dirty states are preserved.
  - Existing fixture coverage proves root finish synchronization and Operator-art clean FF-only preparation separately, but there is no shared authority or one command that reports both persistent checkouts together.
- Evidence:
  - `AGENTS.md` project-root synchronization rule.
  - `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`.
  - `custodian/tools/agent/workstream.py::_teardown_workstream`.
  - `custodian/tools/operator/operator_art_worktree.py::{_main_counts,_ensure_sparse_and_current,inspect_publish_readiness,prepare_publish_checkout,best_effort_coordination_sync,ensure_art_worktree}`.
  - `custodian/tools/operator/ui/service.py` coordination-sync and publish readiness consumers.
  - `tools/custodian_aliases.sh::{CUSTODIAN_REPO,opui}`.
  - `custodian/tools/agent/test_workstream.py` and `custodian/tools/validation/operator_art_worktree_smoke.py`.
  - archived `OPERATOR_WORKBENCH_SPARSE_ART_CHECKOUT.md` and `OPERATOR_WORKBENCH_PUBLISH_READINESS_RECOVERY.md` for the existing safe-sync/recovery boundaries.
- Task-specific authority: `AGENTS.md` for project-root preservation/FF-only policy; `AGENT_WORKSTREAM_LIFECYCLE.md` for persistent coordination-checkout semantics; `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md` plus `operator_art_worktree.py` for the dedicated art-checkout identity, sparse profile, publication, and recovery contract.
- Work surface: Prefer one new shared persistent-checkout sync module/CLI under `custodian/tools/agent/` as the single policy owner, then narrow integrations in `workstream.py`, `operator_art_worktree.py`, `tools/custodian_aliases.sh`, and OPUI launch/status projection. Add focused temporary-repository/fixture validation and only docs made false by the new startup/sync contract.
- Change:
  1. Introduce one structured persistent-checkout synchronization authority with separate **inspect** and **apply** operations. It must return machine-readable state (checkout identity, branch, clean/dirty, ahead/behind counts, pending/recovery blockers, action taken, and exact blocker paths/reasons) so CLI, workstream finish, and OPUI do not parse each other's prose.
  2. Support a `coordination-main` profile for the user's persistent project root. Resolve the checkout through live Git/worktree metadata and the configured coordination root; do not bake `/home/<user>` into Python. On this host the expected user-facing root remains `~/Projects/CUSTODIAN/`.
  3. Coordination-main apply behavior is strictly: fetch fresh `origin/main`; require branch `main`; require no tracked/untracked non-ignored changes; classify HEAD versus `origin/main`; no-op if current; fast-forward only when behind with zero commits ahead; preserve and block when ahead, diverged, detached, on another branch, or dirty. Report exact changed paths and ahead/behind counts. Never reset, stash, rebase, force, delete, clean, or branch-switch.
  4. Support an `operator-art` profile that reuses the existing `workbench/operator-art` identity and sparse-profile authority rather than creating a second art lifecycle. Before a synchronization mutation require: exact art branch identity, no tracked/untracked non-ignored dirt, no `LAND PENDING`, no unresolved Workbench transaction/recovery state, zero commits ahead of `origin/main`, and no active Aseprite process that could be editing an ignored Workbench document based on the pre-sync baseline. If any gate fails, preserve the checkout and return an actionable blocked state.
  5. A safe Operator-art sync may fetch and FF-only to `origin/main`, then verify/reapply the existing `operator-authoring-v1` sparse profile using the current non-destructive profile rules. It must preserve `.ai/operator_animation_workbench/` bytes exactly. It must not hydrate from the network, run project-wide import, republish art, rewrite saved Workbench manifests/documents, or alter canonical source/runtime files except as ordinary bytes arriving through the proven Git fast-forward.
  6. Make ordinary `opui` launch use the shared helper as a **best-effort safe pre-authoring sync boundary** after the persistent art checkout is identified and before the Textual UI begins normal authoring. This intentionally supersedes the current "existing OPUI launch never synchronizes Git" rule. Safe clean/behind art checkouts should arrive current automatically. If synchronization is blocked, OPUI must still mount in its existing read-only/recovery-capable state and show the exact reason; do not turn dirty/ahead/`LAND PENDING`/Aseprite-open state into an application-start failure.
  7. Before resolving/launching OPUI, also make a best-effort coordination-main sync through the same authority so the shell launcher and persistent root tooling do not remain silently stale when the root is clean and behind. A dirty/ahead/diverged root must be preserved and must not prevent OPUI from opening from a healthy art checkout.
  8. Replace the inline root-sync mutation in `workstream.py::_teardown_workstream()` with the shared coordination-main helper while preserving current semantics: successful task landing still attempts root synchronization; dirty/diverged user state remains untouched and is reported as pending.
  9. Replace/delegate `operator_art_worktree.best_effort_coordination_sync()` to the same shared coordination-main policy. Do not retain two subtly different implementations of "safe root sync."
  10. Expose a small user-facing shell workflow in `tools/custodian_aliases.sh`. Required UX:
      - `csync` safely inspects and applies synchronization for both persistent checkouts, printing a compact per-checkout result;
      - `csync root` targets only the coordination checkout;
      - `csync art` targets only `workbench/operator-art`;
      - `csync status` is read-only for both;
      - `opui-sync` is a convenience alias/wrapper for the art target.
      Add the commands to `clisting`. Keep implementation logic in Python; shell wrappers must not grow a second Git policy.
  11. Serialize apply operations with one advisory lock in the Git common directory so two user/agent sync attempts cannot concurrently mutate persistent checkouts. Fail fast or use a short bounded wait with a clear "sync busy" result. Define lock ordering so it cannot deadlock with the existing Operator-art worktree creation lock; do not hold the art creation lock while acquiring the shared sync lock.
  12. Close inspect/apply races by re-fetching/revalidating immediately before mutation and relying on `--ff-only` as the final ancestry guard. If `origin/main` advances or checkout state changes after inspection, fail/preserve rather than broadening into merge/rebase behavior.
  13. Keep ignored state outside the mutation contract. Root `.ai`, Operator Workbench ignored documents, local virtual environments, and other ignored user state must not be copied, deleted, rewritten, or treated as a reason to make destructive cleanup safe.
  14. Project enough status for humans to understand the result without Git archaeology: `CURRENT`, `SYNCED N`, `BEHIND N · SAFE`, `DIRTY`, `AHEAD N`, `DIVERGED A/B`, `LAND PENDING`, `RECOVERY REQUIRED`, `ASEPRITE OPEN`, `WRONG BRANCH`, or equivalent structured states.
- Preserve:
  - The project-root checkout remains coordination-only; implementation still occurs in isolated workstreams.
  - All user edits, untracked files, ignored files, local commits, pending publication receipts, recovery journals, and active Aseprite documents are fail-closed preservation boundaries.
  - Existing workstream landing/validation, remote claim, branch-hygiene, and teardown authority.
  - Existing Operator sparse-profile, LFS, publication allowlist, source-freshness, `LAND PENDING`, and recovery behavior.
  - OPUI remains launchable for browser/review/recovery when tracked publication is blocked.
  - No Git LFS network fetch as part of persistent-checkout synchronization.
- Non-goals:
  - No background daemon, cron job, shell-prompt auto-pull, filesystem watcher, or always-on network polling.
  - No automatic conflict resolution, local-commit rebasing, branch reset, stash, cherry-pick, force push, or deletion of divergent history.
  - No cleanup of currently dirty root files as part of this task.
  - No generic replacement for normal agent workstream creation/claim/finish.
  - No change to Operator pixels, animation timing, canonical animation identity, source/runtime generation, or gameplay.
  - No broad rewrite of OPUI Publish UX; consume the existing readiness/status surfaces.
- Acceptance:
  - A temporary-repository fixture with a persistent root `main` checkout that is clean and behind fast-forwards exactly to fresh `origin/main`; ignored bytes remain unchanged; a second run is an idempotent CURRENT no-op.
  - Root dirty, wrong-branch, detached, ahead-only, and truly diverged fixtures do not move HEAD, index, worktree bytes, or untracked files. Results name the exact reason and ahead/behind counts where applicable. No stash/reset/rebase/clean/checkout command is executed.
  - `workstream.py finish` still synchronizes a clean persistent root after teardown through the shared helper and still reports pending without mutation for a dirty/diverged root.
  - A clean `workbench/operator-art` fixture that is behind-only, has no pending/recovery state, and has no Aseprite process fast-forwards to `origin/main`; the existing sparse profile is healthy afterward and a manifest of ignored `.ai/operator_animation_workbench` file hashes is byte-identical before/after.
  - Operator-art fixtures for dirty state, local commits ahead, true divergence, `LAND PENDING`, unresolved transaction/recovery journal, wrong branch, and simulated Aseprite-open state prove zero Git mutation and actionable output.
  - Repeated normal `opui` launch against a clean behind-only art checkout invokes the safe sync and reaches CURRENT before the UI process starts. When sync is blocked, the UI still mounts and displays the blocker rather than silently rewriting or refusing all access.
  - `csync`, `csync root`, `csync art`, `csync status`, and `opui-sync` route through the same Python authority; shell wrappers contain no independent ahead/behind or dirty-state logic.
  - Two concurrent apply attempts cannot both enter the mutation-critical section. The losing attempt reports the bounded lock state and preserves both checkouts.
  - A race fixture that advances `origin/main` or changes checkout state after inspection cannot cause a non-fast-forward merge, rebase, reset, or partial cleanup; the apply step revalidates/fails closed.
  - Existing Operator publish-readiness, `LAND PENDING`, sparse-worktree, and Workbench UI fixture suites remain green.
  - Documentation states that OPUI launch now performs a bounded safe sync attempt when the art checkout is clean/idle, replacing the old read-only-startup rule.
- Validation:
  - Add one focused temporary-repository persistent-checkout sync smoke under `custodian/tools/validation/`; before closeout, update this packet with its exact live path. It must cover root current/behind/dirty/ahead/diverged/wrong-branch, art current/behind/dirty/ahead/diverged/pending/recovery/Aseprite-open, ignored-byte preservation, lock contention, and inspect/apply race rejection.
  - Extend `python3 custodian/tools/agent/test_workstream.py` only for the integration assertion that finish delegates root sync without changing preservation semantics.
  - Extend/run `python3 custodian/tools/validation/operator_art_worktree_smoke.py` for OPUI startup-safe sync and blocked-startup preservation.
  - Run the existing focused OPUI service/UI smoke if launch/status projection changes.
  - Run `bash -n tools/custodian_aliases.sh` and a focused shell-wrapper fixture or equivalent command-routing proof for `csync`/ `opui-sync`.
  - Run one `python3 custodian/tools/validation/run_validation.py --changed --json` closeout sweep and `git diff --check`.
  - No renderer captures or visual/model review are required.
- Task overrides: `none`
- Deferred:
  - Automatic recovery of already-diverged local commits remains manual/recovery tooling; this packet prevents avoidable drift and diagnoses existing divergence but never rewrites it.
  - Background periodic synchronization remains out of scope.
  - Generic synchronization for other persistent specialist worktrees is deferred until another real long-lived checkout needs the same profile abstraction.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh instruction: Re-read live `workstream.py`, `operator_art_worktree.py`, `tools/custodian_aliases.sh`, and the completed Operator publish-readiness evidence at claim time. Mechanical helper/path drift may be reconciled in-scope. If current main has changed the destructive-safety contract or OPUI checkout ownership, stop and return the conflict to this chat instead of silently weakening preservation.

## Completion Truth

Required before completion.

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `pending`
- Completion boundary satisfied: `pending`
- Acceptance satisfied: `pending`
- Superseded/legacy production path disposition: `pending`
- Evidence: `pending`

## Execution Feedback

Required before completion.

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `pending`
- Friction severity: `pending`
- What went wrong: `pending`
- Root cause / contributing factors: `pending`
- Prevention / pipeline improvement: `pending`
- Tooling / docs drift discovered: `pending`
- Follow-up: `pending`
- What worked: `pending`

## Handoff

- Next action: Claim `persistent-checkout-sync-hardening`, implement the shared persistent-checkout sync authority plus root/OPUI helpers, validate, land, then run the paired fresh-context review.
- Best starting files: `custodian/tools/agent/workstream.py`, `custodian/tools/operator/operator_art_worktree.py`, `tools/custodian_aliases.sh`, `custodian/tools/validation/operator_art_worktree_smoke.py`.
- Blockers or open questions: None.
