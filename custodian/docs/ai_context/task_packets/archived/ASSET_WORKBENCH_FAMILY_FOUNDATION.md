# ASSET WORKBENCH — SLICE 1 FAMILY NAVIGATOR FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `asset-workbench-family-foundation`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `asset-workbench-ui, asset-v2-read-projection`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `b32a10d`
- Goal: Provide the first useful read-only Asset Workbench surface over Asset Pipeline V2 so a user can launch a visual UI, browse/search registered non-Operator asset families, inspect state contracts and production lifecycle status, and understand what is present/missing/pending without reading JSON or composing several CLI commands.
- Completion boundary: Deliver Slice 1 of `design/04_architecture/ASSET_WORKBENCH_ROADMAP.md`: a stable optional Textual entrypoint, a side-effect-free Asset V2 read-model/service boundary, FAMILY navigation/detail/status UX, transactional browser refresh semantics, Baby Opossum production acceptance coverage, focused validation ownership, and current-doc/roadmap reconciliation. No raster review or repository mutation belongs in this workstream.
- Current measured state:
  - No general Asset Workbench UI exists on current main.
  - `custodian/tools/assets/asset.py` is the human CLI front door and currently combines CLI rendering with command orchestration.
  - `asset_contract.py` already exposes immutable validated `AssetFamilyContract` / `AssetStateContract` truth.
  - `asset_status.py::get_family_status()` already exposes per-family/per-state inbox pending, runtime art, authored/mirrored directions, import, binding, runtime-verification and completeness truth.
  - `asset_plan.py::generate_plan()` is pure/read-only but plan display/ingest is intentionally deferred to Slice 3.
  - `ambient_baby_opossum` is a real `custodian.asset_family.v2` acceptance family with **50 states**, 7 action groups, body + `barrel_prop` layers, 96×96 canvas, 4-direction policy, and auto-mirroring.
  - Operator has mature Textual UX references, but its UI package and backend are Operator-specialized. Slice 1 must not make Asset Workbench depend on Operator service/state/runtime authority.
  - `validation_manifest.json` currently routes `custodian/tools/assets/**` through `asset_pipeline_v2`; no focused Asset Workbench UI owner exists.
- Evidence:
  - `design/04_architecture/ASSET_WORKBENCH_ROADMAP.md`
  - `design/04_architecture/ASSET_PIPELINE_V2.md`
  - `custodian/tools/assets/asset_contract.py`
  - `custodian/tools/assets/asset_status.py`
  - `custodian/tools/assets/asset_requirements.py`
  - `custodian/tools/assets/asset.py`
  - `custodian/content/metadata/assets/families/ambient_baby_opossum.asset.json`
  - `custodian/tools/validation/asset_pipeline_v2_smoke.py`
  - `custodian/tools/validation/asset_pipeline_cli_ux_smoke.py`
  - `custodian/tools/validation/asset_requirements_smoke.py`
- Task-specific authority:
  - `design/04_architecture/ASSET_WORKBENCH_ROADMAP.md` owns Asset Workbench slice sequencing and must be kept current by this workstream.
  - `design/04_architecture/ASSET_PIPELINE_V2.md`, `custodian/tools/assets/`, and registered Asset V2 family contracts remain technical asset authority.
  - `custodian/content/metadata/assets/required_assets.registry.json` remains production requirement authority.
  - Operator Workbench may be used as a UX/reference implementation only; it does not become Asset Workbench backend authority.
- Work surface:
  - Primary: new Asset Workbench UI/service/state code under `custodian/tools/assets/` using a clean subpackage/module boundary appropriate to current main.
  - Integration: `custodian/tools/assets/asset.py` and/or `tools/custodian_aliases.sh` only as needed for one stable UI launch path.
  - Validation: new focused `asset_workbench_ui` smoke/owner plus existing Asset V2 CLI/pipeline regressions.
  - Docs: `design/04_architecture/ASSET_WORKBENCH_ROADMAP.md`, concise `CURRENT_STATE.md` / `FILE_INDEX.md` updates only when implementation creates durable current truth.
