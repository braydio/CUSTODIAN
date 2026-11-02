extends SceneTree

const TrackerScript := preload(
	"res://game/systems/combat/engagement_tracker.gd"
)
const ItemCatalog := preload(
	"res://game/ui/inventory/inventory_item_catalog.gd"
)
const ICON_PATH := (
	"res://content/ui/inventory/runtime/icons/relics/"
	+ "vanguard_seal__icon__inventory__default__omni__1f__48.png"
)
const FX_PATH := (
	"res://content/sprites/effects/combat/status/"
	+ "combat_fx__initiative_claimed__6f__64.png"
)

var _failed := false


class MockOperator:
	extends Node2D


class MockHostile:
	extends Node2D
	var health := 100.0
	var dead := false
	var target: Node2D = null


func _initialize() -> void:
	var inventory := root.get_node_or_null("InventoryManager")
	_assert(inventory != null, "InventoryManager autoload missing")
	if inventory == null:
		_finish()
		return
	inventory.call("clear")

	var operator := MockOperator.new()
	root.add_child(operator)
	var hostile := MockHostile.new()
	hostile.add_to_group("enemy")
	root.add_child(hostile)
	var tracker := TrackerScript.new()
	root.add_child(tracker)
	tracker.call("configure", operator, inventory)
	await process_frame

	var opening: Dictionary = tracker.call(
		"prepare_direct_operator_hit",
		hostile,
		&"melee"
	)
	_assert(
		is_equal_approx(
			float(opening.get("direct_damage_multiplier", 0.0)),
			1.0
		),
		"universal initiative must not add health damage"
	)
	_assert(
		is_equal_approx(
			float(opening.get("stagger_damage_multiplier", 0.0)),
			1.20
		),
		"first direct hit should add 20% stagger/breach damage"
	)
	_assert(
		bool(opening.get("initiative_candidate", false))
		and bool(tracker.call(
			"confirm_direct_operator_hit",
			10.0,
			opening
		)),
		"nonzero applied damage should confirm initiative"
	)
	var repeat: Dictionary = tracker.call(
		"prepare_direct_operator_hit",
		hostile,
		&"ranged"
	)
	_assert(
		is_equal_approx(
			float(repeat.get("stagger_damage_multiplier", 0.0)),
			1.0
		),
		"same engagement must not retrigger initiative"
	)

	tracker.call("advance_fixed", 4.0)
	_assert(
		not bool(tracker.call("get_status").get("engagement_active", true)),
		"four quiet seconds should end the engagement"
	)
	var zero_damage_hit: Dictionary = tracker.call(
		"prepare_direct_operator_hit",
		hostile,
		&"ranged"
	)
	_assert(
		not bool(tracker.call(
			"confirm_direct_operator_hit",
			0.0,
			zero_damage_hit
		))
		and not bool(
			tracker.call("get_status").get("initiative_claimed", true)
		),
		"zero-damage or deflected contact must not claim initiative"
	)
	tracker.call("advance_fixed", 4.0)
	hostile.target = operator
	tracker.call("advance_fixed", 0.1)
	_assert(
		bool(tracker.call("get_status").get("engagement_active", false)),
		"hostile targeting should start an engagement before damage"
	)
	hostile.target = null
	tracker.call("advance_fixed", 3.9)
	_assert(
		bool(tracker.call("get_status").get("engagement_active", false)),
		"engagement should remain active until four full quiet seconds"
	)
	tracker.call("advance_fixed", 0.1)
	_assert(
		not bool(tracker.call("get_status").get("engagement_active", true)),
		"targeting engagement should end at the quiet boundary"
	)
	tracker.call("notify_direct_hostile_damage", 5.0)
	var lost_opening: Dictionary = tracker.call(
		"prepare_direct_operator_hit",
		hostile,
		&"melee"
	)
	_assert(
		not bool(lost_opening.get("initiative_claimed", false)),
		"receiving direct hostile damage first should lose initiative"
	)
	tracker.call("advance_fixed", 4.0)

	inventory.call("add_item", &"vanguard_seal", 1)
	_assert(
		bool(inventory.call("equip_item", &"vanguard_seal", &"relic")),
		"Vanguard Seal should equip into the constrained relic slot"
	)
	var talisman_opening: Dictionary = tracker.call(
		"prepare_direct_operator_hit",
		hostile,
		&"unarmed"
	)
	tracker.call(
		"confirm_direct_operator_hit",
		10.0,
		talisman_opening
	)
	_assert(
		bool(tracker.call("get_status").get("vanguard_active", false)),
		"claiming initiative with Vanguard Seal equipped should activate it"
	)
	_assert(
		is_equal_approx(
			float(talisman_opening.get("direct_damage_multiplier", 0.0)),
			1.0
		),
		"the claiming hit should grant, not retroactively consume, Vanguard"
	)
	var pressed_hit: Dictionary = tracker.call(
		"prepare_direct_operator_hit",
		hostile,
		&"ranged"
	)
	_assert(
		is_equal_approx(
			float(pressed_hit.get("direct_damage_multiplier", 0.0)),
			1.08
		),
		"active Vanguard should add 8% direct damage"
	)
	_assert(
		is_equal_approx(
			float(pressed_hit.get("stagger_damage_multiplier", 0.0)),
			1.15
		),
		"active Vanguard should add 15% stagger damage"
	)
	tracker.call("notify_direct_hostile_damage", 1.0)
	_assert(
		not bool(tracker.call("get_status").get("vanguard_active", true)),
		"direct hostile damage should immediately break Vanguard"
	)
	var after_break: Dictionary = tracker.call(
		"prepare_direct_operator_hit",
		hostile,
		&"melee"
	)
	_assert(
		is_equal_approx(
			float(after_break.get("direct_damage_multiplier", 0.0)),
			1.0
		),
		"Vanguard must not retrigger in the same engagement"
	)

	var saved: Dictionary = inventory.call("to_save_dict")
	_assert(
		str(
			(saved.get("equipment_slots", {}) as Dictionary).get(
				"relic",
				""
			)
		) == "vanguard_seal",
		"save contract should include equipped relic"
	)
	inventory.call("clear")
	inventory.call("from_save_dict", saved)
	_assert(
		str(inventory.call("get_equipped", &"relic")) == "vanguard_seal",
		"load contract should restore equipped relic"
	)
	inventory.call("from_save_dict", {"legacy_item": 2})
	_assert(
		int(inventory.call("get_count", &"legacy_item")) == 2,
		"legacy flat carried-item saves should remain readable"
	)

	var definition := ItemCatalog.get_definition(&"vanguard_seal")
	_assert(
		str(definition.get("display_name", "")) == "Vanguard Seal"
		and definition.has("mechanical_effects"),
		"combat relic catalog definition missing"
	)
	_validate_image(ICON_PATH, Vector2i(48, 48), "inventory icon")
	_validate_image(FX_PATH, Vector2i(384, 64), "activation sheet")
	var fx_scene := load("res://game/vfx/initiative_claimed_vfx.tscn")
	_assert(fx_scene is PackedScene, "initiative activation VFX scene missing")
	if fx_scene is PackedScene:
		var fx := (fx_scene as PackedScene).instantiate() as AnimatedSprite2D
		_assert(
			fx != null
			and fx.sprite_frames.get_frame_count(&"claim") == 6,
			"initiative activation VFX must expose six frames"
		)
		if fx != null:
			fx.free()

	inventory.call("clear")
	tracker.free()
	hostile.free()
	operator.free()
	_finish()


func _validate_image(
	path: String,
	expected_size: Vector2i,
	label: String
) -> void:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	_assert(error == OK, "%s failed to load" % label)
	if error == OK:
		_assert(
			Vector2i(image.get_width(), image.get_height()) == expected_size,
			"%s dimensions changed" % label
		)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("[InitiativeVanguardSealSmoke] %s" % message)


func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("[InitiativeVanguardSealSmoke] PASS")
	quit(0)
