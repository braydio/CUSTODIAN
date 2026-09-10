# Task Packet — Operator Runtime Decomposition

**Status:** Slices A and B complete (2026-09-10)
**Contract:** `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`
**Gate:** `custodian/tools/validation/operator_architecture_debt_audit.py`

## Goal

Turn `operator.gd` from a 540 KB multi-authority god object into a thin
deterministic actor facade built from explicit domain controllers and a single
presentation authority.

**This is a staged strangler migration, not a rewrite.** Each slice must be
independently reviewable and leave the runtime green.

## Read first

- `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`
- `design/04_architecture/INTEGRATION_CONTRACT_GLUE_LAYER.md`
- `design/02_features/animation/OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md`
- `design/02_features/combat_feel/OPERATOR_MELEE_CONTACT_TIMING_AND_CADENCE.md`
- `design/02_features/combat_feel/OPERATOR_MELEE_ATTACK_DRIVE.md`
- `custodian/game/actors/operator/AGENTS.md`
- `custodian/docs/ai_context/ARCHITECTURE_OWNERSHIP_MAP.md`

The core locks are listed in the contract and are not restated here. Do not
weaken one to make a slice easier; raise it instead.

## Working rule for every slice

Run the debt audit before and after. It ratchets:

```bash
python3 custodian/tools/validation/operator_architecture_debt_audit.py
python3 custodian/tools/validation/operator_architecture_debt_audit.py --final   # end state
```

- a NEW or INCREASED violation fails ordinary validation — debt cannot grow;
- a DECREASED violation makes the baseline stale, which is TODO normally and a
  failure under `--final`, so the ledger must shrink as work lands;
- refresh the ledger with:

```bash
python3 custodian/tools/validation/operator_architecture_debt_audit.py --emit-baseline \
  > /tmp/base.json && mv /tmp/base.json custodian/tools/validation/operator_architecture_debt_baseline.json
```

Do not redirect straight onto the baseline file: the audit reads it at import
time and the shell truncates it first.

## Slice A — contract + audit + characterization — DONE

Delivered:

- `design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`
- this packet
- `custodian/tools/validation/operator_architecture_debt_audit.py` with 13
  ownership rules, `--final`, `--json` and `--emit-baseline`
- `custodian/tools/validation/operator_architecture_debt_baseline.json`
  frozen at **347 violations across 12 rules**
- registered as `operator_architecture_debt` in the validation manifest
- documentation drift corrected (see below)

Characterization measured at freeze time is tabulated in the contract.

## Slice B — presentation firewall

**Landed (commit `cb157148b`):** the one-body invariant itself.
`_set_body_presentation_owner()` in `operator.gd` is now the single authority —
it hides and stops every body-capable renderer, then enables only the requested
owner. The Vigil posture bridge and ready→fast_1 startup acquire it atomically
and surrender it on release. `operator_visual_ownership_smoke.gd` asserts
visible **body owners** one frame before and after every handoff, with negative
controls proving it catches the pre-fix duplicate-body behaviour.

**Extracted (Slice B):** the authority now lives in
`presentation/operator_body_presenter.gd` (`RefCounted`) with
`presentation/operator_body_presentation_plan.gd` as the typed request shape.
`operator.gd` holds a presenter instance, registers the static renderers in
`_ready()` and the lazily built Vigil rigs as they are created, and keeps thin
delegating wrappers with no visibility policy. `body_visibility_outside_presentation`
is **0**; no other debt category moved.

One deliberate deviation from the brief: `show_layer()` **adopts** the layer's
owner rather than refusing to preempt an exclusive rig. Refusing broke
`operator_melee_posture`, where a draw/equip presentation legitimately
interrupts a posture bridge. Adoption still retires the previous owner in the
same call, so no frame shows two bodies, and the exclusive guarantee stays
where the regression tests point it: `_update_animation()` and the legacy
fallback both check `_is_exclusive_body_owner_active()` first. Strict
same-owner validation moved into `present(plan)`, which rejects a plan whose
body layers span owners.

Do not convert `operator_presentation_rig_2d.gd` into this controller.

