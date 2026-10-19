#!/usr/bin/env bash
# Authored reproducible local preview only. Git commit and Dropbox upload follow gates.
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
python3 custodian/tools/validation/operator_ne_skin_v2_smoke.py
python3 custodian/tools/operator/ne_walk_retarget/skin_v2/register_validation.py
python3 custodian/tools/operator/ne_walk_retarget/skin_v2/run.py \
  --donor-bundle "$HOME/Downloads/operator_ne_master_audit_implementation_v1/authoritative_ne_donor_v1" \
  --rig "$HOME/Downloads/operator_ne_master_audit_implementation_v1/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite" \
  --baseline "$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_004_upper_body_followthrough/operator_ne_walk_v6_15f.png" \
  --source-aseprite "$HOME/Downloads/SINGLE_FRAME.aseprite" \
  --output "$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_010_skin_v2_articulation_apron_proof"
printf '%s\n' 'Skin V2 preview generated. Stage exact authored files, run changed-file test, checkpoint, then publish using CODEX_IMPLEMENTATION.md; no automatic continuation.'
