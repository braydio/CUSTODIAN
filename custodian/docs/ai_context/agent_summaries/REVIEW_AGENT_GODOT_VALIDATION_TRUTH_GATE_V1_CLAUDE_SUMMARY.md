# Review: Agent Godot Validation Truth Gate V1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1

## Result

The fresh independent review found one blocking defect (R0-01): a referenced tracked `.png.import` sidecar can evade the new preflight when its `source_file` and UID fields are both absent. The gate builds reference needles only from those parsed fields, so it cannot associate the malformed sidecar with a scene that directly references the PNG inferred by the sidecar's tracked filename. A fresh isolated Git fixture reproduced this: `valid=false`, empty `dest_files`, valid remap path, absent `source_file`/UID, direct scene path reference; `preflight_detail()` returned `None`.

The validation runner's negative-control matrix passed. The real import-gated resource trio passed 3/3 and exercised actual actor relationship, Vaultwing, and generated-region rollback resources. The review-artifact changed-file sweep passed 2/2 with complete coverage, and pairing passed for 64 auto-review packets. An additional sweep against the implementation parent was attempted twice and stopped at Godot import infrastructure: editor socket binds failed with `_sock == -1` / `ERR_CANT_CREATE`; XDG path isolation removed the settings-save errors but not the socket failures. This extra target-parent sweep is recorded as an environment limitation; the review packet's changed-file sweep itself is green.

No reviewed implementation or runtime code was edited. The smoke fixture passes when its temp directory is rooted inside this worktree; `/tmp/.git` in the sandbox otherwise causes its standalone fixture to be misdetected as a Git checkout.

## Review Evidence

- Reviewed current main `455392871` and implementation commit `0adbe6265` against base `4b5ba4c4f88f25cbde281ca6f148da58cd5648b2`.
- `python3 custodian/tools/validation/validation_runner_smoke.py`: PASS.
- `godot_import_preflight_smoke.py`, run with `tempfile.tempdir` rooted inside the worktree: PASS.
- `python3 custodian/tools/validation/run_validation.py --tag import_truth --json`: PASS, 3/3.
- `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`: PASS, 2/2 reviewer artifact tests, complete coverage.
- `python3 custodian/tools/agent/validate_review_pairing.py`: PASS, 64 auto-review pairs.
- `python3 custodian/tools/validation/run_validation.py --changed --base 0adbe6265^ --json`: BLOCKED during Godot import on sandbox socket bind diagnostics; XDG path isolation did not resolve it.
- Isolated malformed-sidecar fault probe: FAIL-CLOSED CONTRACT FALSIFIED (`preflight_detail()` returned `None` for referenced invalid sidecar).

## Finding

### R0-01 — Referenced malformed sidecar evades preflight when source metadata is missing

- Class: `blocking_defect`; domain: `implementation`.
- Affected acceptance: referenced tracked malformed `.png.import` sidecars must block project import.
- Evidence: `_sidecar_metadata()` returns `source=None` and `uid=None`; `invalid_referenced_png_sidecars()` indexes only those fields. A tracked `assets/bad.png.import` missing both metadata fields had `valid=false`, an empty destination list, and a remap path. A tracked scene referenced `res://assets/bad.png`, but `preflight_detail()` returned `None`.
- Disposition: correction required. Associate candidates using the tracked `.png.import` path (and explicitly validate required source metadata), and add this missing-source/UID negative fixture while preserving current direct-path/UID coverage.
- Rationale: the preflight can greenlight the exact invalid referenced resource it is meant to reject.

## Validation Limitation

The additional implementation-parent changed-file sweep remains unrun because Godot editor import emits fatal socket bind errors in this sandbox. The packet-required changed-file sweep of review artifacts passed, as did the focused import-gated resource trio. This extra target-parent sweep is useful follow-up evidence but does not block the recorded review outcome.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: A fail-open malformed-sidecar case was not covered; the required changed sweep could not pass Godot import infrastructure.
- Root cause / contributing factors: Sidecar reference matching trusts optional fields inside the malformed sidecar, and Godot editor startup cannot bind sockets in this sandbox.
- Prevention / pipeline improvement: Match the source from the tracked sidecar filename, add the direct-path fixture with absent source/UID, and rerun the changed sweep in a socket-capable environment.
- Tooling / docs drift discovered: The fixture's `/tmp` root intersects an environment-provided `/tmp/.git` marker; a worktree-local temp root passes.
- Follow-up: agent-godot-validation-truth-gate-v1-review-corrections-1
- What worked: The runner negative controls and all three actual imported resource smokes passed.

## Next Handoff

- Next workstream: agent-godot-validation-truth-gate-v1-review-corrections-1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1
- Refresh reason: none
- Next action: Claim the bounded R0-01 correction after this review lands; retain the missing-source/UID negative fixture.
- Blockers or open questions: The optional implementation-parent changed sweep is blocked by sandbox socket restrictions; packet-required review-artifact sweep is green.
