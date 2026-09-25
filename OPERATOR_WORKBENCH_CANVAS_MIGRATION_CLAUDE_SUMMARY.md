# Operator Workbench Canvas Migration — Closeout

Implemented a first-class `frame_canvas` contract migration beside the existing `frame_count` migration. Canvas changes center-copy source RGBA frames into a new transparent cell without scaling, keep source contracts unchanged while staged, recompute the physical document canvas/placements, and update workspace and publish contracts. Shrinking checks all discarded regions for nonzero alpha and fails with layer/frame/bounds context before committing a transformed strip. Socket coordinate tracks are a separate YELLOW dependency and block apply/publish.

Fast 02 E was used as the real integration fixture in a temporary workspace: six 96×96 lower-body, upper-body, and FX strips migrated to 128×128, with a 768×128 output and physical Aseprite assembly. Every original frame's RGBA bytes matched the centered region at `(16,16)` exactly; padding remained transparent. Frame count stayed six. No canonical art was published or changed by this fixture.

Scopes are `animation` (Operator-authored current-profile presentation layers), `body` (lower+upper or full-body fallback), and `all` (every editable publishing binding, including linked ownership). CLI and UI call the same backend. The UI uses a typed canvas migration view, `Shift+R`, preset buttons plus explicit dimensions, a separate review/confirm screen, a truthful canvas-size line in publish review, and refuses migration when the exact connected Aseprite document is dirty. The Art Agent remains unable to resize; canvas-contract migration belongs only to Workbench publication authority.

The existing runtime catalog merge already updates `frame_size`; a regression now starts with stale 96×96 catalog metadata and proves a 128×96 runtime contract replaces it. Mirrored publish collision checking also refuses to overwrite an unrelated existing new-size target.

Validation:

- `operator_animation_workbench_smoke.py` — passed, including real Aseprite Fast 02 E assembly and centered pixel identity.
- `operator_workbench_ui_smoke.py` — passed service assertions; optional Textual pilot skipped because Textual is not installed.
- `operator_workbench_mirror_publish_smoke.py` — passed.
- `operator_modular_pipeline_smoke.py` — passed, including catalog `frame_size` migration.
- `operator_animation_contract_report.py` — 63 expected, 60 present, zero required gaps, three optional gaps.
- `run_validation.py --changed --json` — 13 passed, one unrelated unit failure, 40 later-tier tests skipped. The failing `operator_animation_timing` expects `melee_1h/locomotion/run_01/s`, absent from the pre-existing dirty generated runtime manifest, which currently contains only the schema/empty animations. The failure is unrelated to canvas migration; the worktree's generated manifest was already dirty before this task.
- `py_compile` and `git diff --check` — passed.

Not done: no canonical publish, no resize/scaling of pixels, no arbitrary anchors, no socket rewriting, and no forced cleanup of unrelated dirty files. The graph MCP could not initialize (`No module named 'rich.traceback'`), so exploration used targeted file/symbol reads.
