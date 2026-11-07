extends Node2D

## Dev-only, reversible playable preview of the corrected 3D-rendered Operator candidates.
##
## The real Awakening scene is instantiated intact. The real Operator keeps its movement, input,
## collision, camera and shadow (its _physics_process is untouched). Only its per-frame sprite
## presentation (_process) is paused on this instance, and the 3D candidate body is acquired
## through OperatorBodyPresenter as the single visible body.
##
## Controls (preview only):
##   F3 toggle 3D preview <-> original presentation    F4 toggle inspect mode
##   F5 toggle 80 / 50 px/m candidate                  F6 toggle physical-size match (50 px/m scaled x1.6)
##   [ ]  previous / next action        (inspect)      ; '  previous / next direction (inspect)
##   , .  previous / next frame         (inspect)      SPACE pause playback
##   -  =  preview FPS down / up (6..60, preview only)
## Movement: the game's own controls (arrows/WASD) move the Operator; hold sprint to run.

const AWAKENING := preload("res://scenes/awakening_first_return.tscn")
const Catalog := preload("res://tools/debug/operator_3d_preview_catalog.gd")
const PreviewSprite := preload("res://tools/debug/operator_3d_preview_sprite.gd")
const OWNER_3D := OperatorBodyPresenter.Owner.PREVIEW_3D_CANDIDATE
const ACTIONS := ["walking", "running", "alert", "casual_walk", "dead", "run_03", "runfast",
		"skill_01", "skill_03", "triple_combo_attack", "unsteady_walk"]
const MOVE_THRESHOLD := 8.0
const DEFAULT_FPS := 24.0

var awakening: Node
var operator: CharacterBody2D
var body: Sprite2D
var presenter: RefCounted
var catalog := Catalog.new()

var preview_on := true
var inspect := false
var scale_px_m := 80
var physical_match := false
var fps := DEFAULT_FPS
var paused := false
var clock := 0.0
var action_index := 0
var direction_index := 0
var frame_index := 0
var last_direction := "S"
var current_action := "walking"
var current_direction := "S"
var current_frame := 0
var preempted_count := 0
var idle := false

var _label: Label


func _ready() -> void:
	awakening = AWAKENING.instantiate()
	awakening.name = "Awakening"
	add_child(awakening)
	move_child(awakening, 0)
	operator = awakening.get_node("World/Operator") as CharacterBody2D
	presenter = operator.get("_body_presenter") as RefCounted
	if presenter == null:
		push_error("[Operator3DPreview] Operator has no body presenter; preview cannot start")
		return
	body = PreviewSprite.new()
	body.name = "Operator3DPreviewBody"
	body.centered = false
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var legacy := operator.get("animated_sprite") as CanvasItem
	body.z_index = legacy.z_index if legacy != null else 0
	operator.add_child(body)
	if not bool(presenter.call("register_body_layers", OWNER_3D, [body])):
		push_error("[Operator3DPreview] presenter rejected registration of the 3D body")
	# Stop the Operator's per-frame sprite presentation only. Movement stays in _physics_process.
	operator.set_process(false)
	_acquire()
	_build_label()
	_refresh()


func _acquire() -> bool:
	var plan := OperatorBodyPresentationPlan.create(OWNER_3D, [body])
	var ok: bool = presenter.call("present", plan)
	if not ok:
		push_error("[Operator3DPreview] presenter refused the 3D body")
	return ok


func _release() -> void:
	operator.set_process(true)
	presenter.call("present_legacy_full_body")


