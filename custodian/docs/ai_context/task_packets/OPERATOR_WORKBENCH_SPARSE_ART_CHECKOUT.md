# OPERATOR WORKBENCH SPARSE ART CHECKOUT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-sparse-art-checkout`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-operator-workbench-sparse-art-checkout`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `ef9bd0f`
- Goal: Keep the persistent Operator Workbench checkout physically and operationally focused on Operator authoring so normal main synchronization does not churn hundreds of unrelated assets/code files or present unrelated repository content as Workbench-versioning surface, while preserving the existing one-button publish/validate/commit/land contract.
- Completion boundary: Harden only the persistent `workbench/operator-art` checkout lifecycle. Make it a per-worktree sparse checkout with an explicit tested Operator-authoring dependency profile, automatically fast-forward it to fresh `origin/main` when doing so is provably safe, and preserve the existing scoped publication allowlist and ignored `.ai` authoring state. Do not change ordinary Codex workstreams or the repository's global tracked tree.
- Current measured state: Root `.gitignore` already ignores `.ai/`, including `.ai/operator_animation_workbench/`; the archived isolated-art-worktree packet correctly states ignored scratch is not the source of this problem. `operator_art_worktree.ensure_art_worktree()` currently creates a normal full-tree Git worktree with `git worktree add`, fetches `origin/main`, but applies no sparse-checkout profile and does not fast-forward an idle clean `workbench/operator-art` branch to current main. Therefore the persistent checkout physically contains the whole repository and can remain far behind main between publishes. `publish_to_main()` is already safe about commits: it requires a clean art checkout, derives a per-animation publication allowlist, rejects unexpected changed paths, stages only verified Operator outputs, and delegates landing to `land_main.py`. The problem is checkout/UI/sync surface area, not missing commit allowlisting.
- Evidence: `custodian/tools/operator/operator_art_worktree.py` has no `sparse-checkout` setup and uses whole-worktree `git status --porcelain=v1 --untracked-files=all`; `ensure_art_worktree()` only fetches main before returning an existing art checkout; `publish_to_main()` already verifies `changed - allowlist == ∅` and stages only that set; root `.gitignore` already excludes `.ai/`; `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md` and archived `OPERATOR_WORKBENCH_ISOLATED_ART_WORKTREE.md` define the dedicated checkout and one-button landing contract.
- Task-specific authority: `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`; `custodian/tools/operator/operator_art_worktree.py`; `custodian/tools/validation/operator_art_worktree_smoke.py`; `custodian/tools/operator/animation_workbench.py`; `custodian/tools/agent/land_main.py`; current root/local AGENTS checkout-safety rules.
- Work surface: `custodian/tools/operator/operator_art_worktree.py` is the primary owner. Expected supporting changes are its fixture smoke, launcher/status projection only if useful, active Workbench/current-state/file-index docs, and one repository-owned sparse-profile declaration/helper if that is cleaner than embedding a long path tuple in Python.
- Change:
  1. Do **not** solve this with a committed branch-specific `.gitignore`. Gitignore only controls untracked-path status; it does not remove tracked files from the checkout or stop unrelated tracked files from being materialized during sync. The persistent art checkout needs Git sparse-checkout, which is worktree-local metadata.
  2. Add one explicit **Operator art sparse profile** applied only to the attached `workbench/operator-art` worktree. Prefer cone-mode directories where practical. The initial profile should include only the paths required to launch OPUI, read/write canonical Operator art, rebuild Operator runtime/generated resources, run mandatory Workbench publish validation, and invoke approved landing. At minimum account for:
     - `custodian/tools/operator/`
     - `custodian/tools/aseprite/`
     - the exact pipeline/validation/agent helpers transitively used by Workbench publish
     - `custodian/game/` or a narrower tested dependency closure sufficient for Godot Operator validation
     - `custodian/content/sprites/operator/`
     - Operator-facing weapon source/runtime content required by source discovery
     - `custodian/content/data/operator/`
     - other content directories proven necessary by current Operator project/validation dependencies
     - `design/02_features/animation/` only if live OPUI reads its plan/config there
     - repository/custodian root files needed by Git/Godot such as `custodian/project.godot`.
     Do not include `reports/`, unrelated level/environment/fauna/enemy art, `custodian/asset_drop/`, historical Python runtime, or broad design trees merely because they exist.
  3. Treat the sparse profile as a tested dependency contract, not a guessed tiny allowlist. Start narrow, run the exact mandatory Workbench publish validation path, and add only proven dependencies until launch, preview, publication rebuild/import, focused smokes, and landing all succeed. The final profile must materially reduce physical file count and unrelated large-asset presence versus a full checkout.
  4. On every normal `opui` ensure/reuse:
     - fetch fresh `origin/main`;
     - verify checkout identity;
     - preserve ignored `.ai/operator_animation_workbench` bytes;
     - if there is no pending landing receipt, no tracked/untracked non-ignored dirt, and the art branch has **zero local commits ahead** of `origin/main`, fast-forward it with an FF-only operation when behind;
     - never auto-rebase/reset/stash;
     - if ahead, diverged, dirty, or LAND PENDING, preserve state and report relation without rewriting it;
     - reapply/verify the sparse profile after safe synchronization.
     This removes routine branch drift without asking the user to manually “sync” a checkout full of unrelated files.
  5. Existing attached full-tree art checkouts must migrate in place when safe. If clean/no-pending, enabling sparse-checkout may remove unrelated tracked files from the filesystem but must not create Git deletions. Preserve ignored Workbench/Aseprite state exactly. If local tracked/untracked non-ignored data would be lost or sparse conversion is unsafe, fail closed with the exact paths and leave the existing checkout untouched.
  6. Preserve the current publication safety model. A sparse checkout does not widen commit authority. `publication_allowlist()`, upstream selected-source conflict checks, unexpected-output rejection, deterministic commit, approved `land_main.py` landing, and LAND PENDING resume semantics remain authoritative.
  7. Separate **checkout cleanliness** from **versioning scope** clearly in code/messages. The UI should never suggest that unrelated tracked repository files are publication candidates merely because they exist in Git history. Publish review/version output should name only selected animation source/runtime/generated paths that the existing allowlist can actually stage. Repository synchronization itself is not an art “version” operation.
  8. Add a small status/debug projection showing sparse profile health, e.g. `DEDICATED ART · sparse operator profile · origin/main current`, without making the user manage sparse Git commands manually.
