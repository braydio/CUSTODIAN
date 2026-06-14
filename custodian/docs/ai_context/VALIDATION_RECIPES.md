# VALIDATION RECIPES

Canonical validation guide for CUSTODIAN agent work.

Use the narrowest recipe that proves the change, then broaden only when the change affects shared runtime behavior, scenes, imports, or workflow routing.

Prefer RTK subcommands for compact output when they support the command shape. RTK is not a blind prefix: use `rtk git status`, `rtk grep ...`, `rtk find ...`, etc. For unsupported commands where token tracking still helps, use `rtk proxy <command> ...`. Use the raw command when RTK changes argument ordering or hides information needed for debugging.

## Selection Rules

- Doc-only change: validate paths, links, status labels, and discoverability.
- Agent workflow change: validate `AGENTS.md`, `custodian/AGENTS.md`, `docs/ai_context/*`, any affected task packets, and prompt indexes.
- Runtime GDScript change: run a Godot headless check when feasible.
- Scene or asset import change: run Godot import before headless boot when feasible.
- Sprite pipeline change: run dry-run ingest first, then targeted ingest only when outputs are intended.
- Generic runtime-ready asset intake: run the persistent drop router in dry-run mode before apply.
- Tile pipeline change: run Python syntax checks plus the relevant tile generator command.
- Commit/staging task: inspect status with RTK, but do not stage or commit without explicit user approval.

## Common Commands

Run from the repository root unless the recipe says otherwise.

```bash
rtk git status
rtk git diff
rtk grep "pattern" path
rtk find path -maxdepth 3 -type f
```

Correction examples:

```bash
# Git status goes through the git subcommand:
rtk git status

# Exact porcelain status should stay raw:
git status --short

# Raw ripgrep can stay raw or go through proxy:
rg -n "pattern" path
rtk proxy rg -n "pattern" path
```

RTK grep argument order:

```bash
rtk grep "pattern" path --glob "*.md"
```

For complex ripgrep expressions, use raw `rg` or pass the raw command through `rtk proxy`:

```bash
rtk proxy rg -n --glob "*.md" "pattern" path
```

## Doc-Only Validation

Use for markdown, routing, task packet, and context-pack edits.

```bash
rtk grep "referenced/path" AGENTS.md custodian/AGENTS.md custodian/docs/ai_context
rtk find custodian/docs/ai_context -maxdepth 3 -type f
```

Check:

- referenced files exist or are explicitly described as future work
- `CURRENT_STATE.md` reflects meaningful workflow/status changes
- `FILE_INDEX.md` indexes new docs, prompts, task packets, and ownership changes
- task packet status and completion notes match the actual work state when a packet exists

## Godot Runtime Validation

Use for runtime GDScript, scene wiring, autoload, input, or gameplay behavior changes.

```bash
cd custodian
godot --headless --quit
```

Use import first when scenes/assets/resources changed:

```bash
cd custodian
godot --headless --import --quit
godot --headless --quit
```

Known caveat: current headless validation may exit with existing object/resource leak warnings. Treat new parse errors, missing resources, broken script loads, or changed fatal errors as blockers.

For Sundered Keep asset wiring specifically:

```bash
cd custodian
godot --headless --script tools/validation/sundered_keep_asset_smoke.gd
```

This instantiates the authored Sundered Keep connected map and fails if any `Sprite2D` in the slice has a missing texture.

For fabrication terminal readability / work-order translation changes:

```bash
cd custodian
godot --headless --script tools/validation/fabrication_terminal_readability_smoke.gd
```

This validates the live FABRICATION terminal translation layer, the readable next-action text, and the `BUILD PLACE <ready_build_id>` placement alias against the runtime autoloads.

## Manual Godot Validation

Use when behavior requires play, input, camera, animation, UI, collision, or visual confirmation.

```bash
cd custodian
godot
```

Check the specific acceptance path from the task packet when one exists; otherwise use the active spec and task request. For runtime gameplay changes, include deterministic concerns in the result notes: fixed-step simulation ownership, input mapping, and whether UI/rendering stayed out of simulation authority.

## Sprite Pipeline Validation

Use for sprite intake, runtime animation slices, and curated operator resources.

Read first:

- `custodian/content/sprites/_pipeline/README.md`
- `custodian/docs/ASSET_LAYOUT_CONVENTION.md`

Typical dry-run shape:

```bash
cd custodian
python tools/pipelines/ingest.py --dry-run <manifest_or_source>
```

Only run non-dry-run ingest when generated files are intended. Successful non-dry-run ingests may stage generated files by default; use `--no-git-add` when inspecting outputs without staging.

## Runtime-Ready Asset Drop Validation

Use for already-runtime-ready assets that do not require specialized sprite processing:

```bash
python custodian/tools/pipelines/runtime_ready_assets.py --dry-run
python custodian/tools/validation/runtime_ready_asset_pipeline_smoke.py
python custodian/tools/pipelines/runtime_ready_assets.py --apply --godot-import
```

The apply command rejects different existing targets unless `--replace` is intentionally supplied.

## Tile Pipeline Validation

Use for wall tile extraction, composition, and procgen wall atlas bridge work.

```bash
python3 -m py_compile tools/tiles/extract_wall_parts.py tools/tiles/compose_wall_variants.py tools/tiles/build_procgen_wall_atlas.py
```

Then run the specific generator command documented in the relevant design or README file.

## Fabrication Balance Pipeline Validation

Use for the offline fabrication/resource economy simulator and proposal generator.

```bash
python -m py_compile custodian/tools/balance/fabrication_balance_pipeline.py
python custodian/tools/balance/fabrication_balance_pipeline.py --seeds 100
```

Check:

- `reports/fabrication_balance/fabrication_balance_report.md` exists and lists affordability, optimality, bottlenecks, and lore-drop review.
- `reports/fabrication_balance/proposed_changes.json` is proposal-only JSON and does not imply runtime data was applied.
- Lore violations are understood before using `--strict-lore` in automated checks.

## Review Validation

Use for code review, docs drift review, or handoff review.

```bash
rtk git status
rtk git diff
rtk grep "changed_symbol_or_path" custodian design
```

Findings should prioritize:

- behavior regressions
- determinism risks
- simulation/UI authority leaks
- stale paths or docs drift
- missing validation
- unsafe staging or commit assumptions

## When Validation Is Deferred

If a feasible validation step cannot run, record it in the task packet completion notes when a packet exists, or in the final handoff otherwise:

- command that was skipped or failed
- reason
- risk left behind
- exact next validation command
