extends Node2D

@onready var fabricator: Node = $FieldFabricatorMk1
@onready var controller: Node = $FieldFabricatorMk1/VisualController
@onready var power_consumer: Node = $FieldFabricatorMk1/PowerConsumer

var state := "offline"


func _process(_delta: float) -> void:
	state = str(controller.call("get_active_state"))


func moment_forge_fixture_command(command: String, _args: Dictionary) -> Variant:
	match command:
		"power_on":
			power_consumer.call("apply_power_allocation", 25.0)
		"begin_fabrication":
			controller.call("play_state", &"fabricate")
		"complete_fabrication":
			controller.call("play_state", &"fabricate_complete")
		_:
			return {"ok": false, "error": "unknown command: %s" % command}
	state = str(controller.call("get_active_state"))
	return {"ok": true, "state": state}
