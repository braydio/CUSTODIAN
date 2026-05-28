clear

# ── Project root variable (change once if location moves) ──────────────
export CUSTODIAN_DIR="/home/braydenchaffee/Projects/CUSTODIAN/custodian"

# ── Usage log helper ───────────────────────────────────────────────────
_update_usage() {
	local name="$1"
	local usage_file="${HOME}/.custodian_alias_usage.log"
	echo "$(date '+%Y-%m-%d %H:%M:%S') - ${name}" >> "${usage_file}"
}

# ── Commands ───────────────────────────────────────────────────────────

# Generate json sidecars if needed (dry run)
dryjson() {
	_update_usage "dryjson"
	python "${CUSTODIAN_DIR}/tools/pipelines/generate_inbox_manifests.py" --dry-run
}

# Generate json sidecars if needed (live)
runjson() {
	_update_usage "runjson"
	python "${CUSTODIAN_DIR}/tools/pipelines/generate_inbox_manifests.py"
}

# Run sprite ingest pipeline
runsprite() {
	_update_usage "runsprite"
	python "${CUSTODIAN_DIR}/tools/pipelines/ingest.py"
}

# List current assets in sprite pipeline inbox
listbox() {
	_update_usage "listbox"
	eza "${CUSTODIAN_DIR}/content/sprites/_pipeline/inbox"
}

# ── Usage tally ───────────────────────────────────────────────────────
alias_usage() {
	local usage_file="${HOME}/.custodian_alias_usage.log"
	if [[ ! -f "$usage_file" ]]; then
		echo "No usage data yet."
		return
	fi
	echo "Custodian alias usage counts:"
	for cmd in dryjson runjson runsprite listbox; do
		local count
		count=$(grep -c "$cmd" "$usage_file" 2>/dev/null || echo 0)
		printf "  %-12s %d\n" "$cmd:" "$count"
	done
	echo "---"
	echo "Total: $(wc -l < "$usage_file") invocations"
}

echo "Custodian Commands: dryjson, runjson, runsprite, listbox"
echo "Type 'alias_usage' to see how many times you've used each."
