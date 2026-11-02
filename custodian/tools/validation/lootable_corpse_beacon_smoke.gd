extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const MARKER_SCENE := preload("res://game/vfx/loot/loot_corpse_marker.tscn")
const VAULT_STORAGE_SCENE := preload("res://game/actors/storage/vault_storage.tscn")
const LOOT_FX_ROOT := "res://content/sprites/effects/loot_marker/runtime/fx/interaction/"
const REVEAL_TEXTURE := LOOT_FX_ROOT + "loot_marker__fx__interaction__reveal__omni__8f__96.png"
const BEACON_TEXTURE := LOOT_FX_ROOT + "loot_marker__fx__interaction__beacon_loop__9f__48x160.png"
const COLLAPSE_TEXTURE := LOOT_FX_ROOT + "loot_marker__fx__interaction__collect_collapse__omni__8f__96x160.png"
const OBSOLETE_COLLAPSE_TEXTURE := LOOT_FX_ROOT + "loot_marker__fx__interaction__collect_collapse__omni__6f__96x160.png"
const RING_TEXTURE := LOOT_FX_ROOT + "loot_marker__fx__interaction__ground_ring_loop__omni__6f__96.png"
const LOOT_TOAST_QUEUE_SCENE := preload("res://game/ui/loot/loot_toast_queue.tscn")

var _failed := false
var _vault_recovery_seen: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	root.name = "LootableCorpseBeaconSmokeRoot"
	get_root().add_child(root)
	current_scene = root
	root.add_child(LOOT_TOAST_QUEUE_SCENE.instantiate())
	var navigation_stub := Node.new()
	navigation_stub.add_to_group("navigation")
	root.add_child(navigation_stub)
	await process_frame

	_validate_marker_contract(root)
	await _validate_corpse_delivery(root)
	await _validate_lifecycle_contract(root)

	if _failed:
		push_error("lootable_corpse_beacon_smoke failed")
		quit(1)
		return
	print("lootable_corpse_beacon_smoke passed")
	quit()


func _validate_marker_contract(root: Node) -> void:
	_validate_runtime_sheets()
	var marker := MARKER_SCENE.instantiate()
	root.add_child(marker)
	var reveal := marker.get_node("Reveal") as AnimatedSprite2D
	var beam_lower := marker.get_node("BeamLower") as AnimatedSprite2D
	var beam_tip := marker.get_node("BeamTip") as AnimatedSprite2D
	var ring := marker.get_node("GroundRing") as AnimatedSprite2D
	var collapse := marker.get_node("CollectCollapse") as AnimatedSprite2D
	_assert_true(marker.z_index == 0, "marker root must inherit corpse depth at z_index 0")
	_assert_true(marker.z_as_relative, "marker root must use relative corpse depth")
	_assert_true(ring.z_as_relative and ring.z_index <= 0, "ground ring must remain at or below corpse depth")
	_assert_true(beam_lower.z_as_relative and beam_lower.z_index == 0, "lower beam must inherit corpse depth")
	_assert_true(beam_lower.animation == &"beacon_lower_loop", "lower beam must use its cropped loop")
	_assert_true(not beam_tip.z_as_relative, "beam tip must use absolute depth")
	_assert_true(beam_tip.z_index > 100, "beam tip must remain above ordinary world sprites")
	_assert_true(beam_tip.animation == &"beacon_tip_loop", "beam tip must use its cropped loop")
	_assert_true(reveal.z_as_relative and reveal.z_index == 0, "reveal must remain at corpse depth")
	_assert_true(collapse.z_as_relative and collapse.z_index == 0, "collection collapse must remain at corpse depth")
	_assert_true(reveal.sprite_frames.get_frame_count(&"reveal") == 8, "reveal must expose 8 frames")
	_assert_true(ring.sprite_frames.get_frame_count(&"ground_ring_loop") == 6, "ground ring must expose 6 frames")
	# Intake limitation is intentional and documented: current workspace art has
	# 9 beacon cells and 8 collapse cells rather than the requested 8/6 source.
	_assert_true(beam_lower.sprite_frames.get_frame_count(&"beacon_loop") == 9, "compatibility beacon loop must retain all 9 supplied cells")
	_assert_true(beam_lower.sprite_frames.get_frame_count(&"beacon_lower_loop") == 9, "lower beam must expose all 9 supplied cells")
	_assert_true(beam_tip.sprite_frames.get_frame_count(&"beacon_tip_loop") == 9, "beam tip must expose all 9 supplied cells")
	_assert_true(is_equal_approx(beam_lower.sprite_frames.get_animation_speed(&"beacon_lower_loop"), 9.0), "lower beam must run at 9 FPS")
	_assert_true(is_equal_approx(beam_tip.sprite_frames.get_animation_speed(&"beacon_tip_loop"), 9.0), "beam tip must run at 9 FPS")
	_validate_beam_crops(beam_lower.sprite_frames)
	for category in [&"common_salvage", &"power", &"signal", &"anomaly"]:
		marker.call("set_category", category)
		_assert_true(beam_lower.modulate == beam_tip.modulate, "%s hue must affect both beam pieces" % category)
		_assert_true(is_equal_approx(beam_lower.scale.y, beam_tip.scale.y), "%s scale must affect both beam pieces" % category)
		var lower_top := beam_lower.position.y - 68.0 * beam_lower.scale.y
		var tip_bottom := beam_tip.position.y + 16.0 * beam_tip.scale.y
		_assert_true(tip_bottom + 0.01 >= lower_top + 8.0 * beam_lower.scale.y, "%s beam scale must preserve the scaled 8 px lower/tip overlap" % category)
	_assert_true(collapse.sprite_frames.get_frame_count(&"collect_collapse") == 8, "current review collapse must expose all 8 supplied cells")
	marker.queue_free()


