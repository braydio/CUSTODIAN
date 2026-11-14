extends Node
## Persistent, save-facing vehicle diagnosis knowledge.
##
## Scan inputs are immutable snapshots. This authority never references live
## vehicle nodes and never creates parts or mutates fabrication/restoration state.

const DEFAULT_PROGRESSION_PATH := "res://content/vehicles/vehicle_knowledge_progression.json"
const SAVE_SCHEMA_VERSION := 1

var _progression: Dictionary = {}
var _domains: Array[String] = []
var _domain_xp: Dictionary = {}
var _pattern_evidence: Dictionary = {}
var _scanned_fingerprints: Dictionary = {}
var _archetype_scan_counts: Dictionary = {}


func _ready() -> void:
	load_progression(DEFAULT_PROGRESSION_PATH)


func load_progression(path: String = DEFAULT_PROGRESSION_PATH) -> bool:
	if not FileAccess.file_exists(path):
		push_error("VehicleKnowledgeState: missing progression data %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("VehicleKnowledgeState: progression data must be a JSON object")
		return false
	return configure_progression(parsed as Dictionary)


func configure_progression(data: Dictionary) -> bool:
	var domains_value: Variant = data.get("domains", [])
	var thresholds: Variant = data.get("level_thresholds", {})
	var repeat_values: Variant = data.get("archetype_diminishing_multipliers", [])
	var condition_values: Variant = data.get("condition_multipliers", {})
	if not domains_value is Array or not thresholds is Dictionary \
			or not repeat_values is Array or not condition_values is Dictionary:
		return false
	var domains: Array[String] = []
	for value: Variant in domains_value:
		var domain := String(value)
		if domain.is_empty() or domains.has(domain):
			return false
		domains.append(domain)
	if domains.is_empty() or repeat_values.is_empty():
		return false
	for domain: String in domains:
		var levels: Variant = thresholds.get(domain)
		if not levels is Array or levels.is_empty():
			return false
		var previous := -1
		for value: Variant in levels:
			var threshold := int(value)
			if threshold < 0 or threshold <= previous:
				return false
			previous = threshold
	for condition: String in ["OPERATIONAL", "DISABLED", "WRECKAGE"]:
		if not condition_values.has(condition):
			return false
	_progression = data.duplicate(true)
	_domains = domains
	return true


func get_domain_xp(domain: StringName) -> int:
	return int(_domain_xp.get(String(domain), 0))


func get_domain_level(domain: StringName) -> int:
	var domain_id := String(domain)
	var thresholds: Array = Array(Dictionary(_progression.get("level_thresholds", {})).get(domain_id, []))
	var xp := get_domain_xp(domain)
	var level := 0
	for index in range(thresholds.size()):
		if xp < int(thresholds[index]):
			break
		level = index
	return level


func get_pattern_evidence(pattern_id: StringName) -> int:
	return int(_pattern_evidence.get(String(pattern_id), 0))


func has_scanned(fingerprint: String) -> bool:
	return _scanned_fingerprints.has(fingerprint)


func record_vehicle_scan(scan: Dictionary) -> Dictionary:
	var fingerprint := String(scan.get("fingerprint", "")).strip_edges()
	var archetype := String(scan.get("archetype_id", "")).strip_edges()
	if fingerprint.is_empty() or archetype.is_empty():
		return _rejection("INVALID_SCAN_IDENTITY", fingerprint)
	if has_scanned(fingerprint):
		return _rejection("ALREADY_SCANNED", fingerprint)
	var condition := String(scan.get("condition", ""))
	var condition_multipliers: Dictionary = Dictionary(_progression.get("condition_multipliers", {}))
	if not condition_multipliers.has(condition):
		return _rejection("INVALID_CONDITION", fingerprint)
	var base_xp: Variant = scan.get("base_xp", {})
	var patterns: Variant = scan.get("patterns", [])
	if not base_xp is Dictionary or not patterns is Array:
		return _rejection("INVALID_SCAN_PAYLOAD", fingerprint)
	var repeat_values: Array = Array(_progression.get("archetype_diminishing_multipliers", []))
	if repeat_values.is_empty():
		return _rejection("PROGRESSION_UNAVAILABLE", fingerprint)
	var prior_count := int(_archetype_scan_counts.get(archetype, 0))
	var repeat_index := mini(prior_count, repeat_values.size() - 1)
	var repeat_multiplier := maxf(0.0, float(repeat_values[repeat_index]))
	var condition_multiplier := maxf(0.0, float(condition_multipliers[condition]))
	var minimum_gain := maxi(0, int(_progression.get("minimum_xp_gain", 0)))
	for domain_variant: Variant in base_xp.keys():
		if not _domains.has(String(domain_variant)):
			return _rejection("UNKNOWN_DOMAIN", fingerprint)
	for pattern_variant: Variant in patterns:
		if not pattern_variant is Dictionary:
			return _rejection("INVALID_PATTERN", fingerprint)
	var xp_gained: Dictionary = {}
	for domain_variant: Variant in base_xp.keys():
		var domain := String(domain_variant)
		var base_amount := maxi(0, int(base_xp[domain_variant]))
		var multiplier := repeat_multiplier * condition_multiplier
		var amount := int(round(float(base_amount) * multiplier))
		if base_amount > 0 and multiplier > 0.0:
			amount = maxi(amount, minimum_gain)
		if amount > 0:
			_domain_xp[domain] = get_domain_xp(StringName(domain)) + amount
			xp_gained[domain] = amount
	var evidence_gained: Dictionary = {}
	for pattern_variant: Variant in patterns:
		if not pattern_variant is Dictionary:
			continue
		var pattern: Dictionary = pattern_variant
		var pattern_id := String(pattern.get("pattern_id", "")).strip_edges()
		var observable: Variant = pattern.get("observable_conditions", [])
		if pattern_id.is_empty() or not observable is Array or not observable.has(condition):
			continue
		var amount := maxi(0, int(pattern.get("base_evidence", 0)))
		if amount <= 0:
			continue
		_pattern_evidence[pattern_id] = get_pattern_evidence(StringName(pattern_id)) + amount
		evidence_gained[pattern_id] = int(evidence_gained.get(pattern_id, 0)) + amount
	_scanned_fingerprints[fingerprint] = true
	_archetype_scan_counts[archetype] = prior_count + 1
	var levels: Dictionary = {}
	for domain: String in _domains:
		levels[domain] = get_domain_level(StringName(domain))
	return {
		"accepted": true,
		"reason": "",
		"fingerprint": fingerprint,
		"vehicle_name": String(scan.get("display_name", archetype)),
		"xp_gained": xp_gained,
		"domain_levels": levels,
		"pattern_evidence_gained": evidence_gained,
		"pattern_evidence": _pattern_evidence.duplicate(true),
		"archetype_scan_count": prior_count + 1,
		"repeat_multiplier": repeat_multiplier,
		"learned_any": not xp_gained.is_empty() or not evidence_gained.is_empty(),
	}


func meets_requirements(requirements: Dictionary) -> bool:
	return bool(get_requirement_status(requirements).get("met", false))


func get_requirement_status(requirements: Dictionary) -> Dictionary:
	var unmet: Array[Dictionary] = []
	var domains: Variant = requirements.get("domains", [])
	var patterns: Variant = requirements.get("patterns", [])
	if not domains is Array or not patterns is Array:
		return {"met": false, "unmet": [{"reason": "INVALID_REQUIREMENTS"}]}
	for requirement_variant: Variant in domains:
		if not requirement_variant is Dictionary:
			unmet.append({"reason": "INVALID_DOMAIN_REQUIREMENT"})
			continue
		var requirement: Dictionary = requirement_variant
		var domain := String(requirement.get("domain", ""))
		var required_level := maxi(0, int(requirement.get("level", 0)))
		var current_level := get_domain_level(StringName(domain))
		if not _domains.has(domain) or current_level < required_level:
			unmet.append({"domain": domain, "required_level": required_level, "current_level": current_level})
	for requirement_variant: Variant in patterns:
		if not requirement_variant is Dictionary:
			unmet.append({"reason": "INVALID_PATTERN_REQUIREMENT"})
			continue
		var requirement: Dictionary = requirement_variant
		var pattern_id := String(requirement.get("pattern_id", ""))
		var required_evidence := maxi(0, int(requirement.get("evidence", 0)))
		var current_evidence := get_pattern_evidence(StringName(pattern_id))
		if pattern_id.is_empty() or current_evidence < required_evidence:
			unmet.append({"pattern_id": pattern_id, "required_evidence": required_evidence, "current_evidence": current_evidence})
	return {"met": unmet.is_empty(), "unmet": unmet}


func to_save_dict() -> Dictionary:
	var fingerprints: Array[String] = []
	for fingerprint: Variant in _scanned_fingerprints.keys():
		fingerprints.append(String(fingerprint))
	fingerprints.sort()
	return {
		"schema_version": SAVE_SCHEMA_VERSION,
		"domain_xp": _domain_xp.duplicate(true),
		"pattern_evidence": _pattern_evidence.duplicate(true),
		"scanned_fingerprints": fingerprints,
		"archetype_scan_counts": _archetype_scan_counts.duplicate(true),
	}


func from_save_dict(data: Dictionary) -> void:
	_domain_xp.clear()
	_pattern_evidence.clear()
	_scanned_fingerprints.clear()
	_archetype_scan_counts.clear()
	var saved_xp: Variant = data.get("domain_xp", {})
	var saved_patterns: Variant = data.get("pattern_evidence", {})
	var saved_fingerprints: Variant = data.get("scanned_fingerprints", [])
	var saved_counts: Variant = data.get("archetype_scan_counts", {})
	if saved_xp is Dictionary:
		for key: Variant in saved_xp.keys():
			var domain := String(key)
			if _domains.has(domain):
				_domain_xp[domain] = maxi(0, int(saved_xp[key]))
	if saved_patterns is Dictionary:
		for key: Variant in saved_patterns.keys():
			var pattern := String(key)
			if not pattern.is_empty():
				_pattern_evidence[pattern] = maxi(0, int(saved_patterns[key]))
	if saved_fingerprints is Array:
		for value: Variant in saved_fingerprints:
			var fingerprint := String(value).strip_edges()
			if not fingerprint.is_empty():
				_scanned_fingerprints[fingerprint] = true
	if saved_counts is Dictionary:
		for key: Variant in saved_counts.keys():
			var archetype := String(key)
			if not archetype.is_empty():
				_archetype_scan_counts[archetype] = maxi(0, int(saved_counts[key]))


func reset_for_validation() -> void:
	_domain_xp.clear()
	_pattern_evidence.clear()
	_scanned_fingerprints.clear()
	_archetype_scan_counts.clear()


func _rejection(reason: String, fingerprint: String) -> Dictionary:
	return {"accepted": false, "reason": reason, "fingerprint": fingerprint, "learned_any": false}
