# REVIEW: NPA-7 COMMANDED ALLY RELATIONSHIP, TARGETING AND IDENTITY CONTRACTS

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-npa-7-commanded-ally-contracts`
- Kind: `review`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `npa-7-commanded-ally-contracts`
- Locks: `ally-runtime`
- Review: `none`
- Review target workstream: `npa-7-commanded-ally-contracts`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/NPA_7_COMMANDED_ALLY_CONTRACTS.md`
- Reviewed main: `4cbc6a67d1156fe7e87262203279835cffe1548f`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify that NPA-7 integrates commanded drones/droids with the existing relationship/targetability resolver, preserves autonomous-vs-explicit targeting behavior and squad identity/commands, and prevents a projectile from firing after target eligibility changes.
- Reviewed implementation acceptance: Evaluate every acceptance criterion of the archived implementation packet. Specifically verify shared resolver authority, the explicit-only passive Shrumb exception, pre-projectile and mid-burst revalidation, squad command and identity authority, and live non-Enemy drone/droid inheritance.
- Review evidence: Archived implementation packet and summary, landed implementation diff, `CombatDrone`/`AlliedInfantryDroid`, `DroneManager`/`DroneTargeting`/`DroneSquadState`, ActorAllegianceComponent/ActorRelationshipResolver, focused smokes/manifest and docs/ownership changes, changed-file validation and `git diff --check`.
- Correction threshold: Automatic passive/neutral scan acquisition; regression of explicit Shrumb orders; any shot fired after target is allied/dead/untargetable/freed; duplicate writable squad command/ID state; stale reference crashes; broken command propagation or slot reuse; navigation/weapon tuning drift; unrelated global hostility or bonded Vaultwing changes; insufficient meaningful test coverage.
- Focused validation: Re-run new NPA-7 real target-transition/shot smoke; the registered `actor_relationship_contract` and `allied_drone_navigation_walkability`; existing `drone_follower_commands_smoke.gd`, `main_scene_allied_droid_smoke.gd`, and when relevant `debug_collector_combat_drone_smoke.gd` directly unless implementation registered those IDs. Run relevant projectile and shared resolver regression if touched. Verify manifest source selection, changed-file checks, and LFS-safe diff verification.
- Review focus: Shared actor relationship authority remains singular. `DroneTargeting` distinguishes autonomous hostility checks from explicit Operator commands; no unintended friendly fire at final weapon commit. Squad mode, slot labels and roster remain with existing owner, and droid uses CombatDrone inheritance. No Vaultwing bond changes.
- Acceptance: Fresh-context findings-first review, pass only with zero blocking findings and no material missing evidence. Do not directly patch reviewed code. If correction is required, author a bounded correction/re-review packet through the existing paired review cycle.
- Non-goals: No new gameplay, drone tuning, art/audio/VFX, species/bond command rewrite, actor superclass, persistent identity, broader social/turret convergence.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Independent Review

- Review schema: `custodian.independent_review.v1`
- Reviewer provenance: `same-agent-fresh-context`
- Reviewed implementation SHA: `64306601e824012017d8f6a653438951e53a8975`
- Reviewed main SHA: `4cbc6a67d1156fe7e87262203279835cffe1548f`
- Verdict: `pass`
- Findings: `none`
- Evidence: The landed implementation was inspected at the source and commit level. `commanded_ally_targeting_contract`, `actor_relationship_contract`, and `allied_drone_navigation_walkability` each passed 1/1 after a fresh Godot import. Direct `drone_follower_commands_smoke.gd`, `main_scene_allied_droid_smoke.gd`, and `debug_collector_combat_drone_smoke.gd` all exited 0. The relevant projectile regression `enemy_direct_hit_awareness` passed 1/1. The new smoke proves actual projectile emission and cancellation after live target changes; source inspection confirms shared resolver allegiance, command-only passive Shrumb qualification, final shot-time validation, manager-owned orders, squad-state-owned mode/roster, and inherited droid integration. Manifest ownership entries cover all changed drone sources; changed-file routing reported complete coverage with no uncovered files. LFS-safe `git diff --check` passed using `git -c filter.lfs.process= -c filter.lfs.clean=cat -c filter.lfs.required=false diff --check 64306601e^ 64306601e`. The changed-file sweep selected 29 checks and had complete file coverage, but `review_pairing_contract` failed when it tried to write shared `FETCH_HEAD` under the read-only common Git directory; this unit-tier failure caused 12 downstream checks, including the drone checks, to be skipped. Those drone checks were run directly and passed. No blocking or material runtime/design defect remains.
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: medium
- What went wrong: `Fresh import initially lacked generated Godot class/import caches. The full changed-file sweep was interrupted by review_pairing_contract attempting to write FETCH_HEAD in read-only shared Git metadata; downstream checks were skipped by tier gating. The import also generated nine temporary Operator .import sidecars, which were removed.`
- Root cause / contributing factors: `The fresh ephemeral worktree had no .godot import cache, and the review sandbox exposes common Git metadata as read-only. The initial import emitted editor socket/settings diagnostics but completed asset import.`
- Prevention / pipeline improvement: `Initialize the Godot import cache before focused tests. For restricted paired-review worktrees, use matching durable target-workstream changed-file evidence alongside direct focused checks when repository-wide review-pairing validation cannot write FETCH_HEAD.`
- Tooling / docs drift discovered: `The review packet requires changed-file validation but does not mention the shared-Git-metadata write restriction in this read-only review environment.`
- Follow-up: `none`
- What worked: `All six prescribed focused/direct checks and the additional projectile regression passed; source and manifest ownership checks agreed with the acceptance boundary.`

## Handoff

- Next workstream: `non-player-fauna-bonded-command-convergence`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `NPA-8 requires reviewed NPA-7 command boundaries and the current stealth-perception and bonded Vaultwing runtime contracts, rather than assuming a generic NPC system.`
- Next action: `After the NPA-7 paired review passes, stop and return to this authoring chat for NPA-8 planning. Do not auto-author or claim NPA-8.`
- Blockers or open questions: `NPA-8 intentionally remains unauthored.`
