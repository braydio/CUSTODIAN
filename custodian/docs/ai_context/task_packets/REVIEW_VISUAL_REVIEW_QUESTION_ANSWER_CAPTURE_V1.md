# REVIEW VISUAL REVIEW QUESTION ANSWER CAPTURE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-visual-review-question-answer-capture-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `visual-review-question-answer-capture-v1`
- Locks: `agent-workflow, visual-review-handoff`
- Kind: `review`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `none`
- Review target workstream: `visual-review-question-answer-capture-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/VISUAL_REVIEW_QUESTION_ANSWER_CAPTURE_V1.md`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `fresh-context verification of human-review evidence integrity and cleanup safety`
- Reviewed main: `<fill at claim>`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable review/correction/closeout summary and final `## Next Handoff`.
- Goal: Independently prove that important visual-review handoffs cannot lose their questions, that human/ChatGPT answers are paired and recorded deterministically before new review evidence is eligible for cleanup, and that legacy manifests remain safe/readable.
- Completion boundary: Review landed implementation from fresh context against the implementation packet, live publisher/docs, focused hostile fixtures and any still-live AR4 dogfood result. Pass only if questionless important publication fails closed, structured Q/A decision capture is complete/idempotent/fail-closed, cleanup cannot erase unresolved new evidence, and no legacy cleanup or path-confinement regression is introduced.
- Current measured state: Reconstruct from landed main at claim time. Do not rely on the implementation agent's prose summary as correctness authority.
- Evidence: `custodian/docs/ai_context/task_packets/archived/VISUAL_REVIEW_QUESTION_ANSWER_CAPTURE_V1.md` after implementation closeout; live `publish_review_artifacts.py`; focused publisher tests; visual-review lifecycle docs; implementation closing summary; AR4 live/repaired manifest only if it still exists.
- Task-specific authority: implementation packet acceptance; `VISUAL_REVIEW_HANDOFF.md`; `AGENT_WORKSTREAM_LIFECYCLE.md`; live publisher/test code.
- Work surface: Review code/tests/docs and durable implementation evidence. Do not edit the reviewed implementation. This review may commit only its review receipt, summary, lifecycle metadata, and bounded correction/re-review packets when findings require them.
- Change:
  1. Re-run the focused publisher unit suite from fresh context.
  2. Inspect the publication path and prove `--important` cannot publish zero effective questions.
  3. Inspect the decision-recording path and prove answer pairing is strictly by stable question order, with exact count/content validation.
  4. Prove malformed questions, missing/extra/blank answers, unsupported dispositions and conflicting repeat decisions fail without partial remote-state corruption.
  5. Prove identical repeated decisions are idempotent.
  6. Prove newly published decision-required manifests cannot be cleaned up before a complete recorded decision, and can be cleaned up afterward according to retention policy.
  7. Prove historical manifests without the new marker keep explicit legacy cleanup behavior and that the legacy empty-question repair path requires explicit full questions+answers.
  8. Verify path confinement, workstream/run identity, `LATEST.json` behavior and credential boundaries remain at least as strict as before.
  9. If the implementation dogfooded the still-live AR4 run, fetch the exact manifest and verify all five ordered AR4 questions, all five approved answers and `waive-to-playtest` are present. Do not re-judge AR4 aesthetics.
  10. Confirm the implementation did not delete the AR4 evidence run from this tooling workstream.
- Preserve: Reviewer independence; no edits to reviewed implementation; no subjective art/game-feel re-review; no provider credential access; no unrelated Dropbox cleanup.
- Non-goals: No new feature design; no gameplay review; no historical evidence migration beyond validating compatibility; no aesthetic judgment.
- Acceptance:
  - All implementation acceptance items are independently evidenced.
  - At least one negative fixture demonstrates questionless important publication fails before remote upload.
  - At least one negative fixture demonstrates unresolved new evidence cannot be cleaned up.
  - At least one hostile fixture demonstrates answer mismatch/conflicting second decision leaves prior remote state intact.
  - Legacy explicit cleanup still works for manifests without the new decision-required marker.
  - If AR4 dogfood was possible, the fetched live manifest contains exactly 5 questions, 5 matching answers and disposition `waive-to-playtest`.
  - Focused tests, review-pairing validation and changed-file review checks are green or any unrelated pre-existing failure is clearly separated.
- Validation:
  - `python3 custodian/tools/iteration/test_publish_review_artifacts.py`
  - `python3 custodian/tools/agent/validate_review_pairing.py`
  - `python3 custodian/tools/agent/check_ai_context.py --json`
  - affected changed-file validation as appropriate
  - `git diff --check`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`
- Deferred: Optional broader human-decision persistence across non-visual workflows.

## Review Receipt

- Status: `pending`
- Review target workstream: `visual-review-question-answer-capture-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/VISUAL_REVIEW_QUESTION_ANSWER_CAPTURE_V1.md`
- Reviewed main: `<fill at review>`
- Reviewer context: `fresh`
- Reviewer provenance: `<fill>`
- Blocking defects: `<fill>`
- Material evidence gaps: `<fill>`
- Non-blocking issues: `<fill>`
- Optional improvements: `<fill>`
- Correction finding IDs: `<fill>`
- Next-slice finding IDs: `<fill>`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_VISUAL_REVIEW_QUESTION_ANSWER_CAPTURE_V1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `<fill>`

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: `Close review or author only bounded corrections from confirmed findings.`
- Blockers or open questions: `implementation dependency only`
