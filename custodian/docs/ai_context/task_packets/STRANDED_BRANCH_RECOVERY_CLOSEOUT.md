# STRANDED BRANCH RECOVERY CLOSEOUT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `stranded-branch-recovery-closeout`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `agent-branch-hygiene`
- Kind: `implementation`
- Review: `none`
- Review rationale: `low-risk exemption: bounded workflow/tooling hardening plus exact-SHA retirement of six user-reviewed stale refs; no gameplay/runtime/content mutation`
- Reviewed main: `b57ab98db06b697bdb300e397feb67e02c1563fe`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac323e0-c600-83ea-bb5c-c706c785cf73`
- Summary backlink: Include this exact Authoring chat URL in every durable implementation/recovery/closeout summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Safely retire the six stale divergent agent branches reviewed in the authoring chat, preserving every unique head as a verified archive tag and recording the recovery/supersession disposition without merging obsolete implementation back into current main.
- Completion boundary: Done when `branch_hygiene.py` has one explicit fail-closed path for operator-approved retirement of a named divergent `agent/*` ref at an exact expected SHA, that path is regression-covered, all six audited heads below have been archive-tagged and ledgered through the existing retirement machinery, the six remote branch refs are absent, and no donor implementation/art beyond the already-preserved Fast 01 South source master has been replayed into production.
- Current measured state:
  - `main@b57ab98d` already preserves the one irreplaceable donor source master at `custodian/asset_drop/source_work/operator/unarmed/attack/fast_01/south/fast_1_south.png` as LFS object `sha256:9b079688917b620d6fd46102e0ec5d6d36896fef416b7c676da36cc7a5a5723f`; runtime was intentionally unchanged.
  - Current `branch_hygiene.py --apply` retires landed/identical/ordinary archive candidates but classifies divergent `agent/*` refs as `ACTIVE`, so these six human-classified stale refs cannot currently be retired through the public CLI.
  - Exact audited remote heads:
    - `agent/operator-fast-chain-continuity@93e9604b166027aba27a7c3003aacff86970a09d`
    - `agent/twin-solaria-runtime-v1@f68f0ab049efbc6169692441a815b9ee08a094f3`
    - `agent/awakening-connector-04-05@fe3f3f7788bec3208f544c2be0e79c03384bfee6`
    - `agent/awakening-detail-assets-batch-01@66be9592722c3c67d5b12dfbc49237c7c5506440`
    - `agent/vaultwing-bonding-art-final-ingest@2eb4e7190a3bd5f50719e0c613782bac1cf21cc8`
    - `agent/visual-review-dropbox-handoff@b91659c63ff7786925dfe9f106c4134d8325f03e`
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
  5. After tests are green, retire exactly the six audited branch/SHA pairs above. Do not use a wildcard, branch-age heuristic, or broader cleanup pass.
  6. Record these disposition notes in `BRANCH_ARCHIVE.md`:
     - `operator-fast-chain-continuity`: high-resolution Fast 01 South donor master preserved on main at `b57ab98d`; normalized/canonical Fast 01 South and modular decomposition already live; remaining South Fast 02-04 continuity is owned by `operator-fast-chain-south-continuity`.
     - `twin-solaria-runtime-v1`: validated donor assets were selectively salvaged, then production `hub_twin_solaria` AuthoredLevel runtime landed and evolved on main; do not replay donor registry/import/runtime files.
     - `awakening-connector-04-05`: unique history is an obsolete visual-acceptance packet; current 04→05 ownership is `awakening-room-connectors-polish` and its refreshed downstream gates.
     - `awakening-detail-assets-batch-01`: useful source masters are preserved on main; old standalone publication/binding assumptions are superseded by current baked-only/not-ready Awakening consumption truth.
     - `vaultwing-bonding-art-final-ingest`: accepted donor art was selectively recovered and the later bond-greet closeout reached 24/24 bonding directions and 80/80 total Vaultwing runtime strips.
     - `visual-review-dropbox-handoff`: publisher/tests/docs landed on main and have since evolved, including bidirectional Dropbox handoff work; old branch must not overwrite newer workflow.
  7. Verify each expected `archive/<sanitized-branch>-<YYYYMMDD>` annotated tag resolves remotely to the exact audited head before accepting branch deletion. Verify all six `refs/heads/agent/...` refs are absent afterward.
- Preserve: All current active agent branches/worktrees/claims; all diagnostic refs; current `main`; all six archive heads; the already-preserved Fast 01 high-resolution source; current Twin Solaria, Awakening, Vaultwing, visual-review, and Operator production truth.
- Non-goals: No cherry-pick/merge from any donor branch. No gameplay, scene, Asset V2 publication, Operator runtime, Twin Solaria runtime, Awakening runtime, Vaultwing runtime, Dropbox transport behavior, dispatcher scheduling, or generic age-based cleanup changes.
- Acceptance:
  - explicit approved-retirement mode requires exact branch+SHA and is test-covered;
  - default hygiene behavior remains conservative;
  - six archive tags remotely verify at the six exact audited heads;
  - six stale remote agent refs are gone;
  - `BRANCH_ARCHIVE.md` has six truthful entries with successor/recovery notes;
  - no donor file is introduced to current production except the Fast 01 South source master already landed at `b57ab98d`;
  - `git diff --check` and focused agent-workflow tests pass.
- Validation: Run `python3 -m unittest custodian.tools.agent.test_branch_hygiene` first. Then the smallest directly affected workflow suite from `VALIDATION_RECIPES.md`; run a report-only hygiene pass before and after retirement and inspect exact branch/tag refs with `git ls-remote`. Finish with the packet/AI-context checks selected by changed files. No Godot or Moment Forge validation is required because runtime/content behavior is unchanged.
- Task overrides: `none`
- Deferred: Operator South Fast 02-04 art/runtime continuity is a separate packet. Do not solve it in this workflow cleanup.

## Handoff

- Next action: After this packet lands, claim `operator-fast-chain-south-continuity` when ready to perform the art/runtime continuity pass.
- Best starting files: `custodian/tools/agent/branch_hygiene.py`, its focused tests, `BRANCH_ARCHIVE.md`, and the six exact remote refs above.
- Blockers or open questions: None. If any audited branch head changes before execution, that branch is blocked for re-audit rather than force-retired.