- Preserve: Canonical Operator PNG authority; `.ai` ignored authoring workspace; source/runtime/catalog generation; local-cache-only scoped LFS hydration; existing stale-source and upstream same-source conflict protection; mirror counterpart semantics; mandatory Godot/import/smoke validation; one-button `Publish to Main`; approved Operator landing path; no force-push; normal agent workstream behavior.
- Non-goals: No repository-wide sparse checkout; no change to coordination `main`; no new remote `workbench/operator-art` workflow; no deletion/untracking of unrelated repository files; no Asset V2 redesign; no art changes; no weakening validation to make sparse mode pass; no blanket Git ignore of tracked assets; no generic IDE/file-sync configuration.
- Acceptance:
  - A newly created persistent art checkout is sparse by default and physically omits clearly unrelated heavy repository areas while `git ls-tree HEAD` still proves those paths remain tracked in branch history.
  - A preexisting clean full art checkout migrates to the sparse profile without staging deletions and without changing ignored Workbench/Aseprite bytes.
  - Normal OPUI launch on a clean idle art branch automatically FF-syncs to current `origin/main` when behind and ahead=0; unrelated upstream files outside the sparse profile do not become physically materialized.
  - Dirty, ahead, diverged, or LAND-PENDING art state is never reset/rebased/stashed by ensure.
  - OPUI launch/browser/preview remain functional from the sparse checkout.
  - Workbench publish can still rebuild runtime/generated Operator outputs, run its existing mandatory validation commands, commit only the existing publication allowlist, and land successfully.
  - Unexpected changed publication output still blocks exactly as before.
  - Ignored `.ai/operator_animation_workbench` remains outside Git status and survives sync/sparse reapply.
  - Scoped Operator LFS hydration remains limited to Operator/weapon Operator art and works under sparse checkout without network-wide hydration.
  - Status/readout makes sparse profile health and main relation understandable without requiring a manual Git step.
  - Focused fixtures prove unrelated tracked files remain absent from the sparse filesystem after upstream sync while selected Operator files update normally.
- Validation: Extend `operator_art_worktree_smoke.py` with fixture-isolated sparse creation, existing-checkout migration, FF-only idle sync, dirty/ahead/pending refusal, unrelated-upstream omission, selected-Operator update, ignored-workspace preservation, and scoped publish/landing cases. Run `operator_workbench_ui_smoke.py`, `operator_animation_workbench_smoke.py`, `operator_workbench_mirror_publish_smoke.py`, and a real sparse-checkout dry-run/mandatory validation pass against the current repository to prove the profile has the dependencies Workbench publish actually needs. Finish with `run_validation.py --changed --json` and `git diff --check`. No Moment Forge or visual inspection is required.
- Task overrides: `none`
- Deferred: Applying the same sparse persistent-checkout pattern to the future general Asset Workbench should happen in its mutation slice after this Operator implementation is proven; do not prematurely create a shared framework in this packet.

## Implementation Notes

The likely correct Git primitive is per-worktree sparse checkout, not a branch
`.gitignore`. Use Git's worktree-local sparse configuration/pattern storage so
the coordination checkout and ordinary agent worktrees remain full.

Do not use `assume-unchanged` or `skip-worktree` as ad hoc user-facing hacks;
let `git sparse-checkout` own those index bits.

If the current mandatory Godot validation genuinely requires a wider code/resource
closure than expected, widen the declared sparse profile transparently and
measure it. Correctness beats an artificially tiny checkout, but unrelated bulk
asset trees should not be restored without a proven dependency.

## Handoff

- Next action: Auto-claim and reproduce the persistent art checkout from a temporary fixture before touching the developer's real `CUSTODIAN-operator-art` worktree.
- Best starting files: `operator_art_worktree.py`, `operator_art_worktree_smoke.py`, `animation_workbench.py::_validation_commands()`, `tools/custodian_aliases.sh::opui`, current Workbench design/current-state notes.
- Blockers or open questions: None. The exact final sparse dependency profile is an implementation measurement task; it must be proven by the existing Workbench publish validation rather than guessed.
