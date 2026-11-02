# Ash-Bell Wall Composition — First Implementation Pass

Status: complete (2026-08-31).

## Inputs

Installed files:

- `custodian/content/metadata/assets/meridian_civic_wall.semantic.json`
  - source: `meridian_civic_wall_semantic_manifest_v2.json`
- `custodian/tools/art/build_meridian_civic_wall_runtime_catalog.py`
- generated:
  `custodian/game/world/levels/authored/ash_bell/common/meridian_civic_wall_runtime_catalog.gd`
- `custodian/game/world/levels/authored/ash_bell/common/ash_bell_wall_composition_first_pass.json`

Use the correctly repacked 512×512 wall atlas where logical 14×14 source coordinates map directly to runtime coordinates 0..13.

## Directional review result

The previous 43 `review_required` modules are resolved.

- Clear corners/junctions with reliable cardinal continuation are now marked `auto_compose=true` with exact N/E/S/W ports.
- Slopes, stairs, damage, rubble, composite corners, and ambiguous diagonal/channel modules are deliberately `manual-only`.
- This is intentional. Do not weaken that fail-closed rule.
- No runtime rotation or mirroring.

The v2 manifest contains 80 auto-safe modules and 116 explicit/manual modules.

## Runtime rule

The semantic JSON is build-time authoring metadata. Generate the static GDScript catalog and use that at runtime.

Do not parse the semantic manifest from the live gameplay presenter.

Generate:

```bash
cd custodian
python3 tools/art/build_meridian_civic_wall_runtime_catalog.py \
  content/metadata/assets/meridian_civic_wall.semantic.json \
  game/world/levels/authored/ash_bell/common/meridian_civic_wall_runtime_catalog.gd
```

## First visual production pass

Patch `meridian_civic_art_presenter.gd`.

1. Do not use broad near-black `draw_rect()` as the visible wall mass.
2. For each authored mass in `ash_bell_wall_composition_first_pass.json`:
   - fill the full rect with floor-atlas roof source `(8,0)`;
   - draw the exact north cap run `(0,0)`;
   - draw the exact south/player-facing facade specified by the layout.
3. Do not add the old sparse interior wall-detail grid.
4. Do not call `Palette.choose()` for wall topology.
5. Special arches/doors/damage remain explicit authored placements.

Lower Quarter exact first-pass masses:
- `Rect2i(48,66,10,18)`
- `Rect2i(70,68,10,16)`
- `Rect2i(26,55,6,25)`

This patch changes presentation only. Preserve collision, navigation, blockers, route state, props and walkable geometry.

## Auto-composer contract

When later tracing an exposed boundary:

1. Calculate desired port signature from authored boundary neighbors.
2. Ask the static catalog only for entries with:
   - `auto=true`
   - exact matching `topology`
   - desired semantic family
3. Pick deterministically inside that exact compatible list.
4. If no exact compatible entry exists, fail closed and report the boundary for explicit authoring.
5. Never substitute a damaged, opening, slope, stair, door, gate or manual-only module.

## Validation

Add/extend a smoke validating:

- manifest schema v2
- exactly 196 logical entries
- all runtime coords are 0..13
- runtime rows/cols 14–15 unused
- all former review-required entries now have a completed composer decision
- `auto=true` entries have nonempty ports
- manual-only entries are never returned by automatic variant lookup
- no runtime rotation/mirroring
- three Lower Quarter mass rects remain unchanged
- old sparse interior wall-detail loop removed
- gameplay collision/navigation unchanged

Capture Lower Quarter arrival/direct-route view at gameplay scale.

PASS when:
- the two direct-route flanks read as large continuous architecture rather than black void;
- the evacuation arcade reads as a structure;
- no random wall fragments float inside the mass;
- the existing coherent floor remains intact;
- native props remain unchanged.

## Completion record

The V2 manifest, topology-review CSV, deterministic catalog generator, generated
Godot catalog, and first-pass composition are installed at the paths above.
`MeridianCivicArtPresenter` uses the three exact mass rectangles, floor-atlas
roof source `(8,0)`, continuous cap `(0,0)`, retaining face `(1,4)`, and six
explicit arcade modules. The former sparse interior facade loop is removed.
Collision, navigation, blockers, native props, and walkable geometry were not
changed. Automated validation is recorded in the task completion response;
gameplay-scale aesthetic approval remains developer-owned.

## Supersession note — 2026-09-02

The reviewed Gothic-future native module packet extends Lower Quarter visual
presentation without replacing the 32px topology substrate or its authority.
Multi-cell facades, piers, and collapse modules must not be flattened into the
existing wall atlas.
