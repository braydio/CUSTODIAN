# Enemy Navigation and Pursuit System

**Status:** Implemented foundation; crowd flow fields deferred  
**Runtime authority:** Godot 4.x

## Purpose

Enemy navigation must preserve responsive pursuit without allowing ambient or wave activation to concentrate actor initialization, perception, path searches, or separation scans into frame-time cliffs. Navigation remains derived from the existing structural world graph; enemies query that graph but never rebuild it.

## Runtime ownership

- `AmbientEnemySpawner` owns the global ambient actor-spawn queue. It instantiates at most one queued ambient combat actor per physics frame, assigns the local transform before `add_child()`, assigns a stable spawn ordinal, and prewarms grunt body/FX animation libraries during world startup. Marker processing is idempotent: deferred startup and `ContractWorldLoader` may both request processing, but marker metadata and generated-child detection permit exactly one camp and count suppressed duplicates.
- `NavigationSystem` owns the authoritative `AStar2D` graph, navigation revision, deterministic grid line-of-sight, and path smoothing.
- `EnemyNavigationBroker`, owned beneath `NavigationSystem`, admits at most two synchronous A* searches per physics frame and coalesces repeated pending requests from one actor.
- `EnemySpatialIndex`, also owned beneath `NavigationSystem`, rebuilds 64 px buckets at 10 Hz. Separation examines only neighboring buckets in stable spawn/path order.
- `EnemyPerceptionComponent` owns sensing cadence and physics LOS. Active actors sense at 10 Hz, nearby actors at approximately 3.3 Hz, background actors at 1 Hz, and dormant actors do not sense.
- `SimulationInterestManager` remains the tier classifier. Enemies apply full active simulation, 10 Hz nearby simulation, 2 Hz background simulation, and disabled dormant physics.
- `DevObservatory` receives spawn, queue, A*, LOS, separation, and tier metrics but never influences simulation.

## Pursuit contract

Enemies test deterministic navigation-grid visibility at a throttled cadence. A clear route steers directly. A blocked route is submitted to the broker only when the current path is empty, the navigation revision changes, the target moves at least two cells, or stuck recovery invalidates the route.

Broker results use greedy farthest-visible waypoint smoothing. Grid visibility consults authoritative walkable cells; smoothing requests one-cell clearance so shortcuts cannot cut blocked corners. Physics raycasts remain perception authority and are not used for waypoint smoothing.

Stable spawn ordinals phase initial path and perception work. `get_instance_id()` is not a gameplay seed.

## Observability

The focused smoke reports:

- animation prewarm microseconds;
- ambient spawn count, last and maximum spawn microseconds, and queue depth;
- A* query count, total, average, maximum, and queue depth;
- LOS query count and total microseconds;
- separation candidate checks;
- interest-tier populations through the existing interest-manager gauges.

Run:

```bash
godot --headless --path custodian \
  --script res://tools/validation/ambient_enemy_navigation_perf_smoke.gd
```

For threshold-free real-actor scaling evidence, run
`ambient_enemy_full_actor_perf_bench.gd`. It uses the production grunt scene at
0/1/2/4/8 live actors and writes JSON under `user://performance/`; it is a
comparison fixture, not a hardware-independent pass/fail gate.

## Deferred crowd scale

Engagement slots, simultaneous-melee authorization, shared objective flow fields, and navigation-revision path caches remain the next scale phase for large assaults. They must not replace individual paths for stuck recovery, investigation points, or unusual destinations.