## Slice C — canonical animation authority

Route every presentation request through `OperatorAnimationSelector` and the one
generated `operator_runtime_frames.tres`. Retire `AnimationResolver` (45),
`DirectionalAnimationFallback` (6), `OperatorAnimationCatalog` (4),
`fallback_animation` (16) and actor-local `SpriteFrames.new()` (5) **only as
their consumers reach zero**. The selector's exact-identity → temporary SOUTH →
error contract is already correct; the existing final audits define the finish
line.

## Slice D — input + fixed-step spine

Introduce `OperatorInputFrame`, `OperatorInputRouter` and
`OperatorAimController`. Move the 12 simulation advances out of `_process()`
onto the explicitly ordered fixed tick; leave `_process()` presentation-only.
Make gamepad/mouse ownership deterministic: a neutral stick retains the last
gamepad aim and only real mouse movement hands the device back. Make
`ControllableActor.process_input()` a real adapter instead of the current
no-op `pass`, so replay/AI/vehicle drivers have a seam.

## Slice E — action arbitration

Introduce `OperatorActionController`. Delete the empty `idle_state.gd`,
`walk_state.gd` and `sprint_state.gd` shells — locomotion is a separate axis and
must not compete with attack state. Action arbitration owns interruption and
priority only; melee, guard, dodge, ranged, equip/sheathe, damage and death own
their own behaviour. Eliminate the 34 `actor.has_method()`/`call()` glue sites.
The action controller must not hold a sprite reference at all.

## Slice F — extract domains

One domain at a time: melee timeline/drive, dodge, ranged/ammo/heat/reload,
loadout, interactions/build/repair, recovery. Keep `operator.gd` facade methods
so existing callers and tests keep working. Split
`OperatorWeaponDefinition` into immutable definition data plus
`OperatorWeaponRuntimeState` (the 3 mutable `@export` fields are old-architecture
residue with no meaningful current consumers).

## Slice G — collapse the shell

Reorganise `operator.tscn` into `Controllers`, `Presentation`, `Sockets`,
`Hitboxes` and `Feedback` groups. Remove compatibility nodes and resources.
Move Knight Test Skin and debug frame construction out of production Operator
code. Update `FILE_INDEX.md`, `CURRENT_STATE.md` and
`ARCHITECTURE_OWNERSHIP_MAP.md`. Turn the debt audit into a hard `--final` gate
in the default validation set.

## Non-goals

- No ECS rewrite, no constellation of tiny manager classes.
- No arbitrary LOC limits during extraction.
- No new art assets.
- No behavioural change to combat, locomotion, dodge, ranged or interaction.
- No conversion of `operator_presentation_rig_2d.gd`.

## Documentation drift corrected in Slice A

| Drift | Correction |
|---|---|
| `OPERATOR_MELEE_PRESENTATION_POSTURE.md` said attacks from RELAXED bypass `ready_up` | Live `MeleePostureState.attack_action_bypasses_ready_up()` returns **false**; the doc was stale, not the code. Doc now states the bridge chain. |
| `OPERATOR_MELEE_FAST_CHAIN.md` referenced by 3 live docs but absent | References redirected to the live cadence/posture authorities |
| `operator_modular_core.json` referenced by 4 live docs | Live contract is `custodian/tools/validation/contracts/operator_animation_core.json` |
| `WEAPON_OWNED_ANIMATION_SYSTEM.md` carried the old `AnimationResolver` target architecture | Marked superseded by `OPERATOR_RUNTIME_ANIMATION_AUTHORITY.md` |

The locked relaxed-attack flow is:

```text
relaxed
→ relaxed_to_ready
→ READY ANCHOR
→ ready_to_fast_1
→ fast_1
```

with no `idle_ready` playback between the bridges.

## Validation

```bash
python3 custodian/tools/validation/operator_architecture_debt_audit.py
python3 custodian/tools/validation/operator_runtime_path_audit.py
python3 custodian/tools/validation/run_validation.py --test operator_visual_ownership
python3 custodian/tools/validation/run_validation.py --changed --json
```
