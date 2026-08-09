# PROCGEN NON-WALKABLE SURFACES

- Status: `review`
- Authority: `design/02_features/procgen/NONWALKABLE_SURFACE_REGIONS.md`
- Goal: Add deterministic complete CHASM/OCEAN semantics and connect a bounded Sundered Keep ocean claim to near-field visuals and the existing vista.
- Files: procgen classifier/tilemap/scene/TileSet/tile IDs, Sundered frontage and vista, focused smokes, active procgen/level docs and context indexes.
- Constraints: Final floor remains ground/traversal/navigation authority; RuntimeWalkableBoundary remains physical authority; walls never influence surface floods; current depth-backdrop mode remains live; no new art; preserve unrelated worktree edits.
- Acceptance: Complete exclusive surface classification, deterministic Sundered ocean claim, visual-only ocean layers, exact candidate-promotion preservation, protected floor/spawn disjointness, vista geographic integration, required smokes and full Moment Forge evidence.
- Completed: Active authority, deterministic classifier, Sundered ocean claim,
  final-floor integration, semantic exports, visual-only TileMap layers, shoreline
  painting, vista ocean bounds, candidate preservation, placement guards, focused
  validation, and documentation drift remediation.
- Deferred: Chasm-driven backdrop rendering remains intentionally deferred. The
  seam-safe camera-following backdrop stays live.

### Ownership And Timing

- Owner: procgen runtime / Sundered Keep generated frontage
- Agent/session: Codex `/root`
- Created: 2026-08-09
- Last updated: 2026-08-09

### Work Surface

- Read: repository/local agent primers, active frontage/elevated-world authority, current context/index/validation recipes, generation/terrain/depth/boundary runtime, Sundered runtime, scene/TileSet/assets, and focused tests.
- Change: active authority first; classifier and final-floor integration; semantic exports/promotion; ocean visual layers/assets; frontage claim/validation; vista ocean bounds; tests and docs drift.
- Out of scope: traversal mechanics, new art, global oceans, replacement collision/camera/routes, and `configure_from_chasm_cells()` migration.

### Plan

1. Define authority and stable claim/classifier contracts.
2. Register visual assets and wire presentation-only layers.
3. Classify from final floor, preserve candidate state, export semantics, and audit placement.
4. Integrate Sundered claim/vista geometry and accurate overlap diagnostics.
5. Extend focused validation, run required suite and Moment Forge full capture.
6. Remediate documentation drift and complete evidence/handoff.

### Drift Review

- Primary authority: new spec created; frontage/elevated-world docs require implementation-state updates.
- `CURRENT_STATE.md`: header date is stale and a later moonlight-wiring statement contradicts live runtime.
- `CONTEXT.md`: update only if the surface/traversal separation needs a project-wide guardrail beyond the new authority.
- `FILE_INDEX.md`: classifier, design, packet, surface smoke, and visual ownership require indexing.
- Local routing/readmes: no new directory routing required.

### Handoff

- Structural validation: all required headless smokes pass, including candidate
  promotion and IDs 124–128 asset registration. Additional playability and world
  vista smokes also pass.
- Visual evidence: Moment Forge scenario
  `vista/sundered_keep_first_reveal` completed in `full` mode at
  `reports/moment_forge/vista/sundered_keep_first_reveal/20260809T022553-0400`.
  Its six captured frames remained in the scenario's static probe composition,
  so it is evidence of harness completion but not sufficient visual acceptance.
  Renderer-backed seed 1 captures in
  `reports/sundered_keep_procgen_frontage/` were inspected at overview, first
  reveal, frontage apex, and gate approach. They show generated ocean outside
  land and a continuous near/far-water handoff. The opaque void underlay exposed
  by the geographic clip was made transparent so the seam-safe depth backdrop
  remains visible instead of a hard rectangular fill.
- Remaining review limitation: the current registered Moment Forge scenario does
  not move through seven distinct semantic checkpoints. A future scenario repair
  should expose before-funnel, takeover, first apex, frontage start/apex, return,
  and terminal-apron frames in one deterministic capture. The renderer-backed
  gate-approach frame also retains the pre-existing rectangular GateShadow veil;
  it is not an ocean tile or surface-authority defect, but it prevents full
  composition approval under this packet's strict visual criteria. No baseline
  was accepted or replaced.
- Blockers or open questions: no structural blocker; source IDs 124–128 were
  verified free before registration.
