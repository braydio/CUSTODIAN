#!/usr/bin/env bash
set -euo pipefail

# ==========================
# CUSTODIAN — UI ALERT PROCESSOR
# Applies identical UI-safe processing to multiple pulse files.
# ==========================

INPUTS=(
  "alert_pulse.wav"
  "alert_pulse_2.wav"
)

# ---- Processing parameters (locked) ----
HP="300"  # High-pass cutoff (Hz)
LP="4500" # Low-pass cutoff  (Hz)

COMP="acompressor=threshold=-20dB:ratio=2.5:attack=5:release=70:makeup=2"

FADE_IN="0.010"
FADE_OUT_START="0.140"
FADE_OUT_DUR="0.050"

LOUDNORM="loudnorm=I=-20:TP=-2:LRA=5"

AR="44100"
BR="96k"

for IN in "${INPUTS[@]}"; do
  if [[ ! -f "$IN" ]]; then
    echo "❌ Missing input: $IN"
    exit 1
  fi

  BASENAME="${IN%.*}"
  OUT="${BASENAME}_ui.mp3"

  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT

  echo "▶ Processing $IN → $OUT"

  # 1) Band-limit
  ffmpeg -hide_banner -y -i "$IN" \
    -af "highpass=f=${HP},lowpass=f=${LP}" \
    "$TMPDIR/band.wav"

  # 2) Gentle compression
  ffmpeg -hide_banner -y -i "$TMPDIR/band.wav" \
    -af "$COMP" \
    "$TMPDIR/comp.wav"

  # 3) Envelope shaping
  ffmpeg -hide_banner -y -i "$TMPDIR/comp.wav" \
    -af "afade=t=in:d=${FADE_IN},afade=t=out:st=${FADE_OUT_START}:d=${FADE_OUT_DUR}" \
    "$TMPDIR/env.wav"

  # 4) Loudness normalize
  ffmpeg -hide_banner -y -i "$TMPDIR/env.wav" \
    -af "$LOUDNORM" \
    "$TMPDIR/norm.wav"

  # 5) Final export (mono, UI-safe)
  ffmpeg -hide_banner -y -i "$TMPDIR/norm.wav" \
    -ac 1 -ar "$AR" -c:a mp3 -b:a "$BR" \
    "$OUT"

  # Optional spectrogram (for verification)
  ffmpeg -hide_banner -y -i "$OUT" \
    -lavfi "showspectrumpic=s=1024x512:legend=1:fscale=log" \
    "${BASENAME}_ui_spec.png" >/dev/null 2>&1 || true

  echo "✅ Wrote $OUT"
done

echo
echo "All pulses processed with identical UI profile."
