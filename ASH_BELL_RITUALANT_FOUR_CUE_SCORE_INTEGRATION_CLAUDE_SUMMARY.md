# Forlorn Ritualant Four-Cue Score Integration

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20

## Implemented

- Installed the four provided OGGs without re-encoding into both the Ash-Bell
  runtime music path and the specialized audio inbox. Source ZIP member, inbox,
  and runtime SHA-256 values match for all four. The handoff manifest records
  archive provenance, codec, channels, sample rate, measured duration, loop
  semantics, and state target.
- Added an exclusive `MusicManager` scene lease with loop and one-shot playback,
  transition cancellation, music-only ducking, one-shot completion, and
  conditional playlist restoration. A second scoped owner cannot steal an
  active lease; a successor global playlist explicitly takes authority.
- Added the Underground music director for ChapelApproach reveal, committed
  combat, fresh Set Stilling Pin and final anchor transitions, hostile
  defilement, nonlethal dissolve, save/restore, dialogue, Ninth Answer, and
  teardown. It avoids replaying historical one-shots and does not start
  exploration before the authored reveal on pre-reveal route restore.
- Added the independent fulfilled music requirement while leaving
  `ash-bell-audio-cues` (SFX and room bed) `needed`. Added a deterministic smoke,
  validation routing, the score design note, and current-state/index/recipe
  documentation. Passive fountain stabilization code remains untouched.

## Evidence and blockers

- PASS: `ritualant_four_cue_music` via the validation runner; also passed after
  testing explicit-pin and final-anchor routes, hostile resolution, restore,
  fresh-only playback, one-player ownership, scoped ducking, and fade takeover.
- PASS: audio requirement projection and `asset_requirements_smoke.py`.
- PASS: `git diff --check` at checkpoint.
- PASS: archive/runtime/inbox byte and SHA-256 parity for all four cues; Godot
  4.7.2 imported and loaded the new audio resources.
- BLOCKED: full changed-file report had complete coverage, with 41 passes, two
  failures, and two Moment Forge checks skipped. Existing failures were
  `forlorn_ritualant_mapper_semantics` (chapel art bounds) and
  `forlorn_ritualant_runtime` (lower lift backstop/wings and boarding collision).
  These checks target unchanged geometry/texture-bound code; a clean baseline
  checkout comparison hit the filesystem quota while generating a 1.2 GB Godot
  cache. I removed that temporary checkout and did not change unrelated lift or
  mapper behavior.
- BLOCKED: the existing `asset doctor` reports four Awakening designation-locker
  catalog hash mismatches, outside this workstream. Direct existing Ash-Bell
  scene and combat-audio smokes also report unrelated pin-pickup/lift and
  positional-audio assertions; none are changed by this score integration.
- Human in-game audition of dialogue clarity, duck intensity, and loop edges is
  still pending, as required by the audit; it is a post-implementation review.
- Root `main` has the user's unrelated dirty Operator file, so safe root sync
  remains pending even after a future landing.

The current changed-file validation is not green. Do not mark this packet
complete or land on `main` until its finish gate can accept the required
validation evidence. The branch is being preserved for recovery and latest-main
reconciliation.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: high
- What went wrong: required changed-file validation exposed existing Ritualant geometry checks; a separate baseline worktree exceeded the filesystem quota during Godot import.
- Root cause / contributing factors: shared validation-manifest ownership selected 45 checks; clean Godot worktrees each generated large import caches.
- Prevention / pipeline improvement: reuse the current worktree import cache for focused checks and verify free space before creating a second imported worktree.
- Tooling / docs drift discovered: changed-file routing from `validation_manifest.json` alone selects many unrelated checks; asset doctor currently has unrelated catalog hash drift.
- Follow-up: manual-follow-up
- What worked: the focused score smoke was deterministic and the source/runtime/inbox audio parity was independently hashed.

## Next Handoff

- Next workstream: ash-bell-ritualant-four-cue-score-integration
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Refresh reason: none
- Next action: Reconcile this branch with latest origin/main, resolve or obtain accepted ownership for the two existing Ritualant validation failures, then rerun the changed-file finish validation and paired review.
- Blockers or open questions: `forlorn_ritualant_mapper_semantics` and `forlorn_ritualant_runtime` are red in the changed-file sweep; no source owner for their geometry assertions was confirmed in this workstream.
