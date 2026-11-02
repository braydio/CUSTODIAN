# Twin Solaria V1-A asset foundation salvage

## Landed scope

- Started from current `origin/main` after the Awakening connector landed at `c53160b9b`; used the donor branch only for validated source material and the environment family starting contract.
- Preserved the eight exact 2048×1536-master gameplay crops, the exact master as `fidelity_underlay_source.png`, four reference-only crops, and all 15 flattened landmark crops. SHA-256 checks matched every specified source hash; all 15 landmark hashes matched `MASTER_TRACKER.csv`.
- Recovered `MASTER_TRACKER.csv`, `CROP_MANIFEST.json`, `PLACEMENT_MANIFEST.json`, and a provenance README from the temporary ZIP. Updated the four moved reference-crop paths in the preserved manifests. The root ZIP was removed and is not staged.
- Published eight required `twin_solaria_v1_environment` states and one `twin_solaria_v1_fidelity_underlay` through the current-main Asset V2 pipeline. Runtime output bytes match the preserved source objects exactly; the generated catalog contains eight environment records and one fidelity record. Current Godot import sidecars were generated. Both families have empty consumers.
- No landmark crops were ingested. No standalone Node2D scene/controller/smoke or stale donor import/catalog product was transplanted. Production authored-level runtime remains pending the full runtime packet.

## Validation

- Environment and fidelity plans and dry runs: clean, with exact native dimensions and current Asset V2 routing.
- Asset status: environment 8/8 required; fidelity 1/1 required. Asset doctor has no Twin Solaria errors; it retains one unrelated warning for the existing unregistered Operator inbox.
- Exact source/runtime byte comparisons: 8 gameplay plates and fidelity underlay passed.
- Preserved metadata JSON parse and 15 landmark hash checks: passed. Root ZIP absent.
- `twin_solaria_canon_docs_smoke.py`: PASS. `git diff --check`: PASS.
- `run_validation.py --changed --base origin/main --json`: runner overall `passed=false`; all 6 selected checks passed, with 0 failed, 0 timed out, and 0 infrastructure errors.

## Follow-up for the full runtime task

The donor audit recorded the legacy development-controller expectation at 3500×3000 while the loaded development texture measured 4000×3000. Resolve whether the development source legitimately became 4000×3000 or whether the preview should return to its documented 3500×3000 source. This is development-preview debt; do not change or use it as authority for the production 2048×1536 source.

The old ZIP implementation spec is superseded by current design and the full runtime packet. This commit is an asset foundation only; it does not claim a Twin Solaria V1 production runtime.