- Change:
  - Add the read-only Asset Workbench FAMILY mode described by roadmap Slice 1.
  - Expose a low-friction primary launch path as `asset ui` unless current main proves a cleaner existing seam. UI dependencies must be lazy/optional so ordinary non-UI `asset plan|status|ingest|...` commands remain usable without Textual installed.
  - Do not scrape human CLI text. Build a thin Python service/read-model facade over existing Asset V2 authorities.
  - Represent the accepted UI data with immutable projections sufficient to render:
    - family ID and kind;
    - family required completeness;
    - canvas size;
    - direction policy and auto-mirror state;
    - consumers;
    - family inbox existence/pending filenames;
    - state ID;
    - required / recommended / optional role;
    - layer and action group;
    - static vs animated contract;
    - declared FPS and expected frame count when present;
    - per-state frame size;
    - minimum/required directions;
    - authored and mirrored runtime directions;
    - source-pending/art-present/imported/bound/runtime-verified state;
    - first/current runtime path when present.
  - The UI must support family/state navigation and search/filtering without encoding NPC/enemy/fauna-specific semantics.
  - Search is a pure view over the last accepted in-memory projection. Typing/clearing search performs zero repository scans and zero Asset V2 mutation.
  - Refresh must be transactional from the UI perspective:
    1. build a complete candidate snapshot side-effect-free;
    2. only replace the accepted snapshot after candidate construction succeeds;
    3. preserve the previous visible snapshot and selection on discovery/status exceptions;
    4. preserve semantic selection when the selected family/state still exists;
    5. if a genuinely removed selection no longer exists after a successful refresh, choose a deterministic fallback and log one explicit activity/status message rather than silently jumping.
  - Do not maintain a second asset-truth cache inside widgets. Widgets render accepted projections; Asset V2 remains authority.
  - FAMILY presentation should make required/recommended/optional status and lifecycle state readable without relying on color alone.
  - Missing inbox directories, no runtime output, unbound consumers, absent validation evidence, and incomplete families are ordinary states and must not crash the UI.
  - Loading one malformed family/contract should fail the refresh visibly while retaining the previous accepted snapshot; do not replace the entire navigator with an empty tree.
  - The UI must be usable without raster terminal protocols because Slice 1 contains no image preview.
  - Use `ambient_baby_opossum` as the real production acceptance family. Prove the projection handles its 50 states, 7 action groups, `body` and `barrel_prop` layers, 4dir policy, and mirror provenance without hard-coded opossum logic.
  - Add focused UI/service smoke coverage. The smoke should use fixture repositories/data for mutation-sensitive conditions and may inspect the real Baby Opossum contract read-only.
  - Add/update `validation_manifest.json` ownership so future Asset Workbench UI edits select the focused UI smoke rather than relying only on the broad Asset Pipeline V2 owner.
  - **Roadmap maintenance is part of implementation, not closeout decoration.**
    - At the start of implementation, update Slice 1 in `ASSET_WORKBENCH_ROADMAP.md` to `in progress` with the active workstream/current reviewed main.
    - If implementation changes a planned boundary, dependency, launcher decision, shared-UI assumption, or later-slice scope, update the roadmap in the same branch when that decision is made.
    - Before completion, set Slice 1 to `complete`, record landed/focused-validation evidence, update `Last updated` and `Last reconciled main`, and reconcile the descriptions of later slices against what was actually built.
    - Do not mark Slice 2+ complete or silently delete deferred work.
- Preserve:
  - Asset Pipeline V2 family contracts, catalog, requirement registry, status semantics, plan semantics, ingest transactions and existing CLI behavior.
  - Existing `asset` CLI output and exit behavior outside the new UI entrypoint.
  - Operator Workbench code/behavior; no Operator backend import into Asset Workbench.
  - Current runtime outputs and production assets. Slice 1 is read-only.
  - Existing validation for Asset V2, requirements and CLI UX.
- Non-goals:
  - No image/raster preview, filmstrip, playback, onion skin, overlay or pixel diff.
  - No Aseprite integration.
  - No `asset plan` visualization beyond any minimal read-only next-action text naturally exposed by current status; the full plan surface is Slice 3.
  - No ingest, replace, mirror mutation, archive mutation, Git commit/push/landing, or persistent art worktree.
  - No family-contract editing or `asset new` UI.
  - No actor/NPC-specific grouping or review sequences.
  - No speculative shared Workbench framework extraction from Operator.
  - No changes to runtime/gameplay consumers or asset art.
