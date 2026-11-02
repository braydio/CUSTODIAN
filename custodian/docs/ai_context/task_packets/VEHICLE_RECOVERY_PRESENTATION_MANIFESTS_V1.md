# VEHICLE RECOVERY PRESENTATION MANIFESTS V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `vehicle-recovery-presentation-manifests-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-vehicle-field-scout-buggy-asset-v2`
- Locks: `asset-pipeline-vehicle, vehicle-recovery-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `asset-pipeline, architecture, code`
- Paired review workstream: `review-vehicle-recovery-presentation-manifests-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `new shared Asset V2 families and required-asset truth consumed by the recovery loop`
- Reviewed main: `ce07a578c39bad0b4eacf8bb02ee09eb59241801`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Visual review: `none`
- Goal: Register the shared Asset Pipeline V2 contracts needed to present vehicle diagnosis, component requirements, installation, and bootstrap without creating final raster art or class-specific one-off asset routes.
- Completion boundary: Done when the three shared families in `VEHICLE_RECOVERY_ART_MANIFEST.md` are registered, Asset V2 request/plan/status produces their exact required filenames and geometry, required-assets truth names the missing production art, the recovery/UI consumers have data-driven family IDs or explicit future binding seams, and no PNG is fabricated or hand-copied into runtime.
- Current measured state: The Scout body family is owned by the preceding Asset V2 slice. The gameplay design now also requires shared diagnostic/install FX and replacement-component icon vocabulary. No registered families currently own those requirements.
- Evidence: `design/02_features/vehicles/VEHICLE_RECOVERY_ART_MANIFEST.md`; reviewed Scout Asset V2 family; live `effect`, `ui`, and `world_prop` kind schemas; required-assets registry.
- Task-specific authority: `VEHICLE_RECOVERY_ART_MANIFEST.md`; `design/04_architecture/ASSET_PIPELINE_V2.md`; live kind schemas/CLI.
- Work surface: New family contracts `vehicle_recovery_fx_common.asset.json`, `vehicle_service_component_icons.asset.json`, `vehicle_service_component_props.asset.json`; `required_assets.registry.json` + generated projection; minimal consumer metadata/read seams if required; focused asset-contract smoke.
- Change: Register exact family/state/canvas/frame contracts from the design manifest. Mark world-prop component art recommended/optional, not required for V1 gameplay. Add requirement-registry entries for required FX/icon states. Do not generate placeholders to falsely satisfy them.
- Preserve: Scout body family ownership; all existing Asset V2 routing; no runtime reference to `asset_drop`; no new asset kind; no direct image generation in implementation agent; no gameplay mechanic changes.
- Non-goals: No production pixels, no subjective art approval, no new vehicle class, no UI redesign, no physical loose-part actor.
- Acceptance: `asset request` for all three family IDs emits the designed exact state names/dimensions; plan/status parse; doctor remains clean; required-assets reports required FX/icons missing until real art exists; optional props do not block gameplay readiness; no runtime file is synthesized or copied by hand.
- Validation: Asset Pipeline V2.1 production + CLI UX smokes; `asset doctor`; `asset needs --check`; focused family-contract smoke; changed-file closeout.
- Task overrides: `none`
- Deferred: Production source creation/ingest and human visual review; class-specific R2 missing-assembly silhouettes.

## Handoff

- Next workstream: `review-vehicle-recovery-presentation-manifests-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Summary backlink: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac58690-6728-83e9-ac55-af4abfa0525b`
- Refresh reason: `none`
- Next action: Review the contracts, then return to this authoring chat before producing the actual art.
- Blockers or open questions: `none`
