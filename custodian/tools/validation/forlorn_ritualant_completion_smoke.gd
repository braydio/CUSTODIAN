extends SceneTree

const SITE_SCENE := preload("res://game/world/events/ash_bell/forlorn_ritualant_site.tscn")
const UNDERGROUND_SCENE := preload(
	"res://game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.tscn"
)
const SURFACE_LIFT_SCENE := preload(
	"res://game/world/approaches/ash_bell/ash_bell_lift_ingress_presentation.tscn"
)
const LIFT_ASSEMBLY_PATH := "res://game/world/approaches/ash_bell/ash_bell_lift_platform_assembly.tscn"
const KNOT_DESCRIPTION := "A funerary knot of unnaturally clean white thread. Names were tied into these before the dead were counted. The fibers pull taut near places that do not agree with their own history."


class FakeOperator:
	extends Node2D
	var damage_taken := 0.0
	var speed_multiplier_calls := 0

	func take_damage(amount: float) -> void:
		damage_taken += amount

	func apply_external_speed_multiplier(_multiplier: float, _duration: float) -> void:
		speed_multiplier_calls += 1

	func add_test_visual() -> void:
		var visual := ColorRect.new()
		visual.name = "Visual"
		visual.size = Vector2(12.0, 18.0)
		add_child(visual)


class RejectingExit:
	extends InteractableLevelExit2D

	func request_transition(_actor: Node) -> bool:
		return false


var errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_canonical_data()
	await _validate_encounter_runtime()
	await _validate_lower_lift()
	if errors.is_empty():
		print("[ForlornRitualantCompletionSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[ForlornRitualantCompletionSmoke] %s" % error)
	quit(1)


func _validate_canonical_data() -> void:
	var resources := _json("res://content/resources/resource_defs.json")
	var items := _json("res://content/items/lore/ash_bell_items.json")
	_check(str((resources.get("white_thread_knot", {}) as Dictionary).get("description", "")) == KNOT_DESCRIPTION, "resource Knot description drifted")
	var item_description := ""
	for item_variant in items.get("items", []):
		var item := item_variant as Dictionary
		if str(item.get("id", "")) == "white_thread_knot":
			item_description = str(item.get("description", ""))
	_check(item_description == KNOT_DESCRIPTION, "inventory Knot description drifted")
	var dialogue := _json("res://content/dialogue/ash_bell/forlorn_ritualant_dialogue.json")
	_check((dialogue.get("nodes", {}) as Dictionary).has("ninth_answer_bark"), "dialogue data lacks Ninth Answer bark")
	var stabilized := ((dialogue.get("nodes", {}) as Dictionary).get("stabilized_exit", {}) as Dictionary).get("lines", []) as Array
	_check(stabilized.size() == 3, "stabilized resolution does not own its three-beat cadence")
	if stabilized.size() == 3:
		_check(str((stabilized[0] as Dictionary).get("text", "")) == "Enough.", "stabilized resolution opening drifted")
		_check(str((stabilized[1] as Dictionary).get("text", "")) == "The thread has the count.", "stabilized resolution meaning drifted")


