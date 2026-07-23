# Dodge Flow

**Project:** CUSTODIAN  
**Status:** implemented-v1  
**Created:** 2026-07-21  
**Last Updated:** 2026-07-23

## Purpose

Connect charge, dodge links, directional redirects, recovery, and locomotion exit through an authored deterministic movement state rather than uncontrolled `CharacterBody2D.velocity` carry-over.

> Charge creates Flow. Chaining preserves Flow. Turning spends Flow. Stopping releases Flow into a bounded locomotion carry.

The target sequence is:

```text
run → charge → committed dodge → same-direction link → 90° redirect → sprint exit
```

## State Contract

Operator authority remains explicit:

```gdscript
var _dodge_flow: float = 0.0
var _dodge_flow_direction: Vector2 = Vector2.ZERO
var _dodge_chain_index: int = 0
var _dodge_chain_buffered: bool = false
var _dodge_exit_velocity: Vector2 = Vector2.ZERO
var _dodge_exit_timer: float = 0.0
```

Flow is never inferred from live physics velocity and never grants simulation authority to VFX, animation, or HUD code.

## Chain Timing

| Time from link start | Behavior |
|---:|---|
| `0.00–0.10s` | committed movement; dodge presses do not buffer |
| `0.10–0.20s` | a dodge press buffers the next direction |
| active completion | buffered link launches immediately |
| first `0.06s` recovery | late press cancels recovery and launches immediately |
| after grace | final recovery and cooldown continue |

Each successful link owns a fresh `0.20s` active clock and a fresh iframe clock capped at the unchanged `0.16s`. This preserves at least the authored `0.04s` vulnerability seam between normally timed links. Holding dodge during a live chain is treated as one buffered tap and cannot begin another charge.

The ordinary cooldown is held at zero while a sequence is active. It begins when the final active link enters recovery; a late-grace continuation clears that provisional cooldown again.

## Flow Sources

| Opener | Initial Flow |
|---|---:|
| Tap | `0.35` |
| Long | `0.65` |
| Committed | `1.00` |

An input-driven charged opener uses `lerp(0.35, 1.0, charge_ratio)`, which remains consistent with those profile anchors. Charged profile speed/distance bonuses are not multiplied by Flow on the opener; Flow modifiers begin on subsequent chain links.

## Directional Retention

| Absolute turn | Retention | Animation entry |
|---:|---:|---:|
| `0–45°` | `1.00` | frame `2` |
| `>45–90°` | `0.75` | frame `1` |
| `>90–135°` | `0.40` | frame `0` shortened plant |
| `>135–180°` | `0.00` | frame `0` full pivot |

The retained Flow becomes the next link's magnitude and the requested direction becomes its new explicit Flow direction. Reverse links remain legal but clear their movement energy.

## Link Modifiers

At maximum retained Flow:

- peak chain speed is `+12%`;
- integrated chain travel is `+18%`;
- final chain recovery is `-35%`;
- iframe duration remains unchanged.

The active duration stays fixed at `0.20s`. To achieve both peak-speed and travel targets without lengthening that clock, runtime adjusts the endpoint of the existing linear deceleration curve. The charged opener is never fed through this chain curve.

Every link costs the ordinary `16` stamina. V1 has no hard link cap and no fatigue escalation; stamina, vulnerability seams, directional loss, obstacles, and timing are the constraints.

## Animation Contract

Charged windup uses the dedicated non-looping five-frame
`operator_dodge_charge_windup_*` body sheet. Runtime selects its frame directly from charge ratio, so short holds show
early compression and maximum charge holds frame four without granting animation timing any gameplay authority.

The existing non-looping nine-frame, 25 FPS full dodge atlas remains authoritative for the released opener, turns
over 90 degrees, and final settle. Clean turns through 90 degrees use the dedicated four-frame
`operator_dodge_chain_link_*` body sheet at 20 FPS, exactly one cycle over the unchanged 0.20-second link clock. Every
successful link restarts at frame zero; it does not loop after gameplay stops launching links. Hard pivots retain the
full-atlas plant frame, and the final settle continues through the existing dodge exit frames.

Direction fallback is presentation-only. Body and FX independently select their nearest authored sector through the
shared directional fallback helper; neither may modify `_dodge_direction`, `_dodge_flow_direction`, movement timing,
or iframe timing.

## Exit Carry and Decay

After final recovery, retained Flow creates a bounded carry state:

```gdscript
exit_speed = SPEED * lerp(1.0, 1.45, flow)
exit_duration = 0.18
```

The normal locomotion target blends with this authored vector. Matching run/sprint input inherits the direction without a neutral stop; no input produces a short braking step. Flow waits `0.22s` after carry, then decays at `1.8/s`. Matching sprint movement slows decay to preserve part of the sequence without creating raw physics momentum.

## Presentation

The charge ring remains opener-only. `DodgeChargeFeedback` consumes `dodge_chain_started` for a thin cyan continuation streak scaled by retained Flow. Chain audio reuses the roll transient with a small pitch increase capped at `1.08`; pitch never climbs indefinitely. Bespoke pivot fragments and dedicated pivot-link art remain optional polish.

## Signals and Read-only Status

```gdscript
signal dodge_chain_started(index: int, flow: float, direction: Vector2)
signal dodge_chain_ended(count: int, flow: float, reason: StringName)
signal dodge_flow_changed(value: float, direction: Vector2)
```

`get_dodge_flow_status()` exposes Flow/direction, buffer state, chain index, last turn angle/retention, exit carry,
requested/resolved presentation sectors, selected animation, and fallback status without allowing consumers to mutate
movement authority.

## Observability

Runtime records buffered inputs, successful links, stamina rejection, final count/reason, turn angle, retention, animation entry frame, Flow, speed, recovery, iframe duration, and exit velocity. Observatory gauges expose current Flow and chain index.

## Validation

`custodian/tools/validation/operator_dodge_flow_smoke.gd` proves:

- opener Flow values and charged ratio integration;
- active input-window buffering and hold-as-tap behavior;
- exact directional retention bands;
- same-direction then 90-degree chaining;
- uncapped reverse pivot with Flow break;
- fixed active/iframe clocks, peak speed, integrated travel, and recovery targets;
- dedicated four-frame clean/90-degree link playback and full-atlas hard-pivot entry;
- late-grace recovery cancellation;
- final-link cooldown ownership;
- exit carry, delayed decay, stamina cost, and insufficient-stamina termination.

The charged-roll, charge-feedback, overlap-telemetry, and modular fast-attack smokes remain required regressions.

## Deferred

- Chain fatigue after the third link, only if playtesting finds uncapped stamina-limited chains too safe.
- Dedicated two- or three-frame hard-turn/pivot art and authored skid fragments.
- Dedicated clean-link latch and momentum-break audio.
- Flow conversion into attacks; V1 ends or cancels Flow at the existing attack boundary.

## Next Agent Slice

**Goal:** Manually tune the charged opener → clean link → 90° redirect → sprint-exit sequence at gameplay zoom.

**Constraints:** Do not change the `0.16s` iframe ceiling, do not multiply charged-opener distance with Flow, and do not replace explicit Flow/exit state with raw velocity carry-over.

**Acceptance:** The sequence has no neutral pose between links, the 40ms vulnerability seam remains observable, redirects visibly spend movement energy, reverse pivots brake, and sprint exit reads as one continuous locomotion action.
