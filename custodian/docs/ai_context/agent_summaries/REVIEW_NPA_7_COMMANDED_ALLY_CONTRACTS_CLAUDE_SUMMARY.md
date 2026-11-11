# NPA-7 Commanded Ally Contracts — Independent Review

## Verdict

**Pass; no findings.** Reviewed implementation commit `64306601e824012017d8f6a653438951e53a8975`, included in current main `4cbc6a67d1156fe7e87262203279835cffe1548f`. The review was reconstructed from the archived implementation packet and summary, the review packet, landed source, docs, manifest and focused validation. No implementation-session transcript was used.

## Findings

None. `CombatDrone` composes the shared `ActorAllegianceComponent`; autonomous qualification delegates hostility/targetability to `ActorRelationshipResolver`, while the opted-in explicit command path allows passive Shrumb targets and still rejects invalid, dead, newly allied and untargetable targets. The manager remains the command/order owner, `DroneSquadState` remains the squad mode/roster owner, and `AlliedInfantryDroid` inherits `CombatDrone`. The final fire path revalidates before projectile creation and before subsequent burst rounds. No Vaultwing behavior or unrelated shared hostility policy changed.

## Validation

- `godot_import_preflight.py --project-dir custodian`: PASS, no checked-out LFS pointers.
- Fresh `godot --headless --path custodian --import --quit`: import completed; Godot printed editor socket/settings diagnostics in this restricted environment. Nine temporary Operator `.import` sidecars were removed.
- `commanded_ally_targeting_contract`: PASS, 1/1.
- `actor_relationship_contract`: PASS, 1/1.
- `allied_drone_navigation_walkability`: PASS, 1/1.
- Direct `drone_follower_commands_smoke.gd`, `main_scene_allied_droid_smoke.gd`, and `debug_collector_combat_drone_smoke.gd`: all exited 0.
- `enemy_direct_hit_awareness`: PASS, 1/1.
- Manifest ownership: all modified drone sources have corresponding validation owners; changed-file routing produced complete coverage and no uncovered files.
- Changed-file sweep: selected 29 checks and coverage was complete. `review_pairing_contract` failed because `git fetch --prune origin` could not write shared `FETCH_HEAD`; tier gating skipped 12 downstream checks. The required drone checks were run directly and passed.
- `check_ai_context.py --json`: PASS, 0 findings. `task_packet_index.py`: PASS after archiving. `validate_review_pairing.py`: blocked by the same read-only shared `FETCH_HEAD` path.
- LFS-safe `git diff --check 64306601e^ 64306601e`: PASS using `git -c filter.lfs.process= -c filter.lfs.clean=cat -c filter.lfs.required=false`.

The first focused attempt preceded import and could not load generated classes/resources. After import, all required focused checks passed. The broad sweep limitation is environmental and does not leave a material evidence gap for the NPA-7 review.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Fresh import was required; broad changed-file review was blocked at the unrelated pairing-contract check by read-only shared Git metadata.
- Root cause / contributing factors: The ephemeral review worktree lacked a `.godot` cache and shares Git metadata outside the writable review path.
- Prevention / pipeline improvement: Initialize import before focused runs; use direct focused checks plus matching implementation-finish evidence when a restricted worktree cannot update `FETCH_HEAD`.
- Tooling / docs drift discovered: The review packet does not mention the shared Git metadata write boundary.
- Follow-up: none
- What worked: Focused tests, source review and manifest mapping all agreed with the packet's acceptance criteria.

## Lifecycle

The review packet is complete and archived. The initial isolated Codex process could not write lifecycle traces or `FETCH_HEAD` in shared Git metadata, so its worktree was preserved. Recovery from the coordination context recorded the required Independent Review receipt on the archived implementation packet, reran the focused projectile check after synchronization (1/1 passed), and completed `workstream.py finish`. Review landing commit: `f7c1ea6b3b18ecce2754ef2cb9fa17985708dd7c`. The project-root checkout is synchronized and clean.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Next Handoff

- Next workstream: non-player-fauna-bonded-command-convergence
- Next packet state: refresh-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: NPA-8 requires reviewed NPA-7 command boundaries and the current stealth-perception and bonded Vaultwing runtime contracts, rather than assuming a generic NPC system.
- Next action: Return to the authoring chat for NPA-8 planning; do not auto-author or claim NPA-8.
- Blockers or open questions: NPA-8 intentionally remains unauthored and requires the planning refresh.
