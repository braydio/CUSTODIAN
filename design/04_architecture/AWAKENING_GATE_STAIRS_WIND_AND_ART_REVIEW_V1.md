# Awakening Gate of Dust: Wind Relocation, Lateral Stairs, and Asset Rejection V1

**Status:** Recorded user-observed defects and recommended lateral-branch concept. Not a completed runtime fix or an approved new traversal lock.
**Area:** Awakening Zone 07 Gate of Dust, immediately north of Zone 06 Undergate.
**Authoring conversation:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
**Date:** 2026-10-10
**Authorities:** `design/04_architecture/AWAKENING_FIRST_RETURN.md`; `custodian/game/world/awakening/awakening_layout.gd`; `custodian/game/world/awakening/awakening_first_return.gd`; production Gate underlay/foreground (1536×768). Perimeter vision: `AWAKENING_PERIMETER_SUPPORT_V1.md`.
**Decision state:** Wind-location defect confirmed in code; side-stair destination identities are **proposed, pending user ratification**. No additional active task packet yet.

## W0 — Move wind-dust effects north out of Undergate (confirmed defect, implementation pending)

User reports the two dust-devil animations appearing inside the Undergate Mechanism Hall; they belong on the exterior Gate plaza. Current `AwakeningFirstReturn._build_detail_presentation()` creates `GateWindDustWest` and `GateWindDustEast` as children of Zone07 `SetPieces`, but at `Vector2(-112,-4848)` and `Vector2(112,-4848)` respectively. `Layout.ZONES` gives Gate Zone07 envelope `Rect2(-704,-5504,1408,640)` (Y `-5504..-4864`). Both current centers are **16 px south of the Gate envelope**, explaining why they appear on the Undergate side despite their scene parent.

**Bounded correction proposal:** Move the two positions north to `Vector2(-112,-5056)` and `Vector2(112,-5056)`, a 208 px northward translation with existing X, animation (8 FPS, 128px), alpha, scale, ownership and z unchanged. `Layout` already has the visual `rest_checkpoint` set piece near `(0,-5056)`; the two flanking winds should feel part of the exterior forecourt rather than a machine chamber. This is a starting coordinate to confirm by real renderer, not an immutable final art-registration target.

**One-time implementation guidance (not run):** In `custodian/game/world/awakening/awakening_first_return.gd`, replace only the two exact existing `GateWindDustWest/East` `Vector2(` positions, keeping every other parameter unchanged. Add a deterministic scene test that resolves their actual global rects (including Sprite2D scale) and requires the entire visible animated area inside the Gate presentation envelope, not merely correct Zone07 parent or center. Verify by entering from Undergate and looking north, crossing the existing Gate camera reveal, and returning south. No residual exterior dust should render in Undergate; enough plaza dust remains to convey exterior wind. Do not alter the separately-owned Dust Lung motes or falling ash; do not introduce new VFX or a gameplay obstacle. Regression: `awakening_first_return_progression`, scene/geometry, Gate art registration and real renderer before/after.

## S0 — What the real production plate depicts

`res://content/levels/awakening/07_gate_of_dust/awakening_gate_plaza_underlay_1536x768.png` visibly shows an axial plaza with conspicuous **west and east stairways** climbing into flanking masonry/fortifications, in addition to the main northerly progression. The same-sized foreground gives the upper walls correct Operator occlusion. Thus the side stairs are deliberate-looking physical invitations, not invented features from generative art.

The current `AwakeningLayout` Zone07 floor is `Rect2(-704,-5504,1408,640)` and Zone07 has no distinct west/east branch connector, markers, or entered destinations. The north Route remains `zone07_gate_of_dust → zone08_custodian_approach`, and Zone09's Chapel of Late Service is a **separate optional west detour farther north**. An apparent staircase in raster art does not establish a working route or justify making an unbounded continuation.

### West/east branch direction revised 2026-10-10 (exploration, NOT implementation)

**User rejected both former tentative names**. Never use `Warden's Vigil` or `Scourwind Overlook` as active lore/quest/location IDs. Former small west guard-duty pocket is superseded as a creative direction. These stair destinations are NOT yet ratified runtime traversal.

| Gate direction | Revised intended presentation | Decision state |
|---|---|---|
| **WEST** | **Unnamed, hard/secret mid-game underground region**, close enough to the opening experience to tease very early, with apparent catacomb-like descent and later much deeper institutional/continuity horror. The Gate stair is a conspicuous sealed return-later invitation, not a mundane watch platform. | Location/presentation direction favored; identity, interior content and gate imagery undecided |
| **EAST** | **Unnamed simple overlook of the dead historical city**. Cracked elevated terrace, ruined skyline, subtle wind and tremendous negative space; no named destination, special reward or narrative mechanism required. | User directed; preserve scenery without over-design |
| **NORTH** | Existing mandatory route to Custodian Approach and South Reach. | Locked current runtime authority |

