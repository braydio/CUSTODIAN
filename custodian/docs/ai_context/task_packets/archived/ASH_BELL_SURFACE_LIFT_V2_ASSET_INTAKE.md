# ASH BELL SURFACE LIFT V2 ASSET INTAKE
- Packet schema: `custodian.task_packet.v2`
- Workstream: `ash-bell-surface-lift-v2-asset-intake`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-dropbox-asset-lifecycle-reconciler-v1`
- Locks: `asset-pipeline, ash-bell-lift-art, dropbox-handoff`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `asset-pipeline, runtime, visual`
- Paired review workstream: `review-ash-bell-surface-lift-v2-asset-intake`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `asset/route lifecycle or presentation cross-authority; independent post-land verification required`
- Reviewed main: `b224e51a295e19ef4ae15111c1517dc6a79e70ea`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: `conditional`
- Goal: Turn the independently generated full-resolution Ash-Bell surface-lift V2 images into verified Asset Pipeline V2 source masters and runtime-family states without inventing animation or modifying lift traversal.
- Completion boundary: Download and verify the exact reviewed Dropbox ZIP, reconcile its 5 source states, register two scoped V2 family contracts, stage five immutable source masters and ingest only states that pass alpha/registration/fixed-grid review; explicitly leave the 8f activation target source-pending if the supplied 6f artwork cannot fulfill it. Complete only with truthful per-state status, conversion receipts, and no accidental runtime wiring.
- Current measured state: Latest known approved visual direction includes 2 static image sources (1448×1086 deck and 1086×1448 projector) plus 3 individually generated 2172×724 RGBA six-frame strips. Package is source-work only; Git source-review receipt registry was initially empty; current shared platform assembly is 128×128 static/4f legacy art. ZIP declares arming target 8f×512×192 but contains 6 visible frames. Do not equate 5 source files with 5 valid normalized states.
- Evidence: Dropbox `/CUSTODIAN/asset_batches/ash-bell-ritualant/CUSTODIAN_Ash_Bell_Surface_Lift_V2_Full_Resolution_Source_20261013.zip`; ZIP SHA-256 `fb283369cf3546c7615d1ea51a28c6f6fd95591d36d8c1ccafd5e4c2338bcdbc`, byte size 7,801,299, 5 separate PNG entries + MANIFEST.json + README. `custodian/docs/ai_context/asset_audits/DROPBOX_ASSET_FAMILY_BASELINE_20261013.json`; `design/05_levels/ASH_BELL_BRIDGED_FALLS_ASSET_MANIFEST.md` §B; source manifest specifies per-PNG digest.
- Task-specific authority: `custodian.asset_family.v2` and existing `custodian/tools/assets/asset.py`; `custodian/tools/art/custodian_pixelart_converter.py` fixed-frame registration; Git source-review receipts + Dropbox integrity workflow; `design/05_levels/ASH_BELL_LIFT_INGRESS_PRESENTATION.md` owns lift geometry and 832×608 dress clearance, not this intake.
- Work surface: `custodian/content/metadata/assets/families/ash_bell_surface_lift_ingress_props_v1.asset.json` and `ash_bell_surface_lift_safety_field_v1.asset.json` (new when justified); `custodian/asset_drop/source_work/ash_bell/<family-id>/<state-id>_source.png`; `custodian/asset_drop/inbox/<family-id>/<state-id>.png`; `custodian/content/metadata/assets/source_review_receipts.v1.json`; relevant Asset V2 generated catalog/requirements/status validation; no presentation scene mutations.
- Change:
  1. Check fresh `origin/main` and lifecycle-audit/review predecessor, and dedupe existing lift family or intake work; never duplicate or override a proven live consumer.
  2. Fetch exact ZIP through approved Dropbox transport / `dropbox_asset_stage.py`, verify ZIP SHA-256 and every member against MANIFEST.json, check PNG alpha/halo and whether six 362px-wide source columns are truly independent frame cells; reject baked contact sheets or visual-matte artifacts. Document evidence, not just CRC.
  3. Use one user-authorized, exact-hash source review receipt (five immutable source entries and reviewed runtime targets) only where original authoring-chat visual acceptance actually identifies these files. If provenance or art suitability is ambiguous, produce a minimal objective + visual handoff and do not self-approve. The empty review-receipts index is an intentional gate.
  4. Define exactly two V2 families: `ash_bell_surface_lift_ingress_props_v1` kind `world_prop` with `lift_deck` 1f 448×320 and `field_projector` 1f 64×128; `ash_bell_surface_lift_safety_field_v1` kind `effect` with `field_idle` 6f×512×192 @6 FPS loop, `field_engaged` 6f×512×192 @8 FPS loop, and `field_arming` **target 8f×512×192 @12 FPS one-shot**. Confirm exact accepted Asset V2 kind/metadata fields using live schema; registration must not assert 8f art where only 6f exists.
  5. Preserve all five source PNG bytes at canonical `source_work/ash_bell/<family-id>/<state-id>_source.png` (source-work evidence, even when normalized input remains blocked); normalize each structurally acceptable asset with shared bounding box per strip. Preserve true alpha, exact frame boundaries, no jitter/bleed, visual coherence of transparency at game scale. Use exact manifest target grids; don't assume a 2172×724 source scales or crops to a 512×192 cell without evidence.
  6. Run `asset.py plan` / ingest / status / doctor / needs for eligible states. No direct copy to runtime, no silent replacement of existing 128×128 platform art or scene references. Keep unapproved/invalid/shortfall states genuinely `source_pending`; do not silently relabel the eight-frame arming state to six, repeat frames, reverse other states, interpolate poses or paint missing pixels. An additional 8-frame art generation/review becomes a narrow follow-up only if still missing.
  7. Record per-state exact status and hash/registration/alpha evidence in the Dropbox lifecycle report and scoped design/spec notes. Existing engine/runtime consumers stay unchanged in this slice. Do not mark the entire family runtime-verified merely because imported files exist.
- Preserve: Existing `ash_bell_lift_platform_assembly.tscn` shared by surface and underground; all boarding collision, rider anchor, front-lip z ordering, movement/timing, ritual route gating, screenshot proof and generated-floor authority; original source art/resolution and Dropbox history.
- Non-goals: No scene wiring, no new gameplay lift state authority, no direct-to-lift debug tool, no 6→8 fabricated animation, no wholesale cliff/environment source regeneration, no unrelated Ritualant actor/chapel/Bridged Falls asset intake.
- Acceptance: 5 exact source candidates inventoried with immutable provenance; both proposed families registered only under valid V2 schema and no duplicate family; eligible states normalized/imported at explicit exact dimensions with alpha/frame consistency and named runtime outputs; `field_arming` either has a separately approved genuine 8f input or remains explicitly source-pending with a concrete follow-up, **not falsely completed**; Asset V2 catalog/status + doctor + required-assets and human/technical review discrepancies agree; source assets and runtime remain unmodified by audit-only paths.
- Validation: `python3 custodian/tools/assets/dropbox_asset_audit.py report --format markdown`; `python3 custodian/tools/assets/asset.py plan <family-id>`; `python3 custodian/tools/assets/asset.py status <family-id>`; `python3 custodian/tools/assets/asset.py doctor`; `python3 custodian/tools/assets/asset.py needs --check`; inspect generated per-state grids, alpha/hashes and focused asset-family/ingest tests; Godot import smoke only after eligible image state exists; `git diff --check`. Give compact native-size ROI/contact sheet only if human visual acceptance remains.
- Task overrides: `none`
- Deferred: Eight-frame `field_arming` is not supplied (only six distinct illustrated stages); this is a scoped **source-pending** state, not permission to guess or downgrade. Runtime wiring owned by integration packet.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Evidence: The exact Dropbox ZIP and five manifest members were hash-verified; the user’s current-chat, per-state approval was recorded in `custodian/content/metadata/assets/source_review_receipts.v1.json`; both scoped V2 family contracts were registered; five source masters were preserved; the four approved runtime states were normalized, imported and validated; and the six-frame `field_arming` source remains explicitly source-pending against its eight-frame contract. Structured evidence is `custodian/docs/ai_context/asset_audits/ASH_BELL_SURFACE_LIFT_V2_INTAKE_20261013.json` with two Asset V2 ingest job receipts under `custodian/asset_drop/logs/`.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: The source staging tool originally rooted archive paths under `custodian/`, producing an unintended nested path; the defect was corrected and the five masters were restaged at canonical paths. Godot import also emitted two unrelated `.uid` files during broad project import; those are excluded from task changes.
- Root cause / contributing factors: The staging tool’s default project root and review/inbox/contract paths mixed repository-root-relative archive paths with `custodian/`-relative metadata paths.
- Prevention / pipeline improvement: Source staging now resolves the repository root consistently and has a focused source-only pending-status regression test.
- Tooling / docs drift discovered: Asset V2 status previously did not recognize hash-pinned approved source-work-only states as `source_pending`; this was corrected. Dropbox path/registry drift remains and is explicitly deferred.
- Follow-up: fixed-in-scope
- What worked: Exact-hash review provenance and per-state decisions allowed four states to ship while preserving the arming shortfall honestly.

## Handoff

- Next workstream: `review-ash-bell-surface-lift-v2-asset-intake`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Next action: Land and archive this implementation, then execute its paired fresh-context independent review. Do not wire scenes or modify traversal. Keep `field_arming` source-pending until an exact reviewed eight-frame source exists; reconcile the package’s Dropbox batch path/registry afterward as a bounded lifecycle cleanup.
- Blockers or open questions: None for this intake. Genuine reviewed eight-frame `field_arming` artwork and Dropbox path/registry reconciliation remain follow-ups owned by subsequent work.
