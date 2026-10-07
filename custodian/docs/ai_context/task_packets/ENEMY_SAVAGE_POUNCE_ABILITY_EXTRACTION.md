# ENEMY SAVAGE POUNCE ABILITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `enemy-savage-pounce-ability-extraction`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `enemy-marine-dash-ability-extraction-recovery-1, review-enemy-marine-dash-ability-extraction-recovery-1`
- Locks: `enemy-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-enemy-savage-pounce-ability-extraction`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `state-machine/ownership extraction; independent review should verify behavior equivalence and one-authority closure`
- Reviewed main: `92b05fa966`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Move the Savage pounce phase machine out of `enemy.gd` into one actor-local ability authority, reusing the landed Marine/Falcon host-service pattern without changing Savage rushdown behavior.
- Completion boundary: This slice owns Savage pounce state/tuning extraction, the narrow host-service seam required by it, focused pounce diagnostics/tests, validation ownership, and docs made false by the extraction. It does not own the Savage two-hit chain.
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Current measured state: NPA-1 implementation is landed and complete. Its paired review workstream `review-enemy-marine-dash-ability-extraction-recovery-1` is ready and pending. The landed implementation provides actor-local `MarineDash` + typed `MarineDashConfig`, public `request_marine_dash`, exact 26-default/26-scene tuning parity, and reduces `enemy.gd` by 343 lines. Do not begin NPA-2 until the paired review passes and the authoring conversation refreshes this packet against the reviewed seam. On current production main, Savage pounce authority remains in `enemy.gd`.
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

- Next action: After NPA-1's paired review passes, return to this planning chat, remeasure live Savage pounce ownership/callers/tuning against the reviewed Marine host-service seam, then rewrite this packet in place to `ready/auto` before implementation.
- Best starting files: `enemy.gd`, `enemy_savage.tscn`, `abilities/README.md`, validation manifest, and NPA-1's landed ability/config pattern.
- Blockers or open questions: NPA-1's paired review is pending; its result and planning refresh are required before implementation.
## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh instruction: Bring the landed NPA-1 implementation summary, paired-review receipt, final ability/config API, final `enemy.gd` diff, and any correction-cycle changes back to this chat. Re-derive NPA-2 against that reviewed live seam before promoting it to `ready/auto`.
