# COMBAT RESOURCE FEEDBACK

- Status: `complete`
- Authority: `design/02_features/combat_feel/COMBAT_RESOURCE_AND_READABILITY_SYSTEM.md`; ranged mechanics contract in `design/02_features/combat_feel/RANGED_COMBAT_BALANCE_AND_STEALTH_SYSTEM.md`
- Goal: Convert authoritative per-weapon ammo, reload, heat, and overheat state into a compact persistent HUD row plus debounced weapon-local feedback events, audio, and restrained VFX.
- Files: Operator weapon status/events, weapon definition data access, Operator feedback presenter/scene, compact HUD, weapon schema/data, focused smoke validation, active docs, and root routing primer.
- Constraints: Operator remains authoritative; presentation never emits `NoiseEventBus` events; held-fire failures are debounced; missing presentation assets warn loudly and never block gameplay; no manual venting, reload-cancel changes, new resource mechanics, or AI-noise changes.
- Acceptance: Expanded status values are valid; transition events emit once; repeated blocked fire is bounded; reload and per-weapon state remain correct; the HUD is read-only; focused ranged and combat-resource smokes pass.
- Completed: Expanded authoritative status and threshold math; added debounced transition/failure events and observability; wired weapon JSON sound access/schema/data; attached local-only presenter audio, tint, and procedural barrel vent VFX; added compact pressure HUD and transition-only tweens; reconciled root routing and active docs; added focused ten-boundary smoke coverage. Supplied WAVs were verified as 48 kHz mono and within the requested duration ranges. Ranged balance, combat-resource feedback, modular ranged presentation, import, and full headless boot validation pass with only pre-existing cape-animation/resource-leak warnings.
- Deferred: Authored overheat sprite sheet and optional HUD state icons; weapon-specific P-9 replacements may follow the shared V1 sounds.