func _validate_runtime_sheets() -> void:
	_assert_texture_size(REVEAL_TEXTURE, Vector2i(768, 96))
	_assert_texture_size(BEACON_TEXTURE, Vector2i(432, 160))
	_assert_texture_size(COLLAPSE_TEXTURE, Vector2i(768, 160))
	_assert_texture_size(RING_TEXTURE, Vector2i(576, 96))
	_assert_true(
		not ResourceLoader.exists(OBSOLETE_COLLAPSE_TEXTURE),
		"obsolete collapse sheet with the false 6-frame filename must remain retired"
	)


func _assert_texture_size(path: String, expected_size: Vector2i) -> void:
	var texture := load(path) as Texture2D
	_assert_true(texture != null, "%s must load as a Texture2D" % path)
	if texture == null:
		return
	_assert_true(
		Vector2i(texture.get_size()) == expected_size,
		"%s must be %s, got %s" % [path, expected_size, Vector2i(texture.get_size())]
	)


func _validate_beam_crops(frames: SpriteFrames) -> void:
	for frame_index in range(9):
		var lower := frames.get_frame_texture(&"beacon_lower_loop", frame_index) as AtlasTexture
		var tip := frames.get_frame_texture(&"beacon_tip_loop", frame_index) as AtlasTexture
		var source_x := float(frame_index * 48)
		_assert_true(lower != null and lower.region == Rect2(source_x, 24.0, 48.0, 136.0), "lower crop %d must use source Y 24-159" % frame_index)
		_assert_true(tip != null and tip.region == Rect2(source_x, 0.0, 48.0, 32.0), "tip crop %d must use source Y 0-31" % frame_index)


