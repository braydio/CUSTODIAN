extends SubViewportContainer

@onready var sub_viewport: SubViewport = %SubViewport
@onready var border: Line2D = %border
@onready var placeholder: ColorRect = %placeholder
@onready var camera_2d: Camera2D = %Camera2D
@onready var marker: Sprite2D = %marker
@onready var sub_viewport_container: SubViewportContainer = $"."

@export var zoom:float=0.5
@export var target:Node2D
@export var hide_marker:=false
@export var marker_image:Texture2D
@export var window_size:Vector2i=Vector2i(256,128)
@export var border_line_color:Color=Color.BLACK
@export var frame_image:PackedScene
@export var hide_layer2:bool=false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## iniating everything:
	
	if hide_marker:
		marker.hide()
	sub_viewport.size=window_size
	marker.texture=marker_image
	placeholder.hide()
	camera_2d.zoom=(Vector2(zoom,zoom))

	border.default_color=border_line_color
	border.add_point(Vector2(2.5,2.5))
	border.add_point(Vector2(sub_viewport.size.x-2.5,2.5))
	border.add_point(Vector2(sub_viewport.size.x-2.5,sub_viewport.size.y-2.5))
	border.add_point(Vector2(2.5,sub_viewport.size.y-2.5))
	border.add_point(Vector2(2.5,0))
	if hide_layer2:
		sub_viewport.set_canvas_cull_mask_bit(1,false)
	marker.position=Vector2(sub_viewport.size.x/2,sub_viewport.size.y/2)
	if frame_image and frame_image:
		# Create an instance of the NinePatchRect scene
		var fameimage = frame_image.instantiate() 
		if fameimage is NinePatchRect:
			add_child(fameimage)
			fameimage.custom_minimum_size=Vector2(sub_viewport.size.x,sub_viewport.size.y)
	sub_viewport.world_2d=get_tree().root.world_2d

# Called every frame. 'delta' is the elapsed time since the previous frame.

func _process(delta: float) -> void:
	if target:
		camera_2d.position=target.position
