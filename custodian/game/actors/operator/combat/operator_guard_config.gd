class_name OperatorGuardConfig
extends Resource

@export_group("Guard")
@export var movement_multiplier := 0.60
@export var weak_start_time := 0.0
@export var full_activation_time := 0.10
@export var damage_reduction := 0.65
@export var minimum_chip_damage := 1.0
@export var base_stamina_cost := 12.0
@export var break_threshold := 6.0
@export var exit_speed_scale := 1.60
@export var light_stamina_multiplier := 0.75
@export var heavy_stamina_multiplier := 1.75
@export var interrupt_stamina_multiplier := 2.0
@export var light_recoil_time := 0.12
@export var heavy_recoil_time := 0.20
@export var break_impact_time := 0.08
@export var break_recovery_time := 0.40
@export var reraise_lockout_time := 1.50

@export_group("Parry")
@export var minimum_guard_time := 0.04
## Two authored frames at the parry strip's 12 FPS.
##
## `unarmed/defense/parry_01` spends frame 0 on anticipation and frame 1 raising
## the guard; the guard is only fully extended across frames 2-3, which is the
## visible catch. At 0.02 the active window ran 0.020-0.120 s and closed 47 ms
## before that extension even began, so gameplay caught what the art was still
## winding up for. Opening at 2/12 s puts the whole 0.10 s window inside the
## extended-guard frames.
##
## This is the art used as evidence for a deterministic value, not as authority:
## nothing at runtime reads an animation frame to decide whether a parry lands.
@export var parry_windup_time := 0.16667
@export var parry_active_time := 0.10
@export var parry_recovery_time := 0.16
@export var parry_success_recovery_time := 0.03
@export var parry_stamina_cost := 8.0
@export var parry_success_stamina_refund := 6.0
@export var parry_enemy_stagger_time := 0.55
@export var parry_enemy_knockback := 44.0
@export var counter_window_time := 0.45
@export var counter_damage_multiplier := 1.25
