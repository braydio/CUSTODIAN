CUSTODIAN IMPLEMENTATION PASS 1
CORE RUNTIME CORRECTNESS: SPAWNING, NAVIGATION, ENEMY AWARENESS, MELEE, VEHICLE

IMPLEMENT NOW. Do not return a plan.

Repository:
braydio/CUSTODIAN

Audited baseline:
4e1b5e57080d53be2ea8ebd005bab6d4e2025bcf

Before editing:
- Read root AGENTS.md and custodian/AGENTS.md.
- Run the required repository adjacency/graph inspection.
- Re-check the named files against current HEAD in case another agent changed them.
- Preserve existing authorities. Do not create parallel navigation, perception, or movement frameworks.

OUT OF SCOPE:
- Fabricator presentation/scale. It was handled separately.
- cognitive residue seeking
- inventory/terminal UI
- Home opening
- procgen visual art
- portal redesign

MISSION

Resolve NOTES 6, 8, 11, 14, and the runtime-defect portions of 15:

1. Shrumbs and camp enemies may only spawn on valid runtime-walkable space.
2. Fix camp enemies inheriting the ProcGenMap 2× transform.
3. Preserve current pathfinding behavior. Do not rewrite NavigationSystem.
4. A player projectile striking a hostile must immediately alert that hostile.
5. Verify idle grunts actually transition into their already-existing patrol behavior.
6. Remove point-blank melee dead zone.
7. Make Light Buggy exit placement body-safe and traversability-safe.
8. Wire the existing vehicle turn_response profile field.
9. Disable the production debug startup grunt.

============================================================
A. FIX THE AMBIENT CAMP 2× PARENTING BUG
============================================================

CURRENT ROOT CAUSE

custodian/game/world/procgen/proc_gen_map.tscn currently has:

    [node name="ProcGenMap" type="Node2D"]
    scale = Vector2(2, 2)

ContractWorldLoader parents generated ambient camp markers beneath the procgen map.

AmbientEnemySpawner parents AmbientEnemyCamp beneath the marker.

Then:

custodian/game/systems/spawning/ambient_enemy_camp.gd

currently does:

    var parent := get_parent()

and passes that parent into queue_enemy_spawn().

AmbientEnemySpawner._spawn_queued_enemy() then does:

    enemy.position = (parent as Node2D).to_local(spawn_position)
    parent.add_child(enemy)

Therefore the spawned grunt becomes a descendant of the 2× ProcGenMap transform.

enemy_grunt.tscn itself is explicitly scale 1:
- custom_enemy_animation_scale = Vector2(1, 1)
- custom_enemy_fx_scale = Vector2(1, 1)
- AnimatedSprite2D.scale = Vector2(1, 1)

DO NOT counter-scale the enemy.
DO NOT add enemy.scale = Vector2(0.5, 0.5).

The semantic fix is to spawn mobile actors under an unscaled world actor container.

EDIT:
custodian/game/systems/spawning/ambient_enemy_spawner.gd

Add:

    @export var enemy_container_path: NodePath = \
        NodePath("/root/GameRoot/World/Enemies")

Add:

    func get_enemy_spawn_parent() -> Node2D:
        var container := get_node_or_null(enemy_container_path) as Node2D
        if container != null:
            return container
        return get_node_or_null("/root/GameRoot/World") as Node2D

EDIT:
custodian/game/systems/spawning/ambient_enemy_camp.gd

In spawn_camp(), stop using get_parent() as the normal spawned-enemy parent.

Resolve the scheduler first, then:

    var parent: Node2D = null

    if (
        spawner != null
        and spawner.has_method("get_enemy_spawn_parent")
    ):
        parent = spawner.call("get_enemy_spawn_parent") as Node2D

    if parent == null:
        parent = get_node_or_null(
            "/root/GameRoot/World/Enemies"
        ) as Node2D

    if parent == null:
        parent = get_node_or_null(
            "/root/GameRoot/World"
        ) as Node2D

If no neutral world parent exists, abort and warn.
Do not fall back to the scaled camp marker unless running a deliberately isolated unit test.

