# NPA-6 Enemy Death, Corpse, and Loot Lifecycle Extraction

Implemented `npa-6-enemy-death-corpse-loot-extraction` in its claimed worktree. `EnemyLifecycle` + typed `EnemyLifecycleConfig` now own health/death state and arithmetic, one-time damage results and corpse payload construction, lootable/empty corpse transitions, and cleanup clocks. Enemy remains the combat coordinator and host-integration boundary; `EnemyCorpseLoot` remains the collection/reward authority, and `EnemyLootCarrier` remains the captured-resource authority.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Delivered

- Added `EnemyLifecycle`, typed lifecycle tuning, and per-archetype config resources. Migrated base Enemy, Grunt, Marine, Savage, Pursuit Frame, Fast/Heavy Drone, and dev cutout scene tuning without changing authored health, drops, corpse lifetimes, pickup radius, or marker offset.
- Preserved Enemy-facing `health`, `max_health`, `dead`, `life_state`, `take_damage`, `_damage_result`, `die`, and reification APIs. Lethal damage, paired-execution damage, death callbacks, event/stat order, host presentation, BSM/ability shutdown, observability, camera, and world-history remain host coordinated.
- Kept payload rolling after Enemy's observability and velocity updates, matching the prior death sequence. The lifecycle makes payload construction once-only and retains the configured-table rule that suppresses legacy PARTS even when no usable typed amount is produced.
- Updated loot/reification validation callers to use supported lifecycle APIs. Expanded `lootable_corpse_beacon` with damage-result parity, pre-ready health overrides, repeated death, invalid collector, fallback suppression, and minimum/on-screen/offscreen/hard cleanup checks. Added `enemy_lifecycle_config` coverage for all migrated scenes and default tuning.
- Reconciled `CURRENT_STATE.md`, the Enemy ownership map, and the NPA runtime architecture roadmap.
- `enemy.gd` is 3,832 lines versus 3,946 at the worktree base, a net reduction of 114 lines.

## Validation

- Focused lifecycle, loot, reification, and combat regressions: 10/10 passed.
- Typed lifecycle config smoke: passed.
- Changed-file sweep: 40/40 passed, zero failures/timeouts, complete file coverage. Report: `/tmp/npa6-changed-validation.json`.
- `git diff --check`: passed.
- `check_ai_context.py --json`: passed with zero findings.
- Initial validation found an invalid GDScript nested-enum cast and a loot-toast smoke assertion that assumed a fixed count despite random typed drops. Both were corrected. The first changed sweep then showed missing manifest ownership for migrated config resources; the config smoke closed the gap and the complete rerun passed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: The initial parse pass rejected using the nested `LifeState` enum as a constructor; the existing corpse smoke expected exactly two toasts even when random loot produced additional valid entries; the first changed sweep exposed missing owners for migrated scene configs.
- Root cause / contributing factors: GDScript enums are integer-backed namespaces, toast count varies with loot RNG, and moving serialized values to typed resources requires explicit config-test ownership.
- Prevention / pipeline improvement: Keep enum-backed façade values integer typed, assert reward categories instead of random counts, and add config-parity ownership whenever scene-authored values move to resources.
- Tooling / docs drift discovered: None.
- Follow-up: fixed-in-scope
- What worked: Focused lifecycle behavior checks plus a config smoke made the ownership and scene-value contract machine-verifiable.

## Next Handoff

- Next workstream: review-npa-6-enemy-death-corpse-loot-extraction
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: Run the paired post-land review through `paired_review_runner.py` in its fresh reviewer context. After it passes, stop at the NPA-7 planning refresh gate.
- Blockers or open questions: none
