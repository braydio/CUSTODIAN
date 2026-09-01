# CODEX BRIEF — Ash-Bell Lower Quarter Entrance Reauthor V1

Repo:
`/home/braydenchaffee/Projects/CUSTODIAN`

Mode:
**APPLY**

This is an authored Godot-runtime change. Do not inspect or implement against the retired Python simulation.

## Read first

- `AGENTS.md`
- `custodian/AGENTS.md` if present
- `design/05_levels/ASH_BELL_LOWER_QUARTER.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md`
- `custodian/game/world/levels/authored/ash_bell/lower_quarter/lower_quarter.gd`
- `custodian/game/world/levels/authored/ash_bell/common/meridian_civic_art_presenter.gd`
- `custodian/game/world/levels/authored/ash_bell/common/meridian_civic_art_palette.gd`
- `custodian/tools/validation/ash_bell_lower_quarter_floor_atlas_smoke.gd`
- existing native civic/catastrophe placement authorities

Input spec:
`ash_bell_lower_quarter_entrance_reauthor_v1.json`

## Objective

Re-author only the Lower Quarter world entrance into:

**narrow threshold -> broad civic forecourt -> narrow north apron -> existing Direct Personnel Line**

while preserving the canonical failed-direct-route / west-evacuation-detour gameplay.

Do not implement the generated concept-art infographic literally as a straight route into Station IX.

## 1. Geometry patch

In `lower_quarter.gd`, replace this one `WALKABLE_REGIONS` member:

```gdscript
Rect2i(52, 82, 24, 12)
```

with these three members:

```gdscript
Rect2i(60, 90, 9, 4),   # South Threshold
Rect2i(54, 84, 21, 6),  # Entry Forecourt
Rect2i(57, 82, 14, 2),  # North Apron
```

Do not modify:
```gdscript
Rect2i(58,70,12,14) # Direct Personnel Line
Rect2i(38,74,22,8)  # West Detour
Rect2i(32,48,14,32) # Evacuation Arcade
DIRECT_BLOCKER_RECT = Rect2i(55,71,18,4)
```

Keep:
```text
Spawn_FromWorld = (64,87)
Exit_ReturnWorld = (64,91)
Beat_DirectLine = (64,78)
```

Expected geometry delta:
```text
removed walkable cells: 98
added walkable cells: 0
```

## 2. Presenter constants

In `meridian_civic_art_presenter.gd`, retire `ARRIVAL_PLATFORM_RECT`.

Add:

```gdscript
const ENTRANCE_SOUTH_THRESHOLD_RECT := Rect2i(60, 90, 9, 4)
const ENTRANCE_FORECOURT_RECT := Rect2i(54, 84, 21, 6)
const ENTRANCE_NORTH_APRON_RECT := Rect2i(57, 82, 14, 2)
const ARRIVAL_AXIS_RECT := Rect2i(62, 82, 5, 12)
const DIRECT_COLLAPSE_FLOOR_RECT := Rect2i(58, 71, 12, 4)
```

Keep the existing Direct Personnel, West Detour, Arcade, Market, Basin, Wrong Street, Court, East Switchback and Station Threshold constants.

## 3. Exact floor base priority

Patch `_get_lower_quarter_base(cell)` so the entrance/direct-route-relevant priority is exactly:

```gdscript
if DIRECT_COLLAPSE_FLOOR_RECT.has_point(cell):
    return Palette.SRC_ROAD_DARK

if WEST_DETOUR_RECT.has_point(cell):
    return Palette.SRC_ROAD_DARK

if DIRECT_PERSONNEL_RECT.has_point(cell):
    return Palette.SRC_ROAD_GREY

if ARRIVAL_AXIS_RECT.has_point(cell):
    return Palette.SRC_ROAD_GREY

if ENTRANCE_SOUTH_THRESHOLD_RECT.has_point(cell):
    return Palette.SRC_CIVIC_DARK

if ENTRANCE_FORECOURT_RECT.has_point(cell):
    return Palette.SRC_CIVIC_LIGHT

if ENTRANCE_NORTH_APRON_RECT.has_point(cell):
    return Palette.SRC_CIVIC_LIGHT
```

