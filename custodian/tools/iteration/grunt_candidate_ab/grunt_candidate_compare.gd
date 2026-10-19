extends Node2D
## DEV ONLY: compare live enemy_grunt.tscn against 96x96 candidate source crops.
## Visual benchmark only, not an animation/physics validation or production art load.

const GRUNT_SCENE: PackedScene = preload("res://game/actors/enemies/enemy_grunt.tscn")
const CANDIDATE_ROOT := "res://../.ai/grunt-candidate-raster-workflow-v1/out/"
const REDUCTION_MODES: Array[String] = ["crisp", "balanced", "clustered"]
const FACING_DIRECTIONS: Array[Vector2] = [Vector2.DOWN, Vector2.RIGHT, Vector2.UP, Vector2.LEFT]
const FACING_NAMES: Array[String] = ["S / front", "E / right", "N / back", "W / left"]
const FACING_CODES: Array[String] = ["s", "e", "n", "w"]
const BODY_HEIGHTS: Array[int] = [64, 72, 80]

var _facing_index := 0
var _height_index := 1
var _zoom_level := 2.6
var _original_actor: Node2D
var _candidate_actor: Node2D
var _original_sprite: AnimatedSprite2D
var _candidate_sprite: Sprite2D
var _instructions: Label
var _details: Label
var _camera: Camera2D
var _playing := true
var _candidate_load_status := "Not loaded"
var _candidate_missing_label: Label
var _reduction_mode_index := 0


func _ready() -> void:
    RenderingServer.set_default_clear_color(Color("12151d"))
    _camera = Camera2D.new()
    _camera.name = "ABCamera"
    _camera.position = Vector2(0, -1)
    _camera.zoom = Vector2.ONE * _zoom_level
    add_child(_camera)
    _camera.make_current()
    _original_actor = _new_grunt(Vector2(-112, 46))
    _candidate_actor = _new_grunt(Vector2(112, 46))
    _original_sprite = _original_actor.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
    var hidden_candidate_anim := _candidate_actor.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
    if hidden_candidate_anim != null:
        hidden_candidate_anim.hide()
    _candidate_sprite = Sprite2D.new()
    _candidate_sprite.name = "DEVONLY_CandidateReferenceSprite"
    _candidate_sprite.position = Vector2(0, -18)
    _candidate_sprite.centered = true
    _candidate_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _candidate_actor.add_child(_candidate_sprite)
    # Visible failure state; a missing texture must not silently look like
    # invisible candidate artwork.
    _candidate_missing_label = Label.new()
    _candidate_missing_label.name = "DEVONLY_CandidateLoadError"
    _candidate_missing_label.position = Vector2(-44, -30)
    _candidate_missing_label.add_theme_color_override("font_color", Color("ff7381"))
    _candidate_missing_label.add_theme_font_size_override("font_size", 10)
    _candidate_missing_label.text = "PNG LOAD FAILED"
    _candidate_missing_label.visible = false
    _candidate_actor.add_child(_candidate_missing_label)
    _build_overlay()
    _refresh()
    queue_redraw()


func _new_grunt(world_pos: Vector2) -> Node2D:
    # Both columns are the REAL Grunt scene; only one body's texture is replaced.
    var actor: Node2D = GRUNT_SCENE.instantiate()
    actor.position = world_pos
    actor.name = "BaselineRealGrunt" if world_pos.x < 0.0 else "CandidateRealGruntScene"
    add_child(actor)
    actor.set_physics_process(false)
    actor.set_process(false)
    var health := actor.get_node_or_null("HealthBar") as CanvasItem
    if health != null:
        health.hide()
    var fallback := actor.get_node_or_null("Visual") as CanvasItem
    if fallback != null:
        fallback.hide()
    var fx := actor.get_node_or_null("CustomEnemyFxSprite") as CanvasItem
    if fx != null:
        fx.hide()
    return actor


func _build_overlay() -> void:
    var ui := CanvasLayer.new()
    add_child(ui)
    var background := ColorRect.new()
    background.color = Color(0.055, 0.07, 0.095, 0.96)
    background.position = Vector2(0, 0)
    background.set_anchors_preset(Control.PRESET_TOP_WIDE)
    background.custom_minimum_size = Vector2(0, 126)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(background)
    _instructions = Label.new()
    _instructions.position = Vector2(20, 12)
    _instructions.add_theme_font_size_override("font_size", 19)
    _instructions.text = "CUSTODIAN  |  REAL GRUNT vs CUTOUT SOURCE CANDIDATE"
    ui.add_child(_instructions)
    _details = Label.new()
    _details.position = Vector2(20, 45)
    _details.add_theme_font_size_override("font_size", 14)
    _details.add_theme_color_override("font_color", Color("c6c8d2"))
    ui.add_child(_details)
    var footnote := Label.new()
    footnote.position = Vector2(20, 695)
    footnote.add_theme_font_size_override("font_size", 13)
    footnote.text = "DEV PREVIEW ONLY | Same Grunt scene, origin, collider, shadow, and sprite offset. No cutout joints or new animation yet."
    ui.add_child(footnote)


func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_LEFT:
            _facing_index = posmod(_facing_index - 1, FACING_CODES.size())
        KEY_RIGHT:
            _facing_index = (_facing_index + 1) % FACING_CODES.size()
        KEY_1:
            _height_index = 0
        KEY_2:
            _height_index = 1
        KEY_3:
            _height_index = 2
        KEY_M:
            _reduction_mode_index = (_reduction_mode_index + 1) % REDUCTION_MODES.size()
        KEY_SPACE:
            _playing = not _playing
        KEY_Z:
            _zoom_level = 1.0 if _zoom_level >= 3.0 else _zoom_level + 0.5
            _camera.zoom = Vector2.ONE * _zoom_level
        KEY_S:
            _take_screenshot()
        KEY_ESCAPE:
            get_tree().quit()
        _:
            return
    _refresh()
    get_viewport().set_input_as_handled()


