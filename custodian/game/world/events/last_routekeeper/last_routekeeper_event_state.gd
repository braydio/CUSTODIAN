extends Resource

const EVENT_ID := &"last_routekeeper"

@export var signature := "B. CHAFFEE"
@export var assignment := "RETURN CORRIDOR SURVEY"
@export var status := "UNACKNOWLEDGED"

@export var discovered := false
@export var completed := false
@export var route_hint_tile := Vector2i.ZERO

var route_notes := [
	"ROUTE NOTE 003:\nBRIDGE VISIBLE. SHORE TRAVERSABLE. CENTER SPAN UNRELIABLE.",
	"ROUTE NOTE 009:\nMARKED THE LOWER STONES AGAIN. THE SEA KEEPS TAKING THE PAINT.",
	"ROUTE NOTE 014:\nIF THE GATE DOES NOT OPEN, THE ROAD BENEATH STILL REMEMBERS TRAFFIC.",
	"ROUTE NOTE 018:\nRETURNED TO MARK THE WAY BACK.\nRETURN NOT OBSERVED.",
]


func get_header_lines() -> Array[String]:
	return [
		"ROUTE AUTHORITY TRACE DETECTED",
		"SIGNATURE: %s" % signature,
		"ASSIGNMENT: %s" % assignment,
		"STATUS: %s" % status,
	]


func get_recovery_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append_array(get_header_lines())
	lines.append("")
	for note in route_notes:
		lines.append(note)
		lines.append("")
	lines.append("ROUTEKEEPER TRACE RECOVERED")
	lines.append("LOCAL TRAVERSAL HINT RECONSTRUCTED")
	return lines