**Literal spawn distinction:** `AwakeningLayout.OPERATOR_WAKE_POSITION` is the Crèche `(0,160)`, whereas the west Gate stair is in Zone07 several zones north. If the requested experience is *literally beside spawn*, a separate **purely visual** inaccessible glimpse of the same forbidden substructure at the Crèche/early Ambulatory (a shaft, grille, hanging iron doors, distant vertical chamber) can establish its presence there, while the actual sealed entrance is later encountered at Gate west. This is a concept, not a second functional portal or a coordinate change. Never pretend the Zone07 staircase itself is at spawn.

**No mechanics in this design iteration:** avoid specifying a key, player ability, boss prerequisite or authored state machine. Present a physical heavy seal that *visually* promises later entry: structural weights, immobile bolt drums, inaccessible descent, and low distant activity. Next review may choose a thematic reason for the seal; coders must not infer a mechanical unlock contract from an art concept.

**Candidate environmental identities:** see [AWAKENING_FORBIDDEN_LOWER_REGION_CONCEPTS_V1.md](AWAKENING_FORBIDDEN_LOWER_REGION_CONCEPTS_V1.md). The environmental region must not accidentally duplicate the later Hub Sepulcher Gardens, the Undergate Register of Departures, or the optional Chapel. A memory/identity/recovery-oriented catacomb underground is a particularly apt synthesis, because the Crèche canon deliberately distinguishes valid designation from proven continuity of personhood.

Keep the two existing Gate stair mouths legible and preserve main north route. Any future region-scale/branch game area requires its own separately decided design, spatial plan, task packet and paired review; neither AP3 perimeter art nor W0 wind fix can create a secretly claimable side route.

### Immediate containment / art requirement

Until the user approves which branches become playable, **do not cover or visually seal those east/west stair mouths with generic perimeter rubble.** Likewise do not silently open them: if a side stair presently goes nowhere, an explicitly honest non-invasive temporary in-world obstruction or termination needs visual/user review. This is an existing **visible invitation versus authored-route authority** issue. All future Zone07 distant-structure `distant_structures` and `edge_transition` generation/compositing must protect both staircase apertures and the main north route; do not paint a second Gate, invent new portals or enable side collision merely because scenery looks walkable. The exterior AP3 art packet cannot claim this branch implementation; an explicit later spatial branch packet + paired review is required if approved.

## A0 — Batch 01 (ten image assets) rejected by human aesthetic QA

The earlier `CUSTODIAN_Awakening_Perimeter_Batch01_10_Assets_CANDIDATES.zip` (user-visible artifact, not a repo-verified asset release; SHA-256 `9fbc3e0d187c8b44d8146ad6457ac2e12a91e71e26c0d0e417ca6d7356268c1e`) was assembled by cutting ten labeled items from **two rendered atlases**. This was a bad production tactic. Three supposed repeatable 512×512 tiles were expanded using mirror-periodic reconstruction, producing conspicuous reflections and central motifs. The panoramas and edge decals contain malformed/cross-bred architectural details and incoherent perspective, are partly derived from source art as small as ~201×179, and do not match real plate visual scale. Border-pixel equality, RGBA and filename/dimension checks are not artistic acceptance.

**Human disposition 2026-10-10: REJECT_REGENERATE for all ten.** Source donors may be retained solely as concept/reference material. **Do not copy their normalized `inbox` candidates into a working checkout, ingest, bind, register as complete, or promote dependent art-implementation packets.** The 27 generic planned perimeter images remain **zero newly approved in this batch**. No repository runtime files have been altered by these generated images.

### New generation QA gate

1. Generate **one independent image per state**, not a labeled multi-asset atlas. Show the real production plate as reference or use a well-defined art/camera lock.
2. Inspect the **original output** at full resolution before normalization for duplicated morphology, anatomical/structural distortions, mismatched perspective, impossible machinery, AI-smudged fine detail, second Gate or second route.
3. Structural tiling must be authored/validated as genuine continuous pattern, **not mirrored to force a zero-difference border**. For inaccessible architecture, use clean true RGBA with controlled depth; image metadata is not proof of scene fit.
4. Assemble a **real scene-scale before/after composite** at the measured adjacent camera footprint. Keep landmark silhouettes and left/right stairs unobstructed; do not arbitrarily upscale tiny atlas crops.
5. Mark `REJECT_REGENERATE` or `SOURCE_READY_NEEDS_TUNE` as indicated, with explicit human review. Only accepted source work can proceed through Asset Pipeline V2. Store SHA/size/provenance for every accepted state.

## Next engineering packets (not yet authored)

- **W0** minimal Gate wind placement correction and focused renderer/geometry regression, ideally independent of art intake.
- **S0** user-ratified Gate west forbidden-region presentation concept and unnamed east city-overlook presentation, then evidence-driven independent spatial plan/implementation/review only if approved. For a literal spawn-adjacent tease, audit an early Crèche/nearby view of the *same* deep structure; do not invent a second portal.
- **A0** revise and regenerate the three first calibration states one-by-one, re-auditing Gate branch mouths before creating any perimeter atlas; retain the AP0/AP3 art gates as manual where appropriate.

The separately tracked Crèche screen-local activation VFX fix remains owned by `awakening-interactible-console-port-presentation-v1`. Dust Lung V2 remains separate. This document does not change either.
