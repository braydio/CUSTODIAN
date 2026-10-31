# Lightweight worktree provisioning and interrupted claim recovery

Workstream: `agent-workstream-lightweight-lfs-provisioning-v1`

Implemented an explicit deferred-LFS worktree path while preserving full checkout as the default. Capacity is measured before claim acquisition and rechecked before checkout writes. Profiled LFS hydration is local-only, path-specific, and verified against the pointer SHA-256 and size. The published Awakening profile has SHA-256 `03356bf1ae6d3e06974b85f0f2cccb423118135bdb15aac4f080c19fe6e34487`, contains 387 paths including itself, 386 of which exist at the reviewed base, and hydrates 74 exact assets totaling 46,349,921 bytes. A static dependency-closure check covers all 36 loaded project, scene, autoload, and focused-smoke paths. Both Gate plates and `custodian/icon.svg` are explicitly included.

The pinned profile estimate is 52,245,835 filesystem bytes, or 1,125,987,659 bytes including its 1 GiB reserve; a full checkout estimates 6,190,134,467 bytes before reserve. A disposable clone populated from the exact profile and local LFS cache measured 51,097,600 allocated checkout bytes, with zero omitted paths materialized and zero LFS failures. A separate Git/LFS fixture measured 360,448 allocated bytes for full checkout and 28,672 for sparse checkout. Included text remained usable and exact local hydration succeeded. Missing/corrupt local objects and unapproved paths fail closed.

Same-claim recovery now uses an exact-run read-only plan and separately authorized apply. It rechecks the authenticated trace, claim and diagnostic refs, base/branch, exact target, profile, storage, local process evidence, and remote refs under lifecycle mutexes. It preserves the original claim and failed trace, uses a creation-only remote branch lease, and activates a separate recovery trace only after checkout and ref verification. Synthetic fixtures pass the success path and adversarial identity, process, capacity, profile, target, and ref-drift cases. The real Awakening claim, failed run, diagnostic ref, and worktree were not modified; actual recovery remains deferred until the fresh paired review passes.

Validation evidence:

- `test_workstream`, `test_dispatch`, `test_worktree_provisioning`, and `test_workstream_checkout_recovery`: 182 tests passed together; the added static profile dependency-closure test passed independently.
- Canonical changed-file validation: 12 selected owners passed, complete coverage, zero failures/timeouts/infrastructure errors. Final report is retained under the repository Git common-dir validation reports.
- `py_compile` and `git diff --check` passed.

During final scale measurement, a pipe deadlock was found in the batched `git cat-file` reader. It was fixed using concurrent subprocess pipe handling and guarded by a 20,000-entry regression. Static dependency verification also found and added the project icon.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933

## Next handoff

Start the fresh paired review `review-agent-workstream-lightweight-lfs-provisioning-v1` against the landed implementation. Do not recover the protected Awakening claim before its PASS. The current host's incomplete same-user process visibility must remain a recovery blocker if still present at that time.
