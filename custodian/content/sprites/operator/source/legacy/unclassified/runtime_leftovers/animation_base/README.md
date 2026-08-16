# Operator Runtime Animation Base

This directory is the authoritative body-base source for placeholder locomotion.
These sheets are intended to sit under later skin/weapon overlays.

## Rule

- Multi-animation or multi-direction sheets in this directory are source masters.
- They should not be treated as direct runtime bindings when a smaller rebuilt slice will do.
- Runtime resources should be rebuilt from only the specific directional or animation slices currently consumed by gameplay.

## Core Locomotion

- `body/core_locomotion/walking_base.png`
  - 64 frames total
  - 8 directions, 8 frames per direction
  - directional order in-sheet: `NW`, `W`, `SW`, `S`, `SE`, `E`, `NE`, `N`
  - wired to:
    - `walk_up`
    - `walk_up_right`
    - `walk_right`
    - `walk_down_right`
    - `walk_down_default`

- `body/core_locomotion/running_base.png`
  - 128 frames total
  - 8 directions, 16 frames per direction
  - directional order in-sheet: `NW`, `W`, `SW`, `S`, `SE`, `E`, `NE`, `N`
  - wired to:
    - `run_up`
    - `run_up_right`
    - `run_right`
    - `run_down_right`
    - `run_down`

## Melee

- `body/melee/light_attack_base.png`
  - 56 frames total
  - inferred as 8 directions, 7 frames per direction from sheet dimensions
  - directional order assumed to match the locomotion masters: `NW`, `W`, `SW`, `S`, `SE`, `E`, `NE`, `N`
  - wired to:
    - `melee_2h_fast_up`
    - `melee_2h_fast_up_right`
    - `melee_2h_fast_right`
    - `melee_2h_fast_down_right`
    - `melee_2h_fast_down`

- `body/melee/fast_attack_right_base.png`
  - 12 frames total
  - body-only right-facing fast attack using the newer base body
  - wired to:
    - `melee_2h_fast_right`

## Runtime Notes

- Left-facing travel currently mirrors the right-side directional strips at runtime.
- Standalone west-facing locomotion exports in `body/core_locomotion/` are currently treated as source-side helper exports, not active runtime bindings.
- The rebuild path is `res://tools/pipelines/update_operator_curated_resources.gd`.