Then continue with the existing unrelated Lower Quarter region logic.

Important:
- West Detour is now dark service/evacuation road `(11,5)`, not grey personnel road.
- The collapsed 12x4 lane under the blocker is dark road `(11,5)`.
- no random source selection.

## 4. Exact entrance wear overrides

Remove entrance-specific overrides that contradict the new layout.

Add exactly:

```gdscript
Vector2i(55,85): Vector2i(5,0),
Vector2i(58,88): Vector2i(6,0),
Vector2i(55,89): Vector2i(5,0),

Vector2i(73,85): Vector2i(5,0),
Vector2i(70,88): Vector2i(6,0),
Vector2i(73,89): Vector2i(5,0),

Vector2i(57,83): Vector2i(6,0),
Vector2i(70,83): Vector2i(5,0),

Vector2i(60,92): Vector2i(10,0),
Vector2i(68,92): Vector2i(10,0),
```

Keep existing non-entrance floor overrides intact.

## 5. Replace entrance/direct-route overlays

In `get_floor_overlay_source_cell(cell)`, make the Lower Quarter entrance/direct route rules exactly:

```gdscript
# direct-route arrows win over centerline
if cell == Vector2i(64,86) or cell == Vector2i(64,78):
    return Palette.SRC_ROAD_ARROW_N

# precinct threshold
if cell.y == 90 and cell.x in range(60,69):
    return Palette.SRC_ROAD_LINE_H_DOUBLE

# forecourt crosswalk
if cell.y == 89 and cell.x in range(62,67):
    return Palette.SRC_ROAD_CROSSWALK_H

# world-entry centerline
if cell.x == 64 and cell.y in range(91,93):
    return Palette.SRC_ROAD_LINE_V_DASH

# forecourt centerline
if cell.x == 64 and cell.y in range(84,89):
    return Palette.SRC_ROAD_LINE_V_DASH

# direct personnel centerline
if cell.x == 64 and cell.y in range(75,84):
    return Palette.SRC_ROAD_LINE_V_DASH

# west evacuation turn
if cell.y == 79 and cell.x in range(40,64):
    return Palette.SRC_ROAD_LINE_H
```

Delete the superseded Lower Quarter entrance rules:
- crosswalk at `y=82, x=62..66`
- arrow `(64,85)`
- old arrival centerline range
- old West Detour line `y=77, x=40..57`

Do not touch unrelated North Ramp / east-switchback / West Gate / Station IX markings.

## 6. Reserved lane

Treat:

```gdscript
Rect2i(62,82,5,12)
```

as a prop-anchor exclusion zone.

No active civic or catastrophe prop anchor may occupy it.

Do not generate collision from this visual rule. It is an authoring/validation constraint.

## 7. Civic prop remap

Update the Lower Quarter native civic placement authority exactly:

```text
KEEP arrival_w_lamp (54,88)
MOVE arrival_e_lamp (75,88) -> (74,88)
KEEP arrival_w_bench (57,85)
KEEP arrival_e_bench (71,85)
KEEP personnel_sign (60,82)
KEEP arrival_directory (69,82)
MOVE arrival_bin (53,85) -> (54,86)
KEEP arrival_bollard_w (58,82)
MOVE arrival_bollard_e (71,82) -> (70,82)
MOVE arrival_drain (58,90) -> (60,89)
MOVE arrival_hatch (72,90) -> (72,89)
MOVE arrival_pier (52,83) -> (57,83)
MOVE arrival_railing (54,83) -> (55,84)
MOVE arrival_chain_railing (73,83) -> (72,84)
MOVE arrival_beacon (73,82) -> (74,84)
```

Do not alter Direct Personnel props outside this arrival list.

## 8. Catastrophe entrance remap

Update the catastrophe placement authority exactly:

