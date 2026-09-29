# REVIEW: AWAKENING HANDOFF READINESS + ART CONVERGENCE V1

- Workstream: `review-awakening-handoff-readiness-art-convergence-v1`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `awakening-handoff-readiness-art-convergence-v1`
- Locks: `awakening-runtime, awakening-art-registration`
- Review: `none`
- Review target workstream: `awakening-handoff-readiness-art-convergence-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AWAKENING_HANDOFF_READINESS_ART_CONVERGENCE_V1.md`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the landed Awakening convergence slice against its registration, seam, progression, asset-consumption, and South Reach handoff-readiness contract.
- Review focus: Exact Layout-to-art registration; no speculative resizing; preservation of the corrected 1024×576 04→05 connector; late-seam renderer evidence; Road/Approach join; Gate pylon alignment and central-body non-collision decision; exactly-once console+P-9 completion; production-named handoff seam without scene transition; no duplicate fixture rendering; no Contract prewarm; documentation truth.
- Acceptance: Produce a findings-first independent review of live `main`. Either record a clean `passed` receipt or concrete findings. Blocking findings create the bounded correction pair through the normal review lifecycle. Do not patch reviewed implementation/runtime code inside this review workstream.
- Non-goals: Do not implement the Hub, change Twin Solaria gameplay, create missing P1 art, redesign the Layout, enlarge Gate center collision, or add procgen/startup work during review.
- Task overrides: `TASK OVERRIDE: review only with respect to the reviewed implementation; do not stage, commit, or push changes to it. Repository/document mutations required for the review receipt and any follow-up correction/review packets are allowed.`

## Required Review Evidence

1. Recompute all nine zone art rectangles from live Layout envelopes and live scene sprites; prove exact `grow(64)` registration and underlay/foreground parity.
2. Prove the 04→05 runtime state is `full_plate_underlay` at 1024×576 centered at `(352,-2464)`, with no live 832×384 binding.
3. Inspect focused visual evidence for all mandatory seams and the optional Late Service branch. Reject any hard crop edge, doubled threshold, missing walkable floor, or foreground-over-Operator contradiction.
4. Verify the Approach/Road seam uses the existing Road offset, y=-6144 anchor, 192 px south gap, and presentation-only correction if any correction was needed.
5. Verify Gate west/east pylon blockers remain 240×496 and the central visual-route mismatch was not “fixed” by blocking the route.
6. Exercise South Reach before console acknowledgment, after console but before P-9, and after both. Only the final case may complete.
7. Prove the production-named completion event emits once and any retained `blockout_completed` compatibility emission comes from the same authority.
8. Prove no scene change, Hub transition, Twin transition, or Contract generation is added.
9. Reconcile the live generated asset catalog with the documented BAKED_ONLY / specialized / partial / unpublished classifications.
10. Confirm CURRENT_STATE and related docs no longer describe the rejected connector or missing Road art as current truth.
11. Confirm existing Awakening geometry/progression, Road production, asset-pipeline, and changed-file validation remain green.

## Human Decision Gate

If the central Gate sealed-body composition still visually hides a legal Operator position and the only credible fix requires a different authored Gate state/composition, record that exact evidence as `human_required`. Do not invent art or move collision.

Aesthetic preferences beyond objective seam/registration correctness are not automatic review failures.

## Handoff

- Next action: on pass, the next integration packet may implement Awakening→Hub world-context transition and the persistent Hub runtime host.
- Blockers or open questions: blocked only by `awakening-handoff-readiness-art-convergence-v1`.
