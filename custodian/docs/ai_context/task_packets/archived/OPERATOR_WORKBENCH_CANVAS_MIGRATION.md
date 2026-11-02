# Operator Workbench Canvas Contract Migration

- Status: `complete`
- Authority: `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`
- Goal: Add explicit centered, no-resampling per-frame canvas migration to Workbench V2 with CLI/UI parity and transactional publish compatibility.
- Files: Workbench frame-contract/backend/model consumers, Operator CLI and UI, Aseprite assembly path, focused Workbench/UI/pipeline smokes, animation docs and AI context.
- Constraints: Preserve source contracts while staged; never scale pixels or silently crop visible pixels; keep frame count/timing unchanged; only explicit publish changes canonical source/runtime; preserve unrelated shared-worktree edits.
- Acceptance: Fast 02 E 6f 96×96 → 128×128 stages all Operator-authored lower/upper/FX layers, assembles a 768×128 six-frame sheet, and preserves each source frame byte-for-byte centered at (16,16); shrink refuses visible crop; generated catalog adopts new `frame_size`; UI/CLI use one backend authority.
- Completed: Center-copy transform, scopes, coordinate dependency audit, staged `frame_canvas` manifest, CLI and Shift+R review/apply flow, dirty live-document guard, committed runtime-catalog `frame_size` correction with end-to-end Fast 02 pipeline regression, and focused pixel/crop/Aseprite integration coverage.
- Deferred: Full canonical publish is intentionally not run against shared production art; normal explicit publish pipeline remains the publication gate.

## Validation

- `python3 custodian/tools/validation/operator_animation_workbench_smoke.py` — passed, including real temporary Fast 02 assembly when Aseprite is present.
- `python3 custodian/tools/validation/operator_workbench_ui_smoke.py` — full Textual pilot passed in an isolated temporary virtual environment, including the actual Y action and live bridge result/cache freshness behavior.
- `python3 custodian/tools/validation/operator_workbench_mirror_publish_smoke.py` — passed.
- `python3 custodian/tools/validation/operator_modular_pipeline_smoke.py` — passed, including canonical/staged/runtime/catalog Fast 02 96×96→128×128 contract propagation.
- `python3 custodian/tools/validation/operator_animation_contract_report.py` — 63 expected, 60 present, 0 missing required, 3 missing optional.
- `python3 custodian/tools/validation/run_validation.py --changed --json` — 12 passed, one unrelated `operator_animation_timing` failure because the dirty generated Operator runtime manifest lacks `melee_1h/locomotion/run_01/s`; 41 dependent/later checks skipped. The exact failing assertion is the missing animation key in the generated runtime manifest.
- Canvas review reports expansion clipping as impossible and shrink clipping as validated during staging (where the existing visible-pixel audit fails closed); it no longer claims the dry-run inspected pixels.
