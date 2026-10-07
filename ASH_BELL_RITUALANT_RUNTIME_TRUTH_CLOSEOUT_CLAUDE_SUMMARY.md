# Ash-Bell Ritualant Runtime Truth Closeout

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c

## Result

- Removed the passive 4.5-second anchored-Fountain stabilization path. Fountain warnings, linger dialogue, and silence pressure remain; the explicit Set Stilling Pin path remains the peaceful-resolution authority.
- Added a negative control that holds the Knot-bearing player in an anchored Fountain for a synthetic five-second process tick, checks that resolution does not change, and checks that pressure and warning dialogue still run. Existing explicit-resolution positive coverage remains.
- Renamed the shared idle/kneel strip identity from 7f to 8f across the archive manifest, source/import identity, normalized and runtime outputs, and builder references. The four canonical strips retain identical SHA-256 `8aabde797481b7de1f56217c2c26345efc6bf9dff293965182ef0660462e9574` and are 1024×128 (eight 128×128 frames). The generated SpriteFrames now checks as eight frames, 5 FPS, looping, shared artwork.
- Updated `CURRENT_STATE.md` with the corrected runtime and asset contract.

## Validation

- Passed: `build_forlorn_ritualant_spriteframes.py --check`.
- Passed: Asset Pipeline V2 and V2.1 production smoke suites.
- Passed: narrowed encounter smoke covering the full Ritualant runtime without its unrelated lower-lift checks, including the new passive-dwell negative control and existing Stilling Pin positive path.
- Failed: official `forlorn_ritualant_completion_smoke.gd` reports five lower-lift backstop/wing/boarding-geometry assertions.
- Failed: `forlorn_ritualant_underground_smoke.gd` reports the descent landing/lower lift and chapel blend z-authority assertions.
- Failed: changed-file validation reports the mapper semantics chapel art-bounds assertion, plus the completion smoke's lower-lift assertions. No failures were reported in the new encounter or asset contract assertions.
- `git diff --check` passed. Godot import completed successfully. Invalid UID path-fallback warnings remain on existing Ritualant scene resources.

These route/scene failures concern unchanged files and are outside this packet's explicit non-goals. The required validation set is not green, so this implementation is checkpointed and not marked complete, archived, or landed. Resume this workstream after the owning validation/scene issues are reconciled or the packet's required validation is refreshed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: required focused validation is blocked by unrelated lower-lift and chapel/Underground scene assertions.
- Root cause / contributing factors: route/scene validation assertions do not match the authored geometry currently loaded; the SpriteFrames owner builder also exposed generated-resource formatting drift during regeneration.
- Prevention / pipeline improvement: split lower-lift assertions out of the focused Ritualant smoke and repair the Underground/mapper validation contracts in their owning scope before rerunning closeout.
- Tooling / docs drift discovered: runtime still had a hidden timer that active design and CURRENT_STATE said was absent; generated SpriteFrames had drifted from canonical builder output.
- Follow-up: manual-follow-up
- What worked: focused runtime and asset pipeline checks isolated the requested contract changes.

## Next Handoff

- Next workstream: ash-bell-ritualant-runtime-truth-closeout
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Refresh reason: none
- Next action: resolve or explicitly disposition the stale lower-lift, Underground, and chapel-bounds validation failures, then rerun the packet's required validation and finish this workstream.
- Blockers or open questions: validation report remains red; paired review and downstream production-art handoff cannot begin until this workstream lands.
