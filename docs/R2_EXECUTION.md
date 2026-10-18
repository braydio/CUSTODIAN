# Luna execution-only handoff: Iteration 007 R2

1. Read latest canonical `origin/main` Operator NE task packet. Keep existing retained branch/worktree; no new workstream. Verify all files from the ZIP match the bundle manifest before staging. Do not edit Python code or artistic parameters.
2. In `braydio/CUSTODIAN` repository root, extract the ZIP without overwriting any pre-existing differing file; original R1 files remain intact. Exact intended new files are `clean_silhouette_r2.py`, `smoke_clean_silhouette_r2.py`, `register_r2_validation.py`, `run_silhouette_cleanup_r2.sh`, `fixtures/SINGLE_FRAME.aseprite`, the validation smoke, and docs/R2*.md. Four source-work PNGs and `docs/REFERENCE_MANIFEST.json` are included unchanged for provenance; skip identical files and STOP if any differs.
3. The single command (from repo root) is:

   ```bash
   bash custodian/tools/operator/ne_walk_retarget/run_silhouette_cleanup_r2.sh
   ```

4. The runner SHA-verifies **exact existing** Iteration 004 strip/report and approved recovery rig, runs synthetic smoke and source-manifest smoke, registers missing `docs/REFERENCE_MANIFEST.json` focused test owner, runs the authored R2, requires 15-frame motion/sole report boundaries and changed-file validation including coverage, stages the prescribed paths, then publishes exactly 6 review files to Dropbox. It never runs Aseprite or writes runtime art.
5. If any SHA, semantic rig part, anatomical joint-distance check, source requirement, changed-file coverage or publisher check fails, STOP. Do not tune R2 yourself or bypass failures. Return exact trace, current SHA, specific frame, and which input/guard failed; no output acceptance claim.
6. Otherwise return one succinct result: git checkpoint, focused/changed-file validation, R2 candidate SHA, contact/art diagnostics, Dropbox `/CUSTODIAN/visual_review/operator-2-5d-ne-walk-retargeting/iter-007-motion-anchored-art-r2/REVIEW_MANIFEST.json`. Then STOP for human review in the authoring chat.
7. This run does not authorize a merge, packet archive, runtime promotion, or frame timing.
