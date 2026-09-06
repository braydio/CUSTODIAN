# Operator Runtime Animation Authority

Status: migration in progress. This contract supersedes Operator animation
fallback and compatibility allowances in older animation/pipeline documents.
Existing bridges are migration debt, not permitted final architecture.

## Ownership

Authoring authority:

- `content/sprites/operator/source/animations/`
- `content/sprites/weapons/<weapon>/source/operator/`

Execution authority:

- `content/sprites/operator/runtime/`
- `content/sprites/weapons/<weapon>/runtime/`

Gameplay must never read Operator animation art from `source/`. Weapon art
remains weapon-owned. Unrelated weapon runtime content is outside this migration.

## Identity and selection

Runtime identity is `profile / group / action / direction / layer`.
Weapon identities use `weapon/<weapon_id>/` before that identity.

`OperatorAnimationSelector` resolves only:

1. The exact requested runtime identity.
2. Temporarily, SOUTH in the same profile, group, action, layer and weapon owner.
3. A missing-animation error and empty result.

OMNI identities are explicit; they never fall back to SOUTH. No selection may
substitute another action, group, profile, layer or owner. Old left/right or
unsuffixed aliases, nearest-direction searches, source assets, compatibility
SpriteFrames and legacy animation identities are forbidden in the final runtime.

Every south substitution records `operator_animation_south_fallback` with
profile, group, action, requested direction and layer. Remove the south branch
when the required contract has zero missing exact directional identities.

## Build and publication

`sync_operator_runtime_assets.py` validates source, synchronizes canonical
runtime PNGs, removes superseded managed runtime files, then scans runtime to
generate `content/sprites/operator/runtime/operator_runtime_manifest.generated.json`
with schema `custodian.operator_runtime_manifest.v1`. Every manifest PNG must
contain `/runtime/`; legacy actions are rejected.

After Godot import, `build_operator_runtime_frames.gd` generates the sole
`content/sprites/operator/runtime/operator_runtime_frames.tres`. Presentation
nodes share this resource; the actor does not build an animation database.
Workbench browses the runtime manifest and publishes through this same build.

## Preservation and migration gates

Before removing a compatibility resource, materialize still-live frames using
its actual SpriteFrames textures and ordering. Preserve pixels, canvas, frame
count, frame durations, FPS and loop behavior. Never redraw, infer sheet slicing,
overwrite existing semantic art, or rename a baked sheet without extracting its
actual frames. Art without reliable direction metadata initially uses SOUTH.

Combat profiles carry a semantic `presentation_action`, not concrete clip names,
fallbacks or overlay clips. Weapon definitions retain combat/tuning data and
semantic actions, not independent SpriteFrames stores. States and guard code
request semantic behavior; the selector owns animation selection. Socket tracks
own sockets, and posture state owns posture.

Deletion requires zero live consumers, pixel/timing preservation evidence, and
passing runtime tests. Migration is complete only when all bridges disappear.

## Acceptance and remaining implementation

- [ ] Inventory and materialize every live compatibility-only animation.
- [ ] Strict modern schema; normalization isolated in migration tooling.
- [ ] Weapon source/runtime split and deterministic runtime-scanned manifest.
- [ ] One generated runtime SpriteFrames including owner-prefixed weapon layers.
- [ ] One exact/SOUTH selector with telemetry and explicit OMNI behavior.
- [ ] Actor, states, guard, combat resources and weapon definitions migrated.
- [ ] Socket/posture ownership renamed and separated from direction selection.
- [ ] Workbench publication/browser migrated; compatibility machinery deleted.
- [ ] Authority/path/selector tests, changed validation and Moment Forge pass.
- [ ] Final audit has no active Operator compatibility/alias/source consumers.

The user-supplied 26-step migration packet is the implementation scope; these
gates track completion, not a reduced replacement scope.

## Next Agent Slice

Preservation progress: 32 strips have been extracted and verified, covering
heavy attack/windup/recovery/guard body and overlays, and Sword-Cleaver's
three-link E/W body/FX/weapon packages. Timing sidecars use
`custodian.operator_animation_timing.v1` and must be consumed by the runtime
sync/builder. The selector module and its independent smoke pass; actor wiring
and the end-to-end authority audit are still pending. No compatibility resource
has been removed and no production fallback has been cut over in this slice.

Complete preservation inventory using actual loaded SpriteFrames, including
actor-installed critical/dodge/ranged frames. Then perform runtime synchronization
and consumer cutover. Do not delete the old resources while this checklist is
incomplete. Preserve combat authority and all existing authored semantic art.
