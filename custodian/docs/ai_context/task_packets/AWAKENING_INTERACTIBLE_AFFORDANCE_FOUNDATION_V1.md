# AWAKENING INTERACTIBLE AFFORDANCE FOUNDATION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-interactible-affordance-foundation-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `awakening-interaction-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-awakening-interactible-affordance-foundation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `afb1f1c5f145fec42f9a3f5a492ab31d5ffc138d`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Visual review: `none`
- Goal: Establish one narrow visual-affordance mounting/presentation authority for actual Awakening interactibles while auditing every posted marker against live gameplay nodes. Preserve target selection, prompts, progression, collision, lighting, and existing art authorities.
- Completion boundary: Real live interactibles have unambiguous marker/owner mappings, data-driven long/mid/near presentation descriptors and no art-dependent boot failure. No marker without a live interaction owner produces actionable highlights/prompts.
- Current measured state: `AwakeningFirstReturn._build_interactables()` instantiates Crèche Console, damaged Port readout and one two-station TransitLift. `Zone04_LockerReliquary/SidearmLocker` is scene-instanced. Layout MARKERS calls `lift_mechanism` an interactable but there is no separate mechanism interactible node. Other marked lore/Attestation/Register/Checkpoint/Gate/Chapel content is principally scenic, not a live interaction.
- Evidence: `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md`; the screenshot/user note in Authoring chat; live `awakening_layout.gd`, `awakening_first_return.gd`, `awakening_transit_lift.gd`, `world_readout_interactable.gd`, `sidearm_locker_interactable.gd`.
- Task-specific authority: Layout owns zone/marker coordinates; each current node owns gameplay interaction state; Operator owns `interaction_target`; HUD owns prompt display; new affordance presenter owns visuals only.
- Work surface: `custodian/game/world/awakening/awakening_layout.gd`; `custodian/game/world/awakening/awakening_first_return.gd` (wiring only); `custodian/scenes/awakening_first_return.tscn`; new `custodian/game/world/awakening/awakening_interactible_affordance_presenter.gd` or equivalent narrow presenter; focused smoke; `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/CURRENT_STATE.md`.
- Change:
  1. Build a measured marker-to-live-owner audit of all Awakening MARKERS including true interactible, marker-only, lift-station, trigger, encounter, and future. Record discrepancies in machine-readable evidence. For `lift_mechanism`, demonstrate whether a separate owner exists; if not, reclassify it as decorative/inert without changing its placement or inventing an interaction.
  2. Add a lightweight presenter/descriptor bound by existing marker ID and interactible NodePath, supporting family/art parts, world-space mount offset, long-range silhouette, mid-range floor/dressing and near-range focus/status indicator. Do not add a new interaction registry, gameplay target radius, or redundant input handler.
  3. Mount visual-only scene children at existing zone SetPieces/Interactables, deriving world anchors from Layout. Make offsets explicit per art instance, not new gameplay positions. Allow both Lift lower/upper station mounts to share a single real lift gameplay owner.
  4. Read existing target/state changes: available/disabled/used and focused/unfocused, but never decide whether interaction is allowed. Use transition-driven presentation refresh and bounded focus updates, not full-scene scans.
  5. Missing art is permitted: visual parts remain absent/disabled with no texture-load spam; preserve existing console, P-9, lift and Gate presentation. Inert markers never gain focus beacons suggesting press-to-use.
  6. Provide a concise no-art smoke and a read-only diagnostic snapshot of real owner/marker/visual mount state. Wire ownership to validation_manifest; document any current marker vs runtime drift.
- Preserve: Crèche acknowledgement, P-9 one-shot grant, two-station lift transit, damaged Port status readout, existing HUD target behavior, zone art registration including locked Dust→Connector→Locker composition, geometry/navigation and camera/lighting.
- Non-goals: No new art/images, no generic glowing highlight on every set-piece, no new supply/Continuity Port/Hub gameplay, no 04→05 connector reconstruction.
- Acceptance:
  1. Four live owners including both distinct lift station anchors map to actual runtime nodes; no nonexistent owner is advertised.
  2. Existing target/HUD interactions and all gameplay semantics are unchanged.
  3. Absence of future art does not fail scene load or emit warnings per frame.
  4. Affordance host has no gameplay collision, no Nav edits, no duplicate per-frame target scan.
  5. New focused marker/owner parity smoke and Awakening progression/locker/lift/geometry tests pass.
- Validation: Focused new parity/host smoke; `awakening_first_return_progression`; `awakening_designation_locker_presentation`; existing lift/04→05/05→06/geometry checks selected by live manifest; `python3 custodian/tools/validation/run_validation.py --changed --json`; `git diff --check`.
- Task overrides: `none`
- Deferred: Art/FX ingestion and visual signoff happen in art-gated successors.

## Context Pack
- Repomix: `none`

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `No gameplay interaction path replaced; visual overlay is additional and optional.`
- Evidence: `<fill at closeout>`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `Prompt-only world discoverability and ambiguous marker kind.`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `Marker/live-owner parity gate and Asset V2 visual mounting contract.`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `review-awakening-interactible-affordance-foundation-v1`
- What worked: `Existing scene node and Operator/HUD target authority.`

## Next Handoff
- Next workstream: `review-awakening-interactible-affordance-foundation-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none`
- Next action: `Fresh-context review, then art-consuming successor once approved assets arrive.`
- Blockers or open questions: `None to claim.`
