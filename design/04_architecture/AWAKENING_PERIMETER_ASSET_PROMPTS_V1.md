# Awakening Perimeter Support: Image Generation Prompts V1

**Status:** Production prompt contract only; 30 new images requested, **0 created or approved by this document**.
**Design authority:** [AWAKENING_PERIMETER_SUPPORT_V1.md](AWAKENING_PERIMETER_SUPPORT_V1.md).
**Intake:** [ASSET_PIPELINE_V2.md](ASSET_PIPELINE_V2.md).
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a

## Universal style and negative lock

Top-down 2D CUSTODIAN environment art in the live First Return's dark gothic-industrial / ruined civic language. Render a **flat overhead orthographic environment production asset** at native readable game scale, world north at image top, aligned to a 32-pixel architectural grid, with consistent overhead light response and no camera perspective/photography. Restrained near-black graphite, charcoal, aged masonry, oxidized bronze, pale ash and dim cold institutional accent light; meaningful scale cues but no miniature diorama boundary. Text-free except abstract illegible environmental markings. Refer visually to the *existing live zone plate* at review time; never redraw its floor or assume inaccessible geometry is a new gameplay path.

**Universal rejection:** characters, enemies, weapons, loot, UI/icons, legible writing, labels, logos, watermarks, checkerboard transparency, arbitrary doors/portals, walkable alternate corridors, strong glows, broad highlights brighter than the actual player route, isometric/3D perspective, generic fantasy dungeon decoration, photo textures, large black rectangles, hard matte edges, duplicated room plates, random scattered props with no structural logic. For a `structural_support` repeatable image, **all four outer edges tile seamlessly**; for `distant_structures` and `edge_transition`, actual transparency outside authored silhouettes must be genuine RGBA (not dark-color-key fakery).

### File/state contract

Each row below requests one independent static image, 1 frame, omni, 0 FPS, no animation. Save the unprocessed output as `source_work` first. After real inspection/normalization, promote the accepted copy to the exact `inbox` path; do not treat a filename as proof of accepted art. Runtime canvas targets: `structural_support` **512×512**, `distant_structures` **1024×512**, `edge_transition` **256×256**. For a generation service lacking these exact resolutions, keep aspect ratio, produce a larger source-work master, normalize by uniform resize/crop/pad when sound, otherwise regenerate. Do not stretch, rotate an accepted region plate or fake source RGBA.

## 01 — Crèche of Answerless Names: Dormant Recovery Stacks

**Family:** `awakening_creche_perimeter_support` · **Kind:** `backdrop` · **Area:** `levels/awakening/01_creche` (Road module ownership separately verified for 10).

### `structural_support` — 512×512, 1f
**Prompt:** "Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Dormant Recovery Stacks in CUSTODIAN's Awakening. Compose seamless reinforced recovery-wing outer-wall foundations and maintenance slab skirts, regular bays with sparse broken inserts. Materials: charcoal graphite ceramic, oxidized brass ID trims, matte medical-industrial panels, cold pinprick status lamps. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Crèche of Answerless Names production underlay. 1 static frame, native scale, overhead orthographic."
- Source: `custodian/asset_drop/source_work/awakening/awakening_creche_perimeter_support/structural_support_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_creche_perimeter_support/structural_support.png`

### `distant_structures` — 1024×512, 1f
**Prompt:** "Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Dormant Recovery Stacks. Depict receding banks of inert crèche alcoves interrupted by thick partition walls; different depths imply adjacent rooms but no doors. Architecture: serial recovery chambers, inactive body alcoves, separated vault cells and heavily insulated conduits. Materials: charcoal graphite ceramic, oxidized brass ID trims, matte medical-industrial panels, cold pinprick status lamps. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest one recovered Operator among hundreds of vacant/unresponsive units, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate."
- Source: `custodian/asset_drop/source_work/awakening/awakening_creche_perimeter_support/distant_structures_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_creche_perimeter_support/distant_structures.png`

