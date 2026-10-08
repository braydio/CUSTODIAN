# AWAKENING 04→05 REGISTERED COMPOSITION CORRECTION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-04-05-registered-composition-correction-v1`
- Status: `complete`
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
- Reviewed main: `ff1c3788409747dd0f74f70d100862acd6af139e`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Goal: Replace the independently fitted/rotated Dust Lung ↔ connector ↔ Locker Reliquary presentation with the user's exact precomposed three-layer registration. Preserve the supplied relative layout exactly; do not solve the connector as a separate anchor-fitting problem.
- Completion boundary: Done when the three production layers reproduce the supplied 1502×2048 composition with one shared coordinate basis, zero per-piece rotation, exact layer bounds/overlaps/order, and no independent Dust/Locker/connector normalization that changes their relative registration. Gameplay geometry and the specialized Designation Locker remain unchanged.
- Current measured state: The runtime now publishes and binds the exact registered RGBA 1502×2048 images through the three existing Asset V2 families. One shared root at `(349,-2585)`, native 1:1 scale, and zero rotation aligns the visible-bounds centers of Dust and Locker to their existing room-art centers with symmetric 33×10 world-unit residuals. Layer bounds, draw order, overlaps, and composition export-edge difference are asserted. The separate Designation Locker remains interactive; Layout and collision remain unchanged. Paired review is the remaining lifecycle step.
- Evidence: machine-readable registration authority `custodian/docs/ai_context/reports/assets/awakening_04_05_registered_composition_v1.json`;  authoring-chat reference images supplied 2026-10-07; current runtime screenshots showing the rotated/misaligned join; archived `AWAKENING_ROOM_CONNECTORS_POLISH.md` and review receipt; live `awakening_first_return.tscn`; existing three Asset V2 families and exact Dropbox raw source receipts.
- Task-specific authority: the 1502×2048 registered composition geometry below owns relative art placement; existing Dropbox source masters own source pixels; `awakening_layout.gd` remains gameplay geometry authority; the specialized `awakening_designation_locker` remains P-9 interaction/presentation authority.
- Work surface: `custodian/scenes/awakening_first_return.tscn`; the three existing environment/connector Asset V2 families only if their runtime representation must change; narrow Awakening presentation visibility/z-order code; focused registration validation; active docs describing the now-superseded rotated connector transform.
- Change:
  1. **Treat the supplied composition as placement authority, not inspiration.** Do not independently fit any of the three art pieces to room/connector gameplay anchors.
  2. **Exact shared reference canvas:** every reference export is RGBA `1502×2048` with the same top-left origin `(0,0)`. **The four exact registered reference PNGs are now durable Dropbox inputs and are required execution inputs; the authoring-chat link is no longer needed to obtain them.**
     - composed reference: `/CUSTODIAN/implementation_inputs/awakening_04_05_registered_composition_v1/composite_reference_1502x2048.png`; Dropbox id `id:8NXqdXuW6GUAAAAAAAACuA`; rev `65d59438bcb75915cdd61`; SHA-256 `521beec078b9c3dfb3d694d134258c6a77d0db64e3ce4cc8a71491efff8c9383`.
     - Dust registered layer: `/CUSTODIAN/implementation_inputs/awakening_04_05_registered_composition_v1/dust_registered_1502x2048.png`; Dropbox id `id:8NXqdXuW6GUAAAAAAAACuQ`; rev `65d5943d2805a915cdd61`; SHA-256 `fa8637992bfc0b1ff1b0d009fbe463e098a4adbfe97031c67d2276d2fe94172e`.
     - connector registered layer: `/CUSTODIAN/implementation_inputs/awakening_04_05_registered_composition_v1/connector_registered_1502x2048.png`; Dropbox id `id:8NXqdXuW6GUAAAAAAAACug`; rev `65d5943ff9a84915cdd61`; SHA-256 `489b49615ba53b0073519d5a261f736321ba69b95019bb54ec02ff408a9ffd76`.
     - Locker registered layer: `/CUSTODIAN/implementation_inputs/awakening_04_05_registered_composition_v1/locker_registered_1502x2048.png`; Dropbox id `id:8NXqdXuW6GUAAAAAAAACuw`; rev `65d59441dc32c915cdd61`; SHA-256 `76cc103eda059974f8f279e8e4e10fdb1b388030ea26f2a7b659075c45ceb48d`.
     - Fetch these four files first and fail closed on any revision/hash/dimension/mode mismatch. Do not reconstruct the reference pixels from hashes/bounds alone and do not substitute the three raw masters for these registered-layer files.
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
- Validation: registration/bounds smoke; compact three-layer render evidence; Asset V2 status/doctor for the three families if touched; Designation Locker smoke; Awakening scene/geometry/progression; bidirectional connector traversal; changed-file validation; `git diff --check`; changed-file validation passed all 28 selected checks with complete coverage and no failures or timeouts after the Moment Forge late-seams scenario was updated to assert the new shared composition bounds.
- Task overrides: `none`
- Deferred: any genuine gameplay-geometry mismatch exposed after exact art composition is restored; Locker foreground replacement art; full Awakening convergence.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Evidence: `All registered source hashes/dimensions/modes match; Asset V2 doctor is healthy; focused registration, renderer, traversal, P-9, geometry, progression, startup, and Moment Forge checks pass; changed-file validation passed 28/28 with complete coverage; git diff --check passed.`
- State: complete
- Registered source checks: all four Dropbox references match exact SHA-256, RGBA mode, and 1502×2048 dimensions.
- Asset V2: Dust, connector, and Locker runtime outputs use the registered bytes; all three family statuses are complete and `asset.py doctor --json` is healthy.
- Composition: alpha bounds match exactly; order is Dust→connector→Locker; overlaps are 17,979 / 10,979 / 0 pixels; ordered composite differs from the supplied composite at exactly 1,267 edge pixels.
- Runtime: shared root `(349,-2585)`, scale `(1,1)`, rotation `0`; Designation Locker smoke passes; unchanged Layout geometry smoke reports a safe route and A→B→C/C→B→A order.
- Real traversal: 1,025 Operator samples in the live scene remained on Layout walkable floor with registered layer alpha beneath the Operator, from Locker through Dust Lung and back.
- Renderer: compact 640×720 GL compatibility capture passes with visible bounds `[65,12,575,708]`; artifact `/tmp/custodian_awakening_registered_composition.png`.
- Focused checks: Awakening scene, progression, geometry, startup routing, Designation Locker, registered pixels, and Asset V2 doctor pass. Changed-file validation report is recorded in the implementation summary.
- Deferred: Locker foreground parity and any later gameplay geometry redesign remain out of scope.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: low
- What went wrong: the first registered render probe used Godot's headless dummy renderer, which cannot return viewport pixels; the chained Asset V2 invocation completed Dust before interruption, so connector and Locker were checked and ingested separately; changed-file validation exposed a stale Moment Forge assertion equating the retired Zone 05 underlay bounds with foreground bounds; the finish coverage gate also showed that the manually-run renderer smoke lacked a manifest entry.
- Root cause / contributing factors: headless CI rendering has no pixel backend; `asset.py --godot-import` imports the project for each requested family; the late-seams scenario still encoded the pre-registration room-local underlay contract, and the renderer smoke was not declared in validation coverage.
- Prevention / pipeline improvement: ingest all family outputs first, run one project import, and use `xvfb-run` with the GL compatibility renderer for viewport captures. The render helper now exits clearly when no rendered image is available. The late-seams scenario now probes Dust, connector, and Locker runtime layers and asserts their shared world bounds. The compact renderer smoke is now an Xvfb-backed manifest integration test, so changed-file coverage includes both its wrapper and Godot script.
- Tooling / docs drift discovered: the registered-canvas migration left one stale Zone 05 underlay/foreground bounds equality in `awakening_late_seams_v1`, and the compact renderer smoke lacked a manifest owner; both corrected in-scope.
- Follow-up: fixed-in-scope
- What worked: pixel hash/alpha checks and real Operator sampling closed the registration and traversal questions without changing Layout.

