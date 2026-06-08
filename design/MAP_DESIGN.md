Paste this full instructional into Codex:  
```
Task: Re-author the Sundered Keep V1 front-gate slice into the cheat-sheet layout while preserving all existing progress.

Context:
Sundered Keep V1 is already implemented. This is not a greenfield task. The current slice already has a data-driven level JSON, runtime loader, roof/interior occlusion work, elevation metadata, Return Mooring concepts, gate progression concepts, and some placeholder/production assets. However, the V1 layout is still too rough: the approach does not yet strongly match the intended wall silhouette, floorplan, elevation design, causeway bridge approach, lower shore traversal, Great Hall exterior/interior cutaway, and readable playable spaces shown in the attached cheat-sheet.

Use the attached image as the visual/layout target:
- Long elevated causeway approach from the south.
- Lower shore / under-bridge lanes at height 0.
- Return Mooring west of the approach.
- Locked Main Gate and Gatehouse Core.
- Broad courtyard combat arena.
- West Service Yard scavenging/optional encounter space.
- East Rampart high-ground flank route.
- Great Hall entrance.
- Great Hall roof-on exterior that cuts away to an authored interior floorplan when the Operator enters.

Repository authority:
- Follow `AGENTS.md` and `custodian/AGENTS.md`.
- Active runtime is Godot under `custodian/`.
- Do not treat `python-sim/` as active gameplay authority.
- Keep simulation/runtime changes deterministic.
- For gameplay/runtime changes, update active design docs and AI context docs.

Known active files likely involved:
- `custodian/game/world/sundered_keep/sundered_keep_map.gd`
- `custodian/game/world/sundered_keep/sundered_keep_tilemap_loader.gd`
- `custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json`
- `custodian/content/sundered_keep_manifest.game32.json`
- `custodian/content/runtime/sundered_keep/sundered_keep_game32_assets.gd`
- `custodian/tools/validation/sundered_keep_large_layout_smoke.gd`
- `design/02_features/world_expansion/THE_SUNDERED_KEEP_LEVEL_SET.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md`
- `REQUIRED_ASSETS.md`

Critical non-destructive requirement:
Do not erase existing Sundered Keep progress.

Before changing authored level data, create a preservation copy:

```bash
git checkout -b sundered-keep-cheatsheet-layout

cp custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json \
   custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.before_cheatsheet_relayout.json

git status --short
git diff -- custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json

```
Do not delete existing markers, objectives, encounters, asset references, occlusion regions, roof/cutaway metadata, gate/key/progression data, or Return Mooring metadata unless replacing them with an equivalent or better version.  
If a field’s purpose is unclear, preserve it and add a TODO note in the docs rather than deleting it.  
Core goal: Rework the V1 slice so the playable authored map actually follows the cheat-sheet layout. Preserve the working V1 systems, but improve the geometry, walls, floors, elevation metadata, blocker coverage, bridge approach, lower shore pathing, and Great Hall floorplan.  
Implementation requirement: Prefer a deterministic level-layout generator instead of hand-editing hundreds of JSON operations.  
Create:  
```
custodian/tools/levels/generate_sundered_keep_front_gate_layout.py

```
The generator should load the current sundered_keep_front_gate_large.json if it exists, preserve gameplay-critical metadata, then regenerate/migrate the geometry/layout portions.  
The script should emit:  
```
custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json

```
Also keep the preservation copy:  
```
custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.before_cheatsheet_relayout.json

```
The generator must print a summary of:  
* top-level JSON keys preserved  
* top-level JSON keys changed  
* top-level JSON keys added  
* top-level JSON keys removed, ideally none  
* unresolved asset IDs  
* placeholder assets created  
* blocker regions with visible wall/edge coverage  
* elevation regions generated  
Generator design: Define named zones/rects/polygons for:  
```
approach_bridge_h1
lower_shore_h0
west_underbridge_lane_h0
east_underbridge_lane_h0
return_mooring
gatehouse_core
main_gate_threshold
courtyard
west_service_yard
east_rampart
great_hall_exterior_roof
great_hall_interior
great_hall_right_turn_hallway

```
Preserve or intentionally migrate these anchor semantics unless there is a strong reason to move them:  
```
map_size_tiles: approximately 112x80 unless expansion is required
start_tile: around [56,76]
return_gate_tile: around [42,58]
return_mooring_origin_tile: around [39,56]
main_gate_tile: around [54,50]
great_hall_door_tile: around [55,30]
key_pickup_tile: around [73,56]
east_rampart marker: around [82,48]
courtyard marker: around [56,39]