### `edge_transition` — 256×256, 1f
**Prompt:** "Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Crèche of Answerless Names. Include broken ceramic threshold, partially obscured dormant unit housing and wall debris fading into shadow. Follow the same existing top-down CUSTODIAN palette of charcoal graphite ceramic, oxidized brass ID trims, matte medical-industrial panels, cold pinprick status lamps. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame."
- Source: `custodian/asset_drop/source_work/awakening/awakening_creche_perimeter_support/edge_transition_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_creche_perimeter_support/edge_transition.png`

## 02 — Recovery Ambulatory: Abandoned Processing Wards

**Family:** `awakening_ambulatory_perimeter_support` · **Kind:** `backdrop` · **Area:** `levels/awakening/02_ambulatory` (Road module ownership separately verified for 10).

### `structural_support` — 512×512, 1f
**Prompt:** "Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Abandoned Processing Wards in CUSTODIAN's Awakening. Compose seamless outer ambulatory floor ribs and medical partition bases; cold ceramic with intermittent diagnostic inlays. Materials: aged pale bone ceramic, blackened glass, desaturated teal indicator glass, brushed brass medical fixtures. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Recovery Ambulatory production underlay. 1 static frame, native scale, overhead orthographic."
- Source: `custodian/asset_drop/source_work/awakening/awakening_ambulatory_perimeter_support/structural_support_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_ambulatory_perimeter_support/structural_support.png`

### `distant_structures` — 1024×512, 1f
**Prompt:** "Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Abandoned Processing Wards. Depict glimpses of sealed inspection corridors and dark glass wards beyond the ring; the central shaft falls downward into unlit structure. Architecture: octagonal circulation's surrounding medical processing cells, observation partitions and descending central service shaft. Materials: aged pale bone ceramic, blackened glass, desaturated teal indicator glass, brushed brass medical fixtures. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest the Crèche was a processing facility, not a lone awakening chamber, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate."
- Source: `custodian/asset_drop/source_work/awakening/awakening_ambulatory_perimeter_support/distant_structures_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_ambulatory_perimeter_support/distant_structures.png`

### `edge_transition` — 256×256, 1f
**Prompt:** "Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Recovery Ambulatory. Include broken medical glass, sheared observation rail, hanging insulated cable and faded processing diagram fragments. Follow the same existing top-down CUSTODIAN palette of aged pale bone ceramic, blackened glass, desaturated teal indicator glass, brushed brass medical fixtures. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame."
- Source: `custodian/asset_drop/source_work/awakening/awakening_ambulatory_perimeter_support/edge_transition_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_ambulatory_perimeter_support/edge_transition.png`

## 03 — Attestation Gallery: Silent Registry

**Family:** `awakening_attestation_perimeter_support` · **Kind:** `backdrop` · **Area:** `levels/awakening/03_attestation` (Road module ownership separately verified for 10).

### `structural_support` — 512×512, 1f
**Prompt:** "Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Silent Registry in CUSTODIAN's Awakening. Compose seamless formal registry foundation with linear record-bay plinths and precise seal borders. Materials: near-black dressed stone, bronze registry rails, aged parchment composite plates, soot-faded ivory seals. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Attestation Gallery production underlay. 1 static frame, native scale, overhead orthographic."
- Source: `custodian/asset_drop/source_work/awakening/awakening_attestation_perimeter_support/structural_support_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_attestation_perimeter_support/structural_support.png`

### `distant_structures` — 1024×512, 1f
**Prompt:** "Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Silent Registry. Depict sealed side archive halls, high-ranked shelves holding fragmented identity records, fallen ceremonial columns. Architecture: side archives and long ranked record stacks behind rows of authority attestation steles. Materials: near-black dressed stone, bronze registry rails, aged parchment composite plates, soot-faded ivory seals. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest identity verification once demanded a sprawling bureaucracy, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate."
- Source: `custodian/asset_drop/source_work/awakening/awakening_attestation_perimeter_support/distant_structures_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_attestation_perimeter_support/distant_structures.png`

### `edge_transition` — 256×256, 1f
**Prompt:** "Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Attestation Gallery. Include stone fragments, shattered authority tablet fragments and dust-filled gaps between archival shelves. Follow the same existing top-down CUSTODIAN palette of near-black dressed stone, bronze registry rails, aged parchment composite plates, soot-faded ivory seals. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame."
- Source: `custodian/asset_drop/source_work/awakening/awakening_attestation_perimeter_support/edge_transition_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_attestation_perimeter_support/edge_transition.png`

