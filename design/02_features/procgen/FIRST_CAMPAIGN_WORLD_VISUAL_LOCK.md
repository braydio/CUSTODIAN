# First Campaign World Visual Lock

**Status:** locked  
**Date:** 2026-10-02  
**Scope:** current generated campaign world / first campaign world visual identity  
**Visual source:** user-approved 2026-10-02 world reference image  
**Archive Resolve:** governed separately by `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`; this document does not redefine it.

## Authority

This document is the primary visual authority for what the current procgen campaign world looks and feels like once resolved.

Where older procgen/world art notes conflict with this document, this document wins for the first campaign world unless a location-specific authored-level document explicitly declares a deliberate exception.

This lock governs:

- macro terrain identity;
- terrain palette and ecological presentation;
- roads, hardstand, terraces, retaining infrastructure and field installations;
- Custodian structure integration;
- Custodian vehicle presentation in this world;
- normal-play field-HUD shell;
- marker, beacon and world-tag visual grammar.

It does **not** change topology, biome simulation, weather simulation, gameplay semantics, Archive Resolve behavior, minimap mechanics, compass mechanics, or subsystem ownership.

The literal names/text visible in the reference image are not lore canon. In particular, the reference's displayed location labels are style reference only and do not rename the campaign world.

## Core World Read

The first campaign world is a **cold alpine frontier under organized ruined authority**.

At gameplay scale the player should read:

> exposed rocky highland, conifer wilderness, light snow/frost, severe elevation, broken but engineered routes, and fortified Custodian logistics infrastructure occupying terraces cut into the landscape.

The world should feel already old, physically difficult, strategically important and actively maintained in pockets.

The dominant visual tension is:

**wild vertical terrain × disciplined hard infrastructure**

not:

**generic wilderness × random sci-fi props**.

## Terrain Identity

### Macro geography

Prefer:

- rocky uplands;
- cliffs and escarpments;
- ledges, terraces, ravines and hard elevation breaks;
- exposed stone shelves;
- narrow traversable highland corridors;
- hardstand plateaus and engineered retaining edges;
- conifer-lined approaches;
- dark depth below the playable plane;
- infrastructure fitted into geology rather than placed on a flat field.

Avoid making broad regions read primarily as:

- flat green meadow;
- lush fantasy woodland;
- tropical forest;
- warm desert;
- colorful biome showcase;
- clean sci-fi platform field.

### Ground palette

The resolved ground family should stay inside a restrained cold-earth range:

- charcoal and graphite stone;
- cold gray rock;
- desaturated brown/olive soil;
- muted moss and dead grass;
- off-white patchy snow and frost;
- dirty melt edges;
- weathered concrete / stone-metal hardstand;
- faded ochre/amber route markings;
- sparse dark asphalt/bitumen notes where infrastructure calls for them.

Snow is a **broken surface condition**, not a total white biome blanket by default.

Vegetation should never push the world toward saturated emerald green.

### Ecological biomes

The existing ecological biome IDs remain valid, but in the first campaign world they are local ecological variation inside one macro art direction.

- `rocky_upland`: dominant highland expression.
- `woodland`: cold conifer woodland, dark understory, exposed rock and infrastructure remnants.
- `scrubland`: wind-exposed sparse cold scrub, stone and dead grass.
- `wetland`: bounded cold bog/drainage pockets, dark waterlogged ground, not a lush swamp identity.

Biome borders should feel naturally interleaved rather than four separate color-coded worlds.

### Weather presentation

The baseline visual family especially supports:

- clear cold exposure;
- overcast;
- mist;
- light snow;
- heavier snow as a weather state;
- cold rain.

Ashfall and dust wind remain valid system states but should read as event/weather overlays, not redefine the base campaign-world palette.

## Elevation And Depth

Elevation is part of the world identity, not only traversal math.

The composition should repeatedly produce:

- visible cliff lips;
- vertical or near-vertical fascia;
- terraces overlooking depth;
- roads/hardstand perched above drop-offs;
- treelines descending into darker lower bands;
- occasional infrastructure spanning or retaining severe terrain.

The playable upper plane should read as **cold, exposed and high**, not "bright."

Depth scenery should support the locked alpine/conifer identity. Legacy profile names such as `ENDLESS_FOREST` are implementation/profile identifiers and must not pull the world toward lush fantasy forest presentation.

## Hardened Infrastructure

Custodian occupation should appear as engineered insertions into hostile terrain.

Preferred world-scale infrastructure:

- weathered civic/military hardstand;
- reinforced service aprons;
- landing/transfer pads;
- retaining walls;
- barriers and guard rails;
- pylons and service masts;
- cargo stacks and field crates;
- utility towers;
- relay/communications structures;
- fortified gates;
- compact checkpoints;
- maintenance yards;
- narrow engineered causeways;
- road markings and service lanes that are worn but still legible.

The hardstand family should feel built from stone/composite/concrete slab systems adapted to a severe field environment.

Do not make the world look like a pristine base-builder grid.

## Custodian Structure Application

The global structure grammar remains owned by
`custodian/design/02_art_direction/CUSTODIAN_STRUCTURE_DESIGN_CONTRACT.md`.

For the first campaign world, emphasize:

- severe, functional silhouettes;
- dark steel / blackened iron / stone-metal composite;
- substantial bases and retaining geometry;
- vertical authority elements on strategic structures: pylons, mast clusters, guarded towers, signal spines;
- stacked logistics and service modules;
- readable exterior machinery;
- restrained insignia;
- weathering, frost, grime and repair scars;
- integration with hardstand and cliff geometry.

Exterior lighting should be sparse and purposeful.

Use:

