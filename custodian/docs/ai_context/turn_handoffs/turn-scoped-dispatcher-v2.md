<!-- V2 turn metadata -->
Task identity: turn-scoped-dispatcher-v2
Task definition: owner-authorized:https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0#sha256=6eda0554429ff16bd5cdaf6c2923dad1d44d8b343c102821c346891ac2c1a03c at origin/main de9fb72d8f4f2c239c551d87797351c9093e21b8
Remote branch: agent/turn-scoped-dispatcher-v2
Acquisition mode: owner-authorized
Acquisition source: agent/turn-scoped-dispatcher-v2
Acquisition source commit: 817d9256bda6bd82035644a68f46f71e5bdd8943
Checkpoint base: 7dd45e37063f55deb34a0800498997457805f616
<!-- /V2 turn metadata -->

# Dispatcher V2 D2-007 conditional merge handoff

Workstream: `turn-scoped-dispatcher-v2`
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0
Implementation branch: `agent/turn-scoped-dispatcher-v2`
Candidate base reviewed for this turn: `de9fb72d8f4f2c239c551d87797351c9093e21b8`
Prior implementation branch head: `7dd45e37063f55deb34a0800498997457805f616`

Original goal: Complete D2-006 of the Dispatcher V2 integration: make new/resumable task selection advisory and fair, make V2 finish independent of prior-session/legacy lifecycle state, and align repository guidance with standard CI/branch protection and optional consequential review. D2-007 conditionally authorizes merge after required CI and branch protection pass on the exact latest PR head. The candidate remains inactive until that gate is met and the merge is verified.

Implemented: `dispatch.py claim` and `claim-next` use V2 task identity, packet bytes authenticated from fetched `origin/main`, normal/historical/owner-authorized modes, and temporary turn checkouts. `claim-next` excludes review packets, rotates across new/resumable tasks with a best-effort advisory cursor, and skips only tasks whose durable packet completion and branch reachability from `origin/main` agree. Missing cursor/session state cannot block resumption. V2 `workstream.py finish` now authenticates the attached V2 receipt and directly checkpoints/retires through `turn_dispatcher_v2`, without `RunTrace.resume`, a workstream mutex, or branch renaming. A focused real-Git lifecycle test proves fresh acquisition can rehydrate the completed checkpoint after retirement. Updated root/Godot guidance, lifecycle/current-state context, implementation plan, and `custodian-next`: standard GitHub CI and branch protection govern landing, ordinary review is optional, and two-hour expiry/fencing applies only to any future exclusive non-Git lease. Restored Chrome CDP as the default Chat Relay sender/reader on port 9223 and added explicit `*_firefox.py` entrypoints plus separate Firefox setup docs; neither browser path replaces or manages the other. Checkout-profile/LFS handling and private acquisition receipts remain integrated. Ignored Python caches are classified against tracked source by decoded code-object equality. The private historical archive was not read or changed.

Remaining: Wait for GitHub CI on the next checkpoint SHA. Run #42664061114 failed on `7dd45e3` in `paired_review_runner_unit`; the standalone 304-test suite and the exact changed-file validation command pass locally, so retain this as a CI/environment discrepancy to verify on the new run. Do not merge unless all required checks pass on the exact latest head. The candidate remains inactive on `origin/main`.

Validation: Earlier focused checks remain recorded above. After the D2-007 relay correction, Firefox relay tests passed (17); Chrome/Firefox/Firefox-MCP transport tests passed (21); all four Chrome and Firefox CLI help checks passed; the live Chrome reader was verified on port 9223. `python3 custodian/tools/validation/run_validation.py --changed --base de9fb72d8f4f2c239c551d87797351c9093e21b8 --max-tier unit --json` passed locally with 23/23 selected checks and complete changed-file coverage. `python3 -m unittest test_paired_review_runner -q` passed 304/304. The earlier GitHub run #42664061114 failed four historical source-span expectations in that suite; those exact tests pass locally, and this must be checked again on the next head. `git diff --check` passed. No full Godot validation is required for this tooling-only slice; GitHub CI/branch protection remains the merge gate.

Sources/evidence: D2-005 orchestration instructions and the exact `Authoring chat` above; Stage 3A architecture and implementation plan; V2 acquisition receipt in the repository Git common directory; scoped code diff and focused test evidence. No Godot/gameplay runtime or private archive data was part of this implementation.

Resume: Fetch `origin/agent/turn-scoped-dispatcher-v2`, verify the exact advertised SHA, inspect required CI on that exact PR head, and merge PR #123 only after all required checks pass. Verify the resulting `origin/main` SHA. Firefox support is additive through explicit `*_firefox.py` scripts; Chrome remains the default on CDP 9223. The root coordination checkout contains unrelated dirty user files and must remain untouched.
