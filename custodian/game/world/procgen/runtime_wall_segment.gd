extends StaticBody2D
class_name ProcGenRuntimeWallSegment

var procgen_tilemap: ProcGenTilemap = null
var tile_position: Vector2i = Vector2i.ZERO


func setup(owner_tilemap: ProcGenTilemap, wall_tile: Vector2i) -> void:
	procgen_tilemap = owner_tilemap
	tile_position = wall_tile
	add_to_group("destructible_wall")


func receive_projectile_hit(amount: float, attacker_team: String) -> Dictionary:
	if procgen_tilemap == null:
		return {
			"blocked": false,
			"destroyed": false,
		}
	return procgen_tilemap.damage_wall_tile(tile_position, amount, attacker_team)


func take_damage(amount: float) -> void:
	if procgen_tilemap != null:
		procgen_tilemap.damage_wall_tile(tile_position, amount, "")