## 04 — Locker Reliquary: Sealed Armament Annex

**Family:** `awakening_locker_reliquary_perimeter_support` · **Kind:** `backdrop` · **Area:** `levels/awakening/04_locker_reliquary` (Road module ownership separately verified for 10).

### `structural_support` — 512×512, 1f
**Prompt:** "Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Sealed Armament Annex in CUSTODIAN's Awakening. Compose seamless fortified equipment-annex outer footing and inset empty rack bases with worn security markings. Materials: smoked gunmetal, dark basalt flooring, brushed brass designation rails, faded amber lock indicators. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Locker Reliquary production underlay. 1 static frame, native scale, overhead orthographic."
- Source: `custodian/asset_drop/source_work/awakening/awakening_locker_reliquary_perimeter_support/structural_support_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_locker_reliquary_perimeter_support/structural_support.png`

### `distant_structures` — 1024×512, 1f
**Prompt:** "Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Sealed Armament Annex. Depict receding inaccessible locker banks and immense welded armory bulkheads; locked void bays, no open side passage. Architecture: inaccessible designation-keyed vault banks, reinforced armament racks, sealed security compartments. Materials: smoked gunmetal, dark basalt flooring, brushed brass designation rails, faded amber lock indicators. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest P-9 issuance is a narrow surviving right, not general arsenal access, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate."
- Source: `custodian/asset_drop/source_work/awakening/awakening_locker_reliquary_perimeter_support/distant_structures_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_locker_reliquary_perimeter_support/distant_structures.png`

### `edge_transition` — 256×256, 1f
**Prompt:** "Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Locker Reliquary. Include frayed conduits, armory debris, severed latch rails and cracked floor security threshold. Follow the same existing top-down CUSTODIAN palette of smoked gunmetal, dark basalt flooring, brushed brass designation rails, faded amber lock indicators. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame."
- Source: `custodian/asset_drop/source_work/awakening/awakening_locker_reliquary_perimeter_support/edge_transition_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_locker_reliquary_perimeter_support/edge_transition.png`

## 05 — Dust Lung Cistern: Subterranean Rupture

**Family:** `awakening_dust_lung_perimeter_support` · **Kind:** `backdrop` · **Area:** `levels/awakening/05_dust_lung` (Road module ownership separately verified for 10).

### `structural_support` — 512×512, 1f
**Prompt:** "Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Subterranean Rupture in CUSTODIAN's Awakening. Compose seamless rim-side cistern rockwork and reservoir foundation slabs with dry mineral crust; NO new walkable bridges. Materials: cold charcoal stone, rusted pipe iron, chalky deposits, ashen sediment, diluted pale-blue daylight. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Dust Lung Cistern production underlay. 1 static frame, native scale, overhead orthographic."
- Source: `custodian/asset_drop/source_work/awakening/awakening_dust_lung_perimeter_support/structural_support_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_dust_lung_perimeter_support/structural_support.png`

### `distant_structures` — 1024×512, 1f
**Prompt:** "Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Subterranean Rupture. Depict plunging layered walls of a colossal dry cistern with suspended inaccessible bridge wreckage and distant pipe banks. Architecture: vast ruptured reservoir, deep maintenance shafts, hanging pipe galleries, broken bridges, enormous dry void. Materials: cold charcoal stone, rusted pipe iron, chalky deposits, ashen sediment, diluted pale-blue daylight. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest first shocking reveal of institutional scale and collapse, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate."
- Source: `custodian/asset_drop/source_work/awakening/awakening_dust_lung_perimeter_support/distant_structures_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_dust_lung_perimeter_support/distant_structures.png`

### `edge_transition` — 256×256, 1f
**Prompt:** "Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Dust Lung Cistern. Include fractured lip masonry, torn pipe flange, falling rubble and haze-dissolved edges around an inaccessible chasm. Follow the same existing top-down CUSTODIAN palette of cold charcoal stone, rusted pipe iron, chalky deposits, ashen sediment, diluted pale-blue daylight. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame."
- Source: `custodian/asset_drop/source_work/awakening/awakening_dust_lung_perimeter_support/edge_transition_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_dust_lung_perimeter_support/edge_transition.png`

