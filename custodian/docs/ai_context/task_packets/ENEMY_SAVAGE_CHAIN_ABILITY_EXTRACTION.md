# ENEMY SAVAGE CHAIN ABILITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `enemy-savage-chain-ability-extraction`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `enemy-savage-pounce-ability-extraction`
- Locks: `enemy-runtime`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-enemy-savage-chain-ability-extraction`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `state-machine/ownership extraction; independent review should verify two-hit/guard-pressure equivalence and removal of parallel state`
- Reviewed main: `92b05fa966`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Move the Savage two-hit chain lifecycle out of `enemy.gd` into one actor-local ability authority while preserving the existing rushdown cadence and guard-pressure semantics.
- Completion boundary: This slice owns only the Savage chain's state/tuning/execution extraction, its narrow host-service seam, focused diagnostics/tests, validation ownership, and docs made false by the extraction. Pounce is already owned by the dependency; ordinary generic enemy melee remains for the next program slice.
- Current measured state: NPA-3 remains two steps downstream. NPA-1 has a validated but unlanded Marine extraction checkpoint (`9af2adf59`); NPA-2 is now deliberately refresh-gated on the passed NPA-1 review. Therefore the exact Savage-chain host-service seam must not be frozen from the old `main@02ca0025b8` snapshot. On current production main, Savage pounce and two-hit chain phase machines remain hosted by `enemy.gd`.
- Evidence: `custodian/game/actors/enemies/enemy.gd`; `custodian/game/actors/enemies/enemy_savage.tscn`; `custodian/game/actors/enemies/abilities/README.md`; `custodian/docs/ai_context/CURRENT_STATE.md`; `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`; landed NPA-1/NPA-2 ability seams.
- Task-specific authority: `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`; live Savage tuning/behavior; shared enemy hit/engagement/guard-stamina contracts; landed actor-local ability service seam.
- Work surface: `custodian/game/actors/enemies/abilities/`, focused typed config if warranted, `enemy.gd`, `enemy_savage.tscn`, Savage/combat validation and manifest ownership, current ownership docs.
- Change: Extract the complete Savage two-hit chain lifecycle: phase/clocks, first-to-second transition, gap and second windup, damage/guard-stamina requests, recovery/interruption/reset, target/attack identity needed for deterministic resolution, and read-only diagnostics. Reuse host services instead of moving generic combat gateways into the ability. Move chain-specific tuning out of generic Enemy exports where practical. Delete old duplicate chain state/methods from `enemy.gd`. Do not fold the chain into generic ordinary melee yet; first establish clean special-ability ownership and let NPA-4 compare the remaining generic path against real extracted consumers.
- Preserve: Current Savage rushdown cadence, two-hit damage and guard-stamina pressure, attack result semantics, BSM behavior/profile, pounce behavior from NPA-2, presentation fallback, engagement coordination, Operator guard/parry behavior, deterministic fixed-step execution.
- Non-goals: No ordinary melee extraction; no Savage balance change; no new animation art; no generic ability hierarchy; no Operator guard refactor; no reactions/loot refactor.
- Acceptance: Savage chain mutable phase/timer state and complete phase methods are removed from `enemy.gd`; one extracted ability owns the lifecycle without parallel state; existing tuning and two-hit/guard-pressure behavior remain equivalent; pounce ownership from NPA-2 is untouched; focused tests use the ability/public diagnostic seam instead of actor-private chain fields; validation ownership follows the module; after this packet, `enemy.gd` contains no Marine Dash, Savage pounce, or Savage chain phase machine.
- Validation: Use existing combat/Savage/guard tests selected by the live validation manifest after fresh-main inspection, extending the narrowest appropriate coverage for two-hit order, gap/windup, damage, guard-stamina request, interruption, and recovery. Add/register a focused gate if existing tests cannot prove the chain contract, but do not invent a pre-claim nonexistent path. Run `python3 custodian/tools/validation/run_validation.py --changed --json` once at closeout. No visual capture is required for a behavior-equivalent ownership extraction.
- Task overrides: `none`
- Deferred: NPA-4 ordinary enemy melee execution/cadence extraction; shared reaction/critical authority; corpse/loot lifecycle; cross-family convergence and final compatibility cleanup.

## Handoff

- Next action: after NPA-2 lands **and its paired review passes**, return to this planning chat, remeasure Savage chain callers/state/tuning and the actual reviewed pounce/Marine service seams, then rewrite this packet in place to `ready/auto`.
- Best starting files: `enemy.gd`, `enemy_savage.tscn`, landed Marine/Pounce ability modules, and the narrow Savage/combat validation selected by the manifest.
- Blockers or open questions: reviewed NPA-2 is required; this planning packet intentionally does not assume the final pounce service API.
## Refresh Planning Authority

- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Refresh planning chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search`
- Refresh instruction: Bring the landed NPA-2 implementation summary, paired-review receipt, final pounce ability/config API, and current `enemy.gd` chain ownership back to this chat. Re-derive NPA-3 against that reviewed live seam before promoting it to `ready/auto`.