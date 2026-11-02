# World Placement

`WorldPlacementContext` is the shared read-only input seam for placement services.
`ContractWorldLoader` remains world lifecycle and placement orchestration authority;
P1 creates the context but does not extract resource, vehicle, relay, encounter,
or ingress policy.

## Context API

`game/world/placement/world_placement_context.gd` owns:

- a private handle to the accepted map instance, with no public map `Node` accessor;
- defensive level-data snapshots and typed spawn, compound-room, and ingress queries;
- narrow region, intensity, floor-walkability, and canonical tile-transform reads;
- the shared deterministic integer seed primitive used by existing resource score
  helpers, without moving their scoring policies or candidate selection;
- an explicit observability callback invoked only when a service calls `observe()`.

Construction copies the accepted level data and performs no map queries or
placement work. Returned arrays and dictionaries are detached copies. If the
accepted map has left the tree, query methods return stable empty/default values.
Services must receive the context built for the accepted contract currently being
placed; they must not use it as a writable world model or retain it across a
world-generation handoff.

## Ownership

- Belongs here: shared placement inputs and read-only query primitives; later,
  vehicle, ARRN relay, resource patch, encounter, and authored-ingress services.
- Does not belong here: candidate map scoring, terrain connectivity, actor AI, UI
  controls, placement order, spawning, or domain-specific presets.
- Current source of truth for lifecycle and placement order:
  `game/systems/core/systems/contract_world_loader.gd`.
- Future placement services must preserve this owner boundary and use the focused
  context smoke plus their domain-specific determinism tests.
