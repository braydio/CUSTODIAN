# Route Traversal System

**Project:** CUSTODIAN
**Status:** complete-v1
**Runtime target:** Godot 4.x (`custodian/`)
**Last updated:** 2026-07-21

## Purpose

Provide one directed, transactional traversal authority for authored scenes that remain inside a campaign world. Route traversal preserves the campaign-world context and persistent Operator while moving authority between route nodes.

## Ownership Boundary

```text
WorldTransitionManager  Compound ↔ Campaign major-context changes (future)
RouteTraversalManager   Directed traversal inside one campaign (live V1 target)
LevelLoader             Stage, validate, activate, deactivate, cache, release one level
Level scene             Local content, named spawns, state hooks, generic exit requests
```

`LevelLoader` never resolves topology, profiles, branches, or history. Level scenes never instantiate or select their next destination. `RouteTraversalManager` never performs Compound/Campaign context changes.

## Data Contracts

### Route

A `custodian.route_definition.v1` document owns a route ID, display name, campaign world context, tags, optional world ingress, nodes, directed edges, and profiles. `RouteRegistry` loads the sorted paths in `content/routes/routes.json`, rejects duplicate paths/IDs, and validates routes against `LevelRegistry`.

### Node

A node contains a unique `node_id` and registered `level_id`. Presentation, cache, and state policy remain authoritative in the referenced `LevelDefinition`. `@world_origin` is reserved and cannot be declared as a normal node.

### Edge

An edge contains globally unique `edge_id`, `from_node_id`, local `exit_id`, `to_node_id`, target spawn, direction, and transition style. Directions are `forward`, `back`, `lateral`, or `exfil`. A target of `@world_origin` requires `exfil`; a source of `@world_origin` is legal only as a profile entry edge.

### Profile

A profile names one entry edge and an explicit enabled-edge set. Exactly one enabled edge may resolve each `(from_node_id, exit_id)`. Every reachable production node must have a path to `@world_origin` unless `allow_no_exfil` is explicit.

### Session

`RouteSession` owns route/profile identity, the current node/level/instance, origin ingress/snapshot, persistent actor, parent, history, last edge, cached instances, node state, route state, and started state. Its serialization-safe snapshot excludes all `Node` references and contains only route/profile/current node/history/last edge/node state/route state.

## Reserved World Endpoint

`@world_origin` represents the captured campaign-world location and the ingress that opened the route. It is not a level ID and is never staged by `LevelLoader`.

Production ingress captures and isolates the origin before the entry edge activates. Exfil restores the exact origin branch, actor, camera, and UI snapshot transactionally, resets the ingress, releases all route instances, clears session state, and preserves runtime-persistent state.

## Transition Transaction

Phases are `IDLE`, `REQUESTED`, `VALIDATING`, `FREEZING_SOURCE`, `STAGING_TARGET`, `VALIDATING_TARGET`, `ACTIVATING_TARGET`, `DEACTIVATING_SOURCE`, `FINALIZING`, `COMPLETE`, `ROLLING_BACK`, and `FAILED`.

For node-to-node traversal:

1. Reject concurrency and validate route/profile/actor/current-node/exit/edge.
2. Capture actor and source activation state, lock the actor, capture route state, and call `prepare_route_deactivation`.
3. Stage or retrieve the target and validate its named spawn before relinquishing source authority.
4. Disable the source, activate the target, restore target state, complete activation, and bind legal `LevelExit2D` nodes.
5. Commit loader/session identity, apply the source cache policy, append history, unlock the actor, and emit success.

Failure enters rollback: release or re-hide the incomplete target, restore source visibility/process/camera, restore actor position/process, keep loader/session identity, reset source exit locks, emit a structured failure, and return to `IDLE`. Two route nodes may never process gameplay simultaneously.

## LevelLoader Boundary

`LevelLoader` provides low-level staging and activation APIs. Staging loads, instantiates, parents, configures, disables, and validates a requested spawn without moving the actor or changing active identity. Commit verifies expected active identity, disables the source, activates and places the actor, and only then changes active identity. It retains the direct entry/return bridge for legacy debug scenes and focused lifecycle tests.

## Level Contract

`AuthoredLevel2D` supplies route hooks:

- `activate_route_node(actor, spawn_id)`
- `capture_route_state()` / `restore_route_state(state)`
- `prepare_route_deactivation(context)`
- `complete_route_activation(context)`

Adapters may isolate legacy Sundered roots only when those roots cannot expose the contract directly. They must not form a parallel loading architecture.

`LevelExit2D` is a dumb `Area2D` request source. It owns only an `exit_id`, prompt, body-entry behavior, and duplicate-request lock. It contains no route, destination, scene, spawn, profile, cache, or loader authority.

## State Policies

- `reset_on_entry`: discard captured state and never restore it.
- `session`: capture on exit, restore during the same session, clear at route end.
- `persistent`: capture in `RouteStateStore`, restore across later sessions in the current runtime; no disk persistence is claimed.

## Cache Policies

- `destroy_on_exit`: release whenever left.
- `destroy_on_forward_exit`: release on `forward`/`exfil`, retain on `back`/`lateral` until route end.
- `keep_during_route`: retain hidden and disabled until route end.
- `snapshot_and_unload`: always capture and release, then restore into a new instance on revisit.

`RouteTraversalManager`, never the level, applies these policies.

## Sundered Keep V1

Distinct registered levels:

- `sundered_keep_vista_approach`
- `sundered_keep_return_causeway`
- `sundered_keep_front_gate`

Production:

```text
@world_origin → vista_approach → return_causeway → front_gate
front_gate → return_causeway → vista_approach → @world_origin
front_gate → @world_origin
```

`debug_direct_keep` resolves Vista `continue` directly to Front Gate. `causeway_only` enters Return Causeway and exfils for focused validation. Route data, not scene booleans, selects these edges.

## Single-Level Compatibility

Production ingress for a level-only destination calls `start_single_level_route`, which creates an in-memory `@world_origin → node → @world_origin` session using `return_world`. Direct `LevelLoader.enter_level()` and `AuthoredLevel2D.return_to_main()` remain compatibility bridges outside production registry ingress.

## Save Boundary

RouteSession and node/route state have serialization-safe dictionaries. Campaign save-file integration is deferred. `persistent` means current-runtime persistence through `RouteStateStore`, not disk persistence.

## Validation Requirements

- Registry schema/identity/reference/spawn/profile/connectivity failures.
- Forward/back traversal with single active authority and cache reuse.
- Profile-specific resolution of the same local exit.
- Rollback for load, spawn, activation, camera, and state failures.
- Exact world-origin restoration and route cleanup.
- All cache and state policies.
- Physics-driven `LevelExit2D` binding.
- Real Sundered production/debug graphs and Keep state restoration.
- Generator create/append transaction behavior and CI runner coverage.
- Static failure if active Sundered runtime regains direct transition authority.

## Non-Goals

- Disk/save-file serialization.
- Major-context `WorldTransitionManager` implementation.
- Editor route-graph UI.
- Production transition-screen polish.
- Conditional quest scripting beyond explicit profiles.
- Additional campaign migrations.

## V1 Validation Record

Completed 2026-07-21 with Godot 4.7. The project import, `tools/validation/run_route_pipeline_suite.sh`, the authored-level lifecycle matrix, Sundered ingress/approach/chain regressions, `architecture_ownership_smoke.py`, and the no-direct-transition-authority search all passed. The rollback smoke intentionally logs controlled target load, spawn, activation, camera, and state-preflight failures before reporting PASS.
