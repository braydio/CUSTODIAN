# OPERATOR WORKBENCH FX LAYER ADOPTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-workbench-fx-layer-adoption`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-operator-workbench-browser-preview-disconnect-ownership-correction`
- Locks: `operator-workbench-ui, operator-workbench-publish`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `review-operator-workbench-fx-layer-adoption`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `f64ee5c71ebb42ed7e192fccb71dec4fba3664d9`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Let an artist add or replace an FX layer directly inside an existing Operator Aseprite Workbench, explicitly adopt that saved layer as the animation's canonical `fx` source, preview the result, and publish it through the normal guarded source→runtime transaction without a separate inbox/manual-ingest detour.
- Completion boundary: Add one narrow human-authored FX adoption path for an already-existing semantic Operator animation. Saved top-level Aseprite layers named `vfx` or `fx` may be discovered as unbound editor content, explicitly adopted as semantic layer `fx`, represented transactionally as CREATE or REPLACE against the canonical source target, included in Workbench preview/publish review, rebuilt into runtime/catalog resources, mirrored only when the existing explicit counterpart option is enabled, and rolled back exactly on failure. Do not add arbitrary new animation identities or general layer-creation/autopilot authority.
- Current measured state:
  - Implemented in isolated workstream `operator-workbench-fx-layer-adoption`, claimed from `origin/main` at `8ba836d40553f189487fdf2b292e434057388282` (full baseline recorded in workstream receipt).
  - Saved top-level `vfx`/`fx` inspection and explicit adoption now support schema-derived direct CREATE/REPLACE; canonical binding-set drift refreshes clean documents and preserves edited documents.
  - UI/CLI share the backend, unsaved live-only candidates are non-adoptable, and counterpart mirroring defaults off unless explicitly selected.
  - Exact frame RGBA preview, normalized source hashes, transaction rollback, collision refusal, mirrored CREATE/REPLACE, and workbench UI action are covered by focused fixtures and Aseprite integration.
- Preserve: Canonical PNGs remain source authority; runtime/catalog/resources remain generated projections; Aseprite Workbenches stay ignored/disposable; publication remains isolated to `workbench/operator-art`; source-conflict guards, scoped publication allowlist, LAND PENDING, the predecessor's local-only LFS materialization contract (cache first, exact verified hydrated donor second, no network), import preflight, frame/canvas migration safety, timing authority, explicit counterpart promotion, existing body/head/cape/weapon bindings, and current block-hold FX gameplay behavior remain unchanged.
- Non-goals: No new block art or VFX redesign. No Asset V2 inbox redesign. No arbitrary new semantic animation creation. No generic adoption of body/head/cape/weapon layers in this first slice. No Art Agent autonomous layer creation or publish authority. No gameplay timing/combat changes. No automatic semantic inference from arbitrary layer names. No broad Workbench schema rewrite beyond the minimum creation/adoption contract.
- Acceptance:
  - Fixture with an existing body-only animation and saved Aseprite `vfx` layer shows one unbound layer with suggested semantic role FX; it does not publish or mutate the manifest until explicit adoption.
  - Explicit adoption creates one manifest-authorized `fx` binding while preserving editor layer name `vfx`; FX ONLY and BODY + FX saved-workbench previews render its exact RGBA pixels before publish.
  - If no canonical FX source exists at adoption, publish preview reports direct `CREATE` at the exact schema-derived canonical source path. Successful publish creates source + generated runtime/catalog/resource output, then converts the binding to a normal canonical source contract with real hashes.
  - Injected downstream failure after CREATE removes the new source/runtime/import artifacts and restores generated resources; no orphan canonical FX identity remains.
  - If canonical FX already exists but the Workbench manifest predates it, adopting saved `vfx` reports `REPLACE`, backs up/restores the previous source on injected failure, and refuses publish if that canonical source changed after adoption.
  - If a CREATE target appears between adoption/preview and publish, publication refuses rather than overwriting it.
  - Unsaved live-only `vfx` presence is visible as unsaved/non-adoptable; Save makes it eligible. Unknown layers and `__REFERENCE*` layers are never auto-adopted.
  - Mirror promotion OFF changes only the authored direction. Explicit mirror promotion correctly CREATEs/REPLACEs the counterpart with a per-frame horizontal mirror and participates in the same rollback journal.
  - CLI default mirror behavior now matches active Workbench design: no counterpart without explicit `--mirror-counterpart`.
  - A stale clean Workbench detects fresh canonical binding-set drift instead of silently omitting the new canonical FX layer; edited Workbench pixels are never discarded automatically.
  - Existing block-hold FX playback, Workbench publication, mirror, sparse checkout, runtime authority, import-preflight, and focused Operator guard smokes remain green.
