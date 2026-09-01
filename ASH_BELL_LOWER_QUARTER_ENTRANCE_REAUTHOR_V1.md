# Ash-Bell Lower Quarter Entrance Reauthor V1

## Status

**Proposed authored redesign grounded in the current Godot runtime.**

The current live runtime uses a 32-world-unit authored cell, Lower Quarter origin `(-2048,-1536)`, the arrival region `Rect2i(52,82,24,12)`, `Spawn_FromWorld` at `(64,87)`, `Exit_ReturnWorld` at `(64,91)`, Direct Personnel Line `Rect2i(58,70,12,14)`, and the physically impassable collapse `Rect2i(55,71,18,4)`.

This pass keeps the canonical route logic: the player is initially aimed straight at Station IX, discovers the direct personnel route is physically failed, and must divert west into the evacuation route. The generated "ideal state" infographic must **not** be interpreted as a literal straight-through route to Station IX.

## Design goal

Turn the current broad rectangular arrival slab into:

```text
                 STATION IX / FAILED DIRECT LINE
                           ↑
                    direct personnel road
                  x=58..69, y=70..83
                           │
                 ┌─────────┴─────────┐
                 │  north apron      │  x=57..70, y=82..83
                 └──────┬─────┬─────┘
                        │ 5-cell official axis
          ┌─────────────┴─────────────┐
          │       civic forecourt     │  x=54..74, y=84..89
          │ west pad   │   east pad   │
          └─────────────┬─────────────┘
                        │
                   narrow threshold       x=60..68, y=90..93
                        │
                  LOWER QUARTER WORLD
```

The floor must establish hierarchy before props:
- **grey official personnel roadway**
- **light civic plaza**
- **dark threshold shoulders**
- **dark evacuation/service road**
- **dark failed-collapse band**

## Exact geometry

Replace only:

```gdscript
Rect2i(52, 82, 24, 12) # old Arrival Platform
```

with:

```gdscript
Rect2i(60, 90, 9, 4)   # South Threshold
Rect2i(54, 84, 21, 6)  # Entry Forecourt
Rect2i(57, 82, 14, 2)  # North Apron
```

Do not modify:
- `Rect2i(58,70,12,14)` Direct Personnel Line
- `Rect2i(38,74,22,8)` West Detour
- `Rect2i(32,48,14,32)` Evacuation Arcade
- `Rect2i(55,71,18,4)` DirectPersonnelCollapse
- `Spawn_FromWorld (64,87)`
- `Exit_ReturnWorld (64,91)`

This removes 98 formerly walkable cells and adds none. It deliberately cuts the old rectangular corners away to produce a narrow-entry / broad-court / narrow-apron composition.

## Exact floor atlas coordinates

Use only the already-reviewed runtime floor coordinates:

| Meaning | Atlas coordinate |
|---|---:|
| civic light | `(2,0)` |
| civic light worn A | `(5,0)` |
| civic light worn B | `(6,0)` |
| civic dark | `(8,0)` |
| civic dark worn | `(10,0)` |
| official grey road | `(2,5)` |
| evacuation/damaged dark road | `(11,5)` |
| horizontal line | `(1,4)` |
| horizontal double line | `(2,4)` |
| vertical dashed line | `(5,4)` |
| vertical double line | `(6,4)` |
| horizontal crosswalk | `(0,4)` |
| north arrow | `(10,4)` |
| horizontal dash | `(12,4)` |

No hashing and no random variant selection.

## Base-floor priority

Implement in this exact priority:

1. `Rect2i(58,71,12,4)` -> `(11,5)` collapse band.
2. `Rect2i(38,74,22,8)` -> `(11,5)` West Detour.
3. `Rect2i(58,70,12,14)` -> `(2,5)` Direct Personnel Line.
4. `Rect2i(62,82,5,12)` -> `(2,5)` Arrival Axis.
5. `Rect2i(60,90,9,4)` -> `(8,0)` South Threshold.
6. `Rect2i(54,84,21,6)` -> `(2,0)` Forecourt.
7. `Rect2i(57,82,14,2)` -> `(2,0)` North Apron.

