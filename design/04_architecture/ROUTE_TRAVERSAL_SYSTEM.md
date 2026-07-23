# Route Traversal System

**Project:** CUSTODIAN
**Status:** complete-v1
**Runtime target:** Godot 4.x (`custodian/`)
**Last updated:** 2026-07-23

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

A profile names one entry edge and an explicit enabled-edge set. Exactly one enabled edge may resolve each `(from_node_id, exit_id)`. Every non-world node participating in an enabled edge must be reachable from the selected entry. Every reachable node must have a path to `@world_origin` unless `allow_no_exfil` is explicit; route nodes that do not participate in that profile are not required.

### Session

`RouteSession` owns route/profile identity, the current node/level/instance, origin ingress/snapshot, persistent actor, parent, history, last edge, cached instances, node state, route state, and started state. Its serialization-safe snapshot excludes all `Node` references and contains only route/profile/current node/history/last edge/node state/route state.

## Reserved World Endpoint

`@world_origin` represents the captured campaign-world location and the ingress that opened the route. It is not a level ID and is never staged by `LevelLoader`.

Production ingress captures and isolates the origin before the entry edge activates. Exfil restores the exact origin branch, actor, camera, and UI snapshot transactionally, resets the ingress, releases all route instances, clears session state, and preserves runtime-persistent state.

Origin isolation uses the explicit `world_origin_branch` group. `WorldIngressSite`
collects only grouped direct children of `/root/GameRoot/World`, plus temporary
compatibility lookups for `ProcGenRuntime` and `ConnectedMaps`; nested authored
content, route instances, and persistent services are never swept into the
snapshot. Captured branches remain hidden and processing-disabled across every
node-to-node transition and recover their exact captured visibility/process
states only during exfil. Operator, Camera2D, shared lighting, LevelLoader, and
RouteTraversalManager remain active for the route session.

## Transition Transaction

Phases are `IDLE`, `REQUESTED`, `VALIDATING`, `FREEZING_SOURCE`, `STAGING_TARGET`, `VALIDATING_TARGET`, `ACTIVATING_TARGET`, `DEACTIVATING_SOURCE`, `FINALIZING`, `COMPLETE`, `ROLLING_BACK`, and `FAILED`.

For node-to-node traversal:

1. Reject concurrency and validate route/profile/actor/current-node/exit/edge.
2. Capture actor and source activation state, lock the actor, capture route state, and call `prepare_route_deactivation`.
3. Stage or retrieve the target and validate its named spawn before relinquishing source authority.
4. Disable the source, activate the target, restore target state, complete activation, and bind legal `LevelExit2D` nodes.
5. Commit loader/session identity, apply the source cache policy, append history, unlock the actor, and emit success.

Failure enters rollback: synchronously clear loader authority when a post-commit target owns it, release or re-hide the incomplete target, restore source visibility/process/camera and loader identity when a source exists, restore actor position/process, reset source exit locks, emit a structured failure, and return to `IDLE`. Initial-entry failure therefore leaves no active loader identity and can be retried in the same frame. Two route nodes may never process gameplay simultaneously.

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

Production Sundered exits are authored `LevelExit2D` children in the Vista, Return Causeway, and Front Gate scenes. Their scripts may locate and position them from authored markers or tiles, but must not instantiate route exits.

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

Front Gate uses `snapshot_and_unload` plus session state. Its scalar state, siege-objective dictionaries, and Great Hall ambush dictionary restore symmetrically into a new instance without replaying rewards, pickups, encounter completion, gate events, dialogue, or enemy spawning. Only coherent timer activity is resumed; live `Node` references are never serialized.

## Generator Validation Boundary

Route-aware scaffold generation renders the staged level definition in memory, loads existing generated level definitions through a validation-only registry view, configures the complete proposed `RouteDefinition`, and runs full route validation before overwrite preflight or any filesystem write. Invalid schemas, references, spawns, directions, duplicate mappings/IDs, second entry edges, disconnected enabled topology, and no-exfil topology fail without changing registries, route definitions, or level directories. Dry-run performs the same validation.

## Single-Level Compatibility

Production ingress for a level-only destination calls `start_single_level_route`, which creates an in-memory `@world_origin → node → @world_origin` session using `return_world`. Direct `LevelLoader.enter_level()` and `AuthoredLevel2D.return_to_main()` remain compatibility bridges outside production registry ingress.

## Save Boundary

RouteSession and node/route state have serialization-safe dictionaries. Campaign save-file integration is deferred. `persistent` means current-runtime persistence through `RouteStateStore`, not disk persistence.

## Validation Requirements

- Registry schema/identity/reference/spawn/profile/connectivity failures.
- Forward/back traversal with single active authority and cache reuse.
- Profile-specific resolution of the same local exit.
- Rollback for load, spawn, activation, completion, camera, state, and exit-binding failures, including initial-entry failures after loader commit.
- Exact world-origin restoration and route cleanup.
- All cache and state policies.
- Physics-driven `LevelExit2D` binding.
- Real Sundered production/debug graphs, authored exit nodes, physics-driven production traversal, and symmetric Keep state restoration.
- Generator create/append transaction behavior, complete pre-write route validation, and CI runner coverage.
- Static failure if active Sundered runtime regains direct transition authority.

## Non-Goals

- Disk/save-file serialization.
- Major-context `WorldTransitionManager` implementation.
- Editor route-graph UI.
- Production transition-screen polish.
- Conditional quest scripting beyond explicit profiles.
- Additional campaign migrations.

## V1 Validation Record

Completed V1 on 2026-07-21 and hardened on 2026-07-23 with Godot 4.7. The hardening adds synchronous loader-authority cleanup after post-commit entry failure, symmetric nested Front Gate state, disconnected-profile rejection, full generator route validation before writes, and authored production Sundered exits. The route runner, authored-level lifecycle matrix, focused Sundered state/graph/exit tests, generator immutability tests, and no-direct-transition-authority search are the acceptance boundary. Controlled failure tests intentionally log their rejected transitions before reporting PASS.
