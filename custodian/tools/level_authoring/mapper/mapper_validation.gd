class_name MapperValidation
extends RefCounted

static func collision_findings(polylines: Array) -> Array[String]:
	var findings: Array[String] = []
	for polyline: Array in polylines:
		if polyline.size() < 2:
			findings.append("collision chain has fewer than two vertices")
		for index in range(polyline.size() - 1):
			var a := polyline[index] as Vector2
			var b := polyline[index + 1] as Vector2
			if a.is_equal_approx(b):
				findings.append("collision chain contains zero-length rail")
	return findings

