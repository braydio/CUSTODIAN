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

Requirements:

- Godot available as `godot` or through `GODOT_BIN`
- Pillow for contact sheets and visual diffs
- FFmpeg is optional; without it the report still contains frames/contact sheets

See `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md` for the full contract.
