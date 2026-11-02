# REVIEW_COMPOUND_CONNECTED_BUNKER_BLOCKOUT Summary

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488

## Findings

- **R0-01 — Blocking defect: surface access does not connect to the underground network.** The planner creates paired `surface_anchor` / `subsurface_anchor` metadata, but runtime code has no consumer that transfers the player or changes the active layer. Outside planner generation, `compound_vertical_entries` is stored/exported by ProcGenTilemap, drawn on the minimap, and inspected by validation. The smoke performs separate floods from the surface spawn and underground anchor; it never traverses between paired anchors. Neither surface housing can currently be used to reach the underground network, contrary to the acceptance that both surface access points reach it.
- **R0-02 — Material evidence gap: collision, navigation, and camera isolation are not verified.** The new smoke sets `build_runtime_wall_collision = false` and `auto_bake_nav = false`. It verifies floor/wall cell connectivity, but does not exercise generated collision or navigation, and it has no camera-layer assertion. The review packet explicitly requires physical two-layer geometry/navigation evidence and no collision/camera or other-layer leaks.

These findings fail the review correction threshold for incomplete accepted behavior and missing proof. No PASS receipt was appended to the target packet. The active review packet and claimed worktree remain recoverable for the bounded correction/re-review lifecycle.

## Review identity

- Reviewed main: `2f3c0def9b5297e149816f34660bad6040ed16d7`.
- Reviewed implementation commit: `475ad8d85b45fda792351ea14c19152567d9a4bc`.
- Reviewer context: fresh.
- Reviewer provenance: different-agent.
- Review outcome: findings; one blocking defect and one material evidence gap.

## Evidence

All six focused validations passed: `compound_connected_bunker`, `compound_archetype_profile`, `persistent_compound_layout`, `persistent_compound_runtime`, `persistent_compound_minimap`, and `carrow_yard_interior`. The new smoke covers planner and real-generator determinism for seeds 1, 2, 3, 10, 42, 99, and 1337, and proves the surface and subsurface regions are each internally connected. Those passes do not prove a usable transfer between the separate regions or actual collision/navigation behavior.

Structured validation result: `/home/braydenchaffee/Projects/CUSTODIAN/.git/custodian-review-runs/review-compound-connected-bunker-blockout/20261017T093022Z-53c824e8e5a6/validation.json` (`custodian.validation.result.v1`, six of six tests passed, complete coverage).

The first smoke invocation encountered a cold Godot cache and failed before test execution. A project import populated the cache; all six focused validation runs then passed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: blocked
- Friction severity: medium
- What went wrong: passing smoke coverage does not exercise the paired layer transfer and turns off collision and navigation generation
- Root cause / contributing factors: the smoke treats the two independently walkable regions and exported entry metadata as sufficient traversal proof
- Prevention / pipeline improvement: add an end-to-end paired-entry traversal check plus real collision/navigation and camera-layer assertions to the bounded correction
- Tooling / docs drift discovered: validation passes currently overstate the acceptance proof for connected surface-to-subsurface access
- Follow-up: manual-follow-up
- What worked: the focused smoke exposed its own proof boundary when compared with runtime consumers and the declared acceptance

## Next Handoff

- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Refresh reason: none
- Next action: coordinator should resume this active review worktree and author the bounded correction/re-review packet; this reviewer did not claim another workstream
- Blockers or open questions: implement a player-usable paired surface/subsurface transfer and validate its collision, navigation, and camera behavior
