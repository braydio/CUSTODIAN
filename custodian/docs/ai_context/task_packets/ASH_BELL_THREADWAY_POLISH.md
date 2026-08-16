# Ash-Bell Threadway Presentation And Routing Polish

- Status: `complete`
- Authority: `design/05_levels/ASH_BELL_LIFT_INGRESS_PRESENTATION.md`
- Goal: Deliver the directed full-width remembered-road wave, authored-only visible floor, restrained deterministic bends, and clean authored lift occlusion described by the task ISA.
- Files: Ash-Bell presentation/site/causeway, procgen connector/floor authority, route config, focused validation, Moment Forge scenario if framing requires it, design/current-state docs.
- Constraints: Preserve one terrain commit, semantic floor/navigation/minimap authority, pre-acquired Knot behavior, 18 then bounded 30/10 budgets, generic ingress defaults, Sundered Keep protection, and unrelated dirty work.
- Acceptance: Focused smokes and full Moment Forge capture pass; actual checkpoints are reviewed.
- Completed: Full-width per-cell resolve lifecycle, directed deterministic wave, authored-only visual floor, organic safe routing/curved widening, occlusion cleanup, focused validation, and reviewed Moment Forge capture.
- Deferred: None.

### Ownership And Timing

- Owner: LifeOS
- Agent/session: Codex root
- Created: 2026-08-15T20:05:25-04:00
- Last updated: 2026-08-15T20:20:00-04:00

### Work Surface

- Read: root/local primers, active level spec, current state/index/validation guidance, ingress route and runtime/test files named in the brief.
- Change: presentation occlusion, per-cell reveal scheduler, opt-in floor-visual suppression, optional connector routing profile and curved-width expansion, tests and docs.
- Out of scope: new art, Knot economy, Ritualant authored route, generic routing behavior, Sundered Keep, per-cell navigation commits.

### Plan

1. Make focused regression probes fail for occlusion, timing, full-width VFX, hidden base visuals, and shaped paths.
2. Implement the smallest compatible runtime changes across presentation, site/config, and procgen authority.
3. Run import/focused/world-ingress validation and review a full Moment Forge capture.

### Drift Review

- Primary authority: update with final implemented contract.
- `CURRENT_STATE.md`: update because runtime presentation and connector behavior change.
- `CONTEXT.md`: no ownership/guardrail change expected.
- `FILE_INDEX.md`: update only if durable files are added.
- Local routing/readmes: no path changes expected.

### Handoff

- Next action: use the polished live feature for manual multi-seed play review when convenient.
- Best starting files: `ash_bell_threadway_causeway.gd`, `proc_gen_tilemap.gd`, `ash_bell_lift_ingress_presentation.tscn`.
- Validation to run: the three Ash-Bell smokes, relevant world-ingress smoke, import, Moment Forge full capture.
- Blockers or open questions: none. Existing authored floor vocabulary still has limited corner-specific visual variety; no new art was introduced.
