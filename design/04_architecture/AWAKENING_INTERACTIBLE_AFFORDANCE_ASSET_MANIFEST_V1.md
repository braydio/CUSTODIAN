# Awakening Interactible Affordance Overlay V1 — Required Artwork Manifest

**Authority:** supplementary art/presentation contract, not an interaction/spatial authority.
**Workstream:** `awakening-interactible-affordance-overlay-v1`
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d
**Base inspected:** `main@afb1f1c5f145fec42f9a3f5a492ab31d5ffc138d`
**Machine-readable state ledger:** [AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.json](AWAKENING_INTERACTIBLE_AFFORDANCE_ASSET_MANIFEST_V1.json) (source plan only, NOT a V2 published-status claim)
**Status:** artwork manifest locked for source creation; all new files SOURCE_PENDING. No generated art is represented as available.

## Main overlay, scope, and gameplay truth

**Main overlay:** a per-zone **Interactible Affordance Presentation** child/binding under existing Awakening zone `Interactables`/`SetPieces` nodes, keyed to existing `AwakeningLayout.MARKERS` identity and bound to the canonical interaction node. It supplies three presentation layers: (1) legible distance silhouette, (2) local floor/backplate/dressing footprint, and (3) near-range subtle active indicator/FX. No new interaction owner, collider, route, objective, or transfer is created by painting a prop.

**Current actual interaction owners:** Crèche Console (`zone01_creche.creche_console`, `CrecheConsole`), P-9 Designation Locker (`zone04_locker_reliquary.p9_locker`, scene `SidearmLocker`), Dust Lung Lift (two stations `lift_lower`/`lift_upper`, one `TransitLift` runtime owner), and damaged Port Console (`zone06_undergate.port_status_plaque`, `PortStatusPlaque`).
**Important drift:** `lift_mechanism` marker is `kind=interactable` in Layout but `_build_interactables()` does **not** create a distinct mechanism interaction owner. Audit/reclassify only on semantic evidence; never advertise a live control that is inert. `lore_plaque`, `attestation_dais`, `register_of_departures`, `rest_checkpoint`, `gate_aperture`, `reward_cache` and other markers are not currently equivalent to live interactibles. Future transfer/Continuity Port, Witness/Forum/Adjudication, Sepulcher, supply and gate-control art is **deferred** rather than falsely described as present in Awakening 01–10.

**Existing visual sources to preserve**: `awakening_creche_console`, `awakening_designation_locker` (4-state), `awakening_dust_lung_lift` (1 state), `gate_of_dust` (sealed components), existing room underlays/foregrounds/registered 04→05 composite and `awakening_creche_console_activation_fx`. New families complement them and must not overpaint or replace them without evidence that the existing role cannot be retained.

**Projection/style:** CUSTODIAN high-detail 2.5D aerial-oblique/angled top-down, weathered Gothic-civic institutional stone, graphite ceramic-metal, dulled brass/ochre authority inlays, restrained teal/cyan information and amber authorization. Tight pixel-detail registration; real RGBA transparent exterior; no painted background, nonuniform stretch, soft photo-real blur, free-floating generic sci-fi kiosk, bright neon, or fake icons. Lighting/illumination should be local and low-energy; never make the screen or emissive halo into unreadable bloom.

## Authoring/Asset V2 rule

`kind=world_prop` for static art; `kind=effect` for animated overlay states. Each family: `custodian/content/metadata/assets/families/<family_id>.asset.json`, runtime owner `<family_id>`, runtime domain under `sprites/environment/props/awakening` (static) or `sprites/effects/awakening` (FX), `direction_policy=omni`, `auto_mirror=false`. Inspect the current live schema and derive supported state metadata; do not paste this manifest as a family JSON schema. **All new sources**: `custodian/asset_drop/source_work/awakening/<family_id>/<state_id>_source.png`; **normalized intake**: `custodian/asset_drop/inbox/<family_id>/<state_id>.png`; Asset V2 alone owns generated runtime filenames. Every listed state is one-layer body (world_prop) or fx (effect), `variant=state_id`; action_group=affordance for world_prop and effect for FX. Required vs recommended vs deferred below. Register required currently missing art in `custodian/content/metadata/assets/required_assets.registry.json`, regenerate `REQUIRED_ASSETS.md`; do not manufacture success. Never block foundation on art; gate runtime binding for a family on true verified source availability.

