# CUSTODIAN — Drone Sprite Assets Needed

**Created:** 2026-03-19  
**Status:** Pending Assets

---

## Required Drone Animations

### Current Problem

The `drone_missiles` animation uses irregular regions from the missile arm spritesheet:
- Frame regions: 533x229, 541x249, etc.
- Not a clean grid — needs proper animation frames

### Needed Animations

| Animation | Frames | Frame Size | Purpose |
|-----------|--------|-----------|---------|
| `drone_idle` | 2-4 | 96x96 | Hovering idle state |
| `drone_move` | 4-6 | 96x96 | Flying/moving |
| `drone_firing` | 4 | 96x96 | Shooting projectile |
| `drone_missiles` | 6-8 | 96x96 | Missile launch attack |
| `drone_hurt` | 2-3 | 96x96 | Damage feedback |
| `drone_death` | 4-6 | 96x96 | Death explosion |

### Specs

- **Frame size:** 96x96 pixels (matches player scale)
- **Layout:** Horizontal strip (one row)
- **Style:** Consistent with existing drone aesthetic
- **Colors:** Enemy red/orange accents

### Priority

1. **High:** drone_idle, drone_move, drone_firing
2. **Medium:** drone_missiles (replaces messy current)
3. **Low:** drone_hurt, drone_death (nice to have)

---

## After Each Image Received

> ⚠️ **TODO:** Begin implementing animation cleanup from `design/ANIMATION_SYSTEM_MIGRATION.md`

---

## Animation Notes

### drone_idle
- Subtle hover/bob animation
- 2-4 frames loop
- Engine glow effect

### drone_move  
- Forward flight motion
- 4-6 frames
- Banking/tilting

### drone_firing
- Weapon flash
- 4 frames
- Fast animation (high FPS)

### drone_missiles
- Missile deployment
- 6-8 frames
- Launch then retract cycle

### drone_hurt
- Flash white
- Recoil
- 2-3 frames, non-looping

### drone_death
- Explosion
- 4-6 frames
- Fade out

---

## Next Steps

1. [ ] Acquire drone sprite sheets
2. [ ] Verify frame sizes match spec
3. [ ] Begin animation cleanup process
4. [ ] Update `enemy.tres` with new frames
