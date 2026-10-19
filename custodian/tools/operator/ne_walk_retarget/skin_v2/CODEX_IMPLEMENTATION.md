# CUSTODIAN Operator NE Skin V2 | Iteration 010 execution-only task

Workstream: `operator-2-5d-ne-walk-retargeting`.
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe
Branch: existing retained `agent/operator-2-5d-ne-walk-retargeting`, starting checkpoint `bfdee84b7a50fec81b67f4ceff07828289ff7a03`, no duplicate checkout/worktree.

1. Fetch `origin/main`. Read the current canonical active packet and Skin V2 authorization. The complete, exact ChatGPT-authored source archive is checked into `main` as base64. Verify its pinned SHA before decoding. **Do not hand-implement or retune** the algorithm.
2. Inspect the new-only contents. Verify each member SHA against `skin_v2/SKIN_V2_PACKAGE_MANIFEST.json` inside the ZIP. Every file belongs at exactly its stated relative repo path. Reject collisions instead of overwriting. Do not copy the separate `docs/` R1 untracked files or `.gd.uid` artifacts.
3. From the same retained branch/worktree, extract only these new paths:
   - `custodian/tools/operator/ne_walk_retarget/skin_v2/apron_authority.py`
   - `custodian/tools/operator/ne_walk_retarget/skin_v2/run.py`
   - `custodian/tools/operator/ne_walk_retarget/skin_v2/register_validation.py`
   - `custodian/tools/operator/ne_walk_retarget/skin_v2/run_skin_v2.sh`
   - `custodian/tools/operator/ne_walk_retarget/skin_v2/README.md`
   - `custodian/tools/operator/ne_walk_retarget/skin_v2/CODEX_IMPLEMENTATION.md`
   - `custodian/tools/operator/ne_walk_retarget/skin_v2/SKIN_V2_PACKAGE_MANIFEST.json`
   - `custodian/tools/validation/operator_ne_skin_v2_smoke.py`
4. Execute:

```bash
python3 custodian/tools/validation/operator_ne_skin_v2_smoke.py
python3 custodian/tools/operator/ne_walk_retarget/skin_v2/register_validation.py
python3 custodian/tools/operator/ne_walk_retarget/skin_v2/run.py \
  --donor-bundle "$HOME/Downloads/operator_ne_master_audit_implementation_v1/authoritative_ne_donor_v1" \
  --rig "$HOME/Downloads/operator_ne_master_audit_implementation_v1/anatomy_recovery_verified/operator_ne_rig_ANATOMY_RECOVERY_CANDIDATE.aseprite" \
  --baseline "$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_004_upper_body_followthrough/operator_ne_walk_v6_15f.png" \
  --source-aseprite "$HOME/Downloads/SINGLE_FRAME.aseprite" \
  --output "$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_010_skin_v2_articulation_apron_proof"
```

5. Missing reference or hash, test, region/cel/neutral mismatch, incomplete 7-file output, or apron support/alpha/palette deviation: **STOP**, report exact evidence without editing my code, changing limits, or finding a substitute image. No new reference is required for this stage.
6. Stage ONLY eight authored tool/validation paths above and the scoped `validation_manifest.json` change. Run `git diff --cached --check`, `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --test operator_ne_skin_v2_apron --json`; check selected PASS with complete coverage for these exact paths. Treat unrelated `origin/main` drift as recorded, not license for a 320-test unfiltered sweep.
7. Commit/push a single `[skip render]` checkpoint on the existing retained branch. Publish only seven output artifacts under `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-010-skin-v2-articulation-apron-proof/REVIEW_MANIFEST.json` with the existing `publish_review_artifacts.py` and arguments shown below. Check remote manifest's 7 SHA values against the files. No source/artwork is imported through Asset V2.

```bash
python3 custodian/tools/iteration/publish_review_artifacts.py \
  --important \
  --reason 'authentic Skin V2 ownership and apron pose art proof' \
  --workstream operator-2-5d-ne-walk-retargeting \
  --run-id iter-010-skin-v2-articulation-apron-proof \
  --authoring-chat 'https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe' \
  --source "$HOME/Downloads/operator_ne_master_audit_implementation_v1/iter_010_skin_v2_articulation_apron_proof" \
  --max-files 7 --max-keyframes 0 \
  --question 'F05 and F07 crossover: improved garment depth or still hiding far boot?' \
  --question 'F12 near-leg stride: does the opened apron look credible?' \
  --question 'Which red alpha gaps require newly authored hidden cloth backing?' \
  --question 'Does the upper-body ownership audit support next separate pivots?'
```

**STOP.** No new or duplicate worktree, no 15-frame animation, autonomous frame corrections, hidden surface painting, main merge, runtime publication, FPS decision, workstream archive or R4 restart. Human reviews real Dropbox pixels first.
