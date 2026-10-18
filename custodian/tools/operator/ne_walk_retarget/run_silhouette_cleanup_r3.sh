#!/usr/bin/env bash
# ONE-CANDIDATE R3; exact ChatGPT-authored source, no Codex-design changes.
set -euo pipefail
[[ -f custodian/tools/iteration/publish_review_artifacts.py ]] || { echo 'ERROR run at repository root' >&2; exit 2; }
TOOL=custodian/tools/operator/ne_walk_retarget
REF=custodian/asset_drop/source_work/operator/operator_ne_walk_cleanup_r1
ROOT="$HOME/Downloads/operator_ne_master_audit_implementation_v1"
BASE="$ROOT/iter_004_upper_body_followthrough"
RIG="$ROOT/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite"
R2="$ROOT/iter_007_motion_anchored_art_r2/operator_ne_walk_r2_motion_anchored_candidate_15f_1920x128.png"
OUT="$ROOT/iter_008_boot_continuity_art_r3"
CHAT='https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe'
[[ ! -e "$OUT" ]] || { echo "ERROR output exists, refusing overwrite: $OUT" >&2; exit 2; }
python3 - <<'PYVERIFY'
import hashlib,json
from pathlib import Path
for manifest_name in ['docs/R2_PACKAGE_MANIFEST.json','docs/R3_PACKAGE_MANIFEST.json']:
    m=json.loads(Path(manifest_name).read_text())
    for name,digest in m['files'].items():
        p=Path(name)
        assert p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest()==digest, f'{manifest_name}: missing/drifted {name}'
print('PASS R2+R3 authored member hashes')
PYVERIFY
python3 - "$RIG" "$BASE/operator_ne_walk_v6_15f.png" "$BASE/report.json" "$R2" <<'PYVERIFY'
import hashlib,sys
from pathlib import Path
for path,digest in zip(sys.argv[1:],[
 'b7002e66df5928a53d4a42e7b74e7bdf82f6ef8006a2bed11a8dcdae815a0ff5',
 'e06daea3f55b6bb8c2787b5874978a72644a7607f0eb37519c03828b3b61bb6a',
 '88aa6469a76b986d0d3ccd2592dfed62903b5461ebe3e6e25c0fdb7f9519e83a',
 '51e196c0a6b7dd34a9eb53557ff52528e3ef4cc7bd84b3fab6df8b8cdbc95047']):
  p=Path(path); assert p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest()==digest,f'locked input changed {p}'
print('PASS accepted rig, Iteration 004 active/report, reproduced published R2 candidate')
PYVERIFY
python3 "$TOOL/smoke_clean_silhouette_r3.py" \
 --original-rig-fixture "$TOOL/fixtures/SINGLE_FRAME.aseprite" \
 --style-fixture "$REF/single_frame_style_source.png" \
 --alternate-fixture "$REF/alternate_walk_15f_source.png"
python3 "$TOOL/register_r3_validation.py"
python3 custodian/tools/validation/operator_ne_r3_topology_smoke.py
python3 "$TOOL/clean_silhouette_r3.py" \
  --active "$BASE/operator_ne_walk_v6_15f.png" \
  --rig "$RIG" --report "$BASE/report.json" \
  --alternate "$REF/alternate_walk_15f_source.png" \
  --style "$REF/single_frame_style_source.png" \
  --idle "$REF/idle_lock_15f_source.png" \
  --r2-candidate "$R2" --output-dir "$OUT"
python3 - "$OUT" <<'PYREVIEW'
import json,sys,hashlib
from pathlib import Path
p=Path(sys.argv[1]);a=json.loads((p/'R3_TOPOLOGY_AUDIT.json').read_text())
assert a['status']=='REVIEW_ONLY' and not a['animation_approved'] and not a['runtime_approved'] and a['fps'] is None
assert len(a['frames'])==15 and a['output']['frames']==15
assert all(f['support_connected_after'] and f['final_distal_orphan_count']==0 for f in a['frames'])
(p/'REVIEW_NOTES.md').write_text('# Iteration 008, R3 boot continuity preview\n\n'
 'Locked Iteration 004 IK motion and rig remain untouched. The R2 candidate was reconstructed and SHA verified. '
 'This R3 pass makes only bounded semantic-boot palette connections and records actual final-raster connected components. '
 'No runtime art/animation/FPS approved.\n\n'
 'Review F05 F06/F07, F12 F13/F14, F15/F01. Inspect the R3_TOPOLOGY_AUDIT.json bridge pixel counts and island decisions. '
 'A successful synthetic test is not proof of final character art.\n')
print('PASS all 15 R3 topology audit items, still REVIEW ONLY')
PYREVIEW
# Stage newly authored source/test/docs, plus already-staged R2 from previous approved run.
git add -- "$TOOL/clean_silhouette_r3.py" "$TOOL/smoke_clean_silhouette_r3.py" \
 "$TOOL/register_r3_validation.py" "$TOOL/run_silhouette_cleanup_r3.sh" \
 custodian/tools/validation/operator_ne_r3_topology_smoke.py \
 custodian/tools/validation/validation_manifest.json \
 docs/R3_AUTHORING_SPEC.md docs/R3_EXECUTION.md docs/R3_PACKAGE_MANIFEST.json
python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json
# Also check the index: these new files are staged and must not evade diff --check.
git diff --check
git diff --cached --check
python3 custodian/tools/iteration/publish_review_artifacts.py \
 --important --workstream operator-2-5d-ne-walk-retargeting \
 --run-id iter-008-boot-continuity-art-r3 --max-files 6 --max-keyframes 0 \
 --source "$OUT" \
 --artifact "$OUT/operator_ne_walk_r3_connected_candidate_15f_1920x128.png" \
 --artifact "$OUT/R3_R2_BEFORE_AFTER_15_POSES.png" \
 --artifact "$OUT/R3_BOOT_SOLE_CLOSEUPS_10_POSES.png" \
 --artifact "$OUT/R3_TOPOLOGY_AUDIT.json" \
 --artifact "$OUT/REVIEW_PIXELS.json" \
 --artifact "$OUT/REVIEW_NOTES.md" \
 --authoring-chat "$CHAT" \
 --reason 'Bounded semantic boot/sole and final-composite component connectivity R3; moving gait unchanged; mandatory art review.' \
 --question 'Is F07 detached distal sole resolved without invented leg anatomy or new orphan fragments?' \
 --question 'Does the planted sole join cleanly in F05 F12 F13, and are apron silhouettes unchanged outside repair?' \
 --question 'Is F15/F01 still credible, with exact original gait and no visual sole pop?'
echo 'STOP: report manifest and validation, checkpoint retained branch only after review handoff. No more art modifications.'
