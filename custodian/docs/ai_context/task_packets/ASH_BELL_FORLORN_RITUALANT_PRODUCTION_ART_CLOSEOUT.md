# ASH-BELL / FORLORN-RITUALANT PRODUCTION ART CLOSEOUT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `ash-bell-forlorn-ritualant-production-art-closeout`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P2`
- Depends on: `review-ash-bell-ritualant-runtime-truth-closeout`
- Locks: `asset-pipeline, ash-bell-art`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `1362ba9569e1`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Goal: Close the genuinely remaining production-art gaps for the already-landed authored Ash-Bell / Forlorn-Ritualant encounter through Asset Pipeline V2, without reopening completed route, dialogue, encounter, or combat authority.
- Completion boundary: Done when the current required-assets registry no longer reports an Ash-Bell / Forlorn-Ritualant production-art need that this packet explicitly accepts; every accepted source is reviewed, staged through `custodian/asset_drop/inbox/...`, published by Asset Pipeline V2 with provenance, wired only where a current consumer contract exists, and validated at native gameplay scale. Unknown animation cadence/directional contracts are resolved before source generation rather than guessed. Runtime encounter behavior and authored-route ownership remain unchanged.
- Current measured state: The authored route, Threadway/lift/travel spine, data dialogue, four-action Ritualant encounter, and canonical 128×128 Asset V2 strips for Ninth Answer, Orra Comes Late, dissolve, and violent death are live. The legacy active packet was archived as `task_packets/archived/ASH_BELL_FORLORN_RITUALANT_AUTHORED_ENCOUNTER.md`. Current required-assets truth still reports: (a) Forlorn-Ritualant locomotion/reaction coverage partial, including directional walk/drag, turning, reactions, and an eight-frame rise; (b) Unarrived Saint apparition polish/directional variants partial; (c) Unarrived procession silhouettes needed; (d) ritual prop sprites needed; and additional chamber dressing/fountain/audio needs tracked separately in the registry. Repository search found no matching reviewed `asset_drop/source_work` source set for these remaining items on the reviewed main, so this packet is blocked on production source/art decisions rather than code.
- Evidence: `custodian/content/metadata/assets/required_assets.registry.json`; `custodian/content/metadata/assets/families/enemy_forlorn_ritualant.asset.json`; `design/02_features/enemy_objective/FORLORN_RITUALANT_ENCOUNTER_DETAILED_SPEC.md`; `custodian/tools/pipelines/build_forlorn_ritualant_spriteframes.py`; current `forlorn_ritualant_animations.tres`; `CURRENT_STATE.md`; archived authored-encounter packet.
- Task-specific authority: Asset Pipeline V2 and current family contracts own publication/provenance; `required_assets.registry.json` owns open production needs; the active Forlorn-Ritualant detailed spec owns visual intent; the landed encounter runtime owns animation/action semantics and may not be redesigned by art intake.
- Work surface: Only reviewed Ash-Bell / Forlorn-Ritualant production source, Asset V2 family contracts/inbox/source/runtime publication, the bounded spriteframes post-process if the `enemy_forlorn_ritualant` family is extended, current encounter presentation bindings, required-assets truth, and focused asset/presentation validation.
- Change:
  1. Re-audit the current requirement registry and runtime consumers before generating or ingesting anything. Close only needs still factual on execution day.
  2. Extend the existing `enemy_forlorn_ritualant` Asset V2 family rather than creating a parallel enemy sprite hierarchy. The current production cell contract is **128×128 RGBA/true alpha**, `auto_mirror=false`. Existing canonical states already cover 8f Ninth Answer at 8 FPS, 8f Orra Comes Late at 8 FPS, 8f dissolve at 6 FPS, and 8f violent death at 8 FPS.
  3. The one currently explicit replacement animation target is the **eight-frame rise**: 8 frames × 128×128 cells = **1024×128 RGBA**. Before authoring, define its final family state/action-group in `enemy_forlorn_ritualant.asset.json` and update the spriteframes builder to consume the canonical V2 output. The current 4f rise remains fallback until the reviewed 8f replacement publishes.
  4. Directional walk/drag, turning, and reaction art remain required, but their exact direction set and frame counts are **not locked by current active authority**. Do not invent a 4-way/8-way set or arbitrary cadence. Human/design review must first record each state name, directions, frame count, FPS, loop flag, and 128×128 cell contract in the family JSON. Only then stage source using the family-approved semantic filename under `custodian/asset_drop/inbox/enemy_forlorn_ritualant/`.
  5. Unarrived procession silhouettes remain a production need with **32×48 per silhouette/cell** in the active detailed spec/registry. The registry currently names `custodian/content/sprites/npcs/ash_bell/unarrived_procession_ghosts_32x48.png`, but does not lock animation frame count/layout. Treat **frame count/layout as unresolved** until the human art brief decides static grouped silhouettes versus authored procession animation. Create a V2 family contract first, then use `custodian/asset_drop/inbox/<approved-family-id>/...`; do not hand-copy to the legacy target path.
  6. Unarrived Saint apparition polish remains partial. The active detailed spec calls for a **64×96** apparition presentation while the current registry/runtime still points at legacy `unnarrived_apparration_01.png`. This is a real naming/publication drift seam. Do not overwrite the live file. Define a dedicated Asset V2 family/state, establish whether the approved production target is one static **1f 64×96** apparition or directional variants, ingest through the family inbox, then migrate the scene consumer only after registration/alpha review.
  7. Ritual prop needs are static **1-frame RGBA** assets with the following locked target dimensions from current requirement/design authority:
     - empty bell frame: **96×96**
     - stilling pin: **32×32**
     - white-thread floor A: **32×32**
     - white-thread floor B: **32×32**
     - white-thread hanging: **32×64**
     - white-thread knot: **16×16**
     Define/reuse one coherent Ash-Bell ritual-prop V2 family before staging. Inbox convention is `custodian/asset_drop/inbox/<approved-family-id>/<family-semantic-filename>.png`; canonical runtime paths are generated by the family contract, not copied by hand into the legacy paths.
  8. Chamber dressing, Dry Fountain transition polish, and audio remain truthful registry needs but are not automatically absorbed unless the execution-time art brief explicitly expands this packet. Keep those registry rows open rather than claiming visual closure from unrelated assets.
  9. Every new/updated asset must pass native-size alpha/bounds/registration checks, Asset V2 plan/apply/status/doctor, requirement-registry reconciliation, and runtime consumer validation. Do not resample finished pixel art at runtime or use generated placeholders as production.
