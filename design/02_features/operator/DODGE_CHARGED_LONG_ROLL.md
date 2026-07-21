# Dodge Charged Long Roll

**Project:** CUSTODIAN
**Status:** implemented-v1
**Created:** 2026-07-20
**Last Updated:** 2026-07-20

## Purpose

Add deliberate long-distance evasion without making the normal defensive dodge analog or weakening its timing contract.

> Tap and release performs the fixed standard dodge. Holding and releasing selects a more expensive, more punishable positioning roll. Distance and recovery scale; invulnerability does not.

## Runtime Contract

| Profile | Hold | Speed / distance multiplier | Active | Iframes | Recovery | Stamina |
|---|---:|---:|---:|---:|---:|---:|
| Tap | `< 0.12s` | `1.00` | `0.20s` | `0.16s` | `0.16s` | `16` |
| Long | `0.12–0.30s` | `1.30` | `0.20s` | `0.16s` | `0.20s` | `20` |
| Committed | `>= 0.30s` | `1.55` | `0.20s` | `0.16s` | `0.256s` | `26` |

All values are exported tuning defaults. The active duration remains fixed in V1; the speed multiplier creates proportional displacement while preserving the existing roll clock and animation. Iframes remain clamped to active duration and never extend through recovery.

## Input and Commitment

1. Dodge press begins a short detection phase and captures the movement-first dodge direction.
2. Release selects `tap`, `long`, or `committed` from bounded hold time.
3. Once hold time reaches `dodge_tap_release_window`, movement decelerates to a locked coil stance.
4. Charge has no invulnerability. An incoming hit records `windup_hit`, cancels charge, and resolves normally.
5. UI, portal, death, and impact locks cancel pending charge.

The compatibility method `_try_start_dodge()` remains an immediate standard dodge for existing runtime callers and tests. Setting `dodge_charge_enabled = false` restores press-to-dodge input behavior.

## Attack Interaction

Tap dodge preserves the existing explicit roll-exit fast-attack cancel. Long and committed rolls cannot cancel their increased recovery. Attack input during those profiles may be buffered and begins only after recovery completes.

## Presentation

The ordinary directional dodge body and rear FX animation remain unchanged. `DODGE_CHARGE_FEEDBACK.md` owns the additive charge presentation: delayed ratio-controlled ground ring, restrained body compression, full-charge latch, origin burst, scaled trail, one maximum-charge afterimage, tiny camera impulse, temporary stamina-label copy, and stamina-rejection feedback. Presentation never grants or implies charge invulnerability.

## Observability

Runtime emits:

- `player_dodge_charge_started`
- `player_dodge_charge_released`
- `player_dodge_charge_cancelled`
- `player_dodges_started_tap`
- `player_dodges_started_long`
- `player_dodges_started_committed`
- `incoming_dodge_classification_windup_hit`

## Validation

`custodian/tools/validation/operator_charged_long_roll_smoke.gd` proves tier boundaries, profile speed/recovery/stamina values, fixed iframe duration, charged-roll attack commitment, charge vulnerability, and hold/release input execution.

The existing dodge overlap and modular fast-attack smokes remain regressions for iframe/recovery classification and tap roll-exit behavior.

## Deferred

- Authored mechanical click/hum/latch/discharge audio beyond the preserved roll sound and charged-release pitch/weight treatment.
- Manual gameplay-zoom tuning of VFX placement, alpha, controller pulse, and maximum-charge camera impulse.
- A narrow authored late-recovery cancel window for charged profiles.
- Balance changes to active duration or iframe duration.
