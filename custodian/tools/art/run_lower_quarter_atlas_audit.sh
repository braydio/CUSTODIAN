#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/braydenchaffee/Projects/CUSTODIAN/custodian"
PY="$ROOT/tools/art/audit_tile_atlas.py"

PROPS="$ROOT/asset_drop/source_work/meridian_civic_props/meridian_civic_props_atlas.png"
WALL="$ROOT/asset_drop/source_work/meridian_civic_wall/meridian_civic_wall_atlas.png"

if [[ ! -f "$PROPS" ]]; then
  echo "Missing props atlas: $PROPS" >&2
  exit 1
fi

if [[ ! -f "$WALL" ]]; then
  echo "Missing wall atlas: $WALL" >&2
  exit 1
fi

echo
echo "============================================================"
echo "AUDIT: meridian_civic_props_atlas"
echo "============================================================"
python3 "$PY" "$PROPS" \
  --cell 32 \
  --flood-threshold 30 \
  --halo-threshold 48

echo
echo "============================================================"
echo "AUDIT: meridian_civic_wall_atlas"
echo "============================================================"
python3 "$PY" "$WALL" \
  --cell 32 \
  --flood-threshold 30 \
  --halo-threshold 48

echo
echo "DONE."
