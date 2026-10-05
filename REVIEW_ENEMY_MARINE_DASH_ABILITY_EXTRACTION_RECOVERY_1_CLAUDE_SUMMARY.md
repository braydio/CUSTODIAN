# Marine Dash Extraction Recovery 1 — Independent Review

Review outcome: **pending**, solely on the required changed-file coverage gate. Marine implementation review found zero blocking defects and one non-blocking documentation issue. No reviewed implementation or unrelated files were edited.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search

## Findings

- **R0-02 — medium, evidence_gap, pipeline, pending / external repair.** The packet requires a green complete changed-file closeout without exemptions. On landed main `1ba0981e7859fa91ae86ea3bc638c0ce2474a1ad`, `run_validation.py --changed --base 9af2adf59^ --json` selected 23 tests; all 23 passed, with zero failures, timeouts, skips, or infrastructure errors. Its overall `passed` is false and exit code is 6 because `.agents/skills/custodian-next/agents/openai.yaml` alone lacks an owner. That path was introduced by unrelated `48d0871bb`. This prevents the required green proof, not confidence in Marine behavior. Preserve the review workstream; repair genuine ownership upstream rather than add an exemption or change reviewed code. Original report: `/tmp/npa1-review-closeout.json`, SHA-256 `5294b66b0fefe439cc2bd8ab0d244a8e0b8de3b6f3224154531e2224c9483803`.
- **R0-01 — low, non_blocking_issue, implementation, next_slice.** `custodian/docs/ai_context/CONTEXT.md:117` still assigns generic Marine dash phases to `enemy.gd`; `CURRENT_STATE.md:1486` still places the tactical heavy commitment move in that file. The newer ownership map, extraction status, and design runtime-ownership section correctly identify `MarineDash`. Refresh these older prose references with NPA-2 authoring. Affected acceptance: consequence-driven documentation describes the final owner. This is not duplicate runtime authority and does not warrant a combat correction.

## Reconstruction and architecture

- Reviewer context: fresh. Reviewer provenance: same-agent-fresh-context. Separate claimed review workstream; reconstructed from repository authority, review/archived implementation packets, implementation closing summary, checkpoint `9af2adf5914ed799f4c7ee7606202b03ea5a95f1`, live source and changes, NPA architecture, ownership map, focused tests and fresh reports.
- Reviewed landed main: `1ba0981e7859fa91ae86ea3bc638c0ce2474a1ad`; implementation checkpoint and later closeout `e2415fcc7` are ancestors. Marine runtime/config/scene/ambush and focused tests are unchanged from checkpoint `9af2adf59`.
- Graph-first review attempted detect_changes/get_review_context on the coordination checkout and tests_for/affected_flows in the isolated checkout. Root graph was stale and could not supply reliable GDScript coverage; worktree graph was empty. Used targeted source/diff and actual registered-test evidence.
- `MarineDash` alone owns cadence, phase clocks, direction/prediction, charge budget, contact/travel, impact/recovery/reset, lifecycle IDs/terminals, and warning presentation. `MarineDashConfig` owns tuning. No old Marine phase/timer/target/reset state remains in `Enemy`, and no runtime caller reaches the old private phase helpers.
- `Enemy` delegates before strategic BSM processing and supplies shared movement, target qualification, hit resolution/context, facing/presentation, observability, hitstop and camera services. Existing Falcon/Savage runtime is preserved; no generic ability base or cross-family inheritance was introduced.
- Sundered Keep uses `request_marine_dash`; host-target queries, one-shot prediction at 62% windup, active contact lane, one-hit defense outcomes, cadence accrual only during launch evaluation, and reset side alternation retain the original semantics.
- Independent historical-source parity script compared every old exported default and every old Marine scene float to the new config/resource: **26/26 defaults and 26/26 scene values match exactly**. `enemy.gd` has **4,615 lines versus 4,958**, exactly **343 fewer**.
- Manifest ownership covers Marine ability/config/resource/scene, spatial telemetry, and production ambush. The Falcon closeout repair reads the ordinary-critical animation's actual first-frame texture rather than an absent profile key; the fresh Falcon Reversal check passes.

## Validation