- Validation: Completed focused fixture coverage for saved-layer inspection, explicit `vfx→fx` adoption, CREATE success/rollback, REPLACE rollback and changed-source refusal, target collision, binding-set drift, unsaved-live refusal, unknown/reference-layer refusal, preview composition, and mirror opt-in/default-off behavior. The UI smoke covers unbound-layer projection/adopt action; mirror smoke covers adopted FX CREATE/REPLACE mirror transactions. Required Aseprite Workbench, art worktree, import-preflight, SpriteFrames, focused modular-defense, changed-file validation, and diff checks were run. No Moment Forge or subjective visual baseline was required: exact layer identity, RGBA hash equality, generated-path/resource checks, and guard smoke falsify this tooling slice more cheaply.
- Task overrides: `none`
- Deferred: General nonexistent-layer adoption for `head`, `cape`, and `weapon`; Art Agent autonomous `create_layer` and bounded creation-mode publication. Entirely new semantic animation creation is now explicitly owned by `OPERATOR_WORKBENCH_ANIMATION_CREATION.md`, which depends on this packet's reviewed CREATE/rollback contract.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Result: Complete. Explicit saved-layer FX adoption is available for existing semantic animations through the shared Workbench backend and UI/CLI; direct CREATE/REPLACE and optional mirrored publication use the existing schema, transaction, rebuild, and rollback authority.
- Evidence: `operator_animation_workbench_smoke.py` (real Aseprite saved `vfx`, adoption, exact pixel preview); `operator_workbench_mirror_publish_smoke.py` (CREATE/REPLACE, mirror opt-in, rollback, collision); `operator_workbench_ui_smoke.py` (service plus Textual pilot); `operator_art_worktree_smoke.py`; Godot import preflight and runtime SpriteFrames import; focused modular defense smoke; final changed-file validation report.
- Deferred: General nonexistent-layer adoption for head/cape/weapon; Art Agent autonomous `create_layer`; entirely new semantic animation authoring.
- Limitation: Focused modular-defense smoke returned exit 0 and its pass marker but printed pre-existing missing imported resource/animation diagnostics. Import-preflight and SpriteFrames checks passed separately.

## Handoff

- Next action: Run the paired fresh-context review after this implementation lands.
- Best starting files: this packet's archived implementation, `OPERATOR_WORKBENCH_FX_LAYER_ADOPTION_CLAUDE_SUMMARY.md`, and the paired review packet.
- Blockers or open questions: none.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The focused modular-defense smoke emitted existing missing-resource/animation diagnostics while still exiting successfully with its pass marker.
- Root cause / contributing factors: The defense fixture loads adjacent legacy/runtime content with unresolved import artifacts in this checkout; dedicated import-preflight and SpriteFrames import checks passed.
- Prevention / pipeline improvement: Retain the pass marker/exit status and record diagnostic noise; no in-scope change to unrelated legacy content.
- Tooling / docs drift discovered: None.
- Follow-up: `review-operator-workbench-fx-layer-adoption`
- What worked: Focused fixture and UI coverage exercised exact saved-layer adoption, transaction rollback, mirror choice, collision guards, and real Aseprite preview.
