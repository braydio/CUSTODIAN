#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

# ----------------------------------------
# CUSTODIAN terrain recolor helper
# ----------------------------------------
# Usage:
#   ./recolor_custodian.sh
#   ./recolor_custodian.sh my_sheet.png
#
# If no file is passed, it auto-detects the newest PNG in the current folder.
# Outputs go into: <basename>_custodian/
# ----------------------------------------

need_cmd() {
	command -v "$1" >/dev/null 2>&1 || {
		echo "Error: required command '$1' not found."
		exit 1
	}
}

need_cmd magick
need_cmd awk
need_cmd find
need_cmd sort
need_cmd head
need_cmd cut

pick_latest_png() {
	find . -maxdepth 1 -type f \( -iname '*.png' \) \
		-printf '%T@ %p\n' |
		sort -nr |
		head -n 1 |
		cut -d' ' -f2-
}

INPUT="${1:-}"
if [[ -z "$INPUT" ]]; then
	INPUT="$(pick_latest_png || true)"
fi

if [[ -z "$INPUT" || ! -f "$INPUT" ]]; then
	echo "Error: no input PNG found."
	echo "Usage: ./recolor_custodian.sh [image.png]"
	exit 1
fi

INPUT="$(realpath "$INPUT")"
DIR="$(dirname "$INPUT")"
FILE="$(basename "$INPUT")"
NAME="${FILE%.*}"
OUTDIR="$DIR/${NAME}_custodian"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

ALPHA="$TMPDIR/alpha.png"
PALETTE="$TMPDIR/custodian_palette.png"
CLUT="$TMPDIR/custodian_terrain_clut.png"

mkdir -p "$OUTDIR"

echo "Input:  $INPUT"
echo "Output: $OUTDIR"

# ----------------------------------------
# Build palette strip
# ----------------------------------------
magick \
	xc:'#080F12' xc:'#151A1E' xc:'#1F262B' xc:'#282328' xc:'#2F3A40' \
	xc:'#3E4A4F' xc:'#516063' xc:'#657073' xc:'#787E81' xc:'#8F938F' \
	xc:'#A6A8AA' xc:'#C0C2CA' xc:'#D8DAD8' xc:'#E6E9EE' xc:'#F5F7F6' \
	xc:'#C7984D' xc:'#E2C06A' xc:'#B5533A' xc:'#8E483C' xc:'#C17268' \
	+append "$PALETTE"

cp "$PALETTE" "$OUTDIR/${NAME}_custodian_palette.png"

# ----------------------------------------
# Preserve alpha separately
# ----------------------------------------
magick "$INPUT" -alpha extract "$ALPHA"

restore_alpha() {
	local rgb="$1"
	local out="$2"
	magick "$rgb" "$ALPHA" \
		-alpha off \
		-compose CopyOpacity \
		-composite \
		"$out"
}

# ----------------------------------------
# Analyze image to pick a default
# ----------------------------------------
SATURATION="$(magick "$INPUT" \
	-alpha off \
	-colorspace HSL \
	-channel G -separate +channel \
	-format '%[fx:mean]' info:)"

LUMA="$(magick "$INPUT" \
	-alpha off \
	-colorspace Gray \
	-format '%[fx:mean]' info:)"

BEST_MODE="$(awk -v s="$SATURATION" -v l="$LUMA" 'BEGIN{
  if (s > 0.24) print "cold";
  else if (l > 0.72 && s > 0.18) print "value";
  else print "soft";
}')"

echo "Detected average saturation: $SATURATION"
echo "Detected average luma:       $LUMA"
echo "Best guess mode:             $BEST_MODE"

# ----------------------------------------
# Variant 1: soft in-scope recolor
# ----------------------------------------
SOFT_RGB="$TMPDIR/soft_rgb.png"
SOFT_OUT="$OUTDIR/${NAME}_custodian_soft.png"

