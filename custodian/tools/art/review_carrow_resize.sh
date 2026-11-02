#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# CUSTODIAN — Carrow / District Transfer Frame review normalizer
#
# Requires:
#   imagemagick
#   aseprite
#
# Arch:
#   sudo pacman -S imagemagick aseprite
#
# Usage:
#   ./custodian/tools/art/review_carrow_resize.sh
#
# Optional:
#   SOURCE_DIR=/some/path REVIEW_DIR=/some/path ./script.sh
# -----------------------------------------------------------------------------

REPO_ROOT="$(git rev-parse --show-toplevel)"

SOURCE_DIR="${SOURCE_DIR:-$REPO_ROOT/custodian/asset_drop/source_work/district_transfer_frame}"
REVIEW_DIR="${REVIEW_DIR:-$REPO_ROOT/custodian/asset_drop/production_prep/carrow_resize_review}"

mkdir -p "$REVIEW_DIR"

command -v magick >/dev/null || {
	echo "ERROR: ImageMagick 'magick' not found."
	exit 1
}

command -v aseprite >/dev/null || {
	echo "ERROR: 'aseprite' not found."
	exit 1
}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

pause_for_review() {
	local src="$1"
	local out="$2"

	echo
	echo "================================================================"
	echo "SOURCE : $src"
	echo "OUTPUT : $out"
	echo "================================================================"
	echo

	# Open both source and normalized derivative in Aseprite.
	aseprite "$src" "$out" >/dev/null 2>&1 &

	read -r -p "Review in Aseprite, then press ENTER for next asset..."
}

clean_alpha() {
	local src="$1"
	local dst="$2"

	# Preserve graduated alpha, but hard-zero nearly invisible AI matte.
	magick "$src" \
		-channel A \
		-threshold 6.3% \
		+channel \
		"$dst"
}

# Resize a single object while preserving aspect ratio.
# Object is trimmed to alpha bounds, fitted into target canvas, centered.
resize_static() {
	local filename="$1"
	local width="$2"
	local height="$3"
	local output_name="${4:-$filename}"

	local src="$SOURCE_DIR/$filename"
	local out="$REVIEW_DIR/$output_name"

	[[ -f "$src" ]] || {
		echo "MISSING: $src"
		return
	}

	echo "Normalizing static: $filename -> ${width}x${height}"

	magick "$src" \
		-background none \
		-trim \
		+repage \
		-filter Lanczos \
		-resize "${width}x${height}>" \
		-gravity center \
		-extent "${width}x${height}" \
		"$out"

	pause_for_review "$src" "$out"
}

# Similar to resize_static, but preserve the original graduated alpha.
resize_vfx_static() {
	local filename="$1"
	local width="$2"
	local height="$3"
	local output_name="${4:-$filename}"

	local src="$SOURCE_DIR/$filename"
	local out="$REVIEW_DIR/$output_name"

	[[ -f "$src" ]] || {
		echo "MISSING: $src"
		return
	}

	echo "Normalizing VFX/static: $filename -> ${width}x${height}"

	magick "$src" \
		-background none \
		-trim \
		+repage \
		-filter Lanczos \
		-resize "${width}x${height}>" \
		-gravity center \
		-extent "${width}x${height}" \
		"$out"

	pause_for_review "$src" "$out"
}

# -----------------------------------------------------------------------------
# Grid-sheet extractor
#
# Takes a generated NxM grid:
#
#   source
#      ↓
#   crop each grid cell
#      ↓
#   trim logical content
#      ↓
#   fit onto identical runtime frame canvas
#      ↓
#   repack horizontal
#
# Example:
#   aperture source = 4 cols x 2 rows
#   target = 8 horizontal frames @ 96x160
# -----------------------------------------------------------------------------

