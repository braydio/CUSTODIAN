# OPERATOR WORKBENCH NEW ANIMATION CREATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-animation-creation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-operator-workbench-fx-layer-adoption`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-operator-workbench-animation-creation`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `278a542dda`
- Goal: Let an artist create an entirely new semantic Operator animation from OPUI, open a blank/reference-backed Aseprite Workbench, author and preview it, then publish the new canonical source through the existing guarded Operator production pipeline without hand-building filenames, manifests, inbox entries, runtime resources, or Git transactions.
- Completion boundary: Add one human-authored **New Animation** flow for a semantic Operator action/direction that does not yet exist in canonical source. The flow owns identity/template selection, creation-session manifest construction, blank/reference-backed Aseprite assembly, preview, transactional CREATE publication, runtime/catalog/import/validation, and normal guarded landing. It consumes the FX-adoption packet's absent-source CREATE/rollback contract. It does not wire arbitrary new gameplay behavior, invent runtime selectors, auto-generate finished art, or replace Asset Pipeline V2's external-asset intake path.
- Current measured state:
  - Workbench V2 can edit only an identity already returned by canonical `source_index()`; `build_plan()` raises when no canonical layers resolve.
  - The FX-adoption packet is intentionally narrower: it proves one missing `fx` layer can be adopted on an **existing** semantic animation. It explicitly defers creation of an entirely new semantic animation.
  - `OPERATOR_ART_AGENT_SYSTEM.md` Phase 8 already defines creation mode as an additive Workbench capability with no source contract, an explicit proposed publish contract, transactional new-source publication, rebuild/import/test, collision refusal, and exact rollback deletion.
  - `operator_asset_schema.py` already owns Operator semantic validation, canonical filename generation, and canonical source/runtime paths.
  - `sync_operator_runtime_assets.py` already owns canonical Operator source -> runtime/catalog synchronization; Godot import preflight and `build_operator_runtime_frames.gd` own import/resource projection.
  - Asset Pipeline V2 explicitly delegates Operator artwork to the specialized Operator backend. Current Workbench publication intentionally does **not** route through `asset_drop/inbox`; the inbox remains the intake boundary for external/generated/untrusted art that needs normalization/provenance before it becomes canonical source.
- Evidence:
  - `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`
  - `design/02_features/animation/OPERATOR_ART_AGENT_SYSTEM.md` Phase 8
  - `design/04_architecture/ASSET_PIPELINE_V2.md`
  - `custodian/tools/operator/animation_workbench_model.py::build_plan/assert_context`
  - `custodian/tools/operator/animation_workbench.py::ensure/state/publish`
  - `custodian/tools/operator/ui/service.py`
  - `custodian/tools/operator/ui/app.py`
  - `custodian/tools/operator/operator_cli.py`
  - `custodian/tools/pipelines/operator_asset_schema.py`
  - `custodian/tools/pipelines/sync_operator_runtime_assets.py`
  - `custodian/tools/pipelines/godot_import_preflight.py`
  - landed `operator-workbench-fx-layer-adoption` implementation/review when dependency completes
- Task-specific authority:
  - Workbench is the authoritative human editing/publication surface for Operator canonical art.
  - `operator_asset_schema.py` is the sole semantic/path authority for new Operator layer assets.
  - Asset Pipeline V2 remains the orchestration/intake authority for externally supplied art, but its Operator backend is specialized. Native Workbench creation reuses the same production stages instead of round-tripping its own saved pixels through `asset_drop/inbox`.
  - Gameplay/runtime consumers remain separate authority. A newly published animation may be catalog-present but DORMANT until an owning gameplay/presentation packet wires it.
- Work surface:
  - `custodian/tools/operator/animation_workbench_model.py`
  - `custodian/tools/operator/animation_workbench.py`
  - `custodian/tools/aseprite/operator_animation_workbench.lua`
  - `custodian/tools/operator/ui/service.py`
  - `custodian/tools/operator/ui/app.py` and the narrow New Animation dialog/widget surface
  - `custodian/tools/operator/operator_cli.py`
  - existing Workbench model/UI/mirror/publish validation
  - active Workbench/Art Agent/roadmap/current-state docs where live truth changes
