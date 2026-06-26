extends SceneTree

const REVIEW_SCENE := preload("res://scenes/debug/sundered_keep_overlay_authoring_review.tscn")


func _init() -> void:
	var review := REVIEW_SCENE.instantiate()
	root.add_child(review)
	current_scene = review
	await process_frame
	await process_frame

	var state := review.call("get_review_state") as Dictionary
	var overlay := state.get("overlay", {}) as Dictionary
	var map_state := state.get("map", {}) as Dictionary

	_assert(bool(overlay.get("loaded", false)), "overlay authoring JSON did not load")
	_assert(str(overlay.get("schema", "")) == "custodian.sundered_keep.overlay_authoring_mask.v1", "overlay authoring schema mismatch")
	_assert(int(overlay.get("floor_rects", 0)) > 0, "overlay authoring produced no floor rects")
	_assert(int(overlay.get("border_void_rects", 0)) > 0, "overlay authoring produced no border-void rects")
	_assert(int(overlay.get("solid_tiles", 0)) > 1000, "overlay authoring produced too few solid tiles")
	_assert(bool(map_state.get("underlay_present", false)), "review scene map underlay missing")
	_assert(
		str(map_state.get("authoring_mask_path", "")) == "res://content/levels/sundered_keep/sundered_keep_overlay_authoring.json",
		"map authoring mask path drifted"
	)

	print("[SunderedKeepOverlayAuthoringSmoke] OK: review scene loaded overlay authoring data")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[SunderedKeepOverlayAuthoringSmoke] %s" % message)
	quit(1)
