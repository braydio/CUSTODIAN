# Enemy Savage Runtime Wiring

Status: active rushdown gameplay slice
Last updated: 2026-07-13

## Summary

`enemy_savage` is a distinct active rushdown enemy built on the shared `Enemy` simulation and behavior components.
It is faster and less durable than the grunt, commits to a two-hit melee chain, and uses a short pounce to collapse
medium-close space. Its weakness is low poise and long recovery after overcommitting, not weak damage output.

The Savage is not a stronger grunt. Grunts provide baseline pressure and objective theft; Savages create immediate
combat tempo, punish passive blocking, ignore theft, and expose themselves when their chain or pounce ends.

## Runtime Model

- Enemy type key: `savage`
- Scene: `res://game/actors/enemies/enemy_savage.tscn`
- Animation source: `res://game/enemies/procgen/savage_animation_library.gd`
- Runtime art: `res://content/sprites/enemies/enemy_savage/runtime/body/`
- Debug spawn: `spawn_savage [x_offset y_offset]`
- Wave cost/unlock: cost 3, available from wave 4
- Behavior profile: `raider_savage`
- Core stats: 104 speed, 64 HP, 10 first-hit damage, 16 stagger threshold, 38 critical threshold
- Chain: 0.26s first windup, 10 damage, short gap, 12 damage, then 0.55s recovery
- Guard pressure: blocked chain hits spend 10 then 22 stamina through the shared Operator hit gateway
- Pounce: 0.28s highlighted windup, 64px/0.18s locked lunge, 18 damage, brief knockback, 0.55s recovery, 1.8s cooldown
- Objective utility: cannot steal resources; may perform fast, crude storage sabotage

Available idle coverage is E, N, S, SE, SW, and W. NE/NW deliberately fall back to N. Frame canvases remain at
their supplied sizes (`95`, `96`, and `128` pixels); the runtime slices each strip using explicit per-animation
metadata instead of rescaling source pixels.

## Behavior Identity

`raider_savage` is quick to notice and engage, with high aggression (`0.92`), very low self-preservation (`0.08`),
low theft interest, and theft disabled. It has medium-high curiosity, a low morale pool, severe morale loss from
stagger, engage speed equal to its scene speed, and a flee speed below its engage speed. This makes it commit early
and collapse under clean interruption instead of probing, kiting, or retreating intelligently.

Both Savage commitments remain fixed-step simulation-owned in `Enemy`. Incoming damage cancels an active chain or
pounce before recoil/stagger/critical reaction playback, preserving its intended flinch susceptibility. Animation
selection remains presentation-only and currently falls back to directional idle.

## Current Art Limitation

The current slice has no authored Savage movement, chain, pounce, reaction, FX, or death strips. The actor is fully
functional, but idle clips are used as presentation fallback while moving and attacking, and death has no authored
playback delay. Missing production art is tracked only in root `REQUIRED_ASSETS.md`.

## Acceptance

- Full sprite ingest succeeds with superseded cleanup.
- `enemy_savage.tscn` instantiates with six runtime idle animations.
- `WaveManager`, `EnemyFactory`, `EnemyDirector`, and `scenes/game.tscn` resolve `savage`.
- `spawn_savage` reaches the shared debug-spawn path.
- `savage_runtime_smoke.gd` proves frame counts, direction selection, scene activation, and spawn-system wiring.
- `enemy_savage_smoke.gd` proves stats, profile identity, no-theft behavior, two chain hits with 10/22 guard costs,
  and one pounce hit in its active window.

## Next Agent Slice

- Goal: replace idle substitution with authored Savage rushdown action playback.
- Files: Savage runtime strips, `savage_animation_library.gd`, `enemy.gd`, `enemy_savage.tscn`, and focused smoke.
- Constraints: preserve fixed-step gameplay authority in `Enemy`; animation selection remains presentation-only; do
  not rescale authored pixels without an explicit normalization contract.
- Acceptance: movement, `melee_chain_01`, `pounce`, stagger/flinch, and death clips play from canonical runtime paths;
  death waits for its non-looping clip; at least S/E/W/N resolve before broad encounter use; gameplay timing and hit
  authority remain independent of animation frames.
