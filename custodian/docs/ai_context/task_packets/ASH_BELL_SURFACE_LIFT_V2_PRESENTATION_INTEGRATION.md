# ASH BELL SURFACE LIFT V2 PRESENTATION INTEGRATION
- Packet schema: `custodian.task_packet.v2`
- Workstream: `ash-bell-surface-lift-v2-presentation-integration`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-ash-bell-surface-lift-v2-asset-intake, review-ash-bell-lift-dev-quick-launch`
- Locks: `ash-bell-lift-art, ash-bell-lift-site, world-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual, asset-pipeline`
- Paired review workstream: `review-ash-bell-surface-lift-v2-presentation-integration`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `asset/route lifecycle or presentation cross-authority; independent post-land verification required`
- Reviewed main: `b224e51a295e19ef4ae15111c1517dc6a79e70ea`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: `conditional`
- Goal: Replace the Ash-Bell lift's legacy industrial presentation with approved rail-free deck/projectors/safety-field VFX across surface and underground, leaving every traversal and gameplay authority unchanged.
- Completion boundary: Reuse the shared `ash_bell_lift_platform_assembly.tscn` for both surface presentation and lower Underground lift, wire approved Asset V2 runtime texture states into idle/arming/engaged/releasing/off visuals against real lift events, validate first-play and return through `ash_bell_lift_surface` developer preset; close only once technical and, if still subjective, compact human visual checks pass.
- Current measured state: Both surface `ash_bell_lift_ingress_presentation.tscn` and authored Underground `forlorn_ritualant_underground.tscn` instantiate `ash_bell_lift_platform_assembly.tscn`. Current shared assembly has a 128×128 split platform back/front lip and 4f `vibrate` variants, `set_vibrating(active)` and `set_depths`; surface traversal is 1.05s/176px lift + 384px shaft, Underground arrival/departure uses its own canonical longer travel sequence. Five V2 sources exist but are not equivalent to imported scene-bound textures. Arming source remains 6f vs agreed 8f target until independently approved replacement arrives.
- Evidence: `design/05_levels/ASH_BELL_LIFT_INGRESS_PRESENTATION.md`; `design/05_levels/ASH_BELL_BRIDGED_FALLS_ASSET_MANIFEST.md` §B; `custodian/game/world/approaches/ash_bell/ash_bell_lift_platform_assembly.gd/.tscn`; `ash_bell_lift_ingress_presentation.gd/.tscn`; `custodian/game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.gd/.tscn`; existing focused smokes; exact Asset V2 status/catalog from implementation review predecessor.
- Task-specific authority: Shared AshBellLiftPlatformAssembly owns lift visual leaves and moving anchor; surface AshBellLiftIngressPresentation owns surface descent timing/occlusion; ForlornRitualantUnderground owns authored arrival/departure state; Asset Pipeline V2 owns textures; physics/route loaders own all collision, transitions, actor processing.
- Work surface: Shared lift platform assembly script/scene and a narrow reusable safety-field presenter component/resource under `custodian/game/world/approaches/ash_bell/`; two lift instance presentation bindings as needed; focused lift/Underground validation; related design docs and required-assets references only when rendered binding is proven.
- Change:
  1. Re-read predecessor independent review outcomes. Only bind states that are genuinely registered, imported and source-reviewed; reject a claimed 8f arming state when actual source is six frames. If approved eight-frame arming input still does not exist, stop before a false final V2 closeout; report `source_pending` and request a bounded source-art completion rather than inventing frames. No silent substitute is permitted for final animated field.
  2. Integrate `lift_deck` in the shared passive platform assembly without losing real front-lip/rider occlusion or bounds. Use separate reusable `field_projector` module instances mounted on deck front corners and VFX-only transparent field sprites (no duplicated physical support/railing inside VFX); derive pivots/mount geometry from live assembly at native gameplay scale, not source-image canvas extents.
  3. Implement a narrowly owned field presenter with explicit `off`, `idle`, `arming`, `engaged`, `releasing` sequence. `field_idle` 6f 6 FPS loop, `field_engaged` 6f 8 FPS loop, `field_arming` 8f 12 FPS one-shot only after approved 8f art; `releasing` may be time-reversed arming via control code if visually valid and documented, no new source sprite required. Off hides energy field but keeps physical emitters. Idle subtle, peak only on arming/engaged. Do not make field an additional collision or navigation authority.
  4. Bind to **observed** lift travel/interaction state through existing presentation callbacks; do not infer world route unlock from VFX, change signal timing or create a competing gameplay state machine. Ensure correct cancel/reset, repeated entry, underground arrival, ascent, return, camera/layer/occlusion and actor puppet cleanup.
  5. Exercise first-play through `ash_bell_lift_surface` real-world debug preset; verify boarding, descent, authored Underground lower lift and return all reuse the same deck/emitter/field family without z-order pops, sprite drift or frame flicker. Check old mixed-source cliff assets remain until separate approved replacement.
  6. Run objective frame registration/pivots/alpha and layer visibility tests first, then capture minimal idle/arming/travel/arrival ROI evidence at native game resolution for user review only if subjective composition remains. Publish compact visual handoff; do not let Codex self-approve material art choices.
- Preserve: Real collisions/boarding bounds and attached safe marker, rider-puppet capture/restore and z ordering; surface 176px lift/384px shaft travel; Underground 256px vertical lower-lift staging and distinct timeline; procedural ingresses, White Thread progression, LevelLoader/route ownership, current production camera/occluder behavior.
- Non-goals: No teleport/debug-tool implementation, no new environment compositions, no gameplay collision wall for visual field, no rewrite of motion/route loader, no restructuring of the 37-state Underground environment family, no Ritualant quest/lore/actor change, no resize-in-runtime placeholders.
- Acceptance: Surface and Underground lift instances share a single authoritative visual assembly and same Asset V2 states; static deck and physical emitter remain positioned when field off; animated energy is physically legible but transparent and never hard collision; all five approved states have correct frame counts/cadences/pivots or packet reports genuine art blocker and defers closeout; boarding, departure, return, cancel and repeat states preserve canonical behavior; actual quick launch successfully reaches and tests exterior lift; required visual handoff only after objective evidence.
- Validation: `godot --headless --path custodian --script res://tools/validation/ash_bell_lift_ingress_presentation_smoke.gd`; `godot --headless --path custodian --script res://tools/validation/levels/forlorn_ritualant_underground_smoke.gd`; `godot --headless --path custodian --script res://tools/validation/world_ingress_physics_reentry_smoke.gd`; focused new field-state/cancel/return smoke, Asset V2 status/doctor, native-scale alpha/ROI comparisons and quick-launch playtest, changed-file validation and `git diff --check`.
- Task overrides: `none`
- Deferred: New animation frames for the eight-frame arming source if genuinely missing; new cliff architecture sheet/source decomposition, Underground redesign and chapter audio. Complete no final V2 integration until any blocking arming source-review gap is resolved.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Refresh instruction: At execution inspect review-asset-intake report for arming state. If still source-pending, do not silently implement missing visual semantics; report the exact missing artwork and publish minimal human review request, then resume when approved input lands.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Next action: Follow the dependency order; deliver exact validation and artifact/provenance evidence, then let the paired fresh-context review execute.
- Blockers or open questions: New animation frames for the eight-frame arming source if genuinely missing; new cliff architecture sheet/source decomposition, Underground redesign and chapter audio. Complete no final V2 integration until any blocking arming source-review gap is resolved.