- warm amber/brass work lights and navigation/service lamps;
- neutral industrial white where practical;
- restrained teal/cyan only where it clearly communicates machine state or established Custodian operational identity.

Do not turn ordinary infrastructure into a teal-neon skyline.

Major strategic structures may be taller and more monolithic than ordinary utility nodes, but still require mechanical/function cues.

## Custodian Vehicle Application

Vehicle system/runtime authority remains `design/02_features/vehicles/VEHICLES.md`.

The first campaign-world Custodian vehicle family should read as:

- rugged expeditionary/logistics equipment;
- field-serviceable;
- boxy and mechanically legible;
- armored or reinforced without becoming a main-battle-tank visual default;
- muted charcoal, gunmetal, weathered olive and dirty canvas/tarp;
- restrained brass/ochre markings;
- practical cargo, scanner, maintenance or transport fittings;
- tires/tracks/hover hardware visibly appropriate to role;
- worn, snow-dusted, mud-streaked and used.

Preferred reads include:

- utility truck;
- expedition carrier;
- field maintenance vehicle;
- survey/recon vehicle;
- cargo/relay support vehicle.

Avoid:

- sleek civilian sports-car silhouettes;
- glossy clean sci-fi shells;
- neon hover-racer styling;
- improvised Mad-Max scrap heaps;
- oversized weaponry as the default identity.

## World UI Shell

The world HUD remains in the Black Reliquary family, but the first campaign-world field shell is specifically:

- sparse;
- dark charcoal/graphite;
- warm ivory text;
- restrained brass/gold linework;
- thin technical rules;
- small corner brackets;
- geometric authority glyphs;
- compact uppercase metadata;
- generous negative space over the world;
- readable at gameplay zoom without becoming a cockpit HUD.

The field HUD should feel like an archival/survey instrument laid lightly over the world, not a dense tactical dashboard.

Normal play should prioritize:

- vitals;
- immediate interaction/status;
- objective/route tags when needed;
- small contextual world metadata;
- marker/beacon language below.

### Not locked into the field HUD yet

The reference image contains a compass and minimap, but those are **not part of this first-campaign-world UI lock at this time**.

Existing minimap runtime systems remain valid implementation capability. Their presence in old HUD docs does not make them mandatory for the new field-HUD baseline.

Compass presentation is likewise deferred.

Archive Resolve presentation remains separately locked and is not restyled here.

## Marker / Beacon Grammar

World markers should use the same restrained survey/authority language as the field HUD.

Preferred elements:

- thin amber/brass brackets;
- compact corner ticks;
- small geometric glyphs;
- vertical locator stems;
- subtle target/registration rings;
- short uppercase tags;
- tiny range/state metadata only when useful;
- restrained pulse/acquisition animation;
- world-space beacons that remain visually narrow rather than becoming large floating icons.

Markers should feel **registered / attested / surveyed**, not like generic RPG pins.

Avoid:

- oversized colored map pins;
- saturated red/green/blue category badges;
- bouncing exclamation marks;
- cartoon arrows;
- giant floating text blocks;
- dense tactical reticles around every interactable.

Important beacons may gain one stronger geometric frame, but never enough ornament to compete with terrain/actors.

## Iconography

Preferred iconography is:

- geometric;
- thin-line;
- symbolic;
- institutional;
- slightly ceremonial;
- mechanically plausible as signage or survey notation.

Favor:

- diamonds;
- split circles;
- compass-like radial marks without requiring a compass UI;
- restrained crosshair/registration geometry;
- gate/relay/structure silhouettes reduced to clean glyphs;
- narrow chevrons and ticks.

Avoid:

- fantasy runes;
- military-shooter stencil spam;
- emoji-like pictograms;
- skeuomorphic glossy buttons;
- ornate gothic heraldry on routine UI.

## Composition And Readability

At the standard gameplay camera, visual hierarchy should usually read:

1. Operator / immediate threat;
2. traversable ground and cliff edge;
3. route / hardstand / structure frontage;
4. large strategic structure or vehicle silhouette;
5. marker/beacon information;
6. small surface detail.

Terrain detail, foliage, hardstand markings and UI must not flatten that hierarchy.

The reference's strongest composition rule is worth preserving:

> large quiet dark space around a sharply readable island of resolved terrain and infrastructure.

Archive Resolve owns how that frontier resolves. This document owns what the resolved side looks like.

## Anti-Drift Rules

For this campaign world, reject direction that primarily reads as:

- lush fantasy forest;
- colorful biome sampler;
- generic post-apocalyptic wasteland;
- neon cyberpunk;
- pristine white sci-fi colony;
- Gothic cathedral landscape;
- modern military simulator;
- flat RTS base;
- cozy alpine village;
- dieselpunk junkyard;
- UI-heavy tactical shooter.

The intended flavor is:

> **cold alpine frontier + ruined organized authority + hardened logistics infrastructure + severe elevation + restrained archival/brass field UI.**

## Relationship To Archive Resolve

`STREAMING_REVEAL_PRESENTATION_V1.md` remains the sole visual/presentation authority for Archive Resolve itself.

This world lock only constrains the material on either side of that transition:

- resolved terrain/structures/vehicles/UI follow this document;
- unresolved/reacquisition presentation follows Archive Resolve;
- no later visual packet should redefine Archive Resolve merely to match this document.

## Relationship To Old References

`STARTER_MAP_PROCGEN_REFERENCE.png` and the original starter-map prose remain useful for historical layout/semantic-generation intent only.

They are **not visual-style authority** for the current campaign world.

Any future concept/reference that intentionally replaces this visual lock must update this document explicitly rather than quietly introducing another competing style source.
