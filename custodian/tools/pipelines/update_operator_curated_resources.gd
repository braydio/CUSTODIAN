extends SceneTree

const BODY_FRAMES_PATH := "res://game/actors/operator/operator_runtime_frames.tres"
const MODULAR_LOWER_BODY_FRAMES_PATH := "res://game/actors/operator/operator_modular_lower_body_frames.tres"
const MODULAR_UPPER_BODY_FRAMES_PATH := "res://game/actors/operator/operator_modular_upper_body_frames.tres"
const MODULAR_SIDEARM_FRAMES_PATH := "res://game/actors/operator/operator_modular_sidearm_frames.tres"
const MODULAR_UPPER_FX_FRAMES_PATH := "res://game/actors/operator/operator_modular_upper_fx_frames.tres"
const WEAPON_FRAMES_PATH := "res://game/actors/operator/operator_weapon_frames.tres"
const MELEE_OVERLAY_FRAMES_PATH := "res://game/actors/operator/operator_melee_overlay_frames.tres"
const RANGED_FX_FRAMES_PATH := "res://game/actors/operator/operator_ranged_fx_frames.tres"

const BASE_WALK_SHEET := "res://content/sprites/operator/runtime/animation_base/body/core_locomotion/walking_base.png"
const BASE_RUN_SHEET := "res://content/sprites/operator/runtime/animation_base/body/core_locomotion/running_base.png"
const BASE_LIGHT_ATTACK_SHEET := "res://content/sprites/operator/runtime/animation_base/body/melee/light_attack_base.png"
const BASE_FAST_ATTACK_RIGHT_SHEET := "res://content/sprites/operator/runtime/animation_base/body/melee/fast_attack_right_base.png"
const BASE_FAST_ATTACK_NORTH_BODY_SHEET := "res://content/sprites/operator/runtime/animation_base/body/melee/fast_attack_north_base_body.png"
const BASE_FAST_ATTACK_NORTH_WEAPON_SHEET := "res://content/sprites/operator/runtime/animation_base/body/melee/fast_attack_north_base_weapon.png"
const BASE_FAST_ATTACK_NORTH_FX_SHEET := "res://content/sprites/operator/runtime/animation_base/body/melee/fast_attack_north_base_effects.png"
const BASE_DEATH_SHEET := "res://content/sprites/operator/runtime/animation_base/body/core_locomotion/death_disintigrate_base.png"
const RANGED_RUN_BODY_SHEET := "res://content/sprites/operator/runtime/body/ranged_2h/operator__body__ranged_2h__run_01__e__5f__96.png"
const RANGED_RUN_WEAPON_SHEET := "res://content/sprites/operator/runtime/curated/weapon/ranged_2h/carbine_rifle_mk1/operator__weapon__ranged_2h__run_01__e__5f__96.png"
const RANGED_RUN_WEST_BODY_SHEET := "res://content/sprites/operator/runtime/body/ranged_2h/operator__body__ranged_2h__run_01__w__5f__96.png"
const RANGED_RUN_WEST_WEAPON_SHEET := "res://content/sprites/operator/runtime/curated/weapon/ranged_2h/carbine_rifle_mk1/operator__weapon__ranged_2h__run_01__w__5f__96.png"
const RANGED_STANCE_EAST_BODY_SHEET := "res://content/sprites/operator/runtime/body/ranged_2h/operator__body__ranged__stance_01__e__12f__96.png"
const DODGE_STEP_BODY_SHEET := "res://content/sprites/operator/runtime/body/locomotion/operator__body__locomotion__dodge__n__4f__96.png"
const DODGE_RECOVERY_BODY_SHEET := "res://content/sprites/operator/runtime/body/locomotion/operator__body__locomotion__dodge_recovery__n__4f__96.png"
const DODGE_BACKSTEP_BODY_SHEET := "res://content/sprites/operator/runtime/body/locomotion/operator__body__locomotion__dodge_backstep__s__4f__96.png"
const DODGE_BACKSTEP_RECOVERY_BODY_SHEET := "res://content/sprites/operator/runtime/body/locomotion/operator__body__locomotion__dodge_backstep_recovery__s__4f__96.png"
const DODGE_FULL_NORTH_BODY_SHEET := "res://content/sprites/operator/runtime/actions/dodge/body/operator__body__full__dodge_01__n__9f__96.png"
const DODGE_FULL_SOUTH_BODY_SHEET := "res://content/sprites/operator/runtime/actions/dodge/body/operator__body__full__dodge_01__s__9f__96.png"
const DODGE_FULL_NORTH_FX_SHEET := "res://content/sprites/operator/runtime/actions/dodge/fx/operator__fx__full__dodge_01__n__9f__96.png"
const DODGE_FULL_SOUTH_FX_SHEET := "res://content/sprites/operator/runtime/actions/dodge/fx/operator__fx__full__dodge_01__s__9f__96.png"
const HEAVY_ANTICIPATION_SHEET := "res://content/sprites/operator/runtime/curated/body/melee_2h/heavy_anticipation_body.png"
const HEAVY_ATTACK_SHEET := "res://content/sprites/operator/runtime/curated/body/melee_2h/heavy_attack_right_3layer_7f.png"
const BLOCK_ENTER_BODY_SHEET := "res://content/sprites/operator/runtime/curated/body/melee_2h/block_enter_body_4f.png"
const BLOCK_HOLD_BODY_SHEET := "res://content/sprites/operator/runtime/curated/body/melee_2h/block_hold_body_1f.png"
const BLOCK_EXIT_BODY_SHEET := "res://content/sprites/operator/runtime/curated/body/melee_2h/block_exit_body_2f.png"
const BLOCK_ENTER_WEAPON_SHEET := "res://content/sprites/operator/runtime/curated/overlay/melee_2h/block_enter_weapon_4f.png"
const BLOCK_HOLD_WEAPON_SHEET := "res://content/sprites/operator/runtime/curated/overlay/melee_2h/block_hold_weapon_1f.png"
const BLOCK_EXIT_WEAPON_SHEET := "res://content/sprites/operator/runtime/curated/overlay/melee_2h/block_exit_weapon_2f.png"
const RELOAD_BODY_SHEET := "res://content/sprites/operator/runtime/curated/body/ranged_2h/reload_body.png"
const FIRE_BODY_SHEET := "res://content/sprites/operator/runtime/curated/body/ranged_2h/fire_body.png"
const OPERATOR_RELOADING_SHEET := "res://content/sprites/operator/runtime/curated/body/ranged_2h/operator_reloading.png"
const FAST_ATTACK_1_SHEET := "res://content/sprites/operator/runtime/curated/body/melee_2h/fast_attack_1_right_body.png"
const FAST_ATTACK_2_SHEET := "res://content/sprites/operator/runtime/curated/body/melee_2h/fast_attack_2_right_body.png"
const FAST_RECOVERY_SHEET := "res://content/sprites/operator/runtime/curated/body/melee_2h/fast_recovery_body.png"
const UNARMED_WALK_SOUTH_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__walk_01__s__6f__96.png"
const UNARMED_WALK_EAST_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__walk_01__e__5f__96.png"
const UNARMED_WALK_NORTH_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__walk_01__n__7f__96.png"
const UNARMED_WALK_WEST_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__walk_01__w__5f__96.png"
const UNARMED_FAST_SOUTH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_01__s__6f__96.png"
const UNARMED_FAST_FX_SOUTH_SHEET := "res://content/sprites/operator/runtime/overlay/unarmed/operator__fx__unarmed__fast_01__s__6f__96.png"
const UNARMED_FAST_EAST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_01__e__5f__96.png"
const UNARMED_FAST_WEST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_01__w__5f__96.png"
const UNARMED_FAST_FX_EAST_SHEET := "res://content/sprites/operator/runtime/overlay/unarmed/operator__fx__unarmed__fast_01__e__3f__96.png"
const UNARMED_FAST_NORTH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__fast_01__n__6f__96.png"
const UNARMED_FAST_FX_NORTH_SHEET := "res://content/sprites/operator/runtime/overlay/unarmed/operator__fx__unarmed__fast_01__n__6f__96.png"
const UNARMED_FAST_RECOVERY_NORTH_FX_SHEET := "res://content/sprites/operator/runtime/overlay/unarmed/operator__fx__unarmed__fast_recovery_01__n__2f__96.png"
const UNARMED_HEAVY_EAST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__heavy_01__e__7f__96.png"
const UNARMED_HEAVY_FX_EAST_SHEET := "res://content/sprites/operator/runtime/overlay/unarmed/operator__fx__unarmed__heavy_01__e__7f__96.png"
const UNARMED_HEAVY_WEST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__heavy_01__w__7f__96.png"
const UNARMED_HEAVY_FX_WEST_SHEET := "res://content/sprites/operator/runtime/overlay/unarmed/operator__fx__unarmed__heavy_01__w__7f__96.png"
const UNARMED_HEAVY_NORTH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__heavy_01__n__8f__96.png"
const UNARMED_HEAVY_FX_NORTH_SHEET := "res://content/sprites/operator/runtime/overlay/unarmed/operator__fx__unarmed__heavy_01__n__8f__96.png"
const UNARMED_HEAVY_SOUTH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__heavy_01__s__7f__96.png"
const UNARMED_HEAVY_FX_SOUTH_SHEET := "res://content/sprites/operator/runtime/overlay/unarmed/operator__fx__unarmed__heavy_01__s__7f__96.png"
const UNARMED_IDLE_SOUTH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__idle_01__s__8f__96.png"
const UNARMED_IDLE_EAST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__idle_01__e__6f__96.png"
const UNARMED_IDLE_NORTH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__idle_01__n__10f__96.png"
const UNARMED_IDLE_WEST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__idle_01__w__6f__96.png"
const UNARMED_RUN_EAST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__run_01__e__5f__96.png"
const UNARMED_RUN_NORTH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__run_01__n__6f__96.png"
const UNARMED_RUN_SOUTH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__run_01__s__7f__96.png"
const UNARMED_RUN_WEST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__run_01__w__5f__96.png"
const UNARMED_RUN_SOUTHEAST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__run_01__se__4f__96.png"
const UNARMED_RUN_SOUTHWEST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__run_01__sw__4f__96.png"
const UNARMED_STANCE_EAST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__stance_01__e__6f__96.png"
const UNARMED_STANCE_WEST_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__stance_01__w__6f__96.png"
const UNARMED_DEATH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__death_01__omni__6f__96.png"
const UNARMED_ARRIVAL_SOUTH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__arrival_01__s__9f__96.png"
const UNARMED_LIGHT_HITREACT_SOUTH_BODY_SHEET := "res://content/sprites/operator/runtime/body/unarmed/operator__body__unarmed__light_hitreact_01__s__3f__96.png"
const UNARMED_LIGHT_HITREACT_FX_SOUTH_SHEET := "res://content/sprites/operator/runtime/overlay/unarmed/operator__fx__unarmed__light_hitreact_01__s__3f__96.png"
var _had_rebuild_error := false

