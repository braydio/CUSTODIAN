class_name PerceptionObservation
extends RefCounted

enum Channel { ACOUSTIC }

var channel: Channel = Channel.ACOUSTIC
var stimulus_kind: StringName = &"generic"
var observed_position: Vector2 = Vector2.ZERO
var source: Node2D = null
var source_team: StringName = &"neutral"
var salience: float = 0.0
var certainty: float = 0.0
var radius_px: float = 0.0
var loudness: float = 0.0
var threat_value: float = 0.0
var suppressed: bool = false
var event_timestamp_msec: int = 0
