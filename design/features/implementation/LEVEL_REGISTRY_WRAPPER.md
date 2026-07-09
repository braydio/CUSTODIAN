# Level Registry Wrapper

## Status

- Type: World/level ownership foundation
- Runtime target: `custodian/game/world/levels/`
- First wrapped level: Sundered Keep front-gate route
- Last updated: 2026-07-09

## Problem

The runtime has stable authored levels and routes, but discovery and entry remain feature-specific. In particular,
`ContractWorldLoader` manually constructs the Sundered Keep ingress and points it at a concrete approach scene.
This leaves world bootstrap code aware of destination implementation details.

## Goal

Introduce a registry-owned level identity layer:

```text
WorldMap / ContractWorldLoader
  -> WorldIngressSite(level_id)
  -> LevelLoader
  -> LevelRegistry
  -> LevelDefinition
  -> existing LevelRoute / level scene
```

The first slice wraps Sundered Keep without replacing its route, stages, final map, local map script, front-gate JSON,
or return behavior.

## Runtime Types

### LevelDefinition

Immutable runtime description loaded from JSON:

- stable `level_id`
- display name
- route scene path
- final target scene path
- world context
- tags
- optional authored data path
- ingress definition

It validates identity and referenced resources. It does not own live scene state.

### WorldIngressDefinition

Data describing discovery/entry presentation:

- stable ingress ID
- prompt
- target spawn ID
- interaction distance

It does not select coordinates or alter world topology.

### LevelRegistry

Loads `res://content/levels/levels.json`, then individual definition JSON files. It owns lookup, duplicate rejection,
and definition validation. The registry does not instantiate scenes.

### LevelLoader

Instantiates the registered route or scene for a level ID, binds existing main-map/return context, and calls the
existing `enter_from_main` contract. It owns active level/route instance identity, not route stage logic or
world-transition state.

## First Integration

`sundered_keep_front_gate` points to:

- route: `res://game/world/routes/sundered_keep/sundered_keep_approach_route.tscn`
- final target: `res://game/world/sundered_keep/sundered_keep_map.tscn`
- authored data: `res://content/levels/sundered_keep/sundered_keep_front_gate_large.json`

`ContractWorldLoader` still selects the procgen discovery coordinate in this slice. It ensures one shared
`LevelLoader`, then creates a `WorldIngressSite` configured with the stable level ID. The ingress delegates entry
to the loader and retains its prior direct approach-scene fields as a migration fallback.

## Non-Goals

- no rewrite of the Sundered Keep route or stages
- no replacement of `WorldTransitionManager`
- no generalized save/load schema
- no migration of Gothic Compound, Home, Ash-Bell, or Return Causeway yet
- no change to procgen discovery placement or connectivity
- no removal of legacy ingress fallback until migrated destinations are validated

## Acceptance

- registry loads and validates Sundered Keep from project data
- loader instantiates the existing route by level ID
- route registers its existing stages and retains its final target
- ingress delegates by level ID when a loader exists
- missing/invalid IDs fail without partially entering a level
- current route and procgen validation remain green

## Next Agent Slice

- Wrap Gothic Compound without changing its travel gate or authored map behavior.
- Then register Home, Ash-Bell, and Return Causeway only after each destination has a stable route/entry contract.
- Move discovery placement out of `ContractWorldLoader` only after multiple registered ingress definitions prove the
  shared placement API.
