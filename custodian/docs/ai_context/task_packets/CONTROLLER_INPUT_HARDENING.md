# Controller Input Hardening

- Status: `complete`
- Authority: `design/02_features/input/CONTROLLER_INPUT_SYSTEM.md`
- Goal: close keyboard-only holes in the existing twin-stick controller contract without replacing InputMap.
- Files: `project.godot`, Operator input, shared prompt presentation, inventory/pause/prompt UI, controller smoke, current-state/index/context docs.
- Constraints: preserve keyboard/mouse hot-swap; no gameplay authority in prompt service; no debug controller reservations or undocumented drone chords; no combat timing changes.
- Acceptance: semantic sprint/heavy actions; documented Xbox bindings and analog thresholds; no D-pad gameplay collisions; action-driven prompts; pause/inventory accept/back behavior; focused smokes and headless load pass.
- Completed: active design authority and audit; InputMap/controller migration; prompt service and action-driven Black Reliquary prompt path; inventory prompt consolidation; pause cancel/hints; focused contract smoke.
- Deferred: controller glyph art, drone command mode, live item-cycle design, hands-on hardware feel review.

## Completion Notes

- Focused controller contract, ranged-ready regression, inventory inspection,
  historical-boundary validation, diff whitespace checks, and headless project
  load passed.
- The changed-file runner has complete manifest coverage and passed 17 selected
  tests. Its overall result remains non-green because the pre-existing
  `operator_melee_posture` smoke asserts that the Vigil posture weapon has four
  frames, then times out; this pass changes no animation assets or posture code.
- Production-input audit classifies remaining raw inputs as developer/debug
  controls, keyboard-only UI enhancements, construction keyboard compatibility,
  or InputMap label extraction. Operator's remaining raw J key is explicitly a
  debug damage hook.
- Moment Forge: not run — bindings, reachability, and prompts changed without
  dodge/combat timing or feel changes.
