# AWAKENING INTERACTIBLE LOCKER LIFT PRESENTATION V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-interactible-locker-lift-presentation-v1`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-awakening-interactible-affordance-foundation-v1, review-awakening-interactible-affordance-asset-v2-contracts-v1, review-transit-lift-runtime-foundation-v1`
- Locks: `awakening-interaction-presentation, awakening-interactible-asset-contracts`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual, asset-pipeline`
- Paired review workstream: `review-awakening-interactible-locker-lift-presentation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `afb1f1c5f145fec42f9a3f5a492ab31d5ffc138d`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `required`
- Goal: Supplement already-approved P-9 Designation Locker and two-station Dust Lung Lift with approach floors, mounting/authority cues and state-aware indicators without altering their visuals or mechanics.
- Completion boundary: Locker art/state/grant remains exact and mid-distance discoverability increases. Both station affordances track one lift owner and never create a phantom lift-mechanism prompt. Registered composite/05→06 path/lighting/collision preserved and art states verified; human review recorded.
- Current measured state: `SidearmLockerInteractable` draws canonical four-state Asset V2 hero art with `SPRITE_VISUAL_OFFSET = (88,-24)` and one-shot sidearm grant. `AwakeningTransitLift` owns one mobile sprite/interaction, with lower/upper station world positions (384,-3008)/(384,-3424). `lift_mechanism` has no standalone runtime interactible. Locker→Dust registered composition is accepted 1:1.
- Evidence: `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md`; live files listed in Work surface; human playtest screenshot/feedback in Authoring chat.
- Task-specific authority: AwakeningLayout owns location/marker kinds; real interactible nodes own gameplay; Asset V2 owns art; presentation-only overlay cannot manufacture gameplay semantics.
- Work surface: `custodian/game/world/home/sidearm_locker_interactable.gd`; `custodian/game/world/awakening/awakening_transit_lift.gd`; `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/game/world/awakening/awakening_layout.gd`; `custodian/scenes/awakening_first_return.tscn`; `custodian/content/metadata/assets/families/awakening_interact_{locker,lift,support,shared_fx}.asset.json`; directly affected focused validation.
- Change:
  1. ART GATE: Keep blocked/manual until exact locker/lift/support/FX required states are approved on Dropbox and verified through Asset V2, then promote implementation/review pair after predecessor reviews pass. Existing core art stays canonical.
  2. At Layout `p9_locker` marker and actual scene `SidearmLocker`, add shallow relief footing, brass designation seal/inset, warm sconce and correct floor approach cue. Retain original 4-state `closed -> authorize_open -> open_loaded -> empty`, 128×160, one-shot P-9 grant, offset and on-wall relief; DO NOT generate/wire a second full locker body.
  3. Bind individual lower/upper lift call housings, service stop floor plates and cyan ready/busy lamps to the existing two Layout station positions, while retaining one `TransitLift` owner. No duplicate lift buttons, duplicate group registrations or changes to ride duration/current_station logic.
  4. Idle long-read physical presence, mid-read floor/utility mounting, near-read only if actual available state. On emptied locker and during lift busy, lights may show an inert/processing state but never imply an actionable prompt.
  5. Measure 04→05 registration against immutable shared `RegisteredComposition04_05` (Dust→Connector→Locker, 1:1 root at (349,-2585)) and 05→06 passage. Do not conceal the previously noted Dust-side wall/grate mismatch with new prop dressing or change connector geometry.
  6. Provide four visual proofs: Locker before and after recovery; both lower/upper lift stations. Include actual in-game movement and visual layers. Require human sign-off.
- Preserve: All live Crèche/Locker/Lift/Port gameplay, authored Layout, original scene art/LightingDirector, registered 04→05 composition and 05→06 passage, Gate sealed state, Asset V2 pipeline.
- Non-goals: No reauthor of existing locker/lift sprites, no connector rebuild, no teleport/input-lock redesign.
- Acceptance:
  1. Locker art/state/grant remains exact and mid-distance discoverability increases.
  2. Both station affordances track one lift owner and never create a phantom lift-mechanism prompt.
  3. Registered composite/05→06 path/lighting/collision preserved and art states verified; human review recorded.
- Validation: awakening_designation_locker_presentation; awakening_first_return_progression; lift smoke; awakening_04_05_registered_composition; awakening_04_05_registered_composition_fade; awakening_lower_upper_spine_connection; Asset V2 status; renderer; --changed; git diff --check
- Task overrides: `none`
- Deferred: Further subjective art tuning only after explicit human decision; no asset gate bypass.

