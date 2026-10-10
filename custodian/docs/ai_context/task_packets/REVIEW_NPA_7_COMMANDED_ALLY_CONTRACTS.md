# REVIEW: NPA-7 COMMANDED ALLY RELATIONSHIP, TARGETING AND IDENTITY CONTRACTS

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-npa-7-commanded-ally-contracts`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `npa-7-commanded-ally-contracts`
- Locks: `ally-runtime`
- Review: `none`
- Review target workstream: `npa-7-commanded-ally-contracts`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/NPA_7_COMMANDED_ALLY_CONTRACTS.md`
- Reviewed main: `55905da45588857f4c6847aaba5b506d090a4a3a`
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

## Handoff

- Next workstream: `non-player-fauna-bonded-command-convergence`
- Next packet state: `refresh-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166`
- Refresh reason: `NPA-8 requires reviewed NPA-7 command boundaries and the current stealth-perception and bonded Vaultwing runtime contracts, rather than assuming a generic NPC system.`
- Next action: `After the NPA-7 paired review passes, stop and return to this authoring chat for NPA-8 planning. Do not auto-author or claim NPA-8.`
- Blockers or open questions: `NPA-8 intentionally remains unauthored.`
