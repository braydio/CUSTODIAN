# Operator Workbench Sparse Art Checkout — Independent Review

Reviewed landed main at `dfaf9e269`. The per-worktree sparse profile and scoped publication controls largely match the packet. One blocking live validation defect remains: the two `block_hold_01` FX import records are committed invalid, causing the required modular-layer smoke to fail. Finding `R0-01` and its bounded correction/re-review pair are recorded in the archived packets.

## Review Evidence

- `operator_art_worktree_smoke.py`: PASS. Its isolated fixtures cover fresh and migrated worktrees, ignored `.ai` preservation, clean FF-only synchronization, dirty/ahead/pending preservation, unrelated tracked-path omission, selected-path updates, unexpected-output refusal, allowed scoped staging/landing, and resumable pending landing.
- Per-worktree isolation: a fresh probe found `core.sparseCheckout` and sparse patterns in the art worktree's `config.worktree`; coordination remained full-tree and its unrelated tracked enemy file stayed present.
- Real sparse profile: 9,665 of 37,307 tracked paths materialized (27,642 omitted; about 26%), about 321 MB before Godot's ignored `.godot` cache. Unrelated enemy art, reports, and asset-drop inputs were absent. Operator source/runtime, tools, animation design, and project dependencies used by the UI were present.
- `operator_workbench_ui_smoke.py`: PASS; optional Textual pilot skipped because its dependency is not installed.
- `operator_animation_workbench_smoke.py`: PASS.
- `operator_workbench_mirror_publish_smoke.py`: PASS.
- Compatibility-resource `--check`: PASS. Animation contract report: 60/63 present, 0 required missing, 3 optional missing.
- Godot import completed, but `operator_modular_layers_smoke.gd` failed loading the east/west `block_hold_01` FX resources. Both PNGs are tracked, present in the sparse tree, and Pillow-valid; their `.import` sidecars have `valid=false` and no remap path/destination entries. A repeat smoke after import failed the same way. The failed smoke process was stopped after it remained alive with the same script-load error.
- This import failure is in the live tracked `origin/main` asset metadata, not a path omitted by the sparse profile. It prevents the required real sparse publication-validation proof and contradicts the implementation packet's completion note that the modular smoke passed.

No reviewed implementation code or production art was changed. Local LFS cache hydration materialized test inputs only in the review worktree. The project-root checkout's staged procgen changes were left untouched.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `low`
- What went wrong: The first UI/Workbench smoke attempts encountered pointer-only LFS files; after using cached LFS objects, those checks passed. The actual Godot modular-layer check exposed invalid tracked import metadata.
- Root cause / contributing factors: The LFS-degraded checkout skipped smudge as designed. Two `block_hold_01` FX `.import` files on main were committed without valid remap metadata.
- Prevention / pipeline improvement: Keep the real sparse Godot modular-layer validation in the correction acceptance and inspect generated `.import` records, not only fixture behavior and Python checks.
- Tooling / docs drift discovered: The configured code-review-graph MCP tools were unavailable in this session; source-text and Git history inspection were used as fallback. The implementation completion note does not reproduce for the current main asset state.
- Follow-up: `operator-workbench-sparse-art-checkout-review-corrections-1`
- What worked: Isolated sparse checkout and fixture publication checks avoided mutating the developer's art worktree.
