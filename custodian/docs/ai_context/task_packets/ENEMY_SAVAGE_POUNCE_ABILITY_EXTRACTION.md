# ENEMY SAVAGE POUNCE ABILITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `enemy-savage-pounce-ability-extraction`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `enemy-marine-dash-ability-extraction-recovery-1`
- Locks: `enemy-runtime`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `02ca0025b8`
- Goal: Move the Savage pounce phase machine out of `enemy.gd` into one actor-local ability authority, reusing the landed Marine/Falcon host-service pattern without changing Savage rushdown behavior.
- Completion boundary: This slice owns Savage pounce state/tuning extraction, the narrow host-service seam required by it, focused pounce diagnostics/tests, validation ownership, and docs made false by the extraction. It does not own the Savage two-hit chain.
- Current measured state: On reviewed main, `enemy.gd` contains `savage_pounce_enabled`, pounce tuning exports, mutable pounce phase/timer/contact state, launch gating, travel/contact/recovery behavior, and read-only Savage debug output. Current active state says `enemy_savage` is a live rushdown archetype and shared `Enemy` owns its telegraphed pounce. Authored E/W pounce body/FX exist but remain unwired; that art gap is unrelated to this ownership extraction.
- Evidence: `custodian/game/actors/enemies/enemy.gd`; `custodian/game/actors/enemies/enemy_savage.tscn`; `custodian/game/actors/enemies/abilities/README.md`; `custodian/docs/ai_context/CURRENT_STATE.md`; `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`; the landed result of `enemy-marine-dash-ability-extraction-recovery-1` is a dependency and becomes the immediate structural reference.
- Task-specific authority: `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`; current Savage runtime/scene tuning; live combat hit/engagement contracts; the landed actor-local ability service seam after NPA-1.
- Work surface: `custodian/game/actors/enemies/abilities/`, focused typed config if warranted, `enemy.gd`, `enemy_savage.tscn`, Savage-relevant validation and validation-manifest ownership, active ownership/current-state docs.
- Change: Extract the complete Savage pounce lifecycle into one focused ability/controller: launch decision inputs owned by the ability once requested, phase/timers, committed direction/target data, leap movement intent/contact window, one-hit bookkeeping, knockback/damage request, cooldown/recovery, interruption/reset, telemetry/debug snapshot. Reuse the real host-service boundary proven by Falcon/Marine rather than duplicating shared combat code. Move Savage-pounce tuning out of generic Enemy exports into focused config/resource where practical. Remove duplicate pounce state/methods from `enemy.gd`. Keep pounce presentation requests semantic and do not wire missing authored pounce art as part of this refactor.
- Preserve: Current Savage HP/speed/base damage/profile behavior; pounce launch band, damage, knockback, cooldown, active window, reach, collision semantics, deterministic decisions, BSM ownership, ordinary chain behavior, presentation fallback, asset requirement status.
- Non-goals: No two-hit chain extraction; no Savage balance pass; no new art/Asset V2 ingest; no generic ability base; no profile redesign; no loot/reaction refactor.
- Acceptance: Savage pounce mutable phase/timer/contact state is absent from `enemy.gd`; the extracted ability owns the full pounce lifecycle and typed debug state; no parallel pounce authority remains; current pounce gameplay/tuning is equivalent; chain behavior is unchanged; existing Savage/current combat validations remain green; validation ownership follows the new module; `enemy.gd` shrinks by the removed pounce authority rather than gaining a second wrapper implementation.
- Validation: Use the narrowest existing Savage/combat smokes selected by the live validation manifest after fresh-main inspection; add focused pounce-equivalence assertions to an existing appropriate smoke or add/register a new focused gate during implementation. Do not name a nonexistent validation path in advance. Run `python3 custodian/tools/validation/run_validation.py --changed --json` once at closeout. Renderer evidence is not required unless behavior-equivalence tests reveal a presentation timing regression.
- Task overrides: `none`
- Deferred: Savage two-hit chain extraction; pounce authored body/FX wiring; reaction/loot/generic melee decomposition; cross-family actor convergence.

## Handoff

- Next action: after NPA-1 is complete and archived, remeasure live Savage pounce ownership and extract against the landed host-service seam.
- Best starting files: `enemy.gd`, `enemy_savage.tscn`, `abilities/README.md`, validation manifest, and NPA-1's landed ability/config pattern.
- Blockers or open questions: dependency on `enemy-marine-dash-ability-extraction-recovery-1`.
