# CUSTODIAN | Bunker R1 | Codex Takeover of Existing Claude Claim

**Document type:** preservation-first workstream handoff, NOT a new task packet or claim.
**Workstream:** `compound-connected-bunker-blockout-review-corrections-1`
**Review:** `review-compound-connected-bunker-blockout-review-corrections-1`
**GitHub-main audit:** `e9976ea93370ba562f162f8d0d6debe71e94d47a`, 2026-10-17
**Original authoring chat preserved:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
**Source:** uploaded Claude Code export `Pasted text(20261017-103752).txt`, ending at Claude's reported 6:19 AM stop. Local code/evidence cannot be inspected via GitHub.

## Existing surfaces: DO NOT START A NEW WORKSTREAM

- Claimed branch: `agent/compound-connected-bunker-blockout-review-corrections-1`, remote at `934805e71ac4e82c4588365f5e7e1dddea912eaa` (initial claim base, not local implementation).
- Claimed LOCAL worktree: `/home/braydenchaffee/Projects/.custodian-worktrees/compound-connected-bunker-blockout-review-corrections-1-20261017T095054Z-8a9b9edd7d85`
- Persistent coordination checkout: `/home/braydenchaffee/Projects/CUSTODIAN`
- Actual conflict in export: `design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md`.
- Claimed correction packet remains ACTIVE at `custodian/docs/ai_context/task_packets/COMPOUND_CONNECTED_BUNKER_BLOCKOUT_REVIEW_CORRECTIONS_1.md`. NO corresponding archived correction appears on current main.
- Original B review concluded with genuine findings R0-01 (unusable surface↔subsurface entry) and R0-02 (missing real collision, navigation, camera proof). Preserve this verdict and its stable IDs. Do not edit the reviewed parent.

## Positive results from Claude export (claimed, not yet independently verified)

1. Implemented a bounded `custodian/game/world/compound/compound_vertical_entry_controller.gd` (~145 lines), consuming stable `compound_vertical_entries` from `ProcGenTilemap`. It derives active layer from Operator position, uses paired anchors, prevents bounce and tries to restore existing camera bounds.
2. Extended `custodian/game/world/procgen/proc_gen_tilemap.gd` with entry/layer accessors and attached controller, and `custodian/tools/validation/compound_connected_bunker_smoke.gd` plus `validation_manifest.json` to cover two entry pairs both ways and actual physics.
3. Discovered that this project uses `NavigationSystem` / tilemap-backed `AStar2D`; the scene `NavigationRegion2D` baked an empty polygon and is NOT the pathing authority. Updated the smoke to test canonical AStar instead of declaring an empty nav region a bug.
4. Deliberately removed transfer controller / sealed-cell guard separately to prove the smoke rejects both regressions. Reported 77/77 checks before worktree closeout.
5. Kept original review/findings/other session claims protected and committed correction code locally before sync.

## Errors/risk requiring correction

- Claude's command used `git fetch && git merge ... ; python ... ; finish ...`: validation continued despite an **unresolved merge conflict**. 77/77 does NOT prove the merged tree and must never be reused for finish.
- A planning update to the same compound design spec was published while this claimed branch was active. Retain both meaningful implementations/review-status edits, removing contradictions/duplicate claims. Do NOT pick `ours` or `theirs` blindly.
- Earlier `finish` commands launched with working directory in an ephemeral worktree later removed, causing nonzero shell status after a successful landing; use a stable coordination shell and preserve real exit codes, no `tail` masking failures.
- Claude's export says the Claude session is set to **automatically resume at 8:10 AM local**. **HARD GATE:** operator must cancel/pause the scheduled Claude continuation and verify no other writer/claimant/reviewer is active on this original worktree before Codex mutates it. Never race Claude. Do not kill processes, delete claims/locks, `git reset`, `git clean`, `git stash`, force push or create another workstream.
- The remote correction branch is at the initial claim base. New clone/agent claim cannot reconstruct Claude's locally committed code. If local worktree/commits unavailable, STOP and report loss of local evidence.

## Exact first inspection: read-only (from a persistent shell)

```bash
set -euo pipefail
ROOT="/home/braydenchaffee/Projects/CUSTODIAN"
WS="/home/braydenchaffee/Projects/.custodian-worktrees/compound-connected-bunker-blockout-review-corrections-1-20261017T095054Z-8a9b9edd7d85"
test -d "$WS"
git -C "$ROOT" fetch origin main
git -C "$WS" rev-parse --show-toplevel
git -C "$WS" rev-parse --git-common-dir
git -C "$WS" branch --show-current
git -C "$WS" status --porcelain=v1 -b
git -C "$WS" worktree list --porcelain
git -C "$WS" rev-parse -q --verify MERGE_HEAD || true
git -C "$WS" ls-files -u
git -C "$WS" log -5 --oneline
git -C "$WS" diff --cc -- design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md
python3 "$ROOT/custodian/tools/agent/dispatch.py" audit --json
```