## Independent Review

- Status: `passed`
- Review workstream: `review-awakening-04-05-registered-composition-correction-v1`
- Reviewed on main: `d691f61b2d9fcd52f2084145d5c9fb4a7fa73f9b`
- Reviewed implementation commit: `fcb3ccf30ff7f537e77b5f131522f18bc8c46e7e`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime, visual, asset-pipeline`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `none`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_AWAKENING_04_05_REGISTERED_COMPOSITION_CORRECTION_V1_CLAUDE_SUMMARY.md`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Reviewer independence: `The paired review ran from a newly claimed worktree and reconstructed the landed implementation from its archived packet, durable summary, active Awakening architecture authority, registration evidence, live scene, and focused validation. The reviewed implementation was not modified.`
- Focused evidence: `Registered asset contract passed with exact source hashes, canvas dimensions, bounds, overlap counts, draw order, and expected export-edge mismatch. Awakening first-return scene, geometry, progression, 1025-sample bidirectional traversal, Designation Locker, Asset V2 doctor, and compact GL renderer validations passed. Renderer bounds were [65,12,575,708].`
- Validation caveat: `The fresh worktree initially lacked Godot's generated import cache; after headless editor initialization/import, all focused runtime checks passed. Generated untracked import sidecars from that initialization were removed.`
- Follow-up workstream: `none`

## Next Handoff

- Next workstream: `review-awakening-04-05-registered-composition-correction-v1`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac1a7fa-340c-83ea-83b3-ffb3b715d0d9`
- Refresh reason: none
- Next action: land this validated implementation, then claim its paired review from a fresh reviewer context.
- Blockers or open questions: none
