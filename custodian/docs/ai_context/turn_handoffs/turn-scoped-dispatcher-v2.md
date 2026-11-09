<!-- V2 turn metadata -->
Task identity: turn-scoped-dispatcher-v2
Task definition: owner-authorized:https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0#sha256=6eda0554429ff16bd5cdaf6c2923dad1d44d8b343c102821c346891ac2c1a03c at origin/main de9fb72d8f4f2c239c551d87797351c9093e21b8
Remote branch: agent/turn-scoped-dispatcher-v2
Acquisition mode: owner-authorized
Acquisition source: agent/turn-scoped-dispatcher-v2
Acquisition source commit: 817d9256bda6bd82035644a68f46f71e5bdd8943
Checkpoint base: 05b2f71c331b8ac3662a963baf93830a70c995c1
<!-- /V2 turn metadata -->

# Dispatcher V2 D2-005 cutover candidate handoff

Workstream: `turn-scoped-dispatcher-v2`
Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0
Implementation branch: `agent/turn-scoped-dispatcher-v2`
Candidate base reviewed for this turn: `de9fb72d8f4f2c239c551d87797351c9093e21b8`
Prior implementation branch head: `817d9256bda6bd82035644a68f46f71e5bdd8943`

Original goal: Complete the D2-005 Stage 3B Dispatcher V2 integration candidate: make V2 the shared acquisition/checkpoint path, migrate the paired-review receipt boundary and repository guidance, preserve existing review/acceptance gates, and deliver the exact candidate for fresh independent review. This checkpoint is not a merge or production activation.

Implemented: `dispatch.py claim` and `claim-next` now use V2 task identity, packet bytes authenticated from fetched `origin/main`, normal/historical/owner-authorized modes, and temporary turn checkouts. `claim-next` excludes review packets so the paired-review runner remains the review entrypoint. `workstream.py start`, `resume`, and `checkpoint` share V2 acquisition/checkpoint behavior. `finish` accepts an authenticated V2 acquisition trace while retaining the existing validation, independent review, completion, and guarded landing gates. The paired-review runner authenticates V2 claim receipts against private acquisition records and source ancestry. Checkout-profile/LFS handling, recovery receipts, and stable coordination checkout guards remain integrated. Ignored Python caches are classified by decoded code-object equality against tracked source, avoiding false unresolved results from equivalent marshal encodings. Updated root and Godot agent guidance, lifecycle/context docs, task authoring messages, packet-index semantics, and `custodian-next` to describe V2 acquisition and distinguish it from review acceptance. The private historical archive was not read, changed, or required; no launcher/service startup path was found that independently invokes the old dispatcher.

Remaining: Obtain fresh-context independent technical review of this exact remote branch SHA. Correct any findings in bounded follow-up work and request re-review. Keep the candidate unmerged and inactive until the orchestrator explicitly directs the reviewed merge and its acceptance checks. A real feature task claim is a post-review orchestration step, not part of this cutover candidate.

Validation: `python3 -m unittest custodian.tools.agent.test_turn_dispatcher_v2 -q` (28 passed); `python3 -m unittest custodian.tools.agent.test_turn_archive_v1 -q` (10 passed); `python3 -m unittest custodian.tools.agent.test_dispatch -q` (96 passed, including V2 legacy-mutex/gate bypass and review-packet exclusion); `python3 -m unittest custodian.tools.agent.test_workstream -q` (94 passed); `PYTHONPATH=custodian/tools/agent python3 -m unittest test_paired_review_runner -q` (304 passed); `PYTHONPATH=custodian/tools/agent python3 -m unittest test_paired_review_findings_closeout -q` (38 passed); `python3 -m unittest custodian.tools.agent.test_task_packet_index -q` (12 passed); `python3 -m unittest custodian.tools.agent.test_task_packet_contract -q` (32 passed); `PYTHONPATH=custodian/tools/agent python3 -m unittest test_next_execution_boundary -q` (19 passed); workstream artifact/recovery suites (14 and 5 passed); `python3 custodian/tools/validation/agent_workflow_smoke.py` passed; the final V2 rerun passed 28 tests after the Python-cache verifier adjustment; Python compilation, 76-path ignored inventory (0 unresolved), and `git diff --check` passed. New regressions verify V2 receipt-to-private-acquisition binding and claim-next review exclusion. These are focused candidate checks; repository-wide validation and independent review remain outstanding.

Sources/evidence: D2-005 orchestration instructions and the exact `Authoring chat` above; Stage 3A architecture and implementation plan; V2 acquisition receipt in the repository Git common directory; scoped code diff and focused test evidence. No Godot/gameplay runtime or private archive data was part of this implementation.

Resume: Fetch `origin/agent/turn-scoped-dispatcher-v2`, verify the exact advertised SHA and this handoff, and have an independent fresh context review that SHA. Do not merge or activate before the review disposition and explicit orchestrator direction. The root coordination checkout contains unrelated dirty user files and must remain untouched.
