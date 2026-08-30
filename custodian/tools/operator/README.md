# Operator Authoring Tools

## Semantic animation workbench

Canonical PNG source is authority. The ignored `.aseprite` workbench is a
disposable editing surface outside `res://`.

The preferred interactive authoring front door is the optional Textual UI:

```sh
python3 -m venv --system-site-packages .ai/operator-ui-venv
.ai/operator-ui-venv/bin/pip install -r custodian/tools/operator/ui/requirements.txt
.ai/operator-ui-venv/bin/python custodian/tools/operator/operator_cli.py ui
```

If the `operator` alias uses that environment, the final command is simply
`operator ui`. Optional startup context accepts `--profile`, `--group`,
`--action`, `--direction`, `--weapon`, and `--linked-profile`. The TUI calls
the same structured Workbench V2 Python APIs as the CLI; it never executes or
parses `operator anim` output. Aseprite remains the visual editor.

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

The UI supplies searchable semantic navigation, layer/reference inspection,
nonblocking Aseprite launch, saved-workbench change detection, dependency-
audited frame review, mandatory publish review, transaction-journal progress,
and standard/full validation. Browser rows are directional variants and expose
COMPLETE/PARTIAL/REFERENCE status from their canonical layer set; incomplete
weapon-only or fragment sources remain inspectable without being presented as
production-complete. The compact layer table shows source → workspace → publish
contracts, with ownership detail below it. The CLI remains the automation front
door.

Publish refreshes the V2 runtime first, then runs
`tools/pipelines/update_operator_compatibility_resources.py` before Godot
import. This keeps legacy aliases consumed directly by `operator.tscn` pointed
at the current semantic frame contract. Its `--check` mode reports retired
runtime paths before actor smokes.

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
