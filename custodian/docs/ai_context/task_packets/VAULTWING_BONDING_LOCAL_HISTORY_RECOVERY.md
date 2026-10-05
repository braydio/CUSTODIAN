# VAULTWING BONDING LOCAL HISTORY RECOVERY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vaultwing-bonding-local-history-recovery`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `vaultwing-bonding-art-final-ingest, agent-branch-hygiene`
- Kind: `implementation`
- Review: `none`
- Review rationale: `manual history recovery; no runtime or Asset V2 salvage may occur until the immutable checkpoint and per-commit disposition audit are complete`
- Reviewed main: `6af4db244544771abae14e1be63a901d915edb95`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac323e0-c600-83ea-bb5c-c706c785cf73`
- Summary backlink: Include this exact Authoring chat URL in every durable recovery/audit summary and final `## Next Handoff`.
- Goal: Preserve and audit the clean attached Vaultwing bonding-art worktree without losing its exact HEAD, compare its branch history with current main and the previously audited remote checkpoint, and salvage only commits whose missing content remains genuinely valuable.
- Completion boundary: Done when the attached local HEAD has an immutable remotely verified archive tag created before any worktree/branch mutation; every commit in the measured recovery ranges has a documented category and evidence; only confirmed missing valuable material has been selectively salvaged through its current owner/pipeline; the local archive tag remains permanently reachable; and branch/worktree reconciliation happens only after audit and salvage decisions are complete.
- Current measured state:
  - Attached clean worktree: `/home/braydenchaffee/Projects/.custodian-worktrees/vaultwing-bonding-art-final-ingest-20260928T212819`.
  - Attached local branch/HEAD: `agent/vaultwing-bonding-art-final-ingest` at `7aae81a85e77d8fec05df86bd2bac51cf73b94a2`; working tree and untracked-file status were clean at packet authoring.
  - Previously audited remote head: `2eb4e7190a3bd5f50719e0c613782bac1cf21cc8`. The attached local HEAD is an ancestor of this remote head: there are 23 commits in `local HEAD..previous remote head`, and zero commits in the reverse direction. Do not describe these as local-only commits.
  - At packet authoring, `origin/main` is `6af4db244544771abae14e1be63a901d915edb95`. `origin/main...local HEAD` has 1149 main-only and 2 local-only commits; `origin/main...previous remote head` has 1149 main-only and 25 remote-only commits. Remeasure after fetching at execution. These counts explain why the attached checkout differs from the remote and why neither ref may be rewritten based on the stale closeout packet alone.
  - The associated remote branch was deliberately excluded from `stranded-branch-recovery-closeout`; no action in this packet is authorized until its first-step preservation gate passes.
