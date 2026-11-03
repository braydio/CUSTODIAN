# RITUALANT — NPC SILHOUETTE READABILITY SHADER V1 RECOVERY 2

- Packet schema: `custodian.task_packet.v2`
- Workstream: `ritualant-npc-silhouette-readability-shader-v1-recovery-2`
- Category: `assets-art`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `ritualant-npc-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual`
- Paired review workstream: `review-ritualant-npc-silhouette-readability-shader-v1-recovery-2`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `shader and alpha-compositing correctness with human-owned visual acceptance`
- Reviewed main: `ecd4ac324d42e7bc8183fcd7ea0d05732c75ec46`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0
- Visual review: `required`
- Goal: Make the production Forlorn-Ritualant legible against its busy authored chapel floor using a restrained, canon-consistent actor-local shader treatment, without changing gameplay or source sprites.
- Completion boundary: One actor-local sprite readability material, small optional procedural contact-shadow node only if needed, correct binding to the production AnimatedSprite2D, focused rendering/phase regressions, and the previously human-approved close-up evidence and focused phase regressions; no changes to scene/encounter geometry.
- Current measured state: The authored chapel `forlorn_ritualant_site.tscn` already instances `ForlornRitualantShaderFX` for room underlay/edge/haze, but `NPCs/ForlornRitualant/AnimatedSprite2D` uses the canonical sprite-frames resource without an actor-local material. `ForlornRitualantNPC._ready()` shows that AnimatedSprite2D and hides the legacy `Visual` cloth placeholder. User reports that the animated figure nearly disappears against dense ground artwork at gameplay zoom.
- Evidence: `custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn` production NPC/sprite node and existing room FX; `custodian/game/world/events/ash_bell/forlorn_ritualant_npc.gd` animation and phase transitions; `design/02_features/enemy_objective/FORLORN_RITUALANT_SHADER_FX.md`; `design/02_features/enemy_objective/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md`; `custodian/tools/validation/forlorn_ritualant_completion_smoke.gd`; user observation in the authoring chat.
- Task-specific authority: The authored Ritualant encounter design and Ash-Bell continuity presentation contract control lore and visual tone; the production NPC AnimatedSprite2D owns its sprite-local compositing; existing ForlornRitualantShaderFX continues to own room-wide cosmic underlay/edge/haze; ForlornRitualantNPC and ForlornRitualantSite remain phase/combat/dialogue authorities.
- Work surface: `custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn`; new or existing actor-local resource under `custodian/game/world/events/ash_bell/shaders/` and `materials/`; only minimal scene/presenter binding needed; focused Ritualant smoke and shader validation ownership in `custodian/tools/validation/validation_manifest.json` if a new test file is added.
- Publication inputs: `design/02_features/enemy_objective/FORLORN_RITUALANT_SHADER_FX.md`; `design/02_features/enemy_objective/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md`; `custodian/docs/ai_context/reports/ritualant_npc_silhouette_readability_shader_v1_human_visual_decision.md`; `custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn`; `custodian/game/world/events/ash_bell/forlorn_ritualant_npc.gd`; `custodian/tools/validation/forlorn_ritualant_completion_smoke.gd`; `custodian/tools/validation/levels/forlorn_ritualant_underground_smoke.gd`; `custodian/tools/validation/validation_manifest.json`; `custodian/tools/validation/run_validation.py`; `custodian/tools/validation/fixtures/forlorn_ritualant_completion_moment.gd`; `custodian/tools/iteration/godot/moment_action_driver.gd`; `custodian/tools/iteration/publish_review_artifacts.py`; `custodian/tools/pipelines/godot_import_preflight.py`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`
- Source-port provenance: Recovery-1 source commit `8c9b115ec7caf512fa1e37f9dd3dade665363e8f` is preserved on its remote branch and is read-only comparison material. Recovery-2 recreates the required source outputs in its own clean history from current main; no recovery-1 lifecycle, packet, archive, merge, or validation metadata is imported. The underground smoke assertion must expect the production-authored Ritualant spawn Y of `1696`.
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
- Acceptance: At the unchanged production camera/zoom and identical scene state, the Ritualant is distinguishable from its busy chapel floor without obvious cartoon outlining or false glow; original animation alpha and sprite frames remain authoritative; no edge artifacts/atlas bleed; no unintended extra shadow after fade/dissolve; scene drawing has no gameplay semantics; all existing Ritualant completion/phase assertions remain green. Tuning is modest and renderer proof reuses the exact user-approved October 17 candidate and is independently checked against the receipt; Codex does not reopen the subjective sign-off.
- Validation: Run deterministic production-scene/resource assertions first: the shader/material is bound only to the production AnimatedSprite2D, uniforms are bounded and instance-safe, source alpha and transparent pixels remain intact, the 128px atlas cells have no neighboring-frame bleed, scene geometry/collision/animation IDs/z-order are unchanged, and fades/dissolve remove the full silhouette and any optional contact shadow. The implementation may add a narrowly scoped presentation smoke and register it in the existing validation manifest as task outputs. At claim time, first require `python3 custodian/tools/pipelines/godot_import_preflight.py --project-dir custodian` to pass on repaired main; then run the existing `res://tools/validation/forlorn_ritualant_completion_smoke.gd` and `res://tools/validation/levels/forlorn_ritualant_underground_smoke.gd`, focused alpha/phase regressions, and `python3 custodian/tools/validation/run_validation.py --changed --json` against the exact implementation source. Reuse the existing small ROI and human decision receipt at `custodian/docs/ai_context/reports/ritualant_npc_silhouette_readability_shader_v1_human_visual_decision.md`; do not recapture or re-request artistic approval unless a concrete evidence defect or material visual change is found. Run `git diff --check` and record the genuine current-source validation report for canonical `workstream.py finish`.
- Task overrides: `none`
- Deferred: Any future character redraw or wider shader standardization is separate and out of scope; the existing approved treatment remains the target.

