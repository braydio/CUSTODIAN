# OPERATOR RUNTIME COMPATIBILITY RESIDUE — C2b.3

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-runtime-compatibility-residue`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-runtime-decomplexification`
- Locks: `operator-runtime, operator-assets`
- Kind: `implementation`
- Review: `manual`
- Reviewed main: `745a9ea56ec48347d379585b04f050c6415a016c`
- Goal: Close the remaining C2b compatibility-resource and animation-reachability residue after canonical selector demolition, so active Operator presentation has one truthful runtime authority and authored-but-unused animation output is explicitly removed, migrated, or intentionally preserved instead of silently accumulating.
- Completion boundary: This slice is complete when the eleven historical Operator compatibility SpriteFrames have a proved consumer disposition; every active gameplay/presentation consumer uses the generated canonical runtime database or an explicitly non-Operator effect authority; the reachability contract matches live runtime behavior; confirmed orphan/superseded canonical sheets are removed from active source/runtime publication when no preservation contract applies; intentionally dormant/provenance art remains explicitly classified; and the compatibility updater/tooling no longer regenerates deleted runtime resources.
- Current measured state:
  - The generated manifest contains 257 directional animation records spanning 99 semantic action families plus 2 weapon sections.
  - `operator_animation_reachability.json` currently contains 114 classifications: 60 LIVE, 37 DORMANT, 10 SUPERSEDED, 6 ALTERNATE_LAYER, and 1 DORMANT_PENDING_INTERACTION_SUCCESS_CONTRACT. The audit verifies classification coverage only; it does not prove that a LIVE/DORMANT claim still matches runtime consumers.
  - All eleven historical compatibility resources still exist under `game/actors/operator/`: `operator_runtime_frames.tres`, `operator_weapon_frames.tres`, `operator_melee_overlay_frames.tres`, `operator_ranged_fx_frames.tres`, `operator_modular_lower_body_frames.tres`, `operator_modular_upper_body_frames.tres`, `operator_modular_sidearm_frames.tres`, `operator_modular_upper_fx_frames.tres`, `operator_modular_cape_frames.tres`, `operator_modular_head_frames.tres`, and `operator_animation_catalog_frames.tres`.
  - `operator.tscn` already binds the generated canonical `content/sprites/operator/runtime/operator_runtime_frames.tres` to the main body, lower/upper body, modular sidearm/upper-FX, dodge FX and melee overlays. Four compatibility resources remain scene-bound: modular cape, modular head, `PrimaryWeaponSprite`, and `RangedFxOverlaySprite`.
  - Modular head/cape are explicitly retired from active composition. Their source/runtime art is preservation content, not a reason to keep compatibility scene nodes or private SpriteFrames alive.
  - `PrimaryWeaponSprite` and `RangedFxOverlaySprite` still carry legacy fallback/reload/fire logic in `operator.gd`; their removal therefore requires a real consumer cutover or proof that each branch is unreachable for shipped loadouts, not blind node deletion.
  - The current reachability ledger is materially stale. Examples marked DORMANT that are live on current main include `melee_1h/locomotion/walk_01` + the dagger weapon walk through `_sync_modular_melee_locomotion`; `melee_1h_heavy/attack/fast_01..03` through `MeleeAttackProfile.presentation_action` + `_resolve_armed_melee_identities`; `ranged_2h/cosmetic/aim_01` and `fire_01`; `sidearm/cosmetic/fire_sidearm_01`; `unarmed/cosmetic/critical_hitspark_01`; and `unarmed/interaction/field_patch_use_01`.
  - Four dodge-charge/Flow FX rows also look DORMANT in reachability but are not orphaned: `dodge_charge_meter_01`, `dodge_charge_ready_01`, `dodge_charge_release_01`, and `dodge_chain_release_01` are consumed directly by `game/vfx/combat/dodge_charge_feedback.tscn` as runtime PNG textures. That direct Operator-PNG consumption conflicts with the canonical runtime authority and must be migrated rather than deleted.
  - A current manifest/runtime comparison identifies 13 high-confidence action families containing 34 published layer identities that are either hard-orphaned or explicitly superseded. Hard-orphan candidates with no active game consumer found are:
    - `melee_1h/cosmetic/melee_1h` — malformed/untracked E/W full_body + fx family; the reachability audit currently skips `action == "melee_1h"`, so this residue bypasses the guard.
    - `melee_1h/attack/critical_execution_01` — E/W weapon layers; live execution uses `unarmed/cosmetic/critical_execution_01`.
    - `melee_1h/attack/fast_attack_chain_01` — E upper_body; shipped melee chains use `fast_01/02/03`.
    - `ranged_2h/attack/fast_01`, `fast_02`, `fast_03` — E/W weapon layers; ranged firing uses the ranged cosmetic/fire presentation, not this generic attack chain.
    - `sidearm/cosmetic/fx_01` — NE/SE FX; current sidearm fire uses `sidearm/cosmetic/fire_sidearm_01` FX.
  - Explicitly superseded published families are:
    - `melee_1h/cosmetic/relaxed_idle_01` -> `melee_1h/posture/idle_relaxed_01`;
    - `melee_1h/posture/stance_01` -> `melee_1h/posture/idle_ready_01`;
    - `melee_1h_dagger/cosmetic/relaxed_idle_01` -> `melee_1h_dagger/posture/idle_relaxed_01`;
    - `ranged_2h/posture/relaxed_carbine_mk1_01` -> `ranged_2h/posture/relaxed_01`;
    - misspelled `unarmed/cosmetic/criticial_execution_01` -> `unarmed/cosmetic/critical_execution_01`;
    - `unarmed/posture/stance_01` -> `unarmed/locomotion/idle_01`.
  - Do not equate every DORMANT row with deletion. Examples that currently have explicit preservation/future-contract reasons include retired head/cape layers, `ranged_2h/cosmetic/fire_walk_01` provenance, generic non-integrated melee recovery, heavy guard exit art, and `unarmed/interaction/success_01`.
