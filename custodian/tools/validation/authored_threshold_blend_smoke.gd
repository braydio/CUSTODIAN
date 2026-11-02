extends SceneTree

const THRESHOLD_BLEND_SCRIPT := preload(
	"res://game/world/levels/presentation/authored_threshold_blend_2d.gd"
)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var reference := Node2D.new()
	reference.name = "Reference"
	root.add_child(reference)
	var subject := Node2D.new()
	subject.name = "Subject"
	reference.add_child(subject)
	var target := ColorRect.new()
	target.name = "Target"
	reference.add_child(target)
	var blend := Node.new()
	blend.set_script(THRESHOLD_BLEND_SCRIPT)
	blend.name = "Blend"
	blend.reference_path = NodePath("..")
	blend.subject_path = NodePath("../Subject")
	blend.target_path = NodePath("../Target")
	blend.south_y = -608.0
	blend.north_y = -736.0
	blend.south_alpha = 0.0
	blend.north_alpha = 1.0
	reference.add_child(blend)

	subject.position.y = -608.0
	blend._process(0.0)
	assert(is_equal_approx(target.modulate.a, 0.0), "south edge must be transparent")
	subject.position.y = -672.0
	blend._process(0.0)
	assert(is_equal_approx(target.modulate.a, 0.5), "midpoint must be half blended")
	subject.position.y = -736.0
	blend._process(0.0)
	assert(is_equal_approx(target.modulate.a, 1.0), "north edge must be opaque")
	subject.position.y = -608.0
	blend._process(0.0)
	assert(is_equal_approx(target.modulate.a, 0.0), "southward travel must reverse blend")

	reference.queue_free()
	await process_frame
	print("authored_threshold_blend_smoke: PASS")
	quit(0)
