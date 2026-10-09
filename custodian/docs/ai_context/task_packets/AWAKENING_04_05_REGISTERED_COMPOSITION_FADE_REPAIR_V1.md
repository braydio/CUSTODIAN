# AWAKENING 04→05 REGISTERED COMPOSITION FADE REPAIR V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `awakening-04-05-registered-composition-fade-repair-v1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `review-awakening-04-05-registered-composition-correction-v1`
- Locks: `awakening-04-05-connector-presentation, awakening-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual, workflow`
- Paired review workstream: `review-awakening-04-05-registered-composition-fade-repair-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `52135e3401a9efd49b011e676171373c3bef37b2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb`
- Visual review: `required`
- Goal: Repair the live 04→05 underlay fade ownership so the accepted 1502×2048 Dust→Connector→Locker composition stays visually stable in the correct room/connector neighborhoods without changing its approved layout, pixels, registration, draw order, traversal, or gameplay geometry.
- Completion boundary: Done when the shared registered root remains an immutable placement container, each visible child layer owns only its correct fade neighborhood, the Dust layer remains readable through the 05→06 passage, forward/reverse traversal produces identical presentation state, and focused runtime + Moment Forge evidence proves no floor plate disappears merely because the Operator leaves the narrow 04→05 dogleg envelope.
- Current measured state: The approved shared composition is visually correct: root `(349,-2585)`, scale `(1,1)`, rotation `0`, 1502×2048 shared canvas, exact Dust→Connector→Locker order and exact source/runtime pixels. The defect is runtime fade ownership. `_cache_zone_art_visibility_targets()` still sends Zone04/Zone05 fade alpha to their hidden legacy `ArtUnderlay` parents, while `_connector_fade_entries` contains the entire `RegisteredComposition04_05` parent. `_update_zone_art_visibility()` therefore fades/hides all three accepted registered children from the narrow merged A/B/C connector envelope. Because the legacy Zone04/05 underlay sprites are intentionally hidden, visible Dust/Locker floor can disappear even while the Operator remains in the corresponding room or lower→upper passage. Existing smoke coverage also contains two stale or vacuous assertions: it expects the whole registered composition to fade to zero away from the dogleg, and its 05→06 coverage probe samples the retired hidden Zone05 underlay texture rather than the live shared Dust child.
- Evidence: `custodian/game/world/awakening/awakening_first_return.gd::_cache_zone_art_visibility_targets/_update_zone_art_visibility`; `custodian/scenes/awakening_first_return.tscn::RegisteredComposition04_05`; `awakening_first_return_smoke.gd::_check_zone_art_fade/_check_lower_upper_passage_art`; `awakening_late_seams_v1.json`; accepted registered composition report `custodian/docs/ai_context/reports/assets/awakening_04_05_registered_composition_v1.json`; user playtest decision in the recorded authoring chat that layout/order are visually correct and only fade should change.
- Task-specific authority: `awakening_layout.gd` for Zone04/Zone05/04→05/05→06 spatial neighborhoods; the accepted registered composition report + scene for immutable art transform/order; `AwakeningFirstReturn` for presentation alpha/visibility ownership; Moment Forge late-seam probes for reproducible visual-state evidence.
- Work surface: `custodian/game/world/awakening/awakening_first_return.gd`; focused Awakening scene/presentation tests; `custodian/tools/iteration/scenarios/traversal/awakening_late_seams_v1.json` + its existing fixture/evidence path; active Awakening design/current-state docs only where this known defect changes runtime truth. Do not edit the registered PNGs, Asset V2 families, scene transform, Layout geometry, P-9, collision, progression, camera, lighting, or unrelated Operator/procgen systems.
- Change:
  1. Preserve the exact shared `RegisteredComposition04_05` root transform and child order. The parent is a registration container and must remain `visible=true`, `modulate.a=1.0`; it is no longer a fade target.
  2. Cache the live registered children as the actual fade targets: `LockerReliquary` consumes Zone04 fade authority; `DustLung` consumes Zone05 fade authority; `Connector` consumes the merged 04→05 connector envelope. Do not route alpha to hidden legacy Zone04/Zone05 underlay nodes as presentation authority.
  3. Preserve the current full-opacity handoff contract through A/B/C: while the Operator is inside the connector neighborhood, Dust, Connector, and Locker registered children remain fully readable exactly as the accepted overlap composition requires.
  4. Preserve the lower→upper spine contract by holding the live shared `DustLung` child opaque through `Layout.PASSAGES["lower_upper_spine_05_06"]` + the existing fade distance, alongside the live Zone06 underlay. Retired hidden Zone05 art cannot be used as the visual oracle.
  5. Outside transition holds, calculate each child alpha from its own owner rectangle with the existing `ZONE_ART_FADE_DISTANCE`. Distant children may hide at alpha≈0, but one child's distance must never collapse its siblings through parent modulation.
  6. Keep the update path cache-only and O(1) in ordinary play. No per-frame tree/path discovery, texture `get_image()`, pixel sampling, resource loads, full-scene scans, or per-frame telemetry/event emission. Preserve the existing stationary-position early-out and thresholded property writes.
  7. Repair `awakening_first_return_smoke.gd` so it observes the live registered children. Delete the stale assertion that the whole composition root must fade away from the dogleg. Assert parent alpha remains 1.0 and child alphas/visibility follow their individual authorities.
  8. Repair the 05→06 presentation proof so the live registered Dust child, not the hidden legacy Zone05 sprite, supplies the Dust-side alpha/visibility coverage oracle.
  9. Extend the existing `traversal/awakening_late_seams_v1` Moment Forge fixture/scenario to include the 04→05 Reliquary interior, A, B, C, Dust interior, and reverse checkpoints. Reuse the existing registered child roles and probe `effective_alpha`; do not create another connector-specific capture framework unless the existing fixture cannot express the samples.
  10. At equivalent forward/reverse positions, require identical Dust/Connector/Locker alpha and visibility. Capture the smallest useful contact sheet showing both interiors plus A/B/C. Human review answers only: “does the accepted layout remain unchanged and do floors stop evaporating/popping at the wrong locations?”
  11. Preserve exact registered asset hashes/bounds/order with `awakening_connector_asset_contract_smoke.py` and the compact renderer smoke. Any art-byte, transform, scale, rotation, z-order, overlap-count, or registration change is a failure in this workstream.
  12. Reconcile active docs that still say the registered-composition paired review is pending or describe the parent-envelope fade as correct current behavior.
- Preserve: Exact 1502×2048 registered PNG bytes; shared root `(349,-2585)`; scale 1; rotation 0; Dust z0 → Connector z1 → Locker z2; accepted overlap counts; Layout A/B/C + 05→06 geometry; collision/walkability; P-9; progression; lighting; camera; all other zone fade behavior.
- Non-goals: No art reauthor; no position/root fit changes; no connector topology change; no new foreground; no opacity-mask painting; no global zone streaming rewrite; no procgen performance fix; no Operator ranged/overheat/dodge changes; no Developer Observatory redesign.
- Acceptance: (1) Scene/asset tests prove registered art bytes, root transform, 1502×2048 canvas, child order and overlap evidence are unchanged; (2) parent `RegisteredComposition04_05` stays visible at alpha 1 through all samples; (3) Locker child is 1.0 in Zone04 interior and A/B/C, Dust child is 1.0 in Zone05 interior, A/B/C, and the full 05→06 passage neighborhood, Connector is 1.0 across A/B/C, and distant unrelated children may independently fade/hide without collapsing siblings; (4) a real/live-equivalent forward + reverse sequence through Zone05→C→B→A→Zone04 and back produces identical presentation state at equivalent checkpoints; (5) no sampled walkable point in 04→05 or 05→06 loses all correct underlay coverage; (6) `awakening_first_return_smoke` no longer passes by inspecting hidden Zone05 art; (7) Moment Forge produces deterministic alpha telemetry + a compact visual contact sheet with no wrong-location floor disappearance/pop; (8) ordinary update code adds no tree scan/image read/resource load/event spam; (9) no unrelated gameplay/runtime behavior changes.
- Validation: Start with a focused fade-state smoke or the repaired `awakening_first_return_smoke.gd`; run `awakening_registered_composition_traversal_smoke.gd`, `awakening_connector_asset_contract_smoke.py`, `awakening_registered_composition_render_smoke.py`/wrapper, and the 05→06 lower-upper passage coverage. Run `python3 custodian/tools/iteration/run_moment.py traversal/awakening_late_seams_v1 --capture-mode none` first, then one full/contact-sheet capture after objective probes pass. Finish with `python3 custodian/tools/agent/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred: The same user playtest report also exposed unrelated production issues: a wrapped Observatory event ring, a degraded procgen performance incident/rebuild storm, two “Operator modular ranged presentation unavailable” warnings, and ranged overheat dominating fire failures. They are recorded here so they are not lost, but this fade repair only consumes the first two as guardrails: acceptance must not depend on retained event-tail history, and the fade path must remain cache-only/lightweight. Combat/procgen fixes belong to their existing authorities/workstreams.

