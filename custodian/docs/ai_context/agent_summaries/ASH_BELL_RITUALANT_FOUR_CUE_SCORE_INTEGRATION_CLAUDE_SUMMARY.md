# Forlorn Ritualant Four-Cue Score Integration

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20

## Implemented

- Integrated four approved Forlorn Ritualant music cues with one exclusive
  `MusicManager` lease and an Underground-scoped director. Exploration starts at
  the authored ChapelApproach reveal; combat, peaceful and hostile resolution,
  survival aftermath, restore and exit follow their existing encounter state.
  Causeway playlist policy remains unchanged, and SFX/room-bed fulfillment stays
  separate.
- Refreshed only The Ninth Was Never Cast to the approved Gentler Attacks v2
  source. The ZIP SHA-256 is
  `b7e8e37eb058e5a116966a288389afe0691c633e80eedbb727f7b307148e0f90`; the
  exact runtime OGG SHA-256 is
  `51a64027a61ea8db5704e08036bfeb6babdb4c54c130edbaa000db325788f6aa`. It is
  preserved at the canonical v2 inbox and runtime paths. The other three cues
  remain byte-identical.
- Refined the existing completion smoke's boarding samples from x=±68 to x=±50.
  The former points overlapped the current front wings; the new samples remain
  inside the clear boarding corridor. This changes only validation probes; no
  collision, traversal or audio runtime behavior changed.

## Evidence

- PASS: ZIP integrity and all member SHA-256 entries; `ffprobe` reports Ogg
  Vorbis, stereo 48 kHz and 185.806271 seconds; inbox/runtime hashes match.
- PASS: Godot 4.7.2 project import; `ritualant_four_cue_music`;
  `asset_requirements_smoke.py`; `forlorn_ritualant_mapper_semantics`;
  `forlorn_ritualant_runtime`; and `git diff --check`.
- PASS: full `run_validation.py --changed --base origin/main --json` report at
  `/tmp/ritualant-score-final-validation.json`: complete coverage, 46 passed,
  0 failed, 0 skipped, 0 infrastructure errors.
- The four-cue music requirement is fulfilled. `ash-bell-audio-cues` for SFX
  and room ambience remains `needed`. Human in-game audition of dialogue
  clarity, duck intensity and loop edges remains pending as a separate quality
  review; it was not self-certified.
- A clean baseline comparison had previously exceeded the filesystem quota
  while creating a second Godot import cache. The current worktree cache was
  reused for validation, and generated unrelated UID sidecars were removed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: the first current-main geometry correction updated the
  lower-lift backstop and wing dimensions, while the completion smoke still
  sampled x offsets ±68 that overlapped those wings.
- Root cause / contributing factors: validation treated obstructed edge points
  as walkable even though the revised geometry leaves a narrower clear corridor.
- Prevention / pipeline improvement: retain exact geometry-size checks and
  sample runtime clearance only inside the authored open corridor.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: focused music/runtime checks and the complete changed-file sweep
  validated the v2 source refresh without modifying encounter or collision
  behavior.

## Next Handoff

- Next workstream: review-ash-bell-ritualant-four-cue-score-integration
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Refresh reason: none
- Next action: run the paired fresh-context independent review after this implementation lands and archives.
- Blockers or open questions: human in-game audio quality review remains pending and must not be described as complete.
