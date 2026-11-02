# Dodge Charge Feedback

**Project:** CUSTODIAN  
**Status:** implemented-v1  
**Created:** 2026-07-20  
**Last Updated:** 2026-07-20

## Purpose

Make charged-dodge anticipation readable around the Operator without turning charge into invulnerability, spellcasting, or a new permanent HUD subsystem. This presentation composes with the ordinary 9-frame dodge body/rear-FX playback; it does not replace or retime it.

## Visual Contract

- Charge reads as stored mechanical force: a 1–2px body compression and a brass/cyan ground-plane ring.
- Three sparse cyan pixels pull inward across the ground plane while charge accumulates; they stop once the latch is ready rather than radiating like spell particles.
- A tap-length hold remains clean. The ring is withheld until approximately `0.08s` and then selects one of eight authored frames with `round(charge_ratio * 7)`.
- Charge ratio reaches `1.0` at the committed-roll threshold (`0.30s` by default), not at the input safety clamp.
- Full charge plays one five-frame white-cyan latch pass, then settles into a stable ring. Brightness does not continue escalating.
- Release preserves the ordinary dodge animation and rear FX while adding a six-frame origin burst and a cyan trail scaled from `0.25` to `1.0` by charge ratio.
- Maximum release adds one fading afterimage and an approximately 1–2px camera impulse. It must not stack ghost silhouettes.
- Cancellation contracts the ring over approximately `0.08s`; stamina rejection briefly shows a broken danger-red ring instead of a burst.
- Body-wide charge glow is prohibited. Invulnerability remains represented only during the actual dodge iframe window.

Palette authority:

| Role | Color |
|---|---|
| Ring structure | brass `#8a6f3d` |
| Charge energy | blue-tech cyan `#38d6e8` |
| Full latch | white-cyan |
| Stamina | pale green `#b4dca7` |
| Rejection | danger red `#c94d42` |

## Runtime Ownership

`operator.gd` remains authoritative for input, thresholds, profile selection, displacement, stamina, iframes, and recovery. It exposes presentation-only state through:

```gdscript
signal dodge_charge_changed(active: bool, ratio: float, ready: bool)
signal dodge_charge_released(ratio: float, direction: Vector2)
signal dodge_charge_cancelled(reason: StringName)

func get_dodge_charge_status() -> Dictionary:
	return {
		"active": _dodge_charge_active,
		"ratio": _get_dodge_charge_ratio(),
		"ready": _dodge_charge_active and _get_dodge_charge_ratio() >= 1.0,
	}
```

`dodge_charge_feedback.gd` is a non-authoritative signal consumer. It may move visual children, select art frames, play transient effects, pulse a controller, and request a tiny camera presentation impulse. It must never choose dodge profile, distance, stamina cost, or iframe duration.

## HUD Contract

No permanent dodge meter is added. The existing stamina label temporarily reads:

```text
STAMINA DODGE 82%
STAMINA DODGE READY
```

The percentage remains stamina, not charge. At full charge the percentage is omitted so `DODGE READY` reads cleanly in peripheral vision. Insufficient stamina briefly recolors the existing stamina label/bar danger red.

## Asset Contract

Runtime assets live under `custodian/content/sprites/`:

- `operator/runtime/actions/dodge_charge/fx/operator__fx__locomotion__dodge_charge_meter_01__omni__8f__96.png`
- `operator/runtime/actions/dodge_charge/fx/operator__fx__locomotion__dodge_charge_ready_01__omni__5f__96.png`
- `operator/runtime/actions/dodge_charge/fx/operator__fx__locomotion__dodge_charge_release_01__omni__6f__96.png`
- `effects/runtime/motion/dodge_charge_trail_core_01.png`

All textures use nearest filtering. The meter is ratio-selected rather than time-animated; latch and release play at 24 FPS and do not loop.

## Validation

`custodian/tools/validation/operator_dodge_charge_feedback_smoke.gd` proves scene ownership, runtime asset dimensions/frame counts, tap-clean visual delay, ratio-driven frame selection, body compression/reset, full-charge latch, release burst/trail, stamina rejection color, and temporary HUD copy.

## Next Agent Slice

**Goal:** Manually tune effect placement, alpha, camera impulse, and controller strength at gameplay zoom, then add authored mechanical click/hum/latch/discharge sounds if approved assets are supplied.

**Constraints:** Preserve ordinary dodge body/rear-FX timing, keep charge vulnerable, do not add a permanent HUD meter, and do not extend full-charge brightness or iframe duration.

**Acceptance:** Tap dodge remains visually/audio clean; the `0.12s` and `0.30s` thresholds are distinguishable in motion; maximum release reads as a roll rather than teleportation; all focused dodge smokes remain green.