func _validate_encounter_runtime() -> void:
	var ledger := root.get_node_or_null("ResourceLedger")
	var inventory := root.get_node_or_null("InventoryManager")
	var memory := root.get_node_or_null("WorldEventMemory")
	ledger.call("clear")
	inventory.call("clear")
	inventory.call("add_item", &"white_thread_knot", 1)
	_check(int(ledger.call("get_amount", "white_thread_knot")) == 1, "Inventory Knot grant did not route to ResourceLedger")
	_check(int(inventory.call("get_count", &"white_thread_knot")) == 1, "inventory view did not read canonical Knot quantity")
	_check(not (inventory.call("get_all_items") as Dictionary).has(&"white_thread_knot"), "InventoryManager retained a second Knot quantity")
	var site := SITE_SCENE.instantiate() as ForlornRitualantSite
	root.add_child(site)
	var actor := FakeOperator.new()
	actor.name = "Operator"
	actor.add_test_visual()
	actor.add_to_group("player")
	root.add_child(actor)
	await process_frame
	_check(site.event_state.has_thread_knot, "site did not inherit upstream Knot")
	var before := int(ledger.call("get_amount", "white_thread_knot"))
	site.touch_thread()
	_check(int(ledger.call("get_amount", "white_thread_knot")) == before, "touch_thread granted duplicate Knot")
	_check(site.dialogue_presenter != null and site.dialogue_presenter.get_current_text().find("Forlorn-Ritualant waits beneath no bell") < 0, "obsolete no-bell production text remains")
	_check(
		site.dialogue_presenter.get_parent() is CanvasLayer,
		"production dialogue presenter is not screen-space"
	)
	site.dialogue_presenter.start(&"first_interaction", actor)
	_check(
		is_equal_approx(site.dialogue_presenter.background.offset_top, -204.0),
		"manual dialogue did not receive readable native-height layout"
	)
	var first_line := site.dialogue_presenter.get_current_text()
	site.dialogue_presenter.advance()
	_check(site.dialogue_presenter.get_current_text() != first_line, "dialogue did not advance on explicit input contract")
	actor.global_position = site.global_position + Vector2(400.0, 0.0)
	site.dialogue_presenter._process(0.0)
	_check(not site.dialogue_presenter.is_active(), "dialogue did not cancel outside interaction range")
	actor.global_position = site.global_position
	site.dialogue_presenter.open_menu(&"ritualant_root", actor)
	_check(
		is_equal_approx(site.dialogue_presenter.background.offset_top, -268.0),
		"dialogue menu did not receive expanded native-height layout"
	)
	site.dialogue_presenter.force_close()
	site.ask_about_bell()
	while site.dialogue_presenter.is_manual_active():
		site.dialogue_presenter.advance()
	if site.dialogue_presenter.is_menu_active():
		site.dialogue_presenter.close_menu()
	_check(bool(memory.call("is_completed", &"knowledge_ash_bell_ninth_answer")), "knowledge unlock was not persisted")
	var pin_interactable := site.get_node("Props/StillingPinPickup") as AshBellInteractable
	_check(pin_interactable.can_interact(actor), "Stilling Pin did not unlock from the Bell conversation branch")
	var hazard := site.get_node("Props/WhiteThreadHazard") as WhiteThreadHazard
	site.event_state.set_thread_tension(20, &"smoke_low")
	hazard._apply_slow(actor)
	_check(actor.speed_multiplier_calls == 0, "White Thread applied permanent low-tension slow")
	site.event_state.set_thread_tension(60, &"smoke_threshold")
	hazard._apply_slow(actor)
	_check(actor.speed_multiplier_calls == 1, "White Thread did not apply slow at authored threshold")

	var npc := site.get_node("NPCs/ForlornRitualant") as ForlornRitualantNPC
	npc.target = actor
	npc.site = site
	site.event_state.ritualant_hostile = true
	npc.phase = ForlornRitualantNPC.Phase.HOSTILE
	npc.pin_windup_seconds = 0.03
	actor.global_position = npc.global_position + Vector2(150.0, 0.0)
	npc.debug_force_attack(&"pin_strike")
	await create_timer(0.08).timeout
	_check(actor.damage_taken == 0.0, "Pin Strike damaged an out-of-range target")

	site.dialogue_presenter.start(&"first_interaction", actor)
	actor.global_position = npc.global_position + Vector2(20.0, 0.0)
	var dialogue_damage_before := actor.damage_taken
	npc.debug_force_attack(&"pin_strike")
	await create_timer(0.08).timeout
	_check(
		actor.damage_taken == dialogue_damage_before,
		"Ritualant damaged actor while locking dialogue owned input"
	)
	site.dialogue_presenter.force_close()

	site.set_player_inside_fountain(true)
	site.event_state.set_silence_pressure(10, &"test")
	site.dialogue_presenter.start(&"first_interaction", actor)
	var pressure_before_dialogue := site.event_state.silence_pressure
	await create_timer(site.fountain_pressure_tick_seconds + 0.25).timeout
	_check(
		site.event_state.silence_pressure == pressure_before_dialogue,
		"fountain pressure advanced while dialogue locked actor"
	)
	site.dialogue_presenter.force_close()
	site.set_player_inside_fountain(false)
	npc.thread_pull_windup_seconds = 0.03
	actor.global_position = npc.global_position + Vector2(120.0, 0.0)
	var pull_start := actor.global_position
	npc.debug_force_attack(&"thread_pull")
	await create_timer(0.08).timeout
	_check(actor.global_position.distance_to(npc.global_position) < pull_start.distance_to(npc.global_position), "Thread Pull did not provide bounded midrange control")

	npc.ninth_answer_windup_seconds = 0.06
	npc.debug_force_attack(&"ninth_answer")
	await create_timer(0.02).timeout
	_check(site.ghost_procession.visible, "Ninth Answer lane was not telegraphed")
	actor.global_position.x += 90.0
	var damage_before := actor.damage_taken
	await create_timer(0.08).timeout
	_check(actor.damage_taken == damage_before, "Ninth Answer hit after leaving telegraphed lane")

	npc.orra_late_delay_seconds = 0.05
	var orra_start := actor.global_position
	npc.debug_force_attack(&"orra_late")
	await create_timer(0.02).timeout
	_check(site.unarrived_apparition.visible, "Orra Comes Late did not appear behind target")
	actor.global_position = orra_start + Vector2(80.0, 0.0)
	var pressure_before := site.event_state.silence_pressure
	await create_timer(0.08).timeout
	_check(site.event_state.silence_pressure == pressure_before, "Orra reaction was unavoidable after moving")

	var snap_count := [0]
	site.event_state.thread_snapped.connect(func() -> void: snap_count[0] += 1)
	site.event_state.set_thread_tension(100, &"smoke")
	site.event_state.set_thread_tension(100, &"smoke_repeat")
	_check(snap_count[0] == 1, "thread snap did not execute exactly once")
	var cut_site := SITE_SCENE.instantiate() as ForlornRitualantSite
	root.add_child(cut_site)
	await process_frame
	cut_site.cut_thread()
	await create_timer(4.5).timeout
	_check(cut_site.event_state.ritualant_hostile, "explicit thread cut did not provoke Ritualant")
	_check(cut_site.event_state.resolution == AshBellEventState.Resolution.PROVOKED_RITUALANT, "thread snap did not supersede CUT_THREAD resolution")
	var captured := cut_site.capture_encounter_state()
	var restored_site := SITE_SCENE.instantiate() as ForlornRitualantSite
	root.add_child(restored_site)
	await process_frame
	_check(restored_site.restore_encounter_state(captured), "encounter snapshot did not restore")
	_check(restored_site.event_state.ritualant_hostile, "restored encounter lost hostile state")
	_check(restored_site.event_state.resolution == AshBellEventState.Resolution.PROVOKED_RITUALANT, "restored encounter lost resolution")
	cut_site.queue_free()
	restored_site.queue_free()
	var phantom_site := SITE_SCENE.instantiate() as ForlornRitualantSite
	root.add_child(phantom_site)
	await process_frame
	phantom_site.set_player_inside_fountain(true)
	phantom_site.event_state.set_resolution(AshBellEventState.Resolution.SITE_STABILIZED)
	await create_timer(3.25).timeout
	_check(
		not phantom_site.dialogue_presenter.is_active(),
		"terminal fountain zone emitted phantom Ritualant dialogue"
	)
	phantom_site.queue_free()

	site.dialogue_presenter.open_menu(&"ritualant_root", actor)
	_check(site.can_resolve_thread_anchor(&"west"), "WEST anchor did not unlock after a Ritualant exchange")
	_check(not site.can_resolve_thread_anchor(&"north"), "NORTH anchor unlocked out of ritual order")
	site.resolve_thread_anchor(&"west")
	_check(not site.can_resolve_thread_anchor(&"north"), "NORTH anchor unlocked without another Ritualant exchange")
	npc.attack_started.emit()
	site.resolve_thread_anchor(&"north")
	_check(not site.can_resolve_thread_anchor(&"east"), "EAST anchor unlocked without another Ritualant exchange")
	npc.attack_started.emit()
	site.resolve_thread_anchor(&"east")
	await create_timer(0.05).timeout
	_check(
		not site.dialogue_presenter.is_menu_active(),
		"Ritualant menu survived terminal stabilization"
	)
	_check(
		not site.can_speak_to_ritualant(),
		"terminal Ritualant remained conversational"
	)
	_check(site.debug_get_resolved_thread_anchor_count() == 3, "three-anchor route did not resolve")
	_check(site.event_state.resolution == AshBellEventState.Resolution.SITE_STABILIZED, "three anchors did not stabilize site")
	_check(site.get_departure_lines().is_empty(), "stabilized lift repeated Ritualant payoff")
	var contracts := npc.debug_get_animation_contract()
	_check(contracts.size() == 4, "missing action animation contracts are not explicit")
	site.queue_free()
	actor.queue_free()
	await process_frame


