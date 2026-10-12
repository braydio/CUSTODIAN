# Eight Bells Ritualant Score Live V1

## Status

Implementation candidate on `agent/ash-bell-ritualant-score-live-v1`. Not landed: the changed-file validation sweep is not green because two existing Ritualant validation owners fail. Keep this branch attached for recovery. The supplied ZIP remains in Downloads because implementation closeout is not complete.

## Implemented

- Added the approved OGG to the audio inbox and runtime music path. Both copies match SHA-256 `4fcfd676ca77d9f36688edf87c92e6ad58da27b7141a7824f0ac49156796afc2`.
- Added `MusicManager.play_loop_track()` using a duplicated Vorbis stream with loop enabled. Existing sequential playlist playback still sets loop false.
- Bound cue start/restore to the authored `ForlornRitualantUnderground` lifecycle. Exit restores the previous playlist only if the Underground still owns the current cue.
- Added an independent fulfilled audio requirement; the existing `ash-bell-audio-cues` SFX/ambience requirement remains `needed`.
- Added a focused smoke for exact duration, looping, re-entry, playlist restoration, one music player, and another zone taking music authority; registered it in the validation manifest.
- Updated `CURRENT_STATE.md` to describe this as an unlanded candidate and record the remaining gates.

## Evidence

- Bundle SHA-256 checks: all six listed files passed.
- `ffprobe`: Vorbis, 48 kHz, stereo, 185.806271 seconds.
- Godot 4.7.2 editor import: completed.
- `ash_bell_ritualant_music_smoke.gd`: PASS, including re-entry, single-player and authority-handoff cases.
- `asset.py needs --write`, `asset.py needs --check`, and the new requirement query: PASS.
- JSON parsing and `git diff --check`: PASS.
- `run_validation.py --changed --base origin/main --json`: **FAIL**; 37 passed, 2 failed, 2 skipped, coverage complete. Failures: `forlorn_ritualant_mapper_semantics` (`chapel art bounds did not derive from texture size`) and `forlorn_ritualant_runtime` (lower-lift backstop/wing/boarding collision assertions). These files/assertions were not modified by this work. The run also emitted invalid texture UID fallback warnings from the existing Ritualant scene.
- Direct `ash_bell_scene_smoke.gd`: FAIL, Stilling Pin pickup state assertion.
- Direct `levels/forlorn_ritualant_underground_smoke.gd`: FAIL, lower-lift spawn placement and chapel outer-blend z assertions.
- Human in-game listening (entry, full 48-bar loop/seam, exit, re-entry, no double playback): pending. Headless checks cannot establish audible quality.

The unrelated route/state failures are preserved as owner follow-up; this work did not change encounter mechanics or lift geometry. Do not force a green validation report or land around these failures. Re-run the full changed-file sweep after their owning workstream has resolved the Ritualant validation contract, then finish this branch.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: medium
- What went wrong: the authored-level route validation selected by the changed-file sweep has pre-existing failures that prevent the required green closeout.
- Root cause / contributing factors: the score attaches to the authored Underground lifecycle, whose validation ownership also covers existing geometry and encounter contracts outside this music slice.
- Prevention / pipeline improvement: keep the focused score smoke registered and use the full changed-file report to surface cross-owner blockers before landing.
- Tooling / docs drift discovered: no task packet exists for this named workstream; the user-provided handoff brief is the task authority. Existing Ash-Bell scene texture UID fallbacks remain noisy in headless runs.
- Follow-up: manual-follow-up
- What worked: exact bundle hashes and the focused ownership/playlist smoke gave direct evidence for the new music contract.

## Next Handoff

- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Refresh reason: none
- Next action: route the existing Ritualant mapper/runtime validation failures to their owning workstream, then resume this branch, rerun changed-file validation, and land before requesting the human audible playtest.
- Blockers or open questions: `forlorn_ritualant_mapper_semantics` and `forlorn_ritualant_runtime` fail on existing geometry/encounter assertions; actual in-game listening is also required before the cue is accepted as live.
