# Ash Bell Lift Ingress Presentation

Status: implemented V1.4; White Thread threadway gating integrated
Owner: world presentation / authored-level ingress
Runtime target: Godot 4 (`custodian/`)

The production interaction prompt is `DESCEND BELOW`. The current ingress
composition intentionally remains mixed-source: newer mountain/lamp art lives
under `custodian/content/sprites/world/ingress/ash_bell/`, while the entrance
shell, shaft, chains, and platform still use working legacy assets under
`custodian/assets/sprites/world/ingress/ash_bell/`. A future V2 migration may
consolidate those assets; this pass does not move them.

## Purpose

The Empty Bell entrance uses a surface-side lift descent and return ascent around the existing
fade into the Forlorn Ritualant Underground. The presentation belongs to the
generated `WorldIngressSite`; it is not part of
`forlorn_ritualant_underground.tscn`. The canonical Underground
`Spawn_DescentLanding` is `(0, 1670)` inside the migrated 3584x4096 cavern.

## Runtime ownership

- `ash_bell_lift_ingress_presentation.tscn` owns the surface cliff, irregular
  dark mouth, threshold, two chains, parked lift, restrained dust, lamp,
  authored foreground cave mask, traversal-only scrolling shaft, local cliff
  collision, and the current three-piece boarding enclosure.
- `ash_bell_lift_ingress_presentation.gd` owns the 1.05-second travel presentation,
  detached rider-puppet lifecycle, 176 px lift travel, 384 px shaft scroll,
  staged cave-lip occlusion, constant rider depth, and reusable reset.
- `operator_presentation_rig_2d.tscn` is a reusable visual-only snapshot rig.
  It clones the Operator's currently visible body/equipment presentation leaves
  without copying gameplay scripts, collision, input, health, or inventory.
- `ash_bell_lift_ingress_site.gd` specializes only the
  `forlorn_ritualant_underground` world ingress and listens for the canonical
  White Thread milestone.
- `ash_bell_threadway_causeway.gd` owns persistent special floor overlays,
  the restrained mainland-to-lift resolve sequence, and its temporary
  traversal blocker. `ProcGenTilemap` remains floor, collision, navigation,
  nonwalkable-surface, shadow, region, and minimap authority.
- `WorldIngressSite` captures the origin snapshot before awaiting an optional
  entry presentation. Route start and its existing fade happen afterward.
- `WorldIngressSpawner` selects the specialized site by exact route identity;
  every other route retains the generic ingress.
- The presentation exports an `832x608` world-space dressing-clearance
  footprint independently of its compact authored overlook floor. The procgen
  host purges existing foliage and ruin props, filters deferred foliage, and
  rejects later placement inside that footprint.

## Sequence contract

```text
surface trigger
  -> capture origin snapshot
  -> explicit Interact: DESCEND BELOW
  -> capture visible Operator presentation into detached rider puppet
  -> hide live Operator visual leaves without moving its CharacterBody2D
  -> attach puppet to RiderAnchor in a restrained lift-braced pose
  -> vibrate platform + burst dust
  -> reveal the masked shaft during the first 25 percent of travel
  -> move lift and puppet downward
  -> scroll shaft upward behind them
  -> platform back, rider, and front lip share world z=2
  -> scene-tree order keeps rails behind and the front lip over rider boots
  -> cave-mouth mask covers the lift and rider during deep descent
  -> free puppet and restore live Operator visual leaves
  -> start existing fade route
  -> load Underground at Spawn_DescentLanding
```

Return restoration uses the pre-descent snapshot, leaving the live Operator at
the captured surface position. A second detached puppet begins on the lowered
lift, rises through the staged cave-lip occlusion, and is freed before the live
visual leaves are restored. The live CharacterBody2D position, process mode,
and Z state are never changed by either presentation. Cancellation, failed
capture, teardown, and ordinary completion all restore the recorded visibility
state. The return ingress guard tracks the restored Operator's actual distance
and ignores synthetic `body_exited` signals caused by rebuilding Area2D
monitoring, so descent cannot immediately retrigger.

The specialized Ash Bell ingress is an explicit `interactable`; entering its
Area2D does not begin traversal. Its interaction position is `BoardingMarker`
at `(0, -26)`, its interaction distance is 56 px, and `interact()` accepts the
Operator only inside the local boarding rectangle `x=-42..42`, `y=-54..18`.
Generic world ingresses retain their existing body-entry behavior.

## Exterior and traversal modes