The axis/direct road wins over plaza/threshold materials. The West Detour wins over the overlapping two western Direct Personnel cells so the required diversion visibly cuts into the official route.

## Exact wear overrides

```text
(55,85) -> (5,0)
(58,88) -> (6,0)
(55,89) -> (5,0)

(73,85) -> (5,0)
(70,88) -> (6,0)
(73,89) -> (5,0)

(57,83) -> (6,0)
(70,83) -> (5,0)

(60,92) -> (10,0)
(68,92) -> (10,0)
```

No other entrance wear in this pass.

## Exact markings

### South precinct threshold
```text
y=90, x=60..68 -> (2,4) horizontal double line
```

### Forecourt crossing
```text
y=89, x=62..66 -> (0,4) horizontal crosswalk
```

### South threshold centerline
```text
(64,91), (64,92) -> (5,4)
```

### Forecourt official centerline
```text
x=64, y=84..88 -> (5,4)
(64,86) -> replace with (10,4) north arrow
```

### Direct personnel centerline
```text
x=64, y=75..83 -> (5,4)
(64,78) -> replace with (10,4) north arrow
```

### Required evacuation turn
```text
y=79, x=40..63 -> (1,4)
```

That westward line intentionally terminates immediately left of the official centerline. The player sees the direct north arrow, the ruined/blocked route ahead, and the west emergency line at the same decision beat.

Delete the old entrance marking rules:
- old crosswalk `y=82, x=62..66`
- old arrival arrow `(64,85)`
- old broad arrival centerline range
- old West Detour line at `y=77, x=40..57`

Other district markings remain unchanged.

## Prop-layout rule

No active prop anchor may be inside:

```gdscript
Rect2i(62,82,5,12)
```

This is the five-cell official movement lane.

The exact civic and catastrophe prop moves/disables are machine-readable in `ash_bell_lower_quarter_entrance_reauthor_v1.json`.

The entrance should retain:
- two surviving civic lamps
- two surviving benches
- sign/directory
- restrained rail/bollard language
- only seven active catastrophe props in the entrance itself

Heavier rubble/barricade vocabulary belongs at the Direct Personnel collapse, not at world ingress.

## Ruined facade frame

Use the new native ruined-facade family outside the new walkable shape:

```text
source 62 @ top-left cell (50,86)  west facade frame
source 64 @ top-left cell (75,86)  east facade frame
source 129 @ top-left cell (48,91) west outer rubble
source 140 @ top-left cell (75,91) east outer rubble
```

Scale `1.0`. These are visual framing elements in already-nonwalkable space. Do not derive navigation/collision from their alpha.

## Gameplay intent

The opening must read in this order:

1. **Enter through a narrow civic threshold.**
2. **Open into a readable forecourt with Station IX immediately visible.**
3. **The five-cell official personnel axis says "go north."**
4. **The upper apron expands into the old 12-cell personnel road.**
5. **The catastrophic direct-route failure physically stops that promise.**
6. **The dark evacuation floor line turns west and becomes the required playable route.**

This preserves the canonical visual irony: the official order is obvious, but obeying it is impossible.

## Documentation drift to fix

The active level design currently documents the arrival as `Rect2i(52,82,24,12)`. Update it to the three-region entrance composition above. Update runtime-context docs and floor-validation expectations in the same commit. Do not leave the old rectangular Arrival Platform described as current authority.

## Acceptance

At gameplay camera scale, pass only if:
- world ingress is narrower than the forecourt;
- Station IX remains visible immediately after spawn;
- the main official axis can be read without UI arrows;
- the west emergency route becomes visually distinct before the player reaches the hard blocker;
- the forecourt has usable side space but no route ambiguity;
- props do not obstruct the five-cell lane;
- no new walkable path bypasses the direct blocker;
- no floor tile is randomly selected;
- collision/navigation/state behavior outside the explicit geometry change is unchanged.
