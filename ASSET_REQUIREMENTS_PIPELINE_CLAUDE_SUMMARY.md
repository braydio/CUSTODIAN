# Asset Requirements Pipeline — Implementation Summary

## Delivered

- Migrated the live Markdown tracker into `custodian/content/metadata/assets/required_assets.registry.json`. The parser read `origin/main`'s 115 rows, generated unique semantic IDs, and preserved section, title, target, purpose, and notes for every row. It handled both five-column asset rows, three-column Tiled rows, and the literal pipe in a code-formatted note.
- Added `asset needs`, ID detail, JSON, deterministic `--write`, and read-only `--check`; Asset V2 status derives from `get_family_status()` and requested authored/mirrored directions. The root Markdown is now generated and excludes fulfilled Asset V2 rows without deleting their registry entries.
- Added registry/link/projection validation to `asset doctor` and a focused temporary-fixture smoke registered in the validation manifest.
- Linked the three specified live families/states. Current statuses: Reliquary connector **fulfilled**; Opossum south `waddle` + `scurry` **needed**; Vaultwing bonding suite **partial**.
- Updated active pipeline/manifest/current-state/index/validation docs to identify the registry as the requirement authority and family contracts as technical authority.

## Measurements and evidence

- Source rows: **115**. Registry rows after migration: **115**. Generated active Markdown rows: **114** (one derived fulfilled row filtered).
- All 115 migrated title/target/purpose/notes/section values compared equal against `git show origin/main:REQUIRED_ASSETS.md`.
- Passed: `asset_requirements_smoke.py`, `asset_pipeline_cli_ux_smoke.py`, `asset_pipeline_v21_production_smoke.py`, `asset_pipeline_v2_smoke.py`, `asset needs --check`, and `git diff --check`.
- `asset doctor` exits successfully with no errors. It retains one pre-existing warning for 12 PNGs in the unregistered Operator inbox.
- The requested `run_validation.py --changed --max-tier unit --json` selected 7 unit checks: 6 passed; `lattice_canon_docs` failed because untouched `design/03_world/LATTICE_DOCTRINE.md:312` contains the retired phrase “temporary continuity pockets.” The same phrase exists at that line in `origin/main`, so this is baseline drift unrelated to the asset change. No broad actor/integration sweep was run.

## Negative controls and rough edges

- A north-authored Opossum strip did not satisfy the south-only target; it remained `needed` until south art appeared.
- Unknown schema, duplicate ID, unknown route, missing family/state, out-of-policy direction, and empty target-list fixtures fail validation. Missing production art itself does not fail requirement doctor checks.
- The first generated projection check caught a stale source-authority header during implementation; regeneration corrected it and the subsequent check passed.
- Non-V2 requirements remain declared-status records; no audio/Tiled/Operator ingestion adapters, automatic `asset next`, or additional family guesses were added.

Moment Forge: not run — tooling, data, and documentation only.
