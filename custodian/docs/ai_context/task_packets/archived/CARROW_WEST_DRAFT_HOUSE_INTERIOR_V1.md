# CARROW WEST DRAFT HOUSE INTERIOR V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `carrow-west-draft-house-interior-v1`
- Authoring handoff: `auto`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `carrow-yard-route`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-carrow-west-draft-house-interior-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `second interior introduces registry and protected world/room transfer, requires fresh-context regression proof`
- Reviewed main: `06c8a7445b2da3bc206390e7b5a33340db031143`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Goal: Ship an accessible, distinctive 12×10 West Draft House utility interior using Carrow's existing registered floor/wall/equipment assets, while replacing the single-room state assumption with a safe named-interior selection seam.
- Completion boundary: West exterior 7×8 `west_draft_house` site has a reliable enter/leave pair to a 384×320px independently bounded room with real collision, working floor/walls/equipment/light, and two optional diegetic storage or inspection anchors. Machine House remains functionally/visually identical; the main Carrow route remains owned by the pre-migration connection. No new art necessary for this first playable blockout.
- Current measured state: `gothic_compound_map.gd` hardcodes `_machine_house_root`, `_machine_house_interior_rect`, `_machine_house_camera_bounds` and one `_operator_inside_machine_house` flag; `get_environment_region_at_global` and `get_camera_bounds` only recognize East. `GothicCompoundGenerator` exposes `structure_sites["west_draft_house"]` with existing 7×8 `utility_fan` exterior asset footprint. East Machine House is 14×10, 140 floor sprites, 13 artwork sprites, three diegetic caches, its own lighting and weather 0 indoors. Registered reuse stock: 64 floor 32×32, 49 wall/structure, 11 prop states. See design authority `design/05_levels/CARROW_YARD_STRUCTURES_EXPANSION_V1.md`.
- Evidence: `design/03_world/locations/CARROW_YARD.md`; `custodian/game/world/gothic_compound/{gothic_compound_map.gd,carrow_machine_house_door.gd}`; `custodian/game/world/procgen/gothic_compound/{gothic_compound_generator.gd,gothic_compound_asset_defs.gd}`; `custodian/tools/validation/{carrow_yard_interior_smoke.gd,carrow_backdrop_isolation_smoke.gd}`; `custodian/content/metadata/assets/families/carrow_machine_house_{floor,walls,props}.asset.json`; Carrow separate route migration packet.
- Task-specific authority: Generator `structure_sites` owns exterior placement; Carrow map owns *local room selection and temporary transfer* until the separate world route migration. Existing LightingZone2D/WorldEnvironmentDirector own lighting/weather. Asset V2 owns registered art. One active interior identity, not parallel per-room booleans.
- Work surface: `custodian/game/world/gothic_compound/gothic_compound_map.gd`; narrowly scoped Carrow room-definition/room-builder files under that directory; reuse existing `carrow_machine_house_door.gd` by adding a typed site/room ID only if needed (preserve current API via compatibility adapter); focused Carrow tests; validation manifest ownership for new files; only documentation tied to actual implementation. No global route/LevelRegistry edits.
- Change:
  1. Define small immutable named-room metadata for `east_machine_house` and `west_draft_house`: structure site ID, room-local symbol grid, dimensions, explicit door cells, safe interior spawn/return offsets, lighting profile, approved collisions, resource/inspectable anchors. Use same scene-map authority instead of duplicating entire East room building logic in a second 200-line function; avoid refactoring the successful Machine House beyond proven equivalence.
  2. Build W1 from the **exact 12×10 design grid** in `design/05_levels/CARROW_YARD_STRUCTURES_EXPANSION_V1.md` (12 columns each of 10 rows): southern 3-cell passable exit, north fan/exchanger banks, west filter and east controller/power zones, unobstructed technician center. Every floor cell receives 32×32 registered floor art; shell/equipment actual lower footprints drive collision, never alpha. Reuse existing `fan_bay_01`, `vent_pipe_bay_01`, `control_bay_01`, relevant Carrow grates/vents, pillars/doorframes. Do not create a dummy graybox wall sprite or hand-copy art into runtime.
  3. Bind exterior door to actual `west_draft_house` placed structure site; missing site means no orphan interior/door. Interior exit and exterior return use stable site-relative offsets with verified clear collision/portal interaction. Preserve main Carrow entry/return Transfer Frame states and all world-origin teleports.
  4. Introduce exactly one `active_interior_id` selection state and named room rect/camera regions. `get_camera_bounds` and `get_environment_region_at_global` distinguish East, West and the yard; exiting either restores yard camera and exterior rain while regional time/weather continue. Preserve East's existing `get_machine_house_debug_state()` layout/fields, door names, 140 cells, 13 art sprites and storage resources.
  5. Supply W1 functional dressing: practical vent and heat-exchange silhouette, shallow wall panels, low control cabinet, 1-2 bounded VaultStorage/inspectable interactions aligned with presented art. No new item IDs, crafting systems, heating damage or alarm network. Do not create an undesigned room-filling prop blanket.
  6. Preserve per-room consumed storage state on same-runtime revisits and prevent exterior/room double interaction (same Operator). Defend against premature room switching, repeated door calls, missing structure site, missing texture, room AABB overlap or camera-region bleed.
