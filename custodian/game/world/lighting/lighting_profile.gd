extends Resource
class_name LightingProfile

@export var ambient_color: Color = Color(0.18, 0.18, 0.22, 1.0)
@export var directional_color: Color = Color(0.72, 0.78, 0.92, 1.0)
@export_range(0.0, 4.0, 0.01) var directional_energy: float = 0.55
@export_range(-360.0, 360.0, 0.1) var directional_rotation_degrees: float = -35.0
@export_range(0.0, 1.0, 0.01) var cosmic_underlay_alpha: float = 0.0
@export_range(0.0, 1.0, 0.01) var fog_alpha: float = 0.0
@export_range(0.0, 10.0, 0.05) var transition_seconds: float = 1.2