## 06 — Undergate Mechanism Hall: Buried Routeworks

**Family:** `awakening_undergate_perimeter_support` · **Kind:** `backdrop` · **Area:** `levels/awakening/06_undergate` (Road module ownership separately verified for 10).

### `structural_support` — 512×512, 1f
**Prompt:** "Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Buried Routeworks in CUSTODIAN's Awakening. Compose seamless industrial nave perimeter base with repeating bolted machine foundations and routing channels. Materials: oil-dark iron, lead-grey masonry, dull brass coils, worn calibration enamel, tiny dim indicator cyan. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Undergate Mechanism Hall production underlay. 1 static frame, native scale, overhead orthographic."
- Source: `custodian/asset_drop/source_work/awakening/awakening_undergate_perimeter_support/structural_support_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_undergate_perimeter_support/structural_support.png`

### `distant_structures` — 1024×512, 1f
**Prompt:** "Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Buried Routeworks. Depict immense sealed gear chambers, heavy lift housings, dark cable galleries, and partly collapsed west records vault. Architecture: immense blind pressure and route-indexing mechanisms, gear housings, cable galleries and west-side departure records. Materials: oil-dark iron, lead-grey masonry, dull brass coils, worn calibration enamel, tiny dim indicator cyan. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest the player's mechanisms are exposed fragments of a city-scale transport system, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate."
- Source: `custodian/asset_drop/source_work/awakening/awakening_undergate_perimeter_support/distant_structures_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_undergate_perimeter_support/distant_structures.png`

### `edge_transition` — 256×256, 1f
**Prompt:** "Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Undergate Mechanism Hall. Include severed bundled cables, cracked machine shroud, broken index dials and collapsed engineering stone. Follow the same existing top-down CUSTODIAN palette of oil-dark iron, lead-grey masonry, dull brass coils, worn calibration enamel, tiny dim indicator cyan. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame."
- Source: `custodian/asset_drop/source_work/awakening/awakening_undergate_perimeter_support/edge_transition_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_undergate_perimeter_support/edge_transition.png`

## 07 — Gate of Dust: Ruined Threshold District

**Family:** `awakening_gate_of_dust_perimeter_support` · **Kind:** `backdrop` · **Area:** `levels/awakening/07_gate_of_dust` (Road module ownership separately verified for 10).

### `structural_support` — 512×512, 1f
**Prompt:** "Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Ruined Threshold District in CUSTODIAN's Awakening. Compose seamless city-gate apron foundations with cracked civic paving and scattered shallow ash drifts. Materials: smoke-stained monumental limestone, dark civic basalt, tarnished bronze, ashen sand, rust-red dust. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Gate of Dust production underlay. 1 static frame, native scale, overhead orthographic."
- Source: `custodian/asset_drop/source_work/awakening/awakening_gate_of_dust_perimeter_support/structural_support_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_gate_of_dust_perimeter_support/structural_support.png`

### `distant_structures` — 1024×512, 1f
**Prompt:** "Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Ruined Threshold District. Depict fallen checkpoint terraces, collapsed buttress bridges, dislocated colossal statues and faint city silhouette through dust. Architecture: fortified threshold terraces, cracked defensive walls, collapsed causeway approaches and first hints of historical city. Materials: smoke-stained monumental limestone, dark civic basalt, tarnished bronze, ashen sand, rust-red dust. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest passage between institutional machinery and the scale of the old city, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate."
- Source: `custodian/asset_drop/source_work/awakening/awakening_gate_of_dust_perimeter_support/distant_structures_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_gate_of_dust_perimeter_support/distant_structures.png`

