# operator north walk eight-frame recovery

Repaired the ignored unarmed/locomotion/walk_01/n Workbench contract on 2026-10-03. The saved edited Aseprite document contained eight 96x96 frames, while its manifest retained a pending eight-to-nine-frame migration from October 1. User confirmed the desired animation remains eight frames.

Backed up the manifest and edited document under the session backups/eight_frame_contract_recovery_20261003T033001 directory. Restored workspace/document clocks, both body-layer frame counts and timeline slots, and proposed publish paths to the existing eight-frame source contract. Cleared only the obsolete pending migration. Timing already had eight entries and was preserved. Updated layer input paths to the verified exports of the current edited document.

The actual Aseprite-backed publish dry run succeeded with mirroring disabled for north. Both layer exports are 768x96, containing all eight 96x96 cells. The edited Aseprite document is byte-identical before/after recovery (SHA256 a72009a4edb231b193e3d80256e8e24fb8c3ba01f76b29711eb8eb2e7b88f2d0), including its frame order and durations. No frames were inserted, removed, rebuilt, or replaced. Source contracts were checked non-stale before repair. A local recovery receipt accompanies the backups.

This repairs the local session and permits the user to publish from the Workbench; it does not publish the animation or change canonical art. Reopen the Workbench to reload the repaired manifest. Local ignored state does not propagate through Git; this committed summary records the repair and evidence.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: pending nine-frame migration metadata survived while the saved document returned to eight frames
- Root cause / contributing factors: manifest/document contract divergence; confirmation of the intended saved frame count was required
- Prevention / pipeline improvement: compare saved document frame count with the pending contract before publication and provide a targeted recovery explanation
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: backed-up metadata repair and real Aseprite export proved all saved frames are retained
