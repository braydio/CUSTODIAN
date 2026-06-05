extends SceneTree

const RESOURCE_LEDGER_SCRIPT := preload("res://autoload/resource_ledger.gd")
const GRUNT_SCENE := preload("res://game/actors/enemies/enemy_grunt.tscn")
const MARINE_SCENE := preload("res://game/actors/enemies/enemy_marine.tscn")
const GOTHIC_COMPOUND_MAP_SCRIPT := preload("res://game/world/gothic_compound/gothic_compound_map.gd")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var root := Node2D.new()
	root.name = "AuthoredVaultGruntLootMarineSmokeRoot"
	get_root().add_child(root)
	await process_frame

	_validate_grunt_loot(root)
	_validate_marine_idle(root)
	_validate_authored_vault_room(root)

	if _failed:
		push_error("authored_vault_grunt_loot_marine_smoke failed")
		quit(1)
		return
	print("authored_vault_grunt_loot_marine_smoke passed")
	quit()


func _validate_grunt_loot(root: Node) -> void:
	var ledger := get_root().get_node_or_null("ResourceLedger")
	var owns_ledger := false
	if ledger == null:
		ledger = RESOURCE_LEDGER_SCRIPT.new()
		ledger.name = "ResourceLedger"
		get_root().add_child(ledger)
		ledger.call("_ready")
		owns_ledger = true
	if ledger.has_method("clear"):
		ledger.call("clear")

	var grunt := GRUNT_SCENE.instantiate()
	root.add_child(grunt)
	var expected_ids := [
		"ruin_scrap",
		"spent_charge_cell",
		"frayed_signal_filament",
		"cracked_field_tag",
		"power_components",
		"memory_glass_fragment",
		"white_thread_knot",
	]
	var table_ids := {}
	for entry in grunt.get("loot_table"):
		table_ids[str(entry.get("resource_id", ""))] = true
	var defs: Dictionary = ledger.call("get_resource_defs")
	for resource_id in expected_ids:
		_assert_true(table_ids.has(resource_id), "grunt loot table should include %s" % resource_id)
		_assert_true(defs.has(resource_id), "resource defs should include %s" % resource_id)
	var awarded := bool(grunt.call("_award_loot_table"))
	_assert_true(awarded, "grunt loot table should award or intentionally roll no typed loot")
	_assert_true(int(ledger.call("get_amount", "ruin_scrap")) >= 1, "grunt loot should always award at least one ruin_scrap")
	if owns_ledger:
		ledger.queue_free()
	grunt.queue_free()


func _validate_marine_idle(root: Node) -> void:
	var marine := MARINE_SCENE.instantiate()
	root.add_child(marine)
	marine.call("_ensure_directional_animations")
	var sprite := marine.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_assert_true(sprite != null, "marine should have AnimatedSprite2D")
	_assert_true(sprite.sprite_frames != null, "marine should build SpriteFrames")
	for suffix in ["n", "ne", "e", "se", "s", "sw", "w", "nw"]:
		_assert_true(sprite.sprite_frames.has_animation("marine_idle_%s" % suffix), "marine idle should include %s" % suffix)
	_assert_true(sprite.sprite_frames.has_animation("marine_dash_attack_e"), "marine should include east dash attack animation")
	_assert_true(sprite.sprite_frames.get_frame_count("marine_dash_attack_e") == 8, "marine dash attack should have 8 frames")
	marine.call("_ensure_custom_enemy_fx_animations")
	var fx_sprite := marine.get_node_or_null("CustomEnemyFxSprite") as AnimatedSprite2D
	_assert_true(fx_sprite != null and fx_sprite.sprite_frames != null, "marine should build dash FX SpriteFrames")
	_assert_true(fx_sprite.sprite_frames.has_animation("marine_dash_attack_fx_e"), "marine should include east dash attack FX animation")
	marine.queue_free()


func _validate_authored_vault_room(root: Node) -> void:
	var map := GOTHIC_COMPOUND_MAP_SCRIPT.new()
	root.add_child(map)
	var room := map.get_node_or_null("AuthoredVaultRoom")
	_assert_true(room != null, "gothic compound should place AuthoredVaultRoom")
	if room == null:
		map.queue_free()
		return
	var storage_count := 0
	for node in get_nodes_in_group("vault_storage"):
		if room.is_ancestor_of(node):
			storage_count += 1
	_assert_true(storage_count >= 3, "authored vault room should contain at least three storage nodes")
	_assert_true(room.get_node_or_null("VaultEnemyExit") != null, "authored vault room should expose VaultEnemyExit marker")
	map.queue_free()


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_failed = true
	push_error(message)