### `edge_transition` — 256×256, 1f
**Prompt:** "Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Gate of Dust. Include fractured gate-era parapet, broken relief sculpture and windswept ash at a deliberately impassable edge. Follow the same existing top-down CUSTODIAN palette of smoke-stained monumental limestone, dark civic basalt, tarnished bronze, ashen sand, rust-red dust. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame."
- Source: `custodian/asset_drop/source_work/awakening/awakening_gate_of_dust_perimeter_support/edge_transition_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_gate_of_dust_perimeter_support/edge_transition.png`

## 08 — Custodian Approach: Dead Processional Quarter

**Family:** `awakening_approach_perimeter_support` · **Kind:** `backdrop` · **Area:** `levels/awakening/08_approach` (Road module ownership separately verified for 10).

### `structural_support` — 512×512, 1f
**Prompt:** "Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Dead Processional Quarter in CUSTODIAN's Awakening. Compose seamless outer civic-processional pavement and weed-bound retaining-footing texture. Materials: pale ashen stone, dark slate processional paving, subdued bronze, dead grasses, muted rust patina. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Custodian Approach production underlay. 1 static frame, native scale, overhead orthographic."
- Source: `custodian/asset_drop/source_work/awakening/awakening_approach_perimeter_support/structural_support_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_approach_perimeter_support/structural_support.png`

### `distant_structures` — 1024×512, 1f
**Prompt:** "Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Dead Processional Quarter. Depict collapsed roadside chapel shells, ruined statuary, burial terraces and branching streets ending behind rubble. Architecture: burial terraces, ruined chapel shells, fractured civic gardens and abandoned processional side streets. Materials: pale ashen stone, dark slate processional paving, subdued bronze, dead grasses, muted rust patina. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest history, burial and civic memory gradually replace sterile machinery, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate."
- Source: `custodian/asset_drop/source_work/awakening/awakening_approach_perimeter_support/distant_structures_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_approach_perimeter_support/distant_structures.png`

### `edge_transition` — 256×256, 1f
**Prompt:** "Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Custodian Approach. Include uprooted stone garden edge, dead growth, fractured votive slabs and rubble obscuring any apparent side route. Follow the same existing top-down CUSTODIAN palette of pale ashen stone, dark slate processional paving, subdued bronze, dead grasses, muted rust patina. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame."
- Source: `custodian/asset_drop/source_work/awakening/awakening_approach_perimeter_support/edge_transition_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_approach_perimeter_support/edge_transition.png`

## 09 — Chapel of Late Service: Forgotten Devotional Precinct

**Family:** `awakening_late_service_perimeter_support` · **Kind:** `backdrop` · **Area:** `levels/awakening/09_late_service` (Road module ownership separately verified for 10).

### `structural_support` — 512×512, 1f
**Prompt:** "Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Forgotten Devotional Precinct in CUSTODIAN's Awakening. Compose seamless devotional precinct perimeter flagstone with worn memorial engraving and shallow root scars. Materials: smoked limestone, desaturated bronze votive details, weathered linen banners, chalk white thread. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Chapel of Late Service production underlay. 1 static frame, native scale, overhead orthographic."
- Source: `custodian/asset_drop/source_work/awakening/awakening_late_service_perimeter_support/structural_support_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_late_service_perimeter_support/structural_support.png`

### `distant_structures` — 1024×512, 1f
**Prompt:** "Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Forgotten Devotional Precinct. Depict collapsed side cloisters and side shrines lined with unlit lamps and faded banners; no open routes. Architecture: inaccessible cloisters, broken side shrines, memorial galleries and retired relay-lamp service conduits. Materials: smoked limestone, desaturated bronze votive details, weathered linen banners, chalk white thread. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest people ritualized pieces of the abandoned institution after official service ended, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate."
- Source: `custodian/asset_drop/source_work/awakening/awakening_late_service_perimeter_support/distant_structures_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_late_service_perimeter_support/distant_structures.png`

### `edge_transition` — 256×256, 1f
**Prompt:** "Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Chapel of Late Service. Include broken shrine threshold, torn ceremonial textile, dust-covered memorial fragments and white thread ties. Follow the same existing top-down CUSTODIAN palette of smoked limestone, desaturated bronze votive details, weathered linen banners, chalk white thread. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame."
- Source: `custodian/asset_drop/source_work/awakening/awakening_late_service_perimeter_support/edge_transition_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_late_service_perimeter_support/edge_transition.png`

