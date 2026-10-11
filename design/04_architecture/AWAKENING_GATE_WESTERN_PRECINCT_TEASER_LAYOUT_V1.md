# Awakening Gate Western Precinct: Two-View Teaser Spatial Concept V1

**Status:** PROPOSED geography and production-art direction for user review. No gameplay layout, cutscene, resource, new route, collision, or asset has been authorized or implemented.
**Date:** 2026-10-11
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
**Parent concepts:** [Forbidden Lower Region Concepts V1](AWAKENING_FORBIDDEN_LOWER_REGION_CONCEPTS_V1.md), [Occupied Recovery Hypothesis V1](AWAKENING_FORBIDDEN_LOWER_REGION_OCCUPIED_RECOVERY_HYPOTHESIS_V1.md), [Gate Stair/Wind/Art Review V1](AWAKENING_GATE_STAIRS_WIND_AND_ART_REVIEW_V1.md).
**Geometry source of truth:** `custodian/game/world/awakening/awakening_layout.gd`; production Gate plate at `res://content/levels/awakening/07_gate_of_dust/awakening_gate_plaza_underlay_1536x768.png`, center world `(0,-5184)` in `custodian/scenes/awakening_first_return.tscn`.

## The geography we have already selected (not yet laid out)

- The main building/prologue runs Crèche Zone01 → Undergate Zone06 → Gate of Dust Zone07 → Custodian Approach Zone08 → South Reach Zone10; locked north progression remains unchanged.
- Zone07's real 1536x768 art contains west and east side stair mouths off its principal plaza. **West** previews a significantly dangerous, sealed *underground return-later region*, potentially an old ossuary/recovery institution occupied/reappropriated for an unknown reason. **East** is simply an unnamed terrace viewing the dead historical city. Old names `Warden's Vigil`/`Scourwind Overlook` were user-rejected and must not be revived as in-world identity.
- Zone01 player wake at `(0,160)` is roughly 5,344 world units **south of the Gate plate center**; it should reveal an earlier part of the *same old recovery network*, NOT necessarily the same literal local shaft or its position in camera space.
- The hidden area is NOT currently represented by an authored Gate west connector or optional room. Both vistas are presentation concepts; do not make them claimable/interactive by writing this document.

## Proposed macro-geography: northern mouth of a buried north–south recovery complex

The historical Custodian recovery installation was built **through and below the western foundations of the civic threshold district**, extending deep beneath the surviving Crèche and institutional corridor to the south. Parts of the structure were originally ceremonial ossuary / recovery repositories; other spaces are vertically stacked medical/institutional processing. It was later reused for apparently orderly sorting/staging and other unverified work. The world does NOT establish a confirmed entity, the exact entry-crossing route, or a cause of the Severing.

A west-facing **exterior retaining terrace** branches off the existing Gate's west stair. This is the **approach**, not the entire underground facility. The terrace sits on masonry buttresses high above inaccessible collapsed civic-recovery workings. A short lateral walk leads to a monumental, old, **still physically sealed service threshold** cut into the outer city retaining wall / older recovery bedrock. At its side is a slit or broken observation balcony looking **down** into the abyss. The player can recognize niche cadence, one pale continuous band of lamps, and a distinctive twin-counterweight service lift rail seen near the early Crèche, but now in a vast context.

Conceptual diagram, not engine coordinates:

```text
                                   N  ↑
                                  CUSTODIAN APPROACH
                                         │
            WEST: old outer             GATE PLAZA           EAST
            retaining terrace           │                   unnamed open
            ┌───────────────────┐  ┌────┴────┐              city overlook
            │  ② broken parapet │  │         ├═══side stairs═══view
      cliff │  / look into      │  │         │
      face  │  recovery abyss   ├══╡  west   │
            │       ┌──────┐    │  │  stair  │
            │  ③    │seal  │    │  │         │
            └───┬───┴──────┴────┘  └────┬────┘
                ╎                          │
                ╎ nonplayable,             ↓ S
                ╎ deep recovered       UNDERGATE → ... → CRÈCHE
                ╎ infrastructure
                ▼
         buried ossuary / recovery network
                │  (extends beneath the older route)
                └────────────────────► ⓪ early Crèche side-window
