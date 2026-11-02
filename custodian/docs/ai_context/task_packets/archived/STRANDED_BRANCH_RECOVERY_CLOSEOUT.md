# STRANDED BRANCH RECOVERY CLOSEOUT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `stranded-branch-recovery-closeout`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `agent-branch-hygiene`
- Kind: `implementation`
- Review: `none`
- Review rationale: `low-risk exemption: bounded workflow/tooling hardening plus exact-SHA retirement of five user-reviewed stale refs; no gameplay/runtime/content mutation`
- Reviewed main: `b57ab98db06b697bdb300e397feb67e02c1563fe`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac323e0-c600-83ea-bb5c-c706c785cf73`
- Summary backlink: Include this exact Authoring chat URL in every durable implementation/recovery/closeout summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Safely retire the five stale divergent agent branches still in scope from the authoring chat, preserving every approved remote head as a verified archive tag and recording the recovery/supersession disposition without merging obsolete implementation back into current main.
- Completion boundary: Done when `branch_hygiene.py` has one explicit fail-closed path for operator-approved retirement of a named divergent `agent/*` ref at an exact expected SHA, that path is regression-covered, all five in-scope audited heads below have been archive-tagged and ledgered through the existing retirement machinery, those five remote branch refs are absent, and no donor implementation/art beyond the already-preserved Fast 01 South source master has been replayed into production. The Vaultwing ref/worktree is excluded and remains untouched; its separate packet requires permanent local-head preservation and commit-by-commit audit first.
- Current measured state:
  - `main@b57ab98d` already preserves the one irreplaceable donor source master at `custodian/asset_drop/source_work/operator/unarmed/attack/fast_01/south/fast_1_south.png` as LFS object `sha256:9b079688917b620d6fd46102e0ec5d6d36896fef416b7c676da36cc7a5a5723f`; runtime was intentionally unchanged.
  - Current `branch_hygiene.py --apply` retires landed/identical/ordinary archive candidates but classifies divergent `agent/*` refs as `ACTIVE`, so the five refs in this slice could not previously be retired through the public CLI.
  - Exact audited remote heads originally proposed for retirement:
    - `agent/operator-fast-chain-continuity@93e9604b166027aba27a7c3003aacff86970a09d`
    - `agent/twin-solaria-runtime-v1@f68f0ab049efbc6169692441a815b9ee08a094f3`
    - `agent/awakening-connector-04-05@fe3f3f7788bec3208f544c2be0e79c03384bfee6`
    - `agent/awakening-detail-assets-batch-01@66be9592722c3c67d5b12dfbc49237c7c5506440`
    - `agent/visual-review-dropbox-handoff@b91659c63ff7786925dfe9f106c4134d8325f03e`
  - Vaultwing disposition: `agent/vaultwing-bonding-art-final-ingest` is removed from this slice. Its attached clean worktree is at `7aae81a85e77d8fec05df86bd2bac51cf73b94a2`, while its previously audited remote ref is `2eb4e7190a3bd5f50719e0c613782bac1cf21cc8`. The local HEAD is an ancestor of that remote checkpoint; there are 23 commits between the local checkpoint and the remote head. Against current `origin/main` (`6af4db244544771abae14e1be63a901d915edb95`), the local checkpoint has two unique commits and the remote branch has 25. The attachment is clean, but exact-HEAD mismatch requires preserving both branch and worktree until the new manual recovery audit.
- Evidence:
  - `custodian/tools/agent/branch_hygiene.py` and `custodian/tools/agent/test_branch_hygiene.py`
  - `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`
  - `custodian/docs/ai_context/BRANCH_ARCHIVE.md`
  - `AGENT_WORKSTREAM_RESIDUE_HYGIENE_CLAUDE_SUMMARY.md`
  - `TWIN_SOLARIA_V1A_ASSET_SALVAGE_CLAUDE_SUMMARY.md` and `TWIN_SOLARIA_RUNTIME_V1_CLAUDE_SUMMARY.md`
  - `VAULTWING_BOND_GREET_FINAL_INGEST_CLAUDE_SUMMARY.md`
  - `VISUAL_REVIEW_DROPBOX_HANDOFF_CLAUDE_SUMMARY.md`
  - `OPERATOR_FAST_01_SOUTH_MODULAR_CLAUDE_SUMMARY.md`
  - active `AWAKENING_ROOM_CONNECTORS_POLISH.md` / `AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1.md`
- Task-specific authority: existing verified retirement behavior in `branch_hygiene.py::retire`; branch/worktree safety rules in `AGENT_WORKSTREAM_LIFECYCLE.md`; current live-main recovery summaries listed above.
- Work surface: `custodian/tools/agent/branch_hygiene.py`, `custodian/tools/agent/test_branch_hygiene.py`, `custodian/docs/ai_context/BRANCH_ARCHIVE.md`, this packet lifecycle, and the required root closing summary.
- Change:
  1. Add one explicit CLI mechanism for retiring a user/operator-approved divergent `agent/*` branch by **exact expected remote head SHA**. A repeatable form such as `--retire-approved BRANCH=SHA` is preferred. Preserve current report-only/default `--apply` classification semantics.
  2. The explicit path must fetch immediately before mutation and fail closed when the remote branch is absent, the current remote head differs from the supplied SHA, the ref is protected/diagnostic, an attached worktree is dirty, an attached local head differs from the remote head, archive-tag verification fails, ledger write fails, or remote deletion fails.
  3. Reuse the existing `retire()` machinery for archive-tag creation/remote verification, ledger recording, remote branch deletion, and prune. Do not duplicate a second retirement implementation.
  4. Add focused tests proving: exact-head approval succeeds; mismatched expected SHA performs zero mutation; dirty attached worktree blocks; protected/diagnostic refs block; default `--apply` still does **not** age-delete or automatically retire arbitrary divergent `agent/*` refs.
  5. After tests are green, retire exactly these five audited branch/SHA pairs: `agent/operator-fast-chain-continuity`, `agent/twin-solaria-runtime-v1`, `agent/awakening-connector-04-05`, `agent/awakening-detail-assets-batch-01`, and `agent/visual-review-dropbox-handoff`. Do not use a wildcard, branch-age heuristic, or broader cleanup pass. Preserve the Vaultwing worktree, local branch, and approved remote ref completely untouched.
  6. Record these disposition notes in `BRANCH_ARCHIVE.md`:
     - `operator-fast-chain-continuity`: high-resolution Fast 01 South donor master preserved on main at `b57ab98d`; normalized/canonical Fast 01 South and modular decomposition already live; remaining South Fast 02-04 continuity is owned by `operator-fast-chain-south-continuity`.
     - `twin-solaria-runtime-v1`: validated donor assets were selectively salvaged, then production `hub_twin_solaria` AuthoredLevel runtime landed and evolved on main; do not replay donor registry/import/runtime files.
     - `awakening-connector-04-05`: unique history is an obsolete visual-acceptance packet; current 04→05 ownership is `awakening-room-connectors-polish` and its refreshed downstream gates.
     - `awakening-detail-assets-batch-01`: useful source masters are preserved on main; old standalone publication/binding assumptions are superseded by current baked-only/not-ready Awakening consumption truth.
     - `visual-review-dropbox-handoff`: publisher/tests/docs landed on main and have since evolved, including bidirectional Dropbox handoff work; old branch must not overwrite newer workflow.
  7. Verify each expected `archive/<sanitized-branch>-<YYYYMMDD>` annotated tag resolves remotely to the exact audited head before accepting branch deletion. Verify the five in-scope `refs/heads/agent/...` refs are absent afterward. Verify the Vaultwing remote ref and worktree remain untouched.
- Preserve: All current active agent branches/worktrees/claims; all diagnostic refs; current `main`; all five in-scope archive heads; the Vaultwing local worktree/branch and its existing audited remote ref; the already-preserved Fast 01 high-resolution source; current Twin Solaria, Awakening, Vaultwing, visual-review, and Operator production truth.
- Non-goals: No cherry-pick/merge from any donor branch. No gameplay, scene, Asset V2 publication, Operator runtime, Twin Solaria runtime, Awakening runtime, Vaultwing runtime, Dropbox transport behavior, dispatcher scheduling, or generic age-based cleanup changes.
- Acceptance:
  - explicit approved-retirement mode requires exact branch+SHA and is test-covered;
  - default hygiene behavior remains conservative;
  - five archive tags remotely verify at the five exact audited heads;
  - five in-scope stale remote agent refs are gone;
  - Vaultwing branch `agent/vaultwing-bonding-art-final-ingest` and its attached worktree are unchanged;
  - `BRANCH_ARCHIVE.md` has five truthful retirement entries with successor/recovery notes;
  - no donor file is introduced to current production except the Fast 01 South source master already landed at `b57ab98d`;
  - `git diff --check` and focused agent-workflow tests pass.
- Validation: Run `python3 -m unittest custodian.tools.agent.test_branch_hygiene` first. Then the smallest directly affected workflow suite from `VALIDATION_RECIPES.md`; run a report-only hygiene pass before and after retirement and inspect exact branch/tag refs with `git ls-remote`. Finish with the packet/AI-context checks selected by changed files. No Godot or Moment Forge validation is required because runtime/content behavior is unchanged.
- Task overrides: `none`
- Deferred: Operator South Fast 02-04 art/runtime continuity is a separate packet. Vaultwing local-history recovery is a separate manual packet; do not mutate its branch or worktree in this slice.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `none; Vaultwing was deliberately removed from this slice when its attached clean worktree exposed a separate history requiring recovery audit`
- Root cause / contributing factors: `the attached Vaultwing checkout did not match the previously audited remote branch head; ancestry measurement showed the local checkpoint is an ancestor and 23 commits behind that remote checkpoint, while current main shares neither branch tip`
- Prevention / pipeline improvement: `exact-SHA approval now uses a conditional remote deletion lease, and lifecycle docs describe the explicit exception without weakening conservative defaults`
- Tooling / docs drift discovered: `the original six-ref closeout packet did not account for an attached Vaultwing worktree; created a separate ready/manual immutable-history recovery packet. Earlier shorthand reversed the 23-commit direction; packet and summary record measured ancestry accurately`
- Follow-up: `vaultwing-bonding-local-history-recovery`
- What worked: `five annotated archive tags verified at exact heads before leased deletions; the attached Awakening worktree stayed clean at its original head`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: Five approved refs are absent from origin and each annotated archive tag peels to its exact audited SHA; Vaultwing remote ref and attached worktree remain unchanged. Sixteen focused tests and the agent workflow smoke pass, as do AI-context/pairing checks, changed-file validation, and git diff checks.

## Handoff

- Next workstream: `vaultwing-bonding-local-history-recovery`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac323e0-c600-83ea-bb5c-c706c785cf73`
- Refresh reason: `none`
- Next action: `Manually claim the Vaultwing history audit packet before any worktree or branch mutation; operator-fast-chain-south-continuity remains an independent ready packet.`
- Blockers or open questions: `none for this five-ref closeout; the Vaultwing packet records the corrected 23-commit ancestry direction and requires a permanent local-HEAD tag first.`
