# REVIEW: OPERATOR ART REGISTRATION PROFILE

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-art-registration-profile`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-art-registration-profile`
- Locks: `operator-art-agent, operator-source-normalization, operator-aseprite-tooling`
- Review: `none`
- Review target workstream: `operator-art-registration-profile`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_ART_REGISTRATION_PROFILE.md`
- Reviewed main: `907dc2bf0`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that Operator registration geometry is now one truthful machine-readable authority shared by Source Session, Art Agent/MCP, Aseprite, and the required crisp pixelart production entrypoint, without introducing per-frame scale, pose flattening, guide leakage, or a second publication/normalization authority.
- Reviewed implementation acceptance: The archived implementation packet's complete acceptance contract: exact approved 96x96 profile coordinates/provenance; compatible v1 behavior; one landmark-derived global scale; clipping-fail behavior instead of scale shrink; shared anchor placement with preserved pose motion; exact converter-plan replay through `pixelart --choose 1`; verified crisp-only profile handoff; non-exporting Aseprite guide; structured registration reports/overlays; confined CLI/MCP surfaces; advisory artistic QA; and truthful active-doc/packet state.
- Review evidence: Reuse the implementation's profile fixture results, transform/scale observation JSON, clipping negative control, crisp alias-vs-Source candidate hash equality, guide clean-render hash proof, MCP schema output, and compact registration overlay. Gather new rendered evidence only if durable implementation evidence cannot establish an acceptance criterion.
- Correction threshold: Create correction work only for a confirmed acceptance/correctness defect or an evidence gap that prevents confidence in required acceptance. Route optional improvements/generalized art tooling to next-slice/deferred. Subjective questions about whether the resulting Operator looks aesthetically ideal remain `human_required`, not automatic corrections, unless an objective registration contract is violated.
- Focused validation: Re-run `operator_art_registration_profile_smoke.py`, `operator_art_source_smoke.py`, `operator_art_agent_semantic_smoke.py`, `operator_art_agent_mcp_smoke.py`, and the Aseprite guide/clean-render test when available. Inspect one profile-mode plan and one legacy v1/contain plan; verify the converter's plan replay and production proof; verify `qa.py` does not hard-fail a deliberate recoil landmark deviation. Use changed-file validation only after focused checks.
- Review focus:
  - one authority for numeric guide geometry, no duplicated magic registration numbers;
  - exact source/profile/plan provenance and stale-plan rejection;
  - weighted-median shared scale and no hidden per-frame scale;
  - equipment/clipping negative control fails rather than shrinking body scale;
  - shared registration preserves intentional motion and leaves frame `dx/dy` explicit;
  - mandatory production path remains `pixelart --choose 1`, with no MCP shell escape;
  - `__ART_GUIDE_` never enters clean render/export/publish;
  - old Source Sessions/plans remain readable;
  - artistic profile/tolerances remain advisory;
  - blocking-art refresh packet remains safely gated until fresh re-derivation.
- Acceptance: Produce a findings-first independent review of live `main`. Record a `passed` receipt or concrete findings. Give each finding a stable cycle-scoped ID (`R<cycle>-<NN>`) and required class, domain, affected acceptance, evidence, disposition, and rationale. Blocking defects/material evidence gaps create `operator-art-registration-profile-review-corrections-<n>` plus its paired review packet. Do not patch reviewed implementation code.
- Non-goals: Do not adjust the approved guide coordinates, repaint/re-normalize production animations, approve a subjective visual baseline, expand the system to non-Operator characters, implement auto-splitting, or fix reviewed implementation directly.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after `operator-art-registration-profile` is complete and archived on `origin/main`.
2. Review the archived packet/closing summary, active Art Agent/Profile/Style Bible authority, and the landed focused diff.
3. Prefer structured transform/profile/hash evidence; use the compact registration overlay only where geometry cannot be proven numerically.
4. Verify both positive profile-mode normalization and negative clipping/stale-plan/pose-flattening cases.
5. Record the independent review receipt and use the standard correction lifecycle only for acceptance-blocking defects/evidence gaps.

## Handoff

- Outcome: Review found two correction-worthy acceptance gaps, R0-01 and R0-02, recorded in the archived implementation packet's Independent Review receipt and `REVIEW_OPERATOR_ART_REGISTRATION_PROFILE_CLAUDE_SUMMARY.md`.
- Next action: Claim `operator-art-registration-profile-review-corrections-1` after this review lands and archives.
- Blockers or open questions: The profile implementation is landed, but the correction workstream must close plan-tamper acceptance and Workbench report evidence before those claims are considered satisfied.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: Parent validation omitted a negative control for an edited in-bounds production plan and did not assert Workbench report projections/residuals.
- Root cause / contributing factors: Converter proof records the digest only after reading the plan; Workbench report invokes the profile report without a transform plan.
- Prevention / pipeline improvement: Added bounded correction work for both findings and a paired post-land review contract.
- Tooling / docs drift discovered: The graph database was absent in the clean review checkout and its minimal build did not complete; direct source inspection and independent fixture reproduction supplied review evidence.
- Follow-up: `operator-art-registration-profile-review-corrections-1`
- What worked: A separate temporary fixture independently reproduced plan acceptance after changing `destination_x` while retaining passing project smokes.
