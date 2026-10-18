# Luna R3 execution: no algorithm design

1. Read latest canonical task packet on `origin/main`, verify same active worktree/branch `agent/operator-2-5d-ne-walk-retargeting`. The original R2 bundle files are already STAGED and unchanged; do not overwrite them. Never force-reset/rebase their state.
2. Verify the provided ZIP SHA256 against the packet; check `docs/R3_PACKAGE_MANIFEST.json` paths/digests before extraction. The ZIP contains only NEW R3 files, no existing R2 art or source overwrite. If any new file path already exists with different bytes, STOP. Extract at repository root.
3. Run EXACTLY: `bash custodian/tools/operator/ne_walk_retarget/run_silhouette_cleanup_r3.sh`.
4. If any SHA, semantic source, contact, topology, source-test or changed-file coverage gate fails: STOP, report the precise error to the authoring chat. Do not edit the R3 algorithm, relax limits or generate a different candidate.
5. On success, confirm exactly six files under `iter-008-boot-continuity-art-r3` Dropbox visual-review manifest. Optional commit/push only exact authored R2+R3 staging and proof summary to retained branch, `[skip render]`, without main merge. Report SHA, R3 bridge counts, final components and Dropbox manifest, then STOP.

This is preview-only. Human gait, raster art, asset promotion, FPS, runtime publication and landing are NOT approved.
