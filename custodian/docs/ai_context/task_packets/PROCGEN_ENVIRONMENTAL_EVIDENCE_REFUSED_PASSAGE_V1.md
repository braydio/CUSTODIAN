# ES-2: PROCGEN REFUSED PASSAGE PHYSICAL EVIDENCE PILOT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-environmental-evidence-refused-passage-v1`
- Authoring handoff: `auto`
- Kind: `implementation`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-procgen-environmental-evidence-v1`
- Locks: `procgen-runtime`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-procgen-environmental-evidence-refused-passage-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `New physical blocking props, deterministic procgen selection, two native interactions, and streaming lifecycle need independent route/collision/prompt proof.`
- Reviewed main: `eb4de63498ef13eacc86022613bfa35f825d8b7f`
- Authoring chat: `https://chatgpt.com/share/6ae08da1-832c-83ea-8ea3-db1d47ac0576?ogimg=plain`
- Visual review: `conditional`
- Goal: Implement one optional, visibly readable and interactable Refused Passage checkpoint tableau on an existing ES-1 accepted F02 story-site rectangle, without disrupting accepted playable geography.
- Completion boundary: One deterministic Refused Passage plan and one lifecycle-safe site presenter; max one physical pilot per eligible region, three coherent variants, five distinct visual evidence categories, physically closed checkpoint, real three-cell clear bypass, two reachable repeatable readouts, stable negative skips and focused Godot proof. Blockout art is allowed and explicitly provisional; no new asset ingestion.
- Current measured state: ES-1 landed at `e96019d98e86380a87f43bf0fa6104d4004d6c1d` and `main@1917c8940d3d980b5ee58a73da8a2e57eec08bf4`. `story_room_sites` now project `es1-story-site-v1` identities from exact F02 reserved STORY_ROOM ID/rect, and `story_room_geometry_stamper.gd` asserts the join. `_place_story_rooms` still adds a generic placeholder marker; no physical narrative props/readouts exist. `WorldReadoutInteractable` is already repeatable with 72px default range; Operator caps selection at 84px and chooses nearest. The ES-1 independent review is currently ready/claimed but was previously stopped before reviewer launch for five undeclared docs, not an implementation test failure.
- Evidence: `custodian/game/world/procgen/story/story_room_placer.gd`, `custodian/game/world/procgen/story/story_room_geometry_stamper.gd`, `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/game/world/procgen/generation/accepted_world_export.gd`, `custodian/game/world/interactions/world_readout_interactable.gd`, `custodian/tools/validation/faction_story_sites_smoke.gd`, `custodian/tools/validation/procgen_worldgen_shape_smoke.gd`, `PROCGEN_ENVIRONMENTAL_EVIDENCE_V1_CLAUDE_SUMMARY.md`.
- Task-specific authority: `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_EVIDENCE_ES2_REFUSED_PASSAGE.md`; `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_STORYTELLING_V1.md`; `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_EVIDENCE_ES1_INTEGRATION_REVIEW.md`; `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_STORYTELLING_ROADMAP.md`; F02 accepted world/road/terrain/streaming and authored level exclusivity contracts.
- Work surface: `custodian/game/world/procgen/story/refused_passage_plan.gd` (new pure planner); `custodian/game/world/procgen/story/refused_passage_site_2d.gd` and optional `custodian/game/world/procgen/story/refused_passage_site_2d.tscn` (new scene-local presenter); `custodian/game/world/procgen/story/story_room_placer.gd` (only if a proven small selector adaptation is needed); `custodian/game/world/procgen/proc_gen_tilemap.gd` (thin adapter and actual existing lifecycle/coordinate/blocker integration); `custodian/game/world/procgen/generation/accepted_world_export.gd` (only for validated detached plan export); `custodian/tools/validation/refused_passage_site_smoke.gd` (new focused smoke); `custodian/tools/validation/faction_story_sites_smoke.gd`, `custodian/tools/validation/procgen_worldgen_shape_smoke.gd`, `custodian/tools/validation/procgen_accepted_world_export_smoke.gd`, `custodian/tools/validation/validation_manifest.json`; `custodian/docs/ai_context/CURRENT_STATE.md`, `custodian/docs/ai_context/FILE_INDEX.md`, `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_EVIDENCE_ES2_REFUSED_PASSAGE.md`, `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_STORYTELLING_V1.md`, `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_STORYTELLING_ROADMAP.md`. Stage only actually modified files; every future changed Markdown path must be explicitly enumerated here before source-bearing archive closeout.
- Publication inputs: `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_EVIDENCE_ES2_REFUSED_PASSAGE.md`, `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_STORYTELLING_V1.md`, `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_EVIDENCE_ES1_INTEGRATION_REVIEW.md`, `custodian/game/world/procgen/story/story_room_placer.gd`, `custodian/game/world/procgen/story/story_room_geometry_stamper.gd`, `custodian/game/world/procgen/intent/region_footprint_reserver.gd`, `custodian/game/world/interactions/world_readout_interactable.gd`, `custodian/tools/validation/faction_story_sites_smoke.gd`, `custodian/tools/validation/procgen_worldgen_shape_smoke.gd`, `custodian/tools/validation/procgen_accepted_world_export_smoke.gd`, `custodian/tools/validation/validation_manifest.json`.
- Change: Implement the exact ES-2 source spec, with these behavior requirements:
  - Consume only already accepted ES-1 `es1:` site IDs/intent-node IDs/exact unmodified reserved rects. Deterministic pure planner selects at most one site and one of `emergency_quarantine`, `controlled_drawdown`, `disputed_diversion`. No global RNG, second cell-sampled marker, duplicate site registry or invented F15 Location.
  - Fit the versioned 16×12-cell 32px layout in the actual reservation; use deterministic cardinal transforms only when all floor/approach/road/protected/vehicle/readout checks pass. Never imply a new road solely because a `STORY_APPROACH` edge exists. Produce stable optional skip reasons without invalidating the accepted world.
  - Create coherent visual evidence: official post/sign, queue traces, sealed gate, two distinct abandonment traces, tidy stores and contradictory evidence, using legitimately approved reused assets or clearly provisional semantic blockout primitives. No new production art/Asset V2 family. Replaced site loses its generic placeholder; other story sites retain theirs.
  - Physically block only the closed gate footprint and any proven safe optional solid props; preserve the full 3-cell transformed bypass, authoritative required routes, spawn, ingress, objective, extraction, road, vehicle, chasm and authored-site exclusion. Register and remove blocker cells through existing F02 authority; do not write a second navigation controller.
  - Instantiate exactly two `WorldReadoutInteractable` nodes at reachable identity-tray/duty-ledger slots, `single_use=false`, 72px readout radius within 84px Operator cap, distinct nonoverlapping prompts, no through-wall activation or HUD/quest/event/save code rewrite. Use the variant text from the spec.
  - Guarantee one presenter root per accepted selected site ID after regeneration/reveal/re-entry and zero residual prompts/collision on skip/removal. Adapt M5/M6 streaming and Archive Resolve only by the supported lifecycle, never by repainting canonical world cell state.
  - Include a positive fixture proving a site **actually spawns**, plus explicit negative controls for invalid rect/protected route, unsuitable approach, blocked bypass, unsafe gate, duplicated streaming, prompt selection and variant determinism. Update manifest ownership for new scripts/smoke.
