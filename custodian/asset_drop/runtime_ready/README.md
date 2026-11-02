# Runtime-Ready Asset Drop

This is the persistent intake area for assets that are already ready for Godot to import.
It lives outside the Godot `res://` project tree so dropped files do not become accidental
runtime authority before they are routed.

## Fast Path

Mirror the intended `content/` destination under `inbox/`:

```text
asset_drop/runtime_ready/inbox/
  sprites/enemies/new_enemy/runtime/body/new_enemy_idle.png
  tiles/roads_paths/runtime/roads/new_road_tile.png
  ui/black_reliquary/icons/new_icon.png
  audio/encounters/ash_bell/new_bell_hit.ogg
```

Run from the repository root:

```bash
python custodian/tools/pipelines/runtime_ready_assets.py --dry-run
python custodian/tools/pipelines/runtime_ready_assets.py --apply --godot-import
```

Each inbox path maps to `custodian/content/<same path>`.

For continuous routing while working, run:

```bash
custodian/tools/pipelines/watch_runtime_ready_assets.sh
```

The watcher routes files after their write completes. Godot Editor will import accepted
files normally; run the explicit `--godot-import` command for headless workflows.

## Explicit Route

For an asset that cannot be organized by its inbox folder, add a same-name
`.runtime.json` sidecar:

```text
inbox/new_bell_hit.ogg
inbox/new_bell_hit.ogg.runtime.json
```

```json
{
  "targets": [
    "audio/encounters/ash_bell/new_bell_hit.ogg"
  ]
}
```

Targets are always relative to `custodian/content/`.

## Safety Contract

- Existing different runtime files are never overwritten unless `--replace` is supplied.
- Unknown or non-runtime top-level content domains are rejected.
- Exact duplicates are accepted without rewriting the destination.
- Processed inputs and route sidecars move into timestamped `archive/` jobs.
- Rejected or ambiguous inputs remain in `inbox/` and are reported in `logs/`.
- `.import`, `.uid`, hidden files, and unsupported sidecars are ignored.
- Specialized sprite sheets needing frame parsing, compatibility copies, or rebuild hooks still
  belong in `content/sprites/_pipeline/inbox/`.

## Layout

```text
runtime_ready/
  inbox/      # user drop surface
  archive/    # immutable processed-source history by job
  logs/       # JSON receipts for every apply run
  examples/   # route-sidecar examples
```
