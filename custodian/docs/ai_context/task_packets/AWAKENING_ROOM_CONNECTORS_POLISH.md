# AWAKENING 04→05 DIRECT CONNECTOR CORRECTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-room-connectors-polish`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `awakening-runtime, awakening-art-registration, awakening-04-05-connector-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Paired review workstream: `review-awakening-room-connectors-polish`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `0332e00a895a69b306fe3f90904582be2ccc55f4`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Goal: Replace the live 04→05 Reliquary↔Dust Lung connector with the exact user-approved `~/Downloads/connector.png`, preserve its complete alpha silhouette without cropping away the missing western/lower architectural chunk, and register the resulting connector at the correct world transform against the fixed Locker Reliquary and Dust Lung anchors.
- Completion boundary: Done when the direct approved connector source is provenance-recorded, Asset V2 publishes a source-preserving runtime state, the scene binds only that state, the final canvas/scale/position are derived from the approved source plus live room-contact geometry rather than inherited from the legacy 1024×576 plate, the entire nontransparent connector silhouette is present in runtime, forward/reverse traversal remains on the unchanged 04→05 dogleg, and the old crop/reconstruction/feather path is no longer production authority.
- Current measured state: Current `main` still binds `awakening_reliquary_dust_lung_connector_full_plate_underlay_1024x576.png` as `Connector04_05_Underlay` at world `(352,-2464)`. That plate descends from the older flattened/cropped connector pipeline and is not the user's current approved direct `connector.png`. The user has now re-confirmed the live result is wrong in two concrete ways: the connector is not placed at the correct registration and an authored chunk is still missing. Therefore the legacy `1024×576 @ (352,-2464)` canvas/transform is historical evidence only, not an acceptance constraint. The runtime route itself remains one dogleg from Locker exit `(704,-2272)` to Dust Lung entry `(0,-2656)`.
- Evidence: live `custodian/scenes/awakening_first_return.tscn`; `custodian/game/world/awakening/awakening_layout.gd`; family `awakening_reliquary_dust_lung_connector`; historical `AWAKENING_RELIQUARY_DUST_LUNG_CONNECTOR_CLAUDE_SUMMARY.md`; historical compositor `custodian/tools/assets/compose_awakening_connector_full_plate.py`; user-approved local source `~/Downloads/connector.png`.
- Task-specific authority: the exact local `connector.png` bytes for connector pixels; `awakening_layout.gd` for gameplay route anchors/footprint; current Dust Lung and Locker Reliquary room transforms for registration; Asset Pipeline V2 for publication/catalog/runtime naming.
- Work surface: `custodian/content/metadata/assets/families/awakening_reliquary_dust_lung_connector.asset.json`; `custodian/asset_drop/source_work/awakening/awakening_reliquary_dust_lung_connector/`; `custodian/asset_drop/inbox/awakening_reliquary_dust_lung_connector/`; `custodian/scenes/awakening_first_return.tscn`; the narrow 04→05 presentation logic in `awakening_first_return.gd`; focused Awakening/Asset V2 validation and one bidirectional connector scenario.
- Change:
  1. **Fail closed on the correct source only.** Require `~/Downloads/connector.png`. Do not block this correction on `dust.png`, `locker.png`, the active Downloads intake sweep, Attestation/Reliquary fixture ZIPs, or any unrelated asset package.
  2. **Receipt before mutation.** Record SHA-256, pixel dimensions, color mode, alpha coverage, and nontransparent bounding box. Preserve the exact source under `custodian/asset_drop/source_work/awakening/awakening_reliquary_dust_lung_connector/full_plate_underlay_source.png`, preserving any different prior file under a dated `pre_direct_connector_correction_20261007/` directory.
  3. **No destructive normalization.** The complete nontransparent source silhouette is mandatory. Never crop a nontransparent source pixel to satisfy the old 1024×576 contract. Never non-uniformly stretch. Transparent padding and uniform scaling are allowed only when required by runtime registration. If the current family canvas cannot contain the approved silhouette at the correct world scale, update the existing family contract/canvas through Asset V2 rather than amputating the source. The actual local file dimensions are authoritative; do not substitute remembered dimensions.
  4. **Re-derive registration.** Recompute the connector's uniform scale and world translation against the live fixed anchors: Locker exit `(704,-2272)`, Dust Lung entry `(0,-2656)`, and the exact one-dogleg walkable footprint currently represented by the legacy `04_05_A/B/C` primitives. Use the approved connector's room-contact/architectural overlap, not the old sprite center, as registration evidence. The old center `(352,-2464)` may survive only if the new measurements independently reproduce it.
  5. **Direct binding only.** Publish/replace the existing family's `full_plate_underlay` state through Asset V2 and bind that canonical runtime output directly in `awakening_first_return.tscn`. Do not paste Dust/Locker room strips into it. Do not reconstruct the silhouette from legacy A/B/C art.
  6. **Retire the truncation path.** Remove the old crop/room-strip/32px-feather compositor from production authority and remove retired three-piece connector outputs/imports only after proving no live consumer remains. Historical source and summaries remain provenance.
  7. **Opaque, stable handoff.** While the 04↔05 join is on screen, connector and room underlays remain fully opaque; no whole-room partial-alpha dissolve may hide the correction. Connector underlay remains below room underlays and below Operator/world props.
  8. **Bidirectional proof.** Reuse or add one deterministic Dust Lung → connector → Locker Reliquary → same connector reverse → Dust Lung scenario. Prove the full connector texture/silhouette remains visible through both turns, no missing corner/segment appears, no rectangular card edge appears, and forward/reverse registration is identical.
  9. **Docs.** Update current-state/index/design claims that still describe the old connector canvas/center/feather contract as current. Record the new measured canvas and transform only after implementation.
- Preserve: exact 04→05 walkable dogleg and thresholds; Zone04/Zone05 gameplay envelopes; Dust Lung and Locker room anchors; P-9 state machine and placement; camera/progression; other Awakening art.
- Non-goals: No Dust Lung underlay replacement; no Locker Reliquary room-art replacement; no P-9 redesign; no 05→06 work; no generated/AI art; no Hub work.
- Acceptance:
  - Runtime source provenance matches the exact `~/Downloads/connector.png` hash recorded at execution.
  - 100% of nontransparent source pixels survive normalization/publication; alpha-bound comparison proves no source silhouette was cropped.
  - The family/runtime canvas and scene transform are measured outputs, not inherited 1024×576/`(352,-2464)` assumptions.
  - The approved connector visibly contains the previously missing architectural chunk and no legacy crop/reconstruction output is scene-bound.
  - Registration hits both authored room contacts while the gameplay dogleg footprint remains byte-for-byte/geometrically unchanged.
  - Forward and reverse traversal are visually/structurally equivalent and no visible partial-alpha room dissolve obscures the join.
  - Asset V2 status/doctor are healthy and scene/catalog/runtime all reference the same family state.
- Validation: Inspect live `asset.py --help`; run plan/replace-ingest/status/doctor for `awakening_reliquary_dust_lung_connector`; add a source-vs-runtime alpha-bound/full-silhouette assertion; run `awakening_first_return_smoke.gd`, geometry, progression, and the focused bidirectional connector scenario; run changed-file validation and `git diff --check`.
- Task overrides: `none`
- Deferred: Dust/Locker room-art refresh remains separate; complete 05→10 seam/handoff convergence remains downstream.