**Motion geometry:** a 1-frame asset is a static PNG at the dimensions listed. Animated rows use **horizontal Nx1 strips** where `frame` is the listed W×H; total PNG is `(W*N)×H`; FPS shown; `loop=true` for loops. All images require true exterior alpha; no frame bleed; lighting effects register to stationary prop pivots and may have soft emissive alpha only within clean bounds.

## Complete state-level specification

| Asset V2 family | State | Class | Frame px | Frames | Total PNG px | FPS | Requirement | Art/role |
|---|---|---|---:|---:|---:|---:|---|---|
| `awakening_interact_support` | `floor_pad_01` | world_prop | 64×64 | 1 | 64×64 | – | required | neutral access inset |
| `awakening_interact_support` | `floor_pad_02` | world_prop | 64×64 | 1 | 64×64 | – | recommended | alternate cracked access inset |
| `awakening_interact_support` | `beacon_cyan` | world_prop | 64×64 | 1 | 64×64 | – | required | information/control beacon |
| `awakening_interact_support` | `beacon_amber` | world_prop | 64×64 | 1 | 64×64 | – | required | authorization/storage beacon |
| `awakening_interact_support` | `cable_bundle` | world_prop | 64×64 | 1 | 64×64 | – | recommended | gothic-civic cable dressing |
| `awakening_interact_support` | `service_crate` | world_prop | 64×64 | 1 | 64×64 | – | recommended | utility dressing, collision-free |
| `awakening_interact_support` | `wall_backplate` | world_prop | 128×128 | 1 | 128×128 | – | required | shared relief/frame adapter |
| `awakening_interact_support` | `status_pole` | world_prop | 64×96 | 1 | 64×96 | – | recommended | world-space status beacon mounting |
| `awakening_interact_terminal` | `console_pedestal` | world_prop | 96×128 | 1 | 96×128 | – | required | console body with readable reachable face, complement existing crèche art without replacing it |
| `awakening_interact_terminal` | `console_wall` | world_prop | 96×128 | 1 | 96×128 | – | required | wall console variant for damaged Port status, not a freestanding duplicate |
| `awakening_interact_terminal` | `console_backplate` | world_prop | 128×128 | 1 | 128×128 | – | required | heavy slab housing, cable service joint |
| `awakening_interact_terminal` | `screen_glow` | world_prop | 64×64 | 1 | 64×64 | – | required | quiet teal display authority |
| `awakening_interact_terminal` | `console_floor_pad` | world_prop | 128×64 | 1 | 128×64 | – | required | floor approach locus |
| `awakening_interact_terminal` | `console_cables` | world_prop | 64×96 | 1 | 64×96 | – | recommended | concealed service bundle |
| `awakening_interact_locker` | `reliquary_plinth` | world_prop | 128×64 | 1 | 128×64 | – | required | shallow relief footing to match wall recess |
| `awakening_interact_locker` | `reliquary_sconce` | world_prop | 64×96 | 1 | 64×96 | – | required | warm authority lamp; no false inventory |
| `awakening_interact_locker` | `reliquary_insignia` | world_prop | 64×96 | 1 | 64×96 | – | required | designation marker/brass seal |
| `awakening_interact_locker` | `reliquary_floor_inset` | world_prop | 128×64 | 1 | 128×64 | – | required | accessible pickup approach reading |
| `awakening_interact_locker` | `reliquary_latch_detail` | world_prop | 64×64 | 1 | 64×64 | – | recommended | wall latch/cable continuation |
| `awakening_interact_lift` | `station_call_lower` | world_prop | 96×128 | 1 | 96×128 | – | required | lower lift call housing, aligned with lower station |
| `awakening_interact_lift` | `station_call_upper` | world_prop | 96×128 | 1 | 96×128 | – | required | upper lift call housing, aligned with upper station |
| `awakening_interact_lift` | `station_floor_stop` | world_prop | 128×64 | 1 | 128×64 | – | required | service lane landing stop |
| `awakening_interact_lift` | `station_light` | world_prop | 64×96 | 1 | 64×96 | – | required | cold functional status lamp |
| `awakening_interact_lift` | `station_lever_dressing` | world_prop | 128×128 | 1 | 128×128 | – | recommended | reuse/bind existing lift lever art if it genuinely satisfies role |
| `awakening_interact_port` | `damaged_status_body` | world_prop | 128×160 | 1 | 128×160 | – | required | damaged readable port status console, not operational gate |
| `awakening_interact_port` | `route_registry_backplate` | world_prop | 128×128 | 1 | 128×128 | – | required | route readout housing |
| `awakening_interact_port` | `damaged_floor_inset` | world_prop | 128×64 | 1 | 128×64 | – | required | approach and cable groove |
| `awakening_interact_port` | `port_status_beacon` | world_prop | 64×96 | 1 | 64×96 | – | required | weak failing status glow |
| `awakening_interact_port` | `port_conduit` | world_prop | 96×128 | 1 | 96×128 | – | recommended | service route cable trunk |
| `awakening_interact_wayfinding` | `register_of_departures_marker` | world_prop | 96×160 | 1 | 96×160 | – | recommended | register display, *marker only* until gameplay owner exists |
| `awakening_interact_wayfinding` | `gate_rest_marker` | world_prop | 128×128 | 1 | 128×128 | – | recommended | Gate checkpoint readable floor orientation, not new checkpoint mechanic |
| `awakening_interact_wayfinding` | `gate_aperture_access_face` | world_prop | 96×128 | 1 | 96×128 | – | recommended | dormant access face, not open gate control |
| `awakening_interact_wayfinding` | `lore_plaque_frame` | world_prop | 96×128 | 1 | 96×128 | – | recommended | lore plaque frame, marker only unless a readout is explicitly wired |
| `awakening_interact_wayfinding` | `attestation_dais_read` | world_prop | 128×128 | 1 | 128×128 | – | recommended | dais/authority role preview, marker only |
| `awakening_interact_wayfinding` | `chapel_reliquary_marker` | world_prop | 128×128 | 1 | 128×128 | – | recommended | optional chapel presentation, no implicit interaction |
| `awakening_interact_shared_fx` | `indicator_blink` | effect | 64×64 | 6 | 384×64 | 6 | required | dim indicator 6f loop |
| `awakening_interact_shared_fx` | `glow_pulse` | effect | 64×64 | 8 | 512×64 | 8 | required | contained emissive 8f loop |
| `awakening_interact_shared_fx` | `terminal_scan` | effect | 64×64 | 8 | 512×64 | 8 | required | subtle screen activity loop |
| `awakening_interact_shared_fx` | `reliquary_breath` | effect | 64×64 | 8 | 512×64 | 8 | required | warm brass breathing loop |
| `awakening_interact_shared_fx` | `lift_ready` | effect | 64×64 | 6 | 384×64 | 6 | required | station status flicker |
| `awakening_interact_shared_fx` | `port_failing` | effect | 64×64 | 8 | 512×64 | 8 | required | failing port flicker, no fake operational state |
| `awakening_interact_shared_fx` | `ash_drift` | effect | 64×64 | 8 | 512×64 | 8 | deferred | memorial ash in optional future space |
| `awakening_interact_shared_fx` | `route_trace` | effect | 128×128 | 8 | 1024×128 | 8 | deferred | future civic transfer registration trace |
| `awakening_interact_future_transfer` | `transfer_control_post` | world_prop | 64×128 | 1 | 64×128 | – | deferred | crown/transfer control |
| `awakening_interact_future_transfer` | `transfer_threshold_medallion` | world_prop | 128×128 | 1 | 128×128 | – | deferred | transfer floor medallion |
| `awakening_interact_future_transfer` | `transfer_beacon_pair` | world_prop | 128×160 | 1 | 128×160 | – | deferred | paired transfer lamps |
| `awakening_interact_future_transfer` | `transfer_cable_spine` | world_prop | 128×128 | 1 | 128×128 | – | deferred | transfer cable service |
| `awakening_interact_future_transfer` | `transfer_registry_panel` | world_prop | 96×128 | 1 | 96×128 | – | deferred | authoritative registry panel |
| `awakening_interact_future_transfer` | `transfer_seal_frame` | world_prop | 128×160 | 1 | 128×160 | – | deferred | seal frame |
| `awakening_interact_future_transfer` | `continuity_port_pylon` | world_prop | 96×160 | 1 | 96×160 | – | deferred | future continuity port pylon |
| `awakening_interact_future_transfer` | `continuity_port_gate_frame` | world_prop | 256×256 | 1 | 256×256 | – | deferred | future port gate |
| `awakening_interact_future_transfer` | `continuity_port_floor_lane` | world_prop | 128×64 | 1 | 128×64 | – | deferred | egress lane |
| `awakening_interact_future_transfer` | `continuity_port_control_terminal` | world_prop | 96×128 | 1 | 96×128 | – | deferred | future port control |
| `awakening_interact_future_transfer` | `continuity_port_beacon` | world_prop | 64×96 | 1 | 64×96 | – | deferred | egress beacon |
| `awakening_interact_future_transfer` | `continuity_port_signage` | world_prop | 96×96 | 1 | 96×96 | – | deferred | egress signage |
| `awakening_interact_future_civic` | `witness_lectern` | world_prop | 96×128 | 1 | 96×128 | – | deferred | witness civic lectern |
| `awakening_interact_future_civic` | `witness_seal_floor` | world_prop | 128×128 | 1 | 128×128 | – | deferred | authority seal |
| `awakening_interact_future_civic` | `adjudication_plinth` | world_prop | 128×128 | 1 | 128×128 | – | deferred | adjudication |
| `awakening_interact_future_civic` | `adjudication_light_pair` | world_prop | 128×128 | 1 | 128×128 | – | deferred | ritual lamp pair |
| `awakening_interact_future_civic` | `forum_record_pillar` | world_prop | 96×160 | 1 | 96×160 | – | deferred | record pillar |
| `awakening_interact_future_civic` | `registry_brass_plate` | world_prop | 96×96 | 1 | 96×96 | – | deferred | inscribed authority plate |
| `awakening_interact_future_supply` | `supply_station_frame` | world_prop | 128×160 | 1 | 128×160 | – | deferred | service frame |
| `awakening_interact_future_supply` | `supply_station_tray` | world_prop | 128×64 | 1 | 128×64 | – | deferred | supply tray |
| `awakening_interact_future_supply` | `supply_patch_canister` | world_prop | 64×96 | 1 | 64×96 | – | deferred | field patch carrier |
| `awakening_interact_future_supply` | `supply_cabinet` | world_prop | 128×160 | 1 | 128×160 | – | deferred | cabinet |
| `awakening_interact_future_supply` | `supply_floor_marking` | world_prop | 128×64 | 1 | 128×64 | – | deferred | resource safety inset |
| `awakening_interact_future_supply` | `supply_task_light` | world_prop | 64×96 | 1 | 64×96 | – | deferred | status task lamp |
| `awakening_interact_future_memorial` | `sepulcher_plinth` | world_prop | 128×128 | 1 | 128×128 | – | deferred | memorial plinth |
| `awakening_interact_future_memorial` | `sepulcher_marker` | world_prop | 96×160 | 1 | 96×160 | – | deferred | record marker |
| `awakening_interact_future_memorial` | `sepulcher_sconce` | world_prop | 64×96 | 1 | 64×96 | – | deferred | low devotional light |
| `awakening_interact_future_memorial` | `sepulcher_ash_basin` | world_prop | 96×96 | 1 | 96×96 | – | deferred | ash basin |
| `awakening_interact_future_memorial` | `sepulcher_floor_ring` | world_prop | 128×128 | 1 | 128×128 | – | deferred | memorial floor ring |
| `awakening_interact_future_memorial` | `sepulcher_inscription` | world_prop | 128×128 | 1 | 128×128 | – | deferred | record inscription |
| `awakening_interact_future_gate` | `gate_access_panel` | world_prop | 96×128 | 1 | 96×128 | – | deferred | access station, only if real gate owner |
| `awakening_interact_future_gate` | `gate_lock_wheel` | world_prop | 96×96 | 1 | 96×96 | – | deferred | manual emergency lock |
| `awakening_interact_future_gate` | `gate_threshold_strip` | world_prop | 128×64 | 1 | 128×64 | – | deferred | crossing strip |
| `awakening_interact_future_gate` | `gate_status_lamp` | world_prop | 64×96 | 1 | 64×96 | – | deferred | gate status beacon |

