# AWAKENING 04→05 PRODUCTION SOURCE SET + DIRECT CONNECTOR CORRECTION

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
- Reviewed main: `c5ba129967e0428702af95da476b8271f178efbe`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Goal: Replace the live Dust Lung underlay, 04→05 connector, and Locker Reliquary underlay with the exact three user-approved production source files now stored in Dropbox; preserve the complete connector silhouette; and register the connector correctly between the fixed Dust Lung and Locker Reliquary gameplay anchors.
- Completion boundary: Done when all three Dropbox inputs are hash-verified and preserved as source masters, each existing Asset V2 family publishes the intended runtime underlay state, the scene binds the resulting Dust/connector/Locker production art, the connector's final canvas/scale/position are derived from its complete source plus live room-contact geometry rather than the legacy 1024×576 plate, the old crop/reconstruction/feather path is no longer production authority, Locker foreground truth is reconciled rather than blindly overlaid on different composition, and forward/reverse traversal remains on the unchanged one-dogleg 04→05 gameplay footprint.
- Current measured state: Current main still binds the old crop-derived connector runtime plate and its historical registration. The user has now supplied the authoritative three-image production set directly in this chat and those exact bytes are uploaded to Dropbox. Dust Lung and Locker Reliquary room art are also part of this correction, not optional context. The P-9 Designation Locker itself has separately landed as a four-state specialized live prop on main and must remain gameplay/presentation authority for the active locker interaction rather than being baked/replaced by this room-underlay pass.
- Evidence: live `custodian/scenes/awakening_first_return.tscn`; `custodian/game/world/awakening/awakening_layout.gd`; current Asset V2 family contracts; Designation Locker reauthor landed at `81797b5a1`; Dropbox production inputs below; historical connector compositor `custodian/tools/assets/compose_awakening_connector_full_plate.py`.
- Task-specific authority: the exact Dropbox source bytes below own environment/connector pixels; `awakening_layout.gd` owns gameplay route anchors/footprint; the live specialized Designation Locker owns P-9 interaction state/presentation; Asset Pipeline V2 owns publication/catalog/runtime naming.
- Work surface: `custodian/content/metadata/assets/families/awakening_dust_lung_environment.asset.json`; `awakening_reliquary_dust_lung_connector.asset.json`; `awakening_locker_reliquary_environment.asset.json`; their source_work/inbox/runtime surfaces; `awakening_first_return.tscn`; narrow 04→05 visibility/z-order logic in `awakening_first_return.gd`; focused Asset V2 and Awakening validation.
- Change:
  1. **Fetch only the recorded Dropbox sources and fail closed on hash mismatch.** Do not substitute similarly named files from Downloads, stale source_work, old handoff ZIPs, or historical connector masters.
  2. **Dropbox source receipt:**
     - Dust Lung underlay: `/CUSTODIAN/implementation_inputs/awakening_dust_lung_underlay_source_v1.png`; Dropbox file id `id:8NXqdXuW6GUAAAAAAAACjg`; SHA-256 `fa017e6daa218d9a0713be760f19acdb285ae0c5e01854c3fe43126ca547f111`; 1216×1216 RGBA; 1 static frame; alpha 255 everywhere.
     - Direct 04→05 connector: `/CUSTODIAN/implementation_inputs/awakening_04_05_direct_connector_source_v1.png`; Dropbox file id `id:8NXqdXuW6GUAAAAAAAACjw`; SHA-256 `eb1dd930c6c084a3a9dce59ed57c5b0716730698daf88edbb197cceb08ffe721`; 1374×1076 RGBA; 1 static frame; 55.5367% nonzero/opaque alpha; nontransparent bounds touch the full source canvas.
     - Locker Reliquary underlay: `/CUSTODIAN/implementation_inputs/awakening_locker_reliquary_underlay_source_v1.png`; Dropbox file id `id:8NXqdXuW6GUAAAAAAAACkA`; SHA-256 `75e253f73f6570b72ed0b646648c2ba31902612c3241df82956b4d00ddd71a6c`; 1200×1211 RGBA; 1 static frame; 81.2404% nonzero/opaque alpha; nontransparent bounds touch the full source canvas.
  3. **Asset Pipeline V2 mapping and save names.**
     - Dust family/schema: `awakening_dust_lung_environment` / `custodian.asset_family.v2` / backdrop. Preserve exact Dropbox bytes at `custodian/asset_drop/source_work/awakening/awakening_dust_lung_environment/underlay_source.png`; stage runtime input as `custodian/asset_drop/inbox/awakening_dust_lung_environment/underlay.png`; target state `underlay`, 1216×1216, 1 frame.
     - Connector family/schema: `awakening_reliquary_dust_lung_connector` / `custodian.asset_family.v2` / backdrop. Preserve exact Dropbox bytes at `custodian/asset_drop/source_work/awakening/awakening_reliquary_dust_lung_connector/full_plate_underlay_source.png`; stage as `custodian/asset_drop/inbox/awakening_reliquary_dust_lung_connector/full_plate_underlay.png`; target state `full_plate_underlay`, 1 frame. The existing 1024×576 family canvas is historical and may be changed if required to preserve the full source silhouette.
     - Locker family/schema: `awakening_locker_reliquary_environment` / `custodian.asset_family.v2` / backdrop. Preserve exact Dropbox bytes at `custodian/asset_drop/source_work/awakening/awakening_locker_reliquary_environment/underlay_source.png`; stage as `custodian/asset_drop/inbox/awakening_locker_reliquary_environment/underlay.png`; target state `underlay`, 704×704 runtime canvas, 1 frame.
  4. **Preserve source history before replacement.** Any differing current source masters must be moved/preserved under a dated `pre_dropbox_source_set_20261007/` directory before writing the new exact masters. Do not overwrite the historical flattened connector `full_plate_source.png`.
  5. **Dust normalization.** Dust is already the exact family canvas 1216×1216; publish it without crop/stretch/regrade unless the live pipeline requires byte-preserving copy normalization metadata.
  6. **Connector normalization.** Preserve every nontransparent source pixel. No crop, no non-uniform stretch, no reconstruction from room strips. Prefer updating the existing connector family's canvas/frame size to the full 1374×1076 source and using uniform scene scale/translation for world registration. If another source-preserving representation is used, prove 100% silhouette survival. The old 1024×576 canvas and `(352,-2464)` center are not acceptance constraints.
  7. **Locker normalization.** Normalize 1200×1211 → 704×704 with uniform scale-to-fit and transparent centering/padding only; do not crop nontransparent edge pixels and do not non-uniformly stretch. Preserve the complete source composition. If the live Asset V2 implementation can instead preserve source resolution while maintaining the existing room-registration contract without breaking the foreground state, that is acceptable only with explicit underlay/foreground parity proof.
  8. **Locker foreground truth.** Do not blindly retain the old 704×704 Locker foreground over materially different underlay composition. Mechanically prove pixel/registration compatibility. If it does not match, unbind/mark that foreground not-ready through existing Asset V2/requirements truth rather than fabricating or repainting replacement pixels in this packet.
  9. **Designation Locker preservation.** Do not bake a second active P-9 locker into room behavior. Preserve the separately landed `awakening_designation_locker` closed/authorize_open/open_loaded/empty state machine, 8-frame 10 FPS opening, existing gameplay interaction, and current placement contract. Room art may visually contain architectural locker banks, but the specialized live P-9 prop remains the interactive designation locker.
  10. **Re-derive direct connector registration.** Recompute uniform connector scale and world translation against Locker exit `(704,-2272)`, Dust Lung entry `(0,-2656)`, and the exact one-dogleg walkable footprint currently represented by legacy `04_05_A/B/C` primitives. Use the approved connector's room-contact architecture as evidence. The old center may survive only if the new measurements independently reproduce it.
  11. **Direct binding only.** Bind the three canonical Asset V2 runtime outputs directly in `awakening_first_return.tscn`. Do not paste Dust/Locker strips into the connector. Do not reconstruct the connector from old A/B/C art.
  12. **Retire the truncation path.** Remove the old crop/room-strip/32px-feather compositor from production authority and remove retired connector outputs/imports only after proving no live consumer remains. Historical summaries/source provenance remain.
  13. **Opaque, stable 04↔05 handoff.** While the join is on screen, Dust/connector/Locker underlays remain readable and do not depend on whole-room partial-alpha dissolve. Connector underlay remains below room underlays and below Operator/world props.
  14. **Bidirectional proof.** Reuse/add one deterministic Dust Lung → single connector → Locker Reliquary → same connector reverse → Dust Lung scenario. Prove complete connector silhouette, correct placement, no missing chunk/card edge, stable room contacts, and identical forward/reverse registration.
  15. **Docs.** Update current-state/index/design/runtime-ingest claims with the exact Dropbox hashes, realized Asset V2 job IDs, final connector canvas/transform, Locker foreground disposition, and scene bindings.