## 10 — Road of Witnesses: South Reach: Fallen Civic Expanse

**Family:** `awakening_road_south_reach_perimeter_support` · **Kind:** `backdrop` · **Area:** `levels/awakening/10_road_south_reach` (Road module ownership separately verified for 10).

### `structural_support` — 512×512, 1f
**Prompt:** "Produce one 512×512 pixel **seamless-tileable top-down foundation/rim texture** for Fallen Civic Expanse in CUSTODIAN's Awakening. Compose seamless old civic road foundation with chipped processional paving, grout cracks and buried city edges. Materials: worn dark civic basalt, sun-bleached limestone, dulled brass wayfinding, low dusty rust and grey haze. Every boundary repeats pixel-consistently; no standalone room center, no framing borders, no lighting vignette, no scenery implying a playable doorway. This is just the off-route lower architectural field beneath the existing Road of Witnesses: South Reach production underlay. 1 static frame, native scale, overhead orthographic."
- Source: `custodian/asset_drop/source_work/awakening/awakening_road_south_reach_perimeter_support/structural_support_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_road_south_reach_perimeter_support/structural_support.png`

### `distant_structures` — 1024×512, 1f
**Prompt:** "Produce one 1024×512 pixel **top-down overhead ruined-architecture silhouette** for Fallen Civic Expanse. Depict distant ruined administrative arcades, plazas, colonnades, toppled civic arches and blocked branching streets. Architecture: collapsed colonnades, broken civic plazas, inaccessible avenues, distant administrative towers and city foundations. Materials: worn dark civic basalt, sun-bleached limestone, dulled brass wayfinding, low dusty rust and grey haze. Make each ruined structure visibly inaccessible by collapse, masonry or void; arrange high-level masses with believable foundations and subdued distant values. Transparent RGBA outside irregular nonplayable structures, never an opaque rectangular full-canvas matte. This should suggest the Road belongs to a much larger dead city; north barricade still closes the prologue, and sit fully behind established gameplay art. No new entrances. One static isolated silhouette plate."
- Source: `custodian/asset_drop/source_work/awakening/awakening_road_south_reach_perimeter_support/distant_structures_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_road_south_reach_perimeter_support/distant_structures.png`

### `edge_transition` — 256×256, 1f
**Prompt:** "Produce a single 256×256 **transparent RGBA overhead edge-transition decal** for the off-route margin of Road of Witnesses: South Reach. Include collapsed street-side arcade fragment, cracked paving gutter and dusty debris marking inaccessible civic continuation. Follow the same existing top-down CUSTODIAN palette of worn dark civic basalt, sun-bleached limestone, dulled brass wayfinding, low dusty rust and grey haze. Irregular organically damaged silhouette and clean partially transparent erosion; subtle dark-to-haze visual falloff must not be baked as a solid square. It is a noninteractive support seam, not a corridor, gate or piece of playable ground. One static frame."
- Source: `custodian/asset_drop/source_work/awakening/awakening_road_south_reach_perimeter_support/edge_transition_source.png`
- Inbox: `custodian/asset_drop/inbox/awakening_road_south_reach_perimeter_support/edge_transition.png`

## Handoff / review manifest requirements

For every asset: record family, state, actual generated resolution, expected inbox resolution, exact source and inbox path, 1f, image SHA-256, genuine alpha decision, seamless edge metric for `structural_support`, allowed aspect-preserving normalization, review status (SOURCE_READY_NEEDS_TUNE / RUNTIME_READY / REJECT_REGENERATE), and a 1:1 gameplay-scale crop against the existing live room. Packaging may use a `custodian.asset_handoff.v1` ZIP with checked manifest and source files; the handoff installer may only stage reviewed source/inbox assets, and it **does not ingest or bind** them.

**Generation order:** 05 Dust Lung → 07 Gate of Dust → 10 South Reach for style/scale calibration; next 01/02/03/04 interiors; next 06 Undergate; finish 08 Approach and 09 optional Chapel. Human review of style family precedes batch production. Do not mark a downstream implementation packet ready/auto merely because prompts were written.
