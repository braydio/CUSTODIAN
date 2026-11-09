<!-- V2 turn metadata -->
Task identity: turn-scoped-dispatcher-v2
Task definition: owner-authorized:https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0#sha256=6eda0554429ff16bd5cdaf6c2923dad1d44d8b343c102821c346891ac2c1a03c at origin/main de9fb72d8f4f2c239c551d87797351c9093e21b8
Remote branch: agent/turn-scoped-dispatcher-v2
Acquisition mode: owner-authorized
Acquisition source: agent/turn-scoped-dispatcher-v2
Acquisition source commit: 817d9256bda6bd82035644a68f46f71e5bdd8943
Checkpoint base: 89b81519825a5a238f89d68665e5068dfea7a60d
<!-- /V2 turn metadata -->

# Dispatcher V2 D2-007 conditional merge handoff

Workstream: `turn-scoped-dispatcher-v2`
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0
Implementation branch: `agent/turn-scoped-dispatcher-v2`
Candidate base reviewed for this turn: `de9fb72d8f4f2c239c551d87797351c9093e21b8`
Prior implementation branch head: `817d9256bda6bd82035644a68f46f71e5bdd8943`

Original goal: Complete D2-006 of the Dispatcher V2 integration: make new/resumable task selection advisory and fair, make V2 finish independent of prior-session/legacy lifecycle state, and align repository guidance with standard CI/branch protection and optional consequential review. D2-007 conditionally authorizes merge after required CI and branch protection pass on the exact latest PR head. The candidate remains inactive until that gate is met and the merge is verified.

Implemented: `dispatch.py claim` and `claim-next` use V2 task identity, packet bytes authenticated from fetched `origin/main`, normal/historical/owner-authorized modes, and temporary turn checkouts. `claim-next` excludes review packets, rotates across new/resumable tasks with a best-effort advisory cursor, and skips only tasks whose durable packet completion and branch reachability from `origin/main` agree. Missing cursor/session state cannot block resumption. V2 `workstream.py finish` now authenticates the attached V2 receipt and directly checkpoints/retires through `turn_dispatcher_v2`, without `RunTrace.resume`, a workstream mutex, or branch renaming. A focused real-Git lifecycle test proves fresh acquisition can rehydrate the completed checkpoint after retirement. Updated root/Godot guidance, lifecycle/current-state context, implementation plan, and `custodian-next`: standard GitHub CI and branch protection govern landing, ordinary review is optional, and two-hour expiry/fencing applies only to any future exclusive non-Git lease. Restored Chrome CDP as the default Chat Relay sender/reader on port 9223 and added explicit `*_firefox.py` entrypoints plus separate Firefox setup docs; neither browser path replaces or manages the other. Checkout-profile/LFS handling and private acquisition receipts remain integrated. Ignored Python caches are classified against tracked source by decoded code-object equality. The private historical archive was not read or changed.

Remaining: Finish the affected test suites and report their exact results, publish the exact candidate SHA, then use the standard GitHub CI/branch-protection path for cutover when directed. The candidate remains inactive on `origin/main`. Review is not a universal prerequisite; use it only if requested or warranted by consequential risk.

Validation: Passed after D2-006 corrections: `python3 -m unittest custodian.tools.agent.test_dispatch -q` (97); `python3 -m unittest custodian.tools.agent.test_turn_dispatcher_v2 -q` (31); `python3 -m unittest custodian.tools.agent.test_workstream -q` (95; two pre-existing ResourceWarnings and one expected fixture Git diagnostic); focused claim-next rotation/review exclusion (2); V2 finish lifecycle/re-hydration smoke (1); `python3 -m unittest custodian.tools.agent.test_turn_archive_v1 -q` (10); paired-review runner (304); paired-review findings closeout (38); packet index + contract (44); next-execution-boundary policy (18); Firefox MCP transport/UI tests (17); `python3 custodian/tools/validation/agent_workflow_smoke.py` passed, including dispatch suites 97/11, workstream suites 18/5/11, prompt contract, and workflow contracts. Chrome and Firefox CLI help checks passed, and the Chrome reader was verified against the live port-9223 session after restoring its known-good response parsing. `python3 -m py_compile custodian/tools/agent/*.py custodian/tools/orchestration/*.py`, `git diff --check`, and ignored-file inventory passed (76 paths, 0 unresolved). No full Godot/repository validation is required for this tooling-only slice; standard GitHub CI/branch protection remains the landing gate.

Sources/evidence: D2-005 orchestration instructions and the exact `Authoring chat` above; Stage 3A architecture and implementation plan; V2 acquisition receipt in the repository Git common directory; scoped code diff and focused test evidence. No Godot/gameplay runtime or private archive data was part of this implementation.

Resume: Fetch `origin/agent/turn-scoped-dispatcher-v2`, verify the exact advertised SHA, inspect required CI on that exact PR head, and merge PR #123 only after all required checks pass. Verify the resulting `origin/main` SHA. Firefox support is additive through explicit `*_firefox.py` scripts; Chrome remains the default on CDP 9223. The root coordination checkout contains unrelated dirty user files and must remain untouched.
