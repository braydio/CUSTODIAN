# Ash-Bell Bridged Falls Implementation Roadmap

**Status:** active roadmap  
**Date:** 2026-10-07  
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c  
**Design authority:** `ASH_BELL_BRIDGED_FALLS_APPROACH.md`
**Asset manifest:** `ASH_BELL_BRIDGED_FALLS_ASSET_MANIFEST.md`  
**Reviewed main:** `435c422d6cb5`

## Program Goal

Implement the geographic chain:

`Ritualant -> generated Alpine Highlands -> generated Bridged Falls -> existing Lower Quarter route`

without duplicating world/route authority, without turning art into gameplay
authority, and without fixing the generated bridge route to one authored layout.

## Expected Slice Count

Eight design/implementation slices are tracked. **BF0 is this design-lock
landing and is complete when these authorities are committed to main.**
Seven implementation packets follow.

| Slice | Workstream | State at authoring | Dependency |
| --- | --- | --- | --- |
| BF0 | design lock / roadmap | landing now | none |
| BF1 | `bridged-falls-generated-region-lifecycle` | implementation + R0-01 correction complete; correction re-review active | none |
| BF2 | `ash-bell-highlands-generated-destination` | ready/auto, dependency-gated | BF1 correction re-review |
| BF3 | `ritualant-north-egress-and-chapel-vista` | draft | BF2 review |
| BF4 | `bridged-falls-procgen-topology` | draft | BF2 review |
| BF5 | `bridged-falls-bridge-grammar-asset-v2` | draft | BF4 review |
| BF6 | `bridged-falls-vista-waterfall-presentation` | draft | BF5 review |
| BF7 | `bridged-falls-lower-quarter-handoff` | draft | BF3 review + BF6 review |

Assumption used while drafting downstream packets: every listed predecessor
lands cleanly and satisfies its own acceptance contract. Later packets with
multiple architecture-sensitive dependencies are explicitly refresh-gated back
through the authoring chat before execution.

## BF1 — Generated Region Lifecycle

Create one reusable route-node seam that allows `RouteTraversalManager` and
`LevelLoader` to stage/activate/deactivate a generated procgen region with the
same persistent Operator/camera/rollback guarantees as an authored node.

Do not build Ash-Bell-specific generation here.

## BF2 — Ash-Bell Highlands Destination

Register the first concrete generated route destination, with explicit region
identity, deterministic seed policy, named route spawns, Alpine-derived local
biome/frame configuration, and an intent-graph terminal reserved for Bridged
Falls.

## BF3 — Ritualant North Egress + Chapel Vista

Fix the distant-chapel arrival integration and turn the post-resolution northern
seal/throat into the actual route exit to BF2 while preserving its pre-resolution
block.

## BF4 — Bridged Falls Procgen Topology

Extend the generated Highlands intent/topology plan with a required Bridged
Falls subregion. Generate a new multi-span bridge network per seed with a
guaranteed entry-to-Lower-Quarter terminal and protected reveal/commit beats.

## BF5 — Bridge Grammar + Asset Pipeline V2

Give BF4 production bridge presentation and environmental grammar while keeping
semantic floor/collision/navigation authoritative. Lock/publish the modular
Meridian civic bridge asset families needed by the generated topology.

## BF6 — Vista / Waterfall Presentation

Add the location-specific region-frame/underlay, world-positioned waterfall and
mist families, sunset review target, Lower Quarter basin and Station IX skyline,
plus deterministic capture fixtures for the three required compositions.

## BF7 — Lower Quarter Handoff

Connect the generated terminal to the existing Lower Quarter production route
without creating duplicate state authority. Keep the old direct campaign ingress
until the new approach is proven and decide its final disposition from live
evidence.

## Parallelism

After BF1:

- BF2 owns generated destination integration.
- Environment-art preparation for BF5/BF6 may proceed only against the locked
  design and Asset Pipeline V2 paths, but runtime publication waits for the
  geometry contracts those packets depend on.
- BF3 and BF4 may be implemented after BF2 and reviewed independently.
- BF7 remains the cutover gate.

## Visual Review Gates

### Gate A — First Basin Reveal

Must communicate alpine foreground -> colossal bridge/falls middle -> Lower
Quarter/Station IX far field without sacrificing top-down traversal readability.

### Gate B — Bridge Traverse

Must prove the generated route reads as large civic infrastructure rather than
small modular road pieces and remains playable across multiple seeds.

### Gate C — Lower Quarter Approach

Must demonstrate geographic continuity from highland/falls to the authored
Lower Quarter entrance composition.

Use `publish_review_artifacts.py` only after objective geometry/state checks,
with minimal contact sheets/keyframes and the recorded authoring chat.

## Deferred Beyond BF7

- final name replacement for “Bridged Falls” if the working title changes;
- disk/save-file persistence for generated-route sessions unless separately
  required by the existing save architecture;
- direct Station IX shortcut from the Highlands;
- day/night-specific alternate vista sets;
- Lower Quarter full production-art completion unrelated to the approach seam.