func _build_label() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(12, 12)
	_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 4)
	layer.add_child(_label)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F3:
			preview_on = not preview_on
			if preview_on:
				operator.set_process(false)
				_acquire()
			else:
				_release()
		KEY_F4:
			inspect = not inspect
			if inspect:
				paused = true
		KEY_F5:
			scale_px_m = 50 if scale_px_m == 80 else 80
			if not catalog.has_action(scale_px_m, ACTIONS[action_index]):
				scale_px_m = 80
		KEY_F6:
			physical_match = not physical_match
		KEY_BRACKETLEFT:
			action_index = posmod(action_index - 1, ACTIONS.size())
		KEY_BRACKETRIGHT:
			action_index = posmod(action_index + 1, ACTIONS.size())
		KEY_SEMICOLON:
			direction_index = posmod(direction_index - 1, Catalog.DIRECTIONS.size())
		KEY_APOSTROPHE:
			direction_index = posmod(direction_index + 1, Catalog.DIRECTIONS.size())
		KEY_COMMA:
			frame_index -= 1
			paused = true
		KEY_PERIOD:
			frame_index += 1
			paused = true
		KEY_SPACE:
			paused = not paused
		KEY_MINUS:
			fps = maxf(6.0, fps - 3.0)
		KEY_EQUAL:
			fps = minf(60.0, fps + 3.0)
	_refresh()


func _process(delta: float) -> void:
	if not preview_on or presenter == null:
		return
	# Gameplay may reacquire the body for another owner. The 3D candidate must stay the only body.
	if int(presenter.call("current_owner")) != OWNER_3D:
		preempted_count += 1
		_acquire()
	if not paused:
		clock += delta
	_choose_presentation(delta)
	_refresh()


func _choose_presentation(_delta: float) -> void:
	if inspect:
		current_action = ACTIONS[action_index]
		current_direction = Catalog.DIRECTIONS[direction_index]
		idle = false
	else:
		var v := operator.velocity
		if v.length() >= MOVE_THRESHOLD:
			current_direction = Catalog.direction_for_velocity(v)
			last_direction = current_direction
			current_action = "running" if Input.is_action_pressed("sprint") else "walking"
			idle = false
		else:
			# No 80 px/m idle exists in the candidate set; hold the walking pose facing the last heading.
			current_action = "walking"
			current_direction = last_direction
			idle = true
	var scale_now := scale_px_m
	if not catalog.has_action(scale_now, current_action):
		scale_now = 80
	var total := catalog.frame_count(scale_now, current_action)
	if total <= 0:
		return
	if inspect:
		current_frame = posmod(frame_index, total)
	elif idle:
		current_frame = 0
	else:
		var step := int(floor(clock * fps))
		current_frame = posmod(step, total) if catalog.loop(scale_now, current_action) else mini(step, total - 1)
	frame_index = current_frame
	_show(scale_now)


func _show(scale_now: int) -> void:
	var tex := catalog.texture(scale_now, current_action, current_direction, current_frame)
	if tex == null:
		return
	body.texture = tex
	body.offset = -catalog.pivot(scale_now, current_action)
	var s := 1.0
	if physical_match and scale_now == 50:
		s = 80.0 / 50.0
	body.scale = Vector2(s, s)


func _refresh() -> void:
	if _label == null:
		return
	var mode := "3D PREVIEW" if preview_on else "ORIGINAL PRESENTATION"
	var owner_name := "unknown"
	if presenter != null:
		var owner_value := int(presenter.call("current_owner"))
		owner_name = "PREVIEW_3D" if owner_value == OWNER_3D else str(owner_value)
	var n := catalog.frame_count(scale_px_m, current_action)
	var lines := PackedStringArray()
	lines.append("%s | owner %s | preempted %d" % [mode, owner_name, preempted_count])
	lines.append("%s %s | frame %d/%d | %d px/m%s | fps %d%s" % [
		current_action, current_direction, current_frame + 1, n, scale_px_m,
		" (physical match)" if physical_match and scale_px_m == 50 else "",
		int(fps), " | PAUSED" if paused else ""])
	if idle:
		lines.append("idle: no matching 80 px/m idle; holding walking frame 0 (preview only)")
	if inspect:
		lines.append("INSPECT: [ ] action  ; ' direction  , . frame  SPACE pause")
	lines.append("F3 mode  F4 inspect  F5 scale  F6 physical  -/= fps")
	_label.text = "\n".join(lines)
