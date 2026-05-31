# CUSTODIAN Content Layout

This directory is the Godot-visible content root. Paths here are `res://content/...`, so moving runtime files requires updating every scene, script, resource, manifest, and `.import` sidecar that references the old path.

## Stable Domains

```text
content/
  _aseprite/        # .aseprite/.ase source files mirrored from their target content path
  _pipeline/        # staging/history for ingest tooling; never runtime authority
  ammo_types/       # data-only ammo definitions
  animations/       # animation metadata and authored sequence data
  dialogue/         # authored dialogue JSON
  doors/            # door assets and sidecars by set
  fabrication/      # fabrication recipes and schemas
  images/           # review/demo images only; not a new runtime asset target
  items/            # item and lore data
  levels/           # authored level/layout JSON
  masters/          # large source/master sheets, not direct runtime targets
  metadata/         # shared generated or authored metadata
  mods/             # mod data surfaces
  procgen/          # procgen content packs and special-room content
  props/            # prop definitions, prop scenes, prop-owned runtime art
  reference/        # generated art reference sheets
  resources/        # resource and economy data
  runtime/          # generated runtime catalogs/packs that are not sprite/tile specific
  sprites/          # runtime/source sprite art organized by owner
  structures/       # structure content by set
  tiles/            # TileSet sources, runtime tile art, and tile-pipeline outputs
  ui/               # HUD, terminal, inventory, and UI skin assets
  unregistered/     # quarantine for imported art not yet assigned to a runtime domain
  vehicles/         # vehicle registry data
  walls/            # wall content packs not owned by tiles/walls
  weapons/          # weapon registry data and weapon content
```

## Placement Rules

- New runtime art should land in the owning domain, not loose at `content/`, `content/sprites/`, or `content/tiles/`.
- New source art should land under a `source/` folder or `content/_aseprite/` for `.aseprite` / `.ase` files.
- Generated runtime outputs should live under `runtime/`, `sprites/**/runtime/`, or a feature-specific generated folder documented by a local README.
- `_pipeline/`, `source/`, `masters/`, `reference/`, and `legacy/` folders are not runtime authority unless a local README says otherwise.
- `unregistered/` is a quarantine. Before an asset becomes runtime-authoritative, move or regenerate it into the owning domain, update references/manifests, and reimport through Godot.

## Duplicate Policy

Exact duplicates are not automatically safe to remove. The content tree intentionally retains duplicates for:

- ingest history under `_pipeline/archive/` and `_pipeline/normalized/`;
- source/runtime pairs while imports and manifests are being verified;
- `legacy/` generated copies kept for reproduction or compatibility;
- compatibility paths that still satisfy old scenes or scripts.

Use `python3 custodian/tools/validation/content_asset_audit.py --limit 20` from the repository root to inspect duplicate groups and loose files before moving or deleting content.
