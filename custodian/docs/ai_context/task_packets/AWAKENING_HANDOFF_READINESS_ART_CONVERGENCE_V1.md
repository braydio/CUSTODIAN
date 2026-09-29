# AWAKENING HANDOFF READINESS + ART CONVERGENCE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-handoff-readiness-art-convergence-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `awakening-runtime, awakening-art-registration`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Paired review workstream: `review-awakening-handoff-readiness-art-convergence-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `5e50b04d4db1`
- Goal: Make the complete Awakening / The First Return scene a trustworthy production handoff source for the later Hub runtime by locking its current art registration and seam behavior to the Layout authority, closing objective overlap/registration defects found by visual evidence, exposing a clean completion/handoff signal without performing the Hub transition, and reconciling stale Awakening documentation with live runtime truth.
- Completion boundary: Validate and, only where evidence proves a defect, correct presentation registration/seams across Zones 01–10 while preserving authored gameplay geometry; formalize the South Reach completion API that the next world-lifecycle slice can consume; add focused structural/visual validation; reconcile the Awakening asset-consumption ledger and known art gaps; repair current documentation drift. Done means the current scene can be traversed from Crèche wake to South Reach with production art registered to the existing spatial authority, all mandatory joins have explicit evidence, completion requires the opening console plus P-9, and a later Hub transition can subscribe to one production-named completion seam without depending on debug/blockout wording.
- Current measured state: `awakening_layout.gd` is the single spatial authority over `Rect2(-1088,-7328,2176,7680)` and ten sections. Zones 01–09 each bind an Asset V2 underlay/foreground pair centered exactly on the corresponding Layout envelope center; every pair is the envelope plus 128 px in width and height, i.e. 64 px visual bleed per side. Zone 10 embeds the production five-module Road of Witnesses at world offset `(6,-6626)`; its South Reach civic-axis plate is 768×896 and meets the Approach at world y=-6144. The special 04→05 dogleg is already the corrected 1024×576 `full_plate_underlay` at `(352,-2464)`, with 32 px room-overlap feathering and the runtime's 128 px fade; the older 832×384 plate is rejected history. Gate pylon collision is already corrected from 160×320 to 240×496 at the existing centers. The central Gate body/aperture art still visually occludes part of the mandatory center route, and widening collision would close the required path. Current completion already requires both opening console acknowledgement and P-9 recovery, but the runtime still exposes the legacy `blockout_completed` naming/debug copy. First-five-zone and 04→05 visual QA exist; late-level seam coverage is less complete. Generic Crèche fixtures are 7/7 published and Ambulatory is 5/6, while later generic fixture, inlay, decal, and ambient-FX families remain registered but unpublished.
- Evidence: `custodian/game/world/awakening/awakening_layout.gd`; `custodian/scenes/awakening_first_return.tscn`; `custodian/game/world/awakening/awakening_first_return.gd`; `AWAKENING_04_05_CONNECTOR_VISUAL_CLOSEOUT_CLAUDE_SUMMARY.md`; `custodian/tools/assets/compose_awakening_connector_full_plate.py`; `reports/awakening_gate_collision/QA.md`; `reports/awakening_visual_walkthrough/QA.md`; `custodian/game/world/hub/road_of_witnesses_prototype.gd`; `custodian/tools/validation/road_of_witnesses_production_smoke.gd`; live Asset V2 family contracts/catalog; `custodian/content/metadata/assets/required_assets.registry.json`.
- Task-specific authority: `design/04_architecture/AWAKENING_FIRST_RETURN.md`; `design/04_architecture/AWAKENING_ASSET_MANIFEST.md`; `custodian/game/world/awakening/awakening_layout.gd`; live Asset Pipeline V2 family contracts; `design/05_levels/TWIN_SOLARIA.md` only for the next-stage boundary that Awakening must not bypass.
- Work surface: Primary runtime owner is `custodian/game/world/awakening/awakening_first_return.gd` plus its scene and Layout-backed tests. Presentation inputs are the existing Awakening zone plates, 04→05 connector, and Road prototype/module families. Expected docs/tests: Awakening focused smokes, validation manifest/recipes, CURRENT_STATE, FILE_INDEX, and only the minimum design notes needed to record live truth. Do not modify Twin Solaria runtime in this slice.
- Change: Add a machine-checkable art-registration/seam contract for the complete Awakening, renderer-backed seam evidence for the late-level joins, bounded presentation corrections only when those captures prove an objective seam/overlap error, and one production-named completion signal/API for South Reach that preserves legacy compatibility. Update the asset-consumption ledger to distinguish baked-only fixture states, specialized live props, unpublished registered families, and later-Hub assets. Correct stale docs that still describe the rejected connector dimensions or otherwise contradict live placement.
- Preserve: `awakening_layout.gd` remains the sole spatial authority; mandatory route/collision coordinates stay fixed unless a focused geometry failure proves the authority itself is wrong; all current zone underlay/foreground source pixels and Asset V2 identities remain authoritative; 04→05 stays 1024×576 at its current center with current 32 px feather and 128 px fade unless direct capture proves a regression; Gate pylon blockers stay 240×496; the central Gate route stays traversable; Road collision remains Road-owned; opening does not prewarm a Contract; no Field Terminal/Forum/Continuity Port is added to Awakening; no direct Awakening→Twin jump.
- Non-goals: No Hub runtime scene; no world-context transition implementation; no Twin Solaria gameplay changes; no procgen handoff; no Contract prewarm; no new generic fixture art; no speculative rescaling of valid plates; no extraction of a fake 04→05 foreground from flattened RGB; no Gate central-body collision enlargement; no redesign of the ten-section Layout; no procgen performance/pause work.
- Acceptance: All nine Awakening environment plate pairs prove exact center registration and `envelope.grow(64)` visual bounds; underlay/foreground within each family have identical canvas/registration; 04→05 proves the current 1024×576 exception and no stale 832×384 runtime binding; mandatory joins 01→02, 02→03, 03→04, 04→05, 05→06, 06→07, 07→08, and 08→10 plus optional 08↔09 have structural coverage and renderer evidence with no straight crop seam, doubled threshold, missing walkable floor, or opaque art unexpectedly hiding the Operator on the required path; the Road South Reach south boundary gap remains 192 px and aligns to the Approach handoff at world y=-6144; Gate pylon blockers remain aligned while the unresolved central sealed-body composition is recorded as art/design debt rather than “fixed” with collision; South Reach completion fails closed until both console acknowledgement and P-9 recovery, emits one production-named completion event once, and keeps any legacy `blockout_completed` listener working during migration; no Contract generation starts; docs and asset gap status match live runtime.
- Validation: Add focused registration/seam coverage first, preferably `custodian/tools/validation/awakening_art_registration_smoke.gd`, and register changed-file ownership. Keep `awakening_first_return_smoke.gd`, `awakening_first_return_geometry_smoke.gd`, `awakening_first_return_progression_smoke.gd`, `road_of_witnesses_production_smoke.gd`, and Asset V2 requirement/status checks green. Add or extend deterministic Moment Forge/direct-capture coverage to include late seams 05→06, 06→07, 07→08, 08→10 and optional 08↔09; retain existing 01–05 and connector evidence. Run focused checks before `run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: Actual Awakening→Hub transition; Hub runtime host; Ashen Forum/Field Terminal/Continuity Port; Hub→Twin Solaria route; missing registered Awakening P1 art; authored Gate central-passage composition; Twin forensic/route/acquisition slices; procgen pause/optimization.

## Registration Contract

Do not eyeball-resize the nine production room plates. Their current registration pattern is intentional:

| Zone | Layout envelope | Production canvas | Center | Required art rect |
|---|---:|---:|---:|---|
| 01 Crèche | 832×576 | 960×704 | (0,-32) | envelope + 64 px each side |
| 02 Ambulatory | 1024×832 | 1152×960 | (0,-864) | envelope + 64 px each side |
| 03 Attestation | 704×800 | 832×928 | (0,-1744) | envelope + 64 px each side |
| 04 Locker Reliquary | 576×576 | 704×704 | (704,-1984) | envelope + 64 px each side |
| 05 Dust Lung | 1088×1088 | 1216×1216 | (0,-3200) | envelope + 64 px each side |
| 06 Undergate | 1408×1088 | 1536×1216 | (0,-4320) | envelope + 64 px each side |
| 07 Gate of Dust | 1408×640 | 1536×768 | (0,-5184) | envelope + 64 px each side |
| 08 Custodian Approach | 896×736 | 1024×864 | (0,-5872) | envelope + 64 px each side |
| 09 Late Service | 576×640 | 704×768 | (-736,-5728) | envelope + 64 px each side |

The underlay and foreground for a zone must share exact canvas size, center, scale 1, and registration.

### 04→05 exception

Lock the already-reviewed exception:

```text
asset family: awakening_reliquary_dust_lung_connector
state: full_plate_underlay
runtime: content/levels/awakening/04_05_connector/
         awakening_reliquary_dust_lung_connector_full_plate_underlay_1024x576.png
