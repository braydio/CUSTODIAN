# Instant Replay System

- **Status:** implemented-v1
- **Owner:** presentation-only recent-history playback
- **Runtime:** `custodian/` Godot 4.x
- **Last updated:** 2026-08-12

## Contract

Instant Replay is a visual black-box recorder. It never restores or mutates
authoritative gameplay state. At 30 Hz it retains up to 15 seconds of compact
presentation samples for the Operator, enemies, projectiles, explicitly
registered `instant_replay_vfx`, and the active camera.

F5 pauses the live SceneTree, preserves its prior pause state, hides only the
recorded live presentation roots, and plays lightweight sprite proxies. A
0.7-second reverse traversal establishes temporal context, then playback runs
forward from the oldest retained frame. Reaching the recorded present or
pressing F5/Escape destroys proxies, restores exact live visibility and camera
state, and restores the prior pause state.

Playback controls are Space (play/pause), A/D or mouse wheel (scrub), and 1/2/3
for 0.5x/1x/2x. The overlay processes while the tree is paused.

## Authority

```text
gameplay state          -> untouched live actors/simulation
recording               -> InstantReplayRecorder samples presentation only
replay rendering        -> transient proxy sprites
pause ownership         -> existing SceneTree.paused mechanism
resume                  -> exact captured live pause/visibility/camera state
```

Replay IDs use stable instance IDs for the lifetime of the retained buffer.
Recorded sprite layers retain texture/resource references, relative transforms,
animation name/frame, modulation, visibility, and ordering. Positions and
camera values interpolate between adjacent 30 Hz samples.

## Fidelity Boundary

V1 guarantees readable combatant pose, projectile travel, registered important
VFX, and camera motion. Ambient particles, grass motion, audio reconstruction,
tiny debris, shader time, and nondeterministic decoration are not guaranteed.
Replay is inspection/presentation, not a save state, rollback system, input
recording, or continue-from-the-past mechanic.

## Validation

```bash
env HOME=/tmp/custodian-godot-home godot --headless --path custodian \
  --script res://tools/validation/instant_replay_smoke.gd
```

The smoke proves bounded sampling, actor/projectile capture, pause-safe proxy
playback, interpolation, and exact restoration of pause, visibility, and camera.
