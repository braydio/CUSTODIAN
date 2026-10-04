extends InteractableLevelExit2D

const BODY := "res://content/sprites/environment/structure/district_transfer_frame/runtime/body/structure/district_transfer_frame__body__structure__body__omni__1f__192x256.png"
const PORTAL := "res://content/sprites/environment/structure/district_transfer_frame/runtime/fx/interaction/district_transfer_frame__fx__interaction__aperture_loop__omni__8f__96x160.png"


func _ready() -> void:
	trigger_on_body_entered = false
	add_to_group("interactable")
	_add_frame_visuals()
	super._ready()


func _add_frame_visuals() -> void:
	var body := Sprite2D.new()
	body.texture = load(BODY)
	body.position = Vector2(0, -72)
	body.z_index = 3
	add_child(body)
	var portal_texture := load(PORTAL) as Texture2D
	var frames := SpriteFrames.new()
	frames.add_animation("portal")
	frames.set_animation_speed("portal", 7.0)
	frames.set_animation_loop("portal", true)
	for index in range(8):
		var atlas := AtlasTexture.new()
		atlas.atlas = portal_texture
		atlas.region = Rect2(index * 96, 0, 96, 160)
		frames.add_frame("portal", atlas)
	var portal := AnimatedSprite2D.new()
	portal.sprite_frames = frames
	portal.position = Vector2(0, -78)
	portal.z_index = 2
	add_child(portal)
	portal.play("portal")
