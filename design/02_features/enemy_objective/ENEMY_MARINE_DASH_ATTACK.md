# Enemy Marine Dash Attack

Status: implemented-v1  
Last updated: 2026-06-05

## Summary

`enemy_marine` dash attack is a heavy commitment move built around this rhythm:

```text
stand / ready -> deep compression -> full-body missile -> impact -> skid / punish recovery
```

The move should feel like armored mass crossing space violently. Its threat comes from readable windup, sudden acceleration, hitstop, knockback, camera feedback, and recovery commitment, not from damage alone.

## Runtime Ownership

- Shared actor behavior: `custodian/game/actors/enemies/enemy.gd`
- Marine scene/tuning: `custodian/game/actors/enemies/enemy_marine.tscn`
- Animation loading: `custodian/game/enemies/procgen/grunt_animation_library.gd`
- Player impact receiver: `custodian/game/actors/operator/operator.gd`
- Sundered Keep authored ambush: `custodian/game/world/sundered_keep/sundered_keep_marine_ambush.gd`
- Runtime body strip currently wired: `custodian/content/sprites/enemies/enemy_marine/runtime/body/enemy_marine__body__unarmed__dash_attack_01__e__8f__156.png`
- Runtime FX strip currently wired: `custodian/content/sprites/enemies/enemy_marine/runtime/fx/enemy_marine__fx__unarmed__dash_attack_01__e__8f__156.png`

## Required Phases

1. Windup / telegraph
   - Lock dash direction at windup start.
   - Stop movement and show a faint amber ground warning line.
   - Animation should read as deeper compression: helmet lower, shoulders hunched forward, front knee bent, rear foot digging backward, arms tucked tight, cloth/cape pulled back.

2. Dash movement
   - Attacker cannot steer.
   - Active hit window exists only during dash movement.
   - Current v1 target distance: `150px` in `0.18s`.
   - Stop early on wall/collision and enter impact/recovery.

3. Impact lock
   - One hit per target per dash.
   - Apply damage, hitstop, forced slide/knockback, and camera feedback.
   - Play the body/FX impact frame if the current sheet has one.

4. Recovery punish window
   - No active hitbox.
   - Marine is vulnerable and cannot immediately turn another dash into the player.
   - Animation should read as skid/drag: shoulder low, boot planted, one knee near ground, arm/weapon dragging forward, cape settling.

## Gameplay Values

Current v1 values:

```gdscript
marine_dash_windup_time = 0.32
marine_dash_time = 0.18
marine_dash_impact_lock_time = 0.08
marine_dash_recovery_time = 0.42
marine_dash_distance_px = 150.0
marine_dash_damage = 28.0
marine_dash_poise_damage = 55.0
marine_dash_knockback_px = 95.0
marine_dash_attacker_hitstop = 0.045
marine_dash_victim_hitstop = 0.09
marine_dash_camera_shake_strength = 0.45
marine_dash_camera_shake_duration = 0.16
marine_dash_hit_active_start_ratio = 0.34
marine_dash_hit_active_end_ratio = 0.82
marine_dash_hit_forward_reach_px = 24.0
marine_dash_hit_lateral_reach_px = 18.0
```

Rules:

- Lock dash direction at windup start.
- Show telegraph during windup.
- Active hitbox only during dash frames, never during recovery.
- Active hit contact is additionally gated to the middle of travel and a tight body-contact lane; the dash lane/telegraph is not itself damage.
- One hit per target per dash.
- Attacker cannot steer during dash.
- Attacker is vulnerable during recovery.
- On wall collision, stop dash early and play impact/recovery.

## Animation Direction

The current east dash has the correct core silhouette. Future production passes should emphasize contrast:

- Frame 1: idle/ready, roughly `80ms`.
- Frame 2: deeper compression, `110-140ms`.
- Frame 3: launch smear, roughly `45ms`.
- Frames 4-5: fast dash body, `35-45ms` each.
- Frame 6: impact/strike, roughly `60ms`.
- Frame 7: skid, roughly `80ms`.
- Frame 8: recover, roughly `100ms`.

The biggest sprite improvement is more squash before launch and more ugly skid after impact.

## FX Direction

Dash FX must be a separate overlay sheet, aligned to the body frame count:

```text
enemy_marine__fx__unarmed__dash_attack_01__{direction}__8f__156.png
```

Frame plan:

1. none / tiny boot dust
2. compressed boot scrape + shoulder/visor glow
3. launch burst behind feet
4. long dark cape/armor trail
5. thinner trail, floor sparks
6. impact burst / shock crescent
7. skid dust and ground scrape
8. settling dust

FX should be heavy, dirty, metallic: dust scrape, broken floor chips, orange sparks, and a short horizontal shockwave. Avoid large magical bursts.

## Directional Asset Target

Minimum useful coverage:

```text
E, W, NE, NW, SE, SW
```

Budget fallback:

```text
E authored, W horizontal-flipped
```

Full directional target:

```text
N, NE, E, SE, S, SW, W, NW
```

## Audio Direction

The sound stack should be:

- windup: low servo whine + armor creak
- launch: compressed air / boot slam
- travel: short dirty whoosh
- impact: metal body hit + bass thud + stone scrape
- recovery: armor skid / boot grind

Do not use sword-swish audio. This is armored mass, not a blade swing.

## Validation

Use:

```bash
cd custodian
godot --headless --script res://tools/validation/authored_vault_grunt_loot_marine_smoke.gd
godot --headless --script res://tools/validation/sundered_keep_large_layout_smoke.gd
```
