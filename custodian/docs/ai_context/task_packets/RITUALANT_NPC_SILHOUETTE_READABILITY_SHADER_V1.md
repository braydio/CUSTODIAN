# RITUALANT — NPC SILHOUETTE READABILITY SHADER V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `ritualant-npc-silhouette-readability-shader-v1`
- Status: `blocked`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `ritualant-npc-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual`
- Paired review workstream: `review-ritualant-npc-silhouette-readability-shader-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `shader and alpha-compositing correctness with human-owned visual acceptance`
- Reviewed main: `6e38b5b948fa`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: `required`
- Goal: Make the production Forlorn-Ritualant legible against its busy authored chapel floor using a restrained, canon-consistent actor-local shader treatment, without changing gameplay or source sprites.
- Completion boundary: One actor-local sprite readability material, small optional procedural contact-shadow node only if needed, correct binding to the production AnimatedSprite2D, focused rendering/phase regressions, and human-approved close-up before/after evidence; no changes to scene/encounter geometry.
- Current measured state: The authored chapel `forlorn_ritualant_site.tscn` already instances `ForlornRitualantShaderFX` for room underlay/edge/haze, but `NPCs/ForlornRitualant/AnimatedSprite2D` uses the canonical sprite-frames resource without an actor-local material. `ForlornRitualantNPC._ready()` shows that AnimatedSprite2D and hides the legacy `Visual` cloth placeholder. User reports that the animated figure nearly disappears against dense ground artwork at gameplay zoom.
- Evidence: `custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn` production NPC/sprite node and existing room FX; `custodian/game/world/events/ash_bell/forlorn_ritualant_npc.gd` animation and phase transitions; `design/02_features/enemy_objective/FORLORN_RITUALANT_SHADER_FX.md`; `design/02_features/enemy_objective/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md`; `custodian/tools/validation/forlorn_ritualant_completion_smoke.gd`; user observation in the authoring chat.
- Task-specific authority: The authored Ritualant encounter design and Ash-Bell continuity presentation contract control lore and visual tone; the production NPC AnimatedSprite2D owns its sprite-local compositing; existing ForlornRitualantShaderFX continues to own room-wide cosmic underlay/edge/haze; ForlornRitualantNPC and ForlornRitualantSite remain phase/combat/dialogue authorities.
- Work surface: `custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn`; new or existing actor-local resource under `custodian/game/world/events/ash_bell/shaders/` and `materials/`; only minimal scene/presenter binding needed; focused Ritualant smoke and shader validation ownership in `custodian/tools/validation/validation_manifest.json` if a new test file is added.
- Change: Add one bounded actor-local visual readability pass, without changing any gameplay authority.
  1. Implement a Godot 4 `canvas_item` shader/material applied to the **existing production** `NPCs/ForlornRitualant/AnimatedSprite2D`. Keep sprite frame, origin, scale, animation ownership, art registration, and z-order intact. No use of the hidden legacy `Visual` as the rendered character.
  2. Make a perceptible but restrained separation: subtle midtone/value lift within the original silhouette and a thin **internal alpha-aware rim** biased toward cool ash-silver / pale bone-white. Preserve the source palette, original texture alpha, transparency, internal holes, and soft edge pixels. No solid outer stroke, unmasked full-body glow, screen-space post-process, or emissive billboard. Expose small inspector-tunable strength/tint values in the material, not gameplay state.
  3. Keep alpha sampling frame-safe for AnimatedSprite2D/AtlasTexture frames: no neighboring-frame bleed or out-of-bounds halo, including on the 128px encounter animation cells. Favor an internal edge treatment requiring no sprite padding; if sampling neighboring pixels, prove clamp/region handling on actual production frames. The original asset files and SpriteFrames resource remain untouched.
  4. If the rim/value pass alone does not separate lower robes from the floor, add **one** small actor-following procedural oval contact shadow beneath the figure, sourced from a shader or primitive rather than a new PNG. Keep it behind the sprite, above the floor, bounded to the NPC's footing, unobtrusive, and non-interactive; do not alter collision, floor art, room underlay, or map placement. Do not add an independent stagecraft/FX authority.
  5. Canonical art reading: the visible edge is residual pale light/ash discontinuity at the character's boundary where the nearby physical continuity intrusion distorts apparent separation from the chamber; the grounded dark contact is his physical presence on the ritual floor. This is **not** a new spell, shield, divine aura, Rift-status indicator, Ninth Bell manifestation, or assertion that White Thread emits light. Default treatment should read quietly in kneeling/dialogue as well as in combat; any phase adaptation must read existing NPC presentation state only and must not create or mutate encounter logic.
  6. Preserve all existing `kneel_idle`, `rise`, `hostile_idle`, attack, `dissolve`, and `death_violent` animation transitions. Existing death/dissolve alpha fades must still extinguish the entire silhouette/optional shadow, not leave a floating outline. Do not mutate the material globally across instances or override existing material/modulate ownership; no per-frame material allocation.
  7. Update only the active presentation design/context passages made inaccurate by the implementation; check for documentation drift against the actual scene and leave unrelated Ritualant north-egress, Static Asset V2, and Bridged Falls plans unchanged.
- Preserve: Dialogue proximity and click/interaction readability; White Thread hazard gaps/telegraphs and tension rules; Stilling Pin and Ninth Answer canon; actual ordinary broken chapel bell; hostility, combat hitbox, animation frame count/timing, dissolution, rendered room/cosmic FX, authored camera and scene collision/navigation, NPC transform and z-index, all existing art masters and Asset V2 provenance.
- Non-goals: No re-illustration/recoloring of source PNGs; no new asset family or raster intake; no global lighting/camera changes; no extra enemy status UI; no damage/AI/boss difficulty changes; no north-egress/Highlands work, broader room restyling, other NPC shader system, or audio work.
- Acceptance: At the unchanged production camera/zoom and identical scene state, the Ritualant is distinguishable from its busy chapel floor without obvious cartoon outlining or false glow; original animation alpha and sprite frames remain authoritative; no edge artifacts/atlas bleed; no unintended extra shadow after fade/dissolve; scene drawing has no gameplay semantics; all existing Ritualant completion/phase assertions remain green. Tuning is modest and renderer proof is externally **approved** by user/ChatGPT, not self-certified by Codex.
- Validation: Begin with deterministic scene/resource assertions: shader bound only to production AnimatedSprite2D; uniforms bounded and instance-safe; alpha/color preservation including transparent pixels and texture-region borders; same scene geometry/collision, animation IDs, renderer ordering, no duplicate drawable when dissolved. Extend the focused existing `res://tools/validation/forlorn_ritualant_completion_smoke.gd` or add a narrowly named presentation smoke; run `res://tools/validation/levels/forlorn_ritualant_underground_smoke.gd` for authored integration and `python3 custodian/tools/validation/run_validation.py --changed --json` only after focused checks. For final pixel proof, take one **small ROI before/after comparison** of kneeling at original gameplay camera/zoom on the same chapel floor; include one hostile/attack or dissolve alpha keyframe only if needed to falsify phase safety (no more than two contact-sheet compositions, no video). Use `custodian/tools/iteration/publish_review_artifacts.py --important --reason "Ritualant sprite/floor silhouette separation requires human art-direction approval" --authoring-chat https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20` with currently supported CLI flags and report `/CUSTODIAN/visual_review/ritualant-npc-silhouette-readability-shader-v1/<run-id>/REVIEW_MANIFEST.json`. Ask reviewer: (a) can you locate the kneeling actor instantly at normal zoom? (b) does the effect read as residual ash/continuity separation rather than magic outline? (c) does hostile/dissolve still look natural? Stop for subjective approval; delete reviewed transport evidence using publisher-provided cleanup command afterward. Run `git diff --check` and scoped closeout validations per live AGENTS.
- Task overrides: `none`
- Deferred: Final aesthetic strength and any extra variants await human approval of the compact capture; future wider presentation/shader standardization is out of scope.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `Implementation is present and objectively validated; the final aesthetic acceptance remains pending human review.`
- Completion boundary satisfied: `No. The packet requires human approval of the paired ROI before implementation closeout.`
- Acceptance satisfied: `Mechanical and runtime contracts pass. Human visual acceptance is not yet recorded.`
- Superseded/legacy production path disposition: `The hidden legacy Visual placeholder remains hidden and unchanged; production AnimatedSprite2D remains the sole Ritualant sprite.`
- Evidence: `forlorn_ritualant_presentation PASS; forlorn_ritualant_runtime PASS; forlorn_ritualant_underground_smoke PASS; traversal/forlorn_ritualant_completion capture-mode none PASS; validation run --changed --json PASS (42/42). Final before/after ROI is published at /CUSTODIAN/visual_review/ritualant-npc-silhouette-readability-shader-v1/ritualant-readability-human-gate/REVIEW_MANIFEST.json.`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: `The original Moment Forge completion fixture kept its camera near the lift, leaving the Ritualant offscreen; the first shader pass also multiplied the sampled texture twice, and a reserved shader identifier prevented compilation.`
- Root cause / contributing factors: `The fixture camera did not follow authored Operator placement, so initial captures compared an unrelated foreground object. Renderer capture exposed the shader compile and COLOR-input contract issues before review.`
- Prevention / pipeline improvement: `The fixture now follows the Operator at scene commands, and the focused presentation smoke checks production binding, per-scene material isolation, canonical animations, atlas bounds, no neighbor sampling, and alpha pass-through. A dedicated short Moment Forge scenario captures matched pre/post material frames.`
- Tooling / docs drift discovered: `The authored Underground smoke still expected the retired lower-lift Y=1670; live LOWER_LIFT_DOCK/SPAWN_DESCENT_LANDING authority is Y=1696. Updated only that stale assertion, not scene geometry.`
- Follow-up: `human-required`

## Handoff
- Next workstream: `review-ritualant-npc-silhouette-readability-shader-v1`
- Next packet state: `human-required`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Summary backlink: Include this exact Authoring chat URL in every durable implementation/review/correction/recovery/closeout summary and final Next Handoff.
- Refresh reason: `none`
- Next action: `Review the published matched kneeling ROI at the original gameplay zoom. Decide whether the actor is immediately legible, the edge reads as ash/continuity separation rather than magic, and the treatment remains natural in hostile/dissolve phases. After approval, resume and finish this implementation through workstream.py, then allow the paired review to run in fresh context.`
- Blockers or open questions: `Human-owned visual approval is outstanding; do not close AP2-equivalent implementation acceptance or launch the paired review before that decision.`
