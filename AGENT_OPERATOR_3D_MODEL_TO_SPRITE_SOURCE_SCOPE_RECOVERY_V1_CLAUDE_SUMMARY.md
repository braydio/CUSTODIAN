# Operator model-to-sprite source-scope recovery

Workstream: `agent-operator-3d-model-to-sprite-source-scope-recovery-v1`

The original model-to-sprite implementation and review identities remain unchanged. Immutable Git reconstruction confirmed the archived implementation source span has 26 changed paths, including 17 code/test paths. The archived packet’s declaration misses exactly 12 source files: four experimental-master JSON records and eight live model-to-sprite tooling files. Their exact paths, blobs, and `100644` modes are recorded in the recovery packet and canonical attestation.

The host validator now accepts this historical exception only when the exact source run, claim, branch, worktree, source base/head, archive commit/parent/tree, archived packet blob, full 17-path code/test inventory, and all 12 omitted path/blob/mode identities match. It also authenticates the correction pair’s canonical accepted independent PASS, packet/outcome/receipt identities, ancestry, and reviewer evidence before admitting the 12 paths. No generic path rule was relaxed.

Regression coverage exercises activation only after accepted PASS and rejects altered/missing/extra paths, blobs and modes; changed packet, source, archive and review identities; forged/nonpassing outcomes; unrelated worktrees; and divergent histories. The focused `operator_3d_` tests passed (5 tests), and the direct full paired-review runner suite passed (247 tests). Packet authoring, category, AI-context, task-index, Python compilation, and `git diff --check` passed. The changed-file wrapper’s default 120-second test cap timed out; a local in-memory timeout extension was used for a full changed-file rerun and its result is recorded separately.

Before the correction’s independent review is accepted, the original review recovery plan still fails closed with the exact 12 undocumented source paths. No original review run, claim, branch, worktree, or host evidence was changed, and no reviewer verdict has been invented. The next step is the fresh paired review of this correction. Only after its accepted PASS may the exact original run `20261031T022410Z-7204104581e7` be replanned, hash-bound applied, continued, and given a genuine reviewer verdict.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae4ca33-99cc-83ea-b344-8d13b65268d1