center: (352,-2464)
canvas: 1024×576
room-overlap feather: 32 px
runtime zone fade: 128 px
foreground: optional/unbound because source master is flattened RGB
```

Do not reintroduce the rejected 832×384 `full_plate`.

### Approach → Road seam

The Road is not another Awakening room plate.

Current transform:

```text
Road world offset: (6,-6626)
Road local south entry: (-6,482)
Road world south entry: (0,-6144)
south gate gap: 192 px

south_reach_civic_axis
  local center: (0,34)
  world center: (6,-6592)
  canvas: 768×896
  world bounds: x[-378,390], y[-7040,-6144]

Custodian Approach production plate
  center: (0,-5872)
  canvas: 1024×864
  visual bounds: x[-512,512], y[-6304,-5440]
```

The two visual canvases therefore overlap from y=-6304 through y=-6144. Treat that 160 px as a seam-review region, not as permission to move either gameplay authority.

If capture proves visible duplication/hard-edge conflict, correct presentation at the seam with the smallest deterministic mask/alpha/overlap treatment. Do not move the Road offset, Approach envelope, Road collision, or south-entry anchor merely to hide a visual join.

## Gate of Dust

Preserve current validated pylon correction:

```text
west pylon art canvas: 256×512
east pylon art canvas: 256×512
current blocker: 240×496 each
central required route: remains open
```

The central `body_idle_sealed` 768×512 and `sealed_aperture` 512×512 presentation still visually covers part of that route.

This is an **authored composition/art-state issue**. Do not expand collision across it.

If a technically unambiguous alpha/z-order correction using existing source can make the required route readable without altering intended sealed-state composition, it may be proposed in review evidence, but do not invent a new Gate state in this packet. A new/passable state requires a later Asset V2 art decision.

## South Reach Handoff API

The current progression semantics are correct:

```text
console acknowledged
AND
P-9 recovered
AND
Operator reaches South Reach completion trigger
→ Awakening complete
```

Replace blockout-only naming as production authority without breaking compatibility.

Preferred contract:

```gdscript
signal awakening_completed(snapshot: Dictionary)
```

or a cleaner live-project equivalent.

Snapshot should be data only and include enough for the next world lifecycle owner to validate the handoff, e.g. completion flag, console acknowledgment, P-9 recovery, final zone identity, and Operator position. Do not include Node references.

If `blockout_completed` has live consumers/tests, retain it temporarily as a deprecated compatibility emission from the same one-shot authority. There must still be exactly one completion decision.

Do not change scenes in this slice.

## Asset Consumption Ledger

Reconcile against the live generated catalog and family contracts, not old prose.

Known current classes to preserve unless main has advanced when claimed:

- **specialized live:** Crèche recovery alcove; P-9 Designation Locker; Dust Lung lift; required Gate of Dust component composition.
- **BAKED_ONLY:** all seven published `awakening_creche_fixtures`; five published Ambulatory fixture states. Do not double-render them.
- **partial:** `awakening_ambulatory_fixtures`, missing required `service_basin_b`.
- **registered / currently unpublished:** Attestation fixtures, Reliquary fixtures, Dust Lung structures, Undergate machinery, Approach fixtures, Late Service fixtures, Late Service relay lamp, authority inlay, ruin decals, and required ambient FX.
- **later Hub, not Awakening-scene debt:** Field Terminal production prop/art, Field Terminal chamber dressing, Continuity Port, and first-Contract presentation.

Do not publish missing generic art as part of this packet.

If any state has landed on current main by execution time, update the ledger to reality rather than preserving this snapshot as dogma.

## Documentation Drift To Repair

At minimum:

1. `custodian/docs/ai_context/CURRENT_STATE.md` still describes the rejected 832×384 04→05 `full_plate`. Replace it with the current 1024×576 `full_plate_underlay`, 32 px overlap feather, and 128 px room/connector fade truth.
2. Remove/update any statement that the five Road modular presentation families still require native-size art. All five environment families are registered, ingested, and used by `RoadOfWitnessesPrototype`; the north processional continuation remains deferred.
3. Reconcile old “blockout complete” language with the production completion seam without implying the Hub transition exists.
4. Treat `custodian/docs/ai_context/task_packets/AWAKENING_SCENE_CORRECTNESS_HARDENING.md` as stale historical planning if it still asks for already-live A1–A5 work. Do not rerun completed hardening. Update/index/supersede it only according to current packet-lifecycle rules; do not silently leave two active authorities for the same work.

## Visual Evidence

Use renderer-backed evidence for the full spine, not source-image inspection alone.

Required late-seam captures:

```text
05→06 Dust Lung / Undergate
06→07 Undergate / Gate of Dust
07→08 Gate of Dust / Custodian Approach
08→10 Custodian Approach / Road South Reach
08↔09 Approach / Late Service optional branch
```

Objective pass criteria:

- no straight rectangular crop boundary;
- no doubled architectural threshold/stair/rail;
- no transparent hole exposing void where walkable floor exists;
- no opaque foreground masking the Operator where the required route says the Operator can stand;
- no change to locked collision/traversal authority merely to make the screenshot prettier.

If objective seam correction is needed, preserve editable/generation source under the existing family source-work path and route normalized replacements through the existing Asset Pipeline V2 family/inbox. Do not hand-edit runtime output.

## Relationship To Twin Solaria

This packet deliberately stops at South Reach handoff readiness.

The production route remains:

```text
Awakening
→ Road of Witnesses continuation / Hub runtime
→ Ashen Forum
→ Hub destinations, including Twin Solaria
→ Field Terminal / ordinary Continuity Port
→ first Contract world
```

Twin Solaria is `hub_twin_solaria` with `Spawn_CrownCauseway`. It is not a procgen `world_ingress` and must not be wired directly from Awakening.

The already-queued Twin forensic/route-review/acquisition packets remain separate and may proceed independently under their own lock/dependencies.

## Handoff

- Next action: after this packet lands and its review passes, implement the actual Awakening→Hub world-context transition and persistent Hub runtime host. That slice should depend on this workstream and on the App/Boot spine where required.
- Best starting files: Awakening controller/layout/scene and focused smokes; Road prototype; world lifecycle architecture; `hub_twin_solaria` level definition for the later destination contract.
- Blockers or open questions: Gate central sealed-body route readability remains a human/art composition decision if existing presentation cannot be corrected without changing the intended state. Missing P1 generic fixture/inlay/decal/ambient art is not a blocker for handoff readiness.
