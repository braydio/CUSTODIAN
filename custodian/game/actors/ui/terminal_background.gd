extends TextureRect

var _bg_generator: Control = null
var _viewport: SubViewport = null
var _initialized := false

func _ready() -> void:
	z_index = 5  # Above gameplay UI, below the terminal panel.
	mouse_filter = Control.MOUSE_FILTER_STOP

func initialize() -> void:
	if _initialized:
		return
	_initialized = true
	_setup_background_generator()

func _setup_background_generator() -> void:
	# The old external PixelSpace dependency is no longer reliable in this project.
	# Use the built-in fallback background so terminal open cannot fail on missing
	# external scenes or broken script references outside the active runtime.
	_create_fallback_background()

func _create_fallback_background() -> void:
	var gradient = Gradient.new()
	gradient.colors = [Color(0.03, 0.055, 0.07, 0.94), Color(0.008, 0.014, 0.02, 0.96)]
	
	var gradient_tex = GradientTexture2D.new()
	gradient_tex.gradient = gradient
	gradient_tex.fill = GradientTexture2D.FILL_RADIAL
	gradient_tex.fill_from = Vector2(0.5, 0.5)
	gradient_tex.fill_to = Vector2(1.0, 1.0)
	
	texture = gradient_tex

func generate_new(seed_val: float = -1.0) -> void:
	if _bg_generator == null:
		return
	
	if seed_val > 0:
		_bg_generator.starstuff.material.set_shader_param("seed", seed_val)
		_bg_generator.nebulae.material.set_shader_param("seed", seed_val)
	else:
		_bg_generator.generate_new()
	
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	
	texture = _viewport.get_texture()

func set_colorscheme(colorscheme: Texture2D) -> void:
	if _bg_generator == null:
		return
	_bg_generator._set_new_colors(colorscheme, Color(0.02, 0.02, 0.05))
	generate_new()