## Asset and pipeline gate
- Artwork authority: `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md`, including frame sizes, RGBA alpha, state names, source-work and inbox paths.
- Dropbox canonical batch root: `/CUSTODIAN/asset_batches/awakening-interactible-affordances/<batch_id>/`.
- **Not claimable**: ART UNAVAILABLE. Remain draft/manual until approved source PNGs, SHA-256, frame/alpha validation, human style approval, Asset V2 verified status, and predecessor reviews are documented. Promote this packet and its review together after checking current main and regenerating the queue index.
- No gameplay node may bind an unverified runtime art path. Reuse existing authorized hero art first.

## Required visual review handoff

- Publication root: `/CUSTODIAN/visual_review/awakening-interactible-locker-lift-presentation-v1/` via current `publish_review_artifacts.py` protocol after focused objective tests pass.
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`.
- Evidence budget: one before/after contact sheet and at most two representative native-scale stills per setting (more only when temporal animation cannot be judged from stills). Keep review artifacts short-lived/delete-after-review unless explicitly retained.
- External human/ChatGPT questions (must be answered and recorded, not self-approved by the implementer):
  1. Does the P-9 Locker remain the same high-quality wall-integrated existing hero, with clearer approach/readability?
  2. Do both lift call stations look usable and visually connected to one functional lift?
  3. Do busy/empty states avoid promising an action that cannot currently be taken?
  4. Are the floor/trim/grate relationships coherent without hiding or changing the registered Locker→Dust connector?
  5. Are the subtle brass/cyan cues readable but restrained at normal game zoom?
- If no explicit decision is available, implementation stays in its human visual gate. Corrections must be tightly scoped to the answers; no aesthetic acceptance inferred from passing tests.

## Specific runtime binding (refresh 2026-10-10)

**Refresh planning chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166. **Refreshed against:** `main@956cf2114458`. Original Authoring chat stays unchanged.

- Preserve `res://game/world/home/sidearm_locker_interactable.gd` canonical V2 four-state art, calibrated `SPRITE_VISUAL_OFFSET = Vector2(88,-24)`, `authorize_open` eight 128×160 frames at 10 FPS, and one-time P-9 grant. Observe the existing prompt/group behavior; do not draw a second locker hero or create a state owner in the presenter.
- `res://game/world/awakening/awakening_transit_lift.gd` owns one lift and both stations `(384,-3008)`/`(384,-3424)`; use `is_busy()`, `current_station`, `transit_started`, `transit_finished` to display ready/busy indicators. Never create another lift/mechanism prompt.
- Preserve registered 04→05 composite at `(349,-2585)` and the 05→06 passage. Prove before/after P-9 grant and both lift stations at native camera zoom.

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
- Follow-up: `review-awakening-interactible-locker-lift-presentation-v1`
- What worked: `Reuse of Layout, established interactions and existing V2 schema.`

## Next Handoff
- Next workstream: `review-awakening-interactible-locker-lift-presentation-v1`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `Record exact art/hash/Asset V2 verified proof and promote implementation/review pair after predecessor gate.`
- Next action: `After implementation lands, claim fresh-context paired review.`
- Blockers or open questions: `Required art and predecessor reviews are not yet verified; do not claim.`


## Vertical Traversal program refresh gate (2026-10-15)

**Refresh planning chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391  
**Audited main:** `350ee94e4b3b80010c0970903f3418966df3b851`

- Lift mechanics must be hardened/modularized before this presentation slice executes. `review-transit-lift-runtime-foundation-v1` is now a hard predecessor.
- Preserve this workstream identity. Do not create a duplicate lift-polish packet. After B1 review lands, materially refresh this packet against the reusable local-transit API, current Asset V2 source availability and Dust Lung V2 state, then re-run targeted authoring validation before promotion.
- Existing "no teleport/input-lock redesign" language means this presentation packet must not redesign the already-landed B1 mechanics. It does not reinstate today's scene-specific `AwakeningTransitLift` lifecycle as the final reusable authority.
- At refresh, prefer generic lift lifecycle phase/progress signals; preserve exactly one gameplay owner with two physical station affordances. Evaluate existing Operator `lift_braced` presentation, camera motion/shake and audio as consumers without moving lifecycle authority into them.
- `awakening_dust_lung_lift` and `awakening_interact_lift` are Awakening-specific. If reviewed sources are insufficient for machine/platform motion, record an explicit Asset V2 source-creation gate instead of manufacturing runtime placeholders.
