# Sundered Keep Authored Ingress

- Status: implemented
- Authority: `design/05_levels/SUNDERED_KEEP_VISTA_APPROACH.md`
- Runtime: Godot 4.7.1

## Locked route

```text
procgen campaign world
→ playable blackout bridge
→ authored Approach and Outskirts
→ mist-occluded causeway-foot handoff
→ existing Front Gate EntrySpawn
```

The exterior is one scene. Transition arrival, First Vista, Return Parish,
Near Vista, ruined checkpoint, beach, and causeway foot are internal authored
subregions. The retired route-stage scenes are not production authority.

## Ownership

The Approach/Outskirts mapper previews the production scene and writes:

- `sundered_keep_approach_outskirts.json`
- `sundered_keep_approach_collision.json`
- `sundered_keep_approach_occlusion.json`

The existing `sundered_keep_mapper.tscn` remains the independent production
mapper for the Main Keep/Front Gate map.

`RouteTraversalManager` owns both transition styles. `WorldIngressSite`
captures origin state but defers branch isolation for `playable_blackout`.
`LevelLoader` continues to stage and activate levels while preserving the
persistent Operator and Camera2D.

The blackout bridge now owns a fixed directional ribbon plus an independent
Operator contact shadow. Arrival is fail-closed: control and blackout coverage
are released only after route-session identity, approach visual readiness,
camera runtime-map ownership, Operator follow, cleared presentation framing,
and suspended procgen objective presentation all validate. The approach's
position-driven vista controller releases the camera whenever its current
envelope has zero influence.

## Validation

Run `sundered_keep_approach_control_return_smoke.gd` and the five
`sundered_keep_{playable_blackout_transition,
approach_outskirts_mapper,approach_continuity,checkpoint_occlusion,
causeway_handoff}_smoke.gd` scripts plus the route pipeline suite.
