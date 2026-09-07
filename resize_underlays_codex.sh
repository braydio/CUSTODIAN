#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./resize_awakening_underlays.sh /path/to/source_pngs /path/to/CUSTODIAN
#
# Expected source filenames:
#   creche_underlay_v1.png
#   ambulatory_underlay_v1.png
#   attestation_underlay_v1.png
#   locker_reliquary_underlay_v1.png
#   dust_lung_underlay_v1.png

SRC_DIR="${1:-.}"
REPO="${2:-$HOME/Projects/CUSTODIAN}"

OUT_DIR="${SRC_DIR}/corrected_awakening_underlays"
mkdir -p "$OUT_DIR"

command -v magick >/dev/null 2>&1 || {
  echo "ERROR: ImageMagick 'magick' command not found."
  echo "Arch: sudo pacman -S imagemagick"
  echo "Debian/Ubuntu: sudo apt install imagemagick"
  exit 1
}

resize_cover() {
  local src="$1"
  local dst="$2"
  local size="$3"

  echo "Processing: $(basename "$src") -> $size"

  magick "$src" \
    -auto-orient \
    -colorspace sRGB \
    -filter Lanczos \
    -resize "${size}^" \
    -gravity center \
    -extent "$size" \
    -background black \
    -alpha remove \
    -alpha off \
    -strip \
    "$dst"
}

resize_cover \
  "$SRC_DIR/creche_underlay_v1.png" \
  "$OUT_DIR/creche_underlay_v1.png" \
  "960x704"

resize_cover \
  "$SRC_DIR/ambulatory_underlay_v1.png" \
  "$OUT_DIR/ambulatory_underlay_v1.png" \
  "1152x960"

resize_cover \
  "$SRC_DIR/attestation_underlay_v1.png" \
  "$OUT_DIR/attestation_underlay_v1.png" \
  "832x928"

resize_cover \
  "$SRC_DIR/locker_reliquary_underlay_v1.png" \
  "$OUT_DIR/locker_reliquary_underlay_v1.png" \
  "704x704"

resize_cover \
  "$SRC_DIR/dust_lung_underlay_v1.png" \
  "$OUT_DIR/dust_lung_underlay_v1.png" \
  "1216x1216"

echo
echo "VERIFYING OUTPUTS"
echo "-----------------"

magick identify \
  "$OUT_DIR/creche_underlay_v1.png" \
  "$OUT_DIR/ambulatory_underlay_v1.png" \
  "$OUT_DIR/attestation_underlay_v1.png" \
  "$OUT_DIR/locker_reliquary_underlay_v1.png" \
  "$OUT_DIR/dust_lung_underlay_v1.png"

echo
echo "Copying exact-canvas inputs into Asset V2 inboxes..."

install -Dm644 \
  "$OUT_DIR/creche_underlay_v1.png" \
  "$REPO/custodian/asset_drop/inbox/awakening_creche_environment/underlay.png"

install -Dm644 \
  "$OUT_DIR/ambulatory_underlay_v1.png" \
  "$REPO/custodian/asset_drop/inbox/awakening_ambulatory_environment/underlay.png"

install -Dm644 \
  "$OUT_DIR/attestation_underlay_v1.png" \
  "$REPO/custodian/asset_drop/inbox/awakening_attestation_environment/underlay.png"

install -Dm644 \
  "$OUT_DIR/locker_reliquary_underlay_v1.png" \
  "$REPO/custodian/asset_drop/inbox/awakening_locker_reliquary_environment/underlay.png"

install -Dm644 \
  "$OUT_DIR/dust_lung_underlay_v1.png" \
  "$REPO/custodian/asset_drop/inbox/awakening_dust_lung_environment/underlay.png"

echo
echo "DONE."
echo
echo "Next:"
echo "  cd \"$REPO\""
echo "  python3 custodian/tools/assets/asset.py plan awakening_creche_environment"
echo "  python3 custodian/tools/assets/asset.py plan awakening_ambulatory_environment"
echo "  python3 custodian/tools/assets/asset.py plan awakening_attestation_environment"
echo "  python3 custodian/tools/assets/asset.py plan awakening_locker_reliquary_environment"
echo "  python3 custodian/tools/assets/asset.py plan awakening_dust_lung_environment"
