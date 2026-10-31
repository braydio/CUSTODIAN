# REVIEW COORDINATION ROOT DIRTY PREVENTION & RECOVERY V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-coordination-root-dirty-prevention-recovery-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `coordination-root-dirty-prevention-recovery-v1`
- Locks: `agent-workflow, coordination-root-hygiene`
- Review: `none`
- Review target workstream: `coordination-root-dirty-prevention-recovery-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/COORDINATION_ROOT_DIRTY_PREVENTION_RECOVERY_V1.md`
- Reviewed main: `0c162bdde9de7baa177cc592f0df9c0e426c787e`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6adb61f3-35fc-83ea-87ed-ba961c7b5925`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the prevention/snapshot/recovery claims, specifically that automatically recovering routine root contamination never loses user-owned bytes, never modifies unknown/live-writer files, and never requires a per-incident manual cleanup when a complete checked rescue is safe.
- Reviewed implementation acceptance: All A–I acceptance clauses and the new zero-touch supplement in the archived implementation, including common-dir-only diagnostics, verified worktree identity, claim from dirty root, lossless automatic rescue with exact restoration, safe background resync, fail-closed races, disjoint work continuity and no new Git sync implementation.
- Review evidence: Exact implementation commit and closing summary, temp-repository fixture results, root preservation hashes and stage/index checks, live `persistent_checkout_sync` and dispatcher behavior, all review-specific fault injection traces.
- Correction threshold: Any deletion/reset/stash or misclassified user's staged/untracked data, snapshot leak of secret/ignored files, root writes from ordinary task tools, blocked healthy dispatch from dirty root, unsafe wrong-worktree acceptance, silent divergence, missing snapshot proof, new lock inversion, or failed required validation is blocking.
- Focused validation: Independently exercise temporary bare-repo and linked-worktree proof, malicious symlink/path, staged and unstaged root edits, untracked file, ahead+behind local commits, interrupted snapshot, concurrent writes, safe sync and no-sync cases, wrong branch, noncanonical summary; run existing persistent checkout, dispatcher/workstream and paired review affected suites plus green complete changed-file sweep.
- Review focus: Check every root mutation and exact common-dir CAS; fail closed for live/unknown users, large/secret/ignored/unique commits, symlinks and denied/disk-full snapshots; validate resume after restart; prove rescue manifest reopens the exact original staged and untracked bytes; prove disjoint work continues without synchronized root. One-time user authorization is not permission to erase or overwrite unverified files. No OS-wide guard false claim or speculative process attribution.
- Acceptance: Fresh-context findings-first receipt with zero blocking defects/material evidence gaps only after exact proof. Preserve the implemented source; reviewer must not edit it.
- Non-goals: Do not clean the user's current root, alter their pending packet, manipulate active mapper/AP0/ambient branches, or widen design into orphan-lease management.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Next Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6adb61f3-35fc-83ea-87ed-ba961c7b5925`
- Refresh reason: `none`
- Next action: `After independent PASS, activate zero-touch root guard/rescue using existing lifecycle and feed verified results to the Pipeline Recovery Master; let unrelated work continue even when root is protected/dirty.`
- Blockers or open questions: `none after independent reviewer PASSES`

## Zero-touch recovery adversarial cases (2026-10-24)

- Verify that a new untracked non-colliding file is **not** misidentified as a sync blocker: `persistent_checkout_sync.py` already permits the fast-forward with that file in place. Genuine collision is a distinct state.
- Prove safe automatic lossless rescue and fast-forward for an idle root with a small tracked edit, staged change or colliding untracked file, after immutable verified bytes and exact before/after state checks. Include interruption at every stage and snapshot disk-full. Restore original staged/index state on explicit rescue request.
- For root actively edited, unknown owner, local ahead/diverged commits, secrets, large/private/ignored/LFS data, symlink escape or failed verification, preserve the original and **do not** auto-clean; normal dispatch and worktree execution must continue independently of root sync.
- Prove there is no indefinite retry loop or mutex inversion. An automatic trigger must call existing `persistent_checkout_sync.apply_profiles`, not implement a parallel Git merge.
- Verify optional machine-local scheduled retry (systemd user timer where supported) runs after startup and after interrupted sync, is idempotent and never touches the Operator art persistent checkout by default.

## Operator art-worktree non-duplicate regression review (2026-10-25)

The reviewer must independently execute the implementation packet's **reported Operator PNG incident** tests A–D using temporary repositories and synthetic PNGs. Verify that `temp/operator__southeast__aim_ranged-2h.png` remains protected when its counterpart has different hash/dimensions, that an unrelated untracked image does not block fast-forward, and that even identical-by-hash images cannot be removed without durable verified rescue and exact-path race/ownership safety. Confirm the tested code **never edits the real Operator art worktree** and does not claim that file authorship or source equivalence can be inferred from these observations. Require a durable PASS/FAIL result for every case and preserve the original incident report as evidence only, not permission to mutate local bytes.
