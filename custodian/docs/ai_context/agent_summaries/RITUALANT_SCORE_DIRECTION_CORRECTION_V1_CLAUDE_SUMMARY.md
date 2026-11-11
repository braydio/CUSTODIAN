# Ritualant Score Direction Correction V1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20

## Result

Implemented scoped two-deck music playback with equal-power cue crossfades and an independent shared duck controller. The Underground claims the prior zone's playlist on arrival, fades to silence, and starts exploration only after the authored chapel reveal. Committed hostility starts the combat loop; dialogue and Ninth Answer ducks do not cancel cue changes. A committed Stilling Pin or third valid ordered anchor starts the peaceful one-shot, fresh `SITE_DEFILED` starts the hostile one-shot, and both one-shots plus nonviolent survival resolve to scene silence. Departure fades release on failed-exit rollback; scene teardown restores the prior playlist only while the scene still owns the lease. A terminal-resolution latch prevents later provocation from resurrecting combat, and delayed arrival completion cannot start exploration during teardown.

All four approved OGG files and their provenance remain unchanged. Updated the active score/current-state notes and registered the existing Ash-Bell interaction smoke in validation ownership. The fixture now supplies the required completed dialogue topics when no dialogue presenter advances them.

## Validation

- `run_validation.py --test ritualant_four_cue_music --json`: PASS.
- `run_validation.py --test ash_bell_scene_interactions --json`: PASS.
- `ash_bell_scene_smoke.gd` and `forlorn_ritualant_completion_smoke.gd`: PASS.
- `asset.py needs --check` and `asset_requirements_smoke.py`: PASS.
- `run_validation.py --changed --json`: 47/47 tests passed, complete coverage, no skips or infrastructure errors.
- `git diff --check`: PASS.
- The focused and encounter smokes emit existing invalid texture UID fallback warnings. Human in-game balance, dialogue intelligibility, and loop-boundary audition remain pending; no visual or subjective mix approval is claimed.

The first focused run exposed harness timing assumptions around arrival silence and cue-transition completion. The Ash-Bell interaction regression then exposed its missing dialogue prerequisites and absent manifest owner. I corrected those fixtures and added completion signaling from the manager so reveal timing follows the actual fade rather than a parallel timer. The initial changed-file run passed its selected tests but reported the Ash-Bell smoke uncovered; registering it closed coverage, and the final changed sweep passed completely.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Initial test assumptions sampled reveal/one-shot states at the wrong transition boundaries; the existing Ash-Bell smoke omitted prerequisites because its dialogue callback was disconnected, and it had no validation-manifest owner.
- Root cause / contributing factors: The prior integration smoke used zero-duration transitions and expected exploration after terminal one-shots. Arrival completion was not observable through a lifecycle signal, and the interaction fixture relied on dialogue side effects that it did not execute.
- Prevention / pipeline improvement: Use real timed deck assertions; gate reveal on actual scoped-silence completion; explicitly prepare scene fixtures; register each changed smoke with the validation manifest.
- Tooling / docs drift discovered: `ash_bell_scene_smoke.gd` was unowned by changed-file validation; fixed in-scope.
- Follow-up: fixed-in-scope
- What worked: Scoped owner leases and monotonic cue/duck transition generations kept audio authority in one manager while allowing independent transitions and restoration.

## Next Handoff

- Next workstream: review-ritualant-score-direction-correction-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Refresh reason: none
- Next action: Land and archive the implementation, then run the required fresh-context paired review.
- Blockers or open questions: Human in-game listening is pending as a qualitative follow-up and does not block this packet.