resize_grid_sheet() {
	local filename="$1"
	local cols="$2"
	local rows="$3"
	local frame_w="$4"
	local frame_h="$5"
	local output_name="${6:-$filename}"

	local src="$SOURCE_DIR/$filename"
	local out="$REVIEW_DIR/$output_name"

	[[ -f "$src" ]] || {
		echo "MISSING: $src"
		return
	}

	local temp
	temp="$(mktemp -d)"

	local src_w
	local src_h

	src_w="$(magick identify -format '%w' "$src")"
	src_h="$(magick identify -format '%h' "$src")"

	local cell_w=$((src_w / cols))
	local cell_h=$((src_h / rows))

	echo
	echo "Normalizing sheet: $filename"
	echo "Source: ${src_w}x${src_h}"
	echo "Grid: ${cols}x${rows}"
	echo "Approx cells: ${cell_w}x${cell_h}"
	echo "Runtime frames: ${frame_w}x${frame_h}"

	local frame=0

	for ((row = 0; row < rows; row++)); do
		for ((col = 0; col < cols; col++)); do

			local x=$((col * cell_w))
			local y=$((row * cell_h))

			# Last column / row absorb source dimensions that don't divide evenly.
			local crop_w="$cell_w"
			local crop_h="$cell_h"

			if ((col == cols - 1)); then
				crop_w=$((src_w - x))
			fi

			if ((row == rows - 1)); then
				crop_h=$((src_h - y))
			fi

			printf -v frame_name "%03d.png" "$frame"

			magick "$src" \
				-crop "${crop_w}x${crop_h}+${x}+${y}" \
				+repage \
				-background none \
				-trim \
				+repage \
				-filter Lanczos \
				-resize "${frame_w}x${frame_h}>" \
				-gravity center \
				-extent "${frame_w}x${frame_h}" \
				"$temp/$frame_name"

			frame=$((frame + 1))
		done
	done

	magick "$temp"/*.png +append "$out"

	rm -rf "$temp"

	pause_for_review "$src" "$out"
}

# -----------------------------------------------------------------------------
# Two separate props presented side-by-side.
# Same implementation as a 2x1 logical sheet.
# -----------------------------------------------------------------------------

resize_pair_sheet() {
	resize_grid_sheet "$1" 2 1 "$2" "$3" "$4"
}

# -----------------------------------------------------------------------------
# SOURCE NAME CLEANUP
#
# We don't rename the source masters automatically.
# We simply map messy source names to clean derivative names.
# -----------------------------------------------------------------------------

echo
echo "==============================================================="
echo " CUSTODIAN — CARROW ASSET NORMALIZATION REVIEW"
echo "==============================================================="
echo "Source:"
echo "  $SOURCE_DIR"
echo
echo "Review derivatives:"
echo "  $REVIEW_DIR"
echo

# -----------------------------------------------------------------------------
# TRANSFER FRAME BODY
# -----------------------------------------------------------------------------

resize_static \
	"district_transfer_frame_body_v1.png" \
	192 256 \
	"district_transfer_frame_body_v1.png"

resize_static \
	"district_transfer_frame_threshold_v1.png" \
	160 96 \
	"district_transfer_frame_threshold_v1.png"

# Contact shadow deliberately retains graduated alpha.
if [[ -f "$SOURCE_DIR/district_transfer_frame_body_contact_shadow_v1.png" ]]; then
	resize_vfx_static \
		"district_transfer_frame_body_contact_shadow_v1.png" \
		192 96 \
		"district_transfer_contact_shadow_v1.png"
else
	resize_vfx_static \
		"district_transfer_contact_shadow_v1.png" \
		192 96 \
		"district_transfer_contact_shadow_v1.png"
fi

# -----------------------------------------------------------------------------
# TRANSFER FRAME FX
# -----------------------------------------------------------------------------

# Generated as 4 columns x 2 rows.
resize_grid_sheet \
	"district_transfer_frame_aperture_v1_8f.png" \
	4 2 \
	96 160 \
	"district_transfer_frame_aperture_v1_8f.png"

# Generated as 3 columns x 2 rows.
BOOT_SRC="district_transfer_frame_boot_v1_6f.png"

if [[ -f "$SOURCE_DIR/district_transfer_frame_boot_v1_6f.png.png" ]]; then
	BOOT_SRC="district_transfer_frame_boot_v1_6f.png.png"
fi

resize_grid_sheet \
	"$BOOT_SRC" \
	3 2 \
	96 160 \
	"district_transfer_frame_boot_v1_6f.png"

# Generated as horizontal 6-frame sheet.
FAILURE_SRC="district_transfer_frame_failure_v1_6f.png"

if [[ -f "$SOURCE_DIR/district_transfer_frame_failure_v1_6f_96x160.png.png" ]]; then
	FAILURE_SRC="district_transfer_frame_failure_v1_6f_96x160.png.png"
fi

resize_grid_sheet \
	"$FAILURE_SRC" \
	6 1 \
	96 160 \
	"district_transfer_frame_failure_v1_6f.png"

# Generated as horizontal 4-frame sheet.
EMISSIVE_SRC="district_transfer_frame_emissive_v1_4f.png"

if [[ -f "$SOURCE_DIR/district_transfer_frame_emmisive_v1_4f.png" ]]; then
	EMISSIVE_SRC="district_transfer_frame_emmisive_v1_4f.png"
fi

resize_grid_sheet \
	"$EMISSIVE_SRC" \
	4 1 \
	192 256 \
	"district_transfer_frame_emissive_v1_4f.png"

# -----------------------------------------------------------------------------
# PEDESTAL
# -----------------------------------------------------------------------------

PEDESTAL_SRC="district_transfer_pedestal_v1.png"

if [[ -f "$SOURCE_DIR/district_transfer_frame_pedestal_v1.png" ]]; then
	PEDESTAL_SRC="district_transfer_frame_pedestal_v1.png"
fi

resize_static \
	"$PEDESTAL_SRC" \
	64 96 \
	"district_transfer_pedestal_v1.png"

SCREEN_SRC="district_transfer_pedestal_screen_v1_4f.png"

if [[ -f "$SOURCE_DIR/district_transfer_frame_pedestal_screen_v1_4f.png" ]]; then
	SCREEN_SRC="district_transfer_frame_pedestal_screen_v1_4f.png"
fi

resize_grid_sheet \
	"$SCREEN_SRC" \
	2 2 \
	32 32 \
	"district_transfer_pedestal_screen_v1_4f.png"

# -----------------------------------------------------------------------------
# TRANSFER FRAME SUPPORT PROPS
# -----------------------------------------------------------------------------

resize_static \
	"district_transfer_route_plate_v1_96x32.png" \
	96 32 \
	"district_transfer_route_plate_v1.png"

resize_pair_sheet \
	"district_transfer_cable_feed_pair_v1_192x128.png" \
	96 128 \
	"district_transfer_cable_feed_pair_v1.png"

resize_static \
	"district_transfer_service_junction_v1_64x64.png" \
	64 64 \
	"district_transfer_service_junction_v1.png"

# -----------------------------------------------------------------------------
# CARROW MACHINE HOUSE
# -----------------------------------------------------------------------------

resize_static \
	"carrow_machine_house_entry_v1_192x128.png" \
	192 128 \
	"carrow_machine_house_entry_v1.png"

resize_static \
	"carrow_machine_house_relay_bank_v1_160x96.png" \
	160 96 \
	"carrow_machine_house_relay_bank_v1.png"

resize_static \
	"carrow_machine_house_switchgear_v1_128x96.png" \
	128 96 \
	"carrow_machine_house_switchgear_v1.png"

echo
echo "==============================================================="
echo " REVIEW PASS COMPLETE"
echo "==============================================================="
echo
echo "Normalized derivatives:"
echo "  $REVIEW_DIR"
echo
echo "Source masters were NOT modified."