- Change:
  1. Add one typed `AnimationCreationPlan`/equivalent backend contract. It must validate profile, group, action, direction, frame count, frame canvas, timing/loop, and selected presentation template before any file is created. Use `operator_asset_schema.py`; never hand-build canonical paths in Textual.
  2. Add a **New Animation** action in OPUI. Minimum fields:
     - profile;
     - action group;
     - semantic action name;
     - authored direction;
     - frame count;
     - frame canvas, defaulting from the current Operator authoring/profile contract where available;
     - FPS + loop;
     - body template.
     The first production templates are:
     - `full_body`;
     - synchronized `lower_body + upper_body`.
     FX/head/cape/weapon remain addable through the existing/adopted layer mechanisms instead of making the creation dialog a layer-schema editor.
  3. Before creation, show a read-only plan containing the exact semantic identity, layer set, generated canonical source targets, expected runtime targets, frame/timing contract, mirror choice, collision state, and whether the action is already present in implementation-plan/reachability/runtime data. Existing canonical source for any requested CREATE target is a hard collision.
  4. Create an ignored/disposable Workbench manifest with **no existing source contract** for the new publishing layers and explicit proposed publish contracts. Assemble a new Aseprite document with the selected blank publishing layers plus nonpublishing reference/guide layers from deterministic canonical references. Do not create canonical PNGs merely by opening the session.
  5. Creation-session state must distinguish `NEW / UNSAVED`, `NEW / READY TO PUBLISH`, collision/stale states, and ordinary existing-source Workbench states without parsing free-form errors.
  6. Saved-workbench Preview must render the new animation before canonical publication. REVIEW/SEQUENCE/MOTION should accept the creation-session preview where their existing contracts allow, without pretending the animation is already runtime-bound.
  7. Publish the new layers through the same guarded Workbench transaction proven by FX adoption:
     - revalidate publish-readiness and target nonexistence immediately before mutation;
     - export exact saved layer pixels;
     - transactionally CREATE canonical source at schema-derived paths;
     - write timing sidecar authority where applicable;
     - run strict Operator source -> runtime synchronization;
     - run Godot LFS/import preflight;
     - import;
     - rebuild Operator SpriteFrames/catalog resources;
     - run focused Operator contract/runtime checks;
     - stage only publication allowlist outputs;
     - commit/land through the dedicated art checkout flow;
     - on failure, delete new source/runtime/import artifacts and restore generated resources/metadata exactly.
  8. Horizontal counterpart creation remains explicit/default-OFF. If enabled, the preview must show counterpart CREATE/REPLACE consequences and the transaction must use the existing per-frame mirror contract. Never silently overwrite an authored counterpart.
  9. After successful publish, normalize the creation manifest into the ordinary existing-source Workbench contract with real source/pixel hashes so subsequent edits use the same path as every other animation.
  10. Refresh browser/Queue projections after landing. A newly created canonical animation must appear without restarting OPUI. If there is no runtime gameplay consumer, show it truthfully as catalog/source-present but DORMANT/unwired rather than implying it is used in game.
  11. Expose the same backend through CLI for automation, for example:
      `operator anim create <profile> <action> <direction> --group <group> --frames N --size 96 --template full_body --fps 8 [--loop]`.
      CLI and UI must share creation-plan and publication implementations.
  12. Integrate the **useful Operator pipeline stages**, not an unnecessary inbox bounce. The UI should surface structured progress/receipts for schema validation, source CREATE, runtime sync, import, resource/catalog rebuild, validation, commit/landing, and rollback/recovery. Do not duplicate those implementations inside the UI.
  13. Preserve the external-art intake path. If future UI work imports a generated/external PNG rather than authoring pixels in the Workbench, use the established Operator V2 intake convention:
      `custodian/asset_drop/inbox/operator/operator__<layer>__<profile>__<group>__<action>__<direction>__<N>f__<size>.png`
      and the specialized Operator schema/registration path. Do not silently copy arbitrary external files into canonical source from this creation command.
