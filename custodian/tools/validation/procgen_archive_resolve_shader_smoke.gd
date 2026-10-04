extends SceneTree

## Covers PROCGEN_ARCHIVE_RESOLVE_SHADER (AR2): one shared ShaderMaterial on the
## batched veil, deterministic one-shot custom-data identity, pause-safe
## presentation_time sync, reduced-effects/disabled parity, REQUESTED/READY
## cover staying fully opaque, and no per-cell node/material growth.

const PRESENTATION_SCRIPT := preload("res://game/world/procgen/streaming/procgen_reveal_presentation.gd")
const NO_OPERATOR := Vector2i(999999, 999999)
const CHUNK := 6

var _errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_material_and_identity()
	_test_clock_and_controls()
	_test_scheduling_parity()
	_test_live_disable_and_scene_order()
	if _errors.is_empty():
		print("[ProcgenArchiveResolveShaderSmoke] PASS")
		quit(0)
		return
	for error in _errors:
		push_error("[ProcgenArchiveResolveShaderSmoke] %s" % error)
	quit(1)


func _make_owner(reduced: bool = false) -> ProcGenRevealPresentation:
	var owner_node := PRESENTATION_SCRIPT.new() as ProcGenRevealPresentation
	owner_node.slot_capacity = 256
	owner_node.resolve_starts_per_frame = 4
	owner_node.resolve_duration_sec = 0.1
	owner_node.safety_halo_tiles = 2
	owner_node.reduced_effects = reduced
	root.add_child(owner_node)
	owner_node.configure(func(tile: Vector2i) -> Vector2: return Vector2(tile) * 32.0 + Vector2(16, 16))
	return owner_node


