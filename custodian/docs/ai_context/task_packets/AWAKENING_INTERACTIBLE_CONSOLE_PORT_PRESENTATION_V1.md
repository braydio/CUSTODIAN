# AWAKENING INTERACTIBLE CONSOLE PORT PRESENTATION V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-interactible-console-port-presentation-v1`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `review-awakening-interactible-affordance-foundation-v1, review-awakening-interactible-affordance-asset-v2-contracts-v1`
- Locks: `awakening-interaction-presentation, awakening-interactible-asset-contracts`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual, asset-pipeline`
- Paired review workstream: `review-awakening-interactible-console-port-presentation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `afb1f1c5f145fec42f9a3f5a492ab31d5ffc138d`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `required`
- Goal: Give Crèche Console and damaged Undergate Port Console a strong physical/mid-distance read using only their existing interaction/readout owners.
- Completion boundary: Both actual interactibles have recognizable silhouettes before prompt range. Crèche acknowledgement/repeat readout and Port damaged status semantics remain unchanged. No duplicate hero art/extra interaction; scene alpha, anchors and geometry verified; human visual approval recorded.
- Current measured state: `AwakeningFirstReturn._build_interactables()` constructs `CrecheConsole` and `PortStatusPlaque` as `AwakeningPlaqueInteractable` instances. Crèche's existing `awakening_creche_console_activation_fx` is interaction-feedback art, not a full idle affordance. Port remains a broken read-only status terminal.
- Evidence: `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md`; live files listed in Work surface; human playtest screenshot/feedback in Authoring chat.
- Task-specific authority: AwakeningLayout owns location/marker kinds; real interactible nodes own gameplay; Asset V2 owns art; presentation-only overlay cannot manufacture gameplay semantics.
- Work surface: `custodian/game/world/awakening/awakening_first_return.gd`; `custodian/game/world/awakening/awakening_plaque_interactable.gd`; `custodian/game/world/interactions/world_readout_interactable.gd`; `custodian/game/world/awakening/awakening_layout.gd`; `custodian/scenes/awakening_first_return.tscn`; `custodian/content/metadata/assets/families/awakening_interact_{support,terminal,port,shared_fx}.asset.json`; directly affected focused validation.
- Change:
  1. ART GATE: Keep blocked/manual until exact required support/terminal/port/FX states are approved in the specified Dropbox batch, checksum-validated, normalized, Asset V2 `verified`, and reviewed in context. Promote implementation/review together only after the gate and predecessor reviews pass.
  2. Bind `console_pedestal`, `console_backplate`, `screen_glow`, floor pad, beacon and support dressing to existing `zone01_creche.creche_console` (112,144). Prefer reuse of existing Crèche console body when matching dimensions/role; never stack two body sprites if one already fulfills silhouette.
  3. Bind damaged body, backplate, floor inset, failing Port status beacon and low-key readout flicker at existing `zone06_undergate.port_status_plaque` (128,-4016), keeping `PORT_READOUT` status-only and no opening gate or route grant.
  4. Use foundation's dedicated visual-only host; measure visual offset from actual room plates (including draw order) instead of shifting gameplay nodes. Preserve existing `show_latched_interaction` and target/HUD prompt logic. Recognition at mid-distance must not depend on prompt text.
  5. Restrained teal screen/failing cyan, local mount light only. Confirm Operator foreground sorting, lit/dark readability, surrounding floor grate/backplate integrity and no new collision. Activation FX retains existing play-once acknowledgement semantics.
  6. Publish minimal two-scene renderer mid-distance/no-HUD and near-distance/focused evidence in Dropbox with this Authoring chat; require explicit human visual approval, not agent self-approval.
- Preserve: All live Crèche/Locker/Lift/Port gameplay, authored Layout, original scene art/LightingDirector, registered 04→05 composition and 05→06 passage, Gate sealed state, Asset V2 pipeline.
- Non-goals: No new Field Terminal, continuity activation, new lore/quest, map geometry or universal console redesign.
- Acceptance:
  1. Both actual interactibles have recognizable silhouettes before prompt range.
  2. Crèche acknowledgement/repeat readout and Port damaged status semantics remain unchanged.
  3. No duplicate hero art/extra interaction; scene alpha, anchors and geometry verified; human visual approval recorded.
- Validation: awakening_first_return_progression; awakening_undergate_lighting; awakening_art_registration; interaction_feedback console activation; focus/layout smoke; Asset V2 doctor; real renderer; --changed; git diff --check
- Task overrides: `none`
- Deferred: Further subjective art tuning only after explicit human decision; no asset gate bypass.

## Asset and pipeline gate
- Artwork authority: `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md`, including frame sizes, RGBA alpha, state names, source-work and inbox paths.
- Dropbox canonical batch root: `/CUSTODIAN/asset_batches/awakening-interactible-affordances/<batch_id>/`.
- **Not claimable**: ART UNAVAILABLE. Remain draft/manual until approved source PNGs, SHA-256, frame/alpha validation, human style approval, Asset V2 verified status, and predecessor reviews are documented. Promote this packet and its review together after checking current main and regenerating the queue index.
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
- Follow-up: `review-awakening-interactible-console-port-presentation-v1`
- What worked: `Reuse of Layout, established interactions and existing V2 schema.`

## Next Handoff
- Next workstream: `review-awakening-interactible-console-port-presentation-v1`
- Next packet state: `blocked`
- Refresh owner: `human-art-approval`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `Record exact art/hash/Asset V2 verified proof and promote implementation/review pair after predecessor gate.`
- Next action: `After implementation lands, claim fresh-context paired review.`
- Blockers or open questions: `Required art and predecessor reviews are not yet verified; do not claim.`
