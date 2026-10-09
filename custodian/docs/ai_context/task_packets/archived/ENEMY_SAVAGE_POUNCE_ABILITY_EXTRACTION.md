# ENEMY SAVAGE POUNCE ABILITY EXTRACTION

- Packet schema: `custodian.task_packet.v2`
- Workstream: `enemy-savage-pounce-ability-extraction`
- Status: `complete`
- Dispatch: `auto`
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
- Reviewed main: `c8615e22a85337a5190f50df8587684793da322e`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Visual review: `none`
- Summary backlink: Include the exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Move the Savage pounce phase machine out of `enemy.gd` into one actor-local ability authority, reusing the landed Marine/Falcon host-service pattern without changing Savage rushdown behavior.
- Completion boundary: This slice owns Savage pounce state/tuning extraction, the narrow host-service seam required by it, focused pounce diagnostics/tests, validation ownership, and docs made false by the extraction. It does not own the Savage two-hit chain.
- Current measured state: NPA-1 is landed, independently reviewed, and passed with 0 blockers / 0 material gaps; the paired review landed as `8c204833a` and confirmed `MarineDash` + typed `MarineDashConfig` are the sole Marine Dash authority, all 26 defaults and 26 Marine-scene values match, `request_marine_dash(direction, distance)` is the public authored/debug start seam, focused Marine/spatial/Sundered-Keep/Falcon gates are green, and the implementation recorded a 23/23 changed-file closeout. Current `enemy.gd` is 4,615 lines by the reviewed count. Savage pounce is still entirely actor-owned: 13 numeric tuning exports (`windup_time=0.28`, `leap_time=0.18`, `recovery_time=0.55`, `distance_px=64`, `damage=18`, `knockback_px=52`, `cooldown=1.8`, launch band `44..132`, active window `0.20..0.86`, forward/lateral reach `30/22`) plus six mutable runtime fields (phase, timer, cooldown timer, direction, start position, hit-target IDs). `enemy_savage.tscn` enables pounce but overrides none of those numeric values. Pounce launch is attempted before the two-hit chain, owns windup -> leap -> recovery, uses the directional-lane spatial contract with 5 px origin tolerance, applies one hit, and is cancelled by parry/stagger/critical interruption while ordinary LIGHT damage and Vigil Fast-03 do not steal an already-committed Savage attack. The two-hit chain remains a separate actor-owned authority and is out of this slice.
- Evidence: Passed NPA-1 paired-review receipt `REVIEW_ENEMY_MARINE_DASH_ABILITY_EXTRACTION_RECOVERY_1_CLAUDE_SUMMARY.md` and archived review packet; `custodian/game/actors/enemies/abilities/{marine_dash,marine_dash_config}.gd`; `custodian/game/actors/enemies/abilities/configs/marine_dash_default.tres`; `custodian/game/actors/enemies/enemy.gd`; `custodian/game/actors/enemies/enemy_savage.tscn`; `custodian/game/actors/enemies/abilities/README.md`; `custodian/tools/validation/{enemy_savage_smoke,savage_runtime_smoke}.gd`; `custodian/tools/validation/validation_manifest.json`; `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`; `custodian/docs/ai_context/{CONTEXT,CURRENT_STATE}.md`.
- Task-specific authority: `design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`; current Savage runtime/scene tuning; live combat hit/engagement contracts; the landed actor-local ability service seam after NPA-1.
- Work surface: New focused `custodian/game/actors/enemies/abilities/savage_pounce.gd`, `savage_pounce_config.gd`, and `configs/savage_pounce_default.tres` (exact private filenames may differ only if the live ability convention has changed); `enemy.gd` host setup/delegation and shared-service calls; `enemy_savage.tscn`; `enemy_savage_smoke.gd` and `savage_runtime_smoke.gd`; validation-manifest ownership; active non-player architecture/context docs. Do not touch Savage chain execution except for the narrow shared cancellation/presentation query needed to ask whether pounce is active.
- Change: Extract Savage pounce by following the reviewed Marine/Falcon shape, not by inventing a generic ability base. Keep `savage_pounce_enabled` as the actor/archetype feature toggle, replace the 13 generic Enemy numeric pounce exports with one typed `SavagePounceConfig` resource preserving the exact values above, and move the six mutable pounce fields into one `SavagePounce` authority. The actor duplicates/binds the config at setup and ticks the ability at the same fixed-step priority where pounce cooldown/active phases run today, before chain/Falcon/Marine/strategic behavior. The ability owns launch eligibility (valid live player target, 44..132 band, cooldown), committed direction, threat-highlight lifecycle, windup/leap/recovery clocks, 64 px travel through the host's CharacterBody movement service, 0.20..0.86 contact window, directional-lane query (5 px origin tolerance, 30 forward / 22 lateral), one-hit bookkeeping, 18 damage, 52 px `apply_enemy_dash_impact` with the existing 0.04 victim hitstop, recovery/cooldown, cancellation, and read-only debug state. Reuse public host services already proven by Marine where semantics match (`is_combat_target_destroyed`, `resolve_ability_hit`, facing/path/presentation/observability/movement services) rather than reaching back into actor-private combat helpers. Update `get_behavior_attack_range()`, Savage presentation-priority checks, interruption paths, and Savage event diagnostics to ask the ability rather than reading removed actor fields. Preserve pounce-before-chain decision ordering; if pounce does not start, the existing two-hit chain path remains exactly as-is. Correct the NPA-1 ownership prose made stale by the landed extraction.
- Preserve: Current Savage HP/speed/base damage/profile behavior; pounce values and exact launch/contact/recovery/cooldown semantics; player-group target qualification; fixed-step ordering; one-hit and block/parry result behavior; the existing impact knockback/hitstop call; threat highlight and current authored-frame presentation fallback; BSM ownership; two-hit chain state/cadence/guard-pressure implementation; ordinary LIGHT damage not cancelling a committed Savage pounce/chain; Vigil Fast-03 not applying its ordinary Savage recoil while either Savage commitment is active; parry/stagger/critical interruption cancelling pounce; Marine/Falcon behavior and reviewed host-service boundaries.
- Non-goals: No two-hit chain extraction; no Savage balance pass; no new art/Asset V2 ingest; no generic ability base; no profile redesign; no loot/reaction refactor.
- Acceptance: `enemy.gd` no longer contains the 13 Savage-pounce numeric tuning exports or the six mutable pounce runtime fields, and no complete pounce phase/start/update/hit/recovery implementation remains there; one typed ability/config owns them. `savage_pounce_enabled` may remain as the archetype feature toggle. The Savage scene binds the focused config (or inherits its exact default resource) with byte-for-behavior-equivalent values. Launch range, cooldown, phase timing, 64 px travel, 18 damage, 52 px impact, 0.04 victim hitstop, active ratios, spatial reach, one-hit behavior, interruption behavior, pounce-before-chain ordering, and presentation-priority behavior are proven equivalent. Chain mutable state/methods and chain tuning remain unchanged. Focused validation consumes the typed ability/debug seam rather than mutating actor-private pounce fields. Validation ownership includes the new ability/config. No generic ability superclass is introduced; `enemy.gd` is net-negative by the removed pounce authority; NPA-1 ownership prose is current.
- Validation: Update and run `custodian/tools/validation/enemy_savage_smoke.gd` as the primary pounce-equivalence gate, covering exact config values, in-band/out-of-band launch, cooldown, windup/leap/recovery, one-hit window/damage, spatial miss, parry/stagger cancellation, ordinary-LIGHT non-cancellation, and chain-negative-control behavior through the typed ability/public diagnostic seam. Update/run `custodian/tools/validation/savage_runtime_smoke.gd` so presentation-priority assertions query the ability instead of writing removed actor fields. Keep validation-manifest ownership on the new ability/config and run the directly selected spatial/combat regressions (including `enemy_hit_spatial_telemetry` when selected). Finish with `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`. No renderer capture is required unless structured equivalence exposes a presentation defect.
- Task overrides: `none`
- Deferred: Savage two-hit chain extraction; pounce authored body/FX wiring; reaction/loot/generic melee decomposition; cross-family actor convergence.

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION_CLAUDE_SUMMARY.md; focused enemy_savage_pounce and savage_runtime gates pass; run_validation.py --changed --json selects 25, passes 25, and reports complete changed-file coverage; git diff --check passes; pounce mutable phase fields and numeric exports are removed from enemy.gd`

## Execution Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Fresh worktree required a one-time editor import; the import produced unrelated `.import` sidecars that were removed. The pounce smoke initially coupled its mock target to full enemy perception and carried world coordinates between cases; the fixture was made a physics body, perception was disabled for the isolated cases, and each scenario now resets actor/target placement. The first lifecycle finish attempt also identified that the packet Completion Truth headings needed the repository’s exact machine-readable field schema; that receipt is now corrected.
- Root cause / contributing factors: The old smoke directly controlled phase time and did not account for physics callback restrictions or physics-body requirements after switching to the extracted movement authority.
- Prevention / pipeline improvement: Keep ability movement smokes on real physics frames with a `CharacterBody2D` target and reset world positions between independent cases.
- Tooling / docs drift discovered: completion-truth field names/schema are enforced by workstream finish and were not explicit in the task packet template used at authoring time; the packet now follows the canonical receipt.
- Follow-up: none
- What worked: Existing public hit, movement, presentation, and diagnostic host services kept the extraction local without a generic ability base.

## Independent Review

- Status: `passed`
- Review workstream: `review-enemy-savage-pounce-ability-extraction`
- Reviewed on main: `9254c4406da86789f267dc9de912eae2e5f784a8`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime`
- Blocking defects: `0`
- Material evidence gaps: `0`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `none`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION_CLAUDE_SUMMARY.md`
- Follow-up workstream: `none`
- Reviewer independence: `Fresh paired-review workstream reconstructed acceptance from the archived implementation and review packets, landed diff, implementation summary, current architecture/service code, and independent focused validation. Reviewed implementation files were not modified.`

## Handoff

- Next workstream: `review-enemy-savage-pounce-ability-extraction`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Refresh reason: `none; NPA-2 has now been remeasured against the passed NPA-1 review and is executable`
- Next action: `claim and run the paired review from a fresh reviewer context`
- Blockers or open questions: `none`
