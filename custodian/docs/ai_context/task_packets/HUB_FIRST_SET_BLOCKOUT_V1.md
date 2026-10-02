# HUB FIRST SET BLOCKOUT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `hub-first-set-blockout-v1`
- Status: `in_progress`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `hub-runtime, hub-layout`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual`
- Paired review workstream: `review-hub-first-set-blockout-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `04d36ff604da`
- Goal: Build the complete runtime-ready blockout for the first persistent Hub set immediately north of Awakening, from Road of Witnesses South Reach through the Ashen Forum to the Archive/Crown Transfer branch and the Muster Court/Continuity Port deployment wing, so the second half of the first playable has one authoritative, navigable spatial target before world-transition and campaign-deployment behavior are wired.
- Completion boundary: Implement one Hub-first-set spatial authority and one playable authored blockout scene using the exact coordinates locked in `design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md`; reuse the current five Road of Witnesses production module pairs as presentation without reauthoring their coordinates; make the new first-set layout the sole collision/navigation authority for this Hub scene; expose all named handoff/branch/deployment markers; provide a standalone Operator/camera playtest wrapper; prove complete walkable connectivity and minimum route width; generate a minimal human-review overview capture; repair the directly related Hub/Road documentation drift. Done means the player can freely walk the entire proposed first-set blockout from `Spawn_SouthReach` to Forum, Sepulcher loop, Archive Rise, Crown Transfer Court, Muster Court, and Continuity Port threshold, while no actual Awakening, Twin, Contract, or procgen transition fires.
- Current measured state: Awakening ends inside the translated Road prototype at world completion center `(0,-6464)`. Because Awakening translates the Road by `(6,-6626)`, that handoff equals Road-local `(-6,162)`. The live Road presentation contains five modular production plate pairs at exact local centers `(0,34)`, `(0,-862)`, `(-832,-862)`, `(-832,-1820)`, and `(832,-862)` with native canvases 768x896 / 896x896 / 768x896 / 896x896 / 896x896. Its current `BLOCKER_RECTS` cover only a central `1254x1254` legacy collision footprint even though the visual modules extend much farther, so that collision cannot become Hub first-set authority. `AuthoredBlockoutGrid2D` and `AuthoredNavigationProvider2D` already provide a reusable 32px authored blockout/navigation foundation. No production WorldTransitionManager exists yet; it remains design-only. No Hub first-set runtime scene or blockout packet currently exists.
- Evidence: `design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md`; `design/04_architecture/HUB_SPATIAL_LAYOUT.md`; `design/04_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md`; `design/04_architecture/WORLD_TRANSITION_SYSTEM.md`; `custodian/game/world/awakening/awakening_layout.gd`; `custodian/game/world/hub/road_of_witnesses_prototype.gd`; `custodian/game/world/levels/authored_blockout_grid_2d.gd`; `custodian/game/world/levels/authored_navigation_provider_2d.gd`.
- Task-specific authority: `design/04_architecture/HUB_FIRST_SET_BLOCKOUT.md` is the exact spatial/blockout authority. `HUB_SPATIAL_LAYOUT.md` owns district meaning/topology. `AWAKENING_FIRST_RETURN.md` and `awakening_layout.gd` own only the southern seam. `TWIN_SOLARIA.md` owns the later Crown Transfer destination contract. `WORLD_TRANSITION_SYSTEM.md` owns later context switching and must not be partially implemented here.
- Work surface: New primary runtime surface under `custodian/game/world/hub/first_set/` plus one standalone playtest scene under `custodian/scenes/`; reuse the Road module scene/controller as presentation input; focused validation under `custodian/tools/validation/`; minimal current-state/index/Hub spatial docs updates. Do not modify Awakening progression or Twin Solaria runtime.
- Change: Create `HubFirstSetLayout` as the single first-set geometry/marker authority; configure the existing authored blockout grid/navigation provider from it; build blockout collision from the grid boundary; reuse the five Road plate pairs at their exact local positions but suppress/avoid the Road prototype's competing collision authority; add visual blockout regions for North Processional, Ashen Forum, Sepulcher Gardens, Archive Rise, Crown Transfer Court, Muster Court, and Continuity Port Chamber; expose named spawn/POI markers; build a standalone real-Operator/camera playtest wrapper at `Spawn_SouthReach`; add focused connectivity/geometry validation.
- Preserve: Existing Awakening coordinates and South Reach geometry; existing five Road art family/runtime coordinates and pixels; Road behavior inside the Awakening scene; Twin Solaria `hub_twin_solaria` and `Spawn_CrownCauseway`; default boot flow; Contract sandbox/game.tscn behavior; Asset Pipeline V2 contents; 32px macro grid; no duplicate spatial authority.
- Non-goals: No `awakening_completed` scene transition; no WorldTransitionManager implementation; no Contract proposal/selection logic; no `WorldContractBootstrap.ensure_started()` call; no Continuity Port deployment; no Twin route traversal; no CampaignRegion creation; no Campaign return; no new production raster art or Asset V2 families; no NPC/enemy population; no final lighting/audio; no full Archive Heights/Prism Margin/Sunken Civic build.
- Acceptance: The blockout scene uses world bounds `Rect2(-2816,-5504,6016,6080)` and a 188x190 grid at 32px; `Spawn_SouthReach=(-6,162)`; all exact envelopes/connectors/markers from the design authority are represented without coordinate duplication outside the layout authority; the five existing Road module sprites retain exact local registration; Road legacy collision is absent/disabled in this Hub scene; first-set grid boundary collision is the sole Hub-blockout physical authority; a path exists from Spawn_SouthReach through Witness Plaza and North Processional to the Forum, from Forum through Sepulcher and back, from Forum to Archive Rise and Crown Transfer, and from Forum through Muster Court to CampaignExitThreshold; every mandatory route has >=128px/4 cells clear width and no isolated walkable islands; the playtest wrapper spawns a real Operator at Spawn_SouthReach with camera bounds derived from first-set bounds; Crown Transfer and Continuity Port are inert semantic markers only; no Contract bootstrap/generation occurs; no scene/world transition occurs; one human-approved full-map overview demonstrates readable district/branch topology.
- Validation: Add a focused implementation-created blockout smoke and register it in the validation manifest before closeout. It must prove bounds/grid, exact envelopes/connectors/markers, Road presentation registration, absence of competing Road collision, navigation connectivity, minimum route width, named-spawn validity, and inert transition markers. Keep the existing Road production smoke and Twin runtime smoke green. Run the focused blockout/navigation checks first, then `python3 custodian/tools/validation/run_validation.py --changed --json` (or the current equivalent from `VALIDATION_RECIPES.md`) and `git diff --check`.
- Task overrides: `none`
- Deferred: H2 Awakening->Hub world-context handoff; H3 Forum adjudication and single Contract prewarm; H4 Crown Transfer<->Twin Solaria; H5 Muster/Continuity Port deployment; H6 Campaign return; H7 end-to-end first-set closeout; all production Hub art.