func _validate_lower_lift() -> void:
	var level := UNDERGROUND_SCENE.instantiate() as ForlornRitualantUnderground
	root.add_child(level)
	var surface := SURFACE_LIFT_SCENE.instantiate() as AshBellLiftIngressPresentation
	root.add_child(surface)
	var exit := level.get_node("Exits/Exit_ReturnWorld") as InteractableLevelExit2D
	var lift := level.get_node("PropsRoot/LowerLiftAssembly") as AshBellLiftPlatformAssembly
	var surface_lift := surface.get_node("LiftRoot") as AshBellLiftPlatformAssembly
	_check(lift.scene_file_path == LIFT_ASSEMBLY_PATH, "lower lift does not instance shared assembly")
	_check(surface_lift.scene_file_path == LIFT_ASSEMBLY_PATH, "surface lift does not instance shared assembly")
	var actor := FakeOperator.new()
	actor.name = "Operator"
	actor.add_test_visual()
	actor.add_to_group("player")
	root.add_child(actor)
	actor.global_position = lift.get_boarding_position()
	await process_frame
	actor.global_position = exit.global_position + Vector2(140.0, 0.0)
	_check(
		exit.get_interaction_prompt().is_empty(),
		"lower lift showed ASCEND prompt while actor was not boarded"
	)
	actor.global_position = lift.get_boarding_position()
	level.ritualant_site.event_state.set_resolution(
		AshBellEventState.Resolution.SITE_DEFILED
	)
	for offset_x in [-68.0, 0.0, 68.0]:
		actor.global_position = lift.global_position + Vector2(offset_x, -26.0)
		_check(
			lift.is_actor_boarded(actor),
			"visible lower-lift deck rejected boarded actor at x=%s" % offset_x
		)
		_check(
			exit.get_interaction_prompt() == "ASCEND TO SURFACE",
			"visible lower-lift deck lacked ASCEND prompt at x=%s" % offset_x
		)
	actor.global_position = lift.get_boarding_position()
	var transitions := [0]
	exit.transition_requested.connect(func(_id: StringName, _actor: Node) -> void: transitions[0] += 1)
	exit.body_entered.emit(actor)
	await process_frame
	_check(transitions[0] == 0, "walking onto lower lift triggered route travel")
	exit.arm_arrival_guard(actor)
	_check(not exit.can_interact(actor), "arrival guard allowed immediate lower-lift bounce")
	actor.global_position = exit.global_position + Vector2(140.0, 0.0)
	exit._physics_process(0.0)
	actor.global_position = lift.get_boarding_position()
	_check(exit.can_interact(actor), "boarded actor cannot interact with lower lift")
	exit.interact(actor)
	await create_timer(0.4).timeout
	_check(lift.position.y < 1696.0, "lower lift did not move during ascent")
	_check(lift.get_node("RiderAnchor").get_child_count() > 0, "lower lift did not carry a presentation rider")
	await create_timer(2.0).timeout
	_check(transitions[0] == 1, "E-style lower-lift interaction did not request route once")

	var rollback_level := UNDERGROUND_SCENE.instantiate() as ForlornRitualantUnderground
	root.add_child(rollback_level)
	var rollback_actor := FakeOperator.new()
	rollback_actor.name = "OperatorRollback"
	rollback_actor.add_to_group("player")
	rollback_actor.add_test_visual()
	root.add_child(rollback_actor)
	await process_frame
	var rollback_lift := rollback_level.lower_lift
	rollback_actor.global_position = rollback_lift.get_boarding_position()
	rollback_level.ritualant_site.event_state.set_resolution(
		AshBellEventState.Resolution.SITE_DEFILED
	)
	var rejecting_exit := RejectingExit.new()
	rejecting_exit.exit_id = &"return_world"
	var rejecting_shape := CollisionShape2D.new()
	rejecting_shape.name = "CollisionShape2D"
	rejecting_shape.shape = CircleShape2D.new()
	rejecting_exit.add_child(rejecting_shape)
	root.add_child(rejecting_exit)
	var actor_physics_before := rollback_actor.is_physics_processing()
	rollback_level.begin_lift_departure(rollback_actor, rejecting_exit)
	await create_timer(3.4).timeout
	_check(not rollback_level.debug_is_departure_running(), "failed transition wedged departure")
	_check(rollback_lift.position.y == 1696.0, "failed transition did not restore lift Y")
	_check(is_equal_approx(rollback_level.departure_black.modulate.a, 0.0), "failed transition left black overlay visible")
	_check(rollback_actor.is_physics_processing() == actor_physics_before, "failed transition did not restore actor physics state")
	rollback_level.queue_free()
	rollback_actor.queue_free()
	rejecting_exit.queue_free()
	level.queue_free()
	surface.queue_free()
	actor.queue_free()
	await process_frame


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	return parsed as Dictionary if parsed is Dictionary else {}


func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
