# OPERATOR WORKBENCH ISOLATED ART WORKTREE

- Workstream: `operator-workbench-isolated-art-worktree`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Goal: Run the interactive Operator Workbench from a persistent dedicated art worktree so active Aseprite/Workbench authoring never dirties the coordination `main` checkout, while keeping the existing reviewed publish flow as a single user action that publishes, validates, commits, and lands the approved animation to `origin/main`.
- Current measured state:
  - Root `.gitignore` already ignores `.ai/`, including `.ai/operator_animation_workbench/`; ignored scratch is not the source of the Codex collision.
  - `animation_workbench_model.py` derives `REPO_ROOT` from its own script location, so launching the same Operator code from another attached Git worktree naturally redirects canonical source, runtime, generated resources, and ignored Workbench state into that checkout.
  - `tools/custodian_aliases.sh::opui()` currently launches `operator_cli.py` from the persistent project-root checkout.
  - `animation_workbench.publish()` intentionally writes canonical Operator source, rebuilds runtime/generated resources, validates, and leaves tracked Git changes in the checkout that owns the Workbench process.
  - Codex implementation work already uses isolated ephemeral worktrees through `workstream.py`; the persistent project-root checkout is intended for coordination and safe main synchronization.
  - `land_main.py` already owns safe clean-branch landing to `origin/main`, including fetch/rebase-or-fast-forward behavior, local landing serialization, no force-push, and remote-race handling.
  - OPUI already exposes one reviewed `P Publish` flow: preview/review dialog followed by one confirm action. Preserve that mental model.
- Task-specific authority:
  - `tools/custodian_aliases.sh` owns the user-facing `opui` launcher.
  - Operator Workbench/backend code owns edit/export/publish semantics.
  - `custodian/tools/agent/land_main.py` remains the Git landing authority. Do not duplicate its rebase/push logic.
- Change:
  - Add one focused local-worktree helper/authority for ensuring, identifying, and reporting the persistent Operator art checkout.
  - Default dedicated checkout:
    - branch: `workbench/operator-art`
    - path: sibling of the coordination repo, named `<repo-name>-operator-art` (for the current checkout this is `~/Projects/CUSTODIAN-operator-art`).
  - Change `opui` so normal invocation ensures/reuses that dedicated worktree and executes that worktree's `custodian/tools/operator/operator_cli.py ui ...` while continuing to reuse the coordination checkout's ignored Operator UI venv.
  - Preserve `.ai/operator_animation_workbench/` as ignored disposable/local Workbench state inside the art worktree. Do not move it to a tracked location.
  - Add a clear checkout identity projection in OPUI status: dedicated art checkout vs coordination/other checkout, current branch, and last-known `origin/main` relation. This is informational; the user should not have to manage branches manually.
  - Treat tracked publish from the persistent coordination `main` checkout as unsafe. Normal OPUI launch should never land there. If OPUI is explicitly started from coordination `main`, editing/preview may remain available but tracked publish must fail closed with a concise message directing use of the isolated art checkout.
  - Keep the existing publish review dialog. Rename/word the confirm action so its meaning is clear: `Publish to Main`.
  - After the user approves that one button, perform the complete durable flow automatically:
    1. fetch current `origin/main`;
    2. verify the dedicated art worktree has no pre-existing tracked changes before starting a new publication transaction;
    3. compare the selected Workbench's canonical source/publish-owned paths against `origin/main` changes since the art checkout diverged;
    4. if `origin/main` changed any selected canonical source or target path, stop before writing tracked files and report a source conflict; never overwrite remote art by guesswork;
    5. if upstream changes are unrelated to the selected animation, continue without forcing the running UI to merge/reload its own code;
    6. call the existing Workbench publish authority exactly once, preserving its stale-source, transaction, rollback, runtime build, compatibility generation, import, catalog, and mandatory validation behavior;
    7. after successful Workbench publish, derive the Git change set from the previously clean art worktree and verify every changed/untracked non-ignored path belongs to the Operator publication allowlist; never blindly stage arbitrary repository dirt;
    8. stage only the verified publication paths and create one local commit with a deterministic short Operator-art summary derived from semantic identity;
    9. invoke the existing `land_main.py` authority from the art worktree to land the clean committed branch to `origin/main`;
    10. verify the landed commit is reachable from fresh `origin/main`;
    11. leave the persistent art worktree clean and usable for the next edit;
    12. best-effort fast-forward the persistent coordination `main` checkout only when it is clean; if it is dirty for unrelated reasons, preserve it and report sync pending without treating the already-landed art publication as failed;
    13. refresh OPUI browser/session state after success so the reviewed animation remains selected against the newly published canonical source.
  - The normal user workflow must therefore remain:
    ```text
    edit in Aseprite / review in OPUI
              ↓
          P Publish
              ↓
        review dialog
              ↓
      Publish to Main
              ↓
    automatic publish + validate + commit + land + refresh
    ```
  - There must be no normal second `Commit`, `Push`, `Land`, or terminal step.
  - Failed Git landing after a successful local publication/commit must preserve the committed art branch and surface a resumable `LAND PENDING` state. Pressing Publish again while that clean pending commit exists should retry landing rather than re-export/rewrite the animation.
  - Do not automatically reset, stash, discard, or rewrite pre-existing tracked user work in either checkout.
  - First-run handling:
    - create the dedicated worktree automatically when absent;
    - if a legacy ignored Workbench tree exists only under the coordination checkout and the dedicated art worktree has no Workbench state, support a safe one-time migration of ignored Workbench data;
    - migration must preserve Aseprite bytes and semantic Workbench state, rewrite checkout-root absolute manifest paths as needed, and refuse while an affected live Aseprite document is open/modified;
    - do not silently migrate tracked dirty canonical files from the coordination checkout. Preserve and report them for explicit recovery.
  - Keep direct Codex/task execution unchanged: `workstream.py` continues creating ephemeral task worktrees and direct scripts executed inside those worktrees continue deriving their own repo root from script location.
