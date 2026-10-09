# VIGIL-PATTERN DAGGER ATTACK DRIVE

- Status: `complete`
- Authority: `design/02_features/combat_feel/OPERATOR_MELEE_ATTACK_DRIVE.md` and `design/02_features/weapons/VIGIL_PATTERN_DAGGER.md`
- Goal: bootstrap the Vigil dagger as default, add collision-safe attack drive, and support the first two-weapon Chain 01 pipeline slice.
- Files: Operator melee profile/weapon schemas, Operator coordinator/scene, dagger resources, validation, and active docs.
- Constraints: preserve Katana content; no target magnetism, position tweening, snapback, fabricated art, or dagger-specific branches in `operator.gd`.
- Acceptance: dagger and cleaver semantic Fast 01/02/03 playback, per-link drive, synchronized body/weapon/FX, dagger default, and Katana regression pass.
- Completed: generic drive and per-link profiles; weapon-owned body/weapon/FX resources; two weapon-specific pipeline layers; canonical 156×96 outputs; dagger default; optional cleaver override; focused smokes.
- Deferred: dedicated Fast 02/03 pixels, heavy implementations, cleaver held art, N/S art, Katana drive, inventory unlock.

## Full Packet Expansion

### Ownership And Timing

- Owner: gameplay/combat + gameplay/weapons
- Agent/session: Codex
- Created: 2026-07-27
- Last updated: 2026-07-27

### Work Surface

- Read: active melee/weapon design, current state/index, runtime definitions, Operator attack/movement/interruption paths, existing smokes and assets.
- Change: profile data, weapon animation-resource contract, attack-drive physics, dagger bootstrap, default melee assignment, tests, active docs.
- Out of scope: inventing production art, cleaver heavy/held implementation,
  enemy drive, and progression/inventory acquisition.

### Plan

1. Extend reusable data contracts and implement bounded collision-safe drive.
2. Install weapon-owned body/overlay resources at equip time.
3. Create and select the dagger V1 definition.
4. Validate dagger behavior and preserve Katana regression coverage.
5. Remediate active documentation drift.

### Drift Review

- Primary authority: split into universal drive, dagger, and Katana-specific docs.
- `CURRENT_STATE.md`: update default weapon and runtime behavior.
- `CONTEXT.md`: no guardrail/working-model change required.
- `FILE_INDEX.md`: index new runtime, design, and validation entrypoints.
- Local routing/readmes: no new routing surface.

### Handoff

- Next action: live visual/contact/socket review.
- Best starting files: dagger definition/profile and focused smoke.
- Validation to run: dagger smoke, Katana chain smoke, profile smoke, scene boot, diff check.
- Blockers or open questions: dedicated Fast 02/03 and N/S art do not exist;
  cleaver held/heavy assets are absent; live gameplay feel still needs tuning.
