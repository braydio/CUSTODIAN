# Operator 2.5D Animation Viability Audit — closeout summary

Closed the refreshed read-only audit against the current-main migration authority. The report now separates the 69 production-reachable `legacy_96` families from the accepted `operator_2_5d_128` source. It records one authored canonical source (`unarmed/posture/idle_relaxed_01/full_body`, 8 directions x 15 frames x 128x128 cells, SHA-256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`) and the design lock SHA-256 `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`. The canonical source is not yet ingested or runtime-published; that belongs to the next canonical visual-contract packet.

The revised inventory excludes 24 non-live/catalog-only families, preserves current runtime-pixel matrices as legacy/fallback evidence, and ranks 69 live semantic families into seven slices. One source family already exists; the remaining baseline is 68 full-body family atlases / 544 direction-animation strips before any extra modular, weapon, or FX layers. The count is a planning floor; the canonical target plan must settle exact layers and future frame contracts.

No Operator art, source-work, runtime, manifest, SpriteFrames, sockets, timing, or Asset V2 family was changed. The three committed matrices remain evidence of existing legacy runtime coverage. The required LoP archive was absent locally and was not fetched; the now-locked design sheet made that non-blocking for this deterministic closeout.

Validation and diagnostics:

- `operator anim list unarmed --json` succeeded and showed the legacy relaxed-idle remains E/W `lower_body` + `upper_body`.
- Report consistency check passed: 69 legacy rows, one canonical source, 68 baseline atlases, 544 directional strips, seven slice counts totaling 69 families.
- All three matrix artifacts exist; JSON parses; `git diff --check` passed; `task_packet_index.py` passed.
- `check_ai_context.py` still reports 15 repository-wide findings outside this audit, including the canonical-contract packet missing `Change` and its paired review containing duplicate `Review modes`. Those findings were left for the successor packet owner; the archived audit packet itself passes the closeout receipt checks.
- No automated test suites were run; this task is a read-only report closeout and the packet calls for focused evidence checks rather than broad runtime validation.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: the dispatcher found a clean worktree from the earlier audit run; the active planning refresh also left authoring-metadata drift in the immediate successor packet pair.
- Root cause / contributing factors: the packet refresh arrived while a prior clean branch remained claimed, and repo-wide packet metadata checks are not yet green for the canonical successor.
- Prevention / pipeline improvement: inspect and resume clean existing workstreams, reread the refreshed packet, and require packet metadata checks before starting the successor.
- Tooling / docs drift discovered: `check_ai_context.py` reports 15 findings, including missing `Change` on `OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT.md` and duplicate `Review modes` on `REVIEW_OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT.md`.
- Follow-up: operator-2-5d-canonical-visual-contract
- What worked: current-main reachability evidence and the locked generation metadata made the canonical-vs-legacy split falsifiable.

## Next Handoff
- Next workstream: operator-2-5d-canonical-visual-contract
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: repo-wide packet validation identifies a missing required `Change` field in the canonical-contract packet and duplicate `Review modes` metadata in its paired review packet.
- Next action: repair the canonical-contract packet pair in the authoring chat, then claim the canonical visual-contract implementation and complete its paired review before refreshing WB25-1.
- Blockers or open questions: canonical source masters still need exact-byte intake/registration; no art direction questions remain open.
