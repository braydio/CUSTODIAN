# Operator Modular Ingest Hardening

- Status: `complete`
- Authority: `design/04_architecture/SPRITE_PIPELINE_SYSTEM.md`
- Goal: Make shared sprite inbox ingest reliably route and normalize modular Operator layer sheets beyond the previously hardcoded action set.
- Files: `custodian/tools/pipelines/`, sprite pipeline/module docs, focused validation, AI context.
- Constraints: Preserve source pixels at ingest; prefer explicit loadout/action naming; keep runtime playback registration deliberate and state-machine-owned.
- Acceptance: Block/defense and wardrobe-cape sheets route through modular post-processing; generic actions produce stable runtime modules; legacy source names remain accepted; focused validation passes.
- Completed: Generalized modular layer routing and post-process selection; added action-family source buckets; normalized generic modular actions into stable runtime modules; generated/imported current block and ranged-aim modules; added opt-in superseded-animation cleanup across source outputs and generated modules; wired unarmed block entry/hold/blocked-hit/exit into the live modular Operator stack; registered the supplied parry FX without enabling deferred parry gameplay; documented the preferred naming/replacement contracts; added focused smoke coverage.
- Deferred: Parry/counter gameplay and its FX trigger remain deferred. Upper-body block entry needs a west-facing source clip to avoid the current base/right fallback.
