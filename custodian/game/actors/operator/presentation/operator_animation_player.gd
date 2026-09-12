class_name OperatorAnimationPlayer
extends RefCounted

## Sole authority for HOW an already-resolved Operator clip plays.
##
## This class is mechanical. It receives a renderer and a clip name that someone
## else already decided on, and it drives playback: start, restart, stop, speed,
## frame and progress. That is the whole job.
##
## It deliberately does NOT know: attack kind, weapon identity, semantic group or
## action, direction or fallback policy, `OperatorAnimationSelector` semantics,
## input, gameplay state, hit windows, posture policy or damage timing. There are
## no action-specific methods here — an `play_fast_attack()` would drag exactly
## the vocabulary this separation exists to keep out.
##
## The neighbouring responsibilities, which must not be merged into this one:
##
##   OperatorBodyPresenter          WHO is allowed to draw
##   OperatorAnimationPlayer        HOW an already-resolved clip plays  (this)
##   OperatorAnimationSelector      WHICH canonical clip a semantic intent means
##   OperatorPresentationController WHAT semantic presentation the actor wants
##
## Visual layers may synchronize to a visible presentation clock through
## `sync_frame()`. GAMEPLAY timing is never owned here: deterministic combat
## timelines own that, and a renderer must never become their authority.


## Whether `sprite` can actually play `animation` right now.
func can_play(sprite: AnimatedSprite2D, animation: StringName) -> bool:
	if sprite == null or sprite.sprite_frames == null or String(animation).is_empty():
		return false
	return (
		sprite.sprite_frames.has_animation(animation)
		and sprite.sprite_frames.get_frame_count(animation) > 0
	)


## Play `animation` on `sprite`.
##
## `restart` forces the clip back to its first frame even when it is already the
## current animation; without it an already-running clip keeps its position,
## which is what callers re-driving the same animation every frame depend on.
func play(sprite: AnimatedSprite2D, animation: StringName, restart := false) -> bool:
	if sprite == null:
		return false
	if restart:
		sprite.stop()
		sprite.frame = 0
	sprite.play(animation)
	return true


## Play only when the sprite is not already running that clip.
##
## The guard callers used to write by hand, in one place: re-issuing `play()` on
## a running clip is usually harmless but not free, and open-coding the check is
## how subtle "restarts every frame" bugs appear.
func play_if_needed(sprite: AnimatedSprite2D, animation: StringName) -> bool:
	if sprite == null:
		return false
	if sprite.animation == animation and sprite.is_playing():
		return false
	sprite.play(animation)
	return true


## Stop playback. `reset_frame` also rewinds, for callers that need a clean pose.
func stop(sprite: AnimatedSprite2D, reset_frame := false) -> void:
	if sprite == null:
		return
	if sprite.is_playing():
		sprite.stop()
	if reset_frame:
		sprite.frame = 0


## Align `follower_sprite` to the frame and progress of `clock_sprite`.
##
## The clock must be a VISIBLE presentation layer. Synchronizing to a hidden
## renderer is the split-brain the melee timing doctrine forbids: a layer nobody
## can see silently deciding when a visible layer advances.
func sync_frame(clock_sprite: AnimatedSprite2D, follower_sprite: AnimatedSprite2D) -> bool:
	if clock_sprite == null or follower_sprite == null:
		return false
	if follower_sprite.sprite_frames == null:
		return false
	var frame_count := follower_sprite.sprite_frames.get_frame_count(follower_sprite.animation)
	if frame_count <= 0:
		return false
	follower_sprite.set_frame_and_progress(
		mini(clock_sprite.frame, frame_count - 1), clock_sprite.frame_progress
	)
	return true


func set_frame_and_progress(sprite: AnimatedSprite2D, frame: int, progress: float) -> void:
	if sprite == null:
		return
	sprite.set_frame_and_progress(frame, progress)


func set_speed_scale(sprite: AnimatedSprite2D, speed_scale: float) -> void:
	if sprite == null:
		return
	sprite.speed_scale = speed_scale
