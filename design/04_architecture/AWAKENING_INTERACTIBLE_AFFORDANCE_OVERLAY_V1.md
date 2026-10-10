# Awakening Interactible Affordance Overlay V1

**Status:** production design + packet queue authored, artwork pending
**Workstream family:** `awakening-interactible-affordance-overlay-v1`
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d
**Art authority:** `design/04_architecture/AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md`

## Problem and correct boundary

The player encountered the Locker→Dust-side terminal area with no clear physical clue that the Crèche/Undergate terminal family could be used. The first seconds should communicate **actionable place** visually before a proximity prompt appears. The opening currently has only four live interaction owners: Crèche Console, P-9 Designation Locker, a single two-station Dust Lung TransitLift, and damaged Port Status Console. The Layout also exposes many scenic/disabled/future markers. A `kind=interactable` label on `lift_mechanism` does not imply a distinct runtime interaction.

**Primary overlay:** a visual-only `AffordancePresentation` mount tied to existing Layout marker IDs and current real interactible nodes. Its visual layers are (1) long-distance prop silhouette/physical mass, (2) mid-range floor and service dressing, (3) near-range low-amplitude light/VFX when actionability is confirmed by the existing gameplay owner. No second input handler, interact radius, use-state registry, collision shape, quest/route gate, or duplicate asset-pipeline runtime path.

The eight design roles approved in the review are represented:
1. universal support kit (floor marks, cold/amber beacons, sconce/backplate/cables, contained idle VFX);
2. actual Crèche and damaged Port console/readout body, floor, screen and status;
3. P-9 reliquary wall-mounted reinforcement without replacing the 4-state hero body;
4. Dust Lung two lift-station service cues and real busy/readiness status;
5. Gate/Rest/Attestation/Register/Lore/Chapel scenic wayfinding without faux interactivity;
6. transfer/Crown/Continuity Port control and egress markers for future owners;
7. civic/Witness/Forum/Adjudication and memorial/Sepulcher design vocabulary for future owners;
8. supply/Field Patch stations and manual gate controls, deferred until gameplay postings exist.

## Existing owner relationships

| Live world | Existing owner | Affordance overlay | Required before claim |
|---|---|---|---|
| Zone01 Crèche | `CrecheConsole` via `_build_interactables()` | console body / floor / light / idle screen / existing activation FX | verified terminal/support/FX assets |
| Zone04 Locker Reliquary | scene `SidearmLocker` | wall relief / brass authority seal / inset / sconce, retains four-state Asset V2 hero | verified locker/support/FX assets |
| Zone05 Dust Lung | one `AwakeningTransitLift` with lower and upper stations | two station mounts / approach floor / status; no duplicated lift | verified lift/support/FX assets |
| Zone06 Undergate | `PortStatusPlaque` via `_build_interactables()` | damaged console/backplate/failing light / floor inset | verified port/terminal/support/FX assets |

**Inert markers:** Lore Plaque, Attestation Dais, Register of Departures, Gate Aperture, Rest Checkpoint, optional Chapel etc. remain non-interactive; scenic wayfinding must not imply pressing an interaction key.

**Future** (not current Awakening 01–10): Field Terminal, Ashen Forum/Witness/Adjudication, CrownTransfer, ContinuityPort, Sepulcher, supply/Field Patch station, door/gate use. Use existing Hub/Campaign posting owners when available.

## Queue insertion / DAG

```text
AWAKENING_INTERACTIBLE_AFFORDANCE_FOUNDATION_V1  ready/auto
             └─ paired fresh review
AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_V2_CONTRACTS_V1  ready/auto (independent)
             └─ paired fresh review

     exact approved art source + Dropbox receipt
     + genuine normalized Asset V2 VERIFIED states
     + two predecessor reviews
             │
             ├─ CONSOLE_PORT_PRESENTATION_V1       blocked/manual -> art-verified promotion
             ├─ LOCKER_LIFT_PRESENTATION_V1        blocked/manual -> art-verified promotion
             └─ MARKER_WAYFINDING_V1               blocked/manual -> selected optional-art promotion
                 (each has independent paired review and human visual check)

AWAKENING_INTERACTIBLE_DEFERRED_FAMILY_HANDOFF_V1 ready/auto (docs-only future owner crosswalk)
             └─ paired fresh review
```

Implementation packets are in `custodian/docs/ai_context/task_packets/` and each inherits repo AGENTS/task-packet lifecycle rules. Do not fake readiness of any art-driven consumer to force the dispatcher to claim it. When the Dropbox/source evidence and verified state set arrive, refresh and promote a **specific** implementation+review pair together, never blindly all three.

## Adjacent Awakening workstreams

- `awakening-perimeter-support-foundation-v1` and `AWAKENING_PERIMETER_{INTERIOR,DEPTH,EXTERIOR}_V1` own **off-route** scenery/support backdrops, not interactible identity; do not insert new art dependencies into those packets or make their execution depend on this overlay.
- `AWAKENING_ROOM_CONNECTORS_POLISH`, `AWAKENING_04_05_REGISTERED_COMPOSITION_* `, and `AWAKENING_LOWER_UPPER_SPINE_CONNECTION` are already authoritative for seam/draw order/traversal. The affordance owner may only register additively; no wall/grate reauthoring is smuggled in as a terminal enhancement.
- `AWAKENING_INTERACTION_FEEDBACK_CONSOLE_ACTIVATION` already addressed prompt lifetime/console one-shot action, so these packets must not spawn another HUD prompt owner.
- Hub Muster/Continuity Port, Forum Adjudication and First Set packets own future content. The separate deferred handoff crosswalk must avoid duplicating active Hub art families and nodes.

## Visual lock

Custodian detailed angled top-down/2.5D realistic Gothic-civic-industrial construction, weathered grey stone/composite metal, restrained dull brass, dim teal info and warm amber authority signals, deep relief, readable industrial assembly, floor-integrated approach. No generic luminous sci-fi kiosk or full-room neon. Ordinary pickup/prompts confirm but do not announce a surprise object. No unused markers receive actionable focus lights. Each active affordance must read at mid-distance with HUD hidden and still fit baked room art, lighting/occlusion and the accepted 04→05 native-composition alignment. No new VFX source required for claimable foundation; active FX bindings require verified art.

## Artwork gates and source-work

See art manifest for exact 77 state images/12 families and every per-state size, static/animated frame count, fps, alpha, and `source_work/awakening/<family>/<state>_source.png` and `inbox/<family>/<state>.png` destinations. Art planned but absent: 27 required live, 14 recommended, 36 deferred. Register active contracts/required statuses without creating false input assets. Dropbox durable approved input root: `/CUSTODIAN/asset_batches/awakening-interactible-affordances/<batch_id>/`. Human-reviewed exact checksum and V2 status needed; no folder-presence shortcut.

## Closure

Gameplay-scale review shows all four current use opportunities have readable unique physical character from exploratory distance; used/busy states do not falsely invite action; inert markers only guide; no route or collision change; exact asset provenance and no GPU/animation spam; focused progression, geometry, 04→05 scene art, lift/locker, Asset V2 validation and paired reviews green. Human final judgment remains an explicit gate for visual slices.
