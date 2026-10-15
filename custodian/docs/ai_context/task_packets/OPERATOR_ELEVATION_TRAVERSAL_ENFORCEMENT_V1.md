# OPERATOR ELEVATION TRAVERSAL ENFORCEMENT V1
- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-elevation-traversal-enforcement-v1`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-traversal, elevation-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, architecture`
- Paired review workstream: `review-operator-elevation-traversal-enforcement-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `changes final Operator displacement gating against live terrain traversal semantics`
- Reviewed main: `350ee94e4b3b80010c0970903f3418966df3b851`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Visual review: `none`
- Goal: Make existing ElevationMap/ProcGen edge truth physically constrain Operator local motion without creating a second movement or collision authority.
- Completion boundary: Every Operator chassis displacement that is ordinary local movement is filtered through one focused elevation seam before the Operator-owned `move_and_slide()`. Authored levels with no provider preserve existing movement; explicit transition relocations remain separate; existing ElevationMap policy is reused exactly.
- Current measured state: Live ElevationMap owns walkable/blocked/ledge/ramp/stair/drop cardinal transitions with max step/drop 1. ProcGen exposes `can_actor_move_between_tiles()`. NavigationSystem already calls it for directed AStar edges. Operator `_advance_movement()` still owns final displacement but has no equivalent terrain-edge guard.
- Evidence: `game/world/elevation/elevation_map.gd`; `game/world/procgen/proc_gen_tilemap.gd::{can_actor_move_between_tiles,get_actor_elevation_cost}`; `game/systems/core/systems/navigation_system.gd::_can_traverse_edge`; Operator runtime architecture/tick spine; live audit at recorded main.
- Task-specific authority: ElevationMap is edge truth; ProcGenTilemap is provider/facade; `operator.gd` remains final displacement owner; OperatorInputRouter remains the only raw-input sampler.
- Work surface: new focused controller under `custodian/game/actors/operator/traversal/`; narrow Operator dependency/facade wiring; ProcGen public tile-conversion alias only if required; focused validation + validation-manifest ownership.
- Change:
  1. Add an Operator elevation traversal controller that accepts a provider and proposed movement, returns allowed movement, and never samples Input, calls `move_and_slide()`, mutates terrain, or owns collision.
  2. Resolve/cache the active provider at the Operator composition boundary. No per-physics-frame scene-tree scan. If no provider exists, return the proposed movement unchanged.
  3. Trace every cardinal grid edge crossed by the proposed physics-step displacement. Destination-only checking is forbidden because Dodge/attack drive can span intermediate edges. A deterministic supercover/axis implementation is acceptable.
  4. Reuse provider `can_actor_move_between_tiles()` for every edge. Do not copy ramp direction, stair, ledge, drop or max-height rules into Operator code.
  5. Apply the guard to normal locomotion, sprint/sneak, attack drive and Dodge/chassis movement immediately before the existing Operator-owned `move_and_slide()`. Explicit lift/portal/route relocations remain outside ordinary local-motion filtering.
  6. Preserve legal-axis sliding when the other axis is forbidden instead of converting every diagonal contact into a full stop.
  7. If ProcGen needs a public general world-to-runtime-tile method, expose a narrow alias over existing private conversion without changing minimap behavior.
  8. Update touched active docs to state precisely that NavigationSystem enemies are already elevation-aware while vehicles and direct/special enemy motion remain deferred.
- Preserve: fixed-step input/action arbitration, Dodge timing/iframes/Flow, melee drive values, CharacterBody2D collision, direct transition relocations, authored no-provider movement, NavigationSystem behavior and generation fingerprints.
- Non-goals: no new traversal type, climb animation, art, vehicle support, enemy-special rewrite, camera work or procgen topology.
- Acceptance:
  1. Same-height walk, legal ramp up/down, stair and legal one-way drop match ElevationMap exactly; blocked/ledge/wrong-ramp/illegal-height transitions are rejected.
  2. A multi-cell proposal fails at the first forbidden intermediate edge; diagonal motion can retain its legal axis.
  3. A real Operator fixture including Dodge/high-speed movement cannot tunnel across a synthetic forbidden elevation edge; removing the guard makes the focused test fail.
  4. An authored no-provider fixture preserves pre-change motion and emits no warning spam.
  5. Existing elevation/navigation plus directly affected Operator fixed-tick/Dodge/action tests remain green.
- Validation: Add/register focused Operator elevation traversal coverage. Run elevation-map and navigation-elevation smokes, directly affected Operator fixed-tick/Dodge/action tests, then `run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: A2 owns generated connector topology; production traversal art/presentation are A3/A4.

## Handoff
- Next workstream: `review-operator-elevation-traversal-enforcement-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Refresh reason: `none`
- Next action: `Implement from current main, land through normal lifecycle, then run fresh paired review.`
- Blockers or open questions: `none`
