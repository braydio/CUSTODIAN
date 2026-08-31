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

## Operator Art Agent V2

`operator art` is the agent-safe semantic repair layer above Workbench V2. V1
primitive editing remains available; V2 adds capability-confined sessions,
landmarks, RLE part masks, draft-first part edits, metrics, QA, plans, critiques,
and review packets. The local `art_agent.mcp_server` is a thin stdio adapter.
It reuses the same semantic workbench and may modify only its ignored `.aseprite`
document. Canonical PNG publication remains exclusively `operator anim
publish`; Art Agent V2 has no publish, runtime rebuild, frame timing, resize,
rotation, or socket API.

```sh
operator art start melee_1h run_01 e --group locomotion --weapon vigil_pattern_dagger
operator art inspect SESSION
operator art render SESSION
operator art paint SESSION --frame 3 --layer lower_body --pixels pixels.json
operator art erase SESSION --frame 3 --layer lower_body --pixels erase.json
operator art stroke SESSION --frame 3 --layer lower_body --color '#d89915ff' --points '44,62;45,62;46,61'
operator art copy SESSION --layer lower_body --source-frame 2 --destination-frame 3 --rect 35,49,16,28 --to 37,48
operator art move SESSION --frame 3 --layer lower_body --rect 35,49,16,28 --dx 2 --dy -1
operator art undo SESSION
operator art close SESSION
```

Semantic examples:

```bash
operator art landmarks SESSION --set landmarks.json
operator art validate-landmarks SESSION
operator art mask SESSION --frame 3 --layer lower_body --part thigh_far --polygon '43,53;49,54;48,66;42,65'
operator art validate-masks SESSION
operator art draft SESSION --kind shift --mask thigh_far_f3_HASH --dx 2 --dy -1
operator art drafts SESSION
operator art validate-drafts SESSION
operator art bake-draft SESSION --draft __ART_DRAFT__thigh_far__f003__HASH
operator art resolve-gap-repair SESSION --draft __ART_DRAFT__thigh_far__f003__HASH --note "cleaned up bake gap"
operator art metrics SESSION
operator art qa SESSION
operator art review SESSION --task 'review east walk'
```

`bake-draft` takes only `--draft`; the target layer/frame/mask and bake-time
clearing behavior come from the `DraftRecord` created with the draft, not from
caller-supplied arguments. A draft whose source, destination, or draft-layer
pixels changed since creation is refused (`STALE`) rather than baked.

Run the real V2 acceptance pilot with `operator art pilot` or machine-readable
`operator art pilot --json`. The shared runner targets the eight-frame east
Vigil walk, writes review evidence under
`reports/operator_art_agent/v2_pilot/<timestamp>/`, temporarily edits only the
disposable `.ai` Workbench, and requires byte-exact restoration plus unchanged
production hashes. Add `--keep-artifacts` to retain the temporary session;
Aseprite is required unless a caller explicitly supplies
`--allow-skip-aseprite`.

Normal CLI use cannot override Art Agent or Workbench roots. Tests inject
temporary roots through `ArtAgentService` directly.

Sessions live under
`.ai/operator_art_agent/<profile>/<group>/<action>/<direction>/<session-id>/`.
Every mutation takes a complete pre-operation `.aseprite` backup, uses a
nonblocking process lock plus optimistic SHA guard, records an append-only
JSONL journal, and rolls back automatically if the bridge fails. Coordinates
are document-space. `render` writes transparent per-frame PNGs, a strip,
contact sheet, baseline diff, and before/after image. Saving the workbench in a
GUI during an active session intentionally trips the external-change guard.

The UI supplies searchable semantic navigation, layer/reference inspection,
nonblocking Aseprite launch, saved-workbench change detection, dependency-
audited frame review, mandatory publish review, transaction-journal progress,
and standard/full validation. Browser rows are directional variants and expose
COMPLETE/PARTIAL/REFERENCE status from their canonical layer set; incomplete
weapon-only or fragment sources remain inspectable without being presented as
production-complete. The compact layer table shows source → workspace → publish
contracts, with ownership detail below it. The CLI remains the automation front
door.

Weapon and linked-profile context are global UI state, separate from the
identity-only animation tree. If an identity-only workspace already belongs to
a different context, the UI keeps Workbench V2's strict fingerprint check and
offers Cancel, read-only Open Existing Context, or backup-producing
Recontextualize recovery. It never rewrites `workbench.json` directly.

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