```text
DISABLE ruin_arrival_01
MOVE ruin_arrival_02 (56,86) -> (55,87)
KEEP ruin_arrival_03 (59,84)
DISABLE ruin_arrival_04
MOVE ruin_arrival_05 (74,87) -> (73,87)
MOVE ruin_arrival_06 (55,91) -> (60,92)
KEEP ruin_arrival_07 (68,91)
DISABLE ruin_arrival_08
KEEP ruin_arrival_09 (61,90)
DISABLE ruin_arrival_10
DISABLE ruin_arrival_11
MOVE ruin_arrival_12 (75,92) -> (68,93)
```

The entrance should have only seven active catastrophe records after this patch.

Do not change the dense Direct Personnel collapse catastrophe dressing in this task.

## 9. Add ruined facade framing outside walkable floor

Use the new native ruined-facade family.

Add four exact visual placements:

```text
source 62  top-left cell (50,86) scale 1.0
source 64  top-left cell (75,86) scale 1.0
source 129 top-left cell (48,91) scale 1.0
source 140 top-left cell (75,91) scale 1.0
```

Roles:
- west/east nonwalkable facade shoulders
- west/east outer threshold rubble

They must remain outside the walkable entrance union.

No collision from image alpha.

## 10. Navigation / route validation

Add or extend a focused smoke to assert:

```text
(64,87) walkable
(64,91) walkable
(64,78) walkable
(58,80) walkable
(40,75) walkable

(52,88) not walkable
(53,88) not walkable
(75,88) not walkable
(54,92) not walkable
(74,92) not walkable
```

Also assert path connectivity:
- `(64,87)` -> `(64,78)`
- `(64,87)` -> `(58,80)`
- `(64,87)` -> `(40,75)`

and assert `DIRECT_BLOCKER_RECT` remains blocked.

## 11. Floor smoke updates

Update `ash_bell_lower_quarter_floor_atlas_smoke.gd` expectations:

```text
(55,88) -> SRC_CIVIC_LIGHT
(64,88) -> SRC_ROAD_GREY
(60,92) -> SRC_CIVIC_DARK_WORN
(64,86) overlay -> SRC_ROAD_ARROW_N
(64,85) overlay -> SRC_ROAD_LINE_V_DASH
(62,89) overlay -> SRC_ROAD_CROSSWALK_H
(60,90) overlay -> SRC_ROAD_LINE_H_DOUBLE
(50,79) overlay -> SRC_ROAD_LINE_H
(58,76) -> SRC_ROAD_DARK  # West Detour priority
(64,72) -> SRC_ROAD_DARK  # failed collapse band
```

Continue asserting:
- no `Palette.choose`
- no `_stable_hash`
- no random floor pool usage

## 12. Docs drift

Update in the same commit:

- `design/05_levels/ASH_BELL_LOWER_QUARTER.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md` if new placement authority/file paths are introduced
- relevant task packet / validation ownership files

Replace the old single:
`Arrival Platform Rect2i(52,82,24,12)`

with:
- South Threshold `Rect2i(60,90,9,4)`
- Entry Forecourt `Rect2i(54,84,21,6)`
- North Apron `Rect2i(57,82,14,2)`

Document that Direct Personnel remains the obvious but failed official route and West Detour is the required evacuation diversion.

## 13. Visual acceptance

Capture the Lower Quarter opening in Moment Forge / real gameplay camera.

PASS only if:
- ingress is visibly narrower than forecourt;
- forecourt opens immediately around Spawn_FromWorld;
- central five-cell personnel axis stays visually clear;
- Station IX is visible from arrival;
- failed direct route is unmistakably the intended-but-impossible path;
- dark evacuation line visibly peels west;
- side pads hold props without competing with route readability;
- removed old arrival corners read as ruined/nonwalkable urban frame, not empty black mistakes;
- floor remains cohesive and seam-free;
- no route bypass was introduced.

## 14. Commit discipline

Run the repo-required validation stack for the changed-file set.
Commit only the files owned by this task.
Do not push unless explicitly asked.
