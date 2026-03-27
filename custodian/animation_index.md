# Operator Animation Index

> All paths relative to `res://assets/sprites/operator/runtime/`

## Idle

| Animation        | Frames | Source Path                 |
| ---------------- | ------ | --------------------------- |
| idle_right       | 3      | idle/operator_idle_main.png |
| idle_down        | 3      | idle/operator_idle_main.png |
| idle_up          | 3      | idle/operator_idle_main.png |
| idle_alternative | 3      | idle/operator_idle_main.png |
| idle_long        | 10     | idle/idle-long.png          |

## Walk / Run

| Animation         | Frames | Source Path                                      |
| ----------------- | ------ | ------------------------------------------------ |
| walk_right        | 2      | body/ranged_2h/operator_body_ranged_2h_walk.png  |
| walk_east         | 2      | body/ranged_2h/operator_body_ranged_2h_walk.png  |
| walk_up           | 5      | move/walk_up.png                                 |
| walk_down         | 0      | (empty)                                          |
| walk_down_default | 4      | body/default/operator_body_default_walk_down.png |
| run_right         | 4      | body/default/operator_body_default_run.png       |

## Melee 2H

| Animation            | Frames | Source Path                                          |
| -------------------- | ------ | ---------------------------------------------------- |
| melee_2h_stance      | 4      | body/melee_2h/operator_body_melee_2h_stance.png      |
| melee_2h_fast_right  | 8      | body/melee_fast/melee_fast_baked_operator_only.png   |
| melee_2h_heavy_right | 7      | body/melee_heavy/operator_2h_heavy_3layer.png        |
| melee_2h_block_enter | 4      | body/melee_2h/operator_body_melee_2h_block_enter.png |
| melee_2h_block_hold  | 1      | body/melee_2h/operator_body_melee_2h_block_hold.png  |
| melee_2h_block_exit  | 2      | body/melee_2h/operator_body_melee_2h_block_exit.png  |

## Ranged 2H

| Animation        | Frames | Source Path                                                |
| ---------------- | ------ | ---------------------------------------------------------- |
| ranged_2h_stance | 3      | body/ranged_2h/operator_body_ranged_2h_stance.png          |
| ranged_2h_fire   | 2      | body/ranged_2h/operator_body_ranged_2h_fire_loop-sheet.png |

## Combat

| Animation          | Frames | Source Path                 |
| ------------------ | ------ | --------------------------- |
| attack_down        | 6      | idle/operator_idle_main.png |
| attack_up          | 6      | idle/operator_idle_main.png |
| hurt               | 4      | idle/operator_idle_main.png |
| death              | 4      | idle/operator_idle_main.png |
| attack_right_combo | 0      | (empty)                     |

## Unused / Placeholder

| Animation | Frames | Source Path |
| --------- | ------ | ----------- |
| default   | 0      | (empty)     |

---

## Source File Summary

| Source File                                                | Animations Using It                                                                   |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| idle/operator_idle_main.png                                | idle_right, idle_down, idle_up, idle_alternative, attack_down, attack_up, hurt, death |
| idle/idle-long.png                                         | idle_long                                                                             |
| body/ranged_2h/operator_body_ranged_2h_stance.png          | ranged_2h_stance                                                                      |
| body/ranged_2h/operator_body_ranged_2h_fire_loop-sheet.png | ranged_2h_fire                                                                        |
| body/ranged_2h/operator_body_ranged_2h_walk.png            | walk_right, walk_east                                                                 |
| body/default/operator_body_default_run.png                 | run_right                                                                             |
| body/default/operator_body_default_walk_down.png           | walk_down_default                                                                     |
| body/melee_2h/operator_body_melee_2h_stance.png            | melee_2h_stance                                                                       |
| body/melee_2h/operator_body_melee_2h_block_enter.png       | melee_2h_block_enter                                                                  |
| body/melee_2h/operator_body_melee_2h_block_hold.png        | melee_2h_block_hold                                                                   |
| body/melee_2h/operator_body_melee_2h_block_exit.png        | melee_2h_block_exit                                                                   |
| body/melee_fast/melee_fast_baked_operator_only.png         | melee_2h_fast_right                                                                   |
| body/melee_heavy/operator_2h_heavy_3layer.png              | melee_2h_heavy_right                                                                  |
| move/walk_up.png                                           | walk_up                                                                               |
