# Ritualant NPC silhouette readability shader V1 — execution handoff

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20

## Result

Implemented a scene-local CanvasItem ShaderMaterial on the production
`NPCs/ForlornRitualant/AnimatedSprite2D`. It applies a bounded midtone lift and
thin internal ash-silver rim. It samples the current fragment only, derives the
edge from alpha derivatives, and passes incoming sprite/modulate alpha through
unchanged. The original SpriteFrames, sprite registration, transform, z-order,
NPC phase logic, collision, and room-wide ForlornRitualantShaderFX authority
remain intact. No optional shadow was needed for the current review candidate.

The Moment Forge encounter fixture now follows its scripted Operator placement.
It previously left the Ritualant at world Y=-1274 outside the fixed camera view,
so the earlier “before/after” run showed unrelated scenery. A dedicated compact
scenario now holds the kneeling actor, floor, and camera fixed while toggling
only the actor-local material. The run used for final review is:

`validation/forlorn_ritualant_silhouette_readability`

The publisher manifest is:

`/CUSTODIAN/visual_review/ritualant-npc-silhouette-readability-shader-v1/ritualant-readability-human-gate/REVIEW_MANIFEST.json`

Questions for the reviewer:

1. At normal gameplay zoom, is the kneeling Ritualant immediately locatable?
2. Does the pale edge read as residual ash/continuity separation rather than a
   magic outline or aura?
3. Does the treatment remain natural in hostile and dissolve/death phases?

## Validation

- `forlorn_ritualant_presentation`: PASS.
- `forlorn_ritualant_runtime`: PASS (existing dialogue/combat/phase completion
  smoke).
- `forlorn_ritualant_underground_smoke.gd`: PASS after correcting its stale
  lower-lift spawn expectation from Y=1670 to the live named dock authority
  Y=1696; no geometry was changed.
- `traversal/forlorn_ritualant_completion`, capture mode `none`: PASS.
- `validation/forlorn_ritualant_silhouette_readability`, capture mode
  `evidence`: stable assertions PASS; matched frame delta is localized to the
  actor ROI.
- `run_validation.py --changed --json`: PASS, 42 selected / 42 passed.
- `git diff --check`: PASS.

The shader was corrected after renderer evidence caught double texture
application and a reserved identifier that failed compilation. The final
captured candidate compiles successfully and preserves alpha/modulate coverage.

## Human gate

Implementation remains partial until the user approves the published ROI. Do
not archive the packet, land the workstream, or launch its paired review before
that decision. Review evidence uses delete-after-review retention.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: The original capture fixture kept the Ritualant offscreen, and the initial shader had a compile error plus double-applied texture color.
- Root cause / contributing factors: The fixed camera did not follow scripted Operator placement; renderer evidence was needed to catch the COLOR/texture contract and shader parser behavior.
- Prevention / pipeline improvement: Add a short matched-state capture scenario and keep the presentation smoke's atlas, instance-isolation, alpha pass-through, and shader source contracts.
- Tooling / docs drift discovered: The authored Underground smoke expected stale Y=1670 while the live lower-lift dock is Y=1696.
- Follow-up: human-required
- What worked: Renderer-backed two-state capture revealed both the offscreen fixture and shader contract defects before the human gate.

## Next Handoff
- Next workstream: review-ritualant-npc-silhouette-readability-shader-v1
- Next packet state: human-required
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Refresh reason: none
- Next action: Obtain human visual approval of the linked ROI, then resume implementation closeout and launch the fresh paired review.
- Blockers or open questions: Human visual acceptance remains outstanding.