- Preserve: authored Underground route and spawn/lifecycle authority; encounter state/dialogue/combat/timing; existing canonical attack/death strips; White Thread gameplay authority; current production environment plates; true-alpha/native-pixel presentation; requirement-registry truth.
- Non-goals: No route/procgen migration. No combat redesign or retiming. No new lore. No silent replacement of current canonical special/death art. No generic NPC animation framework. No automatic image generation or mirroring. No direct hand-copy from `source_work` to runtime. No closing unrelated chamber/audio requirements without their actual assets.
- Acceptance: Every fulfilled item has a V2 family/state, reviewed source, exact native dimensions/frame contract, provenance, canonical runtime output, consumer proof, and registry status update; the 8f rise is 1024×128 if fulfilled; no unresolved walk/drag/turn/reaction cadence is guessed; procession/apparition publication drift is resolved through explicit family contracts; existing encounter smokes remain green; no open registry item is falsely marked complete.
- Validation: Run Asset V2 plan/status/doctor and family contract checks for each accepted family; `python tools/pipelines/build_forlorn_ritualant_spriteframes.py --check` when enemy animation states change; `godot --headless --path . --script res://tools/validation/forlorn_ritualant_completion_smoke.gd`; authored Underground/route smokes for consumer integrity; requirement-registry/generated-view parity; changed-file validation; `git diff --check`. Use compact native-scale contact sheets/runtime evidence for human art approval only after deterministic asset checks pass.
- Task overrides: `none`
- Deferred: Any animation state whose direction/frame/FPS contract is still unresolved; additional apparition variants beyond the approved brief; chamber dressing, Dry Fountain transition polish, and Ash-Bell audio unless explicitly promoted into this packet with source and family contracts.

## Asset handoff summary

Known source targets must enter Asset Pipeline V2, never legacy direct runtime paths:

- Forlorn-Ritualant 8f rise: family `enemy_forlorn_ritualant`; body; south/current approved direction; **8f × 128×128 = 1024×128**; exact semantic filename is generated/validated from the new family state before staging.
- Walk/drag/turn/reactions: family `enemy_forlorn_ritualant`; body; **128×128 per frame**; direction/frame/FPS contract intentionally unresolved and blocks authoring.
- Unarrived procession: new/reused approved Ash-Bell apparition/procession family; **32×48 per authored cell**; frame/layout contract unresolved.
- Unarrived Saint: new/reused approved apparition family; proposed active-spec base **1f 64×96** only if human review confirms static treatment; directional variants require their own locked states.
- Ritual props: one approved V2 prop family; **1f each** at 96×96, 32×32, 32×32, 32×32, 32×64, and 16×16 respectively.

## Handoff

- Scene-closeout predecessor: `ash-bell-ritualant-runtime-truth-closeout` plus its paired review must land first; return that evidence to https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c before promoting this draft.
- Next action: Human/art-direction pass locks unresolved direction/frame contracts and supplies or approves production source; then change this packet to `ready/auto` and execute the corresponding Asset V2 families. Do not claim while source/cadence contracts remain unresolved.
- Best starting files: `required_assets.registry.json`; `enemy_forlorn_ritualant.asset.json`; detailed encounter spec; `build_forlorn_ritualant_spriteframes.py`; current encounter scene.
- Blockers or open questions: Exact walk/drag/turn/reaction direction/frame/FPS contracts; procession layout/frame count; apparition static-versus-directional production treatment; production source art itself.