# AWAKENING INTERACTIBLE AFFORDANCE ASSET V2 CONTRACTS V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-interactible-affordance-asset-v2-contracts-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `awakening-interactible-asset-contracts`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline`
- Paired review workstream: `review-awakening-interactible-affordance-asset-v2-contracts-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `afb1f1c5f145fec42f9a3f5a492ab31d5ffc138d`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `none`
- Goal: Register the approved live-affordance art contract without falsely treating ungenerated images as supplied.
- Completion boundary: Seven current family contracts parse and accurately show missing state truth. Required asset registry/generated view agree, with all existing hero art preserved. Future Hub/Supply/Sepulcher/Gate concepts are not introduced into the game or active required tracker.
- Current measured state: Live hero art families `awakening_creche_console`, `awakening_designation_locker`, `awakening_dust_lung_lift` and Gate of Dust are already published; the new manifest is an additive supplement. `REQUIRED_ASSETS.md` is generated from the JSON registry.
- Evidence: `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md`; live files listed in Work surface; human playtest screenshot/feedback in Authoring chat.
- Task-specific authority: AwakeningLayout owns location/marker kinds; real interactible nodes own gameplay; Asset V2 owns art; presentation-only overlay cannot manufacture gameplay semantics.
- Work surface: `custodian/content/metadata/assets/families/*.asset.json`; `custodian/content/metadata/assets/required_assets.registry.json`; `REQUIRED_ASSETS.md`; `custodian/tools/assets/asset.py`; `design/04_architecture/AWAKENING_ASSET_MANIFEST.md`; `custodian/docs/ai_context/CURRENT_STATE.md`; directly affected focused validation.
- Change:
  1. Inspect live V2 schema and all overlapping published assets first. Register only the seven currently relevant proposed families: `awakening_interact_support`, `awakening_interact_terminal`, `awakening_interact_locker`, `awakening_interact_lift`, `awakening_interact_port`, `awakening_interact_wayfinding`, and `awakening_interact_shared_fx`. Preserve actual kind/state sizes and effect frames/loops, omni direction and transparent RGBA.
  2. Reconcile already-satisfied visual roles to existing canonical hero states instead of duplicating core console/locker/lift sprites. The manifest is a planning contract, never proof of source availability.
  3. Register only the 27 live-required art states, minus proven substitutions, as open production demand in `required_assets.registry.json`; regenerate generated `REQUIRED_ASSETS.md` via the live generator. Recommended states remain optional; all 36 deferred states stay unregistered as current-required runtime art.
  4. Establish machine-readable gate ledger per exact family/state, Dropbox batch, PNG checksum, alpha/dimensions, pipeline status and human approval. Source-only Dropbox presence never satisfies implementation art gate; verify Asset V2 status `verified` before consumer promotion.
  5. Use `python3 custodian/tools/assets/asset.py --help` and current schema/doctor to verify parser and source-pending states. Repair direct manifest doc drift around Crèche vs Lift consumer descriptions; do not fabricate output PNGs or replace immutable production art.
- Preserve: All live Crèche/Locker/Lift/Port gameplay, authored Layout, original scene art/LightingDirector, registered 04→05 composition and 05→06 passage, Gate sealed state, Asset V2 pipeline.
- Non-goals: No asset generation or upload; no code that assumes missing PNGs are installed; do not create new gameplay interactibles.
- Acceptance:
  1. Seven current family contracts parse and accurately show missing state truth.
  2. Required asset registry/generated view agree, with all existing hero art preserved.
  3. Future Hub/Supply/Sepulcher/Gate concepts are not introduced into the game or active required tracker.
- Validation: Asset V2 plan/status/doctor for seven families; registry generator --check; awakening_art_registration; --changed; git diff --check
- Task overrides: `none`
- Deferred: Production image generation and art-driven installation remain separate.

## Asset and pipeline gate
- Artwork authority: `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md`, including frame sizes, RGBA alpha, state names, source-work and inbox paths.
- Dropbox canonical batch root: `/CUSTODIAN/asset_batches/awakening-interactible-affordances/<batch_id>/`.
- Claimable without new images. Do not assert that missing states are available.
- No gameplay node may bind an unverified runtime art path. Reuse existing authorized hero art first.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `No interaction gameplay authority replaced.`
- Evidence: `<fill at closeout>`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `Existing visible-world affordances were weak or future markers lacked explicit status.`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `Art-state provenance and marker/owner parity with gameplay-scale human review.`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `review-awakening-interactible-affordance-asset-v2-contracts-v1`
- What worked: `Reuse of Layout, established interactions and existing V2 schema.`

## Next Handoff
- Next workstream: `review-awakening-interactible-affordance-asset-v2-contracts-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: `After implementation lands, claim fresh-context paired review.`
- Blockers or open questions: `None to claim.`
