#!/usr/bin/env bash
set -euo pipefail

# Export every .aseprite/.ase file in a directory to PNGs in ONE FLAT OUTPUT DIR.
#
# Usage:
#   ./tools/export_aseprite_dir_flat.sh INPUT_DIR OUTPUT_DIR [sheet|frames|both]
#
# Examples:
#   ./tools/export_aseprite_dir_flat.sh modular modular/_png_exports both
#   ./tools/export_aseprite_dir_flat.sh custodian/content/sprites .ai/aseprite_exports sheet
#
# Output examples:
#   OUTPUT_DIR/modular__lower__operator__body__run_01__e__5f__96__a1b2c3d4__sheet.png
#   OUTPUT_DIR/modular__lower__operator__body__run_01__e__5f__96__a1b2c3d4__sheet.json
#   OUTPUT_DIR/modular__lower__operator__body__run_01__e__5f__96__a1b2c3d4__frame_000.png

IN_DIR="${1:-.}"
OUT_DIR="${2:-./_aseprite_png_exports}"
MODE="${3:-sheet}"

ASEPRITE_BIN="${ASEPRITE_BIN:-aseprite}"

if ! command -v "$ASEPRITE_BIN" >/dev/null 2>&1; then
	echo "ERROR: aseprite not found in PATH."
	echo "Install it or run with ASEPRITE_BIN=/path/to/aseprite"
	exit 1
fi

case "$MODE" in
sheet | frames | both) ;;
*)
	echo "ERROR: mode must be one of: sheet, frames, both"
	exit 1
	;;
esac

IN_DIR="$(realpath "$IN_DIR")"
mkdir -p "$OUT_DIR"
OUT_DIR="$(realpath "$OUT_DIR")"

echo "Input:  $IN_DIR"
echo "Output: $OUT_DIR"
echo "Mode:   $MODE"
echo

count=0

slugify_rel_path() {
	local rel_no_ext="$1"
	local slug

	# Replace directory separators with "__"
	slug="${rel_no_ext//\//__}"

	# Replace weird filename chars with underscores
	slug="$(printf '%s' "$slug" | sed -E 's/[^A-Za-z0-9_.-]+/_/g; s/_+/_/g; s/^_//; s/_$//')"

	printf '%s' "$slug"
}

while IFS= read -r -d '' src; do
	rel="${src#$IN_DIR/}"
	rel_no_ext="${rel%.*}"

	slug="$(slugify_rel_path "$rel_no_ext")"
	hash="$(printf '%s' "$rel" | sha1sum | cut -c1-8)"
	out_base="$OUT_DIR/${slug}__${hash}"

	echo "Exporting: $rel"
	echo "  -> ${out_base}__..."

	if [[ "$MODE" == "sheet" || "$MODE" == "both" ]]; then
		"$ASEPRITE_BIN" \
			--batch "$src" \
			--sheet "${out_base}__sheet.png" \
			--data "${out_base}__sheet.json" \
			--format json-array \
			--list-tags \
			--list-layers
	fi

	if [[ "$MODE" == "frames" || "$MODE" == "both" ]]; then
		"$ASEPRITE_BIN" \
			--batch "$src" \
			--save-as "${out_base}__frame_{frame}.png"
	fi

	count=$((count + 1))
done < <(
	find "$IN_DIR" \
		-type f \
		\( -iname '*.aseprite' -o -iname '*.ase' \) \
		-print0
)

echo
echo "Done. Exported $count Aseprite file(s)."
echo "Flat output written to: $OUT_DIR"
