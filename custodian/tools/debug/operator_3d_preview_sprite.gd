class_name Operator3DPreviewSprite
extends Sprite2D

## Dev-only body renderer for the playable 3D preview. OperatorBodyPresenter retires body layers
## through is_playing()/stop(), which a plain Sprite2D lacks. This static frame never plays, so the
## presenter's stop path is a no-op. It owns no animation timing.


func is_playing() -> bool:
	return false


func stop() -> void:
	pass