The parked world landmark is an exterior cliff composition, not an exposed
level-editor cutaway. While idle, `ShaftWindow` is hidden and transparent. The
player sees the cliff mass, an irregular `DarkMouth`, the parked platform and
short chain sections, the lamp, the entrance threshold, and foreground rock and
timber geometry. `EntranceThresholdMarker` shares the parked `LiftRoot` origin;
`InteractionApproachMarker` sits 72 px toward the exterior and is the
ingress-side threadway anchor. Before a White Thread Knot is acquired, its
authored overlook pocket is intentionally isolated from reachable world floor;
it is not a promise of continuous floor in the locked state.

## White Thread threadway contract

Any first acquisition of canonical resource `white_thread_knot`, including a
rare corpse-loot acquisition, marks run-level WorldEventMemory event
`ash_bell_threadway_unlocked`. The Knot is not consumed. This is an eligibility
milestone, not terrain mutation. An unlocked-but-unresolved road stays pending
until the Operator enters the production reveal audience around the approach.
The loaded site then asks `ProcGenTilemap` for one deterministic, approximately
three-cell-wide connector from the isolated approach toward the main
player-reachable floor.
The resolver rejects map bounds, constructed walls, required route cells, and
Sundered Keep protected cells.

The exact connector is first evaluated without mutation and used as the visual
resolution plan. Every full-width authored floor cell owns one seven-frame
resolve effect and becomes visible only when that effect finishes. Progress
bands advance from mainland toward the lift every `0.065` seconds with a
deterministic `0..0.10` second per-cell jitter, so neighboring effects overlap
as a directed wave rather than random scatter or a rigid scan. A temporary
local blocker prevents entry; only after every effect reports completion is
that same plan committed in one terrain transaction. Generated
floor/wall state, CHASM/OCEAN classification, runtime walkable boundary,
navigation, shadows, region metadata, and canonical minimap `floor` updates
are refreshed once for the batch. Ash Bell opts out of rendering generic base
Floor TileMap cells for both its isolated pocket and committed connector while
retaining all semantic terrain authority. The authored Threadway sprites are
the only visible traversal surface. Presentation overlays use six deterministic
dark-stone variants. A seven-frame 32 px thread/ash/remembered-stone effect
travels from mainland toward the lift at 11 FPS. Only after this witnessed
sequence finishes does the site mark `ash_bell_threadway_resolved`. Save/reload
preserves unlocked-only state as pending. A previously resolved road restores
terrain and overlays immediately without replay. Further Knots are no-ops.

The lift platform back, rider anchor, and front lip live in the shared passive
`ash_bell_lift_platform_assembly.tscn`. Both the surface presentation and the
authored lower landing instance that scene, so they are two termini of the same
physical lift rather than independent visual copies.

`BoardingBounds` is real `StaticBody2D` authority rather than an interaction
trigger. A broad rear stop and two front wings constrain the parked platform
while leaving a centered front opening.

After explicit interaction, the shaft window becomes visible and fades in over
the first 25 percent of descent. Its children are clipped by an irregular
`Polygon2D`, while the authored `EntranceMask` rises over the lift and detached
rider once they pass beneath the cave lip. Return ascent reverses this staging
and hides the shaft again when the lift reaches its parked position. Reset and
cancellation also restore the exterior-only state.

The current platform renders at approximately 173 px wide. Its idle and
vibration art are alpha-split from the original platform into back/deck/rail
and front-lip nodes. Idle world depth is rear mass `-8`, threshold `0`, entrance
structure and platform back/deck `1`, live Operator `2`, platform front lip `3`,
and lamp/dust FX `10`. Temporary solid Polygon2D cave plates remain grouped as
non-production-visible geometry; they are hidden in idle, travel, reset, and
cancellation states. The broad authored foreground occluder is hidden during
ordinary approach.
Travel promotes the platform back, detached rider, and front lip to absolute
`5 / 6 / 7`, activates the full cave mask at `20`, then restores the idle
depth and visibility contract on finish, reset, or cancellation.
Ordinary procgen foliage remains at `1`; it is removed beneath the structure,
while only the localized lower cave lip retains intentional actor occlusion.
The entire mountain mass must never be raised as one foreground
plate. The rider uses `RiderAnchor (0, -26)`. The burst dust
renders at approximately 96×58 px, 34 percent alpha, behind the platform. The
768×512 cliff remains landmark-scale while the functional entrance stays sized
around the 96 px Operator. The authored alpha occluder, rather than raw solid
polygons, provides the travel cave-lip cover.

