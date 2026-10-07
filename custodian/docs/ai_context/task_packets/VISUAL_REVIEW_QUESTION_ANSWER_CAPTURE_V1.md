# VISUAL REVIEW QUESTION ANSWER CAPTURE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `visual-review-question-answer-capture-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `agent-workflow, visual-review-handoff`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-visual-review-question-answer-capture-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `this changes the fail-closed human-review evidence and cleanup contract; independent review should prove questions cannot be lost, answers pair deterministically, and legacy cleanup remains safe`
- Reviewed main: `0a1d526baa19264d20f33308c6acc6edf6351e44`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery/closeout summary and final `## Next Handoff`.
- Goal: Make every important Dropbox visual-review handoff carry the exact reviewer questions and make review resolution pair those questions with explicit human/ChatGPT answers plus one overall disposition before new review evidence can be cleaned up, so no decision is stranded only in chat prose.
- Completion boundary: Done when important review publication fails closed without at least one concrete question; the existing visual-review manifest remains backward-compatible while exposing whether a decision is required/recorded; one bounded review-resolution operation records one answer per question plus reviewer/disposition/notes; cleanup refuses to delete newly published runs until that decision is recorded; legacy manifests remain explicitly cleanable under their previous contract; focused tests cover empty-question publication, count/order mismatch, repeat resolution, legacy behavior and cleanup ordering; docs describe the new lifecycle; and, if the still-live AR4 evidence run exists, the approved five-question `waive-to-playtest` decision below is backfilled and verified without this packet deleting AR4's evidence.
- Current measured state:
  - `custodian/tools/iteration/publish_review_artifacts.py` already accepts repeated `--question` and writes a top-level string-list `questions`, but `--important` does not require any question. The live AR4 manifest `/CUSTODIAN/visual_review/procgen-archive-resolve-frontier-restraint/20261006T143657Z/REVIEW_MANIFEST.json` therefore published with `"questions": []` even though its packet/user handoff had five explicit review questions.
  - `cleanup_reviewed()` currently validates the manifest plus reviewer identity and then applies retention. It has no answer/disposition input and no standard machine-readable review-decision receipt.
  - `VISUAL_REVIEW_HANDOFF.md` and agent guidance already say important handoffs should carry exact questions and that the decision must be recorded before cleanup, but the tooling does not enforce either half of that prose contract.
  - Existing `custodian.visual_review_handoff.v1` manifests and historical cleanup behavior must remain readable; do not require a bulk migration of old Dropbox evidence.
