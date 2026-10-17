# Awakening Interactible Deferred-Family Ownership Crosswalk V1

**Status:** documentation handoff; no future interaction or art is authorized by this document.
**Authority:** [Awakening Interactible Affordance Asset Manifest](AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.md) and its state table/JSON ledger.
**Current-main audit:** `1170afcd386bd98a4fd4471e9542238cc28089fa` (2026-10-12).
**Refresh planning chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Purpose and rules

The source manifest names 36 future-only states across transfer, civic, supply,
memorial, gate, and shared-effect concepts. This crosswalk records the real
current owner or the absence of one, the planned packet where it exists, the
known spatial anchor, and the Asset V2 reuse check that a later art packet must
perform. The manifest's future family IDs are planning labels; they are not
registered families, active required-asset demand, or proof that source images
exist.

A Layout marker, room envelope, route, or scenic backdrop does not by itself own
an interaction. Likewise, an existing family with a related name is only a
reuse candidate until its current V2 state, visual role, binding, geometry, and
human approval establish an exact substitution. New ownerless states remain
deferred. Do not add them to Awakening 01–10, runtime scenes, the required-assets
registry, or live family contracts from this crosswalk.

### Existing terminal and damaged-Port states are separate

The registered `awakening_interact_terminal` contract already names six
source-planned states: `console_pedestal` (96×128), `console_wall` (96×128),
`console_backplate` (128×128), `screen_glow` (64×64), `console_floor_pad`
(128×64), and recommended `console_cables` (64×96). Its five required states
currently report `0/5` present in Asset V2 status. These are the current
Awakening console/readout contract, not a posted Hub Field Terminal owner or
proof of available pixels.

The `awakening_interact_port` states (`damaged_status_body`,
`route_registry_backplate`, `damaged_floor_inset`, `port_status_beacon`, and
recommended `port_conduit`) are specifically the damaged Undergate `PortStatusPlaque`.
They do not represent the Hub's ordinary Continuity Port. The reusable
`FieldTerminalInteractable` script remains in the repository, but the default
boot is `runtime_entrypoint.tscn`, Awakening's opening scene does not instance a
Field Terminal, and H1 replaced the free-standing Field Terminal destination
with Forum adjudication → Muster Court → ordinary Continuity Port. No separate
current Hub Field Terminal gameplay/art owner is posted. A future status surface
must be attached to a real owner and must not become a duplicate destination.

## Current owner and posting evidence

| Concept and manifest states | Current owner / posting state | Known anchor | Existing Asset V2 evidence and reuse boundary |
|---|---|---|---|
| **Crown Transfer** — `transfer_control_post`, `transfer_threshold_medallion`, `transfer_beacon_pair`, `transfer_cable_spine`, `transfer_registry_panel`, `transfer_seal_frame` (`awakening_interact_future_transfer`) | The H4 `hub-crown-transfer-twin-solaria` route owner is complete and independently reviewed. It owns the optional Hub → Twin Solaria route, not a separate six-piece prop controller. No production Transfer Court art owner or per-piece mount is posted. | `HubFirstSetLayout.MARKERS.CrownTransfer` at `(1088,-4672)`; return at `Spawn_TwinReturn`. | `district_transfer_frame` reports 19/19 required states with imported runtime outputs; its consumer is `GothicCompoundTravelGate`, and the current status does not prove Hub binding or reuse approval. Audit its `body`, `threshold`, `pedestal`, screen states, `route_plate`, `service_junction`, and cable feeds before proposing an exact reuse. `twin_solaria_v1_environment.crown_causeway` is a bound backdrop state, not a transfer prop. No zero-new-art substitution is approved. |
| **Ordinary Continuity Port** — `continuity_port_pylon`, `continuity_port_gate_frame`, `continuity_port_floor_lane`, `continuity_port_control_terminal`, `continuity_port_beacon`, `continuity_port_signage` (`awakening_interact_future_transfer`) | `hub-muster-continuity-port-deployment` (H5) is the planned gameplay owner for Port deployment. On this audit it is dispatcher-claimed but not landed on current main; its paired review and H6 Campaign return remain downstream gates. H6 must use the same Port owner, not create a second one. | `ContinuityPort`, `CampaignExitThreshold`, and `Spawn_CampaignReturn` in `HubFirstSetLayout.MARKERS`; the exact prop mounts are not posted. | `district_transfer_frame` is a possible source-review candidate only; its current consumer and state shapes/roles are not an approved ordinary-Port mapping. The Awakening `awakening_interact_port` family is the damaged Undergate readout and is not the Hub Port. Keep all six states deferred until H5/H6 owner and placement are landed and reviewed. |
| **Witness / Forum / Adjudication** — `witness_lectern`, `witness_seal_floor`, `adjudication_plinth`, `adjudication_light_pair`, `forum_record_pillar`, `registry_brass_plate` (`awakening_interact_future_civic`) | H3 `hub-forum-adjudication-contract-prewarm` and its paired review are complete. The live `HubAdjudicationDais` owns first-Contract acceptance at the Dais. It does not establish separate Witness, registry, or record-pillar interactions or art mounts. The Forum 2.5D vertical-slice packet remains `draft/manual` and is presentation-only. | `AdjudicationDais`, `ForumSouth`, and `ForumNorth` in `HubFirstSetLayout.MARKERS`. | Road of Witnesses families and `twin_solaria_v1_environment` are environment/backdrop assets, not approved hero replacements for these pieces. No exact current Hub civic prop family was found. Bind any later props only to a separately posted gameplay owner or to the existing Dais where its authority genuinely applies. |
| **Supply / Field Patch service** — `supply_station_frame`, `supply_station_tray`, `supply_patch_canister`, `supply_cabinet`, `supply_floor_marking`, `supply_task_light` (`awakening_interact_future_supply`) | `OperatorFieldPatch` owns the carried timed heal mechanic. Its completed packet explicitly defers production pickup/restock art; no Hub or Awakening restock-station interaction owner is posted. Do not infer one from the mechanic. | No approved service-station anchor. The H1 Muster Court envelope is spatial context only. | `field_fabricator_mk1` is a complete, bound fabrication owner, but its manufacturing states do not represent Field Patch restock. It is not a substitute without a future gameplay/design decision. No exact supply-station V2 family was found. |
| **Sepulcher memorial** — `sepulcher_plinth`, `sepulcher_marker`, `sepulcher_sconce`, `sepulcher_ash_basin`, `sepulcher_floor_ring`, `sepulcher_inscription` (`awakening_interact_future_memorial`) | H1 owns only the Sepulcher Gardens walkable envelope and two-connector circulation loop. No memorial object, narrative interaction, or gameplay owner is posted. | `SepulcherInteriorSample` and the Gardens/connector geometry in `HubFirstSetLayout`; the sample is not an interaction anchor. | No exact memorial or Sepulcher hero family was found. Road environment plates are scenic presentation and do not establish a memorial prop owner. Keep all six states unowned/deferred. |
| **Gate access** — `gate_access_panel`, `gate_lock_wheel`, `gate_threshold_strip`, `gate_status_lamp` (`awakening_interact_future_gate`) | Awakening's Gate of Dust remains sealed; no gate-control gameplay owner is posted. `gate_aperture` is a Layout marker, not an interactible. Add these only after a real gate owner and legal state transition are authorized. | Existing Gate of Dust scene/layout; no control mount is approved. | Asset V2 `gate_of_dust` reports its five required sealed-structure states present/imported, but those states are not a control panel, wheel, crossing action, or status owner. The recommended `awakening_interact_wayfinding.gate_aperture_access_face` is visual-only and does not authorize opening the Gate. No state-level substitution is approved. |
| **Shared future effects** — `route_trace` (`awakening_interact_shared_fx`) and `ash_drift` (`awakening_interact_shared_fx`) | No route-trace presentation owner or Sepulcher memorial presenter is posted. Existing route and Gate gameplay state must remain authoritative. | No new anchor established. | `district_transfer_frame.aperture_loop` is an existing imported transfer animation with a different canvas and consumer; it is an audit candidate, not an exact route-trace substitute. No ash effect is approved. These two deferred states are not among the six current required states in the registered `awakening_interact_shared_fx` family. |