- Preserve: ES-1 site identity and source rectangles, accepted-world generation seed and topology, road/terrain/route/ingress safety, D1/D2/D3 authority, streaming/unloaded canonical state, existing F15 data-only scope, Operator/HUD, no new authored Ash-Bell West Gate event, no legacy-polity canon, no permanent evidence/quest completion.
- Non-goals: No refined production source artwork or Asset V2 intake; no generic narrative scene editor or new story site authority; no additional campaign locations, faction NPCs, save store, event controller or ambient combat; no ES-3/ES-4 implementation, `operator.gd` or HUD rewrite; no disabling an independent ES-1 reviewer gate via ES-2 source edits.
- Acceptance:
  - A1 One real site at a positive fixture and zero sites with stable skips for unsatisfied optional candidates; exact ID and rectangle preserved.
  - A2 The five visible causal evidence categories are present and visually distinguishable; closed gate blocks actual traversal while a >=3-cell safe bypass and both inspect points are connected to existing playable floor without harming any required road or vehicle path.
  - A3 Same seed/site/grammar produces byte-identical plan hash, variant, transformed prop/readout locations and IDs under repeated/shuffled input; no global RNG or topology drift.
  - A4 Two repeatable default-range native HUD readouts are actually usable by the Operator, with no overlapping competing gate prompt or through-wall interaction, and zero quest/world-history writes.
  - A5 Regenerate/reveal/chunk unload/reload is duplicate-free and clears dedicated blocker ownership; existing story sites/legacy fallback remain intact.
  - A6 No substantial new godfile state in `proc_gen_tilemap.gd`; appropriate focused/changed-file checks pass and implementation reports blockout versus production art accurately.
