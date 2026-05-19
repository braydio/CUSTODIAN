extends RefCounted
class_name ARRNBenefitsManager

const LEVEL_BENEFITS := [
	"signal_reconstruction_i",
	"maintenance_archive_i",
	"threat_forecast_i",
	"fab_blueprints_i",
	"logistics_optimization_i",
	"signal_reconstruction_ii",
	"archival_synthesis",
]

const BENEFIT_LABELS := {
	"signal_reconstruction_i": "SIGNAL_RECONSTRUCTION_I",
	"maintenance_archive_i": "MAINTENANCE_ARCHIVE_I",
	"threat_forecast_i": "THREAT_FORECAST_I",
	"fab_blueprints_i": "FAB_BLUEPRINTS_I",
	"logistics_optimization_i": "LOGISTICS_OPTIMIZATION_I",
	"signal_reconstruction_ii": "SIGNAL_RECONSTRUCTION_II",
	"archival_synthesis": "ARCHIVAL_SYNTHESIS",
}


func build_benefits(knowledge_index: int) -> Dictionary:
	var benefits: Dictionary = {}
	for i in range(LEVEL_BENEFITS.size()):
		benefits[LEVEL_BENEFITS[i]] = knowledge_index >= i + 1
	benefits["fab_blueprints_archive"] = bool(benefits.get("fab_blueprints_i", false))
	return benefits


func unlocked_labels(knowledge_index: int) -> Array[String]:
	var labels: Array[String] = []
	for i in range(mini(maxi(knowledge_index, 0), LEVEL_BENEFITS.size())):
		var key: String = str(LEVEL_BENEFITS[i])
		labels.append(str(BENEFIT_LABELS.get(key, key.to_upper())))
	return labels


func label_for_level(level: int) -> String:
	if level <= 0 or level > LEVEL_BENEFITS.size():
		return ""
	var key: String = str(LEVEL_BENEFITS[level - 1])
	return str(BENEFIT_LABELS.get(key, key.to_upper()))
