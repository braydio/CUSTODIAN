# Repair Gameplay System Implementation Notes (2026-03-07)

## Implemented Runtime Slice

### Operator repair loop

- Added hold-to-repair behavior in `res://entities/operator/operator.gd`
- Input: hold `R`
- Repair amount: `repair_rate * delta` (default `15 HP/sec`)
- Repair targets: nearest `Damageable` in `structure` group within interaction range

### Repair prompt integration

- Added contextual prompt via `Operator.get_repair_prompt()`
- Existing UI prompt pipeline now surfaces repair prompt when applicable

### Destroyed lockout

- `Damageable.repair()` now refuses repair when `state == "destroyed"`
- This enforces documented anti-exploit rule for in-combat repair

## Notes

- Existing interaction prompts (terminal/interactables) retain priority over repair prompt.
- This slice does not yet add progress bars, repair VFX, or dedicated repair tool mode.
- Balance values remain provisional and should be tuned in playtest.