## Exact Layout Contract

Do not reinterpret these dimensions. Read them from `HUB_FIRST_SET_BLOCKOUT.md` into `HubFirstSetLayout` and keep implementation consumers data-driven.

### World

```text
bounds: Rect2(-2816,-5504,6016,6080)
cell size: 32
grid origin: (-2816,-5504)
grid size: 188 x 190
Spawn_SouthReach: (-6,162)
```

### Existing Road presentation

```text
south_reach_civic_axis   center (0,34)      size 768x896
witness_plaza            center (0,-862)    size 896x896
collapsed_chapel_court   center (-832,-862) size 768x896
archive_ruin_west        center (-832,-1820) size 896x896
overgrown_reliquary_east center (832,-862)  size 896x896
```

Reuse the live presentation. Do not copy these five coordinates into a second runtime controller if the Road module API can expose them. If a small read-only accessor is required, add it to the Road presentation owner and cover it.

### North Processional

```text
Rect2(-512,-2400,1024,1152)
center (0,-1824)
grid Rect2i(72,97,32,36)
```

### Ashen Forum

```text
Rect2(-1280,-4032,2560,1792)
center (0,-3136)
grid Rect2i(48,46,80,56)

AdjudicationDais      (0,-3136)
ForumSouth            (0,-2464)
ForumNorth            (0,-3904)
WestGardenThreshold   (-1280,-3200)
EastMusterThreshold   (1280,-3104)
```