- LFS import preflight: PASS, no checked-out pointers. Fresh-worktree headless editor import: exit 0; tracked tree stayed clean.
- `authored_vault_grunt_loot_marine`: PASS; exact quick/charged clocks, prediction lock/no steering, phase transitions, recovery contact exclusion, reset/cadence and wall collision. Report `/tmp/npa1-review-authored_vault_grunt_loot_marine.json`.
- `enemy_hit_spatial_telemetry`: PASS; stable IDs/context, exactly one contact/impact, damaged/dodged/parried/block-hitreact/blocked outcomes and whiff terminal. Report `/tmp/npa1-review-enemy_hit_spatial_telemetry.json`.
- `sundered_keep_marine_ambush`: PASS; production-map staging, original 1.4-second cadence credit, tuned scene resource, public request/telegraph, active/idle/complete restoration. Report `/tmp/npa1-review-sundered_keep_marine_ambush.json`.
- Full changed-file closeout: **23/23 checks PASS; overall FAIL on one unrelated uncovered YAML path** (R0-02). No tests were filtered out or exempted.
- `task_packet_index.py`: fails on known uninitialized managed block; no automatic migration performed. This helper is not the failed closeout gate.
- Moment Forge: not run — behavior-preserving extraction is covered by deterministic logic, contact, telemetry, and production-map assertions. No subjective visual decision is required.

## External owner repair needed

In a separate authorized workstream, give `.agents/skills/custodian-next/agents/openai.yaml` a genuine focused validation owner in `custodian/tools/validation/validation_manifest.json`. The natural owner is `agent_workflow_contract`; its current smoke does not inspect this metadata, so extend the owner check to validate the installed skill metadata/explicit invocation contract rather than merely adding a coverage exemption. Re-run that focused owner and the original 23-check closeout on updated landed main; retain this review's finding IDs and resolve R0-02 only when the complete report is green.

`validate_review_pairing.py`: PASS (28 automatic-review packets paired). `git diff --check`: PASS. `check_ai_context.py`: FAIL with 11 unrelated findings in untouched historical archived packets, the existing README heading, and Twin Solaria packets. None identifies the new review artifacts. Those diagnostics and the documented uninitialized index migration were not silently repaired within this review.

## Deferred / awkward details

The initial repeated --test invocation selected only the final test. It failed on absent imports/classes in the fresh cache, not a Marine defect. After import, three separate serial focused runs passed. The full closeout then exposed independent metadata coverage drift from intervening main commits. This review cannot be marked passed or torn down while the required overall report is false. NPA-2 remains blocked/manual and architecture-refresh gated; this review does not silently promote it.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: blocked
- Friction severity: medium
- What went wrong: Every selected closeout test passed, but the report failed coverage for unrelated current-main skill metadata; an initial focused invocation ran only its final repeated --test argument and encountered the fresh worktree's empty import cache.
- Root cause / contributing factors: Commit 48d0871bb added .agents/skills/custodian-next/agents/openai.yaml without a validation owner. The focused CLI accepts one --test value, and fresh worktrees need initial Godot import before tests that omit needs_import.
- Prevention / pipeline improvement: Repair the skill metadata's genuine validation ownership in a separate workstream; run individual focused IDs serially after import preflight/import.
- Tooling / docs drift discovered: task_packet_index.py cannot find its uninitialized managed Ready/Auto block; VALIDATION_RECIPES.md explicitly documents that migration as separately reviewable. Stale Marine ownership prose remains in CONTEXT.md:117 and CURRENT_STATE.md:1486.
- Follow-up: manual-follow-up
- What worked: Independent 26-default/26-scene parity, state/caller audit, focused runtime gates, and all 23 selected closeout checks passed.

## Next Handoff
- Next workstream: review-enemy-marine-dash-ability-extraction-recovery-1
- Next packet state: dependency-gated
- Refresh owner: execution-agent
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6abb151e-693c-83ea-8563-b7cd74c2960b?src=history_search
- Refresh reason: Required closeout is not green until current-main skill metadata has a validation owner.
- Next action: Repair the unrelated coverage owner separately, then synchronize and resume this same review. After a passed review, refresh enemy-savage-pounce-ability-extraction in the authoring chat before implementation.
- Blockers or open questions: .agents/skills/custodian-next/agents/openai.yaml is the sole uncovered path in /tmp/npa1-review-closeout.json; no Marine blocking defect found.