The former always-exposed rectangular shaft cutaway is superseded and must not
be restored.

Threadway production art is separately curated under
`custodian/content/sprites/world/ingress/ash_bell/`: the live resolve strip is
`ash_bell_threadway_resolve_01__7f__32.png` (224×32), and six individual
32×32 persistent tiles live under `source/generated/`. The seven-frame strip
supersedes the earlier six-frame intake description; its final frame provides
the restrained residue settle.

## Art and import contract

Runtime art lives under
`custodian/assets/sprites/world/ingress/ash_bell/`; source generations are
preserved under `source/generated/`. Runtime PNGs use exact filename
dimensions, alpha outside isolated sprites, lossless compression, no mipmaps,
and nearest CanvasItem filtering. The shaft uses the canonical `256x1536`
`ritualant_underground__lift__shaft_scroll_01` strip with texture repeat disabled.
Descent still travels down-screen while sampling progressively positive texture Y;
ascent reverses both operations. Cavern route progression remains up-screen. The static
entrance shell contains no lift platform or active lamp.

## Connector generation contract

White Thread connector placement and runtime resolution share the same
deterministic dry-run planner and optional `threadway_organic` routing profile.
That profile derives a direct, one-sided dogleg, or shallow-S candidate from the
procgen seed and endpoint coordinates, tries the selected restrained shape
before the direct fallback, and limits intentional lateral drift to one through
three tiles. Width expansion follows each segment's local tangent and unions
incoming/outgoing perpendicular bands at bends before the complete widened
candidate is safety-checked. Generic connectors retain direct routing. A
generated isolated pocket is accepted only
when either the normal three-wide, 18-tile production budget or the shared
30-tile / 10-tile-lateral fallback can reach player-reachable mainland without
crossing bounds, constructed walls, required cells, or Sundered Keep
protection. Placement preflight and runtime resolution read both budgets from
the route contract and evaluate them in that order. The pocket remains isolated
before the first White Thread Knot and the Knot is never consumed.

A connector-invalid placement candidate does not omit Ash Bell. The spawner
advances through an explicit, deterministic candidate bound (the production
route uses `candidate_attempt_limit = lateral_search_tiles * 2 + 1`). Each
candidate is planned into virtual pocket semantics and evaluated against the
shared canonical/fallback dry-run connector before any production terrain, region, road,
foliage, collision-boundary, shadow, or navigation state is touched. Only the
selected candidate is committed once. Rejection and final placement events
include route/site identity and ingress ID.

The route is `required_for_contract`. Every procgen candidate dry-runs all
registered ingresses in production priority order, including their spacing,
and an otherwise valid map is rejected when the Ritualant ingress cannot be
placed. The normal 12-attempt contract loop therefore retries another map
instead of publishing a playable world without this encounter. Real placement
is checked again before contract readiness; a missing required ingress fails
the load and `_mark_contract_ready()` is not reached.

## Validation

```bash
godot --headless --path custodian --import --quit
godot --headless --path custodian \
  --script res://tools/validation/ash_bell_lift_ingress_presentation_smoke.gd
godot --headless --path custodian \
  --script res://tools/validation/ash_bell_threadway_causeway_smoke.gd
godot --headless --path custodian \
  --script res://tools/validation/ash_bell_sundered_keep_two_ingress_renderer_smoke.gd
godot --headless --path custodian \
  --script res://tools/validation/levels/forlorn_ritualant_underground_smoke.gd
godot --headless --path custodian \
  --script res://tools/validation/world_ingress_physics_reentry_smoke.gd
godot --headless --path custodian \
  --script res://tools/validation/authored_level_ingress_return_smoke.gd
godot --headless --path custodian \
  --script res://tools/validation/world_ingress_spawner_smoke.gd
godot --headless --path custodian \
  --script res://tools/validation/required_ritualant_ingress_contract_sweep.gd
```

The focused smokes verify asset dimensions/import settings, animation
contracts, exterior-only idle state, irregular shaft clipping, platform and
threshold alignment, boarding collision dimensions and front opening,
off-platform interaction rejection, constant rider depth, split rail/front-lip
ordering, restrained dust, traversal reveal and cave-lip ordering, actor-state
restoration, reset, snapshot ordering, explicit interaction, specialized versus
generic spawner behavior, per-cell resolve completion, full-width VFX coverage,
directed stagger, authored-only visible floor, deterministic shaped routing,
and connected width-three bends.
