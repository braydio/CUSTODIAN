# Exact review claim parking — packet authoring

## Status

The bounded implementation/review pair is authored against `origin/main@628d403d2629a3f568b003096e4d94585721399f`. Both packets opt into the repository's automatic authoring handoff and are being published together as `draft/manual`; the main-branch workflow is expected to promote them and update the managed index. The parking mechanism is not implemented or reviewed yet.

## Scope and evidence

- The exact protected review remains `review-agent-paired-review-declared-doc-archive-gate-v1`, run `20261019T104055Z-522c04f5260b`.
- Its remote branch is still `f3a225c426a51736551b88c91ea2b786a69e8f5a`; its attached local worktree is at `ad2009ca91a8afec457c8b21c202f1b10b7ca086`, one commit ahead. Original run evidence and review disposition remain untouched and unresolved.
- Packet authoring preflight passed for the implementation/review pair. `task_packet_index.py --write` reported already up to date; review-pair validation passed; `git diff --check` passed.
- The live queue has a separate `agent-workflow` lock held by `review-agent-paired-review-godot-cache-access-v1`. Its local run is `post_exit_recovery`; its worktree has an untracked review summary. This maintenance pair declares `agent-workflow` plus its own `paired-review-claim-parking` lock. No attempt was made to bypass that owner.

## Next Handoff

- Next workstream: `agent-paired-review-exact-claim-parking-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: Verify pair publication and automatic promotion on `origin/main`; re-audit dispatcher eligibility. Claim only if both declared locks are clear. After implementation and fresh independent review, re-audit the exact protected review before its single authorized park transition.
- Blockers or open questions: The target run lacks a recorded OS process/host identity. Apply must fail closed if cross-host owner state cannot be resolved by a fresh explicit, auditable attestation. The existing `agent-workflow` claim also remains a dispatcher blocker until normally resolved.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: medium
- What went wrong: `the first fresh coordination worktree checkout took longer than the short command wait and briefly looked incomplete while git was still populating it; a separate unresolved agent-workflow lock also blocks the future implementation claim`
- Root cause / contributing factors: `large repository checkout is asynchronous under the tool wait limit; dispatcher conservatively treats the published review branch as lock ownership`
- Prevention / pipeline improvement: `retain and poll long-running checkout sessions; keep the broad lock in the maintenance packet and do not claim through an unresolved owner`
- Tooling / docs drift discovered: `the existing OR2 proposal covers general orphan parking but is dependency-gated behind OR1; a bounded exact-claim parking pilot now has its own proposed workstream`
- Follow-up: `agent-paired-review-exact-claim-parking-v1`
- What worked: `targeted packet preflight, dispatcher audit, and fresh-main authoring checkout exposed the second lock before any implementation claim`
