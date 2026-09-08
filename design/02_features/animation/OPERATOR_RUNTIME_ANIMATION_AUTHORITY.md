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

### New-animation wiring rule

A new gameplay state or transition requiring newly authored animation is not a
reason to bypass runtime authority.

If a required semantic identity exists as art but is not yet consumable through
the generated SpriteFrames, publication through the source to runtime to
manifest to SpriteFrames pipeline is part of implementing that gameplay change.

Direct gameplay PNG preloads are prohibited as a temporary wiring shortcut.

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

- [x] Inventory and materialize every live compatibility-only animation.
- [x] Strict modern schema; normalization isolated in migration tooling.
- [x] Weapon source/runtime split and deterministic runtime-scanned manifest.
- [x] One generated runtime SpriteFrames including owner-prefixed weapon layers.
- [x] One exact/SOUTH selector with telemetry and explicit OMNI behavior.
- [ ] Actor, states, guard, combat resources and weapon definitions migrated.
- [ ] Socket/posture ownership renamed and separated from direction selection.
- [ ] Workbench publication/browser migrated; compatibility machinery deleted.
- [x] Authority/path/selector tests, changed validation and Moment Forge pass.
- [ ] Final audit has no active Operator compatibility/alias/source consumers.

The user-supplied 26-step migration packet is the implementation scope; these
gates track completion, not a reduced replacement scope.

## Migration debt ledger

Legacy art is deliberately still present, and every remaining item is counted
rather than hidden:

- Legacy actions in `source/` are skipped by the sync, never synchronized.
- Legacy actions under `runtime/` are residue: excluded from the manifest and
  the generated SpriteFrames, and deleted only by the explicit
  `sync_operator_runtime_assets.py --remove-legacy-runtime`, which stays unsafe
  until the actor cutover lands.
- Legacy weapon art is mirrored under `weapons/<weapon>/runtime/operator/` so
  the surviving compatibility resources read runtime, not authoring, authority.

`operator_runtime_animation_authority_smoke.py` and
`operator_runtime_path_audit.py` both separate always-enforced invariants from
completion gates. Run either with `--final`: the migration is finished when both
pass with that flag, and the temporary SOUTH branch can then leave the selector.

## Next Agent Slice

Preservation is complete. 42 verified strips now cover heavy attack/windup/
recovery/guard, Sword-Cleaver and Vigil-Dagger three-link E/W packages, the
retired melee stance, and the actor-installed critical hitspark and ranged
fire-walk sheets. Every extraction is per-frame SHA256 verified, and the
sheet-sourced ones are byte-identical to their sources.

The pipeline is done: `sync_operator_runtime_assets.py` validates source,
synchronizes runtime, then scans runtime to emit the manifest;
`build_operator_runtime_frames.gd` turns that manifest into the single
`operator_runtime_frames.tres` (512 animations, authored FPS/loop/durations
preserved from the timing sidecars).

Remaining work is consumer cutover, in dependency order:

1. `MeleeAttackProfile` presentation contract and the attack `.tres` resources.
2. `operator.gd`: drop the raw PNG constants and dynamic frame registration,
   install `OperatorAnimationSelector` over the generated SpriteFrames.
3. States, guard controller, weapon definitions, socket/posture renames.
4. `operator.tscn` collapsed onto the one SpriteFrames; Workbench browser and
   publish moved onto the runtime manifest.
5. Delete the compatibility resources and their updater, then clear legacy
   residue with `--remove-legacy-runtime`.

Do not delete a compatibility resource before its consumers are cut over.
Preserve combat authority and all existing authored semantic art.
