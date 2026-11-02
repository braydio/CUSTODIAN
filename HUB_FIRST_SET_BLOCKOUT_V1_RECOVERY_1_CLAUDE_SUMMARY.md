# Hub First-Set Blockout V1 — Workstream Summary

## What changed

- Reimplemented the current-main H1 layout/map at the locked 32px grid bounds, with named spawn/POI markers, one authored navigation grid, and collision rails derived from its walkable boundary.
- Reused the Road's five production plate pairs without duplicating their runtime registration; disabled legacy Road blockers only inside the Hub presentation instance.
- Added the standalone real-Operator/camera playtest at `Spawn_SouthReach`, an exact geometry/connectivity/collision-ownership smoke, and one deterministic full-map overview capture.
- Updated Hub spatial, roadmap, current-state, context, H2 dependency-state, and file-index documentation. Marked H1 complete and archived its packet; left the paired H1 review active.
- Retired the obsolete main-contained remote alias and lifecycle-only diagnostic ref, removed the stale donor worktree/local branch, and preserved donor commit `720185d45930ff6603bd051676f3ff7cb20a655d` under `archive/agent-hub-first-set-blockout-v1-20261005` with branch-ledger entries.

## Evidence

- Focused H1 smoke: passed; 13,142 walkable cells, 52 merged boundary rails, 14 markers, and 12,160 clearance-safe cells. Clearance used the live 15px capsule bound plus 10px boundary rails. Exact bounds/envelopes/markers, all envelope cells, both separate 4x8 connectors, connector-restricted Garden loop, raw and clearance routes, Road registration, inert lifecycle, and playtest spawn/camera checks passed.
- Road production smoke: passed.
- Twin Solaria runtime smoke: passed.
- Final changed-file validation: `/tmp/hub_first_set_blockout_validation.json`; passed 13/13 with complete coverage and no timeouts.
- `git diff --check`: passed.
- Human overview: `reports/hub_first_set_blockout/overview.png` (2048x2048); opened through the review Kitty/xdg-open control and approved when the human closed the Kitty window on 2026-10-05.
- Stale-H1 cleanup: no old `agent/hub-first-set-blockout-v1` branch, no old diagnostic ref, no temporary dispatch claim, and no donor worktree/local branch remain. The old commit remains recoverable by its archive tag.

## Friction and deferred work

The first claim command continued beyond its initial 30-second wait while `git worktree add` reset the fresh checkout through Git LFS; it later completed successfully, and no duplicate claim was started. The fresh worktree then needed its first Godot import before global class discovery worked. The headless dummy renderer has no root texture, so the overview capture was implemented with an explicit GPU SubViewport. The first changed-file validation found that the capture helper was missing an owner; after adding it, the final 13-test run passed with full coverage. H2-H7 transitions, Contract prewarm, Twin transfer, Port deployment, Campaign return, and production Hub art remain deferred.

The historical donor summary recorded 13,110 cells and 48 rails, but did not establish the final two-connector loop, Operator-clearance routes, or Port-return semantics. The fresh implementation did not merge that branch; its unique history is archived as noted above.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The claim exceeded the initial wait while Git LFS materialized the fresh worktree; first-run Godot imports were required; headless root-texture capture failed; initial changed-file coverage omitted the capture helper.
- Root cause / contributing factors: No worktree-local `.godot` import cache; dummy headless renderer; incomplete validation owner list for the capture script.
- Prevention / pipeline improvement: Perform one editor/import preflight in a fresh runtime worktree; use a GPU SubViewport for renderer evidence; register capture helpers under the owning smoke.
- Tooling / docs drift discovered: H1 runtime status/index, H2's measured-state text, and Hub spatial status prose lagged the recovered implementation; corrected in this workstream.
- Follow-up: fixed-in-scope
- What worked: Clearance erosion reads the real Operator capsule and active boundary rails; the restricted loop mask proves traversal through both distinct Sepulcher connectors.

## Next Handoff

- Next workstream: review-hub-first-set-blockout-v1
- Next packet state: ready
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Start the paired review in a fresh reviewer context; reuse the approved overview and focused structural evidence.
- Blockers or open questions: none