- Evidence: live `operator.gd` and `operator.tscn`; generated `operator_runtime_manifest.generated.json`; `operator_animation_reachability.json`; `operator_animation_reachability_audit.gd`; `operator_runtime_animation_authority_smoke.py`; `game/vfx/combat/dodge_charge_feedback.tscn`; `design/02_features/operator/DODGE_CHARGE_FEEDBACK.md`; C2a/C2b evidence and summaries; exact repository searches for the candidate action families above.
- Task-specific authority: `design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md`; `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`; `custodian/content/data/operator/operator_animation_reachability.json`; canonical generated Operator runtime manifest/SpriteFrames; `design/02_features/operator/DODGE_CHARGE_FEEDBACK.md` for the dodge presentation contract.
- Work surface: `custodian/game/actors/operator/operator.tscn`; remaining compatibility presentation paths in `operator.gd`; `game/vfx/combat/dodge_charge_feedback.*`; the eleven compatibility `.tres` files and their updater/tool consumers; `operator_animation_reachability.json`; reachability/runtime-authority validation; Operator Workbench/debug tooling only where it still reads a deleted compatibility resource.
- Change:
  1. Build a deterministic consumer table for all eleven compatibility SpriteFrames before deleting anything. Separate active gameplay/runtime consumers, validation/debug/tool-only consumers, historical/report references, and zero-consumer resources.
  2. Remove the retired head/cape compatibility scene nodes and dead Operator code that only services them while preserving their canonical source/runtime art and DORMANT reachability classification. Retirement means “not drawn”, not “delete the authored asset”.
  3. Finish the `PrimaryWeaponSprite` / `RangedFxOverlaySprite` disposition. Prefer the existing canonical modular/static weapon presentation. Remove compatibility nodes/resources only after every shipped loadout path that currently depends on them is either migrated or proven unreachable. Do not delete weapon-definition data merely to make this packet green; immutable-definition/runtime-state cleanup belongs to the later loadout extraction packet.
  4. Remove compatibility resources with no remaining gameplay consumer and update/delete `update_operator_compatibility_resources.py` responsibilities so deleted resources are not regenerated. Tooling that still needs catalog inspection must read the canonical generated runtime manifest/SpriteFrames rather than keeping a second runtime database alive.
  5. Migrate `DodgeChargeFeedback` away from direct `content/sprites/operator/runtime/animations/...png` references. Preserve its current ratio-selected meter, ready latch, release/chain-release one-shots, timing, placement and gameplay non-authority. Consume the canonical generated runtime frames/semantic identities, or move genuinely effect-owned art to the effects authority if the active design explicitly says it is not Operator animation. Do not leave an undocumented exception to the one-runtime-database rule.
  6. Reconcile every reachability classification touched by current runtime. At minimum correct the stale live rows listed above and classify the four dodge-feedback identities by their actual consumer after migration.
  7. Fix the reachability audit hole that unconditionally skips `action == "melee_1h"`. Legacy exclusion must be based on actual legacy identity semantics, not one canonical-looking action string. The malformed `melee_1h/cosmetic/melee_1h` family must become visible to the contract until it is dispositioned.
  8. For the 13 high-confidence orphan/superseded families above, prove zero active runtime consumer after C2b.2, then remove active source/runtime publication for those with no preservation contract. Preserve provenance in the existing pipeline archive/report history rather than keeping dead canonical runtime output. If a candidate is found live, correct the audit classification and keep it; do not delete to satisfy the packet.
  9. Produce a machine-readable orphan/reachability report under `reports/operator/` containing action identity, layer, direction, source/runtime path, classification before/after, discovered consumers, and disposition (`LIVE`, `PRESERVE_DORMANT`, `REMOVE_SUPERSEDED`, `REMOVE_ORPHAN`). Make the report generator or validation cheap enough to rerun after future Operator asset publication.
  10. Update active docs only where owned truth changes: runtime animation authority, Operator runtime architecture, CURRENT_STATE/FILE_INDEX, and the reachability description. Historical C2a/C2b reports remain historical.
