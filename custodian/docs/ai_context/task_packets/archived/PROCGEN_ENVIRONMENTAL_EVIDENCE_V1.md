# PROCGEN ENVIRONMENTAL EVIDENCE V1: ES-1 SITE IDENTITY FOUNDATION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-environmental-evidence-v1`
- Authoring handoff: `auto`
- Kind: `implementation`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `procgen-runtime`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-procgen-environmental-evidence-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Changes identity and placement of existing procgen story records; requires independent proof of route, terrain, export, and deterministic safety.`
- Reviewed main: `a358584555f91e396f7da3ac4e883aff27c143f3`
- Authoring chat: `https://chatgpt.com/share/6ae08da1-832c-83ea-8ea3-db1d47ac0576?ogimg=plain`
- Visual review: `none`
- Goal: Give every eligible procgen story site one physically grounded, reproducible identity derived from an existing F02 STORY_ROOM intent reservation, ready for later Refused Passage, Borrowed Hearth, and False Seam physical composition.
- Completion boundary: For intent-enabled generation, bind story metadata to actual preexisting reserved STORY_ROOM node ID/rect, replace the competing independent anchor selection, preserve accepted-world terrain and route safety, publish the detached normalized site record through the existing accepted-world export, and prove deterministic skip and compatibility. Do NOT implement the visual tableaux, art, new interactions, F15 topology, or cross-visit save systems in ES-1.
- Current measured state: `story_room_geometry_stamper.gd` iterates `worldgen_reserved_regions[kind=story_room]` and ignores its story list, while `story_room_placer.gd` separately randomly selects floor-cell markers with `metadata_only_v1`, no graph node ID/rectangle join. `proc_gen_tilemap.gd` exports both independent arrays, and its foliage/ruin clearances use story metadata centers. F15 B1/B2 semantics exist but are data-only; `WorldReadoutInteractable` and Operator group interaction already exist. D2 authored claim extraction excludes intent reservations and is a separate queued workstream.
- Evidence: `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_EVIDENCE_ES1_INTEGRATION_REVIEW.md`; `custodian/game/world/procgen/story/story_room_placer.gd`; `custodian/game/world/procgen/story/story_room_geometry_stamper.gd`; `custodian/game/world/procgen/intent/ascent_spine_builder.gd`; `custodian/game/world/procgen/intent/region_footprint_reserver.gd`; `custodian/game/world/procgen/generation/accepted_world_export.gd`; `custodian/game/world/procgen/proc_gen_tilemap.gd`; `custodian/tools/validation/faction_story_sites_smoke.gd`.
- Task-specific authority: `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_STORYTELLING_V1.md`, `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_EVIDENCE_ES1_INTEGRATION_REVIEW.md`, `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_STORYTELLING_ROADMAP.md`, `design/02_features/procgen/PROCGEN_INTENT_GRAPH_ASCENT_V1.md`, `custodian/AGENTS.md`, and the existing F15-B2 semantic-site contract.
- Work surface: Primary `custodian/game/world/procgen/story/story_room_placer.gd` and a focused story-site identity/projection helper there if warranted; `custodian/game/world/procgen/story/story_room_geometry_stamper.gd` only as needed to consume the same reservations; narrow adapter in `custodian/game/world/procgen/proc_gen_tilemap.gd` for supplying reservations and using/exporting authoritative site records; directly affected `custodian/game/world/procgen/generation/accepted_world_export.gd`, `custodian/tools/validation/faction_story_sites_smoke.gd`, `custodian/tools/validation/procgen_intent_graph_smoke.gd`, `custodian/tools/validation/procgen_worldgen_shape_smoke.gd`, relevant manifest/AI-context docs. Avoid creating a new long-lived controller in the TileMap façade.
- Publication inputs: `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_STORYTELLING_V1.md`, `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_EVIDENCE_ES1_INTEGRATION_REVIEW.md`, `design/02_features/procgen/PROCEDURAL_ENVIRONMENTAL_STORYTELLING_ROADMAP.md`, `custodian/game/world/procgen/intent/ascent_spine_builder.gd`, `custodian/game/world/procgen/intent/region_footprint_reserver.gd`, `custodian/game/world/procgen/story/story_room_placer.gd`, `custodian/game/world/procgen/story/story_room_geometry_stamper.gd`, `custodian/game/world/procgen/generation/accepted_world_export.gd`, `custodian/tools/validation/faction_story_sites_smoke.gd`, `custodian/tools/validation/procgen_intent_graph_smoke.gd`, `custodian/tools/validation/procgen_worldgen_shape_smoke.gd`, `custodian/tools/validation/procgen_ascent_style_smoke.gd`.
- Change:
  - In intent-enabled generation, source candidate sites **only** from `worldgen_reserved_regions` entries with `kind=story_room`; bind the exact existing graph `id`, `center`, clipped `rect`, `band_id`, `style_id` and compatible metadata. Do not independently place another story marker. Preserve deterministic ordering, bounded count and a documented legacy/non-intent fallback where existing behavior requires it.
  - Give every candidate an explicit versioned identity derived collision-safely from current effective F02 accepted generation seed, source/region identity where available, existing intent node ID and planner version; never use a transient `Node.get_instance_id`, bare cell, or invent a new F15 Location. If the F15 parent is not provided and verified, record the site as F02-region-scoped only, with **no** claim of durable cross-visit geography.
  - Validate actual rect shape, map bounds, overlaps, required route/ingress/mission/void/collision and accessible approach using current owners' data. If invalid, skip this **optional** site with a stable reason and no physical mutation; do not reject or reroll an otherwise accepted map to meet a story quota. Existing intent reserves remain independent terrain/route authority.
  - Keep current stamped floor/claim effects and accepted topological shape unchanged. If floor stamping does not consume normalized record, establish an explicit identity/assertion check so it cannot silently claim an unrelated rectangle. Existing `story_room_sites` consumers (markers, ruin/foliage exclusion, level_data) must use the joined record consistently; retire the competing intent-mode placement path rather than retaining parallel truth.
  - Add focused deterministic tests: same seed/same reservations; input reordering; two distinct node IDs; clipped/out-of-bounds/overlap rejection; stable zero-site outcome; optional F15 absence; no duplicate anchor; geometry/route/terrain/export parity. Update test selectors/manifest for new focused source owner only when a new file/test actually exists.