```

**Arted spatial beats:**
1. **Gate west stair mouth:** original plate is untouched. Existing authored north route and east stair must remain visibly intact.
2. **Western exterior landing:** a concise masonry lip, ruined parapets and ruined threshold quarter exterior; this reads as **outside** the giant Gate building, not another interior Gothic hall.
3. **Western lookout:** a fall-off edge/fence/collapsed wall with a carefully framed downward view into a vertically enormous recovery-repository shaft. No bridge, shaft landing or implied early movement down.
4. **Sealed original recovery entrance:** at the back/side of that landing, a large mechanically braced historic slab embedded in retaining bedrock, rather than a freestanding circular portal or new magical gateway. Tiny sight slit lets the player see maintenance light and identical alcove massing. Apparent future access is presented but **no unlock mechanism has been chosen**.
5. **Deeper, unwalkable visible structure:** stacked recovery niches, cross-braces, inward-facing registration bays and twin-drum counterweight rail descending into cold shadow. A few lamps have modern/recent-looking maintenance; no proven occupant.
6. **Separate early near-spawn glimpse:** a small wall grille/occluded observation slot on the off-route side of Crèche Zone01 or immediately-adjacent Zone02. It shows related original recovery machinery and one matching lamp/rail/niche motif. No duplicate playable passage, and do not disturb the existing Crèche console or currently tracked screen-FX repair.
7. **Future substantial region:** not squeezed into a little one-room Gate annex. Could expand as dedicated later authored level or different scene ownership beneath the existing zones, with a physically justified western entry. Deferred until user approval and a full spatial/layout authority proposal.

## Real-space constraints from current runtime

- World coordinates: +X east, −X west, +Y south, −Y north. Zone07 envelope `Rect2(-704,-5504,1408,640)`; its western playable edge is **X=-704**.
- Gate underlay is centered at `(0,-5184)`, 1536x768, i.e. nominal visual bounds X `[-768,768]`, Y `[-5568,-4800]`. The scene may show additional props/foreground; review the actual ROI and alpha before using art pixels as geometry authority.
- Whole Awakening currently uses `WORLD_BOUNDS=Rect2(-1088,-7328,2176,7680)`, whose west bound is **X=-1088**. Thus only **384 world units** of current global width exist between the Gate envelope's western edge and the world's western boundary. An isolated modest off-route **vista terrace** may fit in that strip *subject to camera and geometry tests*. **The enormous undercity must not be assumed to fit there or silently extend the camera/map bounds.**
- Conceptual *nonauthoritative* artist/blockout target for the teaser terrace: a compact 256–320-pixel lateral outer-wall shelf from Gate's west stair toward a sealed lower-recovery wall, with a small-looking-down ROI. Its exact X/Y anchoring, stairs landing, 32px world alignment, spectator camera/occlusion and safety barriers remain to be measured on the registered Gate plate by a later spatial audit.
- The current `zone07_gate_of_dust` has NO west/east connectors or target bounds. No new `Layout.ZONES/FLOOR_RECTS/CONNECTORS/THRESHOLDS` is introduced by this proposal; do not fake a game corridor by painting more floor.
- The city overlook belongs to **east**, not west. The west scene should foreground an old ossuary access with only limited glimpses of the wider city; the historical city skyline should not steal the sealed region's reveal.
- Null Warrant's **West Gate** from Ash-Bell history is not demonstrated to be the same physical gate as Awakening's **Gate of Dust**. Do not equate them or put Ash-Bell closure proof on the Gate of Dust façade.

## Three visual signatures shared between Teaser 1 and Teaser 2

1. **Recovery niche unit cadence:** old, narrow, reinforced vertical bays with ceramic/stone and inward-set recovery hardware, **not rows of almost-identical funerary female statues**.
2. **Pale operational lamp band:** one well-ordered cool white/very desaturated cyan stripe, visually tiny at spawn and identifiable in the deep shaft from the Gate.
3. **Paired brass-black service drum + suspended rail:** specific recovery elevator/retention infrastructure. The Crèche glimpse shows only part of the wheel/guide; Gate vista shows the complete rail descending beyond the accessible city retaining wall.

Their spatial arrangement and silhouette grammar match; angle of view, camera scale, age of surfaces and exposed percentage differ. This implies a common **institutional system**, not an exact copy/paste of one rendered shot.

## Five generated split-view references reviewed (each 1672x941 RGB)

The five user-provided images are reference art, **not runtime sprites, not actual Godot 2D perspective, not asset-ready alpha**:

| Local submitted reference | What it contributes | What not to copy |
|---|---|---|
| `cathedral_of_the_mechanical_necropolis.png` | Strongest matched mechanical drum/niche motifs, grating on interior shot and massive sense of inaccessible barrier on exterior | Too symmetrical, polished, overtly crypt-statue imagery; front-on giant gate needs to become off-route west retaining-wall seal |
| `abyssal_archive_cathedral.png` | Strongest dramatic massive exterior door and open lower shaft in one coherent vista; descending slanted service machinery | Round door on high pedestal suggests a principal quest gate rather than an exterior side threshold; interior niche contents look like human effigies |
| `gothic_necropolis_the_lightwell_gate.png` | Strongest deep vertical bridge/elevator shaft and unbroken continuity between glimpses | Exterior is open through a ceremonial monumental arch; needs a truly **sealed** barrier; shaft is too brightly and evenly illuminated |
| `cathedral_of_the_endless_shaft.png` | Strongest overall depth scale and exterior mass as worn civic retaining architecture | Exterior opens into a huge doorway with daylight; wrong staging of an inaccessible lower ossuary unless enclosed/darkened |
| `ancient_ruin_complex_interior_to_exterior.png` | Strongest distinction between an ordinary recovery-room foreground and ruined exterior city-scale architecture | Broad bright exterior staircase reads as current progress destination, not a sealed dangerous below-city; no hard gate |

**Art direction proposal:** merge the **interior barred framing and paired drums of Mechanical Necropolis**, the **vast abyss & retained industrial rail of Abyssal Archive Cathedral**, and the **rock-cut ruined-city cliff integration of Ancient Ruin Complex**. Keep the outside threshold intentionally sealed; interior Crèche glimpse only ~10–20% of the structure whereas Gate reveals a much wider but still nonplayable 40–60% scene slice. These ratios express composition, not camera-metric requirements.

## Candidate future asset planning only; not generated or approved

All new imagery must use Asset Pipeline V2; draft `backdrop` families/states below are **provisional** and must be sized/validated to real camera coverage and source sizes before authoring manifests.

| Planned role | Example proposed source-work path | Proposed native intake | Frame count |
|---|---|---|---|
| Crèche off-route observation insert | `custodian/asset_drop/source_work/awakening/awakening_forbidden_recovery_teaser/creche_glimpse_source.png` | 512×512 RGBA | 1 static |
| Gate west exterior retaining terrace and sealed face | `custodian/asset_drop/source_work/awakening/awakening_forbidden_recovery_teaser/gate_west_threshold_source.png` | 1024×512 RGBA | 1 static |
| Shared deep niche/rail atmospheric shaft plate | `custodian/asset_drop/source_work/awakening/awakening_forbidden_recovery_teaser/deep_recovery_vista_source.png` | 1024×1024 RGBA | 1 static |
| Common niche/lamps/drums detail donor | `custodian/asset_drop/source_work/awakening/awakening_forbidden_recovery_teaser/recovery_signature_detail_source.png` | 512×512 RGBA | 1 static |

Proposed corresponding inbox: `custodian/asset_drop/inbox/awakening_forbidden_recovery_teaser/<state>.png`; proposed family metadata `custodian/content/metadata/assets/families/awakening_forbidden_recovery_teaser.asset.json`. No files physically exist yet, and image generators that cannot produce correct scale/true alpha must produce source-work candidates, not runtime-ready claims. The previous ten atlas-derived perimeter images remain rejected; independent full-frame scene-scale visual review required. Separate technical packets eventually cover scope, visual-only assembly, scene/camera registration and post-land independent review.

## Decision requested from user

Should Gate west **actually travel out onto the small elevated exterior terrace** before reaching the sealed recovery structure (this recommendation), or should the massive blocked descent begin directly at the stair head? In either case the region's *actual* scale is beneath the city; no gameplay gates/mechanics are yet chosen. Once agreed, measure current camera + collision + alpha at the registered stair mouth, write the exact blockout, only then author implementation packets.