- Acceptance:
  - `asset ui` (or the explicitly documented equivalent chosen from current architecture) launches the Asset Workbench when optional UI dependencies are available and ordinary non-UI `asset` commands remain dependency-independent.
  - The navigator can enumerate all registered readable Asset V2 families and select a family/state without parsing CLI text.
  - A selected family/state displays the contract and lifecycle fields listed in Change with correct absent/false states rather than invented success.
  - Search/filtering reads only the accepted snapshot; a focused test proves no family/status discovery occurs while typing/clearing search.
  - Refresh exception after an accepted snapshot retains prior navigator contents and semantic selection.
  - Successful refresh preserves selection when that semantic identity remains.
  - Successful refresh with a genuinely removed selected identity performs one deterministic explicit fallback.
  - Missing inbox/runtime/import/binding/validation evidence is represented without crash.
  - Real `ambient_baby_opossum` projects all 50 states with 7 action groups, both declared layers, 4dir policy and auto-mirror metadata without family-specific conditionals.
  - UI actions in this slice create no tracked/untracked production mutation outside ordinary ignored UI/test temp state.
  - New focused validation ownership is registered and selected for Asset Workbench UI files.
  - Roadmap Slice 1 is maintained throughout the workstream and ends reconciled to actual landed behavior.
- Validation:
  - First run the new focused Asset Workbench service/UI smoke.
  - Then run:
    - `python3 custodian/tools/validation/asset_pipeline_v2_smoke.py`
    - `python3 custodian/tools/validation/asset_pipeline_cli_ux_smoke.py`
    - `python3 custodian/tools/validation/asset_requirements_smoke.py`
  - Exercise the optional Textual UI/Pilot with the supported UI environment when feasible; a missing optional UI dependency must be an explicit skip/refusal, not a false pass.
  - Finish with `python3 custodian/tools/validation/run_validation.py --changed --json`.
  - Run `git diff --check`.
- Task overrides: `none`
- Deferred:
  - Slice 2 raster REVIEW studio and shared preview extraction.
  - Slice 3 plan/ingest mutation, isolated Asset Workbench mutation checkout and one-action landing.
  - Slice 4 actor/NPC/fauna lens and review sequences.
  - Slice 5 contract Design mode.
  - Slice 6 family/state creation and source intake/pixel conversion.
  - Slice 7 platform hardening/domain expansion.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `custodian/tools/assets/asset_workbench/` supplies immutable family/state projections, read-only status composition, pure search, and transactional refresh; `asset ui` lazily launches the optional FAMILY UI. `custodian/tools/validation/asset_workbench_ui_smoke.py` passes with Textual Pilot in the supported UI virtual environment, covers fixture refresh/search/mirroring and the real 50-state Baby Opossum family, and confirms non-UI CLI independence. `asset_pipeline_v2_smoke.py`, `asset_pipeline_cli_ux_smoke.py`, `asset_requirements_smoke.py`, changed-file validation, and `git diff --check` pass. Roadmap Slice 1 is complete and Slice 2 is ready after this landing.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The first Textual Pilot exposed that Textual 0.89.1 accepts `Tree.show_root` as a property, not a constructor keyword. Baby Opossum's 22 cataloged runtime files were LFS pointers in this worktree, so status initially appeared empty.
- Root cause / contributing factors: The installed Textual API differs from the assumed constructor shape; degraded LFS smudge leaves pointer files even though all required objects were already cached locally.
- Prevention / pipeline improvement: Exercise the supported Textual environment with Pilot. Before interpreting missing catalog-backed art as production absence, distinguish LFS pointers from missing files and use only already-cached LFS objects for local validation.
- Tooling / docs drift discovered: The Asset Pipeline V2 command table omitted the new `asset ui` entrypoint; the table now documents its optional dependency boundary.
- Follow-up: `fixed-in-scope`
- What worked: The dedicated fixture smoke caught lifecycle, search, and UI regressions without touching production files.

## Handoff

- Next action: Continue with `asset-workbench-review-studio` after this implementation lands; extend the accepted Slice 1 projections without adding a second asset-truth cache.
- Best starting files: `design/04_architecture/ASSET_WORKBENCH_ROADMAP.md`, `custodian/tools/assets/asset_contract.py`, `asset_status.py`, `asset.py`, `custodian/tools/validation/validation_manifest.json`.
- Blockers or open questions: none. Slice 1 remains read-only; Slice 2 owns raster REVIEW and does not add ingest mutation.
