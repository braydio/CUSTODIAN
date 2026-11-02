# CUSTODIAN Moment Forge

Moment Forge runs curated deterministic micro-playtests and writes review-only
evidence under `reports/moment_forge/`.

```bash
python3 custodian/tools/iteration/run_moment.py --list
python3 custodian/tools/iteration/run_moment.py --changed --base origin/main
python3 custodian/tools/iteration/run_moment.py combat/light_hit_grunt --capture-mode none
python3 custodian/tools/iteration/run_moment.py combat/light_hit_grunt --capture-mode evidence
python3 custodian/tools/iteration/run_moment.py combat/light_hit_grunt --capture-mode full
python3 custodian/tools/iteration/run_moment.py combat/light_hit_grunt \
  --baseline reports/moment_forge/combat/light_hit_grunt/<run-id>
python3 custodian/tools/iteration/run_moment.py combat/light_hit_grunt \
  --capture-mode full --accept-baseline approved --yes
```

The Godot runtime is launched only by the CLI with `--moment-forge`; Moment
Forge is not an autoload and does not affect normal game boot. Full capture
uses Godot Movie Maker so the frame sequence and audio share one fixed-tick
source. Evidence mode captures only the six authored post-draw keyframes;
metrics-only mode is headless.

Review media is advisory. Only stable assertions declared by the scenario can
fail a run.

When objective checks are complete but an important subjective presentation
question remains, publish the smallest useful review surface with
`publish_review_artifacts.py --important --reason ... --authoring-chat <exact-url>`. It sends compact
ROI/contact sheets, sparse keyframes, and selected metadata to the configured
rclone Dropbox review root and emits a manifest path for human/ChatGPT review.
Do not use this as a substitute for probes/metrics, and do not ask the coding
agent to approve its own aesthetics. See
`custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`.

Requirements:

- Godot available as `godot` or through `GODOT_BIN`
- Pillow for contact sheets and visual diffs
- FFmpeg is optional; without it the report still contains frames/contact sheets

See `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md` for the full contract.

## Visual Validation Economy

Prefer structural probes/assertions over screenshot review. `moment_probe_collector.gd`
exposes generic presentation fields (`effective_alpha`, `global_bounds`,
`collision_shape_count`, etc.) on any `Sprite2D`/`AnimatedSprite2D` role, and
`moment_assertion_evidence.gd` adds cross-record assertions (`probe_field_equal`,
`probe_field_delta`, `probe_sequence_equal`) to compare them across
probes/ticks without rendering. When pixels themselves must be checked, use:

```bash
python3 custodian/tools/iteration/presentation_image_metrics.py <spec.json>
```

for deterministic alpha/matte/seam/diff/crop metrics from PNGs, and
`build_roi_contact_sheet()` (in `build_moment_report.py`) to compose several
small crops into one compact sheet instead of N full-resolution frames. See
`traversal/awakening_late_seams_v1.json` and
`custodian/tools/validation/awakening_late_seams_evidence.py` for a worked
example, and the "Visual Evidence Economy" section of
`custodian/docs/ai_context/VALIDATION_RECIPES.md` for the full doctrine.

Four tested adopter templates for Twin Crown forensics, Solarium I acquisition,
Operator mobile guard, and Vaultwing bonding closure live in `adopter_specs/`.
They are reusable scenario fragments whose feature owners bind declared states
and read-only probes to their runtime scenes; they do not replace feature-owned
scenarios or grant presentation tools gameplay authority. Run
`python3 -m unittest custodian.tools.iteration.test_visual_validation_adopter_specs`
to validate their contract against the current scenario DSL.
