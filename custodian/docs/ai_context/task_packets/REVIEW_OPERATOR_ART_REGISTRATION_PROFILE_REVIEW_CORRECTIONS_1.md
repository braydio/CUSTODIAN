# REVIEW: OPERATOR ART REGISTRATION PROFILE REVIEW CORRECTIONS 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-art-registration-profile-review-corrections-1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-art-registration-profile-review-corrections-1`
- Locks: `operator-art-agent, operator-source-normalization`
- Review: `none`
- Review target workstream: `operator-art-registration-profile-review-corrections-1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_ART_REGISTRATION_PROFILE_REVIEW_CORRECTIONS_1.md`
- Reviewed main: `907dc2bf0`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Goal: Independently verify that correction 1 binds production to the approved normalization plan and closes the Workbench registration-report evidence gap without introducing scale-normalization or artistic-enforcement claims into Workbench.
- Reviewed implementation acceptance: Correction packet acceptance for findings R0-01 and R0-02.
- Review evidence: Mutate an in-bounds plan field after approval and verify converter/Source Session rejection; verify a fresh explicit replan succeeds and invalidates old proof; inspect Workbench report JSON for coordinates/residuals/profile hash and its no-normalization declaration; verify pose residuals remain advisory.
- Correction threshold: Keep R0-01 open if any valid plan mutation can still reach verified/handoff state. Keep R0-02 open if report fields are absent, misleading, or imply a scale transform not performed by Workbench. Create further correction work only for confirmed correctness defects or material evidence gaps.
- Focused validation: Run the correction smoke, Source Session smoke, semantic smoke, MCP smoke, and Aseprite guide smoke when available; inspect changed-file unit validation.
- Review focus:
  - expected-plan digest is independently bound and checked before production conversion/verification/review/handoff;
  - a legitimate replan has explicit state transitions and stale evidence invalidation;
  - byte-equivalent crisp replay still holds;
  - Workbench landmarks/residuals use the right coordinate space and disclose the absence of Source Session normalization;
  - artistic deviations remain advisory;
  - no production art/runtime/gameplay changes.
- Acceptance: Produce a findings-first review of correction 1 on live `main`, recording R0-01 and R0-02 dispositions and any new findings with stable `R1-NN` IDs. Do not patch reviewed implementation code.
- Non-goals: Revisit profile coordinates, normalize production art, alter gameplay, or broaden review beyond these findings and direct regressions.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim after correction 1 is complete and archived on `origin/main`.
2. Review the landed plan-digest lifecycle and Workbench report coordinate contract.
3. Reproduce both original findings as negative controls before checking the corrected paths.
4. Confirm the parent profile and v1 compatibility smokes remain green.
5. Record the correction review and finish through the lifecycle.

## Handoff

- Next action: Auto-dispatch after correction 1 lands.
- Blockers or open questions: none.