- Evidence: `custodian/tools/agent/branch_hygiene.py`; `custodian/tools/agent/test_branch_hygiene.py`; `custodian/docs/ai_context/BRANCH_ARCHIVE.md`; `STRANDED_BRANCH_RECOVERY_CLOSEOUT_CLAUDE_SUMMARY.md`; `VAULTWING_BOND_GREET_FINAL_INGEST_CLAUDE_SUMMARY.md`; the exact local worktree and current remote branch.
- Task-specific authority: branch/worktree safeguards in `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; verified retirement/tag behavior in `branch_hygiene.py`; current Asset Pipeline V2 and Vaultwing family ownership for any later selective art salvage.
- Work surface: The attached Vaultwing worktree and local branch, the exact remote branch/tag refs, a durable per-commit audit receipt under `custodian/docs/ai_context/branch_recovery/`, and only files required by confirmed salvage decisions.
- Change:
  1. **Immutable checkpoint first.** Before checking out, moving, resetting, rebasing, deleting, or otherwise mutating any worktree or branch, verify the attached local HEAD still equals `7aae81a85e77d8fec05df86bd2bac51cf73b94a2`, create an annotated tag such as `archive/local-vaultwing-bonding-art-final-ingest-7aae81a-20261005` at that exact commit, push it, and verify `git ls-remote --tags` shows the peeled tag resolving to the full local SHA. If a same-name tag exists at another commit, or tag push/verification fails, stop before all branch/worktree mutation. Keep this tag permanently even if no commit is salvaged.
  2. Fetch `origin` and remeasure the attached worktree status, local HEAD, remote branch head, current main, merge bases, and commit counts. If local or remote identity differs from the recorded checkpoint, preserve all refs and refresh/re-audit the packet before continuing.
  3. Audit each commit from the local checkpoint through the previously audited remote head (the 23-commit `local..remote` range at authoring), plus any local-only checkpoint commits against current main. Because current main contained neither checkpoint at authoring, classify every commit that is unique to either recovery ref relative to `origin/main`; avoid double-counting shared commits. Use commit ancestry, patch IDs / stable patch equivalence, touched paths, current consumers/contracts, prior summaries, and current family/runtime state as evidence.
  4. Record every audited commit SHA exactly once as one of: `already present on main / rewritten-equivalent`, `superseded`, `genuinely unique and valuable`, or `obsolete/no-longer-applicable`. For each, state the evidence, current owner, and whether salvage is selected. The durable audit must cover the complete measured set (25 unique commits across the two refs at packet authoring), not only a hand-picked subset.
  5. Selectively salvage only genuinely unique, valuable, still-missing material. Use its current owner and required Asset V2/source-work or code-validation path; never merge/cherry-pick the whole 23-commit or 25-commit history. If no commit qualifies, record that result explicitly and make no production changes.
  6. Only after the immutable tag, complete audit, and any selected salvage have passed review/validation may the old local branch/worktree be reconciled and the remote branch retired. Use the exact-head retirement path, verify all intended archive refs, and preserve the local-history archive tag permanently. Never force-push or erase an unclassified commit.
- Preserve: The local HEAD and current worktree contents; the remote branch until the audit phase authorizes its retirement; the permanent annotated local-history tag; current main; current Vaultwing production/art state; Git LFS masters and Asset V2 provenance.
- Non-goals: No wholesale merge/rebase/cherry-pick of the stranded history; no blind restore of quarantined/rejected art; no direct runtime writes or bypass of Asset V2; no gameplay redesign; no branch/worktree mutation before the immutable checkpoint is remotely verified.
- Acceptance:
  - The local HEAD is verified remotely under a permanent annotated tag before any branch/worktree mutation.
  - The execution-time ancestry and commit counts are recorded, with the 23-commit range direction stated correctly and duplicates excluded from the unique-to-main audit set.
  - Every commit in the measured recovery set has exactly one of the four required classifications with evidence and a salvage decision.
  - Only confirmed missing, valuable material is selectively salvaged through its present owner; no donor history is merged wholesale.
  - Required focused tests/validation for each salvage pass, plus `git diff --check`, AI-context checks, and clean final worktree/branch/tag verification pass.
  - Any later branch retirement leaves both the exact remote branch head and the local checkpoint reachable from permanent archive refs.
- Validation: Start read-only: check clean status, exact `HEAD`, exact remote branch SHA, and commit ancestry/counts. Verify the immutable annotated tag remotely before mutating worktrees/branches. Run the focused branch-hygiene tests and a report-only pass. For any selected salvage, run its owning pipeline's focused validation and changed-file validation before reconciliation. Finish by verifying the audit receipt, local tag target, archive tag target(s), branch refs, and worktree state.
- Task overrides: `none`
- Deferred: Any commit classified `superseded` or `obsolete/no-longer-applicable`; all runtime/art changes not proven missing and valuable; the separate Operator South continuity packet.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac323e0-c600-83ea-bb5c-c706c785cf73`
- Refresh reason: `none`
- Next action: `Manually claim this packet only after reviewing the preserved-history measurements and confirming the attached worktree is still unchanged.`
- Blockers or open questions: `none`
