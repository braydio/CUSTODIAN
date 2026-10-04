# OPERATOR UNARMED DEFENSE SOURCE PROMOTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-unarmed-defense-source-promotion`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `none`
- Locks: `operator-assets`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `03b6221adb01402b1cf4393b9a1773cdd519f6ae`
- Goal: Turn the newly generated unarmed-defense source-work set into reviewed, registration-correct 96×96 Operator production assets through Source Session + Asset Pipeline V2 without allowing raw generator output to overwrite live canonical art.
- Completion boundary: Done when all ten east-facing source-work candidates are triaged against the live canonical defense families; each accepted candidate is normalized through an approved content-addressed Source Session plan, produces exact 96×96-frame output with true alpha, is staged under the Asset V2 inbox with the correct family schema, ingested/published with provenance, and is either adopted by its owning runtime packet or recorded as approved dormant content. Existing live actions are not replaced without explicit visual approval and deterministic registration/timing evidence; rejected candidates remain source-work only and never enter runtime.
- Current measured state: Latest main contains ten RGBA/alpha source-work files under `custodian/asset_drop/source_work/operator/unarmed_defense_10_generated/`. `temp/ASSET_MANIFEST.json` records each raw generated image as **2172×724**, even though its semantic filename declares a 96px target cell. The set is: `block_hold_01 e 5f`, `block_exit_01 e 4f`, `block_break_01 e 3f`, `block_break_recovery_01 e 6f`, `block_heavy_recoil_01 e 4f`, `block_light_recoil_01 e 3f`, `block_enter_01 e 4f`, `parry_success_01 e 5f`, `parry_miss_01 e 8f`, and `parry_01 e 5f`. The manifest labels the family `owner=operator/profile=unarmed/group=defense/direction=e/source_role=full_body_reference/target_presentation=modular lower_body + upper_body`. These are **source-work candidates, not runtime-ready strips and not Asset V2 inbox inputs yet**.
- Evidence: `temp/ASSET_MANIFEST.json`; the ten files under `custodian/asset_drop/source_work/operator/unarmed_defense_10_generated/`; current canonical Operator manifest/reachability; archived `operator-art-registration-profile-review-corrections-1` receipt proving content-addressed normalization-plan protection; current guard/parry runtime packets.
- Task-specific authority: `design/04_architecture/ASSET_PIPELINE_V2.md`; Operator Asset V2 adapter/profile; Source Session + Operator registration profile; `design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md`; current defense runtime manifest/reachability.
- Work surface: Source Session/registration for only these ten source-work files; `custodian/asset_drop/inbox/operator/`; canonical Operator source/runtime publication for accepted assets; generated manifest/reachability/registration evidence. Runtime behavior changes remain in the owning guard/parry packets.
- Change:
  1. Register each raw source-work candidate through the current Source Session/registration-profile flow before resizing. Use the repository `pixelart` alias with the approved crisp `--choose 1` route and the Source Session's content-addressed normalization plan; do not invoke the converter directly and do not hand-edit a protected plan after approval.
  2. Produce exact target strips at 96×96 per frame. Required accepted output dimensions are:
     - `block_hold_01 e 5f` -> **480×96**
     - `block_exit_01 e 4f` -> **384×96**
     - `block_break_01 e 3f` -> **288×96**
     - `block_break_recovery_01 e 6f` -> **576×96**
     - `block_heavy_recoil_01 e 4f` -> **384×96**
     - `block_light_recoil_01 e 3f` -> **288×96**
     - `block_enter_01 e 4f` -> **384×96**
     - `parry_success_01 e 5f` -> **480×96**
     - `parry_miss_01 e 8f` -> **768×96**
     - `parry_01 e 5f` -> **480×96**
     Every accepted strip must remain RGBA with true alpha and use the approved Operator registration anchor.
  3. The Asset V2 inbox naming convention for an accepted full-body candidate is `custodian/asset_drop/inbox/operator/operator__full_body__unarmed__defense__<action>__e__<N>f__96.png`. If the reviewed production presentation requires split layers, the accepted split names are `operator__lower_body__unarmed__defense__<action>__e__<N>f__96.png` and `operator__upper_body__unarmed__defense__<action>__e__<N>f__96.png`. Do not infer a split merely because the raw manifest says the target presentation is modular; split only where the owning runtime composition actually needs it and seam/registration validation is green.
  4. Asset-family schema for every accepted output: owner `operator`; profile `unarmed`; group `defense`; action exactly the approved semantic action; direction `e` (and separately reviewed `w` counterpart if later produced); layer `full_body|lower_body|upper_body|fx`; frame size `96x96`; exact frame count above; loop/timing copied from the owning canonical action contract, never guessed from generator output.
  5. Treat existing live actions as replacement candidates, not automatic upgrades. `block_enter_01`, `block_hold_01`, `parry_01`, `parry_success_01`, and `parry_miss_01` already have live canonical consumers/identities. Before replacing any of them, compare registration, silhouette, timing/clock compatibility and runtime-scale read against the current production asset; require explicit human art approval. If not approved, leave live art untouched.
  6. Treat `block_exit_01`, `block_light_recoil_01`, `block_heavy_recoil_01`, `block_break_01`, and `block_break_recovery_01` as candidate semantic additions. Publish only after the owning runtime contract confirms the action name/layer shape. Publishing a new identity must not silently change guard timing or make animation completion simulation authority.
  7. West/counterpart production is a separate reviewed output. Do not runtime-mirror a canonical identity and do not auto-generate W unless the active Operator counterpart policy plus registration review approves it.
  8. Accepted source goes through Asset Pipeline V2 into canonical source/runtime under `custodian/content/sprites/operator/{source,runtime}/animations/unarmed/defense/<action>/`; preserve inbox/archive/source/runtime receipts and generated manifest/reachability truth. Never copy raw `source_work` directly to runtime.