Preserve world/global spawn coordinates by converting through the neutral parent's to_local() before add_child(), as the current spawner already does.

============================================================
B. USE EXISTING PROCGEN WALKABILITY AUTHORITY FOR SPAWNS
============================================================

DO NOT create traversable_spawn_resolver.gd.

ProcGenTilemap ALREADY owns this contract:

    find_safe_runtime_walkable_global(world_pos, radius_tiles)
    find_nearest_runtime_walkable_global(...)
    project_runtime_walkable_global(...)
    find_nearest_runtime_walkable_cell(...)
    is_valid_spawn_cell(...)
    is_runtime_walkable_after_props(...)

It is registered in:

    "procgen_walkability_provider"

and find_safe_runtime_walkable_global() is the preferred spawn authority because it also applies local escape/blocker safety.

EDIT:
custodian/game/systems/spawning/ambient_enemy_spawner.gd

Add one centralized adapter:

    func resolve_runtime_walkable_spawn(
        desired_position: Vector2,
        radius_tiles: int = 6
    ) -> Vector2:
        var best := Vector2.INF
        var best_distance_sq := INF

        for provider in get_tree().get_nodes_in_group(
            "procgen_walkability_provider"
        ):
            if (
                provider == null
                or not provider.has_method(
                    "find_safe_runtime_walkable_global"
                )
            ):
                continue

            var candidate: Variant = provider.call(
                "find_safe_runtime_walkable_global",
                desired_position,
                radius_tiles
            )

            if not candidate is Vector2:
                continue

            var position := candidate as Vector2

            if position == Vector2.INF:
                continue

            var distance_sq := desired_position.distance_squared_to(
                position
            )

            if distance_sq < best_distance_sq:
                best = position
                best_distance_sq = distance_sq

        if best != Vector2.INF:
            return best

        # Non-procgen fallback only.
        var navigation := get_node_or_null(
            "/root/GameRoot/NavigationSystem"
        )

        if (
            navigation != null
            and navigation.has_method("is_in_walkable_area")
            and bool(
                navigation.call(
                    "is_in_walkable_area",
                    desired_position
                )
            )
        ):
            return desired_position

        return Vector2.INF

Add Observatory helpers/counters:

    ambient_enemy_spawn_projected
    ambient_enemy_spawn_rejected_unwalkable

In AmbientEnemyCamp.spawn_camp():

Current radial position generation is fine as a DESIRED position:

    var desired_spawn_position := (
        global_position
        + Vector2.RIGHT.rotated(angle) * radius
    )

But resolve it before queueing:

    var spawn_position := Vector2.INF

    if (
        spawner != null
        and spawner.has_method(
            "resolve_runtime_walkable_spawn"
        )
    ):
        spawn_position = spawner.call(
            "resolve_runtime_walkable_spawn",
            desired_spawn_position,
            6
        )

    if spawn_position == Vector2.INF:
        continue

Avoid multiple projected members collapsing onto the exact same spawn.
Within one spawn_camp() batch, keep an Array[Vector2] and require roughly 24-32 px of separation.

IMPORTANT:
The number of attempted slots should still become resolved for the camp even if a slot is rejected. Do not create an infinite "try to spawn the impossible fourth grunt every frame" loop.

REVALIDATE THE QUEUED POSITION TOO.

In AmbientEnemySpawner._spawn_queued_enemy():

Before instantiating:

    var requested_position := request.get(
        "spawn_position",
        Vector2.ZERO
    ) as Vector2

    var spawn_position := resolve_runtime_walkable_spawn(
        requested_position,
        4
    )

    if spawn_position == Vector2.INF:
        _obs_increment(
            "ambient_enemy_spawn_rejected_unwalkable"
        )
        return

    if spawn_position.distance_squared_to(
        requested_position
    ) > 1.0:
        _obs_increment(
            "ambient_enemy_spawn_projected"
        )

This catches runtime prop/topology changes between queue and instantiate.

============================================================
C. FIX SHRUMB SPAWN AUTHORITY
============================================================

EDIT:
custodian/game/systems/core/systems/ambient_critter_manager.gd