magick "$INPUT" \
	-alpha off \
	-colorspace sRGB \
	-modulate 82,38,100 \
	-level 5%,96%,0.90 \
	-level-colors '#080F12,#D8DAD8' \
	"$SOFT_RGB"

restore_alpha "$SOFT_RGB" "$SOFT_OUT"

# ----------------------------------------
# Variant 2: colder / harsher recolor
# ----------------------------------------
COLD_RGB="$TMPDIR/cold_rgb.png"
COLD_OUT="$OUTDIR/${NAME}_custodian_cold.png"

magick "$INPUT" \
	-alpha off \
	-colorspace sRGB \
	-modulate 72,28,100 \
	-level 7%,94%,0.85 \
	-level-colors '#080F12,#A6A8AA' \
	-sigmoidal-contrast 3x45% \
	"$COLD_RGB"

restore_alpha "$COLD_RGB" "$COLD_OUT"

# ----------------------------------------
# Variant 3: palette-locked version
# ----------------------------------------
LOCKED_RGB="$TMPDIR/locked_rgb.png"
LOCKED_OUT="$OUTDIR/${NAME}_custodian_palette_locked.png"

magick "$SOFT_OUT" \
	-alpha off \
	+dither \
	-remap "$PALETTE" \
	"$LOCKED_RGB"

restore_alpha "$LOCKED_RGB" "$LOCKED_OUT"

# ----------------------------------------
# Variant 4: value-mapped version using CLUT
# ----------------------------------------
VALUE_RGB="$TMPDIR/value_rgb.png"
VALUE_OUT="$OUTDIR/${NAME}_custodian_value_mapped.png"
LUMA_IMG="$TMPDIR/luma.png"

magick \
	\( -size 1x28 gradient:'#080F12-#151A1E' \) \
	\( -size 1x38 gradient:'#151A1E-#1F262B' \) \
	\( -size 1x42 gradient:'#1F262B-#2F3A40' \) \
	\( -size 1x46 gradient:'#2F3A40-#516063' \) \
	\( -size 1x42 gradient:'#516063-#787E81' \) \
	\( -size 1x34 gradient:'#787E81-#A6A8AA' \) \
	\( -size 1x18 gradient:'#A6A8AA-#D8DAD8' \) \
	\( -size 1x8 gradient:'#D8DAD8-#E6E9EE' \) \
	-append "$CLUT"

cp "$CLUT" "$OUTDIR/${NAME}_custodian_clut.png"

magick "$INPUT" \
	-alpha off \
	-colorspace Gray \
	-auto-level \
	"$LUMA_IMG"

magick "$LUMA_IMG" "$CLUT" \
	-clut \
	"$VALUE_RGB"

restore_alpha "$VALUE_RGB" "$VALUE_OUT"

# ----------------------------------------
# Pick best guess output
# ----------------------------------------
BEST_OUT="$OUTDIR/${NAME}_custodian_best_guess.png"

case "$BEST_MODE" in
cold) cp "$COLD_OUT" "$BEST_OUT" ;;
value) cp "$VALUE_OUT" "$BEST_OUT" ;;
*) cp "$SOFT_OUT" "$BEST_OUT" ;;
esac

# ----------------------------------------
# Comparison strip
# ----------------------------------------
COMPARE="$OUTDIR/${NAME}_custodian_compare.png"
magick \
	"$INPUT" \
	"$SOFT_OUT" \
	"$COLD_OUT" \
	"$LOCKED_OUT" \
	"$VALUE_OUT" \
	-background '#080F12' \
	-gravity center \
	-geometry +24+24 \
	+append \
	"$COMPARE"

echo
echo "Done."
echo "Main output: $BEST_OUT"
echo "Other outputs:"
echo "  $SOFT_OUT"
echo "  $COLD_OUT"
echo "  $LOCKED_OUT"
echo "  $VALUE_OUT"
echo "  $COMPARE"
