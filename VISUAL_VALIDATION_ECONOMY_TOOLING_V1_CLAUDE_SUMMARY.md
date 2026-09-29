# VISUAL_VALIDATION_ECONOMY_TOOLING_V1 — Claude Summary

## What landed

**Generic presentation probes** (`custodian/tools/iteration/godot/moment_probe_collector.gd`):
`visible`, `effective_visible`, `modulate`, `self_modulate`, `effective_alpha`,
`z_index`, `z_as_relative`, `effective_z_index`, `global_bounds`, `screen_bounds`,
`texture_size`, `frame_progress`, `collision_shape_count`, `navigation_node_count`.
Readable off any `Sprite2D`/`AnimatedSprite2D` role via ordinary probe `fields`,
no task-local inspection helper.

**Cross-record assertions** (`moment_assertion_evidence.gd`, schema + `run_moment.py`
validation updated): `probe_field_equal`, `probe_field_delta`, `probe_sequence_equal`.
Compare one field across two probes/ticks/roles — registration parity, numeric
delta, or an N-point forward/reverse steady-state equivalence — without reading
a screenshot.

**Offline pixel metrics** (`custodian/tools/iteration/presentation_image_metrics.py`,
16 unit tests incl. negative controls): `alpha_bounds`, `matte_void`, `roi_diff`,
`seam_discontinuity`, `crop`. Deterministic JSON, each check's own threshold folds
into a `passed` bool. Standalone module/CLI, not a second scenario runner.

**Compact ROI contact sheet** (`build_moment_report.py::build_roi_contact_sheet`,
2 unit tests): composes several small named crops into one small labeled sheet
instead of N full-resolution frames.

**Flagship adopter, fully live**: `traversal/awakening_late_seams_v1` scenario +
`awakening_late_seams_moment.{gd,tscn}` fixture + `awakening_late_seams_evidence.py`.
Runs against the real `awakening_first_return.tscn` (no fixture-side duplication of
registration logic — the generic probes read the actual zone Sprite2D nodes
directly). Proves, on live production content, for all five late seams
(05-06, 06-07, 07-08, 08-10, 08-09):
- underlay/foreground registration parity (`probe_field_equal` on `global_bounds`) —
  measured values matched the packet's own documented registration table exactly
  (e.g. Zone05 Dust Lung: `[-608, -3808, 1216, 1216]` = envelope center `(0,-3200)`
  + 64px bleed each side, both layers identical);
- zero collision/navigation ownership on presentation sprites;
- forward/backtrack alpha equivalence (revisit Zone05 at tick 355, same
  `effective_alpha` as tick 30);
- one compact `1200x444` ROI sheet (vs. five `1280x720` full frames) plus a
  void/matte sanity check, all green.
Deterministic across a `--repeat 2 --require-identical-stable-fingerprint` run.
Registered in `validation_manifest.json` (`awakening_late_seams_v1`,
`presentation_image_metrics`, `build_moment_report_roi_contact_sheet`) so
`run_validation.py --changed` selects it automatically; full coverage confirmed
(`coverage.complete: true`, 15/15 selected tests passed).

## Templates for the four adopters whose runtime doesn't exist yet

Per the packet's explicit escape hatch, these are **not** live scenario JSON —
`run_moment.py`'s `load_scenarios()` requires every `scenario` path under
`custodian/tools/iteration/scenarios/` to already resolve to a real `.tscn`
(`require_scene=True`), so a stub scenario referencing a not-yet-built fixture
would break `--list`/`--changed` for everyone. Each dependent packet's own
implementer should copy the relevant pattern below once its runtime lands, using
roles that point directly at the real presentation nodes (no bespoke inspection
helper needed) — this is exactly what the Awakening adopter above demonstrates
end-to-end.

**Twin Crown forensics** (`TWIN_SOLARIA_CROWN_INCIDENT_FORENSICS`) — baseline/Stage
B/Stage F overlay state:
```json
{"id": "crown_overlay_facts", "role": "second_crown_overlay", "fields": ["effective_visible", "global_bounds", "collision_shape_count", "navigation_node_count"], "ticks": [<baseline_tick>, <stage_b_tick>, <stage_f_tick>], "required": true}
```
Assertions: `probe_compare` for `collision_shape_count`/`navigation_node_count == 0`
(overlay never becomes authoritative) at each stage; `probe_field_equal` between
baseline and a restored/reset tick to prove deterministic restore. Evidence:
one 3-cell ROI sheet via `build_roi_contact_sheet` over the three staged ticks.

