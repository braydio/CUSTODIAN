# Road Semantics V2 Restore + Presentation Closeout

## Starting state

Started from `origin/main` at `78645570bd5a8847e1137491256c15b56bdb30e2` in an isolated task worktree. Commit `bd5bc493` accidentally removed Road Semantics V2 runtime wiring, natural soft-path material behavior, and validation ownership while carrying unrelated Operator work. Those Operator changes were not reverted.

## Restoration and presentation

Restored the Road Semantics resolver integration and its exports/observability, foliage query, constructed-surface movement query, service hardstand material input, natural `soft_path` material semantics, macro claims, and `procgen_road_semantics_v2` manifest ownership. Kept `intent_main_roads_enabled = false` in production.

Generalized the existing 15-role filled-surface classifier to accept an arbitrary cell dictionary while retaining `_classify_road_surface_role()` as the archived renderer wrapper. Production ruined fragments now spawn presentation-only decals under a distinct `ruined_road` key using the existing pack. Archived wide roads use `road`; soft paths retain `path`. Chunk unload/reveal removes and reconstructs all three independently. No overlay material was added for ruined roads, and no gameplay/topology authority changed.

## Fixed-seed review

Seed `824790`: 4 fragments, 115 ruined-road cells, 115 matching `ruined_road` decals. Production wide roads were disabled. All 13 existing surface roles were represented. Route audit passed with minimum route width 17 and no violations. Captures:

- `reports/procgen_road_semantics_v2/seed_824790_overview.png`
- `reports/procgen_road_semantics_v2/seed_824790_road_fragment_detail.png`
- `reports/procgen_road_semantics_v2/review_manifest.json`

The visual detail shows the existing masonry surface pieces forming intermittent constructed remnants against natural ground; no macro art or continuous highway is used. The capture is a procgen review viewport with debug grid/terrain context, not a final gameplay camera review.

The bounded service-apron sample checked seeds `824790` through `824797` and found none: `NO_ELIGIBLE_APRON_IN_BOUNDED_SAMPLE`. Synthetic resolver/material coverage verifies the apron contract; no geometry was altered to manufacture an example.

## Validation

- `procgen_road_semantics_v2`: passed; verified natural biome materials for generic soft paths, explicit ruined-road/hardstand classification, unchanged floor/wall/route/elevation authority, distinct decal keys, role metadata, one decal per visible ruined cell, and streaming unload/reveal determinism.
- `procgen_surface_materials`: passed.
- `procgen_road_surface_roles_smoke.gd`: passed after explicitly opting into archived wide roads; the test now counts the distinct `road` key rather than conflating it with `ruined_road` decals that share the same art directory.
- `git diff --check` and validation manifest JSON parse: passed.

The `--changed --list` selector expands this procgen façade change to well over
100 validators across unrelated subsystems. With only about 5.5 GiB available
and an unrelated Godot editor active, the broad sweep was not launched; task
owned integration and surface-material validators were run directly instead.

Godot emitted a deterministic stuck-pocket collision cleanup warning during
fixed-seed generation and shutdown ObjectDB/resource leak warnings in smoke /
review processes; test exit codes were successful. The first archived-road
smoke run exposed the shared-texture-directory counting bug above; the
assertion was corrected and the rerun passed. A later brief smoke rerun caught
a removed constant still referenced by the manifest check; the constant was
restored and the final rerun passed.

## Documentation and remaining work

Updated `STARTER_MAP_PROCGEN.md`, `SURFACE_MATERIALS_V1.md`, `CURRENT_STATE.md`, `FILE_INDEX.md`, and `REQUIRED_ASSETS.md` to describe route-owned connectivity, intermittent semantic roads, natural soft paths, hardened service apron, disabled production wide-road carving, and reuse of the existing 15-piece presentation grammar. No new production road art was approved. Replacement art remains deferred until this pack is judged in ordinary gameplay.

No changes were made to unrelated Operator work, road resolver design, route topology, collision/navigation, or movement tuning. The task diff preserves `agent_workflow_contract` validation-manifest ownership.
