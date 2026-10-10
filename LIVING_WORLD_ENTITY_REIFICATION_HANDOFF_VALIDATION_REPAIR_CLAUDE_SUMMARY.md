# F14-C1 Validation Reference Repair

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31

## Result

Removed the reference to a not-yet-created smoke script from the ready implementation packet's validation recipe. The acceptance still requires authoring and registering the focused real-Enemy handoff smoke; the validation recipe now directs the implementation to run it through its committed manifest entry/path. This lets the dispatcher validate packet references against current `origin/main` without weakening the implementation contract.

The dispatcher had rejected the initial claim because it requires ready packets' explicit validation scripts to exist in `origin/main`. The task packet authoring validator had passed, but it does not perform that live script-reference check.

## Validation

- Unpromoted targeted authoring preflight for implementation + paired review: PASS.
- Promoted targeted authoring preflight for implementation + paired review: PASS.
- `task_packet_index.py`: PASS; managed index already matched the ready/auto pair.
- `run_validation.py --test task_packet_contract_unit --json`: PASS, 1 selected / 1 passed (`/tmp/f14c1-validation-reference-repair-validation.json`).
- `git diff --check`: PASS.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The first dispatcher claim was blocked because the packet referenced a future handoff smoke path that was not yet present on `origin/main`.
- Root cause / contributing factors: The packet's future implementation test path was placed in the dispatcher's live validation-reference field.
- Prevention / pipeline improvement: Keep future acceptance artifacts in the acceptance/work-surface prose; make ready packet validation references point to scripts already published on `origin/main`, while requiring the new test to be registered and executed during implementation.
- Tooling / docs drift discovered: The authoring preflight does not check the live validation-script references enforced by dispatch. Dispatch did correctly fail closed.
- Follow-up: `living-world-entity-reification-handoff`
- What worked: The packet's focused acceptance and design scope remained intact; only the not-yet-published path was removed from the pre-claim validation list.

## Next Handoff

- Next workstream: `living-world-entity-reification-handoff`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac840d2-afe8-83e9-b449-553998582a31
- Refresh reason: none
- Next action: Land the packet reference repair, verify the live `origin/main` packet and queue entry, then claim F14-C1 as Codex.
- Blockers or open questions: none.
