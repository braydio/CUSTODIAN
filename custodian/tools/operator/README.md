# Operator Authoring Tools

## Semantic animation workbench

Canonical PNG source is authority. The ignored `.aseprite` workbench is a
disposable editing surface outside `res://`.

```sh
operator anim list melee_1h --group posture
operator anim status melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim edit melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim refresh melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim publish melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger
operator anim frame add melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger --after 2
operator anim frame remove melee_1h idle_relaxed_01 e --weapon vigil_pattern_dagger --frame 3
```

Workspaces default to `.ai/operator_animation_workbench/<profile>/<group>/<action>/<direction>/`.
Use `--dry-run` on frame or publish commands to inspect without mutation. Frame
commands stage a dependency-audited migration in `.ai`; only publish changes
canonical PNG contracts.

Use `modular_combo_check.py` for ordinary modular lower/upper visual review.
Use the provenance-first repair conveyor when the review identifies artwork
that needs manual waist-seam correction:

```sh
python3 custodian/tools/operator/modular_alignment_repair.py
```

Useful non-interactive previews:

```sh
python3 custodian/tools/operator/modular_alignment_repair.py --report-only --no-open
python3 custodian/tools/operator/modular_alignment_repair.py idle --dry-run
```

The repair command treats live runtime pixels as the legacy baseline. It first
asks the production builder which modular source it would consume and proves a
pixel-exact roundtrip. Stale or missing source is backed up, quarantined, and
replaced by a runtime-normalized source only after that promoted source also
roundtrips exactly. `_pipeline/archive` is diagnostic intake recovery, not
canonical history.

The generated workspace is `.ai/operator_modular_alignment_repair/`. It holds
the live-refresh HTML report, queue/resume state, immutable first backups, and
recoverable quarantined source. Aseprite edits remain manual; the controller
never moves, crops, rescales, or redraws pixels. After save/close it validates
the sheet contract, invokes the production modular builder, and rechecks the
affected combinations. Resume with `--resume`.
