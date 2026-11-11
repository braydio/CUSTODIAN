# Visual Review Dropbox Handoff — Summary

Workstream: `visual-review-dropbox-handoff`

## What changed

- Added `custodian/tools/iteration/publish_review_artifacts.py`, an opt-in
  rclone publisher for compact human/ChatGPT visual-review evidence.
- Added focused unit coverage in
  `custodian/tools/iteration/test_publish_review_artifacts.py` and registered
  it as `visual_review_handoff` in the changed-file validation manifest.
- Added `custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md` as the canonical
  gate and transport contract.
- Routed root/local AGENTS, Moment Forge tooling/docs, validation recipes,
  task-packet authoring, paired-review authoring, task-packet README, runtime
  review prompt, FILE_INDEX, and CURRENT_STATE through the same rule:
  objective checks first; when a material subjective decision remains, publish
  one compact Dropbox handoff and stop rather than spending coding-agent turns
  on aesthetic self-review.
- Clarified the Moment Forge design doc so its old direct-human `full` default
  does not override the newer agent visual-evidence economy. Dropbox publication
  is explicitly post-run transport, not a Moment Forge runtime/report dependency.

## Publisher contract

Remote resolution:

1. `--remote`
2. `CUSTODIAN_REVIEW_REMOTE`
3. configured rclone remote named `dropbox:`

Canonical remote root:

`/CUSTODIAN/visual_review/<workstream>/<run-id>/`

Each upload carries `REVIEW_MANIFEST.json`, a compact artifact set, SHA-256 and
size metadata, exact reviewer questions, Git branch/commit provenance, and a
per-workstream `LATEST.json` pointer.

Default budget is 12 files, 6 keyframes, and 50 MiB. One MP4 requires explicit
`--include-video`. Publication itself requires
`--important --reason ...`.

No Dropbox/rclone credentials are stored in the repository.

## Validation

- Python syntax compilation: passed for publisher and focused test.
- Focused unit test: 5/5 passed.
- Fake-rclone end-to-end exercise: passed; verified bundle upload,
  `REVIEW_MANIFEST.json`, artifact selection, `LATEST.json`, and emitted
  `CUSTODIAN_VISUAL_REVIEW_HANDOFF_JSON`.
- The end-to-end fake remote selected one contact sheet, six sparse keyframes,
  and metrics from an eight-keyframe fixture, then verified the remote manifest.
- Live Dropbox transport has not been exercised from the user's workstation yet
  because the local rclone remote still needs to be checked/configured there.

## Documentation drift corrected

- `MOMENT_FORGE_SYSTEM.md` still said direct human use defaults to
  `--capture-mode full`, while root/local AGENTS and validation recipes had
  already moved agent workflow to `none -> evidence -> justified full`.
  The design doc now distinguishes the old V1 direct-human behavior from current
  agent policy.
- General visual-review guidance previously ended at “human-owned” without a
  durable transport path. The new handoff doc and publisher close that gap.

## Deferred / environment setup

- Confirm/configure the user's local rclone Dropbox remote.
- Run `publish_review_artifacts.py --doctor --ensure-root` from the live
  checkout after rclone authentication.
- The linked ChatGPT Dropbox currently has no `/CUSTODIAN` folder; creating the
  canonical review root is an external Dropbox mutation and should happen only
  after explicit confirmation.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: none in the implementation; live workstation rclone state is not visible through GitHub/Dropbox connectors.
- Root cause / contributing factors: rclone credentials and remote naming are intentionally local-user configuration.
- Prevention / pipeline improvement: publisher includes `--doctor`, `--ensure-root`, remote precedence, fail-closed upload verification, and an opt-in gate.
- Tooling / docs drift discovered: stale Moment Forge direct-human full-capture wording; corrected in scope.
- Follow-up: manual-follow-up
- What worked: existing Visual Validation Economy policy provided a clean boundary for the external review transport.

## Next Handoff

- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: configure/verify the local rclone Dropbox remote, then run the publisher doctor against `CUSTODIAN/visual_review`.
- Blockers or open questions: local rclone remote name/authentication has not yet been verified.