```
Elevation requirements:  
* Height 1:  
    * causeway bridge deck  
    * gatehouse approach  
    * east rampart  
    * any elevated bridge/rampart walkable deck  
* Height 0:  
    * lower shoreline  
    * under-bridge side lanes  
    * Return Mooring lower platform  
    * key/winch lower-shore route if still present  
* Add visible stairs/ramps wherever height 0 transitions to height 1.  
* Every visual elevation transition must have matching ElevationMap metadata.  
* Every visual elevation transition must have matching ElevationMap metadata.  
* Every blocker/parapet/wall/void/cliff edge must have visible matching art or placeholder art.  
* Do not use invisible collision walls as a substitute for missing visual layout.  
Important runtime limitation: Current V1 does not support true same-coordinate stacked traversal. Do not fake that by allowing two actors on the same tile at different heights. Simulate the under-bridge route using adjacent/separate height-0 shore lanes plus underpass shadow/occlusion regions. Document this clearly as the V1-compatible approach.  
Causeway bridge requirements:  
* The southern approach should feel long, narrow, elevated, and imposing.  
* Use height 1 for the bridge deck.  
* Add parapet/edge blockers along the bridge.  
* Add ruined side alcoves, broken rail sections, visible ocean/cliff edge, and a few enemy encounter positions.  
* The bridge must lead clearly to the locked Main Gate / Gatehouse Core.  
* Add height-0 shoreline lanes on one or both sides so the player can visually and mechanically understand that the bridge is elevated above the shore path.  
* Where the lower path visually passes “under” the bridge, use shadow/underpass overlays and blocker/occlusion metadata, but do not rely on actual stacked traversal.  
Walls and floorplan requirements: Build the keep outline so it follows the cheat-sheet silhouette:  
* gatehouse front wall split by the locked gate  
* curtain walls enclosing the courtyard  
* west service yard boundary walls  
* broken outer cliff/void edges  
* east rampart high-ground wall/parapet  
* Great Hall exterior walls  
* Great Hall entrance threshold  
* interior Great Hall floorplan  
The authored geometry should read as a real fortress layout, not just a rectangular arena. Use irregular wall runs, broken masonry, collapsed edges, choke points, courtyards, ramps, and readable route hierarchy.  
Gameplay route requirements: There should be multiple readable routes:  
1. Main route:  
    * start bridge  
    * gatehouse  
    * locked Main Gate  
    * courtyard  
    * Great Hall  
2. Lower route:  
    * lower shore / under-bridge lane  
    * optional enemy avoidance or resource pickup path  
    * connection back to gate/courtyard via stairs/ramp  
3. East high-ground route:  
    * ramp/stairs up  
    * east rampart  
    * flanking view or sniper/construct threat  
    * optional approach toward courtyard/Great Hall  
4. West utility route:  
    * Return Mooring  
    * West Service Yard  
    * scavenging/resource opportunities  
    * optional encounters  
Great Hall exterior/interior cutaway: Preserve and improve the existing roof/interior cutaway behavior.  
Requirements:  
* Outside: Great Hall should render with roof/exterior walls visible.  
* Inside: roof/cutaway zone should fade or cut away when the Operator enters the authored interior region.  
* Use/extend interior_occlusion_regions or the current equivalent metadata.  
* Author a real interior floorplan:  
    * central hall  
    * columns  
    * broken tables/cover  
    * collapsed wall/sea-cut edge if appropriate  
    * objective/terminal/throne/archive position  
    * right-turn hallway leading to the marine ambush route  
* Ensure roof cutaway region matches actual interior walkable space.  
* Ensure walls remain visible/readable after roof fades.  
Placeholder asset policy: If a needed art asset does not currently exist, create a temporary placeholder instead of leaving logical gaps.  
Rules:  
* Do not overwrite production assets.  
* Placeholder filenames must start with PLACEHOLDER_.  
* Placeholders should be visually simple but semantically clear in-game.  
* Create matching .game32.json sidecars if the asset pipeline expects them.  
* Create matching .game32.json sidecars if the asset pipeline expects them.  
* Register placeholders where the runtime asset manifest expects them.  
Suggested placeholder paths:  
```
custodian/content/tiles/sundered_keep/placeholders/walls/
custodian/content/tiles/sundered_keep/placeholders/floors/
custodian/content/tiles/sundered_keep/placeholders/cliffs/
custodian/content/tiles/sundered_keep/placeholders/props/
custodian/content/tiles/sundered_keep/placeholders/overlays/