func _chunk_tiles(chunk: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for x in range(chunk.x * CHUNK, chunk.x * CHUNK + CHUNK):
		for y in range(chunk.y * CHUNK, chunk.y * CHUNK + CHUNK):
			tiles.append(Vector2i(x, y))
	return tiles


func _test_material_and_identity() -> void:
	var owner_node := _make_owner()
	var mat := owner_node.get_veil_material()
	_check(mat != null and owner_node.material == mat, "veil is not bound to exactly one shared ShaderMaterial")
	_check(mat != null and mat.shader != null and mat.shader.get_mode() == Shader.MODE_CANVAS_ITEM, "veil material is not the canvas_item Archive Resolve shader")
	var snap := owner_node.get_snapshot()
	_check(int(snap["shared_material_count"]) == 1 and bool(snap["shader_enabled"]) and bool(snap["custom_data_enabled"]), "material/custom-data telemetry is wrong")
	var chunk := Vector2i(3, 4)
	var tiles := _chunk_tiles(chunk)
	owner_node.note_tiles_requested(chunk, tiles, true)
	_check(owner_node.get_child_count() == 0 and owner_node.material == mat, "request grew nodes or replaced the shared material")
	# Identity is written once per slot assignment (headless MultiMesh buffers are
	# not readable, so the owner counts writes instead).
	_check(int(owner_node.get_snapshot()["identity_write_count"]) == tiles.size(), "identity was not written exactly once per assigned slot")
	_check(ProcGenRevealPresentation.cell_identity_hash(Vector2i(-7, 12)) == ProcGenRevealPresentation.cell_identity_hash(Vector2i(-7, 12)), "identity hash is not deterministic")
	var seen := {}
	for t in tiles:
		var h := ProcGenRevealPresentation.cell_identity_hash(t)
		_check(h >= 0.0 and h <= 1.0, "identity hash out of range")
		seen[h] = true
	_check(seen.size() > tiles.size() / 2, "identity hash has no per-cell variation")
	owner_node.note_tile_committed(tiles[0])
	for _i in range(10):
		owner_node.advance(0.05, NO_OPERATOR, CHUNK)
	_check(int(owner_node.get_snapshot()["identity_write_count"]) == tiles.size(), "advance rewrote slot identity (per-frame custom-data write)")
	for t in tiles.slice(1):
		_check(owner_node.get_tile_state(t) == ProcGenRevealPresentation.TileState.REQUESTED and owner_node.has_veil(t), "uncommitted cover was released")
		break
	# Settled/released slots are invisible and neutral; no per-cell material.
	_check(owner_node.get_veil_material() == mat, "shared material identity changed")
	owner_node.queue_free()


func _test_clock_and_controls() -> void:
	var owner_node := _make_owner()
	var mat := owner_node.get_veil_material()
	owner_node.advance(0.25, NO_OPERATOR, CHUNK)
	_check(is_equal_approx(float(mat.get_shader_parameter("presentation_time")), 0.25), "shader presentation_time does not track the owner clock")
	owner_node.advance(0.0, NO_OPERATOR, CHUNK)
	_check(is_equal_approx(float(mat.get_shader_parameter("presentation_time")), 0.25), "zero advance moved shader time (no pause-safe freeze)")
	owner_node.set_effect_enabled(false)
	owner_node.advance(1.0, NO_OPERATOR, CHUNK)
	_check(is_equal_approx(float(mat.get_shader_parameter("presentation_time")), 0.25), "disabled owner advanced shader time")
	owner_node.reduced_effects = true
	_check(float(mat.get_shader_parameter("phase_misregistration_intensity")) == 0.0, "reduced effects did not suppress phase misregistration")
	_check(float(mat.get_shader_parameter("registration_intensity")) < owner_node.registration_intensity, "reduced effects did not weaken registration")
	_check(float(mat.get_shader_parameter("unresolved_haze_intensity")) == owner_node.unresolved_haze_intensity, "reduced effects altered unresolved cover")
	owner_node.reduced_effects = false
	_check(float(mat.get_shader_parameter("phase_misregistration_intensity")) == owner_node.phase_misregistration_intensity, "leaving reduced effects did not restore controls")
	owner_node.queue_free()


func _trace(reduced: bool) -> Array:
	var owner_node := _make_owner(reduced)
	var chunk := Vector2i(2, 3)
	var tiles := _chunk_tiles(chunk)
	owner_node.note_tiles_requested(chunk, tiles, false)
	var out: Array = []
	for t in tiles:
		owner_node.note_tile_committed(t)
	for _i in range(40):
		owner_node.advance(0.02, NO_OPERATOR, CHUNK)
		out.append(owner_node.get_frontier_order().duplicate())
		var s := owner_node.get_snapshot()
		out.append([s["settled_count"], s["resolving_count"], s["active_instance_count"], s["requested_uncommitted_count"]])
	_check(int(owner_node.get_snapshot()["active_instance_count"]) == 0, "settled terrain kept veil slots")
	owner_node.queue_free()
	return out


func _test_scheduling_parity() -> void:
	var a := _trace(false)
	var b := _trace(false)
	var r := _trace(true)
	_check(a == b and not a.is_empty(), "scheduling trace is not deterministic")
	_check(a == r, "reduced effects changed scheduling/order/timing")


func _test_live_disable_and_scene_order() -> void:
	# R0-01: a direct property write must not strand veil slots.
	var owner_node := _make_owner()
	var chunk := Vector2i(1, 1)
	var tiles := _chunk_tiles(chunk)
	owner_node.note_tiles_requested(chunk, tiles, false)
	for t in tiles.slice(0, 8):
		owner_node.note_tile_committed(t)
	owner_node.effect_enabled = false
	_check(int(owner_node.get_snapshot()["active_instance_count"]) == 0, "direct effect_enabled=false stranded veil slots")
	owner_node.note_tile_committed(tiles[20])
	_check(int(owner_node.get_snapshot()["active_instance_count"]) == 0, "late commit after disable re-veiled")
	owner_node.effect_enabled = true
	owner_node.note_tiles_requested(chunk, tiles, true)
	_check(int(owner_node.get_snapshot()["active_instance_count"]) == tiles.size(), "re-enable did not restore veil coverage")
	owner_node.queue_free()
	# R0-02: ContractMap precedes z2 actor/item/projectile containers.
	var text := FileAccess.get_file_as_string("res://scenes/game.tscn")
	var cm := text.find('[node name="ContractMap" type="Node2D" parent="World"')
	_check(cm >= 0, "game.tscn has no World/ContractMap")
	for sibling in ["Enemies", "Projectiles", "Allies", "Items"]:
		var idx := text.find('[node name="%s" type="Node2D" parent="World"' % sibling)
		_check(idx > cm, "ContractMap does not precede World/%s" % sibling)
	_check(text.find('[node name="Operator" parent="World"') > cm, "ContractMap does not precede World/Operator")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