The current ambient path does:

    spawn_pos = player.global_position + spawn_offset

and _is_valid_spawn_position() only checks player distance and literally contains:

    # Could add wall/collision checks here

Replace this incomplete authority.

Add:

    func _resolve_runtime_walkable_spawn(
        desired_position: Vector2,
        radius_tiles: int = 8
    ) -> Vector2:

Use the same procgen_walkability_provider algorithm as above.

Do NOT duplicate the topology logic itself.
Call find_safe_runtime_walkable_global().

Fallback to NavigationSystem.is_in_walkable_area() only when no procgen provider is available.

For each ambient Shrumb spawn:

    var desired_spawn_pos := ...
    var spawn_pos := _resolve_runtime_walkable_spawn(
        desired_spawn_pos,
        8
    )

    if spawn_pos == Vector2.INF:
        increment Observatory:
            ambient_critter_spawn_rejected_unwalkable
        return

    if spawn_pos differs:
        increment:
            ambient_critter_spawn_projected

Also run the final positions of initial/contract Shrumb population through this authority before instantiating, because a nominal floor tile can become blocked by runtime props.

Delete the old misleading "_is_valid_spawn_position" implementation or convert it into a wrapper around the real authority.

============================================================
D. DO NOT REWRITE ENEMY NAVIGATION OR PATROL
============================================================

IMPORTANT CORRECTION:

The current EnemyBehaviorStateMachine ALREADY sends an IDLE enemy to PATROL when objective scoring returns no positive candidate.

The current patrol implementation ALREADY projects patrol goals through procgen walkability.

enemy.gd ALREADY stops instead of direct-walking when authoritative pathfinding returns no path:

    if current_path.is_empty():
        return Vector2.ZERO

Therefore do not add another IDLE -> PATROL system.

Instead add an integration test proving that the actual camp-spawned grunt behaves correctly AFTER its parent and spawn position are fixed.

Extend or supplement:

    custodian/tools/validation/
        enemy_patrol_navigation_smoke.gd

Add:

    ambient_enemy_noncombat_patrol_smoke.gd

It must instantiate/use a real behavior-enabled EnemyGrunt and prove:

- behavior_state_machine_enabled == true
- after > idle_rescore_interval_sec with no player alert/objective,
  state becomes PATROL or AMBIENT_ACTIVITY
- on valid traversable space it changes position
- when given an unreachable path it stops rather than moving directly
- it remains inside its ambient-home leash

If this passes, DO NOT modify idle/patrol logic.

============================================================
E. GUARANTEE DIRECT-HIT AWARENESS
============================================================

Gun noise is already implemented.

operator.gd already calls NoiseEventBus.emit_at(...) with:
    kind = "gunshot"
    team = "player"
    weapon-authored radius/threat/loudness

EnemyPerceptionComponent already consumes NoiseEventBus events.

Preserve all of that.

The missing guarantee is:
"the enemy I directly shot must know I attacked it."

EnemyBehaviorStateMachine already exposes:

    force_notice(operator)

Use that.

EDIT:
custodian/game/actors/projectiles/bullet.gd

Add:

    func _notify_direct_hit_awareness(
        target: Node
    ) -> void:
        if team != "player":
            return
        if shooter == null or not is_instance_valid(shooter):
            return
        if target == null or not target.is_in_group("enemy"):
            return

        var behavior := target.get_node_or_null(
            "EnemyBehaviorStateMachine"
        )

        if (
            behavior != null
            and behavior.has_method("force_notice")
        ):
            behavior.call("force_notice", shooter)

Call this after an enemy has accepted a projectile contact:
- after receive_projectile_hit() for an enemy
- after take_damage() for an enemy

Do not call it:
- for terrain
- for same-team rejected contacts
- for an entity the bullet never actually touched

Even an armored/zero-damage direct impact may alert the victim. Awareness is about being attacked, not merely HP loss.

Add:
    enemy_direct_hit_awareness_smoke.gd

Assert:
- unseen grunt starts non-alerted
- direct player projectile contact calls existing force_notice
- blackboard operator_ref becomes shooter
- has_seen_operator == true
- is_alerted == true
- state becomes NOTICE
- nearby but unstruck enemies continue to use NoiseEventBus, not this direct-hit shortcut