func _validate_corpse_delivery(root: Node) -> void:
	var ledger := get_root().get_node_or_null("ResourceLedger")
	var game_state := get_root().get_node_or_null("GameState")
	var vault := get_root().get_node_or_null("VaultManager")
	_assert_true(ledger != null and game_state != null and vault != null, "reward destination autoloads must exist")
	if ledger == null or game_state == null or vault == null:
		return
	ledger.call("clear")
	var materials_before := int(game_state.get("materials"))
	if vault.has_signal("stolen_resources_recovered"):
		vault.connect("stolen_resources_recovered", _on_vault_recovered)
	var recovery_storage := VAULT_STORAGE_SCENE.instantiate()
	root.add_child(recovery_storage)
	vault.call("register_storage", recovery_storage)

	var grunt := GRUNT_SCENE.instantiate()
	root.add_child(grunt)
	var carrier := grunt.get_node("EnemyLootCarrier")
	carrier.call("set_payload", {&"power_components": 1})
	grunt.die()
	var payload := (grunt.get_lifecycle_debug_state().get("pending_payload", {}) as Dictionary)
	var rolled_ruin_scrap := int((payload["resource_ledger"] as Dictionary).get(&"ruin_scrap", 0))
	_assert_true(rolled_ruin_scrap >= 1, "death roll must determine guaranteed typed loot once")
	_assert_true(int((payload["vault_recovery"] as Dictionary).get(&"power_components", 0)) == 1, "carried loot must transfer into vault channel")
	_assert_true(not bool(carrier.call("is_carrying_loot")), "take_payload must clear the carrier")
	_assert_true(int(ledger.call("get_amount", "ruin_scrap")) == 0, "death determination must not award typed loot")

	grunt.complete_death_presentation()
	var corpse_loot := grunt.get_node_or_null("CorpseLoot")
	_assert_true(corpse_loot != null and bool(corpse_loot.call("has_loot")), "lootable corpse must survive finalization")
	_assert_true(int(grunt.get("life_state")) == 2, "corpse must enter LOOTABLE_CORPSE")
	_assert_true(not grunt.advance_corpse_lifecycle(120.0), "lootable corpse must ignore empty cleanup")
	_assert_true(not grunt.is_queued_for_deletion(), "lootable corpse must ignore empty cleanup")

	await create_timer(0.65).timeout
	var marker := corpse_loot.get_node_or_null("LootCorpseMarker")
	_assert_true(marker != null, "corpse marker must exist after reveal")
	if marker != null:
		_assert_true((marker.get_node("BeamLower") as AnimatedSprite2D).visible, "reveal must show the lower beam")
		_assert_true((marker.get_node("BeamTip") as AnimatedSprite2D).visible, "reveal must show the beam tip")
		_assert_true((marker.get_node("GroundRing") as AnimatedSprite2D).visible, "reveal must transition to ground-ring loop")

	var collector := CharacterBody2D.new()
	collector.name = "Operator"
	collector.add_to_group("player")
	root.add_child(collector)
	var ledger_before_collection := int(ledger.call("get_amount", "ruin_scrap"))
	corpse_loot.call("_on_body_entered", collector)
	var second_collect := bool(corpse_loot.call("collect", collector))
	_assert_true(
		int(ledger.call("get_amount", "ruin_scrap")) > ledger_before_collection,
		"body_entered proximity collection must succeed"
	)
	_assert_true(not second_collect, "second collection must award nothing")
	await process_frame
	_assert_true(
		not corpse_loot.monitoring and not corpse_loot.monitorable,
		"collection must defer-disable both Area2D monitoring flags"
	)
	if marker != null:
		var lower := marker.get_node("BeamLower") as AnimatedSprite2D
		var tip := marker.get_node("BeamTip") as AnimatedSprite2D
		_assert_true(not lower.visible and not lower.is_playing(), "collection must hide and stop the lower beam")
		_assert_true(not tip.visible and not tip.is_playing(), "collection must hide and stop the beam tip")
	_assert_true(int(ledger.call("get_amount", "ruin_scrap")) == rolled_ruin_scrap, "typed loot must reach ResourceLedger")
	_assert_true(int(_vault_recovery_seen.get(&"power_components", 0)) == 1, "carried loot must reach VaultManager")
	var toast_queue := get_first_node_in_group("loot_toast_queue")
	_assert_true(toast_queue != null, "loot toast queue must be available")
	if toast_queue != null:
		var toast_entries := toast_queue.get("_entries") as Array
		_assert_true(toast_entries.size() >= 2, "enemy corpse collection must show typed and recovered-resource toasts")
		var has_loot_table_toast := false
		var has_vault_recovery_toast := false
		for entry in toast_entries:
			if entry.get("item_id") == &"ruin_scrap":
				has_loot_table_toast = true
			if entry.get("item_id") == &"vault_resources":
				has_vault_recovery_toast = true
		_assert_true(has_loot_table_toast, "enemy loot table resource must produce a pickup toast")
		_assert_true(has_vault_recovery_toast, "carried loot must produce a recovery toast")
	_assert_true(int(game_state.get("materials")) == materials_before, "zero legacy materials must not change GameState")
	_assert_true(int(grunt.get("life_state")) == 3, "collected corpse must enter EMPTY_CORPSE")
	_assert_true(not bool(corpse_loot.call("has_loot")), "collected corpse payload must be empty")
	if marker != null:
		await marker.tree_exited
		await process_frame
		_assert_true(not is_instance_valid(marker), "marker must free after collection collapse")
	collector.queue_free()
	grunt.queue_free()


