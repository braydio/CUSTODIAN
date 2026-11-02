# Combat Resource Readability Spec Normalization

## Packet Status

- Status: complete
- Owner: Codex
- Created: 2026-06-21
- Last updated: 2026-06-21

## Task

Convert the root combat-resource/readability draft into a current in-progress
Godot design authority while routing completed V1 slices to durable feature
specs and live runtime ownership.

## Authority And Scope

- Primary workflow: `custodian/AGENTS.md`
- Design lifecycle: `design/00_meta/README.md` and `MASTER_ROADMAP.md`
- Source draft: retired `design/COMBAT_RESOURCE_READABILITY.md`
- New umbrella: `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md`
- Runtime behavior was reviewed but not changed.

## Decisions

- Use the repository's established `design/02_features/<area>/` convention;
  do not create the proposed but nonexistent `design/20_features/` hierarchy.
- Keep completed implementation detail in existing ranged, combat-feel, sidearm,
  enemy-objective, turret, fabrication, and drone authorities.
- Use the umbrella for verified status, integration rules, deferred milestones,
  validation baseline, and the next agent slice.
- Correct stale drone planning references so historical prompts cannot override
  the completed V1 authority.

## Completion

- Root draft replaced by an in-progress feature umbrella.
- Master roadmap updated with completed, active, planned, and backlog slices.
- `CURRENT_STATE.md`, `CONTEXT.md`, and `FILE_INDEX.md` route to the new authority.
- Completed slices point to their permanent design/runtime homes.
- No gameplay, schema, scene, or asset behavior changed.

## Validation

- Verified the new active umbrella, roadmap, and adjacent drone routing no longer
  depend on the retired draft or proposed `design/20_features/in_progress/` path.
- Verified all permanent authority and runtime paths named by the umbrella exist.
- Ran scoped Markdown whitespace/path checks.
