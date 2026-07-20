# Agent Tooling By Ask

Last updated: 2026-06-19

Purpose: give agents a fast routing table for which repo tools to use for a specific ask. This complements `VALIDATION_RECIPES.md`: use this file to pick the tool, then use validation recipes to decide how much proof is needed.

## Modular Operator Asset Audit

Use this section when the ask is about new Operator modular animation drops, missing modular parts, upper/lower visual fit, or source/runtime review for `custodian/content/sprites/operator/new_operator/modular/`.

### Production Coverage Contract

Use first for "what Operator modular animation coverage is missing, suspicious, or ready?":

```bash
python custodian/tools/validation/operator_animation_contract_report.py
python custodian/tools/validation/operator_animation_contract_report.py --json
python custodian/tools/validation/operator_animation_contract_report.py --strict
```

What it does:

- Reads `custodian/tools/validation/contracts/operator_modular_core.json`.
- Scans modular source sheets, generated runtime modules, and action-runtime strips.
- Reports OK required assets, missing required/optional assets, suspicious metadata, extra assets, source/runtime drift, and suggested next production batches.
- Uses `--strict` only when missing/suspicious required coverage should fail validation.

How to interpret it:

- Treat this as the current default production coverage report.
- A strict failure can be acceptable when art is genuinely incomplete. Do not create placeholder art to make it pass.
- Edit the JSON contract when the expected production coverage changes.

### General Action Preview

Use when the ask is "show this Operator action/sequence from the generated runtime assets":

```bash
python custodian/tools/pipelines/operator_action_preview.py --loadout unarmed --action block_loop_01 --directions e,w --include-fx
python custodian/tools/pipelines/operator_action_preview.py --loadout unarmed --sequence fast_windup_01,fast_strike_01,fast_recovery_01 --include-fx
```

What it does:

- Composites lower_body + upper_body when both exist.
- Falls back to combined/full-body action-runtime strips when modular body parts are absent.
- Optionally overlays upper_fx/action FX.
- Writes review-only strips, a combined grid, and a JSON report under `custodian/animation_review/`.

How to interpret it:

- Use it for QA preview, not resource generation.
- Missing layers are reported rather than invented.

### New Character Checklist

Use when the ask is to plan first animation coverage for a new modular-compatible character or enemy:

```bash
python custodian/tools/pipelines/scaffold_character_contract.py --owner enemy_ritualist --template humanoid_combat --frame-size 96 --directions s,se,e,ne,n,nw,w,sw
```

What it does:

- Writes checklist, suggested contract, and expected filename files under `custodian/content/sprites/_pipeline/requests/<owner>/`.
- Does not generate PNGs or runtime registration.

### Legacy First-Pass Inventory

Use:

```bash
python3 custodian/tools/operator/check_operator_modular_assets.py --json-out operator_asset_audit.json
```

What it does:

- Scans the modular Operator source root, defaulting to `custodian/content/sprites/operator/new_operator/modular`.
- Expands an editable expected asset set from inside the script or from `--expected-json`.
- Reports missing expected files, wrong-folder matches, malformed names, unexpected Operator PNGs, and dimension mismatches.
- Can write JSON with `--json-out` and Markdown with `--md-out`.

Historical sample from 2026-06-18 (not current repository state; rerun the command for live counts):

- `expected_files`: 104
- `found_operator_pngs`: 180
- `missing_expected`: 95
- `malformed_operator_pngs`: 58
- `dimension_mismatches_vs_expected`: 2
- `dimension_mismatches_vs_filename`: 19
- JSON refreshed at repo root: `operator_asset_audit.json`

How to interpret it:

- Treat this as the recommended first tool for "what modular Operator assets are present or missing?"
- Do not use the default expected set as a universal CI gate yet. It is intentionally ask-specific and currently scans generated/review folders too, so "unexpected" and "malformed" can include legacy review outputs, compatibility names, or intentionally generated recombinator files.
- For a focused production request, export the default expected JSON with `--write-default-expected`, edit that JSON to the requested suite, then rerun with `--expected-json`.

### Upper/Lower Combination Preview

Use:

```bash
bash custodian/tools/operator/refresh_combo_check_src.sh
python3 custodian/tools/operator/modular_combo_check.py --src /tmp/custodian_combo_check_src --check-dir .ai/operator_modular_combo_check --clean --fit-debug
```

For a ranked “what should I fix next?” report joined to the production contract:

```bash
bash custodian/tools/operator/refresh_combo_check_src.sh
python3 custodian/tools/operator/modular_combo_check.py \
  --src /tmp/custodian_combo_check_src \
  --check-dir .ai/operator_modular_combo_check \
  --clean \
  --fit-debug \
  --fit-gap-threshold 3 \
  --fit-center-threshold 5 \
  --chain fast_windup_01,fast_strike_01,fast_recovery_01 \
  --next-actions \
  --next-actions-max 20
```

To refresh fit evidence and recommendations without regenerating preview PNGs/GIFs:

```bash
python3 custodian/tools/operator/modular_combo_check.py \
  --src /tmp/custodian_combo_check_src \
  --check-dir .ai/operator_modular_combo_check \
  --fit-report-only \
  --fit-debug \
  --next-actions
```

What it does:

- `refresh_combo_check_src.sh` rebuilds `/tmp/custodian_combo_check_src` as a symlink workspace with `lower/` and `upper/` folders.
- `modular_combo_check.py` combines upper and lower modular sheets for visual review.
- Locomotion upper sheets pair with matching lower locomotion; action upper sheets fan out across lower locomotion domains.
- With `--fit-debug`, it reports alpha bounding-box edge gaps and horizontal center deltas.
- With `--next-actions`, it invokes `custodian/tools/operator/operator_next_actions_report.py`, joins fit evidence to `operator_modular_core.json` plus the production coverage reporter, and writes `reports/next_actions.json` and `reports/NEXT_ACTIONS.md` before embedding the top recommendations in `index.html`.
- Pair and chain records retain resolved canonical source paths rather than temporary symlink/workspace paths.

Historical sample from 2026-06-18 (not current repository state; rerun the command for live counts):

- Refresh source produced `48 lower + 48 upper = 96 total`.
- Combo check produced `96` reviews at `.ai/operator_modular_combo_check/index.html`.
- Fit-debug flagged `77/96` pairings over the default `3px` gap threshold.
- The only runtime warning observed was a Pillow deprecation warning for `Image.getdata`; it did not block output generation.

How to interpret it:

- Use this when the ask is "show me upper/lower combinations," "does this modular action fit on locomotion?", or "generate review GIFs for art fit."
- The script expects a source directory with literal `lower/` and `upper/` children. Do not point it directly at the canonical modular root unless you first build that shape with `refresh_combo_check_src.sh`.
- Fit-debug is a visual triage signal, not gameplay authority. Confirm important results by opening the generated review page.
- The next-actions report is generated evidence, not project authority. Contract group membership/required status comes from `operator_modular_core.json`; change that contract rather than hard-coding new priorities into the preview script.

### Body And FX Pair Review

Use:

```bash
python3 custodian/tools/operator/review_modular_body_pairs.py \
  --root custodian/content/sprites/operator/new_operator/modular/fast_attack \
  --out .ai/modular_body_pair_review_fast_attack \
  --fit-debug
```

What it does:

- Recursively pairs modern modular body names such as `modular_lower_body`, `modular_upper_body`, and `modular_upper_fx`.
- Generates combined strips, review sheets, GIFs, an HTML index, and a JSON manifest.
- Supports offset controls and `--strict` if missing pairs should fail the run.
- Supports `--fit-debug`, `--fit-verbose`, and `--fit-gap-threshold`, matching the alpha-bounding-box gap/center analysis from `modular_combo_check.py`.

Historical sample from 2026-06-18 after adding fit-debug (not current repository state; rerun for live counts):

- Produced `39` pair reviews at `.ai/modular_body_pair_review_fast_attack/index.html`.
- Reported incomplete pairs for the malformed `operator__PART__unarmed__fast_windup_01__w__3f__9\t.png` key and several upper-only `run_01` files.
- Fit-debug flagged `38/39` pairings over the default `3px` gap threshold.

How to interpret it:

- Use this for canonical modular review work, especially action folders like `fast_attack`, `block`, `sidearm`, or `ranged`.
- Prefer this over `review_modular_flat_png_pairs.py` for current modular Operator source naming.
- If E/W frame width is actually `128` but the filename says `96`, rerun that subset with `--frame-width 128` or inspect the generated manifest warnings before using outputs as runtime candidates.

### Flat PNG Pair Review

Use only for legacy flat sheet exports shaped like `*upper*__sheet.png` and `*lower*__sheet.png` in the same root:

```bash
python3 custodian/tools/operator/review_modular_flat_png_pairs.py --root <flat-sheet-root> --out .ai/modular_flat_png_pair_review
```

Historical sample from 2026-06-18 (not current repository state; rerun for live counts):

- Running against `assets_review` produced `0` pair reviews.
- Repo-wide scan found no obvious current modular Operator inputs ending in the script's expected `__sheet.png` pattern.

How to interpret it:

- Treat this as legacy or special-case tooling.
- Do not use it as the default modular Operator review path.
- It may still be useful if an external export batch arrives with flat upper/lower filenames that include `upper` or `lower` and end in `__sheet.png`.

## Related Runtime Validation

After modular asset routing or runtime playback changes, use the focused Godot smoke when the change reaches live Operator presentation:

```bash
cd custodian
godot --headless --script tools/validation/operator_modular_layers_smoke.gd
```

For pipeline naming/routing changes, use:

```bash
python custodian/tools/validation/operator_modular_pipeline_smoke.py
```

For visual-only review output generation, an HTML/manifest output check is usually sufficient unless the generated assets are promoted into `res://content/` runtime paths.
