extends RefCounted
class_name CustodianStartupMode

const AWAKENING := "awakening"
const TWIN_SOLARIA := "twin-solaria"
const CONTRACT_SANDBOX := "contract-sandbox"
const MODES := [AWAKENING, TWIN_SOLARIA, CONTRACT_SANDBOX]


static func parse_args(args: PackedStringArray) -> Dictionary:
	var mode := AWAKENING
	var mode_seen := false
	var seed_seen := false
	var contract_seed: Variant = null
	var warning := ""

	for argument in args:
		if argument.begins_with("--custodian-start="):
			if mode_seen:
				warning = "Duplicate --custodian-start argument; using Awakening."
				break
			mode_seen = true
			mode = argument.trim_prefix("--custodian-start=")
			if mode not in MODES:
				warning = "Unknown CUSTODIAN startup mode '%s'; using Awakening." % mode
				mode = AWAKENING
				break
		elif argument == "--custodian-start":
			warning = "Malformed --custodian-start argument; using Awakening."
			break
		elif argument == "--contract-seed":
			warning = "Malformed --contract-seed argument; using Awakening."
			break
		elif argument.begins_with("--contract-seed="):
			if seed_seen:
				warning = "Duplicate --contract-seed argument; using Awakening."
				break
			seed_seen = true
			var seed_text := argument.trim_prefix("--contract-seed=")
			if not seed_text.is_valid_int():
				warning = "Malformed --contract-seed value; using Awakening."
				break
			contract_seed = seed_text.to_int()
			if contract_seed == 0:
				warning = "Contract seed must be nonzero; using Awakening."
				break

	if warning.is_empty() and seed_seen and mode != CONTRACT_SANDBOX:
		warning = "--contract-seed requires contract-sandbox mode; using Awakening."
	if not warning.is_empty():
		return {"mode": AWAKENING, "seed": null, "warning": warning}
	return {"mode": mode, "seed": contract_seed, "warning": ""}