- Preserve: exact 04→05 walkable dogleg and thresholds; Zone04/Zone05 gameplay envelopes/anchors; specialized Designation Locker behavior/placement; camera/progression; unrelated Awakening art and mechanics.
- Non-goals: No new/generated environment art; no P-9 gameplay redesign; no 05→06 spine implementation; no prompt/console-feedback implementation; no Hub work.
- Acceptance:
  - All three runtime sources trace to the exact Dropbox paths/hashes above.
  - Dust runtime underlay is the supplied production image at its existing 1216×1216 family contract.
  - Locker runtime underlay derives from the supplied 1200×1211 source with uniform, crop-free normalization; the old foreground is either proven compatible or truthfully unbound/not-ready.
  - Connector publication preserves 100% of its nontransparent source silhouette and the previously missing architectural chunk is present.
  - Connector family/runtime canvas and scene transform are measured outputs, not inherited 1024×576/`(352,-2464)` assumptions.
  - Registration hits both authored room contacts while gameplay dogleg geometry remains unchanged.
  - Specialized Designation Locker still presents all four states and grants P-9 exactly once with unchanged gameplay semantics.
  - Forward/reverse traversal is visually/structurally equivalent and no whole-room fade masks the join.
  - Asset V2 status/doctor are healthy for all three families; scene/catalog/runtime all reference the same realized states.
- Validation: Inspect live `asset.py --help`; plan/ingest-or-replace/status/doctor all three families; source-hash receipts; connector source-vs-runtime full-silhouette assertion; Locker crop-free normalization/foreground-parity assertion; Designation Locker focused smoke; Awakening scene/geometry/progression; bidirectional 04→05 scenario; changed-file validation; `git diff --check`.
- Task overrides: `none`
- Deferred: new Locker foreground art if mechanically incompatible; 05→06 lower→upper spine; interaction-feedback/console activation; full 01→10 convergence.