- Preserve: all current guard/parry gameplay timing; current canonical assets until explicitly superseded; Asset V2 provenance; Source Session plan integrity; true-alpha pixel-art requirements; human ownership of subjective art approval.
- Non-goals: No guard/parry runtime wiring in this packet. No auto-approval of generated art. No attempt to force all ten candidates live. No diagonal/south expansion. No FX invention for actions whose candidate set contains only body art.
- Acceptance: Every source-work file has a disposition (`accepted-for-normalization`, `approved-and-published`, `rejected`, or `deferred`) with evidence; every published strip has exact dimensions/frame count/alpha/registration; no raw 2172×724 generator output reaches the Asset V2 inbox or runtime; replacement assets have explicit human approval; Asset V2 plan/status/doctor and Operator registration/contract checks are green; generated manifest/reachability matches the actual published set.
- Validation: Source Session plan/verify/review/handoff checks first; exact dimensions/alpha/registration/anchor metrics; Asset V2 dry-run/apply/status/doctor; Operator animation contract/reachability after publication. Use tight contact sheets/ROI at native 96px scale for human art approval. Do not run gameplay Moment Forge in this asset-only packet; owning runtime packets perform final in-game evidence.
- Task overrides: `none`
- Deferred: Guard-break FX is still not present in this ten-file body-only set and remains an explicit requirement of `operator-guard-break-presentation` unless that packet deliberately accepts an existing production impact FX after review.

## Handoff

- Next action: Human review the ten raw source-work candidates, then normalize only the approved candidates through Source Session. Keep existing live canonical families unchanged until a replacement is explicitly accepted.
- Best starting files: `temp/ASSET_MANIFEST.json`; `custodian/asset_drop/source_work/operator/unarmed_defense_10_generated/`; Source Session registration/profile tooling; current canonical Operator defense manifest/reachability.
- Blockers or open questions: Subjective visual approval is required before any existing live canonical action is replaced. The raw files are not production-sized.
