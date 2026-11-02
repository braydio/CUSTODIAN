class_name WorldTransitionResult
extends RefCounted

var request_id := ""
var succeeded := false
var source_context: StringName = &"none"
var final_context: StringName = &"none"
var final_phase: StringName = &"idle"
var failure_code: StringName = &""
var failure_reason := ""
var operator_position := Vector2.ZERO
var binding_order: Array[StringName] = []


func to_dictionary() -> Dictionary:
	return {
		"request_id": request_id,
		"succeeded": succeeded,
		"source_context": source_context,
		"final_context": final_context,
		"final_phase": final_phase,
		"failure_code": failure_code,
		"failure_reason": failure_reason,
		"operator_position": operator_position,
		"binding_order": binding_order.duplicate(),
	}
