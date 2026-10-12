#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

echo "== PASS/FAIL canon acceptance gate =="
python3 custodian/tools/validation/reciprocal_continuity_canon_docs_smoke.py
echo "PASS: active Reciprocal Continuity canon and mutation controls"

echo
echo "== Diagnostic search output only (not an acceptance gate) =="
echo "These broad matches include valid historical, devotional, and negative references."

echo
echo "== Retired ontology mentions =="
rg -n -i \
  'unnarrival|bellfall|provenance wound|anti-arrival|anti arrival|cosmic provenance|provenance.*substrate|substrate.*provenance' \
  design custodian \
  --glob '!pre-design/**' \
  || true

echo
echo "== Non-Recipient references =="
rg -n -i \
  'non-recipient|non recipient' \
  design custodian \
  --glob '!pre-design/**' \
  || true

echo
echo "== Ash-Bell terminology =="
rg -n -i \
  'ash.?bell|unarrival|unarrived|ninth bell|ninth answer|open interval|ninth silence|orra|meridian office|station ix' \
  design custodian \
  --glob '!pre-design/**' \
  || true

echo
echo "== Runtime stale IDs =="
rg -n \
  'ash_bell_ninth_bell|ash_bell_bellfall_containment|TOOK_CLAPPER|RANG_SILENCE|has_clapper|TAKE BELL-CLAPPER|RING SILENCE' \
  custodian \
  || true

echo
echo "== Current cosmology indicators =="
rg -n -i \
  'reciprocal continuity|return-path|return path|continuity anomaly|continuity origin|adjacent continuity' \
  design custodian/docs \
  || true
