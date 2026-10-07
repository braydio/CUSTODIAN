# AWAKENING 04→05 REGISTERED COMPOSITION CORRECTION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-04-05-registered-composition-correction-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-awakening-interaction-feedback-console-activation`
- Locks: `awakening-runtime, awakening-art-registration, awakening-04-05-connector-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Paired review workstream: `review-awakening-04-05-registered-composition-correction-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `1ad7b48267cd7fd2b2e72968e42eb9a019cecbf2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Goal: Replace the independently fitted/rotated Dust Lung ↔ connector ↔ Locker Reliquary presentation with the user's exact precomposed three-layer registration. Preserve the supplied relative layout exactly; do not solve the connector as a separate anchor-fitting problem.
- Completion boundary: Done when the three production layers reproduce the supplied 1502×2048 composition with one shared coordinate basis, zero per-piece rotation, exact layer bounds/overlaps/order, and no independent Dust/Locker/connector normalization that changes their relative registration. Gameplay geometry and the specialized Designation Locker remain unchanged.
- Current measured state: The reviewed implementation at `bb4478fbca7181b4a8e0f5ce4e583e7e2b214a03` is technically self-consistent but visually wrong against newer direct authoring evidence. It binds Dust at its independent 1216×1216 room registration, Locker independently normalized to 704×704, and the connector at `position=(351.821,-2392.391)`, `scale=0.715951`, `rotation=-0.198826 rad` (-11.391598°). The user-provided registration exports prove those independent transforms are unnecessary and incorrect: Dust, connector, and Locker were authored to fit together already on one axis-aligned 1502×2048 canvas.
- Evidence: authoring-chat reference images supplied 2026-10-07; current runtime screenshots showing the rotated/misaligned join; archived `AWAKENING_ROOM_CONNECTORS_POLISH.md` and review receipt; live `awakening_first_return.tscn`; existing three Asset V2 families and exact Dropbox raw source receipts.
- Task-specific authority: the 1502×2048 registered composition geometry below owns relative art placement; existing Dropbox source masters own source pixels; `awakening_layout.gd` remains gameplay geometry authority; the specialized `awakening_designation_locker` remains P-9 interaction/presentation authority.
- Work surface: `custodian/scenes/awakening_first_return.tscn`; the three existing environment/connector Asset V2 families only if their runtime representation must change; narrow Awakening presentation visibility/z-order code; focused registration validation; active docs describing the now-superseded rotated connector transform.
- Change:
  1. **Treat the supplied composition as placement authority, not inspiration.** Do not independently fit any of the three art pieces to room/connector gameplay anchors.
  2. **Exact shared reference canvas:** every reference export is RGBA `1502×2048` with the same top-left origin `(0,0)`.
     - composed reference SHA-256: `521beec078b9c3dfb3d694d134258c6a77d0db64e3ce4cc8a71491efff8c9383`
     - Dust-only reference SHA-256: `fa8637992bfc0b1ff1b0d009fbe463e098a4adbfe97031c67d2276d2fe94172e`
     - connector-only reference SHA-256: `489b49615ba53b0073519d5a261f736321ba69b95019bb54ec02ff408a9ffd76`
     - Locker-only reference SHA-256: `76cc103eda059974f8f279e8e4e10fdb1b388030ea26f2a7b659075c45ceb48d`
  3. **Exact nontransparent layer bounds on that shared canvas:**
     - Dust Lung: `x=[0,870), y=[0,838)` → 870×838; cropped-layer center `(435,419)`.
     - Connector: `x=[258,1300), y=[672,1256)` → 1042×584; cropped-layer center `(779,964)`.
     - Locker Reliquary: `x=[644,1502), y=[1182,2048)` → 858×866; cropped-layer center `(1073,1615)`.
     - Shared-canvas center is `(751,1024)`. If runtime uses losslessly cropped layer textures under one centered root, their exact local center offsets are Dust `(-316,-605)`, connector `(28,-60)`, Locker `(322,591)`.
  4. **Exact overlap/order contract:**
     - bottom→top draw order: Dust Lung, connector, Locker Reliquary.
     - Dust↔connector nonzero-alpha overlap: 17,979 pixels, overlap bounds `(261,672)-(598,838)`.
     - connector↔Locker nonzero-alpha overlap: 10,979 pixels, overlap bounds `(837,1182)-(1300,1256)`.
     - Dust↔Locker alpha overlap: none.
     - Alpha-compositing the three registered reference layers in that order reproduces the supplied composed reference except 1,267 antialiased edge pixels (mean absolute channel error ≈0.0018); treat that as export-edge noise, not layout freedom.
  5. **No per-piece rotation.** Connector `rotation=-0.198826` is explicitly superseded. Dust, connector, and Locker must each be axis-aligned relative to the shared art root. Per-piece rotation must be exactly zero.
  6. **No independent normalization.** The previous Dust-native / Locker-704 / connector-anchor-fit strategy is retired. Use one shared composition transform. Runtime may either:
     - retain full 1502×2048 registered layer canvases with identical transform, or
     - losslessly crop each registered layer to the exact bounds above and preserve the exact local offsets/order.
     Do not recenter a cropped texture without restoring its offset.
  7. **Single shared world transform only.** The three layers may receive one common root translation and, if required by the scene's world-to-art scale, one common uniform root scale. Do not rotate, skew, or scale layers independently. Determine that one root transform from the live scene as a group and validate the entire composition against gameplay. If old room anchors cannot be visually reconciled without breaking the supplied composition, preserve the composition and report the residual geometry mismatch rather than distorting a layer.
  8. **Use existing raw masters only as pixel sources.** The Dropbox Dust/connector/Locker masters remain provenance, but their scene transforms are not authority. If rebuilding registered layer outputs from those masters, the result must reproduce the exact shared-canvas bounds/overlaps/order above. Do not use the prior connector contact-fit rotation.
  9. **Connector masking/overlap truth.** Do not expose raw-master overlap pixels that the registered connector-only reference excludes. The visible connector layer must match the registered connector extent/overlap contract, including the full previously missing architectural chunk.
  10. **Foreground handling.** Keep the current truthful Locker foreground deferral unless a foreground can be transformed into the same shared registration and proven compatible. Dust foreground may remain only if it follows the same Dust shared transform and does not break the composite seam.
  11. **Preserve P-9.** The separately reauthored Designation Locker remains the only active P-9 interactive prop and retains its four states, 8-frame/10 FPS opening, grant-once semantics, and existing gameplay location.
  12. **Validation fixture.** Add one deterministic registration check that records the three effective runtime art rectangles in shared-composition coordinates and fails on any nonzero connector rotation, wrong bounds, wrong layer ordering, or lost overlap. Add a compact renderer capture spanning all three pieces and compare against the supplied composition geometry.
  13. **Bidirectional traversal.** Re-run Dust Lung → connector → Locker → connector → Dust Lung using the unchanged gameplay path and prove the Operator remains on visible floor through the entire join.
  14. **Docs drift.** Replace all active claims that `scale=0.715951, rotation=-11.391598°, center=(351.821,-2392.391)` is accepted/current design truth. Preserve those values only in historical implementation/review evidence.
- Preserve: exact source pixels; exact registered three-layer relative layout; existing 04→05 gameplay/collision unless a separate evidence-backed geometry packet is required; Designation Locker behavior; other Awakening systems.
- Non-goals: No new/generated art; no 05→06 spine work; no HUD/console feedback work; no P-9 redesign; no broad Awakening convergence; no opportunistic room-layout redesign.
- Acceptance:
  1. Runtime Dust/connector/Locker presentation uses one shared registration basis and matches the exact 1502×2048 layout measurements above.
  2. Connector runtime rotation is exactly 0 relative to the shared art root.
  3. No layer is independently rescaled/recentered to satisfy old family canvas assumptions.
  4. Dust/connector/Locker visible bounds and overlap ordering match the supplied references within at most 1 pixel of rasterization tolerance.
  5. The missing connector chunk is present; no raw-master overlap junk appears outside the registered connector layer.
  6. The specialized Designation Locker remains correct and independently interactive.
  7. Bidirectional traversal remains physically valid and visually covered.
  8. Asset V2 status/doctor and changed-file validation are green.
- Validation: registration/bounds smoke; compact three-layer render evidence; Asset V2 status/doctor for the three families if touched; Designation Locker smoke; Awakening scene/geometry/progression; bidirectional connector traversal; changed-file validation; `git diff --check`.
- Task overrides: `none`
- Deferred: any genuine gameplay-geometry mismatch exposed after exact art composition is restored; Locker foreground replacement art; full Awakening convergence.
