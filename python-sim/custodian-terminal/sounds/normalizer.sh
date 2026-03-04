
#!/usr/bin/env bash
set -euo pipefail

# ==========================
# CUSTODIAN: UI Alert Cleaner
# Extracts ONE pulse from a multi-beep recording and makes it UI-safe.
#
# Input:  soft-alert.mp3
# Output: alert_ui_final.mp3 (+ optional spectrogram)
# ==========================

IN="${1:-soft-alert.mp3}"
OUT="${2:-alert_ui_final.mp3}"

# ---- Pulse selection (picked from your spectrogram) ----
# This window targets the isolated pulse around ~17.6s.
# If you need to move it slightly, adjust START/END by ±0.05.
START="17.56"
END="17.76"

# ---- Tuning knobs (safe defaults for terminal/UI) ----
HP="300"     # highpass cutoff (Hz) - remove rumble
LP="4500"    # lowpass cutoff  (Hz) - remove hiss/fatigue

# Compressor: gentle control, not squashing
COMP="acompressor=threshold=-20dB:ratio=2.5:attack=5:release=70:makeup=2"

# Envelope: remove click + kill tail
FADE_IN="0.010"
FADE_OUT_START="0.140"
FADE_OUT_DUR="0.050"

# Loudness target: UI-friendly
LN="loudnorm=I=-20:TP=-2:LRA=5"

# Output encoding
AR="44100"
BR="96k"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

raw="$tmpdir/raw.wav"
band="$tmpdir/band.wav"
comp="$tmpdir/comp.wav"
env="$tmpdir/env.wav"
norm="$tmpdir/norm.wav"

echo "Input:  $IN"
echo "Pulse:  ${START}s to ${END}s"
echo "Output: $OUT"
echo

# 1) Extract pulse
ffmpeg -hide_banner -y -i "$IN" \
  -af "atrim=start=${START}:end=${END},asetpts=PTS-STARTPTS" \
  "$raw"

# 2) Band-limit (remove rumble + hiss)
ffmpeg -hide_banner -y -i "$raw" \
  -af "hi
