# Authored Hub + Campaign Microevents V1

**Status:** authorized implementation contracts, initial no-new-production-art pass
**Authority:** `design/03_world/lore/CUSTODIAN_MANDATE_AND_HUB.md`, `design/03_world/RECIPROCAL_CONTINUITY_DOCTRINE.md`, `design/04_architecture/HUB_SPATIAL_LAYOUT.md`, `design/04_architecture/REGION_GENERATION_SYSTEM.md`.
**Runtime target:** Godot 4.x (`custodian/`).
**Implementation sequencing:** Each event's packets are sequential through its paired review. The five event chains are **independent**; do not create cross-event blockers. Start with Grave G1/G2 (P1).
**Authoring chat:** not-recorded (supply this conversation's exact URL when provided; never substitute another).

## Rules common to all five events
- An authored moment is a bounded local scene/controller + the smallest owner-approved scene/placement seam; no universal narrative-event engine, second world-state manager, hand-authored canonical Asset V2 outputs, or new required raster art.
- Use existing Operator, camera, HUD interaction, objective, combat, weather/lighting, procgen authoring and state owners where their contracts actually support the behavior. No direct call to Contract acceptance/prewarm from an authored Hub event.
- All interactions must be discoverable and physical, reachable at real Operator clearance, non-blocking on ingress/exit, safe to quit/re-enter; never steal input, camera or story progress.
- Use existing presentation, conservative Godot primitives/labels, or available production art for V1; do not silently present temporary primitives as production art. No new Asset V2 family is needed in V1. If final art is subsequently authorized, specify source_work, inbox, family schema, exact dimensions/states and ingestion independently.
- Hub moments persist in the existing authoritative `HubState` serialized snapshot/restore flow. The initial Grave slice may introduce a narrowly named `authored_event_records` Dictionary with safe read/update methods, deep-copy, backward-compatible restore, and exact event IDs; later Hub events **reuse** it. Do not use `WorldEventMemory` to claim Hub persistence.
- Generated-region moments are **run-scoped** and use existing `WorldEventMemory` (or its verified equivalent) with seed-qualified IDs and payloads. They must not write `HubState` directly or force a new `CampaignOutcome` format. Recoverable evidence may use existing in-run UI/inventory semantics; cross-campaign reward conversion is deferred.
- Presentation effects cannot own weather schedule, simulation, terrain, collision, nav, camera, contract, inventory or vehicle lifecycle.
- Canon locks: no identities of impossible figures, no revelation of the Severing's cause, no claim that provenance repairs reality. Null Warrant and Meridian Office remain distinct authorities. CUSTODIAN can find continuity safety status, not decide ordinary ownership or civil law.
- Run focused smokes + directly affected regressions first, changed-file validation after. Visual proof: scripted state/position checks first, at most two tightly cropped before/after frames for subjective readability; stop for human review only if aesthetic approval is genuinely blocking.

## Event 1 — The Grave That Refuses Its Name
**ID** `hub_sepulcher_grave_v1` **Place** first-set Sepulcher Gardens near `HubFirstSetLayout.MARKERS.SepulcherInteriorSample=(-1984,-3200)`.
Three physical, safe inspections around the existing two independent Gardens connectors uncover incompatible identity readings of one gravestone. Its **date is invariant**: `CYCLE 184 · NINTH WATCH`; readings are `RECORD A: ELIAN VALE / WITNESS`, `RECORD B: MARROW SEN / RELAY KEEPER`, `RECORD C: IDENTITY HELD / NO VERIFIED CLAIMANT`. These are contradictory records, **not** proof of body/person replacement. V1 may use a three-step physical inspection circuit anchored by the existing Garden route; one interaction cannot advance more than once per distinct stage/circuit; don't require physically circling an invisible trigger to succeed.
After all three readings offer `ATTEST: PROVENANCE CONFLICT` and `LEAVE UNRESOLVED`. Both persist once. A tiny pale growth appears at the slab upon resolution on subsequent visits (no supernatural causality claim). Fully noncombat, optional, no Contract interaction.

## Event 2 — The Unanimous Contradiction
**ID** `hub_forum_hearing_v1` **Place** Ashen Forum, beside but not atop the canonical `AdjudicationDais=(0,-3136)`.
Two authentic-but-incompatible orders refer to continuity aperture `PORT A-17` at `CYCLE 184 · NINTH WATCH`: `OPEN: VERIFIED TRANSFER` and `HOLD: RECIPROCITY UNRESOLVED`. The third inspection is a damaged relay showing two valid authorities and no trustworthy ordering. These constitute evidence, not a moral puzzle or proof of forgery.
After inspecting three sources offer `ATTEST: PROVENANCE CONFLICT` or `MAINTAIN HOLD: RESTORATION NOT AUTHORIZED`. Persist choice in Hub event record, allow reread without re-resolution. This local hearing **must not** call `HubCampaignSelectionAuthority.accept_first_contract()`, mutate the accepted scenario, activate Dais proposal flow, or start `WorldContractBootstrap`.

## Event 3 — The Procession of No One
**ID** `hub_road_procession_v1` **Place** Road of Witnesses / North Processional, South Reach toward `ForumSouth=(0,-2464)`.
A voluntary one-shot traversal trigger starts exactly one 3-beat light/bell sequence: south lamp, middle lamp, north lamp; final sound and empty-road silence. Ordinary traversal/camera/UI continue. Reuse Road plate positions and existing lighting/audio pathways without altering Road presentation ownership or geometry. Reentry or reload resumes safely (not a repeated spectacle loop). Existing witness station offers 3 conflicting testimonies (`victory procession`, `evacuation`, `road was empty`). After reading all, mark observed; subsequent visit offers a **single brief bell** and no full replay. No visible ghosts or canonical origin reveal.

## Event 4 — The Convoy That Arrived Empty
**ID** `campaign_empty_convoy_v1` **Place** optional, seed-deterministic roadside encounter in an eligible generated campaign region.
An intact defensive ring faces **outward** around an empty cargo cradle; manifest `IN TRANSIT`, dispatch `ABSENT`, receipt `UNACKNOWLEDGED`. Select one accessible 12x10-or-larger navigable pocket (adapt physical units to live generator). Never require insertion if no safe pocket exists; failed placement cleanly skips and leaves the seed/world unchanged. A scan activates existing security units (fixed bounded count, no new AI/boss). On completion, recover `CONVOY CUSTODY TRACE: SHIPMENT UNVERIFIED`, one scoped in-run salvage through existing ledger APIs if valid; no duplicate drops or fabricated item registration. A Scout wreck may be a **static** prop; actual vehicle restoration/driveability is an optional enhancement only when its existing lifecycle can be reused without forcing asset completion.

## Event 5 — The Station That Asked to Be Abandoned
**ID** `campaign_abandoned_station_v1` **Place** optional seed-deterministic landmark on an **Alpine Plateau** generated region.
Station broadcast: `RELIEF REQUESTED / PERSONNEL EVACUATED / DO NOT RESTORE LINK`. Physical service nodes `NORTH RELAY`, `EAST CONDUIT`, `CORE FEED` can be inspected/serviced in any order. Local stability timer 90 simulation seconds from first service action; service completion reveals an unsafe outward continuity coupling. Escalation is locally bounded weather/lighting presentation through **existing** World Environment/Atmosphere/Lighting owners; do not mutate the deterministic global weather scheduler or add another weather engine. After all three services, offer `MAINTAIN CONTAINMENT / EVIDENCE PRESERVED` or `SHUT DOWN COUPLING / EVIDENCE INCOMPLETE`. If 90s elapses before full service, show `STABILITY WINDOW EXPIRED`; fail locally without damaging campaign state or trapping extraction. Don't equate evidence/provenance with the physical coherence field. No new mandatory art or global mission timer.

## Packet count and adjacency
| Event | Implementation slices | Paired reviews | Dependencies |
|---|---:|---:|---|
| Grave | 2 | 2 | G2 after G1 review |
| Contradiction | 2 | 2 | U2 after U1 review |
| Procession | 2 | 2 | P2 after P1 review |
| Convoy | 3 | 3 | C2 after C1 review; C3 after C2 review |
| Station | 3 | 3 | S2 after S1 review; S3 after S2 review |
**Total: 12 implementation + 12 independent reviews = 24 packets.**
The five root packets have no dependencies on one another. For any successor, **assume its named predecessor and post-land review have landed and passed**; inspect live code at claim time and adapt private helpers, not the behavioral contract.