- Preserve: authored timing/pixels of all retained live animations; current melee, ranged, sidearm, field-patch, critical, dodge/Flow and damage-reaction presentation; dormant head/cape source/runtime art; gameplay timing and combat authority; weapon IDs/profile semantics; canonical source-to-runtime pipeline; Workbench authoring/publish behavior.
- Non-goals: No new animation art. No restyling, reslicing or retiming. No action-arbitration extraction (Slice E). No melee/dodge/ranged/loadout/interactions/recovery controller extraction (Slice F). No mutable weapon-runtime-state split. No broad operator.gd dependency-injection pass. No deletion of DORMANT art merely because it is not currently drawn. No rewriting historical reports to make old classifications appear current.
- Acceptance:
  - A checked-in consumer/disposition report accounts for every current canonical action/layer and all eleven compatibility SpriteFrames without an unclassified active-runtime gap.
  - Reachability data agrees with live main for the known stale rows; no current live path is labeled DORMANT solely because an old compatibility-era consumer description was never refreshed.
  - The malformed `melee_1h/cosmetic/melee_1h` family can no longer bypass reachability validation.
  - The 13 listed orphan/superseded families are either removed from active canonical publication after zero-consumer proof or retained with concrete contrary consumer evidence recorded in the report.
  - Dodge charge/Flow feedback remains visually and behaviorally intact without direct active-gameplay Operator PNG access.
  - Retired head/cape do not require compatibility scene nodes/resources to remain, while their preserved canonical art remains available.
  - Deleted compatibility `.tres` resources are not regenerated by the updater, Workbench, or validation.
  - `operator_runtime_animation_authority_smoke.py --final` has fewer compatibility-resource completion gates after this slice and no new direct-PNG/runtime-database violations.
  - Focused Operator melee/ranged/sidearm/dodge/field-patch/critical presentation smokes remain green.