Verify branch name, git-common-dir, claim record/worker ownership, index/merge state, local implementation commit and ALL dirty paths. Confirm `git show :1:<path>`, `:2:`, `:3:` are the intended base/ours/theirs; do not assume the conflict from the export is still the only one. If another owner is active or paths differ, STOP with inventory.

## Codex local continuation: scoped, no new claim

**1. Complete the original merge, not a replacement merge.** Inspect 3-stage conflict for `design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md`. Retain both landed A/B geometry descriptions, newer main's review-gated status, and Claude's genuine R1 implementation details but mark them unaccepted until review. Remove conflict markers and duplicate/contradictory prose. Ensure the correction's committed runtime, test, manifest, packet archive and summary still exist. `git -C "$WS" add -- <designpath>`, inspect `git diff --cached --check`, then `git -C "$WS" -c core.editor=true merge --continue` only if `MERGE_HEAD` exists and all conflicts resolved. Never abort/reset a merge without operator approval.

**2. New verification on the RESOLVED tree.** Confirm `compound_vertical_entry_controller.gd` is the unique transfer owner; tilemap remains one layer/collision authority; `NavigationSystem` AStar proves genuine underground reachability while surface→underground has no path except the explicit paired transfer; two entries both directions, no immediate bounce, no underground room-to-room transfer, camera bounds isolate/restored, physics separator solid. Keep 1/2/3/10/42/99/1337 deterministic, `legacy` + `walled_yard` unchanged. Focused manifest test IDs first, then full changed-file sweep from the worktree. Save JSON **outside any tracked/untracked checkout**:

```bash
set -euo pipefail
ROOT="/home/braydenchaffee/Projects/CUSTODIAN"
WS="/home/braydenchaffee/Projects/.custodian-worktrees/compound-connected-bunker-blockout-review-corrections-1-20261017T095054Z-8a9b9edd7d85"
EVIDENCE_DIR="$(git -C "$WS" rev-parse --git-common-dir)/custodian-codex-handoffs"
mkdir -p "$EVIDENCE_DIR"
REPORT="$EVIDENCE_DIR/compound-connected-bunker-blockout-review-corrections-1-post-merge-validation.json"
python3 "$WS/custodian/tools/validation/run_validation.py" --changed --base origin/main --json > "$REPORT"
python3 - "$REPORT" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
bad=[(t.get("id"),t.get("status")) for t in d.get("tests",[]) if t.get("status")!="passed"]
print(d.get("summary"),"FAILURES",bad)
if bad or not d.get("tests"):
    raise SystemExit("missing or failed validation")
PY
git -C "$WS" diff --check
python3 "$ROOT/custodian/tools/agent/workstream.py" preflight compound-connected-bunker-blockout-review-corrections-1 --validation-report "$REPORT" --json
```

Check the report's actual schema, full coverage, and status before accepting green. `preflight` is read-only and NOT landing. Full `run_validation.py --changed` may invoke a resource-heavy Godot test sweep: honor `VALIDATION_RECIPES.md` budget/lock and do not launch overlapping sweeps.

**3. Normal finish and landing.** From the stable coordination checkout, run `python3 custodian/tools/agent/workstream.py finish compound-connected-bunker-blockout-review-corrections-1 --validation-report "$REPORT"` after preflight is truly ready, using the existing exact claimed worktree. If main advances during finish, re-test the final after-sync tree and pass its own `--validation-report-after-sync` only when the current workflow asks for it. Do not certify the 77/77 conflicted report. Verify archive introduction, exact main ancestry, complete packet/summary, released original claim, preserved evidence. A successful finish may remove the claimed worktree: *never* run shell commands from that deleted directory or interpret resulting shell exit 1 as an implementation failure.

**4. Independent review is a different task and agent context.** Only after actual landed proof, invoke the repository `paired_review_runner.py` front door for `review-compound-connected-bunker-blockout-review-corrections-1` in a NEW Codex reviewer context. Do not first claim it with dispatcher, which would make runner's own claim conflict. Review R0-01/R0-02 using real `NavigationSystem` pathing, transfer, physics, camera, Negative controls and legacy/yard. On PASS: archive proper independent review receipts. On findings: preserve and bounded-correct, no fabricated PASS.

**5. Separate Type A review, then traversal.** `review-compound-walled-yard-blockout` may run when `compound-layout` lock free; it does not require B R1 PASS. `compound-interior-traversal-integration` requires *both* accepted reviews, and must REUSE B's transfer/controller, not implement a second one.

## Narrow return contract

Report: `exclusive_owner_verified`; `original_claim_verified`; `local_commits`; `merge_conflicts_before_after`; `resolved_doc_diff`; `focused_checks`; `post_merge_changed_checks`; `preflight`; `finish`; `main_sha`; `review_state`; `next_eligible`; `blocker`. Stop at a safety failure and preserve all branch/claim/worktree bytes. No asset generation or monitoring expansion.
