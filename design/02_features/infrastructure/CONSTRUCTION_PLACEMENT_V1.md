# Construction Placement V1

**Project:** CUSTODIAN

**Status:** active implementation
**Authority:** `COMPOUND_INFRASTRUCTURE_SYSTEM.md`

## Goal

Deliver one production permanent-infrastructure placement loop:

```text
Capacitor Bank Ready Build
→ close terminal
→ preview true 3×2 footprint in the Fabrication Yard
→ validate and commit atomically
→ foundation / construction / commissioning
→ +250 reserve capacity
```

This is a bounded compound-construction slice, not unrestricted survival/base
editing. The structure catalog remains limited to `capacitor_bank_mk1`.

## Ownership

- `FabPipeline`: fabrication jobs and resource payment.
- `BuildInventory`: unplaced Ready Build tokens.
- `ConstructionCatalog`: permanent build ID to definition/scene resolution.
- `ConstructionPlacementController`: preview state, validation, rotation,
  transactional commit, cancellation, and placement signals.
- `ConstructionPlacementValidator`: pure/read-only footprint, zone, floor,
  occupancy, Operator-clearance, and reserved-path checks.
- `ConstructionZone2D`: authored construction boundary and supported tags/categories.
- `ConstructionPlacementPreview`: world presentation only.
- `ConstructionPlacementHUD`: player-facing mode/status presentation only.
- `InfrastructureStructure`: post-commit construction lifecycle.
- `InfrastructureRegistry`: placed identity and services.
- `Power`: grid registration and reserve behavior.
- `TurretPlacement`: Basic Turret and Light Barricade compatibility only.

## Placement Contract

- Grid origin snaps to 32×32 world pixels.
- `StructureDefinition.footprint_tiles` is authoritative.
- Capacitor Bank is 3×2 at 0°/180° and 2×3 at 90°/270°.
- The complete footprint must fit inside one compatible, enabled construction zone.
- Every footprint sample must resolve to live walkable floor authority.
- Static structures, turrets, construction blockers, reserved paths, the
  Operator clearance radius, and enemies inside the footprint reject placement.
- Canonical rejection IDs are `outside_construction_zone`, `unsupported_zone`,
  `invalid_floor`, `occupied`, `operator_clearance`, and `reserved_path`.
- Invalid movement/click, rotation, and cancellation never consume a token.

## Commit Contract

```text
revalidate
→ instantiate off-tree
→ remove exactly one token
→ add to World at snapped transform
→ begin_construction()
→ emit committed
→ leave construction mode
```

Failure before token removal frees the off-tree instance. Failure after token
removal refunds exactly one token and removes the incomplete instance. The
controller never charges raw resources or directly changes Power reserve.

## UI Contract

Launching from FABRICATION closes the complete terminal and restores world
input. The dedicated construction HUD shows name, Ready count, footprint,
rotation, primary validation reason, and controls. Cancel reopens FABRICATION;
successful commit returns to ordinary world HUD without reopening the terminal.

## Initial Zone

`FabricationConstructionZone` is a bounded 384×320, 32px-aligned yard centered
on generated compound service-area floor near the Field Fabricator. It supports
power/fabrication categories and compound/fabrication site tags. Its faint
boundary is visible only during permanent construction mode.

## Generated Contract Spatial Authority

Procgen owns semantic tile anchors for persistent contract-world population.
`ContractWorldLoader` owns their canonical tile-to-world conversion and applies
the resulting runtime transforms to the existing authored nodes. The Field
Fabricator and `FabricationConstructionZone` own behavior after placement, but
do not author their runtime positions when generated contract authority is
present; scene transforms are editor/fallback defaults only.

The level-data keys are `compound_fabricator_anchor` and
`compound_construction_zone_anchor`. Both are deterministic `Vector2i` values
inside authoritative generated floor and outside generated walls, ocean, and
chasm authority. A missing or invalid anchor is diagnosed once and never
silently converted to world origin.

## Out of Scope

Additional structures, walls/floors/roofs, cables, upgrades, moving,
demolition/refunds, save migration, builders/drones, and production art.

## Acceptance

- Permanent Capacitor placement never routes through `TurretPlacement`.
- True footprint, rotation, zones, floor, and occupancy are validated before click.
- Exactly one token produces exactly one construction-state structure.
- Cancellation and invalid placement preserve the token.
- Capacitor storage activates only after commissioning.
- Permanent construction never uses the crushed 120px terminal shell.
- Tactical turret/barricade behavior remains intact.
- Focused controller, validator, UI, construction, fabrication, power, and
  tactical regressions pass.
- Persistent construction population matches its semantic anchors through the
  procgen map's canonical transform, and both anchors remain generated floor.
