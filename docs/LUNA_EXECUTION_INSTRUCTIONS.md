# CUSTODIAN Operator NE silhouette cleanup r1: executor contract

**Workstream:** `operator-2-5d-ne-walk-retargeting`  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad06f67-3cb8-83ea-b34c-3ebf78a9e6fe

## Execute exactly, do not invent the cleanup

The user asked ChatGPT to author the art logic, and Codex/Luna to **execute the packaged code only**. Do not ask Luna to choose anatomical angles, cleanup masks, repaint pixels, alter gait curves, or introduce new animation decisions. The script is already written and tested on synthetic damage. Its exact per-frame join policy is in `SEAM_Y`.

1. Confirm the retained branch is `agent/operator-2-5d-ne-walk-retargeting` and that its worktree is clean. Use existing workstream identity; do not re-claim, merge, reset, or create duplicate packets.
2. Extract this ZIP *from repository root* after inspecting collisions (`unzip -l`); do not overwrite any existing file silently. The archive root contains `custodian/` and `docs/` directly. Relative paths point to `custodian/tools/operator/ne_walk_retarget/` and `custodian/asset_drop/source_work/operator/operator_ne_walk_cleanup_r1/`.
3. Verify expected local Iteration 004 inputs are present, untouched and have the SHA256 values embedded in `clean_silhouette_r1.py`:
    - `~/Downloads/operator_ne_master_audit_implementation_v1/iter_004_upper_body_followthrough/operator_ne_walk_v6_15f.png` (15-frame active, 1920x128)
    - sibling `report.json` (the matched 15-frame technical report)
4. Verify `python3` includes Pillow and NumPy. Install only into the project-approved Python environment if needed. Don't add new runtime dependencies.
5. Run **one command** from the repo root:

   ```bash
   bash custodian/tools/operator/ne_walk_retarget/run_silhouette_cleanup_r1.sh
   ```

6. This command automatically runs the authored synthetic smoke, validates all pinned image/report hashes, produces exactly one candidate with a per-frame difference report and three visual sheets, and uploads 6 curated files to the stable Dropbox workstream location. **No Aseprite, no runtime code, no new FPS, no script edits.**
7. If the command stops or hash-check fails: record the exact failure and stop. **Do not bypass source hashes with `--allow-active-sha`** (that flag exists for offline synthetic testing only). Do not tune per-frame joins or select other assets. Bring the mismatch back to this chat for a revised ChatGPT-authored script.
8. When successful, run the appropriate changed-file/asset-provenance checks required by the live repository's `AGENTS.md`. Commit the script and the four source-work reference files only if allowed by the active Asset Pipeline V2 contract and branch lifecycle; otherwise keep the ZIP as the traceable staging artifact and flag the next commit boundary for ChatGPT. Do not land to `main` or archive the workstream.
9. Report branch SHA, modified files, command exit status, synthetic test outcome, total changed pixels, **support-foot footprint warning frames**, and the exact manifest path. Then **STOP for human review**.

### Critical scope distinction

The script transplants pixels. It does **not** assert that boot contacts still coincide with the validated 15-frame IK report after the art changes. It reports a heuristic contact-footprint difference at each frame, with anything over 2px horizontal or 1px vertical marked unverified. Those are diagnostics, not authoritative IK tests. Mechanical/gait acceptance remains pending. Never describe this preview as runtime-ready or authoritative FPS.

### Asset Pipeline V2 handling

- Inputs remain source-work references at `custodian/asset_drop/source_work/operator/operator_ne_walk_cleanup_r1/`; **not** runtime assets.
- Input family: `operator_ne_authoring_reference`; `character=operator`; `direction=NE`; variants `alt_walk_10f`, `alt_walk_15f`, `style_lock_1f`, `idle_lock_15f`; cell 128x128; alpha RGBA binary; no authoritative FPS.
- One output: `operator_ne_walk_cleanup_candidate_15f_1920x128.png`, 15 frames, 128x128 per frame, 1920x128 horizontal, preview only. Output stays out of source_work and Asset V2 inbox until explicitly visually accepted, normalized, and promoted by the separate production-authoring process.
- Future normal inbox target, **only if approved**: `custodian/asset_drop/inbox/operator_ne_walk_cleanup/` with family schema resolved against live Operator authoring authority at that time; do not fabricate a new runtime family now.

### Future: idle jitter cleanup

Deferred separate slice within Operator NE animation family, not bundled into this walk correction. The `idle_lock_15f_source.png` is read-only during this slice.
