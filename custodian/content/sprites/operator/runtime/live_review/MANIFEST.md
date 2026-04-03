# Operator Animation Live Review

This folder contains the animation sheets that are currently wired into the live operator runtime.

## Folder Layout

- `body/`: body/base animation sheets
- `weapons/`: primary ranged weapon overlays
- `overlays/`: melee weapon/effects overlays

## Current Live Mapping

### Body

REVIEWED - `idle_right` - THIS FILE IS NOT INTERCHANGEABLE - THIS IS DIRECTIONAL FACING DOWN / TO CAMERA OF IDLE ANIMATION \_\_ NOT RIGHT FACING NOT UP FACING.

- `body/operator_idle_main.png`
- `idle_down`
  - `body/operator_idle_main.png`
- `idle_up`
  - `body/operator_idle_main.png`

REVIEWED - `idle_long` - 10 frame character only, idle_idle animation (runs after no input for duration)

- `body/idle-long.png`

REVIEWED - `walk_right` - THIS IS THE RANGED_WEAPON_EQUIPPED WALKING RIGHT ANIMATION, NOT DEFAULT WALKING ANIMATION. 2 frame custodian body with placeholder rifle walking right - needs real weapon overlay. IS NOT DEFUALT WALKING

- `body/operator_body_ranged_2h_walk.png`

- `walk_down`
  - `body/operator_idle_main.png`
    REVIEWED - `walk_up` - 5 frame CUSTODIAN walking upwards / away
  - `body/walk_up.png`

REVIEWED - `run_right` - 4 frame body only rightways running

- `body/operator_body_default_run.png`

REVIEWED - `walk_down_default` - 4 frame body only walking down (I UPDATED TO REMOVE ANTENNAE)

- `body/operator_body_default_walk_down.png`

REVIEwED - `ranged_2h_stance` - I dont care for this animation - 3 frame of custodian body only idle with holding weapon (not inlcuded) i would like to redo

- `body/operator_body_ranged_2h_stance.png`

REVIEWED - `ranged_2h_fire` - 2 frame body only custodian with no weapon slight recoil animated(I UPDATED REMOVED ANTENNAE)

- `body/operator_body_ranged_2h_fire_loop-sheet.png`

REVIEWED - `melee_2h_stance` - 4 frame body only ffacing camera active sword stance

- `body/operator_body_melee_2h_stance.png`

REVIEWED - `melee_2h_fast_right` - Full animation of fast attack right - no weapons or effects 12 total frames

- `body/melee_fast_baked_operator_only.png`

REVIEWED - `melee_2h_heavy_right` - Full animation of heavy attack - 7 frames, 3 rows. Operator first row, katana 2nd row, effects 3rd row - right-facing

- `body/operator_2h_heavy_3layer.png`

REVIEWED - `melee_2h_block_enter` - 4 frame animated body only, default block gesture built with katana

- `body/operator_body_melee_2h_block_enter.png`

REVIEWED - `melee_2h_block_exit` - 2 frame animated body only default block exit with katana as default

- `body/operator_body_melee_2h_block_exit.png`

REVIEWED - `melee_2h_block_hold` - 1 frame body only block held facing right

- `body/operator_body_melee_2h_block_hold.png`

### Ranged Weapon Overlay

REVIEWED - `ranged_2h_stance` - THIS IS A 3 FRAMES OF RIFLE - SHOULD ONLY BE USED AS TEMPORYR PLACEHOLDER - PRODUCTION WEAPON ANIMATION SHOULD BE MAPPED TO A DEFAULT WEAPON / MOVESET PAIR

- `weapons/carbine_rifle_mk1_stance.png`
  SEE ABOVE - `ranged_2h_fire`
- `weapons/carbine_rifle_mk1_stance.png`

### Melee Overlays

REVIEWED- `melee_2h_fast_weapon` - WEAPON (katana) ONLY FOR THE FAST ATTACK

- `overlays/fallen_star_katana__melee_1h__fast_weapon.png`

REVIEWD - `melee_2h_fast_fx` - EFFECTS ONLY FOR THE FAST ATTACK

- `overlays/fallen_star_katana__melee_1h__fast_fx.png`

REVIEWED `melee_2h_heavy_weapon` - BODY + WEAPON (row 2) + EFFECTS (Row 3) FOR FAST ATTACK 7 FRAMES FACE RIGHT USES KATANA FOR DEFAULT

- `body/operator_2h_heavy_3layer.png`
- row 2
- `melee_2h_heavy_fx`
  - `body/operator_2h_heavy_3layer.png`
  - row 3
    REVIEWED - `melee_2h_block_enter_weapon` - 4 FRAMES OF WEAPON - KATANA - MAP TO BLOCK ANIMATION
  - `overlays/fallen_star_katana__melee_2h__block_enter_weapon.png`
    REVIEWED - `melee_2h_block_hold_weapon` - 1 FRAME OF WEAPON - KATANA - FOR MAIN BLOCK FRAME
  - `overlays/fallen_star_katana__melee_2h__block_hold_weapon.png`
    REVIEWED - `melee_2h_block_exit_weapon` - 2 FRAME OF WEAPON - KATANA - FOR MAIN BLOCK EXIT
  - `overlays/fallen_star_katana__melee_2h__block_exit_weapon.png`

## Sorting Plan

1. Start with body sheets only.
   - For each key above, decide: keep, replace, or remove.
2. Mark authored facing for each kept sheet.
   - `left-facing` or `right-facing`
3. Record frame count for each kept sheet.
4. Record whether the sheet is:
   - body only
   - body + weapon
   - body + weapon + fx
5. For multi-row sheets, write row order directly in the filename list or next to the key.
6. After body sheets are resolved, sort overlays.
   - fast weapon
   - fast fx
   - heavy weapon
   - heavy fx
   - block weapon overlays
7. Once the manifest is updated, I can rewire the runtime cleanly from that one source of truth.

## Recommended First Pass

- Resolve `ranged_2h_stance`
- Resolve `ranged_2h_fire`
- Resolve `walk_right`
- Resolve `run_right`
- Resolve `melee_2h_stance`
- Resolve `melee_2h_fast_right`
- Resolve `melee_2h_heavy_right`
- Resolve block enter/hold/exit
