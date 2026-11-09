#!/usr/bin/env bash
# CUSTODIAN Operator NE one-candidate ART-ONLY review, no runtime publishing.
set -euo pipefail

if [[ ! -f custodian/tools/iteration/publish_review_artifacts.py ]]; then
  echo 'ERROR: Run this command from the live braydio/CUSTODIAN repository root.' >&2; exit 2
fi

HERE='custodian/tools/operator/ne_walk_retarget'
REF='custodian/asset_drop/source_work/operator/operator_ne_walk_cleanup_r1'
RUN_ROOT="$HOME/Downloads/operator_ne_master_audit_implementation_v1"
ACTIVE="$RUN_ROOT/iter_004_upper_body_followthrough/operator_ne_walk_v6_15f.png"
REPORT="$RUN_ROOT/iter_004_upper_body_followthrough/report.json"
OUT="$RUN_ROOT/iter_006_silhouette_transplant_r1"
RUN_ID='iter-006-silhouette-transplant-r1'
CHAT='https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe'

[[ ! -e "$OUT" ]] || { echo "ERROR: refusing overwrite $OUT" >&2; exit 2; }
[[ -f "$ACTIVE" && -f "$REPORT" ]] || { echo 'ERROR: Iteration 004 locked source strip/report missing.' >&2; exit 2; }
python3 "$HERE/smoke_clean_silhouette_r1.py"
python3 "$HERE/clean_silhouette_r1.py" \
  --active "$ACTIVE" \
  --report "$REPORT" \
  --alternate "$REF/alternate_walk_15f_source.png" \
  --style "$REF/single_frame_style_source.png" \
  --idle "$REF/idle_lock_15f_source.png" \
  --output-dir "$OUT"

# Exactly 2 source-authenticated image payloads for the Dropbox text bridge.
python3 - "$OUT" <<'PY'
import base64,hashlib,json,sys
from pathlib import Path
from PIL import Image
p=Path(sys.argv[1]);imgs=[]
for name in ('BEFORE_AFTER_15_POSES.png','BEFORE_AFTER_10_POSES.png'):
 b=(p/name).read_bytes()
 with Image.open(p/name) as im:
  width,height=im.size
 imgs.append({'name':name,'sha256':hashlib.sha256(b).hexdigest(),
   'width':width,'height':height,'mime_type':'image/png',
   'data_uri':'data:image/png;base64,'+base64.b64encode(b).decode('ascii')})
bridge={'schema':'custodian.operator_ne_visual_bridge.v1',
 'source':'iter-006-silhouette-transplant-r1',
 'authoring_chat':'https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe',
 'art_acceptance':'pending','images':imgs}
(p/'REVIEW_PIXELS.json').write_text(json.dumps(bridge,separators=(',',':')))
assert (p/'REVIEW_PIXELS.json').stat().st_size < 5_000_000
for item in imgs:
 raw=base64.b64decode(item['data_uri'].split(',',1)[1],validate=True)
 assert hashlib.sha256(raw).hexdigest()==item['sha256']
print('Authenticated REVIEW_PIXELS.json ready')
PY

# Reuse the standard Dropbox review publisher: no asset ingestion or runtime.
# Temporary review art remains OUTSIDE the live repository.
python3 custodian/tools/iteration/publish_review_artifacts.py \
  --important \
  --workstream operator-2-5d-ne-walk-retargeting \
  --run-id "$RUN_ID" \
  --max-files 6 \
  --max-keyframes 0 \
  --source "$OUT" \
  --artifact "$OUT/operator_ne_walk_cleanup_candidate_15f_1920x128.png" \
  --artifact "$OUT/BEFORE_AFTER_15_POSES.png" \
  --artifact "$OUT/BEFORE_AFTER_10_POSES.png" \
  --artifact "$OUT/WAIST_JOIN_DIAGNOSTIC.png" \
  --artifact "$OUT/CLEANUP_REPORT.json" \
  --artifact "$OUT/REVIEW_PIXELS.json" \
  --authoring-chat "$CHAT" \
  --reason 'Human review of authored programmatic silhouette/apron/boot transplant from operator-native NE refs; exact contact revalidation pending.' \
  --question 'F05/F07/F12/F13 near-leg NE orientation and lower-body silhouette restored without new waist seams?' \
  --question 'Is the apron opening/compression credible across the 15 poses and F15→F01?' \
  --question 'Do the candidate sole-contact and support-foot placement diagnostics justify further pose fitting or rejection?'

echo 'STOP: preview submitted for human review. Do not merge, run Aseprite, select FPS or promote runtime art.'
echo '/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-006-silhouette-transplant-r1/REVIEW_MANIFEST.json'
