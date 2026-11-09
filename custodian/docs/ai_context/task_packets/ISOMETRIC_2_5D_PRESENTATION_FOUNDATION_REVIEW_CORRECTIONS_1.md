# CORRECTION: Isometric 2.5D Presentation Foundation Review Findings

- Packet schema: `custodian.task_packet.v2`
- Workstream: `isometric-2-5d-presentation-foundation-review-corrections-1`
- Authoring handoff: `auto`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `review-isometric-2-5d-presentation-foundation`
- Locks: `world-presentation, presentation-experiments`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime`
- Paired review workstream: `review-isometric-2-5d-presentation-foundation-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `675ccf726bb79397b7242ef3059971a6f1a39448`
- Parent implementation: `isometric-2-5d-presentation-foundation`; `custodian/docs/ai_context/task_packets/archived/ISOMETRIC_2_5D_PRESENTATION_FOUNDATION.md`
- Parent review: `review-isometric-2-5d-presentation-foundation`; `custodian/docs/ai_context/task_packets/archived/REVIEW_ISOMETRIC_2_5D_PRESENTATION_FOUNDATION.md`
- Findings addressed: `R0-01, R0-02`
- Affected acceptance: Effective draw sorting uses the ground/base anchor and its configured sort offset; a focused runtime fixture proves real Y-sort order while elevated visuals overlap.
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Goal: Make the profile's sort-anchor offset affect Godot's actual Y-sort result and prove the result with a falsifiable overlapping runtime fixture.
- Completion boundary: Correct the anchor-to-renderer sort wiring and strengthen the existing focused fixture/smoke with overlapping, distinguishable visuals, effective ordering assertions and negative controls. No consumer migration is part of this correction.
- Current measured state: `get_sort_world_position()` returns `global_position + profile.sort_anchor_offset`, but no production consumer reads it and `apply_profile()` does not forward the offset to the renderer's Y-sort authority. Existing fixture visual polygons do not overlap; the smoke only checks helper values and geometric extents.
- Evidence: Archived parent review packet finding R0-01/R0-02; `custodian/game/world/presentation/isometric_2_5d/isometric_visual_anchor_2d.gd:24-57`; `custodian/tools/validation/isometric_2_5d_presentation_foundation_smoke.gd:72-82`; fixture polygons at `custodian/tools/validation/fixtures/isometric_2_5d_presentation_foundation.tscn`.
- Task-specific authority: `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`; parent implementation packet and archived review receipt.
- Work surface: Isometric visual anchor, its existing fixture/smoke, and only the directly required validation manifest/docs if the smoke contract changes.
- Required correction: For R0-01, apply the supported sort-offset component to the actual engine Y-sort input (or an equivalent renderer-consumed base-anchor mechanism); document behavior for unsupported offset axes and preserve the ground root as the gameplay contact. For R0-02, create intersecting/overlapping distinguishable visuals under Y-sorted anchors, assert effective rear/front draw order after changing the profile offset, reverse relevant sibling/root order to demonstrate the engine result is deterministic, and add a negative control that fails when offset wiring is disabled. Keep elevation isolated to `VisualRoot`.
- Preserve: Ground/global XY, collision, navigation, movement, camera, semantic depth bands, `RoofOccluder2D`, actor shadow ownership, and the existing no-3D boundary.
- Non-goals: No production scene retrofit, art or asset work, global depth authority, camera changes, movement/collision/navigation edits, or gameplay elevation.
- Acceptance:
  1. A nonzero profile sort offset changes the actual engine Y-sort key/order, not only a helper result; zero offset retains ground-root ordering.
  2. Changing visual elevation alone leaves the anchor/world ground position and effective base sort point unchanged.
  3. The focused runtime fixture contains overlapping distinguishable geometry and demonstrates the expected visible/draw order for base and offset cases.
  4. A negative control with the sort-offset application bypassed fails the focused smoke; reversing sibling construction order does not invalidate the claimed geometry-based order.
  5. Collision/navigation, semantic band mapping, RoofOccluder2D reuse and the 2D-only runtime remain unchanged.
- Validation: Run `python3 custodian/tools/validation/run_validation.py --test isometric_2_5d_presentation_foundation --json` after import succeeds; run the direct focused smoke as a diagnostic; exercise the explicit sort-offset/elevation mutation negatives; run changed-file validation and packet authoring/pairing checks. Record infrastructure failures separately; do not waive a failed sort contract.
- Task overrides: `none`
- Deferred: Downstream Forum/Sundered consumer integration remains outside this correction.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `low`
- What went wrong: The parent smoke passed without exercising actual render order; registered import validation hit a TLS handshake error.
- Root cause / contributing factors: Validation asserted a computed helper and non-overlapping fixture geometry rather than engine-observable ordering.
- Prevention / pipeline improvement: Require an overlapping draw-order fixture plus a mutation control whenever an acceptance claim concerns actual rendering order.
- Tooling / docs drift discovered: The exposed Vector2 sort offset currently has no consumer in the renderer path.
- Follow-up: fixed-in-scope
- What worked: Independent inspection matched the runtime path to the focused smoke and isolated two linked findings.

## Next Handoff
- Next workstream: `review-isometric-2-5d-presentation-foundation-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac3be53-1d4c-83e9-9d63-d48ab4035de4`
- Refresh reason: `none`
- Next action: Implement R0-01/R0-02, land the correction, then claim the fresh paired re-review.
- Blockers or open questions: none; auto handoff remains subject to the repository authoring workflow.
