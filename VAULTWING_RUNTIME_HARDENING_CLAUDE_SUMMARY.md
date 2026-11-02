# Vaultwing Runtime Hardening — Closeout

## Outcome

`vaultwing-runtime-hardening` is implemented and synchronized with `origin/main@6a7eab57`. The implementation checkpoint is `884eee027`; the latest-main merge is `388b371ec` and the closeout commit follows it. The shared acoustic observation path remains the only hearing authority, and no combat tuning, bonding thresholds, or companion-command policy changed.

Bond cooldown, safe-feed dwell, and bond-trial clocks now advance through `VaultwingBondState.step()` called from the actor's fixed physics spine. Live first-bond behavior retains its existing transition signals and presentation; loading an already-BONDED save uses a separate silent reconciliation path that restores durable values and allegiance, clears hostile/transient state, and selects a safe behavior state without replaying transition cues. Damage compatibility eligibility now follows `ActorRelationshipResolver`; wild Vaultwings remain hostile-eligible and bonded allies do not. The unused `hostile_fauna` group, actor `attack_damage` export, and write-only `strike_contact_tested` field were removed after current-main searches found no consumers.

The required world-spawn validation exposed existing contract drift, corrected narrowly: the smoke now accepts serialized node attributes independent of `unique_id`, provides the ContractMap signals required by the production loader, and the spawner prunes into a typed `Array[Node]` without assigning untyped `Array.filter()` output. The smoke is now explicitly owned by Vaultwing actor changes in the manifest.

## Validation

After the final sync with `origin/main@6a7eab57`, focused checks passed 5/5: `vaultwing_bond`, `vaultwing_runtime`, `actor_relationship_contract`, `vaultwing_world_spawn`, and `perception_acoustic_contract`. The branch-relative changed-file report `/tmp/vaultwing-hardening-changed-final-6a7e-retry.json` selected 31 checks, passed 31, failed 0, timed out 0, skipped 0, and had complete coverage across 14 changed files with no uncovered files. Task-packet index validation passed; paired-review validation passed for 68 pairs; `check_ai_context.py --json` reported zero findings; `git diff --check` passed.

The initial focused attempt preceded the full import for this new worktree and failed only because global script classes were not registered yet. After the full Godot import completed, the focused suite passed. The first world-spawn run also confirmed the test fixture and typed-array issues described above; both were corrected and the focused spawn check passed afterward. One final full sweep and focused retry intermittently failed `world_transition_handoff` at the qualified Awakening-to-Hub completion assertion. A disposable diagnostic run captured the second transition succeeding with `final_context=hub`; the final full synchronized sweep then passed 31/31. The intermittent trigger remains unknown, and no unrelated transition code was changed.

## Preserved boundaries

Wild combat damage, timing, deterministic movement, feeding/trial policy, stable creature identity, and Asset V2 presentation remain unchanged. No shared hearing logic was recreated. No death/corpse policy, global save orchestration, SFX, bait inventory, or NPA-8 convergence was added. NPA-8 remains unauthored until the fresh-context Vaultwing review passes and the required planning refresh remeasures the reviewed chain.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The fresh worktree required a full import before global script-class checks could run. The required spawn validation also exposed a brittle serialized-node assertion, a typed-array pruning failure, and a missing ContractMap fixture. An unrelated `world_transition_handoff` assertion intermittently failed on two attempts; a diagnostic trace showed the Hub transition succeeding on a separate run, and the final full sweep passed.
- Root cause / contributing factors: The first import had not completed; the scene assertion depended on exact serialization; the validation fixture omitted the loader's contract-map binding; `Array.filter()` returned an untyped array incompatible with `Array[Node]` in Godot 4.7. The cause of the intermittent world-transition assertion was not established.
- Prevention / pipeline improvement: Finish first-import hydration before attributing class-cache failures; test effective scene declarations rather than exact serialized lines; rebuild typed arrays explicitly rather than assigning untyped filter results.
- Tooling / docs drift discovered: Vaultwing world-spawn validation ownership omitted the actor subtree, while its smoke fixture had drifted from the live scene/loader contract.
- Follow-up: fixed-in-scope
- What worked: Focused behavior checks and the complete synchronized changed-file sweep passed with no skips or uncovered files.

## Next Handoff
- Next workstream: review-vaultwing-runtime-hardening
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: Launch the paired review from a fresh reviewer context; after it passes, stop at the NPA-8 planning refresh gate.
- Blockers or open questions: none
