# MC1 Stranded Claim Recovery

## Result

Recovered the stale MC1 logical lock through the approved exact-SHA branch hygiene retirement. The task stopped before an LF1 claim because a different active owner now holds `agent-workflow`.

## MC1 ownership reconciliation

- Initial dispatcher audit on `origin/main` `b05417cc75e5ec735b70a40113c31db20e582084`: MC1 was `claimed`, despite packet `draft/manual`; its only claim evidence was the published agent branch. LF1 was `ready/auto`, `dependency_lock_blocked`, with reason `lock: agent-workflow held by agent-mission-control-data-model-v1`.
- Remote MC1 branch head matched the conditionally authorized SHA `59a1176ce01c1c2f8282a5d1f5df912771b913ab`; it was 17 commits behind and zero commits ahead of fetched main. There were no unique implementation commits.
- Attached MC1 worktree was on the exact branch and SHA. No staged or tracked modifications existed. The only untracked files were the two generated UID sidecars listed below. No live process, Codex/reviewer/supervisor command, open file descriptor, current dispatch receipt, lease, or active RunTrace owner was found. The historical process identity in RunTrace was absent; the RunTrace recorded a direct start with null packet/agent identity and release of its temporary dispatch claim. The old diagnostic ref was preserved.
- Both sidecars were verified disposable Godot-generated UID sidecars: valid `uid://` contents; corresponding tracked scripts unchanged; UIDs absent from tracked references and `origin/main`; timestamps align with initial Godot import after checkout. Before removing only these exact files, byte-identical backups were created and SHA-256 verified in `/home/braydenchaffee/Projects/CUSTODIAN/.git/custodian-recovery/mc1-stranded-20261013T/`.
  - `npa_showcase_existing_enemy_smoke.gd.uid` — `9dcecda3be26b481ec757e9bd4a3c3a85aee34a12afd46bc2939ce89409c9085`
  - `operator_2_5d_composition_preflight_smoke.gd.uid` — `006bf71b5e664ab1975c3b2163cf08dfca29708c75367994ce37aa78fed4188`
  - Manifest: `/home/braydenchaffee/Projects/CUSTODIAN/.git/custodian-recovery/mc1-stranded-20261013T/recovery_manifest.json`; manifest SHA-256 `b7ce3215509b8eac26e6db3a2a5a6c7b1ec5afcd982276b40a86346231a9ecb0`.
- Exact-SHA retirement succeeded through `branch_hygiene.py`. Remote branch `agent/agent-mission-control-data-model-v1` is absent. Annotated archive tag `archive/agent-agent-mission-control-data-model-v1-20261013` peels to `59a1176ce01c1c2f8282a5d1f5df912771b913ab`, and the same disposition is recorded in `custodian/docs/ai_context/BRANCH_ARCHIVE.md`.
- The local MC1 branch/worktree remains preserved and clean at the approved SHA. Diagnostic ref `refs/custodian/diagnostics/agent-mission-control-data-model-v1/20261012T050753Z-d21e8fbdf9fb` remains present. MC1 packet remains `draft/manual` and unimplemented. Reactivation should use the existing clean attached worktree with `workstream.py resume agent-mission-control-data-model-v1` after an authorized owner restarts MC1; reconcile current main and packet first. Do not call `start` while the retained branch/worktree exists.

## LF1 activation

After remote retirement and fresh dispatcher audit, MC1 is no longer claimed and no longer holds the lock. LF1 remains `status: ready`, `dispatch: auto`, but `claim_next_eligible: false`; the current exact reason is `lock: agent-workflow held by review-agent-next-execution-boundary-v1`. No LF1 claim was attempted. Its next action is to wait for that existing owner to release the shared lock, then rerun `dispatch.py audit --json` and claim LF1 explicitly as `codex` only if the audit reports it eligible.

LF1 planning conversation: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62

## Safety and validation

- Coordination checkout remained on main at `b05417cc75e5ec735b70a40113c31db20e582084`; no pull/reset/stash/clean was used.
- `custodian/game/actors/operator/operator.gd` was not modified by this recovery.
- No unrelated remote branch was removed. No gameplay/runtime file, packet eligibility, review result, or acceptance state was changed.
- Recovery audit JSON: `/tmp/custodian-after-mc1-recovery.json`. The exact tag, remote branch absence, MC1 worktree cleanliness/head, and diagnostic ref were checked after retirement.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: LF1's former MC1 lock cleared, but a second current owner already held the same logical lock.
- Root cause / contributing factors: multiple sequential `agent-workflow` owners; eligibility changed between the baseline and refreshed audit.
- Prevention / pipeline improvement: rerun the authoritative dispatcher audit after every lock retirement before claiming the intended successor.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: exact-SHA branch hygiene retirement preserved the remote head and artifact evidence.

## Next Handoff
- Next workstream: agent-longform-session-core-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Refresh reason: none
- Next action: after `review-agent-next-execution-boundary-v1` releases `agent-workflow`, rerun dispatcher audit and claim LF1 as `codex` only if `claim_next_eligible` is true.
- Blockers or open questions: `agent-workflow` is currently held by `review-agent-next-execution-boundary-v1`; ownership must be resolved by that workstream's existing lifecycle.