- Validation: Create and run a focused `refused_passage_site_smoke` as an implementation output, with positive and negative fixtures for A1–A5. Run the existing `godot --headless --path custodian --script res://tools/validation/faction_story_sites_smoke.gd`, `res://tools/validation/procgen_worldgen_shape_smoke.gd`, `res://tools/validation/procgen_accepted_world_export_smoke.gd`, and relevant road, route/collision, readout, M5/M6 and candidate-parity regressions selected by the changed-file manifest. Then `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`, `python3 custodian/tools/agent/check_ai_context.py --json`, `python3 custodian/tools/agent/validate_review_pairing.py`, `git diff --check`. Structured and minimal ROI evidence precedes any optional visual handoff.
- Task overrides: `none`
- Deferred: ES-3 Borrowed Hearth + False Seam on the same planner/presenter contract; ES-4 finished family art/campaign review; persistent F15 associations only when verified. ES-1 independent source-scope review remains the earlier workstream's protected responsibility.

## Execution and provenance

Routine in-scope fixes to new planner/presenter, native interactions, fixture drift, source references and directly affected documentation must be repaired here, not escalated to fresh planning packets. Genuine conflicting claims, independent-review evidence, validation failures, human source-art approvals and locks remain real protections.

**Unresolved parent review:** The existing ES-1 review workstream is not passed. This packet depends on its accepted review via the normal dispatcher, not a forged PASS; authoring/publishing ES-2 is independent and does not modify that claim. If the dispatcher blocks execution, report the **actual** held review/lock identity, preserve its worktree, and allow ES-2 design progress without inventing a new semantic design dependency. The project's separate owner-review-exception proposal is not currently an implemented waiver.

**Visual gate:** Objective scene/blocker/readout proof comes first. If human assessment of story legibility is material, issue exactly one focused ROI/contact-sheet Dropbox handoff through `publish_review_artifacts.py` under `/CUSTODIAN/visual_review/procgen-environmental-evidence-refused-passage-v1/`; preserve the exact authoring-chat URL, the actual manifest link and cleanup instruction. No requirement for expensive full-motion capture or all ES-4 art before a technically complete ES-2.

## Next Handoff

- Next workstream: `review-procgen-environmental-evidence-refused-passage-v1`
- Next packet state: `dependency-gated on landed implementation`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/share/6ae08da1-832c-83ea-8ea3-db1d47ac0576?ogimg=plain`
- Next action: Execute the normalized Refused Passage blockout when dispatcher eligible, then independent technical review; ES-3 follows on the same composition API.
- Blockers or open questions: Existing ES-1 independent review acceptance and any actual `procgen-runtime` claim conflict are dispatch gates, not missing ES-2 design decisions.