## Agent Handoff / Planning Decisions

- **Human visual lock:** the current 1502×2048 layout, placement and Dust→Connector→Locker order are good. Do not reauthor/reposition them.
- The earlier midpoint-fit concern is **not** a blocker and must not be reopened in this workstream.
- The bug is fade ownership: the registered parent is being faded by the connector envelope while the child room plates are the real visible room underlays.
- The user playtest report was captured from `res://scenes/game.tscn`, not `awakening_first_return.tscn`. It is not direct reproduction evidence for 04→05. It does prove that the event buffer can wrap heavily and that runtime is performance-sensitive; use deterministic probes/captures and cheap cached fade logic rather than event-tail archaeology or heavy per-frame diagnostics.
- Do not “fix” the unrelated ranged/procgen findings while holding the Awakening presentation lock.

## Playtest Report Findings Consumed by This Packet

- Event ring: 1,783 events logged with 1,483 dropped from the retained 300-event tail. Connector acceptance must use focused smoke/Moment Forge probes and stable snapshots, not “absence of a retained event.”
- Performance incident: baseline average 17.35 ms, p95 22.57 ms, p99 31.62 ms, with worst gameplay frames up to 152.84 ms. The connector repair may not add tree scans, pixel/image inspection, resource loads, or event-per-frame work to `_process()`.
- Separate follow-up signals, explicitly out of scope here: procgen wall/shadow/navigation rebuild churn with a last navigation rebuild around 442 ms; repeated modular-ranged-presentation warnings; 38/40 ranged failures from overheat; dodges recorded with no observed iframe avoids. These need their own authority/evidence before behavioral changes.

