# Twin Solaria Runtime V1

## Workstream identity

- Workstream: `twin-solaria-runtime-v1`
- Branch: `agent/twin-solaria-runtime-v1`
- Donor preserved intact: `codex/twin-solaria-runtime-v1a@58fc0b3b`
- Chat: **Review Design Changes**
- Last relevant chat activity: **2026-09-27** (15:26 EDT)
- Status: extracted / reconciliation

## Goal

Isolate and land the production Twin Solaria V1 authored-level runtime work without carrying Awakening connector, Operator, Vaultwing, procgen-review, audio, or root-scratch changes from the mixed donor branch.

The production target is the registered `hub_twin_solaria` AuthoredLevel using the 2048x1536 Twin Solaria coordinate authority, Asset V2 plates/fidelity underlay, authored boundary collision, dormant semantic readouts, and standalone playtest coverage.

## Authority and preservation

- Preserve the Twin Solaria canon and landmark layout in `design/05_levels/TWIN_SOLARIA.md`.
- Keep the old backdrop/V1-A scenes as development review surfaces only.
- Runtime must not reference `asset_drop/`.
- Do not activate a Passage, Crown-class traversal, Solarium II reconstruction, or route adjudication in this slice.
- Reuse existing authored-level, camera, level-registry, and route authorities. Do not create parallel global state.

## Extracted implementation surface

Primary owned surfaces:

- `custodian/game/world/levels/authored/hub/twin_solaria/`
- `custodian/content/levels/hub/twin_solaria*`
- `custodian/content/metadata/assets/families/twin_solaria_v1_*.asset.json`
- `custodian/asset_drop/source_work/hub/twin_solaria_v1_*/`
- Twin Solaria focused validation and production-level documentation
- shared read-only interaction/camera seams only where the Twin level actually consumes them

## Acceptance

1. Production Twin Solaria opens as an AuthoredLevel at native 2048x1536 authority.
2. Required plate placements and the fidelity underlay retain exact registration and native scale.
3. Boundary collision and dormant readouts are authored-level owned.
4. No Awakening connector art/runtime or Operator fast-chain files are carried by this branch.
5. Focused Twin Solaria, level-registry, asset, camera seam, and docs validation pass.
6. Any shared registry/doc changes are regenerated/reconciled against current `main` before landing.

## Completion report

Report files changed, final runtime/asset contracts, focused tests, any deferred work, and any remaining shared-file reconciliation.
