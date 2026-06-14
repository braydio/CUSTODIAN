# Runtime-Ready Asset Drop

- Status: `complete`
- Authority: `design/04_architecture/SPRITE_PIPELINE_SYSTEM.md`, `custodian/docs/ASSET_LAYOUT_CONVENTION.md`
- Goal: Add one persistent, safe intake surface for already runtime-ready assets and route them into organized `content/` destinations without bypassing specialized sprite processing.
- Files: `custodian/asset_drop/runtime_ready/`, `custodian/tools/pipelines/runtime_ready_assets.py`, pipeline/layout docs, validation.
- Constraints: Intake must stay outside `res://`; no implicit overwrite; processed source provenance must persist; specialized sprite sheets retain their existing pipeline.
- Acceptance: Dry-run is non-mutating; apply routes mirrored and explicit targets; conflicts reject by default; replace is explicit; processed inputs archive with receipts; smoke validation passes.
- Completed: Added the persistent drop tree, mirrored and sidecar routing, conflict-safe apply, explicit replacement, source archives, JSON receipts, optional Godot import, smoke validation, and workflow documentation.
- Deferred: Automatic classification of ambiguous root-level assets remains intentionally unsupported; specialized sprite processing remains in the existing sprite pipeline.
