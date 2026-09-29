# REVIEW: VISUAL VALIDATION ECONOMY TOOLING V1

- Workstream: `review-visual-validation-economy-tooling-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `visual-validation-economy-tooling-v1`
- Locks: `moment-forge-tooling`
- Review: `none`
- Review target workstream: `visual-validation-economy-tooling-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/VISUAL_VALIDATION_ECONOMY_TOOLING_V1.md`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that the landed visual-validation economy tooling reduces routine renderer/model-vision dependence without weakening deterministic presentation proof or subjective human gates.
- Review focus: generic probe compatibility; deterministic image metrics; cross-tick assertions; ROI/contact-sheet minimization; no simulation authority leakage; no hidden aesthetic scoring; direct-adopter usefulness for Awakening/Twin/Operator/Vaultwing; evidence reuse by paired review; preservation of existing Moment Forge scenarios and capture semantics.
- Acceptance: Findings-first review of live `main`. Prove existing scenarios remain compatible, metrics have deterministic synthetic positive/negative controls, direct-adopter no-capture runs expose the promised structured facts, and evidence mode produces compact ROI artifacts without requiring full-frame model inspection. Confirm subjective baseline/art-direction decisions remain human-owned. Blocking findings create the bounded correction pair; do not patch reviewed tooling inside this review workstream.
- Non-goals: Do not review the artistic quality of Awakening, Twin Solaria, Operator, or Vaultwing assets; do not generate new full visual baselines; do not expand into audio tooling or general CI redesign.
- Task overrides: `TASK OVERRIDE: review only with respect to the reviewed implementation; do not stage, commit, or push changes to the reviewed tooling implementation. Repository/document mutations required for the durable review receipt, required review closing summary, review-packet lifecycle/archive metadata, and any bounded follow-up correction/re-review packets are allowed.`

## Required Checks

1. Run the focused Moment Forge schema/probe/assertion/report tests and synthetic presentation-image metrics fixtures.
2. Confirm old scenario JSON remains valid without adding new required fields.
3. Prove cross-record assertions can compare equivalent presentation state across ticks/directions.
4. Prove the image metrics distinguish clean and intentionally broken alpha/matte/seam/diff fixtures without subjective scoring.
5. Run available direct adopters in `capture-mode none`; inspect structured JSON, not screenshots, as the primary evidence.
6. Run one representative evidence-mode adopter and verify it emits compact ROI/contact-sheet output plus metrics while preserving access to raw frames as secondary human evidence.
7. Confirm no tool mutates gameplay/simulation state and no metric is treated as collision/navigation/route authority.
8. Confirm paired-review documentation tells reviewers to reuse durable structured evidence instead of recapturing equivalent full-screen media.
9. Confirm no baseline or aesthetic/art-direction result is auto-approved.

## Human Gate

No human visual gate is required to review this tooling's technical correctness. Any question about whether a specific game scene or asset actually looks good belongs to that feature's human art review, not this tooling review.

## Handoff

- Next action: Auto-dispatch after `visual-validation-economy-tooling-v1` lands.
- Blockers or open questions: Dependency only.