const WALK_BASE_SLICES := [
	{"animation": "walk_down_left", "start": 0, "count": 8, "fps": 10.0},
	{"animation": "walk_left", "start": 8, "count": 8, "fps": 10.0},
	{"animation": "walk_up_left", "start": 16, "count": 8, "fps": 10.0},
	{"animation": "walk_up", "start": 56, "count": 8, "fps": 10.0},
	{"animation": "walk_up_right", "start": 48, "count": 8, "fps": 10.0},
	{"animation": "walk_right", "start": 40, "count": 8, "fps": 10.0},
	{"animation": "walk_down_right", "start": 32, "count": 8, "fps": 10.0},
	{"animation": "walk_down_default", "start": 24, "count": 8, "fps": 10.0},
]
const RUN_BASE_SLICES := [
	{"animation": "run_down_left", "start": 0, "count": 16, "fps": 14.0},
	{"animation": "run_left", "start": 16, "count": 16, "fps": 14.0},
	{"animation": "run_up_left", "start": 32, "count": 16, "fps": 14.0},
	{"animation": "run_up", "start": 112, "count": 16, "fps": 14.0},
	{"animation": "run_up_right", "start": 96, "count": 16, "fps": 14.0},
	{"animation": "run_right", "start": 80, "count": 16, "fps": 14.0},
	{"animation": "run_down_right", "start": 64, "count": 16, "fps": 14.0},
	{"animation": "run_down", "start": 48, "count": 16, "fps": 14.0},
]
const LIGHT_ATTACK_BASE_SLICES := [
	{"animation": "melee_2h_fast_down_left", "start": 0, "count": 7, "fps": 12.0},
	{"animation": "melee_2h_fast_left", "start": 7, "count": 7, "fps": 12.0},
	{"animation": "melee_2h_fast_up_left", "start": 14, "count": 7, "fps": 12.0},
	{"animation": "melee_2h_fast_up", "start": 49, "count": 7, "fps": 12.0},
	{"animation": "melee_2h_fast_up_right", "start": 42, "count": 7, "fps": 12.0},
	{"animation": "melee_2h_fast_right", "start": 35, "count": 7, "fps": 12.0},
	{"animation": "melee_2h_fast_down_right", "start": 28, "count": 7, "fps": 12.0},
	{"animation": "melee_2h_fast_down", "start": 21, "count": 7, "fps": 12.0},
]
const UNARMED_MODULAR_LOWER_LOCOMOTION_SLICES := [
	{"animation": "unarmed_idle", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/idle_01/operator__modular_lower_body__unarmed__idle_01__s__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 8.0, "loop": true},
	{"animation": "unarmed_idle_down", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/idle_01/operator__modular_lower_body__unarmed__idle_01__s__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 8.0, "loop": true},
	{"animation": "unarmed_idle_down_right", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/idle_01/operator__modular_lower_body__unarmed__idle_01__se__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 8.0, "loop": true},
	{"animation": "unarmed_idle_right", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/idle_01/operator__modular_lower_body__unarmed__idle_01__e__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 8.0, "loop": true},
	{"animation": "unarmed_idle_up_right", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/idle_01/operator__modular_lower_body__unarmed__idle_01__ne__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 8.0, "loop": true},
	{"animation": "unarmed_idle_up", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/idle_01/operator__modular_lower_body__unarmed__idle_01__n__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 8.0, "loop": true},
	{"animation": "unarmed_idle_up_left", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/idle_01/operator__modular_lower_body__unarmed__idle_01__nw__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 8.0, "loop": true},
	{"animation": "unarmed_idle_left", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/idle_01/operator__modular_lower_body__unarmed__idle_01__w__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 8.0, "loop": true},
	{"animation": "unarmed_idle_down_left", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/idle_01/operator__modular_lower_body__unarmed__idle_01__sw__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 8.0, "loop": true},
	{"animation": "unarmed_walk", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/walk_01/operator__modular_lower_body__unarmed__walk_01__s__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 10.0, "loop": true},
	{"animation": "unarmed_walk_down", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/walk_01/operator__modular_lower_body__unarmed__walk_01__s__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 10.0, "loop": true},
	{"animation": "unarmed_walk_down_right", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/walk_01/operator__modular_lower_body__unarmed__walk_01__se__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 10.0, "loop": true},
	{"animation": "unarmed_walk_right", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/walk_01/operator__modular_lower_body__unarmed__walk_01__e__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 10.0, "loop": true},
	{"animation": "unarmed_walk_up_right", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/walk_01/operator__modular_lower_body__unarmed__walk_01__ne__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 10.0, "loop": true},
	{"animation": "unarmed_walk_up", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/walk_01/operator__modular_lower_body__unarmed__walk_01__n__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 10.0, "loop": true},
	{"animation": "unarmed_walk_up_left", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/walk_01/operator__modular_lower_body__unarmed__walk_01__nw__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 10.0, "loop": true},
	{"animation": "unarmed_walk_left", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/walk_01/operator__modular_lower_body__unarmed__walk_01__w__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 10.0, "loop": true},
	{"animation": "unarmed_walk_down_left", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/walk_01/operator__modular_lower_body__unarmed__walk_01__sw__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 10.0, "loop": true},
	{"animation": "unarmed_run_down", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/run_01/operator__modular_lower_body__unarmed__run_01__s__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 12.0, "loop": true},
	{"animation": "unarmed_run_down_right", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/run_01/operator__modular_lower_body__unarmed__run_01__se__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 12.0, "loop": true},
	{"animation": "unarmed_run_right", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/run_01/operator__modular_lower_body__unarmed__run_01__e__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 12.0, "loop": true},
	{"animation": "unarmed_run_up_right", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/run_01/operator__modular_lower_body__unarmed__run_01__ne__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 12.0, "loop": true},
	{"animation": "unarmed_run_up", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/run_01/operator__modular_lower_body__unarmed__run_01__n__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 12.0, "loop": true},
	{"animation": "unarmed_run_up_left", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/run_01/operator__modular_lower_body__unarmed__run_01__nw__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 12.0, "loop": true},
	{"animation": "unarmed_run_left", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/run_01/operator__modular_lower_body__unarmed__run_01__w__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 12.0, "loop": true},
	{"animation": "unarmed_run_down_left", "path": "res://content/sprites/operator/runtime/modules/new_operator/lower_body/locomotion/run_01/operator__modular_lower_body__unarmed__run_01__sw__5f__96.png", "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 12.0, "loop": true},
]
const UNARMED_FAST_WINDUP_BODY_SLICES := [
	{"animation": "unarmed_attack_fast_windup", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_windup_01__s__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_attack_fast_windup_down", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_windup_01__s__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_attack_fast_windup_down_right", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_windup_01__se__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_attack_fast_windup_right", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_windup_01__e__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_attack_fast_windup_up_right", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_windup_01__ne__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_attack_fast_windup_up", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_windup_01__n__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_attack_fast_windup_up_left", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_windup_01__nw__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_attack_fast_windup_left", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_windup_01__w__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_attack_fast_windup_down_left", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_windup_01__sw__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
]
const UNARMED_FAST_STRIKE_BODY_SLICES := [
	{"animation": "unarmed_fast_strike", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_strike_01__s__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_down", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_strike_01__s__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_down_right", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_strike_01__se__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_right", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_strike_01__e__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_up_right", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_strike_01__ne__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_up", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_strike_01__n__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_up_left", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_strike_01__nw__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_left", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_strike_01__w__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_down_left", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_strike_01__sw__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
]
const UNARMED_FAST_STRIKE_FX_SLICES := [
	{"animation": "unarmed_fast_strike_fx", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/overlay/operator__fx__unarmed__fast_strike_01__s__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_fx_down", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/overlay/operator__fx__unarmed__fast_strike_01__s__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_fx_down_right", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/overlay/operator__fx__unarmed__fast_strike_01__se__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_fx_right", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/overlay/operator__fx__unarmed__fast_strike_01__e__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_fx_up_right", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/overlay/operator__fx__unarmed__fast_strike_01__ne__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_fx_up", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/overlay/operator__fx__unarmed__fast_strike_01__n__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_fx_up_left", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/overlay/operator__fx__unarmed__fast_strike_01__nw__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_fx_left", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/overlay/operator__fx__unarmed__fast_strike_01__w__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
	{"animation": "unarmed_fast_strike_fx_down_left", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/overlay/operator__fx__unarmed__fast_strike_01__sw__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 12.0},
]
const UNARMED_FAST_RECOVERY_BODY_SLICES := [
	{"animation": "unarmed_attack_fast_recovery", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_recovery_01__e__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 15.0},
	{"animation": "unarmed_attack_fast_recovery_down", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_recovery_01__s__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 15.0},
	{"animation": "unarmed_attack_fast_recovery_down_right", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_recovery_01__se__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 15.0},
	{"animation": "unarmed_attack_fast_recovery_right", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_recovery_01__e__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 15.0},
	{"animation": "unarmed_attack_fast_recovery_up_right", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_recovery_01__ne__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 15.0},
	{"animation": "unarmed_attack_fast_recovery_up", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_recovery_01__n__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 15.0},
	{"animation": "unarmed_attack_fast_recovery_up_left", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_recovery_01__nw__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 15.0},
	{"animation": "unarmed_attack_fast_recovery_left", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_recovery_01__w__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 15.0},
	{"animation": "unarmed_attack_fast_recovery_down_left", "path": "res://content/sprites/operator/runtime/actions/unarmed/fast_attack/body/operator__body__unarmed__fast_recovery_01__sw__3f__96.png", "frames": 3, "frame_width": 96, "frame_height": 96, "fps": 15.0},
]

func _init() -> void:
	var body_frames := load(BODY_FRAMES_PATH) as SpriteFrames
	var modular_lower_body_frames := _load_or_create_sprite_frames(MODULAR_LOWER_BODY_FRAMES_PATH)
	var modular_upper_body_frames := _load_or_create_sprite_frames(MODULAR_UPPER_BODY_FRAMES_PATH)
	var modular_sidearm_frames := _load_or_create_sprite_frames(MODULAR_SIDEARM_FRAMES_PATH)
	var modular_upper_fx_frames := _load_or_create_sprite_frames(MODULAR_UPPER_FX_FRAMES_PATH)
	var weapon_frames := load(WEAPON_FRAMES_PATH) as SpriteFrames
	var melee_overlay_frames := load(MELEE_OVERLAY_FRAMES_PATH) as SpriteFrames
	var ranged_fx_frames := load(RANGED_FX_FRAMES_PATH) as SpriteFrames

	if body_frames == null or modular_lower_body_frames == null or modular_upper_body_frames == null or modular_sidearm_frames == null or modular_upper_fx_frames == null or weapon_frames == null or melee_overlay_frames == null or ranged_fx_frames == null:
		push_error("Failed to load one or more operator SpriteFrames resources.")
		quit(1)
		return

	# Base locomotion sheets are source masters. Only rebuild the runtime slices we actually consume.
	_replace_sheet_slices(body_frames, BASE_WALK_SHEET, WALK_BASE_SLICES, 96, 96)
	_replace_sheet_slices(body_frames, BASE_RUN_SHEET, RUN_BASE_SLICES, 96, 96)
	_replace_sheet_slices(body_frames, BASE_LIGHT_ATTACK_SHEET, LIGHT_ATTACK_BASE_SLICES, 96, 96)
	_replace_animation(body_frames, "melee_2h_fast_right", BASE_FAST_ATTACK_RIGHT_SHEET, 12, 0, 96, 128, 12.0, false)
	_replace_animation_if_exists(body_frames, "melee_2h_fast_up", BASE_FAST_ATTACK_NORTH_BODY_SHEET, 6, 0, 96, 96, 12.0, false)
	_replace_animation(body_frames, "melee_2h_heavy_anticipation", HEAVY_ANTICIPATION_SHEET, 5, 0, 96, 96, 11.0, false)
	_replace_animation(body_frames, "melee_2h_heavy", HEAVY_ATTACK_SHEET, 7, 0, 96, 96, 11.0, false)
	_replace_animation(body_frames, "melee_2h_heavy_right", HEAVY_ATTACK_SHEET, 7, 0, 96, 96, 11.0, false)
	_replace_animation(body_frames, "melee_2h_fast_1_right", FAST_ATTACK_1_SHEET, 6, 0, 96, 96, 12.0, false)
	_replace_animation(body_frames, "melee_2h_fast_2_right", FAST_ATTACK_2_SHEET, 5, 0, 96, 96, 12.0, false)
	_replace_animation(body_frames, "melee_2h_fast_recovery", FAST_RECOVERY_SHEET, 2, 0, 96, 96, 10.0, false)
	_replace_animation_if_exists(body_frames, "unarmed_attack_fast", UNARMED_FAST_SOUTH_BODY_SHEET, 6, 0, 96, 96, 12.0, false)
	_replace_animation_if_exists(body_frames, "unarmed_attack_fast_down", UNARMED_FAST_SOUTH_BODY_SHEET, 6, 0, 96, 96, 12.0, false)
	_replace_animation_if_exists(body_frames, "unarmed_attack_fast_right", UNARMED_FAST_EAST_BODY_SHEET, 5, 0, 96, 96, 12.0, false)
	_replace_animation_if_exists(body_frames, "unarmed_attack_fast_left", UNARMED_FAST_WEST_BODY_SHEET, 5, 0, 96, 96, 12.0, false)
	_replace_animation_if_exists(body_frames, "unarmed_attack_fast_up", UNARMED_FAST_NORTH_BODY_SHEET, 6, 0, 96, 96, 12.0, false)
	_replace_animation_entries(body_frames, UNARMED_FAST_WINDUP_BODY_SLICES)
	_replace_animation_entries(body_frames, UNARMED_FAST_STRIKE_BODY_SLICES)
	_replace_animation_entries(body_frames, UNARMED_FAST_RECOVERY_BODY_SLICES)
	_replace_animation_if_exists(body_frames, "unarmed_attack_heavy", UNARMED_HEAVY_EAST_BODY_SHEET, 7, 0, 96, 96, 10.0, false)
	_replace_animation_if_exists(body_frames, "unarmed_attack_heavy_right", UNARMED_HEAVY_EAST_BODY_SHEET, 7, 0, 96, 96, 10.0, false)
	_replace_animation_if_exists(body_frames, "unarmed_attack_heavy_left", UNARMED_HEAVY_WEST_BODY_SHEET, 7, 0, 96, 96, 10.0, false)
	_replace_animation_if_exists(body_frames, "unarmed_attack_heavy_up", UNARMED_HEAVY_NORTH_BODY_SHEET, 8, 0, 96, 96, 11.5, false)
	_replace_animation_if_exists(body_frames, "unarmed_attack_heavy_down", UNARMED_HEAVY_SOUTH_BODY_SHEET, 7, 0, 96, 96, 10.0, false)
	_replace_animation_if_exists(body_frames, "unarmed_idle", UNARMED_IDLE_SOUTH_BODY_SHEET, 8, 0, 96, 96, 8.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_idle_down", UNARMED_IDLE_SOUTH_BODY_SHEET, 8, 0, 96, 96, 8.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_idle_right", UNARMED_IDLE_EAST_BODY_SHEET, 6, 0, 96, 96, 8.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_idle_up", UNARMED_IDLE_NORTH_BODY_SHEET, 10, 0, 96, 96, 8.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_idle_left", UNARMED_IDLE_WEST_BODY_SHEET, 6, 0, 96, 96, 8.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_run_right", UNARMED_RUN_EAST_BODY_SHEET, 5, 0, 96, 96, 12.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_run_up", UNARMED_RUN_NORTH_BODY_SHEET, 6, 0, 96, 96, 12.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_run_down", UNARMED_RUN_SOUTH_BODY_SHEET, 7, 0, 96, 96, 12.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_run_left", UNARMED_RUN_WEST_BODY_SHEET, 5, 0, 96, 96, 12.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_run_down_right", UNARMED_RUN_SOUTHEAST_BODY_SHEET, 4, 0, 96, 96, 12.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_run_down_left", UNARMED_RUN_SOUTHWEST_BODY_SHEET, 4, 0, 96, 96, 12.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_stance", UNARMED_STANCE_EAST_BODY_SHEET, 6, 0, 96, 96, 8.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_stance_right", UNARMED_STANCE_EAST_BODY_SHEET, 6, 0, 96, 96, 8.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_stance_left", UNARMED_STANCE_WEST_BODY_SHEET, 6, 0, 96, 96, 8.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_light_hitreact", UNARMED_LIGHT_HITREACT_SOUTH_BODY_SHEET, 3, 0, 96, 96, 10.0, false)
	_replace_animation_if_exists(body_frames, "unarmed_light_hitreact_down", UNARMED_LIGHT_HITREACT_SOUTH_BODY_SHEET, 3, 0, 96, 96, 10.0, false)
	_replace_animation_if_exists(body_frames, "unarmed_walk", UNARMED_WALK_SOUTH_SHEET, 6, 0, 96, 96, 10.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_walk_down", UNARMED_WALK_SOUTH_SHEET, 6, 0, 96, 96, 10.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_walk_right", UNARMED_WALK_EAST_SHEET, 5, 0, 96, 96, 10.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_walk_up", UNARMED_WALK_NORTH_SHEET, 7, 0, 96, 96, 10.0, true)
	_replace_animation_if_exists(body_frames, "unarmed_walk_left", UNARMED_WALK_WEST_SHEET, 5, 0, 96, 96, 10.0, true)
	_replace_animation_entries(body_frames, UNARMED_MODULAR_LOWER_LOCOMOTION_SLICES)
	_replace_animation_entries(modular_lower_body_frames, UNARMED_MODULAR_LOWER_LOCOMOTION_SLICES)
	_replace_animation_entries(modular_lower_body_frames, _build_modular_sidearm_entries("lower_body", "sidearm_draw_lower", "draw_sidearm_01"))
	_replace_animation_entries(modular_lower_body_frames, _build_modular_sidearm_entries("lower_body", "sidearm_fire_lower", "fire_sidearm_01"))
	_replace_animation_entries(modular_lower_body_frames, _build_modular_unarmed_block_entries("lower_body"))
	_replace_animation_entries(modular_lower_body_frames, _build_modular_unarmed_parry_entries("lower_body"))
	_replace_animation_entries(modular_upper_body_frames, _build_modular_locomotion_entries("upper_body"))
	_replace_animation_entries(modular_upper_body_frames, _build_modular_upper_action_entries())
	_replace_animation_entries(modular_upper_body_frames, _build_modular_sidearm_entries("upper_body", "sidearm_draw_upper", "draw_sidearm_01"))
	_replace_animation_entries(modular_upper_body_frames, _build_modular_sidearm_entries("upper_body", "sidearm_fire_upper", "fire_sidearm_01"))
	_replace_animation_entries(modular_upper_body_frames, _build_modular_unarmed_block_entries("upper_body"))
	_replace_animation_entries(modular_upper_body_frames, _build_modular_unarmed_parry_entries("upper_body"))
	_replace_animation_entries(modular_lower_body_frames, _build_modular_ranged_stance_entries("lower_body"))
	_replace_animation_entries(modular_upper_body_frames, _build_modular_ranged_stance_entries("upper_body"))
	_replace_animation_entries(modular_sidearm_frames, _build_modular_sidearm_entries("sidearm", "sidearm_draw", "draw_sidearm_01"))
	_replace_animation_entries(modular_sidearm_frames, _build_modular_sidearm_entries("sidearm", "sidearm_fire", "fire_sidearm_01"))
	_replace_animation_entries(modular_sidearm_frames, _build_modular_ranged_stance_entries("ranged_weapon"))
	_replace_animation_entries(modular_upper_fx_frames, _build_modular_sidearm_entries("upper_fx", "sidearm_fire_fx", "fx_01"))
	_replace_animation_entries(modular_upper_fx_frames, _build_modular_sidearm_entries("upper_fx", "sidearm_draw_fx", "draw_sidearm_01"))
	_replace_animation_entries(modular_upper_fx_frames, _build_modular_sidearm_entries("upper_fx", "sidearm_fire_fx", "fire_sidearm_01"))
	_replace_animation_entries(modular_upper_fx_frames, _build_modular_unarmed_parry_fx_entries())
	_replace_animation_if_exists(body_frames, "unarmed_death", UNARMED_DEATH_BODY_SHEET, 6, 0, 96, 96, 7.0, false)
	_replace_animation_if_exists(body_frames, "unarmed_arrival", UNARMED_ARRIVAL_SOUTH_BODY_SHEET, 9, 0, 96, 96, 12.0, false)
	_replace_animation_if_exists(body_frames, "unarmed_arrival_down", UNARMED_ARRIVAL_SOUTH_BODY_SHEET, 9, 0, 96, 96, 12.0, false)
	_replace_animation(body_frames, "death", BASE_DEATH_SHEET, 9, 0, 128, 128, 7.0, false)
	_replace_animation_if_exists(body_frames, "ranged_2h_stance", RANGED_STANCE_EAST_BODY_SHEET, 12, 0, 96, 96, 8.0, true)
	_replace_animation_if_exists(body_frames, "ranged_2h_run_right", RANGED_RUN_BODY_SHEET, 5, 0, 96, 96, 14.0, true)
	_replace_animation_if_exists(body_frames, "ranged_2h_run_left", RANGED_RUN_WEST_BODY_SHEET, 5, 0, 96, 96, 14.0, true)
	_replace_animation_if_exists(body_frames, "operator_dodge_step", DODGE_STEP_BODY_SHEET, 4, 0, 96, 96, 18.0, false)
	_replace_animation_if_exists(body_frames, "operator_dodge_recovery", DODGE_RECOVERY_BODY_SHEET, 4, 0, 96, 96, 18.0, false)
	_replace_animation_if_exists(body_frames, "operator_dodge_backstep", DODGE_BACKSTEP_BODY_SHEET, 4, 0, 96, 96, 18.0, false)
	_replace_animation_if_exists(body_frames, "operator_dodge_backstep_recovery", DODGE_BACKSTEP_RECOVERY_BODY_SHEET, 4, 0, 96, 96, 18.0, false)
	_replace_animation_if_exists(body_frames, "operator_dodge_full_north", DODGE_FULL_NORTH_BODY_SHEET, 9, 0, 96, 96, 25.0, false)
	_replace_animation_if_exists(body_frames, "operator_dodge_full_south", DODGE_FULL_SOUTH_BODY_SHEET, 9, 0, 96, 96, 25.0, false)
	_replace_animation_if_exists(body_frames, "ranged_2h_reload", RELOAD_BODY_SHEET, 4, 0, 96, 96, 10.0, false)
	_replace_animation(body_frames, "melee_2h_block_enter", BLOCK_ENTER_BODY_SHEET, 4, 0, 96, 96, 10.0, false)
	_replace_animation(body_frames, "melee_2h_block_hold", BLOCK_HOLD_BODY_SHEET, 1, 0, 96, 96, 1.0, true)
	_replace_animation(body_frames, "melee_2h_block_exit", BLOCK_EXIT_BODY_SHEET, 2, 0, 96, 96, 10.0, false)

	_replace_animation_if_exists(weapon_frames, "equipped_run_right", RANGED_RUN_WEAPON_SHEET, 5, 0, 96, 96, 14.0, true)
	_replace_animation_if_exists(weapon_frames, "equipped_run_left", RANGED_RUN_WEST_WEAPON_SHEET, 5, 0, 96, 96, 14.0, true)

	_replace_animation(melee_overlay_frames, "melee_2h_heavy_anticipation_weapon", HEAVY_ANTICIPATION_SHEET, 5, 1, 96, 96, 11.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_heavy_weapon", HEAVY_ATTACK_SHEET, 7, 1, 96, 96, 11.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_heavy_fx", HEAVY_ATTACK_SHEET, 7, 2, 96, 96, 11.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_fast_1_weapon", FAST_ATTACK_1_SHEET, 6, 1, 96, 96, 12.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_fast_1_fx", FAST_ATTACK_1_SHEET, 6, 2, 96, 96, 12.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_fast_2_weapon", FAST_ATTACK_2_SHEET, 5, 1, 96, 96, 12.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_fast_2_fx", FAST_ATTACK_2_SHEET, 5, 2, 96, 96, 12.0, false)
	_replace_animation_if_exists(melee_overlay_frames, "melee_2h_fast_weapon", BASE_FAST_ATTACK_NORTH_WEAPON_SHEET, 6, 0, 96, 96, 12.0, false)
	_replace_animation_if_exists(melee_overlay_frames, "melee_2h_fast_fx", BASE_FAST_ATTACK_NORTH_FX_SHEET, 6, 0, 96, 96, 12.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_fast_recovery_weapon", FAST_RECOVERY_SHEET, 2, 1, 96, 96, 10.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_fast_recovery_fx", FAST_RECOVERY_SHEET, 2, 2, 96, 96, 10.0, false)
	_replace_animation_if_exists(melee_overlay_frames, "unarmed_attack_fast_recovery_fx_up", UNARMED_FAST_RECOVERY_NORTH_FX_SHEET, 2, 0, 96, 96, 10.0, false)
	_replace_animation_if_exists(melee_overlay_frames, "unarmed_attack_fast_fx_down", UNARMED_FAST_FX_SOUTH_SHEET, 6, 0, 96, 96, 12.0, false)
	_replace_animation_if_exists(melee_overlay_frames, "unarmed_attack_fast_fx_right", UNARMED_FAST_FX_EAST_SHEET, 3, 0, 96, 96, 12.0, false)
	_replace_animation_if_exists(melee_overlay_frames, "unarmed_attack_fast_fx_up", UNARMED_FAST_FX_NORTH_SHEET, 6, 0, 96, 96, 12.0, false)
	_replace_animation_entries(melee_overlay_frames, UNARMED_FAST_STRIKE_FX_SLICES)
	_replace_animation_if_exists(melee_overlay_frames, "unarmed_attack_heavy_fx_right", UNARMED_HEAVY_FX_EAST_SHEET, 7, 0, 96, 96, 10.0, false)
	_replace_animation_if_exists(melee_overlay_frames, "unarmed_attack_heavy_fx_left", UNARMED_HEAVY_FX_WEST_SHEET, 7, 0, 96, 96, 10.0, false)
	_replace_animation_if_exists(melee_overlay_frames, "unarmed_attack_heavy_fx_down", UNARMED_HEAVY_FX_SOUTH_SHEET, 7, 0, 96, 96, 10.0, false)
	_replace_animation_if_exists(melee_overlay_frames, "unarmed_attack_heavy_fx_up", UNARMED_HEAVY_FX_NORTH_SHEET, 8, 0, 96, 96, 11.5, false)
	_replace_animation_if_exists(melee_overlay_frames, "unarmed_light_hitreact_fx_down", UNARMED_LIGHT_HITREACT_FX_SOUTH_SHEET, 3, 0, 96, 96, 10.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_block_enter_weapon", BLOCK_ENTER_WEAPON_SHEET, 4, 0, 96, 96, 10.0, false)
	_replace_animation(melee_overlay_frames, "melee_2h_block_hold_weapon", BLOCK_HOLD_WEAPON_SHEET, 1, 0, 96, 96, 1.0, true)
	_replace_animation(melee_overlay_frames, "melee_2h_block_exit_weapon", BLOCK_EXIT_WEAPON_SHEET, 2, 0, 96, 96, 10.0, false)

	_replace_animation(ranged_fx_frames, "ranged_2h_fire_fx", FIRE_BODY_SHEET, 4, 2, 96, 96, 14.0, false)
	_replace_animation(ranged_fx_frames, "ranged_2h_reload_fx", OPERATOR_RELOADING_SHEET, 4, 1, 96, 96, 10.0, false)
	if _had_rebuild_error:
		quit(1)
		return

	ResourceSaver.save(body_frames, BODY_FRAMES_PATH)
	ResourceSaver.save(modular_lower_body_frames, MODULAR_LOWER_BODY_FRAMES_PATH)
	ResourceSaver.save(modular_upper_body_frames, MODULAR_UPPER_BODY_FRAMES_PATH)
	ResourceSaver.save(modular_sidearm_frames, MODULAR_SIDEARM_FRAMES_PATH)
	ResourceSaver.save(modular_upper_fx_frames, MODULAR_UPPER_FX_FRAMES_PATH)
	ResourceSaver.save(weapon_frames, WEAPON_FRAMES_PATH)
	ResourceSaver.save(melee_overlay_frames, MELEE_OVERLAY_FRAMES_PATH)
	ResourceSaver.save(ranged_fx_frames, RANGED_FX_FRAMES_PATH)
	quit()


func _replace_animation(
	sprite_frames: SpriteFrames,
	animation_name: String,
	texture_path: String,
	frame_count: int,
	row_index: int,
	frame_width: int,
	frame_height: int,
	speed: float,
	loop: bool
) -> void:
	if sprite_frames.has_animation(animation_name):
		sprite_frames.remove_animation(animation_name)
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_speed(animation_name, speed)
	sprite_frames.set_animation_loop(animation_name, loop)

	var texture := _load_texture(texture_path)
	if texture == null:
		_had_rebuild_error = true
		push_error("Missing texture for animation %s: %s" % [animation_name, texture_path])
		return

	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(frame_index * frame_width, row_index * frame_height, frame_width, frame_height)
		sprite_frames.add_frame(animation_name, atlas)


func _replace_animation_if_exists(
	sprite_frames: SpriteFrames,
	animation_name: String,
	texture_path: String,
	frame_count: int,
	row_index: int,
	frame_width: int,
	frame_height: int,
	speed: float,
	loop: bool
) -> void:
	if not _texture_file_exists(texture_path):
		print("Skipping optional operator animation %s; missing %s" % [animation_name, texture_path])
		return
	_replace_animation(sprite_frames, animation_name, texture_path, frame_count, row_index, frame_width, frame_height, speed, loop)


func _replace_animation_slice(
	sprite_frames: SpriteFrames,
	animation_name: String,
	texture_path: String,
	start_frame_index: int,
	frame_count: int,
	frame_width: int,
	frame_height: int,
	speed: float,
	loop: bool
) -> void:
	if sprite_frames.has_animation(animation_name):
		sprite_frames.remove_animation(animation_name)
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_speed(animation_name, speed)
	sprite_frames.set_animation_loop(animation_name, loop)

	var texture := _load_texture(texture_path)
	if texture == null:
		_had_rebuild_error = true
		push_error("Missing texture for animation %s: %s" % [animation_name, texture_path])
		return

	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2((start_frame_index + frame_index) * frame_width, 0, frame_width, frame_height)
		sprite_frames.add_frame(animation_name, atlas)


func _replace_sheet_slices(
	sprite_frames: SpriteFrames,
	texture_path: String,
	slices: Array,
	frame_width: int,
	frame_height: int
) -> void:
	for slice_data in slices:
		if not (slice_data is Dictionary):
			continue
		_replace_animation_slice(
			sprite_frames,
			str(slice_data.get("animation", "")),
			texture_path,
			int(slice_data.get("start", 0)),
			int(slice_data.get("count", 0)),
			frame_width,
			frame_height,
			float(slice_data.get("fps", 10.0)),
			true
		)


func _replace_animation_entries(sprite_frames: SpriteFrames, entries: Array) -> void:
	for entry in entries:
		if not (entry is Dictionary):
			continue
		_replace_animation_if_exists(
			sprite_frames,
			str(entry.get("animation", "")),
			str(entry.get("path", "")),
			int(entry.get("frames", 0)),
			int(entry.get("row", 0)),
			int(entry.get("frame_width", 96)),
			int(entry.get("frame_height", 96)),
			float(entry.get("fps", 12.0)),
			bool(entry.get("loop", false))
		)


func _build_modular_locomotion_entries(part: String) -> Array:
	var part_prefix := "operator__modular_%s__unarmed" % part
	var root := "res://content/sprites/operator/runtime/modules/new_operator/%s/locomotion" % part
	var entries: Array = []
	var action_specs := [
		{"action": "idle_01", "base": "unarmed_idle", "fps": 8.0},
		{"action": "walk_01", "base": "unarmed_walk", "fps": 10.0},
		{"action": "run_01", "base": "unarmed_run", "fps": 12.0},
	]
	var direction_specs := [
		{"dir": "s", "suffix": "down", "alias_base": true},
		{"dir": "se", "suffix": "down_right"},
		{"dir": "e", "suffix": "right"},
		{"dir": "ne", "suffix": "up_right"},
		{"dir": "n", "suffix": "up"},
		{"dir": "nw", "suffix": "up_left"},
		{"dir": "w", "suffix": "left"},
		{"dir": "sw", "suffix": "down_left"},
	]
	for action_spec in action_specs:
		var action := str(action_spec["action"])
		var base := str(action_spec["base"])
		for direction_spec in direction_specs:
			var dir := str(direction_spec["dir"])
			var path := "%s/%s/%s__%s__%s__5f__96.png" % [root, action, part_prefix, action, dir]
			if bool(direction_spec.get("alias_base", false)) and action != "run_01":
				entries.append({
					"animation": base,
					"path": path,
					"frames": 5,
					"frame_width": 96,
					"frame_height": 96,
					"fps": float(action_spec["fps"]),
					"loop": true,
				})
			entries.append({
				"animation": "%s_%s" % [base, str(direction_spec["suffix"])],
				"path": path,
				"frames": 5,
				"frame_width": 96,
				"frame_height": 96,
				"fps": float(action_spec["fps"]),
				"loop": true,
			})
	return entries


func _build_modular_upper_action_entries() -> Array:
	var root := "res://content/sprites/operator/runtime/modules/new_operator/upper_body/actions/unarmed/fast_attack/fast_strike_01"
	var entries: Array = []
	var direction_specs := [
		{"dir": "s", "suffix": "down", "alias_base": true},
		{"dir": "se", "suffix": "down_right"},
		{"dir": "e", "suffix": "right"},
		{"dir": "ne", "suffix": "up_right"},
		{"dir": "n", "suffix": "up"},
		{"dir": "nw", "suffix": "up_left"},
		{"dir": "w", "suffix": "left"},
		{"dir": "sw", "suffix": "down_left"},
	]
	for direction_spec in direction_specs:
		var dir := str(direction_spec["dir"])
		var path := "%s/operator__modular_upper_body__unarmed__fast_strike_01__%s__3f__96.png" % [root, dir]
		if bool(direction_spec.get("alias_base", false)):
			entries.append({
				"animation": "unarmed_fast_strike_upper",
				"path": path,
				"frames": 3,
				"frame_width": 96,
				"frame_height": 96,
				"fps": 12.0,
				"loop": false,
			})
		entries.append({
			"animation": "unarmed_fast_strike_upper_%s" % str(direction_spec["suffix"]),
			"path": path,
			"frames": 3,
			"frame_width": 96,
			"frame_height": 96,
			"fps": 12.0,
			"loop": false,
		})
	return entries


func _build_modular_sidearm_entries(part: String, base: String, action: String) -> Array:
	var action_root := "actions/%s" % action if part == "sidearm" else "actions/sidearm/%s" % action
	var root := "res://content/sprites/operator/runtime/modules/new_operator/%s/%s" % [part, action_root]
	var part_prefix := "operator__modular_%s__sidearm__%s" % [part, action]
	var entries: Array = []
	var direction_specs := [
		{"dir": "ne", "suffix": "up_right"},
		{"dir": "nw", "suffix": "up_left"},
		{"dir": "se", "suffix": "down_right", "alias_base": true},
		{"dir": "sw", "suffix": "down_left"},
	]
	for direction_spec in direction_specs:
		var path := "%s/%s__%s__5f__96.png" % [root, part_prefix, str(direction_spec["dir"])]
		if not _texture_file_exists(path):
			continue
		if bool(direction_spec.get("alias_base", false)):
			entries.append({
				"animation": base,
				"path": path,
				"frames": 5,
				"frame_width": 96,
				"frame_height": 96,
				"fps": 12.0,
				"loop": false,
			})
		entries.append({
			"animation": "%s_%s" % [base, str(direction_spec["suffix"])],
			"path": path,
			"frames": 5,
			"frame_width": 96,
			"frame_height": 96,
			"fps": 12.0,
			"loop": false,
		})
	return entries


func _build_modular_ranged_stance_entries(part: String) -> Array:
	var root := "res://content/sprites/operator/runtime/modules/new_operator/%s/actions/ranged_2h/stance_01" % part
	var entries: Array = []
	for direction_spec in [
		{"dir": "e", "suffix": "right", "alias_base": true},
		{"dir": "n", "suffix": "up"},
		{"dir": "w", "suffix": "left"},
	]:
		var path := "%s/operator__modular_%s__ranged_2h__stance_01__%s__5f__96.png" % [root, part, str(direction_spec["dir"])]
		if not _texture_file_exists(path):
			continue
		if bool(direction_spec.get("alias_base", false)):
			entries.append({"animation": "ranged_2h_stance_modular", "path": path, "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 8.0, "loop": true})
		entries.append({"animation": "ranged_2h_stance_modular_%s" % str(direction_spec["suffix"]), "path": path, "frames": 5, "frame_width": 96, "frame_height": 96, "fps": 8.0, "loop": true})
	return entries


func _build_modular_unarmed_block_entries(part: String) -> Array:
	var root := "res://content/sprites/operator/runtime/modules/new_operator/%s/actions/unarmed" % part
	var entries: Array = []
	var action_specs := [
		{"source": "enter_block_01", "base": "unarmed_block_enter", "fps": 10.0, "loop": false},
		{"source": "block_loop_01", "base": "unarmed_block_hold", "fps": 8.0, "loop": true},
		{"source": "blocking_hitreact_01", "base": "unarmed_block_hitreact", "fps": 14.0, "loop": false},
	]
	for action_spec in action_specs:
		var source := str(action_spec["source"])
		for direction_spec in [
			{"dir": "e", "suffix": "right", "alias_base": true},
			{"dir": "w", "suffix": "left"},
		]:
			var sheet := _find_modular_action_sheet(root, part, "unarmed", source, str(direction_spec["dir"]))
			if sheet.is_empty():
				continue
			if bool(direction_spec.get("alias_base", false)):
				entries.append({
					"animation": str(action_spec["base"]),
					"path": str(sheet["path"]),
					"frames": int(sheet["frames"]),
					"frame_width": 96,
					"frame_height": 96,
					"fps": float(action_spec["fps"]),
					"loop": bool(action_spec["loop"]),
				})
			entries.append({
				"animation": "%s_%s" % [str(action_spec["base"]), str(direction_spec["suffix"])],
				"path": str(sheet["path"]),
				"frames": int(sheet["frames"]),
				"frame_width": 96,
				"frame_height": 96,
				"fps": float(action_spec["fps"]),
				"loop": bool(action_spec["loop"]),
			})
	return entries


func _build_modular_unarmed_parry_entries(part: String) -> Array:
	var root := "res://content/sprites/operator/runtime/modules/new_operator/%s/actions/unarmed" % part
	var entries: Array = []
	var sheet := _find_modular_action_sheet(root, part, "unarmed", "parry_01", "n")
	if sheet.is_empty():
		return entries
	for animation in ["unarmed_parry", "unarmed_parry_up", "unarmed_parry_success", "unarmed_parry_success_up"]:
		entries.append({
			"animation": animation,
			"path": str(sheet["path"]),
			"frames": int(sheet["frames"]),
			"frame_width": 96,
			"frame_height": 96,
			"fps": 12.0,
			"loop": false,
		})
	return entries


func _find_modular_action_sheet(root: String, part: String, loadout: String, action: String, direction: String) -> Dictionary:
	var action_root := "%s/%s" % [root, action]
	var directory := DirAccess.open(action_root)
	if directory == null:
		return {}
	var pattern := RegEx.new()
	var compile_error := pattern.compile(
		"^operator__modular_%s__%s__%s__%s__([0-9]+)f__96\\.png$" % [part, loadout, action, direction]
	)
	if compile_error != OK:
		return {}
	for filename in directory.get_files():
		var matched := pattern.search(filename)
		if matched != null:
			return {
				"path": "%s/%s" % [action_root, filename],
				"frames": int(matched.get_string(1)),
			}
	return {}


func _build_modular_unarmed_parry_fx_entries() -> Array:
	var root := "res://content/sprites/operator/runtime/modules/new_operator/upper_fx/actions/unarmed"
	var entries: Array = []
	for direction_spec in [
		{"dir": "n", "suffix": "up", "alias_base": true},
		{"dir": "e", "suffix": "right"},
	]:
		var sheet := _find_modular_action_sheet(root, "upper_fx", "unarmed", "parry_01", str(direction_spec["dir"]))
		if sheet.is_empty():
			continue
		if bool(direction_spec.get("alias_base", false)):
			entries.append({"animation": "unarmed_parry_fx", "path": str(sheet["path"]), "frames": int(sheet["frames"]), "frame_width": 96, "frame_height": 96, "fps": 12.0, "loop": false})
			entries.append({"animation": "PLACEHOLDER_unarmed_parry_success_fx", "path": str(sheet["path"]), "frames": int(sheet["frames"]), "frame_width": 96, "frame_height": 96, "fps": 12.0, "loop": false})
		entries.append({"animation": "unarmed_parry_fx_%s" % str(direction_spec["suffix"]), "path": str(sheet["path"]), "frames": int(sheet["frames"]), "frame_width": 96, "frame_height": 96, "fps": 12.0, "loop": false})
		entries.append({"animation": "PLACEHOLDER_unarmed_parry_success_fx_%s" % str(direction_spec["suffix"]), "path": str(sheet["path"]), "frames": int(sheet["frames"]), "frame_width": 96, "frame_height": 96, "fps": 12.0, "loop": false})
	return entries


func _load_or_create_sprite_frames(resource_path: String) -> SpriteFrames:
	if not ResourceLoader.exists(resource_path) and not FileAccess.file_exists(ProjectSettings.globalize_path(resource_path)):
		return SpriteFrames.new()
	var frames := load(resource_path) as SpriteFrames
	if frames != null:
		return frames
	return SpriteFrames.new()


func _load_texture(texture_path: String) -> Texture2D:
	if ResourceLoader.exists(texture_path):
		var resource_texture := load(texture_path) as Texture2D
		if resource_texture != null:
			return resource_texture
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(texture_path))
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)


func _texture_file_exists(texture_path: String) -> bool:
	if ResourceLoader.exists(texture_path):
		return true
	return FileAccess.file_exists(ProjectSettings.globalize_path(texture_path))
