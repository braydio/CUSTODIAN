# Ash Bell Ritualant Music Integration

## Status

Implementation candidate on `agent/ash-bell-ritualant-score-live-v1`; not landed. The existing Eight Bells exploration loop and newly supplied Stilling Release resolution cue are wired in the authored Forlorn Ritualant Underground. The ZIP is preserved until full changed-file validation and the required human audible playtest are complete.

## Implemented

- Preserved the existing 48-bar Eight Bells exploration loop, its prior-playlist restore, and the global Causeway playlist semantics.
- Added `forlorn_ritualant_stilling_release_v1.ogg` to the runtime music directory and audio intake route. The runtime and intake copies match SHA-256 `ef547c4013a4cb7be23a898fdab7a463683e677959de5cd8999b405ea4761173`.
- Added `MusicManager.play_one_shot_track()`: it fades out the active score, plays one non-looping Vorbis stream through the existing player at -5.4 dB relative playback attenuation, then restores the captured track/playlist and volume.
- Wired the cue only to a fresh `encounter_completed(SITE_STABILIZED)` signal after the peaceful dialogue/dissolve sequence. Route-state restoration suppresses playback; hostile/defiled completion does not select the cue.
- On Underground departure, an active one-shot is cancelled and the previous zone playlist is restored only while the Underground still owns music. Another zone's music authority is preserved.
- Added a distinct fulfilled audio requirement for the one-shot without changing the still-needed Ash-Bell SFX/room-bed requirement.
- Extended `ash_bell_ritualant_music_smoke.gd` for one-shot loop policy, attenuation, completion restore, restore/hostility gates, exit cancellation, single-player ownership, and cross-zone handoff.
- Updated `CURRENT_STATE.md` and registered the expanded validation owners.

## Source and artifact facts

- ZIP: `~/Downloads/Stilling_Release_CUSTODIAN_Final_Audio_Pack_v1.zip`.
- Runtime artifact: stereo Vorbis, 48 kHz, 38.709646 seconds; no re-encoding or other audio processing was performed.
- The ZIP included three visual analysis images and `measurements.json`; those were inspected as supporting materials and were not copied into runtime content.
- The ZIP did not contain the WAV authoring master. The intake README records this explicitly; the supplied review notes that the original WAV is separately available.
- The ZIP is intentionally retained pending final closeout.

## Validation

- Archive path-safety and ZIP integrity: PASS.
- `ffprobe`: PASS, Vorbis / 48 kHz / stereo / 38.709646 seconds.
- Godot 4.7.2 headless editor import: PASS.
- `ash_bell_ritualant_music_smoke.gd`: PASS — loop, fresh one-shot, restore/hostile gates, -5.4 dB, exit restoration/cancellation, single player and authority handoff.
- `asset.py needs --write` / `--check`: PASS.
- Required-assets registry JSON parse and `git diff --check`: PASS.
- Broad changed-file validation and human in-game audible review: pending.

The earlier Eight Bells candidate's broad validation reported unrelated pre-existing Ritualant mapper/geometry assertions. They have not been treated as evidence for this new audio path; a fresh changed-file run is still needed against the now-synchronized `origin/main` before landing. Do not land if the required validation remains red. Headless checks cannot establish audible quality.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the new cue arrived while the existing score workstream was already published but not landed; repository import state was also missing the new OGG import cache on first smoke attempt.
- Root cause / contributing factors: the supplied deployment brief was delivered as a separate ZIP while the compatible Eight Bells integration remained in an unlanded workstream; the first smoke preceded Godot's normal import step.
- Prevention / pipeline improvement: resolve existing audio ownership before asset changes, preserve the active worktree, and run headless editor import before audio-resource smokes.
- Tooling / docs drift discovered: the Stilling Release archive omitted its WAV master even though the accompanying review note says the original WAV is separately available; the packaged OGG and its exact playback contract were sufficient for runtime wiring.
- Follow-up: manual-follow-up
- What worked: the single-player cue transition smoke directly verified the lifecycle and authority boundaries.

## Next Handoff

- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Refresh reason: none
- Next action: run the changed-file validation on the current branch, resolve only failures that belong to this audio work, land through `workstream.py finish` when validation is green, then request the required human audible playtest. Delete the ZIP only after the completed integration and validation no longer depend on it.
- Blockers or open questions: broad changed-file validation and in-game audition remain; the WAV authoring master was not present in the supplied ZIP.