- Preserve: Canon `carrow_yard` civic identity and undecided current faction; original East room byte/geometry-equivalent behavior; 82×60 map default, 32px tile grid, generator roads/required walkability/structure sites, Transfer Frame first-manual/repeat-auto behavior; existing resource pools; procgen backdrop isolation; arbitrary main map seed behavior; planned separate `carrow-yard-route-authority-migration`.
- Non-goals: Operations House/Gatehouse runtime interiors, Alarm Gantry shared alarm gameplay, new source art or Asset V2 reingest, route service migration, quest/stealth rewrites, changing procgen enemy spawn logic, modifying live other agents' Carrow worktrees.
- Acceptance:
  - A1. W1 instantiates only when `west_draft_house` site exists; room 384×320, 120 floor tiles, ten 12-character rows, three-cell south exit and nonoverlapping camera/AABB.
  - A2. Operator enters, moves along safe central aisle, interacts with defined utility furnishings, and returns to valid exterior point; all directions and repeat-entry with same actor work.
  - A3. Yard rain visible outside, indoor precipitation 0 and outdoor rain restores on return. Indoor camera bound is W1, never East or yard; time/weather clocks not frozen.
  - A4. East Machine House 14×10, 140 tiles, 13 art sprites, 3 caches, existing door names/return positions/lighting and legacy debug state remain unchanged, plus no duplicated chest sprites/visual props.
  - A5. Invalid/missing site, blocked doorway, malformed grid, stale room ID and overlapping off-map allocations fail closed; no physical obstruction of the Carrow gate-to-Operations required route; no parallel world travel state.
  - A6. One visible source of truth for interaction/collision/presentation coordinates and registered reused art; no new .png/.asset family required; all focused and changed-file validation green.
- Validation: Extend existing `custodian/tools/validation/carrow_yard_interior_smoke.gd` or add a newly authored West Draft smoke fixture under `custodian/tools/validation/` for W1 grid/door/light/art/equipment, seed-specific exterior site binding, 2-room AABB/camera/weather switch, malformed fixture and East preservation; run `custodian/tools/validation/carrow_backdrop_isolation_smoke.gd` and connected-map generator validation, then changed-file routed validation and `git diff --check`.
- Task overrides: `none`
- Deferred: Ops room implementation after successful independent W1 review; author optional draft-specific art only if native-scale render proves existing assets insufficient.

## Next Handoff

- Next workstream: `review-carrow-west-draft-house-interior-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: Independent review of named-region identity, full West runtime room and East regression before Operations work becomes eligible.
- Blockers or open questions: `Runtime presentation screenshots require Godot; current Carrow route workstream must not own the same lock simultaneously.`

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `West Draft House is built from the generator-owned west_draft_house site as a 12x10 room with 120 registered floor sprites, eight registered art placements, two art-bound storage interactions, named entry/exit doors, independent camera/environment region, same-runtime storage persistence, and East Machine House parity. Focused and changed-file reports passed; see Validation Evidence and CARROW_WEST_DRAFT_HOUSE_INTERIOR_V1_CLAUDE_SUMMARY.md.`

## Execution Feedback
- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: `A negative fixture using a nonexistent art path emitted loader errors, then a guard expression exposed GDScript cast-precedence errors during the follow-up check; both were corrected before final validation.`
- Root cause / contributing factors: `The resource validation path initially attempted a load before checking path existence, and the typed cast needed explicit parentheses around ResourceLoader.load.`
- Prevention / pipeline improvement: `Check ResourceLoader.exists before typed loading and keep casts parenthesized in compound boolean expressions; the smoke now verifies missing art fails closed without logging errors.`
- Tooling / docs drift discovered: `Godot editor scans created unrelated validation .uid sidecars in the worktree; they were explicitly removed as disposable generated metadata.`
- Follow-up: `review-carrow-west-draft-house-interior-v1`
- What worked: `The focused smoke exercised real generated-site binding, two-room state, weather/camera transitions, storage persistence, East compatibility, and missing-site/art/overlap negative controls.`

## Validation Evidence
- Focused checks passed: `carrow_yard_interior`, `persistent_compound_layout`, and `carrow_backdrop_isolation_smoke.gd`.
- Final changed-file report: `/tmp/carrow-west-changed-final.json`; 4 selected, 4 passed, 0 failed, 0 timed out, 0 skipped, complete coverage.
- Packet index and review-pairing contract checks passed in the final changed-file sweep. `git diff --check` passed. The task-packet authoring preflight only accepts active packets and therefore cannot be rerun on the archived completion packet.

## Next Handoff
- Next workstream: `review-carrow-west-draft-house-interior-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: `After implementation lands and archives complete, invoke the paired fresh-context review runner for the named review workstream.`
- Blockers or open questions: `none`


## Independent Review

### Review Receipt: review-carrow-west-draft-house-interior-v1
- Schema: `custodian.paired_review.v1`
- Review workstream: `review-carrow-west-draft-house-interior-v1`
- Review target workstream: `carrow-west-draft-house-interior-v1`
- Status: `passed`
- Blocking defects: `0`
- Material gaps: `0`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Reviewed main: `856c5c8544fa28efc5181eaef426d955c167efd6`
- Reviewed implementation commit: `856c5c8544fa28efc5181eaef426d955c167efd6`
