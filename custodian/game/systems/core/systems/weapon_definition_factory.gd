class_name WeaponDefinitionFactory
extends Node

var weapon_data_loader: WeaponDataLoader

func _ready() -> void:
	weapon_data_loader = WeaponDataLoader.new()
	add_child(weapon_data_loader)

func create_weapon_definition(weapon_id: String) -> OperatorWeaponDefinition:
	var def = OperatorWeaponDefinition.new()
	var data = weapon_data_loader.get_weapon_data(weapon_id)
	def.weapon_data_path = WeaponDataLoader.WEAPON_DATA_PATH + weapon_id + ".json"
	
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
	def.effective_range_px = float(stats.get("effective_range_px", def.range_px * 0.6))
	def.max_range_px = float(stats.get("max_range_px", def.range_px))
	def.damage_falloff_start_px = float(stats.get("damage_falloff_start_px", def.effective_range_px))
	def.damage_falloff_end_px = float(stats.get("damage_falloff_end_px", def.max_range_px))
	def.min_falloff_damage_mult = float(stats.get("min_falloff_damage_mult", 0.5))
	def.accuracy = float(stats.get("accuracy", 0.86))
	def.spread_deg = float(stats.get("spread_deg", 2.0))
	def.recoil = float(stats.get("recoil", 0.35))
	def.projectile_speed_px = float(stats.get("projectile_speed_px", 950.0))
	def.penetration = int(stats.get("penetration", 1))
	
	var ammo = data.get("ammo", {})
	def.ammo_type = String(ammo.get("ammo_type", "kinetic_light"))
	if def.ammo_type == "kinetic":
		def.ammo_type = "kinetic_light"
	def.magazine_size = int(ammo.get("magazine_size", ammo.get("capacity", def.magazine_size)))
	def.max_reserve_ammo = int(ammo.get("max_reserve", 72))
	def.reserve_ammo = clampi(int(ammo.get("starting_reserve", ammo.get("reserve", 48))), 0, def.max_reserve_ammo)
	def.ammo_per_shot = maxi(1, int(ammo.get("ammo_per_shot", 1)))
	def.pickup_weight = float(ammo.get("pickup_weight", 1.0))
	def.reload_style = String(ammo.get("reload_style", "magazine"))

	var handling = data.get("handling", {})
	def.movement_speed_penalty = float(handling.get("movement_speed_penalty", 0.0))
	def.movement_accuracy_penalty = float(handling.get("movement_accuracy_penalty", 0.0))

	var heat = data.get("heat", {})
	def.heat_enabled = bool(heat.get("enabled", true))
	def.heat_max = float(heat.get("max", 100.0))
	def.heat_per_shot = float(heat.get("per_shot", 12.0))
	def.heat_decay_per_sec = float(heat.get("decay_per_sec", 28.0))
	def.heat_decay_delay_sec = float(heat.get("decay_delay_sec", 0.25))
	def.overheat_threshold = float(heat.get("overheat_threshold", def.heat_max))
	def.overheat_lockout_sec = float(heat.get("overheat_lockout_sec", 1.35))
	def.heat_spread_mult_at_max = float(heat.get("spread_mult_at_max", 1.7))
	def.heat_recoil_mult_at_max = float(heat.get("recoil_mult_at_max", 1.4))

	var noise = data.get("noise", {})
	def.shot_noise_radius_px = float(noise.get("shot_radius_px", 360.0))
	def.shot_loudness = float(noise.get("shot_loudness", 1.0))
	def.suppressed = bool(noise.get("suppressed", false))
	def.suppressed_radius_mult = float(noise.get("suppressed_radius_mult", 0.35))
	def.alert_threat_value = float(noise.get("alert_threat_value", 1.0))

	var animation = data.get("animation", {})
	def.animation_fire_frame = int(animation.get("fire_frame", 0))
	def.recoil_animation = StringName(String(animation.get("recoil_animation", "recoil_standard")))
	
	def.current_magazine = def.magazine_size
	
	var weapon_class = data.get("weapon_class", "carbine")
	match weapon_class:
		"pistol":
			def.weapon_type = &"ranged_1h"
		"shotgun", "smg", "carbine", "rifle", "minigun", "sniper":
			def.weapon_type = &"ranged_2h"
	
	return def