## Packet and dependency map

The following posting state is verified from current-main packet files and the
dispatcher audit; a claim or unlanded branch is not treated as implemented:

- **Spatial foundation:** `hub-first-set-blockout-v1-recovery-1` is complete. It
  establishes Forum, Sepulcher, Crown, Muster, and Port geometry/markers only.
- **Forum owner:** `hub-forum-adjudication-contract-prewarm` and
  `review-hub-forum-adjudication-contract-prewarm` are archived complete. The
  Dais interaction is the only civic gameplay owner this crosswalk relies on.
- **Crown route:** `hub-crown-transfer-twin-solaria` and its paired review are
  archived complete. H4 owns the optional same-Hub Twin route; production
  Transfer Court art was explicitly deferred.
- **Ordinary Port:** `hub-muster-continuity-port-deployment` is ready/auto and
  has a published implementation claim, but is not complete on current main.
  `review-hub-muster-continuity-port-deployment` follows its landing;
  `hub-campaign-return` follows that review. H5/H6 are the future owner chain
  for departure/return through one Port.
- **Forum presentation:** `isometric-2-5d-forum-vertical-slice` is draft/manual;
  it cannot authorize a gameplay owner or production art.
- **Field Patch:** archived `OPERATOR_FIELD_PATCH_V1.md` owns the Operator
  mechanic and explicitly defers production pickup/restock art.

The H1 `HubFirstSetLayout` marker coordinates are useful placement context, not
per-prop registration or art approval. Later implementation packets must read
the landed H5/H6 APIs and current Hub/Twin/World Transition authorities before
assigning exact nodes, state ownership, or asset families.

## Art and promotion gates

Before any future state is promoted from this crosswalk:

1. Land and review the gameplay owner that consumes it, then name the actual
   scene node/state owner and measured mounting anchor. Do not create an owner
   solely to make a family appear complete.
2. Run Asset V2 `plan`, `status`, and `doctor` against the live candidate family
   and exact states. Reuse only when the approved role, pixels, registration,
   and state contract match. Similar names, complete family counts, or imported
   outputs do not prove this.
3. If no exact approved state exists, obtain a separate art decision and
   immutable Dropbox source package, verify checksums/dimensions/alpha, and use
   the Asset V2 intake path. Human visual approval remains required before
   published art replaces or supplements a live owner.
4. Only then update the art manifest and required-assets registry for a
   specifically authorized consumer. Keep every currently future-only state
   out of active demand until that gate is met.

The original [Asset Manifest](AWAKENING_ASSET_MANIFEST.md),
[Awakening scene authority](AWAKENING_FIRST_RETURN.md),
[Hub spatial authority](HUB_SPATIAL_LAYOUT.md),
[Hub first-set blockout](HUB_FIRST_SET_BLOCKOUT.md),
[Hub implementation roadmap](HUB_FIRST_SET_IMPLEMENTATION_ROADMAP.md),
[World Transition System](WORLD_TRANSITION_SYSTEM.md), and
[Twin Solaria authority](../05_levels/TWIN_SOLARIA.md) remain the owners of
their respective scene, route, spatial, and runtime contracts.