func _refresh() -> void:
    var facing := FACING_DIRECTIONS[_facing_index]
    var code := FACING_CODES[_facing_index]
    var height := BODY_HEIGHTS[_height_index]
    var mode := REDUCTION_MODES[_reduction_mode_index]
    var path := "%s%s/candidate_%s_%dpx.png" % [CANDIDATE_ROOT, mode, code, height]
    # The ZIP ships genuine PNGs but no Godot .import cache. Calling
    # ResourceLoader.exists() here can report false when the project has not
    # imported new assets yet, leaving the intentionally hidden original sprite
    # with no replacement. Load the dev image directly instead.
    _candidate_sprite.texture = _load_dev_candidate_png(path)
    _candidate_sprite.visible = _candidate_sprite.texture != null
    _candidate_sprite.modulate = Color.WHITE
    _candidate_missing_label.visible = _candidate_sprite.texture == null
    var action_name := "missing"
    if _original_sprite != null and _original_sprite.sprite_frames != null:
        var action: StringName = &"locomotion.ready_idle"
        if _original_actor.has_method("resolve_enemy_action_animation"):
            action_name = String(_original_actor.call("resolve_enemy_action_animation", action, facing))
        if action_name.is_empty() or not _original_sprite.sprite_frames.has_animation(action_name):
            action_name = "idle_s" if _original_sprite.sprite_frames.has_animation("idle_s") else "missing"
        if action_name != "missing":
            _original_sprite.play(action_name)
            if not _playing:
                _original_sprite.stop()
    else:
        action_name = "baseline unavailable (see import errors)"
    _details.text = (
        "Facing: %s   |   Candidate height: %d px   |   Real Grunt clip: %s\n"
        + "Candidate PNG: %s\n"
        + "Mode: %s   |   LEFT/RIGHT facing    1/2/3 body height    M reduction mode    SPACE pause    Z zoom    S screenshot    ESC quit\n"
        + "Candidate is STATIC. This checks scale and silhouette, not motion."
    ) % [FACING_NAMES[_facing_index], height, action_name, _candidate_load_status, mode]


func _load_dev_candidate_png(path: String) -> Texture2D:
    # Development-only loader, intentionally independent of Godot's importer.
    # In the exported game use registered Asset Pipeline V2 resources instead.
    var absolute_path := ProjectSettings.globalize_path(path)
    if not FileAccess.file_exists(absolute_path):
        _candidate_load_status = "MISSING FILE: %s" % path
        push_error("[GruntAB] " + _candidate_load_status + ". Extract the full ZIP at the repository root.")
        return null
    var source_image := Image.new()
    var error := source_image.load(absolute_path)
    if error != OK:
        _candidate_load_status = "PNG READ ERROR %d: %s" % [error, path]
        push_error("[GruntAB] " + _candidate_load_status)
        return null
    if source_image.get_width() != 96 or source_image.get_height() != 96:
        _candidate_load_status = "WRONG SIZE: %dx%d (expected 96x96)" % [source_image.get_width(), source_image.get_height()]
        push_error("[GruntAB] " + _candidate_load_status)
        return null
    var used_rect := source_image.get_used_rect()
    if used_rect.size.x <= 0 or used_rect.size.y <= 0:
        _candidate_load_status = "IMAGE FULLY TRANSPARENT: %s" % path
        push_error("[GruntAB] " + _candidate_load_status)
        return null
    _candidate_load_status = "OK: direct PNG, occupied %dx%d px" % [used_rect.size.x, used_rect.size.y]
    print("[GruntAB] %s | %s" % [_candidate_load_status, path])
    return ImageTexture.create_from_image(source_image)


func _draw() -> void:
    draw_rect(Rect2(-250, -122, 500, 235), Color("242630"), true)
    for x in range(-240, 241, 16):
        draw_line(Vector2(x, -122), Vector2(x, 113), Color(0.23, 0.26, 0.3, 0.35), 0.5)
    for y in range(-112, 114, 16):
        draw_line(Vector2(-250, y), Vector2(250, y), Color(0.23, 0.26, 0.3, 0.35), 0.5)
    for x in [-112, 112]:
        var rect := Rect2(x - 48, 46 - 18 - 48, 96, 96)
        draw_rect(rect, Color(0.60, 0.66, 0.78, 0.26), false, 1)
        draw_line(Vector2(x - 28, 46), Vector2(x + 28, 46), Color(0.95, 0.75, 0.3, 0.8), 1)
        draw_line(Vector2(x, 46 - 8), Vector2(x, 46 + 8), Color(0.95, 0.75, 0.3, 0.8), 1)
    draw_line(Vector2(0, -120), Vector2(0, 110), Color(0.8, 0.84, 0.9, 0.3), 1)


func _take_screenshot() -> void:
    await RenderingServer.frame_post_draw
    var path := ProjectSettings.globalize_path("user://grunt_candidate_ab_%d.png" % Time.get_unix_time_from_system())
    var err := get_viewport().get_texture().get_image().save_png(path)
    if err == OK:
        print("GRUNT_CANDIDATE_AB_SCREENSHOT: ", path)
    else:
        push_error("Could not save screenshot: %s" % err)