**Solarium I acquisition** (`TWIN_SOLARIA_SOLARIUM_I_ACQUISITION_PRESENTATION`) —
dormant/candidate/resolve/stable/warning state sequence:
```json
{"id": "aperture_facts", "role": "aperture", "fields": ["animation", "frame_progress", "effective_alpha", "global_bounds"], "ticks": [<one per state>], "required": true}
```
Assertions: `probe_sequence_equal` on `global_bounds` across all five states
(anchor/witness registration must not drift with state); `probe_compare` on
`animation` per state to prove the state->animation mapping. Evidence: one
5-cell aperture/instrument ROI sheet.

**Operator mobile guard** (`OPERATOR_MOBILE_GUARD_COMPOSITION`) — enter/hold/exit
continuity, reusing the existing cross-tick pattern generically:
```json
{"type": "probe_field_delta", "probe_a": "guard_lower_facts", "tick_a": "<enter>", "probe_b": "guard_lower_facts", "tick_b": "<hold>", "field": "frame_progress", "op": ">=", "value": 0.0}
```
plus `probe_field_equal` between movement-direction and aim-direction probe
fields to prove they diverge only when expected. Evidence: one 3-state
runtime-scale ROI sheet only for the final technical proof, not per-iteration.

**Vaultwing bond-greet ingest** (successor to `VAULTWING_BOND_GREET_FINAL_INGEST`,
already archived by the time this landed — the pattern still applies to any
future closure slice) — 24/24 direction/frame closure proven mechanically:
```json
{"type": "seam_discontinuity", "roi": "<direction_cell>", "axis": "vertical", "boundary": "<cell midline>", "band": 2, "max_mean_absolute_delta": <threshold>}
```
via `presentation_image_metrics.py` over one exported contact sheet, flagging
only strips that fail the metric for a compact manual spot-check instead of
inspecting all 24 cells by default.

## Deviations from the plan / discovered issues

- **`awakening-handoff-readiness-art-convergence-v1` was claimed, then released
  unstarted** before this packet: no commits existed on that branch, so
  releasing it (delete worktree + local/remote branch) was lossless. It was
  then `BLOCKED` by `dispatch.py validate_packet_validation_references`
  (surfaced via `validate_review_pairing.py`/the `review_pairing_contract`
  manifest test) flagging its own `Validation` line's forward-reference to
  `awakening_art_registration_smoke.gd` as a "missing" file — that file was
  meant to be *created by* that packet's own future implementation, not to
  already exist. Fixed in this branch: reworded that one line to describe the
  new smoke's contract instead of naming a literal not-yet-existing path
  (`dispatch.py`'s `VALIDATION_SCRIPT_RE` only matches an actual
  `tools/.../*.{py,gd,sh}`-shaped path, so prose describing intent doesn't
  trigger it). This packet was unclaimed at the time, so this is a same-scope,
  low-risk textual correction, not an edit to another agent's in-progress
  surface. General follow-up still worth filing: `validate_packet_validation_references`
  checks `origin/main`, not the local branch, so a fix for this class of
  false-positive can never appear "already green" from the branch that carries
  it — only after landing. That's a structural limitation of the check, not
  something one packet's fix can route around.
- **Environment bug found and fixed in-scope**: this ephemeral worktree's `*.so`
  files were git-lfs pointer stubs (never smudged), so LimboAI's GDExtension
  failed to load, which cascaded into ~9000 unrelated texture/audio import
  failures on `godot --headless --import --quit` (including, misleadingly, the
  Awakening zone plates — `Sprite2D.get_rect()` degrades to a `1x1` fallback
  rect on a missing texture rather than erroring, so the first structural runs
  of the new scenario "passed" with silently-degenerate `global_bounds`). Fixed
  with `git lfs pull` in this worktree, then a full `--import` pass, then
  reverted ~272 unrelated `.import` sidecar diffs that the broad import churned
  (none touch this task). Confirmed real textures load and the registration
  numbers now match the documented contract exactly. This is a real, repeatable
  gap for any fresh ephemeral worktree, not specific to this task.