## Exact task outputs

These are implementation outputs to create or modify in the claimed recovery-2 worktree; they are not unpublished prerequisites. The `Publication inputs:` above are already-tracked design, source, evidence and validation dependencies on repaired main.

- `custodian/game/world/events/ash_bell/forlorn_ritualant_site.tscn` (production AnimatedSprite2D binding only)
- `custodian/game/world/events/ash_bell/materials/ritualant_silhouette_readability_material.tres`
- `custodian/game/world/events/ash_bell/shaders/ritualant_silhouette_readability.gdshader`
- `custodian/game/world/events/ash_bell/shaders/ritualant_silhouette_readability.gdshader.uid`
- `custodian/tools/validation/forlorn_ritualant_presentation_smoke.gd`
- `custodian/tools/validation/forlorn_ritualant_presentation_smoke.gd.uid`
- `custodian/tools/validation/levels/forlorn_ritualant_underground_smoke.gd` (correct expected Ritualant spawn Y to 1696)
- `custodian/tools/validation/validation_manifest.json` (register the focused presentation smoke)
- `design/02_features/enemy_objective/FORLORN_RITUALANT_SHADER_FX.md`

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill>`
- Completion boundary satisfied: `<fill>`
- Acceptance satisfied: `<fill>`
- Superseded/legacy production path disposition: `<fill>`
- Evidence: `<fill>`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill>`
- Friction severity: `<fill>`
- What went wrong: `<fill>`
- Root cause / contributing factors: `<fill>`
- Prevention / pipeline improvement: `<fill>`
- Tooling / docs drift discovered: `<fill>`
- Follow-up: `<fill>`

## Handoff
- Next workstream: `review-ritualant-npc-silhouette-readability-shader-v1-recovery-2`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae7eb07-c554-83e9-911a-1335e640e4d0
- Summary backlink: Include this exact Authoring chat URL in every durable implementation/review/correction/recovery/closeout summary and final Next Handoff. Original visual-decision conversation: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20.
- Refresh reason: `none`
- Next action: After human acceptance and successful implementation closeout, independently review the landed shader, regression evidence, and approved ROI presentation.
- Blockers or open questions: The October 17 human visual decision is already recorded; objective validation and independent review remain required.


## Supersession and donor provenance

This recovery-2 pair is authorized by the project owner in the exact Authoring chat above. It replaces blocked `ritualant-npc-silhouette-readability-shader-v1-recovery-1`, whose implementation source commit `8c9b115ec7caf512fa1e37f9dd3dade665363e8f` was merged with invalid historical main-sync state `d06bde0800aa494e7c203ebbeff79bab6b920174`. Canonical finish cannot accept that historical merge because its required post-sync import preflight is invalid; the upstream import-sidecar repair is now on main at `ecd4ac324d42e7bc8183fcd7ea0d05732c75ec46`. Recovery-1 is superseded, blocked/manual, not complete, not accepted, and not a PASS. Recovery-2 has no dependency on recovery-1 or its paired review and starts from repaired current `origin/main`.

The source commit above is preserved read-only provenance, not an indispensable external input: this packet explicitly tasks Recovery-2 with creating/porting the production shader, material, scene binding, smoke coverage, manifest entry, underground Y=1696 correction, and presentation documentation. All other required authority and validation inputs are enumerated in `Publication inputs:` and are tracked on current main. Preserve the October 17 approval of candidate `03678c0af88caf911166040a06fba460bcf4d2e0` documented in `custodian/docs/ai_context/reports/ritualant_npc_silhouette_readability_shader_v1_human_visual_decision.md` and its original visual-decision conversation https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20. Do not reopen that subjective approval.
