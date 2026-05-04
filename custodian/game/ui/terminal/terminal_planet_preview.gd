extends RefCounted
class_name TerminalPlanetPreview

const ZOOM_MIN := 2.7
const ZOOM_MAX := 6.2
const ZOOM_STEP := 0.3

var viewport: SubViewport = null
var root: Node3D = null
var globe: MeshInstance3D = null
var camera: Camera3D = null
var environment: WorldEnvironment = null
var drag_active := false
var drag_last_pos := Vector2.ZERO
var rotation := Vector2.ZERO
var spin_velocity := Vector2.ZERO
var zoom_distance := 3.8


func init(ui: Node, target: TextureRect) -> void:
	if viewport != null and is_instance_valid(viewport):
		if target:
			target.texture = viewport.get_texture()
		return

	viewport = SubViewport.new()
	viewport.name = "TerminalPlanetPreviewViewport"
	viewport.size = Vector2i(768, 768)
	viewport.transparent_bg = false
	viewport.disable_3d = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	ui.add_child(viewport)

	root = Node3D.new()
	root.name = "Root"
	viewport.add_child(root)

	globe = MeshInstance3D.new()
	globe.name = "TerminalGlobe"
	var sphere := SphereMesh.new()
	sphere.radial_segments = 96
	sphere.rings = 48
	sphere.radius = 1.0
	sphere.height = 2.0
	globe.mesh = sphere
	root.add_child(globe)

	var light := DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(-24.0), deg_to_rad(28.0), 0.0)
	light.light_energy = 2.4
	viewport.add_child(light)

	environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.02, 0.03, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.7, 1.0)
	env.ambient_light_energy = 0.45
	environment.environment = env
	viewport.add_child(environment)

	camera = Camera3D.new()
	camera.position = Vector3(0.0, 0.06, zoom_distance)
	camera.fov = 34.0
	camera.near = 0.05
	camera.far = 20.0
	camera.current = true
	viewport.add_child(camera)

	if target:
		target.texture = viewport.get_texture()


func render(ui: Node, target: TextureRect, contract: Dictionary) -> void:
	if globe == null or not is_instance_valid(globe):
		init(ui, target)
	if target and viewport:
		target.texture = viewport.get_texture()
	var planet: Dictionary = contract.get("planet", {})
	if not (planet is Dictionary):
		if target and ui.has_method("_build_placeholder_preview"):
			target.texture = ui.call("_build_placeholder_preview", "NO PLANET DATA")
		return
	var planet_key := str(planet.get("key", "terran_dry"))
	var planet_seed := int(planet.get("planet_seed", -1))
	if ui.has_method("_build_terminal_planet_globe_material"):
		globe.material_override = ui.call("_build_terminal_planet_globe_material", planet_key, planet_seed)
	rotation = Vector2(0.14, -0.36)
	spin_velocity = Vector2.ZERO
	zoom_distance = 3.8
	apply_zoom()
	apply_rotation()


func update_spin(delta: float) -> void:
	if globe == null or not is_instance_valid(globe):
		return
	if drag_active:
		return
	if spin_velocity.length_squared() > 0.0001:
		rotation.x = clamp(rotation.x + spin_velocity.x * delta, -0.9, 0.9)
		rotation.y += spin_velocity.y * delta
		spin_velocity = spin_velocity.move_toward(Vector2.ZERO, delta * 0.6)
	else:
		rotation.y += delta * 0.09
	apply_rotation()


func handle_gui_input(event: InputEvent, target: TextureRect) -> Dictionary:
	var handled := false
	var scroll_delta := 0
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_WHEEL_UP and button_event.pressed:
			zoom_distance = max(ZOOM_MIN, zoom_distance - ZOOM_STEP)
			apply_zoom()
			scroll_delta = -96
			handled = true
		elif button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and button_event.pressed:
			zoom_distance = min(ZOOM_MAX, zoom_distance + ZOOM_STEP)
			apply_zoom()
			scroll_delta = 96
			handled = true
		elif button_event.button_index == MOUSE_BUTTON_LEFT:
			drag_active = button_event.pressed
			drag_last_pos = button_event.position
			if not drag_active:
				spin_velocity.x = clamp(spin_velocity.x, -2.2, 2.2)
				spin_velocity.y = clamp(spin_velocity.y, -4.2, 4.2)
			handled = true
	elif event is InputEventMouseMotion and drag_active:
		var motion_event := event as InputEventMouseMotion
		var delta_pos := motion_event.position - drag_last_pos
		drag_last_pos = motion_event.position
		rotation.x = clamp(rotation.x - delta_pos.y * 0.005, -0.9, 0.9)
		rotation.y += delta_pos.x * 0.012
		spin_velocity.x = -delta_pos.y * 0.03
		spin_velocity.y = delta_pos.x * 0.07
		apply_rotation()
		handled = true
	if handled and target:
		target.accept_event()
	return {"handled": handled, "scroll_delta": scroll_delta}


func contains_screen_point(target: TextureRect, point: Vector2) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	return target.get_global_rect().has_point(point)


func apply_rotation() -> void:
	if globe:
		globe.rotation = Vector3(rotation.x, rotation.y, 0.0)


func apply_zoom() -> void:
	if camera:
		camera.position.z = zoom_distance
