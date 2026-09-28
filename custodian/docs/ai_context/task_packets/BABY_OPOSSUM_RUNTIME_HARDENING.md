# BABY OPOSSUM RUNTIME HARDENING

- Workstream: `baby-opossum-runtime-hardening`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P2`
- Depends on: `none`
- Locks: `baby-opossum-runtime`
- Goal: Correct the Baby Opossum runtime state-transition and approach/retrieval semantics, tighten determinism and contract validation, and reconcile the active implementation documentation without changing the existing Asset V2 art pipeline.
- Current measured state: On reviewed `main@49649b35`, the actor has a deterministic explicit state machine, generic passive attack rejection, layered presentation, 22 published body strips, and focused runtime/asset smokes. Review found that several public soft-action APIs can overwrite non-ambient sequences despite the design claiming reactions are gated; timed `APPROACH` states can advance remotely before reaching their target; `retrieve()` marks a target carried before contact; equal-distance discoverable selection has no explicit stable tie-break; runtime FPS metadata mirrors the family contract but parity is only proven for published clips; and the design still refers to generated `REQUIRED_ASSETS.md` as the tracker. Five production-art requirements remain intentionally open in the requirement registry.
- Task-specific authority: `design/02_features/ambient/BABY_OPOSSUM_RUNTIME.md`, `custodian/game/actors/ambient/baby_opossum/baby_opossum.gd`, `baby_opossum_animation_set.gd`, shared ambient presentation/rejection authorities, `ambient_baby_opossum.asset.json`, and the focused Baby Opossum validation smokes.
- Change: Add one explicit transition-priority policy; make soft actions non-destructive while a sequence is active; make approach progression depend on arrival rather than a short fixed timer; make retrieval contact-authoritative; make equal-distance search selection deterministic; extend contract parity validation to missing/unpublished states; update active docs and archive the completed legacy production-wiring record.
- Preserve: Existing state-machine ownership, manager-owned deterministic seeding, generic `AttackRejection`, shared ambient presentation, Asset Pipeline V2 publication/naming, current published art, and fail-soft fallback for missing clips.
- Non-goals: No new behavior controller, planner, navigation system, friendship overhaul, save-system work, new art generation, source re-slicing, asset-family redesign, Operator tooling, or broad ambient-creature refactor.
- Acceptance: Active soft sequences cannot be accidentally overwritten; hard attack/flee reactions have explicit tested priority; treat/retrieve approach does not resolve remotely; carrying begins only on matching contact; search tie selection is stable; family/runtime animation timing parity is validated for the whole contract; docs point to the requirement registry rather than generated Markdown; existing smokes remain green and new focused cases prove the fixes.
- Task overrides: `none`
- Deferred: The five existing Baby Opossum Asset V2 production-art requirements; broader friendship/command gameplay; navigation-aware long-range retrieval.
  
## Ownership And Timing

- Owner: Baby Opossum runtime behavior/presentation contract
- Agent/session: Codex auto-dispatch
- Created: 2026-09-28
- Last updated: 2026-09-28

## Findings To Correct

### 1. Transition policy is implicit and internally inconsistent

The design says only ambient states accept a new reaction, but live APIs do not follow one rule.

Currently:

- detector-driven treat/threat entry checks `_is_interruptible()`;
- direct `receive_treat()` does not;
- `begin_play_dead()`, `enter_hide()`, `search_for_target()`, and `retrieve()` can overwrite an active treat/rejection/flee/scavenge sequence;
- `reject_attack()` and `flee_from()` always preempt.

Do not scatter ad-hoc state checks. Introduce one small transition-policy helper in the existing actor authority.

Required policy:

- **soft actions**: treat, play-dead entry, hide entry, search, retrieve may begin only from ambient `IDLE/WANDER`; otherwise fail/no-op without changing current state;
- sensed/nearby threat remains ambient-only, matching current detector behavior;
- **hard safety reactions**: actual attack rejection and explicit `flee_from()` may preempt soft/ambient sequences;
- repeated hard reactions must not create an infinite restart loop or prevent eventual flee termination;
- peek/exit APIs continue to operate only inside their own held sequence.

Keep public API compatibility where practical. Existing callers that ignore a return value must keep working.

### 2. Approach states can complete before reaching the target

`TREAT_APPROACH` currently has a fixed 1.2 second duration. At default 30 px/s it can cover only about 36 px, while the treat detector radius is 72 px. The actor can therefore transition into sniff/take/eat while visibly remote from the treat.

`RETRIEVE` has the same structural problem and is even more exposed because search radius is much larger.

Implement arrival-aware `Movement.APPROACH` handling:

- reaching `ARRIVAL_DISTANCE_SQUARED` may complete the approach step early;
- the state must not advance to its success successor merely because a too-short fixed timer expired while still remote;
- keep a bounded safety timeout so an unreachable target cannot stall forever;
- derive or size that timeout from current distance/move speed plus a small grace rather than using a value that is known to be shorter than legal approach distance;
- a failed/expired treat approach returns safely to ambient behavior instead of sniffing/taking remotely.

Do not add a navigation subsystem in this task.

### 3. Retrieval claims possession before contact

Live `retrieve(target)` immediately assigns `carrying_target = target`, then begins approaching it. The contact detector also assigns `carrying_target`, so the current state claims possession before pickup.

Correct this contract:

- keep a separate pending retrieve target;
- `retrieve()` rejects null/invalid/non-Node2D targets cleanly;
- starting retrieval does not set `carrying_target`;
- contact only succeeds for the requested pending target, not an arbitrary discoverable entering the detector;
- only successful matching contact sets `carrying_target`;
- timeout/cancel clears pending retrieval without fabricating possession;
- `gift_drop()` must not emit a fake drop for no carried target.

No current external signal consumers were found, so signal timing may be corrected where necessary, but preserve signal names.

### 4. Search tie-breaking is not explicitly deterministic

`search_for_target()` uses `<=` while iterating the scene-tree group, so exact equal-distance candidates depend on group iteration order.

Use a deterministic comparator. Preferred ordering:

1. squared distance;
2. world Y;
3. world X;
4. stable node name/path only as a final tie-break.

Do not introduce randomness for target choice.

If `target_found` currently fires before the visual search/find sequence semantically earns that event, retain the selected target and emit at the appropriate find beat rather than at initial scan. Keep this change local and covered by the smoke.

### 5. Animation timing has a latent duplicate-authority drift risk

`baby_opossum_animation_set.gd` mirrors family FPS values in `ACTION_FPS`. Published clips are checked against the family contract, but a missing/unpublished state can drift silently until art later arrives.

Do not add a fragile runtime JSON dependency solely for this cleanup.

Instead, extend focused validation so **every family state** compares its effective animation-set FPS against the family contract, using `ACTION_FPS` or the animation set's default fallback as runtime would. Also validate the duplicated alias map against the family contract.

The goal is fail-fast parity, not architecture churn.

## Outstanding Production Art

Do not create, resize, re-slice, or ingest new art in this runtime-hardening slice.

Keep these existing requirement-registry items active and truthful:

- `baby-opossum-south-locomotion-re-export`
  - `waddle/s`, `scurry/s`
  - 96x96 cells, six poses each; uniform re-export required.
- `baby-opossum-ambient-threat-re-export`
  - `look/s`, `hiss/s`, `startle/s`
  - 96x96 cells; four poses each per current source notes.
- `baby-opossum-reaction-friendship-re-export`
  - `disapprove/s`, `eat/s`, `friend_happy/s`
  - 96x96 cells; six poses each per current source notes.
- `baby-opossum-hide-exit-re-export-body-barrel`
  - body + `barrel_prop` `hide_exit/s`
  - 96x96 cells; source notes identify five poses requiring a clean uniform re-export.
- `baby-opossum-barrel-prop-hide-layer-consistent-framing`
  - south `hide_enter/hold/peek/exit` barrel layer
  - 96x96 runtime cells; all four actions must share one consistent camera/canvas registration.

Asset source authority remains the existing family plus requirement registry. No new asset family or alternate tracker.

## Documentation And Packet Hygiene

Update `design/02_features/ambient/BABY_OPOSSUM_RUNTIME.md` to describe:

- the actual soft-vs-hard transition policy;
- arrival-aware approach/retrieval semantics;
- contact-authoritative carrying;
- deterministic search tie-breaking;
- open art tracked in `custodian/content/metadata/assets/required_assets.registry.json`, with root `REQUIRED_ASSETS.md` only the generated human view.

Update `CURRENT_STATE.md` / `FILE_INDEX.md` only if their current Baby Opossum statements become false or materially incomplete after implementation.

`custodian/docs/ai_context/task_packets/BABY_OPOSSUM_PRODUCTION_WIRING.md` is a completed 2026-09-06 implementation record but still sits in the active packet directory and is not indexed as active work. Move it to `task_packets/archived/` if no current tooling/reference requires the active path. Do not rewrite its historical contents merely to modernize terminology.

## Focused Validation

Extend `custodian/tools/validation/baby_opossum_runtime_smoke.gd` to cover at least:

1. direct soft action cannot interrupt an active treat sequence;
2. direct soft action cannot overwrite hide/play-dead/rejection sequences;
3. sensed threat remains ignored while a non-interruptible sequence is active;
4. hard attack rejection can preempt a soft sequence and still terminates through flee;
5. repeated hard reactions do not permanently restart/lock flee;
6. treat started near the detector edge reaches the target before sniff/take progression;
7. approach timeout cannot produce remote treat success;
8. `retrieve(target)` does not set `carrying_target` before contact;
9. wrong discoverable contact cannot satisfy retrieval;
10. matching contact does;
11. retrieval timeout clears pending state without carrying;
12. empty `gift_drop()` emits no false drop;
13. equal-distance search candidates resolve deterministically.

Extend the focused asset/runtime contract test to verify:

- effective FPS parity for every family state, including unpublished states;
- alias-map parity with the family contract;
- existing 96px geometry/alpha/body-prop pairing checks remain intact.

Use temporary/test nodes. Do not require new production art.

## Validation Commands

Run focused first:

```bash
cd custodian
godot --headless --path . --script res://tools/validation/baby_opossum_runtime_smoke.gd
python3 tools/validation/baby_opossum_asset_contract_smoke.py
python3 tools/assets/asset.py needs baby-opossum-south-locomotion-re-export
python3 tools/assets/asset.py needs baby-opossum-barrel-prop-hide-layer-consistent-framing
git diff --check
```

Then close out with the repository's changed-file validation according to current AGENTS/workstream rules. Do not require `OPOSSUM_REQUIRE_ART=1` to pass missing deferred art; the existing production baseline must remain green without manufacturing art.

Moment Forge is not required unless implementation changes visible timing enough that deterministic visual evidence materially improves review.

## Completion

Before normal workstream finish:

- keep all five art requirements intact unless real art was independently supplied during the workstream;
- update only active Baby Opossum truth made stale;
- archive the old production-wiring record if safe;
- mark/archive this packet through the normal lifecycle;
- write the required closing summary with findings fixed, files changed, focused validation, changed validation, and any deliberately deferred art/gameplay item.

## Handoff

- Next action: `python3 custodian/tools/agent/dispatch.py claim baby-opossum-runtime-hardening --agent codex`
- Best starting files: `baby_opossum.gd`, `baby_opossum_runtime_smoke.gd`, `baby_opossum_animation_set.gd`, `ambient_baby_opossum.asset.json`, `BABY_OPOSSUM_RUNTIME.md`.
- Blockers or open questions: None. Do not wait on the five existing art re-exports to harden runtime semantics.
