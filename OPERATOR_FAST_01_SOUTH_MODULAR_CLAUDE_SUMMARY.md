# Operator Fast 01 South Modular Decomposition

- Split the approved 6×96×96 South Fast 01 full-body strip into disjoint lower/upper ownership layers using the established E/W hip seam plus hand-authored South arm/hand regions; no pixel synthesis or resampling.
- Pillow recomposition check and validation smoke both pass byte-identically for all six frames.
- Published the pair through the Operator source-to-runtime sync and rebuilt the canonical SpriteFrames catalog. South Fast 01 now resolves exact South only when both layers exist; South Fast 02–04 retain east fallback.
- Focused unarmed fast-chain and modular-fast-attack Godot smokes pass. `--changed --json` finished 57 passed / 1 failed / 1 skipped; the failure is the unrelated, already-dirty `vaultwing_bond_smoke` approach/bond flow, while procgen and the other selected integration checks passed.
- The approved South full-body source was already changed in the shared worktree relative to HEAD, so that exact baseline and its synced runtime copy are included with the new pair; the FX pixels were not edited by this task.
- Aseprite/Operator MCP authoring was unavailable in this session; layer ownership was encoded as explicit reviewed polygon ownership plus the established y=51 seam.
- Visual in-game composition review is still recommended despite pixel-identical reconstruction proving no visual difference from the approved full-body strip.