- Preserve: Single F02 accepted world, deterministic seed, `STORY_APPROACH` route intent, exact required-route/ingress and accepted region topology; D1 road state, D2 authored claim owner (excluding intent reservations), D3 accepted-world export single source, M5/M6 unload/reload, Archive Resolve presentation-only; existing operator/HUD interaction; Sundered Keep protection and other authored events.
- Non-goals: No Refused Passage artwork, HUD readout scene, physical props, populated Hearth, False Seam anomaly, new event engine, FI canonical faction-migration implementation, new permanent F15 B1/B2 site, save/restart contract, generalized ruin generator or `operator.gd` changes. ES-2/3/4 remain separate subsequent expansion slices, not abandoned features.
- Acceptance:
  - A1: For intent-enabled maps, **every** exported active story metadata site binds an existing story intent node by exact ID and actual reserved rectangle; no unrelated metadata-only marker is presented as the authoritative physical site.
  - A2: Identical seed/accepted source/intent graph yields byte-stable versioned site IDs, sorted normalized records and skip reasons under repeated generation and shuffled inputs. Distinct node IDs do not collide.
  - A3: Invalid/unsuitable sites skip safely with no terrain mutation and no changed required route, accepted spawn, ingress, authored protection or existing physical claim semantics.
  - A4: Existing level-data export, marker/foliage/ruin consumers use the same record; legacy/no-intent compatibility is documented and tested, without a second new owner.
  - A5: No new F15 topology, fake durable persistence, actor/Operator/HUD authority, Asset V2 family or new dependency gate; focused regression and changed-file validations pass.
- Validation: Run existing `godot --headless --path custodian --script res://tools/validation/faction_story_sites_smoke.gd`, `procgen_intent_graph_smoke.gd`, `procgen_worldgen_shape_smoke.gd`, `procgen_ascent_style_smoke.gd`, and `campaign_geography_semantic_site_smoke.gd` (same prefix). Add a targeted ES-1 validation smoke as a **work output** if existing tests cannot prove A1–A4. Then `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json`, `python3 custodian/tools/agent/check_ai_context.py --json`, `python3 custodian/tools/agent/validate_review_pairing.py`, `git diff --check`. No screenshot or Asset V2 doctor is necessary for data/geometry-only ES-1.
- Task overrides: `none`
- Deferred: ES-2 Refused Passage actual tableau and two repeatable `WorldReadoutInteractable` evidence points; ES-3 Borrowed Hearth and False Seam using the same composition substrate; ES-4 three Asset V2 families and 27 static/3 optional animation state integration, human visual evaluation.

## In-Scope Blocker Remediation

The user explicitly authorizes normal repair **within this packet** of compilation errors, broken smoke fixtures, stale source references, unsafe duplicate story markers, and docs drift that materially prevent A1–A5. Do not create an avoidable new planning gate or convert a straightforward fix into a new unrelated packet. Preserve and classify any pre-existing failing checks against a verified baseline. **Do not** bypass dispatcher ownership/locks, edit another claimed worktree, waive required validation, forge a reviewer receipt, force a dangerous merge, or broaden D2/F15 authority. An actual competing claim must serialize normally; a genuine out-of-scope invariant should be named precisely in a checkpoint, not used as permission to suppress its check. If newly exposed issue is wholly outside this workstream, leave a specific scoped follow-up, rather than declaring it an ES-1 prerequisite without a concrete dependency.

## Next Handoff

- Next workstream: `review-procgen-environmental-evidence-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/share/6ae08da1-832c-83ea-8ea3-db1d47ac0576?ogimg=plain`
- Next action: Launch the fresh-context paired review `review-procgen-environmental-evidence-v1`; after PASS, prepare ES-2: Refused Passage Physical Tableau as the next development slice.
- Blockers or open questions: none

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `intentionally-preserved`
- Evidence: `49/49 changed-file validations passed; five packet-focused Godot tests passed; accepted-world parity smoke passed after correcting its stale schema pin; check_ai_context, validate_review_pairing, and git diff --check passed. See PROCGEN_ENVIRONMENTAL_EVIDENCE_V1_CLAUDE_SUMMARY.md.`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The existing accepted-world parity fixture pinned the pre-ES-1 export hash; one unrelated agent workflow test hit its timeout once and passed on retry. Godot validation regenerated 13 unrelated PNG import sidecars; byte-exact copies are preserved outside the repository at /home/braydenchaffee/Projects/.custodian-preserved/procgen-es1-generated-import-sidecars-20261028T1109Z before cleanup.`
- Root cause / contributing factors: `The export schema change intentionally changed its stable fixture hash. Validation imports generated metadata for unrelated art assets in the shared worktree.`
- Prevention / pipeline improvement: `Update parity pins alongside intentional export schema changes; continue preserving generated import metadata before removing only those generated sidecars.`
- Tooling / docs drift discovered: `The focused world-shape fixture's story-room placement was unsuitable and required an explicit stable clipped_rect skip assertion; fixed in scope.`
- Follow-up: `fixed-in-scope`
- What worked: `Focused contract tests exposed the identity, exact-rectangle and skip behavior; the full changed-file sweep then passed.`
