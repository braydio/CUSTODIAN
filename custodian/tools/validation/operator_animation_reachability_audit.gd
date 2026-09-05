extends SceneTree

const CATALOG_PATH := "res://content/data/operator/generated/operator_animation_catalog.generated.json"
const REACHABILITY_PATH := "res://content/data/operator/operator_animation_reachability.json"
const VALID_STATUSES := [
	"LIVE",
	"DORMANT",
	"SUPERSEDED",
	"ALTERNATE_LAYER",
	"DORMANT_PENDING_INTERACTION_SUCCESS_CONTRACT",
]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog: Variant = _load_json(CATALOG_PATH)
	_expect(
		catalog is Dictionary and catalog.get("schema", "") == "custodian.operator_animation_catalog.v2",
		"catalog schema mismatch or missing: %s" % CATALOG_PATH
	)
	var reachability: Variant = _load_json(REACHABILITY_PATH)
	_expect(
		reachability is Dictionary and reachability.has("entries"),
		"reachability contract missing 'entries': %s" % REACHABILITY_PATH
	)

	var animations: Dictionary = catalog.get("animations", {}) if catalog is Dictionary else {}
	var entries: Array = reachability.get("entries", []) if reachability is Dictionary else []

	# Reachability entries are indexed two ways: a general classification that
	# covers every layer of a (profile, group, action), and layer-specific
	# overrides (used when different layers of one action have different
	# reachability, e.g. an ALTERNATE_LAYER split).
	var general: Dictionary = {}
	var per_layer: Dictionary = {}
	for entry_variant in entries:
		if not (entry_variant is Dictionary):
			_failures.append("reachability entry is not an object: %s" % str(entry_variant))
			continue
		var entry: Dictionary = entry_variant
		var status := str(entry.get("status", ""))
		var key := "%s/%s/%s" % [entry.get("profile", ""), entry.get("group", ""), entry.get("action", "")]
		_expect(
			status in VALID_STATUSES,
			"invalid reachability status '%s' for %s" % [status, key]
		)
		if entry.has("layer"):
			var layer_key := "%s/%s" % [key, entry.get("layer")]
			_expect(not per_layer.has(layer_key), "duplicate reachability entry for %s" % layer_key)
			per_layer[layer_key] = entry
		else:
			_expect(not general.has(key), "duplicate reachability entry for %s" % key)
			general[key] = entry

	# Every non-legacy canonical (profile, group, action, layer) emitted by the
	# Operator animation catalog must resolve to exactly one classification.
	var missing: Array[String] = []
	for semantic_key in animations.keys():
		var record: Dictionary = animations[semantic_key]
		var action := str(record.get("action", ""))
		if action.begins_with("legacy_") or action.contains("_legacy_") or action == "melee_1h":
			continue
		var profile := str(record.get("profile", ""))
		var group := str(record.get("group", ""))
		var key := "%s/%s/%s" % [profile, group, action]
		var layers: Dictionary = record.get("layers", {})
		for layer in layers.keys():
			var layer_key := "%s/%s" % [key, layer]
			if per_layer.has(layer_key) or general.has(key):
				continue
			var missing_entry := "%s (layer=%s)" % [key, layer]
			if not missing.has(missing_entry):
				missing.append(missing_entry)

	for missing_entry in missing:
		_failures.append("No reachability classification for canonical action: %s" % missing_entry)

	if _failures.is_empty():
		print(
			"operator_animation_reachability_audit: PASS (%d catalog actions checked, %d classifications)"
			% [animations.size(), entries.size()]
		)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		_failures.append("missing file: %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text())


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
