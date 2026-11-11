# Operator publish migration manifest

Recovered fast 1 E/W publication transaction 20261003T232031. Its six source
hashes matched the journal; six source/runtime RGBA pairs matched at 768x128
(six 128x128 frames), and the SpriteFrames hash matched. All 51 changed paths
belonged to the saved migration. No selected source conflicted with upstream.
Backed up all outputs, tracked diff, document, manifest, and journal under the
art checkout's ignored recovery/fast_one_completed_export_20261005 directory.
Committed and resumed the approved Operator landing route without re-exporting.
Publication landed as a0f56b7cf16d13a6ef40e9539915c8d7ccc3f3ed; the checkout
caught up with main. Saved Aseprite document and manifest remained byte identical.

The runtime manifest was missing from the publication allowlist. Canvas migration
regenerated it and left a validated publication uncommitted; retries then saw
preexisting changes. Added the exact canonical runtime manifest to the allowlist.
The full art checkout smoke now writes, stages, and lands that manifest, retaining
existing unexpected-output and coordination-checkout negative controls.

Validation: operator_art_worktree_smoke.py PASS; git diff --check PASS.
Moment Forge: not run — authoring/Git tooling only.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: validated canvas migration output could not commit
- Root cause / contributing factors: generated runtime manifest omitted from publication allowlist
- Prevention / pipeline improvement: exact path allowance and real fixture publication regression
- Tooling / docs drift discovered: output contract omitted a canonical generated artifact
- Follow-up: fixed-in-scope
