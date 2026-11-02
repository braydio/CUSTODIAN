# Moment Forge V1 Task Packet

Status: implementation in progress — core V1 workflow live  
Last updated: 2026-07-29

Authority: `design/02_features/debug_ui/MOMENT_FORGE_SYSTEM.md`

## Objective

Provide a developer-only deterministic micro-playtest workbench that stages
curated scenes at fixed ticks, injects authored inputs, records Observatory
telemetry and probes, captures review evidence, compares compatible baselines,
and routes changed files to ranked scenarios without changing normal game boot
or production authority.

## Implemented

- Full V1 scenario/schema contract with deterministic simulation, setup roles,
  spawns, safe properties, processing controls, timeline actions, probes,
  stable assertions, fingerprints, and tags.
- Six first-pack authored scenario documents.
- Invocation-only `SceneTree` runner; no autoload or normal boot change.
- Real scene instantiation, deterministic role resolution, input cleanup,
  exact post-draw keyframes, Observatory export, timeline enrichment, probes,
  assertions, metrics, and run-result evidence.
- `none`, `evidence`, and Movie Maker-backed `full` capture modes.
- 48 kHz stereo review audio canonicalization, MP4/contact-sheet generation,
  advisory audiovisual comparison metrics, and dependency-free HTML reports.
- Baseline compatibility checks and explicit accept/replace workflow.
- Ranked, reasoned changed-file routing with branch-base support.
- Split schema, router, report, and Godot runtime smoke checks.
- Review output confinement to `reports/moment_forge/`.
- Derived visible-Operator visual-anchor probes; light/heavy combat scenarios
  now fail stable assertions above `0.5 px` at every authored review tick.

## Validation

```bash
python3 -m py_compile custodian/tools/iteration/*.py
python3 custodian/tools/validation/moment_forge_smoke.py
godot --headless --path custodian --script \
  res://tools/validation/moment_forge_runtime_smoke.gd
python3 custodian/tools/iteration/run_moment.py \
  combat/light_hit_grunt --capture-mode none
python3 custodian/tools/iteration/run_moment.py \
  combat/light_hit_grunt --capture-mode evidence
python3 custodian/tools/iteration/run_moment.py \
  combat/light_hit_grunt --capture-mode full
```

Validated on 2026-07-29: Python checks pass, Godot runtime smoke passes, all six
first-pack scenarios complete in `none` mode, two repeated light-hit runs
produce the same stable fingerprint, and light-hit `evidence` plus `full`
captures complete. The full run produced synchronized MP4/WAV evidence,
six exact-tick keyframes, a 3840×1440 contact sheet, audio metrics, and HTML.

## Blocked / Deferred Calibration

- `combat/light_hit_marine_deflect` loads a real Marine, but the production
  enemy surface does not yet expose a narrow public fixture boundary that can
  authoritatively stage guard/deflect state. The scenario captures the strike
  and Marine evidence but does not claim a stable deflect event assertion.
- `combat/parry_success` currently preserves the authored Operator parry-window
  presentation. A deterministic public enemy-attack fixture boundary is still
  needed before adding a stable `parry_success` event assertion.
- `vista/sundered_keep_first_reveal` loads the production approach and captures
  it deterministically, but a production-sized authored world-vista fixture
  with Operator threshold traversal remains the next scenario-calibration
  slice.
- Stable combat assertions are intentionally conservative until live event
  names and fixture boundaries are calibrated. Artistic pixel/audio deltas
  remain advisory.

## Next Agent Slice

1. Add explicit public dev-fixture commands for Marine guard/deflect and a
   deterministic enemy attack without calling private combat methods.
2. Build the production-sized Sundered Keep first-reveal fixture and drive its
   Operator through the authored reveal threshold.
3. Calibrate stable event assertions for damage, deflect, parry, Field Patch
   commit, and vista threshold order.
4. Run all six scenarios twice with
   `--require-identical-stable-fingerprint`, then accept initial baselines only
   after human audiovisual review.
