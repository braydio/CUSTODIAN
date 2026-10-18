#!/usr/bin/env bash
# Execute authored ChatGPT R2 exactly once; no design work delegated.
set -euo pipefail
[[ -f custodian/tools/iteration/publish_review_artifacts.py ]] || { echo 'ERROR repository root required' >&2; exit 2; }
TOOL=custodian/tools/operator/ne_walk_retarget
REF=custodian/asset_drop/source_work/operator/operator_ne_walk_cleanup_r1
RUN_ROOT="$HOME/Downloads/operator_ne_master_audit_implementation_v1"
BASE="$RUN_ROOT/iter_004_upper_body_followthrough"
RIG="$RUN_ROOT/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite"
OUT="$RUN_ROOT/iter_007_motion_anchored_art_r2"
CHAT='https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe'
[[ ! -e "$OUT" ]] || { echo "ERROR output already exists: $OUT" >&2; exit 2; }
# Verify every immutable included script/test/reference byte before execution.
python3 - <<'PYVERIFY'
from pathlib import Path
import hashlib,json
manifest=json.loads(Path('docs/R2_PACKAGE_MANIFEST.json').read_text())
assert manifest['schema']=='custodian.operator_ne_r2_package.v1'
for rel,digest in manifest['files'].items():
 p=Path(rel)
 assert p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest()==digest, 'bundle member mismatch: '+rel
print('PASS all authored R2 package member hashes')
PYVERIFY
[[ -f "$RIG" && -f "$BASE/operator_ne_walk_v6_15f.png" && -f "$BASE/report.json" ]] || { echo 'ERROR accepted source/rig/report missing' >&2; exit 2; }
python3 - "$RIG" "$BASE/operator_ne_walk_v6_15f.png" "$BASE/report.json" <<'PY'
from pathlib import Path
import hashlib,sys
values=('b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5','e06daea3f55b6bb8c2787b5874978a72644a7607f0eb37519c03828b3b61bb6a','88aa6469a76b986d0d3ccd2592dfed62903b5461ebe3e6e25c0fdb7f9519e83a')
for p,h in zip(sys.argv[1:],values):
 assert hashlib.sha256(Path(p).read_bytes()).hexdigest()==h, 'source lock mismatch '+p
print('PASS accepted rig, animation source and motion report SHA locks')
PY
python3 "$TOOL/smoke_clean_silhouette_r2.py" \
  --original-rig-fixture "$TOOL/fixtures/SINGLE_FRAME.aseprite" \
  --style-fixture "$REF/single_frame_style_source.png" \
  --alternate-fixture "$REF/alternate_walk_15f_source.png"
python3 "$TOOL/register_r2_validation.py"
python3 custodian/tools/validation/operator_ne_r2_reference_smoke.py
python3 "$TOOL/clean_silhouette_r2.py" \
  --active "$BASE/operator_ne_walk_v6_15f.png" \
  --rig "$RIG" --report "$BASE/report.json" \
  --alternate "$REF/alternate_walk_15f_source.png" \
  --style "$REF/single_frame_style_source.png" \
  --idle "$REF/idle_lock_15f_source.png" \
  --output-dir "$OUT"
# The source-work art output is review-only and must be checked as such.
python3 - "$OUT" <<'PY'
import json,sys,hashlib
from pathlib import Path
p=Path(sys.argv[1]);r=json.loads((p/'R2_MOTION_CONTACT_AUDIT.json').read_text())
assert len(r['frames'])==15 and r['status']=='REVIEW_ONLY'
assert all(f['support_sole_preserved'] and f['source_upper_68_rows_identical'] for f in r['frames'])
assert not r['animation_approved'] and not r['runtime_approved'] and r['fps'] is None
for n in ['operator_ne_walk_r2_motion_anchored_candidate_15f_1920x128.png','R2_BEFORE_AFTER_15_POSES.png','R2_BOOT_APRON_CLOSEUPS_10_POSES.png','R2_MOTION_CONTACT_AUDIT.json','REVIEW_PIXELS.json']:
 assert (p/n).is_file(),n
(p/'REVIEW_NOTES.md').write_text('# Iteration 007: motion-anchored art reconstruction R2\n\n'
  'Programmatically fitted semantic rig thigh/shin/boot/robe layers to unchanged 15-frame IK joint positions.\n'
  'Planted rendered sole raster restored from Iteration 004. Current art remains REVIEW ONLY: '
  'not declared correct in silhouette/temporal continuity, no runtime publication or FPS lock.\n'
  'Inspect F05/F07/F12/F13, boot silhouettes and 15→1; exact per-part contact diagnostic in JSON.\n')
print('PASS R2 preview boundary, 15 frames, explicit art not accepted')
PY
# Changed-file registry coverage (including previously uncovered docs reference manifest).
# Stage only the exact authored source-work and validation ownership changes.
# The user/executor must ensure the worktree is safely claimed first.
git add -- \
  "$TOOL/clean_silhouette_r2.py" \
  "$TOOL/smoke_clean_silhouette_r2.py" \
  "$TOOL/register_r2_validation.py" \
  "$TOOL/run_silhouette_cleanup_r2.sh" \
  "$TOOL/fixtures/SINGLE_FRAME.aseprite" \
  custodian/tools/validation/operator_ne_r2_reference_smoke.py \
  custodian/tools/validation/validation_manifest.json \
  "$REF/alternate_walk_10f_source.png" \
  "$REF/alternate_walk_15f_source.png" \
  "$REF/single_frame_style_source.png" \
  "$REF/idle_lock_15f_source.png" \
  docs/REFERENCE_MANIFEST.json docs/R2_AUTHORING_SPEC.md docs/R2_EXECUTION.md docs/R2_PACKAGE_MANIFEST.json
python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json
# Prevent publishing if this invocation reports incomplete coverage or failures:
# local validation tool exits nonzero on an uncovered owner in current repo.
git diff --check
python3 custodian/tools/iteration/publish_review_artifacts.py \
  --important --workstream operator-2-5d-ne-walk-retargeting \
  --run-id iter-007-motion-anchored-art-r2 --max-files 6 --max-keyframes 0 \
  --source "$OUT" \
  --artifact "$OUT/operator_ne_walk_r2_motion_anchored_candidate_15f_1920x128.png" \
  --artifact "$OUT/R2_BEFORE_AFTER_15_POSES.png" \
  --artifact "$OUT/R2_BOOT_APRON_CLOSEUPS_10_POSES.png" \
  --artifact "$OUT/R2_MOTION_CONTACT_AUDIT.json" \
  --artifact "$OUT/REVIEW_PIXELS.json" \
  --artifact "$OUT/REVIEW_NOTES.md" \
  --authoring-chat "$CHAT" \
  --reason 'Motion-anchored NE semantic leg and apron clean-contour candidate R2, human art review mandatory.' \
  --question 'Does the planted-sole-locked near-leg art follow the accepted F05/F12/F13 pose without mangling?' \
  --question 'Do robe contours and both leg joints stay continuous during crossover F06/07 and F13/14?' \
  --question 'Does the F15/F01 silhouette close and is native NE facing improved without eastward leg drift?'
echo 'STOP. Hand off published Dropbox manifest. No art acceptance, further edits, FPS or runtime publication.'
