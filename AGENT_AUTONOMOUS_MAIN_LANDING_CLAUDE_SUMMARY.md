# Autonomous Main Landing and Prompt Workflow Summary

## Starting point

- Starting HEAD: `37e8fdc3eee681fd15c923ab3e0c53420624eb81` (`agent workflow, inherit defaults and compress prompts`).
- Implementation ran in isolated worktree `codex/agent-autonomous-main-landing`.
- The shared primary worktree had unrelated Awakening, Operator, procgen, and asset edits. They remain untouched.

## Changes

- Root and custodian `AGENTS.md` now define normal implementation as validate, commit, and automatically land on `origin/main`, with no PR or routine approval gate.
- Substantial parallel work uses isolated worktrees. Task packets describe task deltas, use the smallest coherent completion boundary, and may keep sequential migration steps under one acceptance gate.
- Review-only Git audit has an explicit `TASK OVERRIDE:` and does not stage, commit, push, or mutate repository state.
- Added `custodian/tools/agent/land_main.py`: requires a clean committed task branch; resolves the shared Git common directory; serializes local attempts with `flock`; fetches remote tracking state; rebases onto `origin/main`; pushes without force; retries bounded remote-main advancement; refuses already-published task commits; and aborts/reports rebase conflicts.
- Added `--dry-run` inspection mode. It displays branch, worktree, shared lock, and planned fetch/rebase/push without contacting the remote.
- Added six temporary-repository tests covering dry-run, clean landing, dirty-tree refusal, rebase conflict abort, remote-main race retry, and already-pushed-history refusal.
- Integrated prompt and landing checks as the `agent_workflow_contract` unit validation. Updated `CONTEXT.md`, `CURRENT_STATE.md`, `FILE_INDEX.md`, the prompt README, automation backlog, and packet template.

## Evidence

- `python3 custodian/tools/validation/run_validation.py --test agent_workflow_contract --json` — passed (prompt linter plus six temporary-repository tests).
- `python3 -m json.tool custodian/tools/validation/validation_manifest.json` — passed.
- Python compilation for the landing helper, its tests, and validation wrapper — passed.
- `git diff --check` — passed.
- Prompt template strict scan and self-test — zero duplicated defaults; passed.

## Negative controls and awkward failures

- Dirty worktree is refused before fetch or push.
- A published task commit on an origin tracking branch is refused before rebase.
- A conflicting rebase is aborted and leaves the original task HEAD and clean worktree intact.
- A simulated remote-main push race is fetched, rebased, and retried successfully.
- The first conflict-test attempt used a clone whose bare-remote default HEAD was not reliably initialized; its push was rejected before the helper ran. The fixture was corrected to explicitly fetch and check out `origin/main`; the full validation then passed.
- The external ChatGPT Project instruction files named in the request were not present under the local `Projects` or `Documents` trees, so those copies could not be edited here.

## Landing result

- Commit and push state: reported in the closeout response; this summary is included in the landed commit.
- No force push, PR, or human approval gate used.

## Deferred

- Update the separate ChatGPT Project files (`INSTRUCTIONS-FOR-AUTHORING-CODEX-TASK-PACKETS.txt`, `General-Information-Retrieval.txt`, `INSTRUCTIONS.md`, and `INSTRUCTIONS-FOR-GENERATING-NEW-ASSETS.txt`) in their owning Project workspace; they were not available in this checkout.
