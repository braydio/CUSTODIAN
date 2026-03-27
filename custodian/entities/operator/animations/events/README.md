# Animation Events

Events are markers that occur during animations to trigger game logic.

## Event Types

| Event | Phase | Description |
|-------|-------|-------------|
| `start` | Beginning | Animation just started |
| `windup` | Pre-attack | Preparation phase (can be cancelled) |
| `active` | Attack | Damage frame / hitbox active |
| `recovery` | Post-attack | Return to neutral |

## Animation → Event Mapping

### Combat Animations

```
attack_fast
 ├ start       → Attack begins
 ├ windup      → Weapon swinging (last chance to cancel)
 ├ active      → DAMAGE FRAME - Apply damage here
 └ recovery    → Return to idle

attack_heavy
 ├ start       → Attack begins
 ├ windup      → Heavy windup (longer)
 ├ active      → DAMAGE FRAME - Apply heavy damage
 └ recovery    → Longer recovery

attack_dash
 ├ start       → Dash begins
 ├ windup      → Charge up
 ├ active      → DAMAGE FRAME + Dash movement
 └ recovery    → Slow down
```

### Movement Animations

```
walk
 ├ start       → Walk cycle begins
 └ loop        → Footstep sounds, etc.

sprint
 ├ start       → Sprint begins
 └ loop        → Heavy breathing, faster footstep
```

### Reaction Animations

```
hit_recoil
 ├ start       → Knockback applied
 └ end         → Return to idle

stagger
 ├ start       → Stagger begins
 └ end         → Recover balance

death
 └ start       → Disable controls, play death effect
```

## Usage in Code

```gdscript
# Trigger event from animation callback
func _on_animation_track_frame(track_name: String, frame_idx: int):
	if track_name == "events":
		var event = animation_player.get_node("attack_fast").get_key_value(frame_idx)
		current_state.on_animation_event(event)
```
