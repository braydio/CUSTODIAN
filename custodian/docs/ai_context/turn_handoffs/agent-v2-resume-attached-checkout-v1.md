<!-- V2 turn metadata -->
Task identity: agent-v2-resume-attached-checkout-v1
Task definition: custodian/docs/ai_context/task_packets/AGENT_V2_RESUME_ATTACHED_CHECKOUT_V1.md at origin/main 98dcde474ed92ae36a1d45c5f8faf94b1e75d1f6
Remote branch: agent/agent-v2-resume-attached-checkout-v1
Acquisition mode: normal
Acquisition source: origin/main (no prior branch; fresh start)
Acquisition source commit: 33b24daeae754413fd413387527bcaf87755073d
Checkpoint base: 1bb20877a60706e2c9bc658e5328619e42d80f03
<!-- /V2 turn metadata -->

# Turn Handoff — Agent V2 Attached-Checkout Resume

Original goal: Implement DEBT-0001 so the public V2 `workstream.py resume <id>` command safely reuses one authenticated, attached, clean V2 checkout while preserving the original acquisition and leaving fresh `begin()` behavior unchanged.

Implemented: Commit `1bb20877a60706e2c9bc658e5328619e42d80f03` adds authenticated attached-checkout resume in `turn_dispatcher_v2.py` and routes only the public `resume` command through it. The resume path verifies the original acquisition receipt, managed pool, shared Git common directory, canonical branch, source ancestry, origin identity and remote branch head, current packet provenance, clean tracked/untracked state, ignored-data classification, process ownership, and the existing continuation lock. Repeated resume preserves checkout, turn ID, run ID, receipt bytes, branch, and history. A retired checkout follows the existing fresh-checkout resume behavior. `begin()` and dependency-metadata `reauthorize_checkout()` remain separate.

Validation: `python3 -m unittest custodian.tools.agent.test_turn_dispatcher_v2 custodian.tools.agent.test_workstream` passed (147 tests). `python3 custodian/tools/validation/run_validation.py --changed --json` passed all 6 selected checks with complete changed-file coverage. Task-packet authoring, `check_ai_context.py`, `task_packet_index.py`, and `git diff --check` passed. Sources/evidence: The tests use isolated temporary Git repositories; the preserved Operator claim was not started or modified.

Published branch: `origin/agent/agent-v2-resume-attached-checkout-v1` at `1bb20877a60706e2c9bc658e5328619e42d80f03` before this handoff checkpoint.

Remaining: Open the implementation PR, wait for GitHub CI and branch protection, land through the normal protected path, verify the exact landed source and main synchronization status, then update DEBT-0001 only after acceptance evidence is verified. No main landing is claimed. Validation-runner cancellation/surviving-child cleanup remains a separate follow-up.

Resume: Continue `agent-v2-resume-attached-checkout-v1` from its authenticated remote branch after verifying current `origin/main`, the workstream receipt, and absence of a competing process owner. Do not reopen the relay conversation unless a response is needed; use the existing response poller at 120-second intervals.