- Preserve:
  - isolated `workbench/operator-art` publication authority;
  - publish-readiness/recovery contract;
  - accepted browser/preview generation contract;
  - FX CREATE/REPLACE/rollback behavior;
  - canonical Operator source as source authority;
  - runtime/catalog resources as generated outputs;
  - local-only LFS materialization policy;
  - explicit/default-off counterpart promotion;
  - frame/canvas migration safety;
  - gameplay timing/hit-window authority outside art tooling.
- Non-goals:
  - no autonomous art generation;
  - no Art Agent autopilot;
  - no arbitrary gameplay binding or selector creation;
  - no automatic implementation-plan rank mutation;
  - no generic Asset V2 family-contract creation for Operator art;
  - no forced `asset_drop/inbox` round-trip for Workbench-native pixels;
  - no general new-layer taxonomy editor;
  - no replacement of the specialized Operator runtime builder.
- Acceptance:
  - From OPUI, a user can create a previously absent test identity, choose `full_body`, 6 frames, 96x96, save known pixels in Aseprite, preview them, and see a publish review showing exact canonical source/runtime CREATE targets.
  - Publishing that fixture creates only schema-derived canonical source/timing, generated runtime/catalog/resource outputs, and permitted transaction metadata; the resulting source/runtime RGBA hashes match the saved Workbench pixels.
  - A modular fixture creates synchronized lower+upper layers with one shared frame/timing contract and previews them composed before publish.
  - Existing-target collision before session creation and a race where a target appears after preview both fail closed without overwriting.
  - Injected failure after canonical CREATE removes every newly created source/runtime/import/timing artifact and restores generated resources/metadata exactly.
  - Successful publish converts the Workbench from creation state to ordinary existing-source state without losing the open document or requiring manual manifest surgery.
  - The new identity appears in the refreshed browser immediately after publication; if no gameplay consumer exists it is labeled DORMANT/unwired, not LIVE.
  - Explicit mirror promotion creates the horizontal counterpart correctly; default creation does not.
  - Existing animation edit, FX adoption, publish-readiness, browser/PREVIEW, mirror, sparse-checkout, import and Operator runtime validations remain green.
- Validation:
  - Add focused creation fixtures for plan validation, full-body creation, modular creation, collision, target-appeared race, CREATE success, injected rollback, manifest normalization, browser refresh, dormant reachability projection, and explicit mirror promotion.
  - Extend `operator_animation_workbench_smoke.py`, `operator_workbench_ui_smoke.py`, `operator_workbench_mirror_publish_smoke.py`, and `operator_art_worktree_smoke.py` rather than creating parallel transaction fixtures where practical.
  - Run import-preflight, `operator_runtime_spriteframes_import_smoke.py`, the narrow modular-layer smoke, animation contract report, and one `run_validation.py --changed --json` closeout.
  - No new production art asset is required for this tooling packet; use disposable test fixtures only.
- Task overrides: `none`
- Deferred:
  - External PNG/import wizard integrated into OPUI.
  - General creation-time head/cape/weapon/FX template composition beyond the body templates above.
  - Art Agent autonomous Phase 8 creation/publish authority; it should call this Workbench creation backend later rather than invent another publisher.
  - Automatic gameplay wiring for newly created actions.

## Handoff

- Next action: Auto-claim after the FX-adoption paired review archives.
- Best starting files: the landed FX-adoption creation-binding transaction, `animation_workbench_model.py::build_plan`, `animation_workbench.py::publish`, `ui/service.py`, `ui/app.py`, and `operator_asset_schema.py`.
- Blockers or open questions: None for the bounded human-authored creation flow. Gameplay consumption remains intentionally separate.