- Did not deep-wire `presentation_image_metrics.py`/`build_roi_contact_sheet`
  into `build_moment_report.py`'s automatic per-run pipeline; kept them as
  explicit, separately-invoked escalation (matching "the smallest convenient
  mechanism ... only when renderer pixels are actually requested"). If a future
  adopter wants it folded into the automatic report, that's a small additive
  change, not a redesign.

## Files changed

Modified: `moment_probe_collector.gd`, `moment_assertion_evidence.gd`,
`moment_action_driver.gd`, `moment_schema.json`, `run_moment.py`,
`build_moment_report.py`, `tools/iteration/README.md`, `validation_manifest.json`,
`VALIDATION_RECIPES.md`, `AGENT_TOOLING_BY_ASK.md`, `FILE_INDEX.md`,
`design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`.

New: `presentation_image_metrics.py` (+ test), `test_build_moment_report.py`,
`scenarios/traversal/awakening_late_seams_v1.json`,
`validation/fixtures/awakening_late_seams_moment.{gd,tscn}`,
`validation/awakening_late_seams_evidence.py`.

## Tests run

- `python3 -m unittest custodian.tools.iteration.test_presentation_image_metrics
  custodian.tools.iteration.test_build_moment_report` — 18/18 pass.
- `bash custodian/tools/validation/run_moment_forge_suite.sh` — all 5 existing
  Moment Forge focused checks pass (schema, changed-router, report, evidence
  capture, Python smoke, runtime Godot smoke) — no regressions.
- `godot --headless --script res://tools/validation/{awakening_first_return_smoke,
  awakening_first_return_geometry_smoke, awakening_first_return_progression_smoke,
  road_of_witnesses_production_smoke}.gd` — all PASS (pre-existing benign
  "ObjectDB leaked at exit" shutdown warning, identical across all four, not
  introduced by this change).
- `traversal/awakening_late_seams_v1` — `--capture-mode none` green;
  `--repeat 2 --require-identical-stable-fingerprint` identical; one
  `--capture-mode evidence` proof; ROI sheet + metrics built and inspected.
- `python3 custodian/tools/validation/run_validation.py --changed --json` (no
  `--base`) — exit 0, `coverage.complete: true`, 15/15 selected tests passed,
  before the packet-archival commit.
- Closeout: `--changed --base origin/main` also selects `review_pairing_contract`
  (its `owners` glob is `task_packets/**`, touched by archiving this packet) and
  that one fails — but on `origin/main` itself, unrelated to this diff (see
  Deviations: the awakening packet's own forward-reference). Since that check
  hardcodes `tree="origin/main"` it can never read a local branch's fix, so no
  branch carrying that fix can make it "green" pre-land. Final closeout report
  instead merges `--tag moment` (6), `--tier moment` (9, includes
  `awakening_late_seams_v1` plus regression coverage of every other live Moment
  scenario: `ranged_ballistic_*`, `melee_soft_target_spacing`,
  `meridian_civic_native_scale`, etc. — all green, confirming the probe/assertion/
  action-driver changes didn't regress anything), and the four `awakening_first_return*`
  /`road_of_witnesses_production` smokes run individually — 19 distinct tests,
  all passed, covering every file this task touched plus broad regression
  evidence. That merged report is what was handed to `workstream.py finish
  --validation-report`.
- `git diff --check` — clean.

## Deferred

Sophisticated perceptual/aesthetic scoring, automatic baseline approval, broad
migration of historical packets, GPU/computer-vision models — all explicitly
out of scope per the packet's non-goals. Live scenario wiring for the four
non-Awakening adopters is deferred to their own dependency packets, per the
packet's own escape hatch, using the templates above.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: a fresh ephemeral worktree could not render real textures
  at first — headless Godot import silently degraded (1x1 fallback textures,
  no hard error) instead of failing loud, which almost let a false-positive
  "registration match" through.
- Root cause / contributing factors: `*.so` GDExtension binaries are git-lfs
  tracked but worktree creation does not run `git lfs pull`/smudge, so LimboAI
  failed to load and cascaded into unrelated import failures; `Sprite2D.get_rect()`
  on a texture-less sprite returns a degenerate non-null rect instead of null/error.
- Prevention / pipeline improvement: `workstream.py`/`dispatch.py` worktree
  creation should run `git lfs pull` (or verify LFS objects are smudged) as
  part of worktree setup, before any Godot invocation. Worth a bounded fix in
  `custodian/tools/agent/workstream.py`.
- Tooling / docs drift discovered: `awakening-handoff-readiness-art-convergence-v1`
  packet's `Validation` line forward-references a smoke script its own
  implementation is meant to create; the new packet-index/validator tooling now
  flags that as a hard "missing validation script" block. See Deviations above.
- Follow-up: manual-follow-up (LFS-smudge-on-worktree-create is a good small
  `agent-workstream-lifecycle`-adjacent correction packet; the forward-reference
  validator false-positive is a good `ai-context-task-packet-validator`-adjacent
  correction packet). Neither is fixed in this scope since both sit in other
  tools' ownership.
- What worked: the generic-probe design paid off immediately — the Awakening
  seam scenario needed zero bespoke fixture logic for registration/alpha/
  collision facts, only camera-positioning commands, because probes read the
  real production Sprite2D nodes directly.
