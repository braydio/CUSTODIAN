# Review: NPA-4 Standard Enemy Melee Extraction

Fresh-context paired code, architecture, and runtime review of implementation commit `453bb87dc`, landed on current main `810fb93aa20209096e88a6422c832885f220b22c`. Reviewer provenance: `same-agent-fresh-context`.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Findings

No blocking defects, material evidence gaps, or non-blocking findings found. `StandardEnemyMelee` owns the ordinary attack lifecycle and mutable transaction state. The host retains damage, target selection, shared hit resolution, engagement coordination, reaction policy, presentation, and special abilities. The special-first dispatch seam remains in `Enemy`, and ordinary attack identity retains the `<instance>:<sequence>` form. Config resources retain the default values and Grunt, Marine, Savage, and Pursuit Frame overrides. The variant `attack_cooldown` compatibility value remains outside the melee module and does not bypass recovery/redecision cadence.

## Validation

- Passed: `standard_enemy_melee`, `enemy_grunt_notice_and_attack_cadence`, `enemy_hit_spatial_telemetry`, `combat_exchange_commitment`, `operator_guard_flow`, `grunt_falcon_punch`, `sundered_keep_marine_ambush`, `enemy_savage_pounce`, and `savage_runtime`.
- Confirmed the migrated ordinary-melee mutable field names are absent from `enemy.gd`.
- `git diff --check` for the reviewed implementation commit passed.
- The initial focused validation attempt occurred before the fresh worktree had a generated Godot global-class cache and failed during class resolution. A headless editor scan/import generated the cache; all nine focused checks passed afterward.
- No reviewed implementation files were changed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Fresh-worktree validation first ran without Godot's generated global-class cache; re-running after editor scan/import passed.
- Root cause / contributing factors: The claimed worktree had no local Godot import cache.
- Prevention / pipeline improvement: Initialize fresh Godot worktrees with the editor scan/import before script-based validation.
- Tooling / docs drift discovered: none in reviewed implementation; fresh-worktree import-cache prerequisite observed during review.
- Follow-up: none
- What worked: Explicit packet test IDs provided focused independent runtime proof.

## Next Handoff

- Next workstream: npa-5-enemy-reaction-posture-extraction
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: NPA-5 must be derived from the reviewed ordinary-melee interruption seam and current reaction/posture/parry-critical ownership.
- Next action: Stop at the planning gate; use the Authoring chat to remeasure current reaction/posture/parry-critical ownership and author NPA-5.
- Blockers or open questions: NPA-5 intentionally has no active implementation packet yet.