- Preserve:
  - Existing Workbench source/runtime authority and transaction/rollback behavior.
  - Existing stale-source protection and scary-force override semantics.
  - Existing mirror-counterpart review option.
  - Existing mandatory validation performed by Workbench publish.
  - Existing Codex `workstream.py` ephemeral-worktree lifecycle.
  - Existing `land_main.py` no-force-push/concurrency semantics.
  - Existing ignored UI venv in the coordination checkout may be reused by the art worktree launcher.
  - Existing one-review-dialog publish UX.
- Non-goals:
  - Do not change Operator animation art, frame counts, timing, runtime combat behavior, or asset naming.
  - Do not redesign the generic Asset Pipeline V2.
  - Do not replace `land_main.py` or copy its Git landing algorithm into Operator code.
  - Do not teach Codex to implement from the persistent art worktree.
  - Do not make the coordination checkout a second authoring authority.
  - Do not add an ordinary multi-step Git workflow to the OPUI.
  - Do not auto-stash/reset user changes.
  - Do not require a remote persistent `workbench/operator-art` branch as a user-facing concept; the local persistent branch is implementation detail unless recovery requires surfacing it.
- Acceptance:
  - `opui` launched from the normal shell opens code rooted in the dedicated persistent art worktree, not the coordination checkout.
  - Editing/saving `workbench.aseprite` changes no tracked Git files and keeps coordination `main` clean.
  - Publishing an animation dirties only the dedicated art worktree during the transaction.
  - One confirmation button after the existing review performs Workbench publish, mandatory validation, verified staging, commit, safe landing to `origin/main`, and UI refresh.
  - No normal user terminal/Git step is required.
  - A clean coordination checkout remains clean throughout art authoring and publication except for its optional final fast-forward of `main`.
  - A Codex `workstream.py start`/dispatch path can create and use its ephemeral worktree while the art Workbench has ignored unsaved edits open.
  - A Codex workstream can land while the art Workbench has ignored unsaved edits; it must not need the art checkout to be clean.
  - If `origin/main` changes unrelated files after the art checkout diverges, Publish to Main still succeeds through the existing landing authority.
  - If `origin/main` changes a selected Workbench canonical source/target path, Publish to Main refuses before tracked source replacement and preserves the user's ignored Workbench edit.
  - A failed remote landing preserves a clean committed art branch and OPUI reports `LAND PENDING`; retrying Publish retries landing without regenerating/replacing pixels.
  - Starting OPUI directly from coordination `main` cannot perform tracked publish.
  - Existing Workbench publish rollback tests remain green.
  - Existing Codex/workstream tests remain green.
