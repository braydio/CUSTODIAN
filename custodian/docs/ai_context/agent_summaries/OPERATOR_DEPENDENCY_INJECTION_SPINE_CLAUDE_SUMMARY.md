# Operator Dependency Injection Spine — Codex Summary

Authoring chat: not-recorded

Slice F0 replaced the Operator facade's absolute scene-tree queries with one `OperatorRuntimeDependencies` data bundle. `bind_runtime_dependencies()` is the explicit seam; the bundle has fixed named references and no lookup API, and consumers now read those bound fields. World-owned nodes resolve from the owning World and its composition root; project autoload nodes bind once at the facade boundary. The old `WeaponDefinitionFactory` path named a World child although the live main scene owns it under GameRoot, so the binding now also resolves that actual composition-root placement. Optional services remain nullable, and a missing required world reference fails validation.

The fresh architecture audit found 37 absolute lookups on claim, one fewer than the packet's stale 38 count. The final audit reports zero `absolute_scene_lookups`; the baseline now contains only the three `weapon_definition_runtime_state` findings reserved for F1. The new dependency smoke is registered with `needs_import: true` so clean worktrees build Godot's script-class/resource cache before running it.

Focused dependency binding, architecture audit, fixed-tick, input-aim, ranged ballistic, modular ranged fire, guard flow, death handoff, and powered-fabricator checks passed. The standalone `field_patch_smoke.gd` reported the attack-interrupt and fabrication-restock assertions as failures both in this worktree and in the untouched project-root main checkout; those pre-existing failures remain out of scope. The fresh worktree had no `.godot` cache, so the first direct smoke invocation failed during script-class loading; a one-time Godot editor import resolved it, and the manifest now declares the import requirement for the new test. No LFS files were missing from this worktree relative to the root checkout. The changed-file closeout selected 54 checks but stopped at the repository's `review_pairing_contract` unit gate: five unrelated packets have malformed bounded `TASK OVERRIDE` metadata, so 15 selected checks passed, one failed, and 38 downstream checks were skipped. The same five errors reproduce against fetched current `main`; they are recorded as a repository validation blocker, not changed in this workstream.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: high
- What went wrong: the fresh worktree lacked generated Godot editor cache; standalone Field Patch regression has existing failures; changed-file closeout was gated by five malformed unrelated review packets
- Root cause / contributing factors: new Godot script test initially omitted its `needs_import` declaration; Field Patch assertions reproduce on unchanged main; repository pairing validation fails before the remaining changed-file checks can run
- Prevention / pipeline improvement: dependency smoke now requests import before execution; added named dependency-binding smoke and current measured audit baseline
- Tooling / docs drift discovered: one lookup had already disappeared upstream, and the weapon factory lives under GameRoot rather than the stale World path
- Follow-up: manual-follow-up
- What worked: data-only fixed-field bundle preserves explicit dependency ownership and nullable optional services

## Next Handoff
- Next workstream: `operator-mobile-guard-composition`
- Next packet state: ready
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Claim the independent movement-owned-lower/action-owned-upper guard composition slice; F1 loadout extraction waits for both F0 and that seam.
- Blockers or open questions: none
