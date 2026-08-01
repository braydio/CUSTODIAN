extends SceneTree

const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const MARKER_SCENE := preload("res://game/vfx/loot/loot_corpse_marker.tscn")
const VAULT_STORAGE_SCENE := preload("res://game/actors/storage/vault_storage.tscn")

var _failed := false
var _vault_recovery_seen: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	root.name = "LootableCorpseBeaconSmokeRoot"
	get_root().add_child(root)
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
	var marker := MARKER_SCENE.instantiate()
	root.add_child(marker)
	var reveal := marker.get_node("Reveal") as AnimatedSprite2D
	var beacon := marker.get_node("Beacon") as AnimatedSprite2D
	var ring := marker.get_node("GroundRing") as AnimatedSprite2D
	var collapse := marker.get_node("CollectCollapse") as AnimatedSprite2D
	_assert_true(reveal.sprite_frames.get_frame_count(&"reveal") == 8, "reveal must expose 8 frames")
	_assert_true(ring.sprite_frames.get_frame_count(&"ground_ring_loop") == 6, "ground ring must expose 6 frames")
	# Intake limitation is intentional and documented: current workspace art has
	# 9 beacon cells and 8 collapse cells rather than the requested 8/6 source.
	_assert_true(beacon.sprite_frames.get_frame_count(&"beacon_loop") == 9, "current review beacon must expose all 9 supplied cells")
	_assert_true(collapse.sprite_frames.get_frame_count(&"collect_collapse") == 8, "current review collapse must expose all 8 supplied cells")
	marker.queue_free()


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
		_assert_true((marker.get_node("Beacon") as AnimatedSprite2D).visible, "reveal must transition to beacon loop")
		_assert_true((marker.get_node("GroundRing") as AnimatedSprite2D).visible, "reveal must transition to ground-ring loop")

	var collector := CharacterBody2D.new()
	collector.name = "Operator"
	collector.add_to_group("player")
	root.add_child(collector)
	var first_collect := bool(corpse_loot.call("collect", collector))
	var second_collect := bool(corpse_loot.call("collect", collector))
	_assert_true(first_collect, "first proximity collection must succeed")
	_assert_true(not second_collect, "second collection must award nothing")
	_assert_true(int(ledger.call("get_amount", "ruin_scrap")) == rolled_ruin_scrap, "typed loot must reach ResourceLedger")
	_assert_true(int(_vault_recovery_seen.get(&"power_components", 0)) == 1, "carried loot must reach VaultManager")
	_assert_true(int(game_state.get("materials")) == materials_before, "zero legacy materials must not change GameState")
	_assert_true(int(grunt.get("life_state")) == 3, "collected corpse must enter EMPTY_CORPSE")
	_assert_true(not bool(corpse_loot.call("has_loot")), "collected corpse payload must be empty")
	collector.queue_free()
	grunt.queue_free()


func _on_vault_recovered(resources: Dictionary) -> void:
	_vault_recovery_seen = resources.duplicate(true)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
