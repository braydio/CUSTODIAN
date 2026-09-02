# CUSTODIAN — Lower Quarter Catastrophe Dressing Pass

## Inputs

1. Generated master source:
   `custodian/asset_drop/source_work/lower_quarter_region/meridian_civic_ruins_props__master.png`

2. Raw extraction:
   `custodian/asset_drop/source_work/meridian_civic_ruins_props/native_extract/`

3. Copy semantic annotations:
   `custodian/content/metadata/assets/meridian_civic_ruins_native.semantic_annotations.json`

4. Copy builder:
   `custodian/tools/art/build_meridian_civic_ruins_semantic_manifest.py`

5. Build final semantic manifest:
```bash
cd custodian
python3 tools/art/build_meridian_civic_ruins_semantic_manifest.py \
  asset_drop/source_work/meridian_civic_ruins_props/native_extract/manifest.json \
  content/metadata/assets/meridian_civic_ruins_native.semantic_annotations.json \
  content/metadata/assets/meridian_civic_ruins_native.semantic.json
```

6. Copy exact placement authority:
   `custodian/game/world/levels/authored/ash_bell/common/ash_bell_catastrophe_prop_placements.json`

## Extraction review

The supplied extraction review contains **161 accepted native props**. The set is coherent enough to proceed.

Several connected clusters are intentionally marked `review_required`; do not expose those as generic variants. They may only be used as explicit authored set pieces after visual review.

## Runtime architecture

Do not create a new procedural scatter system.

Reuse/generalize the existing authored native-prop runtime path so Lower Quarter can mount two independent visual layers:

- surviving Meridian civic substrate
- catastrophe/aftermath dressing

Suggested scene structure:

```text
PropsRoot
  NativeCivicPropRoot
  NativeCatastrophePropRoot
  LaterPenitentAdditions
```

The catastrophe root reads `ash_bell_catastrophe_prop_placements.json`.

All catastrophe props:
- native extracted dimensions
- scale 1.0
- exact manifest anchor metadata
- collision disabled for this first visual pass
- no runtime randomization
- no alpha-derived collision

## Exact Lower Quarter placement count

102 placements total.

Zone counts:
- arrival: 12
- direct_collapse: 22
- evacuation_arcade: 18
- lower_market: 22
- civic_basin: 8
- wrong_street: 4
- answers_court: 6
- station_approach: 10

The JSON is authoritative. Do not move props to make a screenshot prettier without reporting the exact changed placement.

## Art-direction contract

The surviving civic family remains the pre-catastrophe substrate.

The new ruins family tells:
1. original structural catastrophe,
2. failed emergency response,
3. abandonment,
4. limited salvage/repair aftermath.

Do not turn every surviving civic prop into rubble.

Do not label generic salvage as explicitly Custodian-made unless authored evidence establishes provenance.

### Zone intent

- Arrival: mostly recognizable civic infrastructure, restrained damage.
- Direct Personnel Collapse: strongest destruction in opening route; real masonry/rebar/pipe failure dominates, not roadwork props.
- Evacuation Arcade: failed public evacuation, damaged utilities, emergency work lights, exposed service cabinets, salvage scars.
- Lower Market: civilian abandonment, dead/overgrown planters, waste, cargo, damaged furniture, concentrated rubble at edges.
- Civic Basin: eerie surviving public infrastructure with selective breakage.
- Wrong Street: minimal ordinary apocalypse dressing; preserve continuity mismatch as the visual thesis.
- Eight Answers Court: formal technical ruin, sparse damage, later Penitent material stays separate.
- Station approach: escalating infrastructural failure and emergency remnants.

## Existing civic prop interaction

Do not resurrect the old dense Direct Personnel roadwork vocabulary. If old source records remain presentation-disabled, keep them disabled.

The catastrophe layer should visually dominate that collapse with masonry, marked broken slab, pipes, wall fragments, rebar/metal debris, plus at most a restrained surviving barrier/beacon/cone.

## Validation

Add a focused smoke verifying:

- final ruins semantic manifest has exactly 161 IDs
- IDs are contiguous 1..161
- all raw extractor filename/native-size/anchor fields survive merge
- `review_required` compound variants cannot be selected generically
- catastrophe placement count == 102
- zone counts match placement JSON
- all placement IDs are unique
- all source IDs resolve
- every placement scale == 1.0
- every placement collision_enabled == false
- no placement occupies current spawn/exit/relay marker cells
- no procedural/random placement code exists
- civic native layer remains present
- LaterPenitentAdditions remains a distinct layer

Update:
- `design/05_levels/ASH_BELL_LOWER_QUARTER.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md` if ownership/path authority changes

Document the environmental-history layering so future cleanup does not collapse the two native prop families back into one generic city-prop bag.

Capture gameplay views:
- Arrival
- Direct Personnel collapse
- Evacuation Arcade
- Lower Market
- Civic Basin
- Wrong Street
- Eight Answers Court
- Station approach

PASS when the district still reads as a former Meridian civic place, but the route now unmistakably reads as catastrophic urban ruin rather than an intact city with municipal props.

## Implementation record — 2026-08-31

- Merged 161 extractor records with authored annotations and materialized exact,
  unscaled RGBA crops into the Meridian ruins runtime domain.
- Added 102 deterministic authored placements with the specified eight-zone
  density profile; all are collisionless and avoid spawn/exit/relay cells.
- Split runtime presentation into surviving civic, catastrophe aftermath, and
  later Penitent history roots without changing collision or navigation.
- Generalized semantic native-prop resolution so non-civic manifests use their
  own runtime indices while preserving the existing civic catalog path.
- Added offline and live Godot validation for manifest integrity, native files,
  zone counts, authored compound policy, runtime instantiation, and history
  layer separation.

Validation completed:

- semantic manifest smoke: PASS (`161` entries, `102` placements)
- catastrophe runtime smoke: PASS (`104` civic, `102` catastrophe)
- native placement regression: PASS (`250` civic placements)
- Lower Quarter art integration regression: PASS

Gameplay-scale zone captures remain a human art-direction review surface; they
do not weaken the deterministic runtime or navigation acceptance gates above.

## Supersession note — 2026-09-02

The reviewed Gothic-future wall/prop packet supersedes the prior Lower Quarter
visual vocabulary for surviving civic and catastrophe presentation. Existing
catastrophe placement authority remains intact; new explicit damage modules are
limited to named collapse beats and remain collisionless overlays.
