# Operator Motion Foundry South Rig Source-Work Integration V1

Workstream: `operator-motion-foundry-south-rig-sourcework-v1`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488

## Result

- Retrieved the packet's exact 197,858-byte Dropbox object by read-only `rclone` using file ID `id:8NXqdXuW6GUAAAAAAAAEfA`; its SHA-256 matched `ea039bbbf945da4172c61d43a61beea793bf92a0f807c73d363cd7877673bf94`.
- Verified all 41 archive members and all 40 payload hashes in `bundle_inventory.json`, then installed the original bundle byte-for-byte under `custodian/asset_drop/source_work/operator/motion_foundry/operator_south_visible_surface_v1/`.
- Preserved the CRLF pixel ledger through Git with one path-scoped `-text -diff !eol` rule in `custodian/.gitattributes`; its staged blob SHA-256 matches the pinned bundle inventory, and tests inspect the ledger contents.
- Added a repo-owned extractor entrypoint and registered `operator_south_rig_extract` smoke. It validates the immutable bundle inventory and launches the supplied seven-test suite.
- Seven tests passed: 2,440 visible source pixels have unique ownership, all 23 full-canvas layers preserve exact RGBA reconstruction, the generated one-frame Aseprite roundtrips exactly, the 15-frame proof stays static with null FPS, repeated extraction is deterministic, and changed source bytes fail closed.
- The bundle remains `source_work_only_unapproved_rig_candidate`. No runtime, canonical art, or Asset V2 inbox path changed. Human review of seams/hidden underpaint and MF1/MF2 acceptance remain deferred.

## Validation

- Bundled test script: 7/7 passed.
- Registered `run_validation.py --test operator_south_rig_extract --json`: passed.
- `git -c core.whitespace=cr-at-eol diff --cached --check`: passed; the source ledger's original CRLF bytes are intentionally preserved.
- After main sync, `run_validation.py --changed --base origin/main --json`: failed one unrelated `operator_unarmed_fast_chain_north_vfx_contract` test because fast-attack source pixels differ from inbox. The suite selected 41 tests: 16 passed, one failed, and 24 were skipped after that failure. The source-work test passed independently. The mismatch is outside this packet's Work surface and remains a follow-up for its owning workstream.
- Godot's first-import preflight generated 12 untracked `.import` sidecars in `custodian/tools/iteration/grunt_candidate_ab/generated/`; those exact validation-generated sidecars were removed from this isolated worktree. The generated `.godot` cache remains worktree-local.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: `The global changed-file validation stopped after an unrelated Operator source/inbox mismatch.`
- Root cause / contributing factors: `validation_manifest.json is a shared owner for many tests, so registering one smoke selected a broad suite.`
- Prevention / pipeline improvement: `Keep the source-work smoke independently selectable and route the unrelated mismatch to its existing owner.`
- Tooling / docs drift discovered: `The pinned source was a flat Dropbox ZIP, so the packet's exact read-only rclone route was required instead of the standard implementation-handoff manifest route.`
- Follow-up: `manual-follow-up`
- What worked: `The immutable remote file identity and exact member hashes made source intake reproducible.`

## Next Handoff

- Next workstream: `review-operator-motion-foundry-south-rig-sourcework-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Refresh reason: `none`
- Next action: `Run the fresh-context paired review against the landed source-work archive and its pinned source receipt.`
- Blockers or open questions: `The unrelated Operator source/inbox mismatch remains outside this workstream. The source-work rig is not art-approved or runtime-published.`
