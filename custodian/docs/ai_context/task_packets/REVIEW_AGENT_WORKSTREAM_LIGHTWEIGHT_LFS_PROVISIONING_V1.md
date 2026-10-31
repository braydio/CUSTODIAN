# REVIEW: Lightweight worktree provisioning and interrupted-claim recovery

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-workstream-lightweight-lfs-provisioning-v1`
- Category: `agent-ops`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `agent-workstream-lightweight-lfs-provisioning-v1`
- Locks: `worktree-provisioning-transaction`
- Kind: `review`
- Review: `none`
- Review target workstream: `agent-workstream-lightweight-lfs-provisioning-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_WORKSTREAM_LIGHTWEIGHT_LFS_PROVISIONING_V1.md`
- Reviewed main: `a6d6206070b4b1f2f4dd12b7b4da3a36c910e3ac`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently falsify the deferred-LFS worktree and same-claim recovery contract, including storage preflight, exact identity binding, local-only asset hydration, and the preserved Awakening profile.
- Reviewed implementation acceptance: Verify each claim in the archived implementation packet against the exact landed source, focused tests, fixture byte measurements, and durable run reports. Reconstruct dispatch/workstream ownership, mutex/CAS behavior, checkout profile provenance, import gate, and original failed-start recovery from repository sources rather than trusting the implementation summary.
- Publication inputs: `custodian/tools/agent/workstream.py`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/workflow_control.py`; `custodian/tools/agent/test_workstream.py`; `custodian/tools/agent/test_dispatch.py`; `custodian/tools/operator/operator_art_worktree.py`; `custodian/tools/validation/operator_art_worktree_smoke.py`; `custodian/tools/pipelines/godot_import_preflight.py`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`; `custodian/docs/ai_context/task_packets/AWAKENING_GATE_LATERAL_OVERLOOKS_BLOCKOUT_V1.md`.
- Review evidence: Exact implementation commit/diff and archived target packet; new and existing dispatch/workstream unit tests; disposable remote and LFS fixtures; measured checkout sizes; local-only hydration and import-preflight evidence; source and test proving the actual Awakening claim remains unchanged. Never apply recovery to the real Awakening claim or run its Godot scene tests in reviewer context.
- Correction threshold: Any second/new claim, altered/released original claim, acceptance without authenticated run/host/process and ref identity, recovery from partial/dirty/ambiguous worktree state, capacity check after claim mutation, network/unscoped LFS hydration, unverified profile or import with present pointers, weakened full-mode behavior, or modified original diagnostic evidence is blocking. Report concrete findings; do not repair reviewed implementation.
- Focused validation: Run `python3 -m unittest custodian.tools.agent.test_workstream custodian.tools.agent.test_dispatch -v` and the new exact fixture tests; verify py_compile, changed-file coverage, fixture size evidence, and `git diff --check`. Re-run only targeted checks needed to falsify a specific acceptance claim. Do not start Godot, broadly hydrate LFS, clean storage, or mutate protected claims/locks.
- Review focus: (1) Verify preclaim size estimation includes LFS payload and reserve and cannot leave a stranded dispatch claim on predictable ENOSPC. (2) Verify temporary deferred mode never alters global config, profile paths are exact/tracked/bounded, and checkout really omits unrelated LFS objects. (3) Verify hydration binds expected pointer OID/size, is local-only and path-scoped, and the Godot import preflight blocks remaining present pointers. (4) Attack every same-claim recovery predicate: run and claim IDs, original claim SHA, branch/base, branch publication, worktree registration/path, complete same-host process scan, active/foreign/ambiguous owner, dirty/partial checkout, profile digest, LFS availability, and remote ref races. Confirm all checks are repeated under the mutex immediately before side effects and recovery never acquires/releases a claim. (5) Confirm tests include the actual failed-start shape without touching its real host evidence. (6) Confirm the Awakening profile contains both exact Gate plates and is sufficient for the packet's validation surface, while its first actual use remains post-review only.
- Acceptance: Record a canonical findings-first fresh-context verdict. PASS only if all implementation acceptance claims have repeatable evidence, the exact same-claim recovery is adversarially fail-closed, the profile/hydration gates preserve Godot correctness, and no protected claim or original evidence was touched. No reviewer edits to implementation. The reviewer does not recover the actual Awakening claim.
- Non-goals: Execute actual Awakening recovery; claim/park/release any protected workstream; alter the implementation or task packet; hydrate broad LFS content; perform visual/design approval.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure
1. Claim only after the implementation lands complete and dispatcher confirms this exact review is eligible.
2. Start a fresh independent reviewer context and reconstruct the contract from the archived packet, commit, source, tests, and fixture evidence.
3. Run focused tests and inspect all positives and adversarial negatives, including no-touch proof for the preserved Awakening claim.
4. Record PASS or concrete findings; never perform recovery against the real claim.
5. Close through the canonical paired-review lifecycle.

## Handoff
- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933`
- Refresh reason: `none`
- Next action: After accepted PASS, let the coordinator perform a separate exact-identity audit and same-claim Awakening recovery.
- Blockers or open questions: The protected Awakening worktree and original run remain absent/unrecovered until independent acceptance.