## Production bundles / individual gating
- **Core shared + Crèche/Port**: `awakening_interact_support`, `awakening_interact_terminal`, `awakening_interact_port`, `awakening_interact_shared_fx` live-required states. Gate **only** their visual consumers until the exact required states are Dropbox-published, checksum-matched, Asset V2 ingested/bound/verified and human-reviewed. Can implement presentation host/contracts beforehand.
- **Locker + Lift**: `awakening_interact_locker`, `awakening_interact_lift`, and shared live FX. Gate only those visual consumers. Preserve existing interactive four-state locker and traveling lift.
- **Markers and waypoint dressing**: `awakening_interact_wayfinding` states are recommended, never falsely mark `kind=interactable` or show an interaction cue without a real owner. Their integration is optional and art-gated, but actual interactible correctness is not gated by optional dressing.
- **Future-only**: `awakening_interact_future_transfer`, `awakening_interact_future_civic`, `awakening_interact_future_supply`, `awakening_interact_future_memorial`, `awakening_interact_future_gate`, and deferred FX are **not** claimable implementation demand for Awakening 01–10. Preserve design lock and require separate posting/ownership decisions later. Hub assets belong to Hub implementation paths when their existing assets/contracts are known; names here are provisional family IDs, not authorization to duplicate an existing Hub family.

