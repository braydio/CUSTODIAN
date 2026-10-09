# AWAKENING DESIGNATION LOCKER VISUAL REAUTHOR V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-designation-locker-visual-reauthor-v1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `asset-downloads-intake-sweep`
- Locks: `asset-pipeline, awakening-art-registration`
- Kind: `implementation`
- Review: `none`
- Review stage: `post-land`
- Review modes: `asset-pipeline, runtime, visual`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `0`
- Reviewed main: `c4c56d175d4e66528b450b6872d888d3ced7eab6`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a`
- Branch: `agent/awakening-designation-locker-visual-reauthor-v1`
- Goal: `Replace the live P-9 Designation Locker art with the approved reauthored four-state family while preserving the existing P0 Asset V2 contract, one-shot opening animation, wall-integrated placement, collision footprint, interaction flow, P-9 grant semantics, and Awakening progression.`
- Completion boundary: `The approved Dropbox handoff is hash-verified, prior canonical source/runtime provenance is preserved, all four states are published through the existing awakening_designation_locker family, the 8-frame authorization strip remains 128×160 per frame at 10 FPS and one-shot, the live locker still transitions closed → authorize_open → open_loaded → empty and grants P-9 exactly once, and focused runtime plus in-scene visual evidence confirms the replacement remains correctly registered in Zone04 without gameplay/geometry drift.`
- Current measured state: `The predecessor asset-downloads-intake-sweep is complete and landed. This slice consumed Dropbox revision 65d3b9b7c35cd915cdd61 at the packet canonical path, verified outer SHA-256 ff188d3d43a49a970126b7e9740cec3f464c60238bbb167ea38378b9bc17a768, preserved prior source masters, and published all four replacement states through the existing P0 awakening_designation_locker family. SidearmLockerInteractable remains the sole runtime state/P-9 authority; focused smoke and five-state Zone04 capture pass with the existing (88, -24) visual offset and unchanged gameplay geometry.`
- Evidence: `custodian/content/metadata/assets/families/awakening_designation_locker.asset.json; custodian/game/world/home/sidearm_locker_interactable.gd; custodian/tools/validation/awakening_designation_locker_presentation_smoke.gd; design/04_architecture/AWAKENING_ASSET_MANIFEST.md; Dropbox /CUSTODIAN/implementation_inputs/awakening_designation_locker_reauthor_handoff_v1.zip.`
- Task-specific authority: `awakening_designation_locker.asset.json owns semantic state/frame contract; SidearmLockerInteractable owns runtime state transitions and P-9 grant; awakening_layout.gd plus the existing scene own anchor/footprint; Asset Pipeline V2 owns normalization publication/runtime naming.`
- Work surface: `custodian/asset_drop/source_work/awakening/awakening_designation_locker/; custodian/asset_drop/inbox/awakening_designation_locker/; canonical awakening_designation_locker runtime/catalog/archive outputs; sidearm_locker_interactable.gd only if an objective visual-registration correction requires a sprite-only offset adjustment; focused designation-locker smoke and visual evidence.`
- Change: `Install the approved art replacement through Asset V2, preserve the exact existing family and gameplay contract, and prove the new visual family in the live Locker Reliquary. Do not redesign the locker mechanic or use this slice to reauthor unrelated Awakening props.`
- Preserve: `P-9 exactly-once grant; closed/open/empty state machine; 84 px interaction distance; authored interaction anchor; Layout p9_locker footprint; shallow wall-integrated collider; existing zone geometry; current progress flags; current family ID/state IDs/runtime consumer; 8 frames at 10 FPS, non-looping.`
- Non-goals: `No gameplay rebalance; no new locker state; no change to P-9 item definition; no new interaction prompts; no zone/room redesign; no Reliquary plate regeneration; no generic fixture placement; no replacement of welded/recalled lockers; no broad Awakening art convergence.`
- Acceptance: `All four handoff states verify against MANIFEST hashes; source history is preserved; Asset V2 publishes closed 128×160, authorize_open 1024×160 as 8×128×160 @10 FPS one-shot, open_loaded 128×160, and empty 128×160; canonical runtime paths remain those already consumed by SidearmLockerInteractable; designation-locker presentation smoke passes; the P-9 is granted exactly once; in-scene capture proves no wall/sconce clipping, no floor-floating read, no frame-to-frame registration jump, and correct closed/open_loaded/empty visual progression.`
- Validation: `Run package/hash/dimension/alpha preflight; live Asset V2 plan/replace/status/doctor for awakening_designation_locker; awakening_designation_locker_presentation_smoke.gd; the smallest relevant Awakening progression/geometry smoke if runtime code or placement changes; one compact visual evidence sequence of closed, representative authorize_open frames, open_loaded, and empty in Zone04; then git diff --check and current changed-file validation.`
- Deferred: `Any reauthor decision for Crèche Recovery Alcove, Crèche Console, Dust Lung Lift, BAKED_ONLY Crèche/Ambulatory fixture libraries, or wider Awakening presentation convergence remains a separate visual-review/planning slice.`

## Immutable Dropbox Input

Remote handoff:

`/CUSTODIAN/implementation_inputs/awakening_designation_locker_reauthor_handoff_v1.zip`

Dropbox file ID:

`id:8NXqdXuW6GUAAAAAAAACdw`

Visual-review contact sheet:

`/CUSTODIAN/visual_review/awakening_designation_locker_reauthor_v1_contact_sheet.png`

Dropbox review file ID:

`id:8NXqdXuW6GUAAAAAAAACeA`

The implementation ZIP is authoritative for supplied bytes and contains:

- `MANIFEST.json`
- `CODEX_IMPLEMENTATION.md`
- `PACKING_NOTES.md`
- `README.md`
- `VALIDATION.txt`
- `CONTACT_SHEET_RUNTIME.png`
- `source_work/awakening_designation_locker/*`
- `inbox/awakening_designation_locker/*`

Do not regenerate or artistically reinterpret the supplied replacement inside this packet.

## Live Family Contract

Family:

`awakening_designation_locker`

Kind:

`world_prop`

Priority:

`P0`

Canvas:

`128×160`

Direction:

`omni`

States:

| state | required | role | frames | normalized input | runtime behavior |
| --- | --- | --- | ---: | --- | --- |
| `closed` | yes | body/state/closed | 1 | 128×160 | idle/rest state |
| `authorize_open` | yes | body/interaction/authorize_open | 8 | 1024×160 horizontal strip | 10 FPS, one-shot |
| `open_loaded` | yes | body/state/open_loaded | 1 | 128×160 | P-9 visible / ready to take |
| `empty` | yes | body/state/empty | 1 | 128×160 | unloaded retention hardware |

The live family contract is already correct. **Do not replace it with the handoff manifest.** The handoff manifest only describes supplied files.

## Asset V2 Intake

1. Sync/rebase current main and inspect live repository AGENTS before acting.
2. Fetch the exact Dropbox ZIP. Do not mutate or delete the remote.
3. Verify the package manifest and every supplied PNG SHA-256.
4. Confirm the package normalized inputs are RGBA with true alpha and exact dimensions.
5. Preserve the current canonical source masters under a clearly named `pre_handoff_*` folder before replacement.
6. Copy package source masters to the existing canonical source-work family directory. If package source filenames differ from current repository source naming, preserve semantics and use the live family's canonical source naming rather than creating duplicate parallel names.
7. Copy normalized package inputs to:
   - `custodian/asset_drop/inbox/awakening_designation_locker/closed.png`
   - `custodian/asset_drop/inbox/awakening_designation_locker/authorize_open.png`
   - `custodian/asset_drop/inbox/awakening_designation_locker/open_loaded.png`
   - `custodian/asset_drop/inbox/awakening_designation_locker/empty.png`
8. Discover current Asset V2 syntax with:
   `python3 custodian/tools/assets/asset.py --help`
9. Run the current equivalent of plan → replace/ingest → status → doctor for `awakening_designation_locker`.
10. Asset V2 owns canonical runtime filenames, import sidecars, catalog truth, archive/receipt, and inbox cleanup.

Do not hand-copy generated art directly into runtime.

## Runtime Preservation Contract

The current runtime authority is:

`custodian/game/world/home/sidearm_locker_interactable.gd`

Preserve these semantics:

`CLOSED → authorize_open → OPEN/open_loaded → P-9 taken → EMPTY`

Specifically:

- `authorize_open` plays once at 10 FPS;
- completion switches to the independent `open_loaded` plate;
- P-9 is **not** granted merely by opening;
- P-9 is granted only on the subsequent take interaction;
- grant remains exactly once;
- empty locker leaves the interactable group;
- repeated interaction cannot duplicate P-9;
- still states remain independent textures, not atlas slices of the opening strip.

No runtime code change is expected merely to replace the art.

## Spatial Contract

Preserve current world authority unless objective visual evidence proves a sprite-registration defect:

- locker interaction anchor: `(832, -1952)`
- physical collider: `112×32`
- collider local offset: `(88, 64)`
- footprint center: `(920, -1888)`
- sprite visual offset: `(88, -24)`
- interaction distance: `84`

The art canvas is deliberately larger/taller than the physical wall projection. Do **not** resize collision to the visual canvas.

### Bounded registration correction

If the new art is objectively misregistered in the live Zone04 capture, a sprite-only offset correction is allowed.

Such a correction must:
- keep the locker node / interaction anchor unchanged;
- keep collider and Layout footprint unchanged;
- change only the visual sprite offset;
- be the minimum pixel correction needed to seat the prop into the existing wall recess;
- update the focused smoke's expected offset;
- include before/after capture evidence.

Do not move the room, locker node, P-9 marker, or collision to accommodate the new illustration.

## Visual Acceptance

Capture the locker **in the actual Locker Reliquary**, not on a neutral gallery background.

Required evidence:

1. `closed`
2. one early `authorize_open` frame
3. one late `authorize_open` frame
4. `open_loaded`
5. `empty`

Verify:

- silhouette remains seated in the east-wall recess;
- it does not clip neighboring sconces/architecture;
- bottom registration does not float over the floor;
- the eight opening frames do not visibly jump position/scale;
- final opening frame flows naturally into `open_loaded`;
- `open_loaded` and `empty` preserve the same outer housing;
- amber illumination remains readable without overwhelming the room;
- P-9 cradle reads clearly enough at gameplay scale;
- the new family materially improves dimensional/material cohesion with the newer Reliquary / Dust Lung / Undergate art.

Human aesthetic approval already exists for the generated family. This gate is for integration/registration defects, not for asking Codex to redesign the art.

## Focused Validation

At minimum:

`custodian/tools/validation/awakening_designation_locker_presentation_smoke.gd`

If no code/placement changes are necessary beyond Asset V2 outputs, do not expand into unrelated gameplay suites.

If the sprite offset changes, also run the smallest Awakening geometry/progression checks that own that constant/placement.

Finish with:
- `git diff --check`
- current changed-file validation.

## Documentation Drift

Update current-truth docs only if they describe the old locker appearance, old source provenance, or stale runtime hash/status.

Do not rewrite historical packets/summaries simply because art changed.

The active `AWAKENING_ASSET_MANIFEST.md` should continue to describe the Designation Locker as the P0 wall-integrated institutional P-9 reliquary. If exact text materially contradicts the new live presentation, make only the smallest current-truth correction.

## Completion Report

- Dropbox ZIP: `/CUSTODIAN/implementation_inputs/awakening_designation_locker_reauthor_handoff_v1.zip`, file ID `id:8NXqdXuW6GUAAAAAAAACdw`, revision `65d3b9b7c35cd915cdd61`, SHA-256 `ff188d3d43a49a970126b7e9740cec3f464c60238bbb167ea38378b9bc17a768`.
- Previous source provenance preserved at `custodian/asset_drop/source_work/awakening/awakening_designation_locker/pre_handoff_20261007/source/`.
- Asset V2 job: `job_20261007T205424Z_80b02bf4`.
- Runtime outputs and SHA-256:
  - `custodian/content/sprites/environment/props/awakening/awakening_designation_locker/runtime/body/awakening_designation_locker__body__state__closed__omni__1f__128x160.png` — `c4899a5ea165eb000ae8aa7b7f6dcfe4ed542f1191a1f60957e88ab01e4c1eae`.
  - `custodian/content/sprites/environment/props/awakening/awakening_designation_locker/runtime/body/awakening_designation_locker__body__interaction__authorize_open__omni__8f__128x160.png` — `84675b649b8cf3b477e2b87ecd2a7ad405dfab1babb20d9146b4872e59b04156`.
  - `custodian/content/sprites/environment/props/awakening/awakening_designation_locker/runtime/body/awakening_designation_locker__body__state__open_loaded__omni__1f__128x160.png` — `4d79cd27bf1c9091a4636b0c54131c2bf51524b8fd9a739f6c85076ab143a04d`.
  - `custodian/content/sprites/environment/props/awakening/awakening_designation_locker/runtime/body/awakening_designation_locker__body__state__empty__omni__1f__128x160.png` — `a81ef45060d0b0f4ac44bcc91073c59e91ce1c3aafb9c8f4a873d7918b208b10`.
- Contract: three independent 128×160 stills; `authorize_open` is 8 horizontal 128×160 frames at 10 FPS, one-shot. Family contract and runtime state IDs were unchanged.
- Sprite offset remained `(88, -24)`; the five-state Zone04 capture shows stable placement through closed, early opening, final opening, open_loaded, and empty. Evidence: `reports/awakening_designation_locker_reauthor_contact_sheet.png`.
- Focused `awakening_designation_locker_presentation` smoke: passed; P-9 remains withheld until the take interaction and is granted exactly once.
- Asset V2 status: 4/4 required states ready; doctor healthy. Changed-file validation: passed (Asset Pipeline V2, review-pairing contract, visual-review handoff, and designation-locker presentation, 4/4).
- Documentation drift corrected: packet measured state and active task index had stale predecessor dependency wording; current-state docs and design authority required no change.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `Dropbox revision and outer hash are recorded above; all source and normalized inputs matched MANIFEST.json; prior masters remain under pre_handoff_20261007/source; Asset V2 job_20261007T205424Z_80b02bf4 published four paths; family status is 4/4 and doctor healthy; focused presentation smoke and changed-file validation passed; the in-scene five-state contact sheet confirms stable placement and unchanged gameplay registration.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `The packet Current measured state and task index still said the predecessor was only partially landed after its completion; both were corrected in this slice.`
- Root cause / contributing factors: `Predecessor closeout updated dependency authority but did not refresh this packet's descriptive state and manual README note.`
- Prevention / pipeline improvement: `Refresh dependent packet measured-state prose and task index notes in the same closeout that archives the predecessor.`
- Tooling / docs drift discovered: `Stale predecessor status in this packet and the Active Awakening Hero-Art Reauthor task index note; dispatcher dependency status was accurate.`
- Follow-up: `fixed-in-scope`
- What worked: `The Asset V2 transaction and focused in-scene smoke provided direct provenance and behavior proof.`

## Next Handoff

After this lands, return to the Awakening art-convergence review and compare only independently visible hero systems against the new art bar: Crèche Recovery Alcove, Crèche Console, and Dust Lung Lift. Do not automatically reauthor BAKED_ONLY fixture libraries.

- Next workstream: `awakening-handoff-readiness-art-convergence-v1-r1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a`
- Refresh reason: `none`
- Next action: `After the declared Awakening paired reviews complete, claim the art-convergence packet and compare only the Recovery Alcove, Console, and Dust Lung Lift against this locker.`
- Blockers or open questions: `The art-convergence packet remains gated on review-awakening-room-connectors-polish, review-awakening-interaction-feedback-console-activation, and review-awakening-lower-upper-spine-connection.`