```
Placeholder categories to create if missing:  
* wall straight  
* wall corner  
* broken wall  
* parapet/bridge rail  
* cliff/void edge  
* ocean/shore edge  
* under-bridge shadow overlay  
* stairs/ramp up  
* stairs/ramp down  
* gate/locked threshold  
* roof overlay  
* interior floor  
* objective marker/terminal stand-in  
* resource node stand-in  
* cover prop stand-in  
Register any new placeholder assets in:  
```
custodian/content/sundered_keep_manifest.game32.json
custodian/content/runtime/sundered_keep/sundered_keep_game32_assets.gd

```
Asset rule: Do not leave an unresolved asset ID in the level JSON. Either use an existing registered asset or create/register a placeholder.  
Validation requirements: Update or add validation coverage in:  
```
custodian/tools/validation/sundered_keep_large_layout_smoke.gd

```
Validate:  
1. Level JSON loads.  
2. No referenced asset_id is unresolved.  
3. Main route from start to Main Gate exists.  
4. Return Mooring is reachable.  
5. Courtyard is reachable after expected gate/progression state.  
6. Great Hall entrance is reachable after expected progression.  
7. Lower shore / underpass lanes are height 0.  
8. Bridge/rampart routes are height 1.  
9. Every height transition has a visible stair/ramp/transition asset.  
10. Main Gate collision blocks before unlock/open state.  
11. Roof occluder/cutaway alpha changes when Operator enters Great Hall interior region.  
12. All blocker regions have visible matching wall/edge/prop coverage.  
13. Minimap floor/wall cells are populated.  
14. Placeholder assets referenced by the JSON are registered in the manifest/runtime asset map.  
15. No existing gameplay-critical top-level JSON metadata was silently dropped.  
Documentation updates: Update:  
```
design/02_features/world_expansion/THE_SUNDERED_KEEP_LEVEL_SET.md
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md
REQUIRED_ASSETS.md

```
Docs should say:  
* Sundered Keep V1 already existed before this task.  
* This task re-authored/improved the V1 front-gate slice to match the cheat-sheet layout.  
* The map now has clearer causeway, lower shore route, Return Mooring, Gatehouse Core, Courtyard, West Service Yard, East Rampart, Great Hall exterior, and Great Hall interior/cutaway regions.  
* True same-coordinate stacked bridge traversal is still not supported in V1.  
* The current bridge/underpass design uses adjacent height-0 lower lanes and visual underpass overlays.  
* List all remaining placeholder assets awaiting production art.  
* List any design compromises made for current runtime constraints.  
Expected deliverables:  
1. Preservation copy:  
    * custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.before_cheatsheet_relayout.json  
2. Migrated playable level:  
    * custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json  
3. Layout generator:  
    * custodian/tools/levels/generate_sundered_keep_front_gate_layout.py  
4. Any required placeholder PNGs and .game32.json sidecars.  
5. Any required placeholder PNGs and .game32.json sidecars.  
6. Any required placeholder PNGs and .game32.json sidecars.  
7. Manifest/runtime asset registration updates.  
8. Smoke validation updates.  
9. Documentation/current-state updates.  
10. Final summary explaining:  
    * what was preserved from V1  
    * what was re-authored  
    * what cheat-sheet areas are now represented  
    * which areas still use placeholder art  
    * which limitations remain  
Run/validation commands: Use the best available existing validation path for the project. At minimum, run the Sundered Keep smoke validation if available. Also run the generator from repo root and confirm the output is deterministic.  
Suggested commands:  
```
python custodian/tools/levels/generate_sundered_keep_front_gate_layout.py

git diff --stat
git diff -- custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json

# Run existing Godot validation/smoke path if supported by the repo.
```
```


```
```
# Prefer the existing command used by this project for .gd validation scripts.

```
Final Codex response should be concise and include:  
* files changed  
* validation performed  
* placeholder assets added  
* any unresolved risks/TODOs  
* confirmation that the original V1 JSON was preserved before relayout  
```
I’d frame it exactly this way: **“V1 exists and works, but it is a rough implementation pass. This task is a non-destructive relayout/migration to make V1 match the intended Sundered Keep cheat-sheet and level design.”**

```