- Task overrides: `none`
- Deferred:
  - Repository-wide atomic filesystem publication for arbitrary non-Workbench readers remains separate from checkout isolation.
  - Cross-machine synchronization of ignored live Workbench/Aseprite state is not part of this slice.

## Ownership And Timing

- Owner: Operator tooling
- Agent/session: Codex
- Created: 2026-09-28
- Last updated: 2026-09-28

## Work Surface

- Expected primary changes:
  - `tools/custodian_aliases.sh`
  - new focused Operator art-worktree helper under `custodian/tools/operator/`
  - `custodian/tools/operator/ui/service.py`
  - `custodian/tools/operator/ui/app.py`
  - publish/status dialog/widget text only as needed
  - focused Operator Workbench validation
  - active Operator Workbench docs/current-state notes
- Related consumers/tests:
  - `custodian/tools/operator/animation_workbench.py`
  - `custodian/tools/operator/animation_workbench_model.py`
  - `custodian/tools/agent/land_main.py`
  - `custodian/tools/agent/workstream.py`
  - `custodian/tools/validation/operator_workbench_ui_smoke.py`
  - existing Workbench publish smokes

## Plan

1. Add the dedicated-art-worktree authority and launcher routing without changing Codex worktree ownership.
2. Add publish preflight/checkout identity and upstream selected-source conflict detection.
3. Compose the existing Workbench publish with verified Git commit + existing `land_main.py` into the current single-confirmation UI path.
4. Add resumable landing behavior and first-run ignored-workspace migration.
5. Add focused isolation/publish regressions, then run changed validation and update current docs.

## Focused Validation

Run focused tests first. Add fixture-isolated coverage that does not mutate the developer's real worktrees/remotes.

Required behaviors to prove:

- dedicated art worktree creation/reuse;
- normal `opui` launcher resolves the art checkout's Operator CLI;
- `.ai` workbench edits do not affect Git status;
- tracked publish mutations occur only in the art checkout;
- coordination `main` stays clean;
- source overlap with a fetched newer main blocks before canonical mutation;
- unrelated upstream changes are allowed;
- verified staging rejects an unexpected changed path;
- successful one-button flow commits and invokes the landing authority once;
- failed landing produces resumable `LAND PENDING` without republishing;
- coordination-main direct publish is refused;
- Codex ephemeral worktree creation remains independent of dirty/edited ignored art state;
- legacy ignored Workbench migration preserves bytes/state and does not migrate tracked dirty canonical files.

Then run:

```bash
python3 custodian/tools/validation/operator_workbench_ui_smoke.py
python3 custodian/tools/validation/operator_animation_workbench_smoke.py
python3 custodian/tools/validation/operator_workbench_mirror_publish_smoke.py
python3 custodian/tools/validation/run_validation.py --changed --json
```

Use an additional focused launcher/worktree smoke if that keeps these assertions out of an already-large UI smoke; update validation ownership only if a new test owner is introduced.

## Documentation

Update only current-truth surfaces affected by the contract:

- `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md` only if a new durable helper/test becomes an authority future agents need to discover.

Document that:

- ignored Workbench state lives in the dedicated Operator art checkout;
- OPUI normal launch isolates tracked publication from coordination `main`;
- the reviewed Publish button is end-to-end publish-to-main, not merely a local file write;
- upstream same-asset conflicts fail closed;
- failed landing is resumable and never destroys edited art.

Do not rewrite historical packets.

## Handoff

- Next action: implement from a normal Codex ephemeral worktree and validate entirely with fixture repositories/worktrees before exercising the real launcher.
- Best starting files: `tools/custodian_aliases.sh`, `custodian/tools/operator/animation_workbench.py`, `custodian/tools/operator/ui/service.py`, `custodian/tools/operator/ui/app.py`, `custodian/tools/agent/land_main.py`.
- Blockers or open questions: none. Preserve the user's one-button publishing requirement as a hard UX acceptance criterion.