## Source package and Dropbox proof
Durable approved batch should be published to `/CUSTODIAN/asset_batches/awakening-interactible-affordances/<batch_id>/` with `MANIFEST.json`, `CODEX_IMPLEMENTATION.md`, `README.md`, `CHECKSUMS.sha256`, source-work PNGs, exact state sizes/frames/alpha, and a Dropbox `_registry` receipt. Human design and gameplay-scale placement approval required before art-gated packet promotion. Availability means **exact verified state and file**; a Dropbox folder alone does not prove a state is ready. Where existing published art already fulfills the role, allow a documented zero-new-art substitution and update the manifest/tracker accordingly.

## Visual behavior lock
- Long read: real console/lift/locker/port physical silhouette, not prompt text appearing out of nowhere.
- Mid read: floor access geometry and mount/cables align with baked room art/geometry. 2–3 tile accommodation on Dust side of Locker→Dust connector is allowed only in presentation and cannot undo accepted shared composition or existing route authority.
- Near read: subtle 0.8–1.4 s pulse or 1-2 Hz status lamp, with clear unavailable/used states. HUD hint is confirmation, not discovery. Focal glows dim during other UI/context without creating new prompt authority.
- No fake interactables at unused markers. No collision/nav expansion. No halo over the Operator or walls. No off-camera/missing-art warnings per frame. Existing asset family names and source masters remain untouched.

## Human proof and acceptance
Single fixed-camera playback set at Crèche, Locker, lower/upper lift, Undergate port; normal and dim lighting, unprompted mid distance and actionable near distance. Reviewer should identify each functional object without HUD labels. Distinguish visual-only markers from real interactibles. Return visual decision to the authoring chat and record it with the relevant implementation packet. Family doctor/status + checksum/provenance + geometry/reachability/occlusion validations must pass. 

**Inventory:** 77 planned state images in 12 families: 27 currently-required live, 14 recommended marker/dressing, 36 deferred future. This count is *planning demand*, not evidence that art exists.
