# ASH BELL SURFACE LIFT V2 PRESENTATION INTEGRATION
- Packet schema: `custodian.task_packet.v2`
- Workstream: `ash-bell-surface-lift-v2-presentation-integration`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-ash-bell-surface-lift-v2-asset-intake, review-ash-bell-lift-dev-quick-launch`
- Locks: `asset-pipeline, ash-bell-lift-art, ash-bell-lift-site, world-presentation`
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
- Current measured state: Both surface `ash_bell_lift_ingress_presentation.tscn` and authored Underground `forlorn_ritualant_underground.tscn` instantiate `ash_bell_lift_platform_assembly.tscn`. Current shared assembly has a 128×128 split platform back/front lip and 4f `vibrate` variants, `set_vibrating(active)` and `set_depths`; surface traversal is 1.05s/176px lift + 384px shaft, Underground arrival/departure uses its own canonical longer travel sequence. The original five-state intake contains four runtime-eligible reviewed states plus the superseded six-frame `field_arming` source-work-only candidate. Human review in the current planning chat has now approved a genuine fixed-grid eight-frame replacement source: 2048×256 RGBA, exactly 8×256×256 cells, SHA-256 `fccc2a81b0abd2d5f3bf755a9dd9f465c35050c45c1155f821688df1317842ef`. Handoff ZIP `custodian_ash_bell_surface_lift_field_arming_8f_replacement_v1.zip` has SHA-256 `88e1d6d163725fb7089917b8a31d7eb5f29b12ec119a98c13b10b165ffbeb51e`. It is approved visual/source authority but still requires reviewed Asset V2 replacement + normalization before runtime binding.
- Evidence: `design/05_levels/ASH_BELL_LIFT_INGRESS_PRESENTATION.md`; `design/05_levels/ASH_BELL_BRIDGED_FALLS_ASSET_MANIFEST.md` §B; `custodian/game/world/approaches/ash_bell/ash_bell_lift_platform_assembly.gd/.tscn`; `ash_bell_lift_ingress_presentation.gd/.tscn`; `custodian/game/world/levels/authored/ash_bell/forlorn_ritualant_underground/forlorn_ritualant_underground.gd/.tscn`; existing focused smokes; exact Asset V2 status/catalog from implementation review predecessor.
- Task-specific authority: Shared AshBellLiftPlatformAssembly owns lift visual leaves and moving anchor; surface AshBellLiftIngressPresentation owns surface descent timing/occlusion; ForlornRitualantUnderground owns authored arrival/departure state; Asset Pipeline V2 owns textures; physics/route loaders own all collision, transitions, actor processing.
- Work surface: Shared lift platform assembly script/scene and a narrow reusable safety-field presenter component/resource under `custodian/game/world/approaches/ash_bell/`; two lift instance presentation bindings as needed; focused lift/Underground validation; related design docs and required-assets references only when rendered binding is proven.

## Approved 8f field_arming replacement normalization

- Human-review chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Approved source: 2048×256 RGBA, 8 fixed 256×256 cells, SHA-256 `fccc2a81b0abd2d5f3bf755a9dd9f465c35050c45c1155f821688df1317842ef`.
- Runtime contract remains: `field_arming`, 8f × 512×192, 4096×192 strip, 12 FPS, one-shot, true alpha.
- Handoff ZIP: `custodian_ash_bell_surface_lift_field_arming_8f_replacement_v1.zip`, SHA-256 `88e1d6d163725fb7089917b8a31d7eb5f29b12ec119a98c13b10b165ffbeb51e`.
- The prior canonical six-frame `field_arming_source.png` is historical source-work evidence and must be superseded through a reviewed replacement transaction, not silently overwritten.

Use the repository converter for the normalization. This is a valid use case because the tool has fixed-cell sheet mode and applies one shared registration transform across every frame:

```bash
python3 custodian/tools/art/custodian_pixelart_converter.py \
  <approved-2048x256-field-arming-source> \
  custodian/asset_drop/inbox/ash_bell_surface_lift_safety_field_v1/field_arming.png \
  --sheet \
  --frames 8 \
  --source-cell 256x256 \
  --size 512x192 \
  --fit contain \
  --anchor center \
  --choose balanced \
  --keep-candidates <review-dir>/field_arming_converter \
  --export-frames <review-dir>/field_arming_frames
```

Do **not** pass `--pixel-source`: the approved master is high-resolution generated RGBA art. Do **not** anisotropically stretch it. The converter intentionally preserves aspect ratio. After conversion, require exact 4096×192 RGBA geometry, eight distinct 512×192 cells, stable shared registration, no frame bleed, and native-scale comparison against `field_idle` / `field_engaged` and the actual projector spacing. If `--fit contain` leaves the barrier materially too narrow to span the physical projector envelope, stop and request/re-author a wider eight-cell source. Do not switch to stretching or `cover` merely to force width.

- Change:
  1. Re-read predecessor independent review outcomes. Only bind states that are genuinely registered, imported and source-reviewed. The old six-frame arming candidate is not runtime authority. Consume the exact approved eight-frame replacement source identified above through a reviewed Asset V2 replacement transaction, run the repository pixel-art converter with the exact fixed-grid command above, inspect its candidate/debug outputs, and ingest only if the 4096×192 result satisfies projector-envelope/native-scale review. If the exact source/handoff is not durably available in the execution environment, stop and request source publication rather than inventing or substituting frames.
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
- Deferred: New cliff architecture sheet/source decomposition, Underground redesign and chapter audio. The eight-frame arming visual source is no longer an art-generation blocker; only durable source promotion, aspect-preserving normalization, and native-scale envelope validation remain.

## Refresh Planning Authority

- Refresh owner: `execution-agent`
- ChatGPT/user planning refresh required: `no`
- Refresh planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Refresh instruction: At execution inspect the asset-intake review and then the exact approved 8f replacement identity above. If the replacement source is not durably retrievable, stop for source publication. If available, use the repository fixed-cell converter command above and fail closed on a visually too-narrow normalized envelope rather than stretching.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Next action: Follow the dependency order; deliver exact validation and artifact/provenance evidence, then let the paired fresh-context review execute.
- Blockers or open questions: The approved 8f source must be durably staged/promoted and its 512×192-per-frame normalization must pass native projector-envelope review; new cliff architecture sheet/source decomposition, Underground redesign and chapter audio remain separate.