============================================================
F. REMOVE POINT-BLANK MELEE DEAD ZONE
============================================================

EDIT:
custodian/game/actors/operator/operator.gd

Current runtime hitbox placement is:

    weapon_hitbox.position =
        Vector2(_melee_range_current * 0.62, 0)

    circle.radius =
        max(8.0, _melee_range_current * 0.44)

That leaves the Area2D rear edge at approximately 0.18R.

For the 72px fallback range this is ~13px, right around the half-width of the grunt's 26×26 collision.
This makes point-blank contact marginal and alignment-dependent.

Change only the BROAD-PHASE overlap geometry:

    func _update_melee_hitbox_transform() -> void:
        if (
            hitbox_root == null
            or weapon_hitbox == null
            or weapon_hitbox_shape == null
        ):
            return

        hitbox_root.rotation = _melee_forward.angle()

        weapon_hitbox.position = Vector2(
            _melee_range_current * 0.50,
            0.0
        )

        if weapon_hitbox_shape.shape is CircleShape2D:
            var circle := (
                weapon_hitbox_shape.shape
                as CircleShape2D
            )
            circle.radius = max(
                8.0,
                _melee_range_current * 0.55
            )

WHY THIS IS SAFE:
_apply_melee_hitbox_tick() still applies the real target-distance/range and directional contact rules.

Do not increase authored attack range.
Do not alter MeleeTargetResolver target-assist cone/range.
Do not add a mandatory sidearm requirement.

Add:
    operator_melee_point_blank_smoke.gd

Test:
- hostile 12-18px in front: hittable
- normal 40-60px contact: hittable
- target > actual authored range: NOT hittable
- target immediately behind Operator: NOT hittable
- same target cannot be damaged repeatedly by the same contact window

============================================================
G. LIGHT BUGGY EXIT CLEARANCE
============================================================

EDIT:
custodian/game/vehicles/pilotable_vehicle.gd

Current code uses:
    PhysicsPointQueryParameters2D

This only proves that one pixel is clear.

The Operator actually has a CapsuleShape2D collision with radius 11.
The Light Buggy has a CapsuleShape2D radius 28 / height 64.

Replace point exit clearance with Shape2D clearance.

Add helpers roughly equivalent to:

    func _get_pilot_collision_shape_node() \
        -> CollisionShape2D:
        if pilot == null:
            return null
        return pilot.get_node_or_null(
            "CollisionShape2D"
        ) as CollisionShape2D

    func _is_exit_position_clear(
        position: Vector2
    ) -> bool:
        if not _is_exit_position_traversable(position):
            return false

        var world := get_world_2d()
        if world == null:
            return true

        var pilot_shape_node := \
            _get_pilot_collision_shape_node()

        var shape: Shape2D = null
        var local_offset := Vector2.ZERO

        if (
            pilot_shape_node != null
            and pilot_shape_node.shape != null
        ):
            shape = pilot_shape_node.shape.duplicate()
            local_offset = pilot_shape_node.position
        else:
            var fallback := CapsuleShape2D.new()
            fallback.radius = 12.0
            fallback.height = 24.0
            shape = fallback

        var query := PhysicsShapeQueryParameters2D.new()
        query.shape = shape
        query.transform = Transform2D(
            0.0,
            position + local_offset
        )
        query.collision_mask = (
            _pilot_collision_mask
            if _pilot_collision_mask != 0
            else 1
        )
        query.collide_with_bodies = true
        query.collide_with_areas = false

        var exclusions: Array[RID] = [get_rid()]
        if pilot is CollisionObject2D:
            exclusions.append(
                (pilot as CollisionObject2D).get_rid()
            )
        query.exclude = exclusions

        return (
            world.direct_space_state
                .intersect_shape(query, 8)
                .is_empty()
        )

Add:

    func _is_exit_position_traversable(
        position: Vector2
    ) -> bool:
        var navigation := get_node_or_null(
            "/root/GameRoot/NavigationSystem"
        )

        if (
            navigation != null
            and navigation.has_method(
                "is_in_walkable_area"
            )
        ):
            return bool(
                navigation.call(
                    "is_in_walkable_area",
                    position
                )
            )

        return true

