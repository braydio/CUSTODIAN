extends SceneTree

const SITE_SCENE := preload("res://game/world/events/ash_bell/forlorn_ritualant_site.tscn")
const EXPECTED_ANIMATIONS := [
	&"kneel_idle",
	&"rise",
	&"hostile_idle",
	&"pin_strike",
	&"thread_pull",
	&"ninth_answer",
	&"orra_late",
	&"dissolve",
	&"death_violent",
]
const EXPECTED_NPC_POSITION := Vector2(0.0, -154.0)
const EXPECTED_SPRITE_Z := 2

var errors: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var first := SITE_SCENE.instantiate() as ForlornRitualantSite
	var second := SITE_SCENE.instantiate() as ForlornRitualantSite
	root.add_child(first)
	root.add_child(second)
	await process_frame
	_check_actor_binding(first, "first")
	_check_actor_binding(second, "second")
	_check_instance_isolation(first, second)
	_check_atlas_frames(first)
	_check_shader_contract()
	if errors.is_empty():
		print("[ForlornRitualantPresentationSmoke] PASS")
		quit(0)
		return
	for error in errors:
		push_error("[ForlornRitualantPresentationSmoke] %s" % error)
	quit(1)


func _check_actor_binding(site: ForlornRitualantSite, label: String) -> void:
	var npc := site.get_node_or_null("NPCs/ForlornRitualant") as ForlornRitualantNPC
	_check(npc != null, "%s production Ritualant missing" % label)
	if npc == null:
		return
	var sprite := npc.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_check(sprite != null, "%s production AnimatedSprite2D missing" % label)
	if sprite == null:
		return
	_check(sprite.material is ShaderMaterial, "%s actor sprite lacks ShaderMaterial" % label)
	_check(sprite.sprite_frames != null, "%s canonical SpriteFrames missing" % label)
	_check(npc.position == EXPECTED_NPC_POSITION, "%s NPC position changed" % label)
	_check(sprite.position == Vector2.ZERO, "%s sprite origin changed" % label)
	_check(sprite.scale == Vector2.ONE, "%s sprite scale changed" % label)
	_check(sprite.z_index == EXPECTED_SPRITE_Z, "%s sprite z-order changed" % label)
	_check(sprite.visible, "%s production sprite is hidden" % label)
	var legacy := npc.get_node_or_null("Visual") as CanvasItem
	_check(legacy != null and not legacy.visible, "%s legacy placeholder is visible" % label)
	_check(sprite.animation == &"kneel_idle", "%s did not retain kneeling animation" % label)


func _check_instance_isolation(first: ForlornRitualantSite, second: ForlornRitualantSite) -> void:
	var first_material := first.get_node("NPCs/ForlornRitualant/AnimatedSprite2D").material as ShaderMaterial
	var second_material := second.get_node("NPCs/ForlornRitualant/AnimatedSprite2D").material as ShaderMaterial
	_check(first_material != null and second_material != null, "actor materials missing")
	if first_material == null or second_material == null:
		return
	_check(not is_same(first_material, second_material), "actor material is shared across scene instances")
	_check(first_material.resource_local_to_scene, "actor material is not local to its scene")
	_check(first_material.get_shader_parameter("value_lift") == 0.05, "value lift default drifted")
	_check(first_material.get_shader_parameter("rim_strength") == 0.22, "rim strength default drifted")
	_check(first_material.get_shader_parameter("rim_tint") == Color(0.72, 0.79, 0.83, 1.0), "rim tint default drifted")


func _check_atlas_frames(site: ForlornRitualantSite) -> void:
	var sprite := site.get_node("NPCs/ForlornRitualant/AnimatedSprite2D") as AnimatedSprite2D
	var frames := sprite.sprite_frames
	if frames == null:
		return
	var animation_names := frames.get_animation_names()
	for animation in EXPECTED_ANIMATIONS:
		_check(animation_names.has(animation), "canonical animation missing: %s" % animation)
	for animation in animation_names:
		for frame_index in frames.get_frame_count(animation):
			var texture := frames.get_frame_texture(animation, frame_index)
			_check(texture != null, "%s frame %d texture missing" % [animation, frame_index])
			if texture is AtlasTexture:
				var atlas_texture := texture as AtlasTexture
				var region := atlas_texture.region
				var atlas_size := atlas_texture.atlas.get_size()
				_check(region.size.x > 0.0 and region.size.y > 0.0, "%s frame %d has empty atlas region" % [animation, frame_index])
				_check(region.position.x >= 0.0 and region.position.y >= 0.0, "%s frame %d starts outside atlas" % [animation, frame_index])
				_check(region.end.x <= atlas_size.x and region.end.y <= atlas_size.y, "%s frame %d exceeds atlas bounds" % [animation, frame_index])
				_check(region.size == Vector2(128.0, 128.0), "%s frame %d dimensions changed" % [animation, frame_index])
			else:
				_check(texture.get_size() == Vector2(128.0, 128.0), "%s frame %d dimensions changed" % [animation, frame_index])
	_check(not sprite.sprite_frames.resource_path.is_empty(), "SpriteFrames resource identity missing")
	_check(sprite.sprite_frames.resource_path.ends_with("forlorn_ritualant_animations.tres"), "non-canonical SpriteFrames assigned")


func _check_shader_contract() -> void:
	var shader := load("res://game/world/events/ash_bell/shaders/ritualant_silhouette_readability.gdshader") as Shader
	_check(shader != null, "actor readability shader failed to load")
	if shader == null:
		return
	var source := shader.code
	_check(source.contains("fwidth(texel.a)"), "rim no longer derives from current-fragment alpha")
	_check(source.contains("COLOR = vec4(lifted_rgb + rim_rgb, incoming.a);"), "source sprite/modulate alpha is not passed through unchanged")
	_check(not source.contains("texture(TEXTURE, UV +"), "shader samples neighboring atlas texels")
	_check(not source.contains("SCREEN_UV"), "screen-space post-process entered actor shader")
	_check(not source.contains("discard"), "shader discards source pixels")


func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