func _validate_lifecycle_contract(root: Node) -> void:
	var enemy := GRUNT_SCENE.instantiate()
	enemy.set("health", 3.0)
	enemy.set("max_health", 10.0)
	root.add_child(enemy)
	var zero_result: Dictionary = enemy.take_damage(0.0)
	_assert_true(bool(zero_result.get("target_was_alive")), "zero damage must be accepted for a living enemy")
	_assert_true(float(zero_result.get("applied_damage", -1.0)) == 0.0, "zero damage must not change health")
	_assert_true(float(enemy.get("health")) == 3.0, "pre-ready health overrides must survive lifecycle setup")
	var hit_result: Dictionary = enemy.take_damage(2.0)
	_assert_true(float(hit_result.get("target_health_before", -1.0)) == 3.0, "damage result must report the pre-hit health")
	_assert_true(float(hit_result.get("target_health_after", -1.0)) == 1.0, "damage result must report the post-hit health")
	_assert_true(float(enemy.get("health")) == 1.0, "lifecycle must own health arithmetic")
	var lethal_result: Dictionary = enemy.take_damage(10.0)
	_assert_true(bool(lethal_result.get("lethal")), "lethal damage must report a lethal result")
	_assert_true(bool(enemy.get("dead")), "lethal damage must enter dead state")
	var death_state: Dictionary = enemy.get_lifecycle_debug_state()
	_assert_true(int(death_state.get("life_state", -1)) == 1, "lethal damage must enter DYING exactly once")
	var pending_payload: Dictionary = death_state.get("pending_payload", {})
	enemy.die()
	_assert_true(
		enemy.get_lifecycle_debug_state().get("pending_payload", {}) == pending_payload,
		"repeated death must not reroll or replace the pending payload"
	)
	enemy.complete_death_presentation()
	_assert_true(int(enemy.get("life_state")) == 2, "configured loot must transition to LOOTABLE_CORPSE")
	var corpse := enemy.get_node_or_null("CorpseLoot")
	var invalid_collector := CharacterBody2D.new()
	root.add_child(invalid_collector)
	_assert_true(not bool(corpse.call("collect", invalid_collector)), "non-player collectors must be rejected")
	_assert_true(not enemy.advance_corpse_lifecycle(120.0), "lootable corpse must not use empty-corpse cleanup")
	invalid_collector.queue_free()
	enemy.queue_free()

	var no_amount_enemy := GRUNT_SCENE.instantiate()
	var no_amount_config := no_amount_enemy.lifecycle_config.duplicate(true) as EnemyLifecycleConfig
	no_amount_config.loot_table = [{"resource_id": "ruin_scrap", "min": 0, "max": 0}]
	no_amount_config.material_drop_min = 3
	no_amount_config.material_drop_max = 3
	no_amount_enemy.set("lifecycle_config", no_amount_config)
	root.add_child(no_amount_enemy)
	no_amount_enemy.die()
	var no_amount_payload: Dictionary = no_amount_enemy.get_lifecycle_debug_state().get("pending_payload", {})
	_assert_true((no_amount_payload.get("resource_ledger", {}) as Dictionary).is_empty(), "zero-amount table entry must produce no typed loot")
	_assert_true(int(no_amount_payload.get("legacy_materials", -1)) == 0, "configured table must suppress legacy fallback even when it yields no loot")
	no_amount_enemy.queue_free()

	var empty_enemy := GRUNT_SCENE.instantiate()
	var empty_config := empty_enemy.lifecycle_config.duplicate(true) as EnemyLifecycleConfig
	empty_config.loot_table.clear()
	empty_config.material_drop_fallback_enabled = false
	empty_enemy.set("lifecycle_config", empty_config)
	empty_enemy.set("health", 1.0)
	empty_enemy.set("max_health", 1.0)
	root.add_child(empty_enemy)
	var camera := Camera2D.new()
	root.add_child(camera)
	camera.make_current()
	await process_frame
	empty_enemy.die()
	empty_enemy.complete_death_presentation()
	_assert_true(int(empty_enemy.get("life_state")) == 3, "empty payload must enter EMPTY_CORPSE")
	_assert_true(not empty_enemy.advance_corpse_lifecycle(7.99), "empty corpse must survive its minimum lifetime")
	_assert_true(not empty_enemy.advance_corpse_lifecycle(0.02), "on-screen empty corpse must survive the offscreen check")
	_assert_true(empty_enemy.advance_corpse_lifecycle(37.02), "empty corpse must obey its hard lifetime")
	empty_enemy.queue_free()

	var offscreen_enemy := GRUNT_SCENE.instantiate()
	var offscreen_config := offscreen_enemy.lifecycle_config.duplicate(true) as EnemyLifecycleConfig
	offscreen_config.loot_table.clear()
	offscreen_config.material_drop_fallback_enabled = false
	offscreen_enemy.set("lifecycle_config", offscreen_config)
	offscreen_enemy.global_position = Vector2(100000.0, 100000.0)
	offscreen_enemy.set("health", 1.0)
	offscreen_enemy.set("max_health", 1.0)
	root.add_child(offscreen_enemy)
	offscreen_enemy.die()
	offscreen_enemy.complete_death_presentation()
	_assert_true(not offscreen_enemy.advance_corpse_lifecycle(7.99), "offscreen cleanup must still wait for the minimum lifetime")
	_assert_true(offscreen_enemy.advance_corpse_lifecycle(0.02), "offscreen empty corpse must clean up after its minimum lifetime")
	offscreen_enemy.queue_free()
	camera.queue_free()


func _on_vault_recovered(resources: Dictionary) -> void:
	_vault_recovery_seen = resources.duplicate(true)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