Do not project an exit through a wall to make it valid.
Candidate search should test actual adjacent positions.

Compute a safe candidate radius from vehicle/pilot dimensions.
For the current authored actors, target ~52-56px.

Update:

custodian/game/actors/vehicles/light_buggy.tscn

ExitMarker:
    from Vector2(48, 4)
    to approximately Vector2(56, 4)

Generate deterministic candidates:
- authored ExitMarker
- +X
- -X
- +Y
- -Y
- four diagonals
- optional second ring

If there is a valid adjacent location, exit must succeed.

If all are blocked, remain piloted as current code does.

============================================================
H. WIRE turn_response WITHOUT REBALANCING THE BUGGY
============================================================

Current profile:

custodian/content/vehicles/
    vehicle_movement_profiles.json

contains:

    "max_speed": 175
    "acceleration": 420
    "deceleration": 520
    "turn_response": 10
    "reverse_multiplier": 0.45
    "offroad_speed_multiplier": 0.78

turn_response is currently dead data.

In PilotableVehicle._apply_movement():

Read:

    var turn_response := float(
        movement_profile.get("turn_response", 10.0)
    )

For ordinary forward/side turning, blend current travel direction toward input direction using a frame-rate-independent alpha:

    var turn_alpha := 1.0 - exp(
        -maxf(0.01, turn_response) * delta
    )

Use normalized lerp/slerp to form the target direction.

PRESERVE the current explicit reverse rule:
when input dot facing_direction < -0.25,
apply reverse_multiplier and do not force a forward-turn arc first.

Do not alter max_speed/acceleration/deceleration in this pass.
First make the declared profile actually control the vehicle.

============================================================
I. DISABLE STARTUP DEBUG GRUNT
============================================================

EDIT:
custodian/scenes/game.tscn

WaveManager currently has:

    debug_spawn_grunt_on_start = true

Set:

    debug_spawn_grunt_on_start = false

Do not delete the debug feature itself.

Run:
    wave_manager_debug_grunt_spawn_gate_smoke.gd

============================================================
VALIDATION
============================================================

Create/run:

    ambient_actor_spawn_walkability_smoke.gd
    ambient_enemy_spawn_parent_scale_smoke.gd
    ambient_enemy_noncombat_patrol_smoke.gd
    enemy_direct_hit_awareness_smoke.gd
    operator_melee_point_blank_smoke.gd
    vehicle_exit_clearance_smoke.gd

Also run:

    enemy_patrol_navigation_smoke.gd
    ambient_enemy_navigation_perf_smoke.gd
    ranged_combat_balance_smoke.gd
    wave_manager_debug_grunt_spawn_gate_smoke.gd

Run the repository validation manifest / --changed validation as required.

REQUIRED ACCEPTANCE

- camp-spawned grunt global scale == Vector2.ONE
- camp-spawned and direct EnemyGrunt presentation/collision dimensions agree
- no ambient enemy is instantiated outside runtime walkable space
- no Shrumb is instantiated outside runtime walkable space
- failed path does not permit direct movement
- camp grunt patrol/ambient behavior works after valid spawn
- direct player projectile impact guarantees victim NOTICE/alert
- weapon noise still alerts nearby enemies through NoiseEventBus
- point-blank forward melee works
- no additional melee range is granted
- Buggy exits whenever a body-sized adjacent traversable location exists
- Buggy refuses impossible exits without corrupting pilot state
- turn_response affects handling
- production boot does not spawn the debug grunt

DOCUMENTATION

Because this alters runtime architecture contracts:
- update the relevant active design spec(s) for spawning/navigation/vehicle/combat only where behavior actually changed
- update custodian/docs/ai_context/CURRENT_STATE.md
- do not broadly rewrite root NOTES yet; final reconciliation is Pass 3

Return:
1. exact changed files
2. exact tests run/pass/fail
3. any behavior deliberately left unchanged
4. any runtime observation that contradicts this packet
