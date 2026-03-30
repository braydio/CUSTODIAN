class_name WeaponDefinitionFactory
extends Node

var weapon_data_loader: WeaponDataLoader

func _ready() -> void:
	weapon_data_loader = WeaponDataLoader.new()
	add_child(weapon_data_loader)

func create_weapon_definition(weapon_id: String) -> OperatorWeaponDefinition:
	var def = OperatorWeaponDefinition.new()
	var data = weapon_data_loader.get_weapon_data(weapon_id)
	
	if data.is_empty():
		push_warning("[WeaponDefinitionFactory] No data for weapon: " + weapon_id)
		return def
	
	def.weapon_id = StringName(weapon_id)
	
	var stats = data.get("stats", {})
	def.damage = float(stats.get("damage", 12.0))
	def.fire_rate_rps = float(stats.get("fire_rate_rps", 7.5))
	def.magazine_size = int(stats.get("magazine_size", 28))
	def.reload_time_sec = float(stats.get("reload_time_sec", 1.7))
	def.range_px = float(stats.get("range_px", 300.0))
	def.accuracy = float(stats.get("accuracy", 0.86))
	def.spread_deg = float(stats.get("spread_deg", 2.0))
	def.recoil = float(stats.get("recoil", 0.35))
	def.projectile_speed_px = float(stats.get("projectile_speed_px", 950.0))
	def.penetration = int(stats.get("penetration", 1))
	
	var ammo = data.get("ammo", {})
	def.ammo_type = String(ammo.get("ammo_type", "kinetic"))
	def.reserve_ammo = int(ammo.get("reserve", 112))
	def.reload_style = String(ammo.get("reload_style", "magazine"))
	
	def.current_magazine = def.magazine_size
	
	var weapon_class = data.get("weapon_class", "carbine")
	match weapon_class:
		"pistol":
			def.weapon_type = &"ranged_1h"
		"shotgun", "smg", "carbine", "rifle", "minigun", "sniper":
			def.weapon_type = &"ranged_2h"
	
	return def
