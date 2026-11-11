# Operator chassis-seal source-scope attestation

Workstream: `agent-operator-chassis-seal-source-scope-attestation-v1`

The original chassis-seal implementation and protected review identities remain unchanged. The immutable source archive, source span, trace commit and claim, archived packet blob, and six source code blobs/modes are pinned in the canonical attestation. The attestation records exactly one omitted source path: `custodian/tools/agent/test_workstream.py`.

The host validator admits this one path only when the original reviewed main and source identities match and the newer approval main is on current `origin/main` ancestry. It verifies the canonical attestation bytes and unique origin commit, then requires the correction pair's complete packets, accepted independent PASS, outcome identity, review receipt, reviewer receipt, and ancestry. Before an accepted review exists, the helper returns no attestation; the original source-scope check continues to fail on the exact undocumented test path.

Temporary-Git regression tests cover preapproval rejection, accepted-PASS activation, nonpassing and invalid-receipt states, foreign approval ancestry, changed source/review identities, extra or missing paths, altered blobs/modes, and canonical attestation mutations. The focused tests passed (4 tests). The complete changed-file validation passed with complete coverage: `agent_workflow_contract`, `paired_review_runner_unit` (300 tests), and `review_pairing_contract`. Targeted packet authoring, category checks, review-pairing validation, task-packet index validation, and `git diff --check` passed.

The only packet edits were the authorized syntax-only repair to both active `Publication inputs` entries. Existing paths, spelling, order, authoring URLs, and the source-trace explanatory sentence were preserved; delimiters now match the canonical parser. No original implementation, archived chassis packet, protected review claim/run/worktree/evidence, or verdict state was changed.

The protected original chassis-seal review remains blocked before its reviewer launch until the correction receives an authentic independent PASS. No recovery plan has been applied, and no verdict has been created for the original review. The next step is the correction's fresh-context paired review; only after its accepted PASS may a fresh read-only recovery plan be prepared for the original review.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ea54-f98c-83ea-8582-3ef5bd595199

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: Targeted packet authoring initially rejected comma-delimited Publication inputs; a workstream status storage census also encountered an unavailable CIFS mount.
- Root cause / contributing factors: Packet parser requires semicolon delimiters, while host storage inventory resolves mountpoints across attached worktrees.
- Prevention / pipeline improvement: Keep Publication inputs semicolon-delimited and treat unavailable mount inventory as unknown; preserve affected checkouts.
- Tooling / docs drift discovered: `none`
- Follow-up: `fixed-in-scope`
- What worked: Targeted authoring and adversarial temporary-Git tests established the exact preapproval/accepted-PASS boundary.