- Validation: First run the reachability audit/report and runtime-animation-authority smoke, then focused smokes for any migrated consumer (dodge charge, modular layers, sidearm, primary ranged, melee posture/chain, field patch, critical execution). Run compatibility-resource/update-tool tests after each deletion cluster. Finish with one `run_validation.py --changed --json` closeout sweep. Use Moment Forge only for a final dodge/ranged visual regression if an existing scenario directly exercises a migrated presentation path.
- Task overrides: `none`
- Deferred: Slice E is now queued as `operator-action-arbitration` in `OPERATOR_ACTION_ARBITRATION.md`, followed by six one-domain Slice F packets (melee, dodge, ranged, loadout/runtime-state, interactions/build/repair, recovery), then Slice G shell collapse/final zero-debt audit.

## Execution Feedback

- Validation outcome: complete. The final changed-unit gate selected 25 checks; all 25 passed with complete changed-file coverage.
- Runtime publication: 596 canonical outputs before retirement; 562 after. The 34 retired sheets from 13 action families remain under `custodian/content/sprites/operator/source/legacy/c2b_runtime_retirement/` as provenance, with no active runtime publication.
- Consumer report: 538 active canonical layer identities and 34 archived retired identities; 11 compatibility SpriteFrames are explicitly dispositioned.
- Acceptance: all eleven actor-local compatibility SpriteFrames and the updater are removed; Operator consumers and DodgeChargeFeedback use the generated runtime database; reachability has 117 classifications and the runtime audit checks 237 actions. No active action/layer report row is unclassified.

- Verification: compatibility-resource, runtime-authority, timing, Workbench mirror/UI/art-worktree, runtime-path, reachability, melee point-blank, and modular-layer checks passed. `operator_runtime_animation_authority_smoke.py` retains its separate 188-file legacy-runtime TODO gate; `--final` therefore remains intentionally red for that independent migration debt.
- Corrections during validation: a deleted sheet-map identifier still remained in paired-execution selection, and shared presentation declarations had been removed along with retired compatibility code. Both were corrected; canonical body/FX selection now checks the generated SpriteFrames. Validation ownership was narrowed to the retired families and their affected fixture/smoke files.
- Production art changed: none. Retained authored timing and pixels were not edited.
- Process Feedback
  - Feedback schema: `custodian.task_feedback.v1`
  - Outcome: success
  - Friction severity: medium
  - What went wrong: compile-time stale sheet-map reference and removed shared declarations were exposed only by the Godot smoke; initial validation coverage did not own every retired art/fixture path.
  - Root cause / contributing factors: compatibility code and canonical consumer changes shared a large actor script, while task-specific validation ownership lagged the actual deletion surface.
  - Prevention / pipeline improvement: retain canonical runtime identity checks for paired executions and assign exact retired-family ownership to the compatibility smoke; keep shared presentation declarations outside compatibility-resource deletion scope.
  - Tooling / docs drift discovered: validation ownership omitted the retired runtime sheet folders, removed scene properties, and new DodgeChargeFeedback conversion fixtures; ownership is now explicit.
  - Follow-up: fixed-in-scope
  - What worked: generated consumer report and focused canonical SpriteFrames checks made the dispositions deterministic.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: final changed-unit validation selected 25 tests and passed all 25; focused Operator runtime, compatibility, reachability, modular-layer, and consumer-report checks passed. The separate 188-file legacy-runtime TODO gate and 25 legacy identity TODOs remain explicitly deferred.

## Handoff

- Next action: proceed to `operator-action-arbitration` after this packet lands; Slice F domain extraction and Slice G shell collapse remain queued behind it.
- Evidence: `reports/operator/operator_runtime_consumer_disposition.json`; `custodian/tools/operator/operator_runtime_consumer_report.py --check`; focused Operator smokes and the changed-unit validation receipt.
- Remaining independent migration debt: 188 legacy runtime files and 25 legacy Operator identities remain tracked by their existing authority audits.
