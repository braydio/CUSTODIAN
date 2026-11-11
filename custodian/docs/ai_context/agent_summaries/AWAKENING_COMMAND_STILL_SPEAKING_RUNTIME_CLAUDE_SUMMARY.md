Workstream: `awakening-command-still-speaking-runtime`

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9bc56-9e1c-83ea-8ff9-285be4092acb

## Result

Integrated the user-approved “A Command Still Speaking” score into the production Awakening scene through a dedicated `AwakeningMusicDirector` and the existing two-deck `/root/MusicManager`. The source master is unchanged and was encoded to Ogg Vorbis quality 8 at 48 kHz stereo. The scene claims one instance-specific scoped lease, starts the cue once at -2.5 dB runtime gain, and keeps it through sections 01–10, including the optional Chapel.

A successful Awakening-to-Hub commit asks the source scene to release its scoped lease with an 0.8-second fade and no playlist restoration; the Hub is left silent. Failed handoff leaves the Awakening owner and cue intact. Ordinary scene teardown retains the manager's existing snapshot restoration. The optional no-restore policy preserves the default release behavior for Ritualant and other existing owners; repeated release during a fade is idempotent, and successor playlist/scoped ownership is protected from stale completion callbacks.

The local source was `/home/braydenchaffee/Downloads/Awakening_01_Command_Still_Speaking.wav`, SHA-256 `36eb550377adf738f009b29565c9ec8bad7eb8ac9216b0bc9145f400639a2e6f`. It is 120.000 seconds, stereo 48 kHz 24-bit PCM, measured at -17.3 LUFS, -6.8 dBTP, and -6.77 dBFS sample peak. The runtime OGG is `custodian/content/audio/music/awakening/awakening_01_command_still_speaking.ogg`, SHA-256 `fa7c8799efa5e91c171d908658a34f6818e682ed1fe37e537aaf12459c867bf4`, 2,350,207 bytes. It decodes to 120.000 seconds, stereo 48 kHz, measures -17.3 LUFS/-6.8 dBTP, and has no clipping. No normalization or other mix processing was applied. Decoded OGG endpoint-to-start sample deltas are 0.0008223/0.0007382 per channel; seam audibility still needs in-game listening.

The dedicated provenance record is `custodian/content/audio/music/awakening/audio_handoff_manifest.json`. The active score contract is `design/02_features/audio/AWAKENING_FIRST_RETURN_SCORE_INTEGRATION.md`; the required-audio registry and generated asset view are current. User artistic approval, technical integration, and listening approval are tracked separately.

## Validation

- `awakening_music_smoke`: passed; resource load/duration, looping on the active manager stream, two-deck ownership, all ten section transitions, console acknowledgement, successful no-restore release, failed-handoff retention, default restoration, idempotent release, and successor playlist/scoped ownership.
- `awakening_first_return`: passed.
- `world_transition_handoff`: passed with an end-to-end production-scene assertion that rollback retains the cue and successful Hub commit fades/releases it without restoring Return Causeway.
- `ritualant_four_cue_music`: passed; existing scoped cue behavior remains green.
- `run_validation.py --changed --base origin/main --json`: passed 35/35, no timeouts/skips/failures, complete changed-file coverage. Report: `/tmp/custodian-awakening-after-sync-validation.json` (merged-tree validation: 35/35).
- `asset.py needs --check`, `asset_requirements_smoke.py`, `check_ai_context.py`, and `git diff --check`: passed.
- Graphical project boot: Godot 4.7.2 rendered with Vulkan on NVIDIA GeForce GTX 1650 SUPER and exited after 180 iterations without errors. This confirms graphical startup; audio output was not observed/listened to.

## Preserved validation evidence

The twelve capture-free Awakening Moment Forge traversal runs produced 144 ignored report files (1063696 uncompressed bytes). They are preserved in the tracked repository archive `custodian/docs/ai_context/validation_evidence/awakening_command_still_speaking_moment_forge_20261105.tar.gz`; SHA-256: `093afb8503e802245f8e471de1de5d0ef320b37c46f7a462dd6eb116a9dc6c86`.

## Independent review

An independent code review identified that the first smoke invoked the success hook directly and did not prove the real transition manager called it. The handoff smoke now covers the actual successful Hub transition and failed rollback, and both the focused test and full changed-file gate pass. The reviewer rechecked the correction and reported no remaining findings.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: the new isolated checkout initially lacked a Godot import cache; the first editor import crashed, and a retry surfaced the host's editor update-check TLS error. The first changed-file run was launched with uncommitted Awakening source, so the collision mapper correctly refused a source-derived draft and dependent Moment tests were skipped. A post-commit run without an explicit base selected zero tests.
- Root cause / contributing factors: this validation gate needs a populated project import cache, a quiet editor network profile, and `--base origin/main` to include committed work in a clean checkout. The collision mapper intentionally requires its source to match HEAD.
- Prevention / pipeline improvement: reuse/regenerate the ignored Godot cache, use a temporary XDG editor config with update checks disabled, commit the source before the full changed-file gate, and name `origin/main` explicitly. The final rerun passed all 35 tests.
- Tooling / docs drift discovered: none.
- Follow-up: complete canonical workstream landing; the independent review correction is closed.
- What worked: the focused smoke covers MusicManager ownership without adding a player, and the modified existing handoff regression proves the transition callback is actually invoked.

## Next Handoff

- Next workstream: none; this is the one authorized solo implementation.
- Next packet state: not applicable; no task packet was created.
- Refresh owner: none.
- ChatGPT/user planning refresh required: no.
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae9bc56-9e1c-83ea-8ff9-285be4092acb
- Refresh reason: none.
- Next action: land with `workstream.py finish`.
- Blockers or open questions: in-game listening and loop-seam audition remain human-owned; graphical startup was tested, but audible playback was not.
