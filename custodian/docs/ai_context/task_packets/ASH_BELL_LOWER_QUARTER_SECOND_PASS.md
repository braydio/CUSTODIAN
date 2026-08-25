# Ash-Bell Lower Quarter Second Pass

- Status: `implemented — navigation/evidence foundation and production-art integration; encounter population deferred`
- Authority: `design/05_levels/ASH_BELL_LOWER_QUARTER.md`
- Scope: interruption-safe West Gate state, generic authored navigation, relay-driven dynamic blockers, semantic traversal beats, civic massing, physical Wrong Street/Court presentation, and ten player-readable records.

## Implemented

- West Gate persists `ClosurePhase`, normalized progress, and resumes the remaining deterministic 2.4-second closure after snapshot reconstruction.
- `AuthoredNavigationProvider2D` builds cardinal AStar paths from `AuthoredBlockoutGrid2D`; `NavigationSystem` delegates to an active provider and authored route activation restores the previous provider on deactivation.
- Lower Quarter shutter, interlock, and permanent collapse update authored path authority with collision state; West Gate slab updates its occupied navigation cells during travel.
- Ten semantic beat markers cover the intended route, and placeholder civic massing establishes arcade/market/court rhythm plus three physical Wrong Street bands and an incompatible imported footprint.
- Ten evidence interactions expose restrained primary records. West Gate and Station IX archive reads now mutate and restore their existing session keys.
- Nine Court positions are real inspectable scene nodes; Meridian equipment and later Penitent additions remain separately named.

## Validation

- `ash_bell_west_gate_interrupted_state_smoke.gd`: midpoint capture/reconstruct/resume/closed.
- `ash_bell_authored_navigation_smoke.gd`: nontrivial path, collapse exclusion, relay revision and gate opening.
- `ash_bell_lower_quarter_evidence_smoke.gd`: ten unique IDs and archive state restoration.
- Existing Lower Quarter layout, Station IX state, route registry, and route pipeline remain required.

Results on 2026-08-21:

- headless import: PASS (existing shutdown leak warnings only)
- all three new focused smokes: PASS
- existing Lower Quarter route/layout and Station IX state smokes: PASS
- changed-file workflow: all six selected tests PASS; aggregate coverage remains false only for unrelated concurrent Forlorn-Ritualant art files
- route pipeline: all tests through route exit binding PASS; existing unrelated `sundered_keep_world_vista_smoke.gd` camera-weight assertions remain red
- historical archive boundary and manifest JSON validation: PASS
- Moment Forge opening capture: not run; fixture remains deferred and no baseline was created

## Deliberately Deferred

- No production Penitent actor exists, so no generic actor is mislabeled as one.
- Authored encounter-wave population and persistence await an approved canonical actor identity.
- Historical note: production art and camera review were absent when the second
  pass closed. The later production integration ingested all ten V2 families,
  replaced blockout presentation, and added the reviewed real-camera fixture.
- The evidence overlay is intentionally narrow and transient; it is not a codex or automatic gameplay binding system.

## Production-Art Follow-up (2026-08-25)

`MeridianCivicArtPresenter` now uses explicit semantic coordinates from the four
32px atlases across all three districts. Station landmark, pedestals, relays,
West Gate slab, Station IX core/receiver, and transit ingress are integrated
without changing geometry, navigation, topology, or state.
The floor correction restricts generic civic paving to the approved clean/worn
cell lists, zones market and road materials explicitly, keeps markings and
ornaments as sparse authored overlays, deduplicates overlapping walkable-region
draws, and uses an alpha-cleaned V2 runtime atlas prepared reproducibly from
`asset_drop/source_work/meridian_civic_floor/`.
`traversal/ash_bell_lower_quarter_opening` completed a full six-keyframe
real-camera capture and manual review. Penitent combat population remains
deliberately deferred because no approved canonical actor was identified.
