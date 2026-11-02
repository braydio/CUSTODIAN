# Procession P1 Exact Source-Scope Recovery

## Result

Expanded the preserved P1 post-hoc attestation from the recipe document to the exact eight source-bearing paths in immutable archive commit `68cef17f59c6d5e04026b56025451b901bd08185`. Each path is bound to its archive Git blob and regular-file mode `100644`; P1's archived packet blob and workstream identity remain pinned. Approval still requires the existing recovery workstream's accepted canonical independent PASS. The original P1 review claim, branch, worktree, and archive were not modified.

Updated the active recovery implementation and paired-review packets to describe the eight-file scope and acceptance conditions. Added a disposable-Git regression that exercises the real P1 source span: it rejects before approval, accepts after authenticated approval, and rejects missing, extra, forged, changed-blob, changed-mode, and non-PASS cases.

## Validation

- Focused Procession attestation tests: 2 passed.
- Full paired-review runner suite: 166 passed.
- Changed-file validation: `paired_review_runner_unit` passed; coverage complete.
- Task-packet authoring preflight: passed.
- Managed task-packet index check: passed.
- `git diff --check` and attestation JSON parse: passed.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The original recovery acceptance scoped only the omitted Markdown recipe, while P1's immutable source archive included seven additional implementation and validation paths.
- Root cause / contributing factors: The original P1 packet described responsibilities but lacked exact filenames; the recovery correction was based on the initially reported Markdown-only validator failure rather than the full P1 archive diff.
- Prevention / pipeline improvement: Historical source-scope regression derives and asserts the complete source payload from the immutable archive and binds each admitted path to its exact blob and mode.
- Tooling / docs drift discovered: Recovery packet and paired review had a one-document acceptance boundary inconsistent with the actual P1 archive; both now enumerate the exact eight-file scope.
- Follow-up: none
- What worked: Disposable Git history exercises pre-approval rejection and post-approval acceptance against P1's real archive commit.

## Next Handoff
- Next workstream: review-agent-paired-review-procession-doc-scope-recovery-v1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Run the existing paired review in a fresh reviewer context. On accepted PASS, resume the preserved original P1 host-validation run using a fresh plan and its exact digest.
- Blockers or open questions: none