## Context Pack

- Repomix: `recommended`
- Include: `custodian/game/world/awakening/awakening_first_return.gd,custodian/game/world/awakening/awakening_layout.gd,custodian/scenes/awakening_first_return.tscn,custodian/tools/validation/awakening_first_return_smoke.gd,custodian/tools/validation/awakening_registered_composition_traversal_smoke.gd,custodian/tools/validation/awakening_registered_composition_render_smoke.gd,custodian/tools/validation/awakening_connector_asset_contract_smoke.py,custodian/tools/iteration/scenarios/traversal/awakening_late_seams_v1.json,custodian/tools/validation/fixtures/awakening_late_seams_moment.gd,custodian/tools/validation/awakening_late_seams_evidence.py,custodian/docs/ai_context/reports/assets/awakening_04_05_registered_composition_v1.json,design/04_architecture/AWAKENING_FIRST_RETURN.md`
- Purpose: `accepted shared registration + actual fade owner + live registered child roles + lower-upper coverage + existing deterministic visual evidence path`

Generate once from the claimed worktree:

```bash
scripts/ai/pack-context.sh task "<Include value above>" "awakening-04-05-registered-composition-fade-repair-v1"
```

Use the persistent-root CRG only for baseline orientation; the claimed worktree and exact runtime files are implementation truth.

## Handoff

- Next workstream: `review-awakening-04-05-registered-composition-fade-repair-v1`
- Next packet state: `ready/auto behind implementation`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb`
- Next action: Claim and implement this fade-only repair, then dispatch the paired fresh-context review.
- Blockers or open questions: none. The human-owned visual decision is already locked: preserve layout/order; repair fade only.
