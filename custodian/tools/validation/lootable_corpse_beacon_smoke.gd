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
	root.add_child(LOOT_TOAST_QUEUE_SCENE.instantiate())
	await process_frame

	_validate_marker_contract(root)
	await _validate_corpse_delivery(root)

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
	grunt.set("material_drop_fallback_enabled", false)
	var carrier := grunt.get_node("EnemyLootCarrier")
	carrier.call("set_payload", {&"power_components": 1})
	var payload := grunt.call("_build_corpse_payload_once") as Dictionary
	var rolled_ruin_scrap := int((payload["resource_ledger"] as Dictionary).get(&"ruin_scrap", 0))
	_assert_true(rolled_ruin_scrap >= 1, "death roll must determine guaranteed typed loot once")
	_assert_true(int((payload["vault_recovery"] as Dictionary).get(&"power_components", 0)) == 1, "carried loot must transfer into vault channel")
	_assert_true(not bool(carrier.call("is_carrying_loot")), "take_payload must clear the carrier")
	_assert_true(int(ledger.call("get_amount", "ruin_scrap")) == 0, "death determination must not award typed loot")

	grunt.set("life_state", 1)
	grunt.set("dead", true)
	grunt.set("_pending_corpse_payload", payload)
	grunt.call("_disable_live_enemy_runtime")
	grunt.call("_finalize_corpse_state")
	var corpse_loot := grunt.get_node_or_null("CorpseLoot")
	_assert_true(corpse_loot != null and bool(corpse_loot.call("has_loot")), "lootable corpse must survive finalization")
	_assert_true(int(grunt.get("life_state")) == 2, "corpse must enter LOOTABLE_CORPSE")
	grunt.call("_update_empty_corpse_cleanup", 120.0)
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
		_assert_true(toast_entries.size() == 2, "enemy corpse collection must show typed and recovered-resource toasts")
		var has_loot_table_toast := false
		for entry in toast_entries:
			if entry.get("item_id") == &"ruin_scrap":
				has_loot_table_toast = true
		_assert_true(has_loot_table_toast, "enemy loot table resource must produce a pickup toast")
	_assert_true(int(game_state.get("materials")) == materials_before, "zero legacy materials must not change GameState")
	_assert_true(int(grunt.get("life_state")) == 3, "collected corpse must enter EMPTY_CORPSE")
	_assert_true(not bool(corpse_loot.call("has_loot")), "collected corpse payload must be empty")
	if marker != null:
		await marker.tree_exited
		await process_frame
		_assert_true(not is_instance_valid(marker), "marker must free after collection collapse")
	collector.queue_free()
	grunt.queue_free()


func _on_vault_recovered(resources: Dictionary) -> void:
	_vault_recovery_seen = resources.duplicate(true)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
