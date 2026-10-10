# AWAKENING INTERACTIBLE MARKER WAYFINDING V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-interactible-marker-wayfinding-v1`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `review-awakening-interactible-affordance-foundation-v1, review-awakening-interactible-affordance-asset-v2-contracts-v1`
- Locks: `awakening-interaction-presentation, awakening-wayfinding`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual, asset-pipeline`
- Paired review workstream: `review-awakening-interactible-marker-wayfinding-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `afb1f1c5f145fec42f9a3f5a492ab31d5ffc138d`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `required`
- Goal: Improve existing Register, Gate/Rest, Attestation, lore-plaque and optional Chapel wayfinding through noninteractive scenic mounts, with no fake prompt or route ability.
- Completion boundary: Scenic markers are recognizable but cannot be mistaken for live interactibles in prompts or signal groups. Gate remains sealed and all authored traversal/camera/collision intact. Approved selected artwork verified, no duplicated overlay pixels and human approval recorded.
- Current measured state: Layout already posts `register_of_departures`, `gate_aperture`, `rest_checkpoint`, `attestation_dais`, `lore_plaque` and optional Chapel markers as `kind=marker`. Existing `gate_of_dust` sealed components are published and bound. No active Gate-access/Forum/Sepulcher dialogue/grant is posted at these markers.
- Evidence: `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md`; live files listed in Work surface; human playtest screenshot/feedback in Authoring chat.
- Task-specific authority: AwakeningLayout owns location/marker kinds; real interactible nodes own gameplay; Asset V2 owns art; presentation-only overlay cannot manufacture gameplay semantics.
- Work surface: `custodian/game/world/awakening/awakening_layout.gd`; `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/scenes/awakening_first_return.tscn`; `custodian/content/metadata/assets/families/awakening_interact_wayfinding.asset.json`; `custodian/content/metadata/assets/families/gate_of_dust.asset.json`; `design/04_architecture/AWAKENING_FIRST_RETURN.md`; directly affected focused validation.
- Change:
  1. ART GATE: This optional visual slice remains draft/manual until a deliberately selected subset of recommended `awakening_interact_wayfinding` states has source/Dropbox/human art approval and verified V2 routing. Do NOT require all recommended or future states for the current story.
  2. Use Layout marker IDs and scene SetPieces to add subtle Register of Departures panel, Gate rest/checkpoint approach medallion, Attestation dais authority marker, lore plaque frame and optional Chapel orientation piece, only where approved art physically fits.
  3. Make scenic markers visually important without false activation: long-read silhouette, mid-read floor and directed lamplight, **no** active near-read interaction pulse, no Operator target registration and no HUD 'press' hint.
  4. Keep the Gate of Dust sealed, its five existing hero components intact, approach/Chapel routes and unlocks untouched. The Road south reach and existing Gate camera reveal remain as live. Avoid replacing foreground/underlay or creating false walkable paths.
  5. Check dependency and registration relative to currently pending `AWAKENING_PERIMETER_*` presentation families; no edits to their off-route artwork and no blocking of unrelated perimeter tasks.
  6. Publish focused panorama + close shots with HUD toggled; require explicit human recognition verdict: landmark, not usable control.
- Preserve: All live Crèche/Locker/Lift/Port gameplay, authored Layout, original scene art/LightingDirector, registered 04→05 composition and 05→06 passage, Gate sealed state, Asset V2 pipeline.
- Non-goals: No new gate activation, checkpoint save/grant, lore dialogue, chapel reward, route extension or Hub-only machinery.
- Acceptance:
  1. Scenic markers are recognizable but cannot be mistaken for live interactibles in prompts or signal groups.
  2. Gate remains sealed and all authored traversal/camera/collision intact.
  3. Approved selected artwork verified, no duplicated overlay pixels and human approval recorded.
- Validation: awakening_first_return_smoke; awakening_first_return_geometry; awakening_first_return_progression; awakening_art_registration; Gate camera review; Asset V2 doctor; screenshots; --changed; git diff --check
- Task overrides: `none`
- Deferred: Further subjective art tuning only after explicit human decision; no asset gate bypass.

## Asset and pipeline gate
- Artwork authority: `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md`, including frame sizes, RGBA alpha, state names, source-work and inbox paths.
- Dropbox canonical batch root: `/CUSTODIAN/asset_batches/awakening-interactible-affordances/<batch_id>/`.
- **Not claimable**: ART UNAVAILABLE. Remain draft/manual until approved source PNGs, SHA-256, frame/alpha validation, human style approval, Asset V2 verified status, and predecessor reviews are documented. Promote this packet and its review together after checking current main and regenerating the queue index.
- No gameplay node may bind an unverified runtime art path. Reuse existing authorized hero art first.

## Required visual review handoff

- Publication root: `/CUSTODIAN/visual_review/awakening-interactible-marker-wayfinding-v1/` via current `publish_review_artifacts.py` protocol after focused objective tests pass.
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`.
- Evidence budget: one before/after contact sheet and at most two representative native-scale stills per setting (more only when temporal animation cannot be judged from stills). Keep review artifacts short-lived/delete-after-review unless explicitly retained.
- External human/ChatGPT questions (must be answered and recorded, not self-approved by the implementer):
  1. Can you identify the Register, Gate checkpoint, Attestation dais, lore marker and optional Chapel landmarks without HUD captions?
  2. Is it still clear these are scenic landmarks, not currently usable consoles/buttons?
  3. Does Gate aperture remain convincingly sealed, with no false invitation to activate?
  4. Does the added dressing stay coherent with lighting, room art, camera and existing routes?
  5. Are landmark cue brightness and density restrained enough to preserve the scene hierarchy?
- If no explicit decision is available, implementation stays in its human visual gate. Corrections must be tightly scoped to the answers; no aesthetic acceptance inferred from passing tests.

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
- Follow-up: `review-awakening-interactible-marker-wayfinding-v1`
- What worked: `Reuse of Layout, established interactions and existing V2 schema.`

## Next Handoff
- Next workstream: `review-awakening-interactible-marker-wayfinding-v1`
- Next packet state: `blocked`
- Refresh owner: `human-art-approval`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `Record exact art/hash/Asset V2 verified proof and promote implementation/review pair after predecessor gate.`
- Next action: `After implementation lands, claim fresh-context paired review.`
- Blockers or open questions: `Required art and predecessor reviews are not yet verified; do not claim.`