### Sepulcher Gardens

```text
Rect2(-2560,-3904,1152,1408)
center (-1984,-3200)
grid Rect2i(8,50,36,44)

connector Rect2(-1408,-3328,128,256)
connector grid Rect2i(44,68,4,8)
```

### Lower Archive Rise

```text
Rect2(-704,-5216,1408,1280)
center (0,-4576)
grid Rect2i(66,9,44,40)
```

### Crown Transfer Court

```text
Rect2(704,-5056,768,768)
center (1088,-4672)
grid Rect2i(110,14,24,24)

CrownTransfer  (1088,-4672)
Spawn_TwinReturn (864,-4672)
```

### Muster Court

```text
Rect2(1408,-3712,1088,1408)
center (1952,-3008)
grid Rect2i(132,56,34,44)

connector Rect2(1280,-3264,128,320)
connector grid Rect2i(128,70,4,10)

MusterEntry          (1472,-3008)
MusterCenter         (1952,-3008)
Spawn_CampaignReturn (2592,-3008)
```

### Continuity Port Chamber

```text
Rect2(2496,-3456,704,896)
center (2848,-3008)
grid Rect2i(166,64,22,28)

ContinuityPort        (2944,-3008)
CampaignExitThreshold (3136,-3008)
threshold volume Rect2(3104,-3072,96,128)
```

## Runtime Structure

Preferred structure:

```text
HubFirstSetMap (AuthoredLevel2D if that cleanly fits current authored-level contract;
                otherwise smallest existing Hub-compatible Node2D wrapper)
  BlockoutGrid            AuthoredBlockoutGrid2D
  NavigationProvider      AuthoredNavigationProvider2D
  CollisionRoot           StaticBody2D derived from grid boundary
  RoadPresentationRoot    existing Road module presentation, no competing collision
  DistrictPresentation
  Markers
  Interactables           empty/inert in H1
  TransitionMarkers       inert markers only
```

Use the current authored-level base if doing so does not invent a fake route graph. The map must expose named spawn lookup compatible with the later H2 lifecycle slice.

The standalone wrapper may own:

```text
Operator
PlayerController
Camera2D
HubFirstSetMap
```

The production map must not.

## Blockout Presentation

Use generated/simple vector blockout fills and semantic labels only.

Suggested categories:

```text
Road / civic axis        slate
Forum                    larger neutral civic field
Garden loop              distinct desaturated green-gray
Archive Rise             cool archive field
Crown Transfer           violet/cobalt diagnostic field
Muster Court             muted brass/industrial field
Continuity Port          cold blue-white threshold field
```

Do not create raster PNGs or Asset V2 families in H1.

Visual colors are diagnostic only and are not production palette authority.

## Road Collision Rule

This is important.

The current `RoadOfWitnessesPrototype.BLOCKER_RECTS` are a legacy/local collision treatment for the existing Road prototype and do not cover the full five-module visual footprint.

For Hub H1:

- retain Road art/module registration;
- do not build its `CollisionRoot` as physical authority inside the first-set map;
- first-set grid/boundary collision owns all walkability;
- preserve existing Road collision behavior in the Awakening scene and standalone old Road prototype.

Do not "fix" the old Road collision globally in this slice.

## Semantic Markers

All named markers must be actual runtime nodes or a stable marker dictionary resolvable through one map API.

H1 markers are inert. In particular:

- `AdjudicationDais` does not select a Contract;
- `CrownTransfer` does not enter Twin;
- `ContinuityPort` and `CampaignExitThreshold` do not generate/deploy;
- `Spawn_TwinReturn` and `Spawn_CampaignReturn` merely establish future handoff coordinates.

This prevents H1 from becoming a shadow lifecycle implementation.

## Navigation / Connectivity Proof

Programmatically prove:

```text
Spawn_SouthReach
 -> ForumSouth
 -> AdjudicationDais
 -> ForumNorth
 -> CrownTransfer

AdjudicationDais
 -> WestGardenThreshold
 -> Sepulcher interior sample
 -> AdjudicationDais

AdjudicationDais
 -> EastMusterThreshold
 -> MusterCenter
 -> ContinuityPort
 -> CampaignExitThreshold
```

Also prove no walkable cell lies in a disconnected component.

Minimum route width is 4 cells/128px. The main processional axis should remain substantially wider where the authored envelopes allow it.

## Human Blockout Review

Subjective topology/readability stays human-owned.

After all structural checks are green, generate exactly one deterministic full-map overview PNG from the blockout/playtest or mapper with:

- all district envelopes visible;
- named markers labeled;
- walkable blockout visible;
- Road module presentation visible where useful;
- Spawn_SouthReach, CrownTransfer, and CampaignExitThreshold called out.

The coding agent must not visually approve it.

Use the established review control:

1. write an ephemeral `/tmp/custodian_hub_first_set_review.sh`;
2. verify `kitty`, `xdg-open`, and capture path;
3. launch one foreground kitty and `xdg-open` the overview;
4. closing that kitty means human approval;
5. if rejected, the user interrupts/provides feedback and the workstream remains open.

One overview is enough for H1. Do not generate a screenshot gallery unless a structural defect requires a focused diagnostic image.

## Documentation Drift Repair

Update only current truth:

1. `HUB_SPATIAL_LAYOUT.md`:
   - Road presentation is five modular plate pairs, not one authored background image;
   - production Twin Solaria is now authored and registered, while the old backdrop remains development-only;
   - first playable Hub slice now begins at South Reach because Gate/Approach are Awakening;
   - link this blockout spec.
2. `custodian/docs/ai_context/CONTEXT.md`:
   - replace "Field Terminal as next destination" framing with Forum adjudication -> Muster Court -> ordinary Continuity Port;
   - do not claim H2-H6 transitions exist.
3. `CURRENT_STATE.md` and `FILE_INDEX.md`:
   - record H1 only after the runtime scene is live.

Do not rewrite broad campaign architecture in H1.

## Completion

Before setting complete:

- archive this packet;
- leave paired review active;
- write `HUB_FIRST_SET_BLOCKOUT_V1_CLAUDE_SUMMARY.md`;
- include the V2 completion receipt and execution feedback required by the task-packet template;
- record exact structural validation and human overview approval.

## Handoff

- Next action: H2 wires reviewed Awakening completion into this reviewed map at `Spawn_SouthReach` through the world-lifecycle authority.
- Best starting files: `HUB_FIRST_SET_BLOCKOUT.md`, Road prototype, generic authored blockout/navigation providers, current authored-level spawn APIs.
- Blockers or open questions: none for H1. The exact visual identity of Muster Court/Continuity Port is intentionally deferred until the reviewed blockout proves the topology.

## Execution Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: The dispatcher successfully claimed the packet but printed no result; recovery required reading its durable last-claim receipt. The fresh worktree also needed the normal Godot import before its global classes/resources would load. An initial changed-file sweep passed its tests but found one new scene uncovered; after adding that scene to the focused smoke's owner list, the closeout sweep passed with complete coverage. The first overview render also showed colliding labels at two marker clusters, so the same overview path was overwritten after spacing those labels.
- Root cause / contributing factors: Dispatcher stdout was lost after a successful claim; Godot caches are worktree-local; validation ownership must include each authored scene; marker labels need deterministic offsets where semantic points are close together.
- Prevention / pipeline improvement: Treat the dispatcher receipt under the Git common directory as authoritative when stdout is absent; keep authored-scene dependencies in the owning validation row; place labels for closely spaced markers using layout-owned presentation offsets.
- Tooling / docs drift discovered: `check_ai_context.py` reports 20 pre-existing packet/index findings outside this workstream, including missing historical feedback receipts, stale packet index entries, and an unrelated V2 Work surface omission.
- Follow-up: none
- What worked: Durable claim recovery, focused structural checks, and same-path overview replacement kept the assignment and evidence traceable.