- Evidence: `custodian/tools/iteration/publish_review_artifacts.py`; `custodian/tools/iteration/test_publish_review_artifacts.py`; `custodian/docs/ai_context/VISUAL_REVIEW_HANDOFF.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; root/local `AGENTS.md`; live AR4 `REVIEW_MANIFEST.json` path above.
- Task-specific authority: `VISUAL_REVIEW_HANDOFF.md` for the human-review boundary and retention contract; `publish_review_artifacts.py` for outbound publication/review cleanup; `AGENT_WORKSTREAM_LIFECYCLE.md` for pause/resume semantics.
- Work surface: Keep implementation centered in `custodian/tools/iteration/publish_review_artifacts.py` and `custodian/tools/iteration/test_publish_review_artifacts.py`; update only the visual-review lifecycle/agent docs made stale by the new enforced contract. Reuse existing rclone/path-confinement/remote-resolution helpers. Do not broaden into inbound implementation handoffs or Dropbox asset-batch tracking.
- Change:
  1. Important upload must require at least one non-empty reviewer question. `--important --reason ...` with zero effective questions fails before upload. Duplicate/blank questions should be normalized or rejected deterministically rather than silently producing an empty review contract.
  2. Preserve the top-level `questions` string list for compatibility with current readers. Add explicit manifest metadata indicating that newly published important runs require a recorded review decision before delete-after-review cleanup. Do not rewrite historical manifests in bulk.
  3. Add one bounded review-resolution operation to the existing publisher. Recommended CLI shape is a dedicated `--record-review-decision <REVIEW_MANIFEST.json>` mode with `--reviewed-by`, one overall `--decision`, repeated ordered `--answer`, and optional bounded notes. Exact private/helper names may differ if the live CLI has a cleaner seam, but the external behavior below is required.
  4. The review-resolution operation fetches and validates the exact path-confined manifest, preserves its workstream/run/git/authoring-chat/artifact identity, then pairs answers to questions by stable manifest order. It must reject missing answers, extra answers, blank answers, unsupported decision values, malformed/non-list question data, or an attempt to silently reorder/replace non-empty manifest questions.
  5. Support these overall dispositions at minimum: `approve`, `tune`, `waive-to-playtest`, and `reject`. Store the literal disposition, reviewer identity, recorded-at UTC timestamp, optional notes, and a structured ordered list containing both each question and its answer. Do not infer an answer from the disposition.
  6. Make repeat resolution idempotent only when the supplied reviewer/disposition/questions/answers/notes are exactly identical to the already-recorded decision. A conflicting second decision must fail closed rather than overwrite human history.
  7. For a legacy manifest whose `questions` is empty, allow one explicit repair path only when the review-resolution command supplies both the complete ordered question list and matching answers. That operation backfills the top-level questions and records the decision in one validated write. A legacy manifest with non-empty questions may not replace them during resolution.
  8. Write the resolved decision into the exact review run in machine-readable form. Prefer a `review` object inside `REVIEW_MANIFEST.json` and, if useful for inspection/atomicity, a sibling `REVIEW_DECISION.json`; do not create a second mutable global `LATEST`-style authority. The emitted stdout receipt must include workstream, run id, manifest path, authoring chat, disposition, question count, answer count and review status without dumping credentials.
  9. Newly published manifests with decision-required metadata may not be deleted by `--reviewed-manifest` cleanup until a valid recorded decision exists and covers every manifest question. Historical manifests without the new decision-required marker retain the existing explicit cleanup behavior so old evidence does not become undeletable.
  10. Keep decision recording and cleanup separable. Recording a decision must not purge the run. Cleanup remains the existing explicit second step after the agent has copied the decision into durable task evidence. This preserves inspectability and avoids destroying the evidence in the same command that records the human call.
  11. Update `VISUAL_REVIEW_HANDOFF.md`, `AGENT_WORKSTREAM_LIFECYCLE.md`, and only directly relevant root/local agent guidance so the canonical sequence is: publish exact questions -> human/ChatGPT answers -> record structured decision -> copy disposition/Q&A into durable task evidence -> cleanup exact reviewed run.
  12. Remove or reconcile duplicated/stale visual-review-pause prose encountered in those active docs only when it is clearly the same contract; do not perform unrelated documentation cleanup.
- Preserve:
  - Coding/execution agents still may not self-approve subjective aesthetics or game feel.
  - Objective validation precedes visual review.
  - Existing compact evidence budgets, Dropbox credential boundaries, path confinement, retention policies and `LATEST.json` ownership remain intact.
  - `questions` remains readable as the existing ordered list of strings.
  - Existing historical manifests remain readable and explicitly cleanable; no provider-wide migration or sweep.
  - Decision recording never edits game/runtime state, task implementation, screenshots, or artifact bytes.
- Non-goals: No automatic visual judgment; no LLM/image-analysis integration inside the publisher; no inbound `implementation_inputs` change; no `asset_batches` change; no provider credential work; no historical Dropbox bulk rewrite; no requirement to retain review media indefinitely; no gameplay/runtime changes.
- Acceptance:
  1. `--important` publication with zero/blank questions fails with a concise nonzero result before any upload; one or more valid questions appear byte-for-byte/in-order in the resulting manifest.
  2. New important manifests mark review-decision requirement explicitly and start unresolved.
  3. A valid review-resolution command records exact reviewer, disposition, timestamp, optional notes and N ordered `{question, answer}` pairs for N manifest questions.
  4. Missing/extra/blank answers, question mismatch/reordering, malformed question data, unsupported disposition and conflicting repeat resolution fail closed without partially rewriting remote state.
  5. An identical repeated decision is a safe no-op/idempotent success.
  6. New decision-required runs cannot be cleaned up while unresolved or only partially answered; after a complete decision they follow the existing retain/delete-after-review policy.
  7. Legacy manifests without the new marker keep the existing cleanup behavior. A legacy empty-question manifest can be repaired only by explicitly supplying a complete ordered question+answer set.
  8. Focused tests prove remote write failure cannot leave a manifest claiming a recorded decision when the corresponding full decision payload was not successfully written. Choose an atomic/replace sequence that is fail-closed with the available rclone primitives.
  9. Emitted machine-readable receipts expose question/answer counts and disposition but no Dropbox credentials or raw config.
  10. Active workflow docs match the implemented sequence and no longer imply that prose-only answers are sufficient durable review evidence.
  11. If the AR4 run still exists when this packet is executed, use the new legacy-repair/record path to populate the exact five question/answer pairs below, verify the remote result by reading it back, and leave cleanup to the AR4 workstream. If the run has already been cleaned up, do not recreate it; the focused regression fixture is sufficient.
  12. Focused publisher tests, directly affected packet/workstream tests, review-pairing validation, changed-file validation and `git diff --check` pass, with pre-existing unrelated failures called out rather than laundered as this packet's defects.
- Validation:
  - Start with `python3 custodian/tools/iteration/test_publish_review_artifacts.py`.
  - Add fake-rclone fixtures covering questionless upload, structured decision success, answer-count mismatch, conflicting second decision, identical idempotent decision, legacy empty-question repair, unresolved-new-manifest cleanup refusal, post-decision cleanup, retain policy, unreadable/malformed manifest, and remote-write failure.
  - Run directly affected agent workflow tests if shared lifecycle parsing/finish behavior changes.
  - Run `python3 custodian/tools/agent/validate_review_pairing.py`.
  - Run `python3 custodian/tools/agent/check_ai_context.py --json` and distinguish pre-existing failures from task-caused regressions.
  - Run `python3 custodian/tools/validation/run_validation.py --changed --json`.
  - Run `git diff --check`.
- Visual review: `none`
- Task overrides: `none`
- Deferred: A generalized durable human-decision database across non-visual workflows; provider-wide evidence TTL/sweeping; arbitrary multi-reviewer voting.

## Live AR4 Decision Fixture

If this exact run still exists:

```text
/CUSTODIAN/visual_review/procgen-archive-resolve-frontier-restraint/20261006T143657Z/REVIEW_MANIFEST.json
```

record:

```text
decision: waive-to-playtest
reviewed_by: chatgpt-user
```

Ordered question/answer pairs:

1. **Q:** Are unresolved sections visibly present without feeling sluggish?
   **A:** Accept for landing. Persistent unresolved sections are clearly present; temporal sluggishness is deferred to ordinary playtest. Do not tune the current 84 starts/sec baseline yet.
2. **Q:** Do walls and turns act as convincing reveal curtains?
   **A:** Yes. The renderer evidence is sufficient to accept walls and turns as reveal curtains at this stage.
3. **Q:** Does the frontier stay local rather than clearing the whole screen?
   **A:** Yes. The 11-tile radius keeps the frontier local while leaving unresolved terrain materially present on screen.
4. **Q:** Is the path and any hazard right around the Operator always readable?
   **A:** Yes. The visibility-gated safety halo keeps the immediate Operator path and hazard area readable; accept the current behavior.
5. **Q:** Does settled terrain stay stable rather than pumping in and out?
   **A:** Accept for landing. The implementation contract preserves settled tiles and avoids re-veil; experiential pumping judgment is deferred to playtest.

Decision notes:

```text
Land AR4 at its current tuning unchanged: radius 11 tiles, current irregular fringe,
84 resolve starts/sec, burst cap 8, resolve_duration_sec 0.22. Revisit those values
only if ordinary gameplay produces concrete pacing/readability evidence.
```

Do not delete this AR4 run from this tooling workstream. AR4 retains ownership of its own post-closeout cleanup.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `none`
- Root cause / contributing factors: `none`
- Prevention / pipeline improvement: `none`
- Tooling / docs drift discovered: `Publisher allowed an important handoff with an empty question list; review cleanup had no structured answer/disposition contract.`
- Follow-up: `paired review`
- What worked: `Existing path-confined publisher, manifest identity and cleanup tests provide the correct narrow seam.`

## Handoff

- Next workstream: `review-visual-review-question-answer-capture-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: `Run the fresh-context paired review after the implementation lands.`
- Blockers or open questions: `none`
