# Paired-review process ownership scanner hardening V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-paired-review-process-ownership-scanner-hardening-v1`
- Category: `agent-ops`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `paired-review-host-validation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-paired-review-process-ownership-scanner-hardening-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Changing /proc-based review ownership verification is security-sensitive; a fresh independent reviewer must falsify spoofed-agent bypass and unknown-process handling.`
- Reviewed main: `56cc783004961c4c4df3d24795b409e27fadbb84`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeb925d-9748-83e9-ae97-11c4532466c2`
- Visual review: `none`
- Goal: `Resolve a demonstrated false-positive missing-checkout reviewer ownership scan when an independently authenticated same-user credential daemon has unreadable cwd, without relaxing checks on possible live review owners.`
- Completion boundary: `Implement and land one narrow /proc ownership-scanner correction with focused adversarial tests and canonical changed-file validation. Follow with independently accepted paired review. Original claimed review, its execution lock, run, branch, and evidence are untouched by this workstream.`
- Current measured state: `The original host_validation_recovery review-agent-paired-review-host-validation-recovery-v1-review-corrections-1 run 20261018T014101Z-f4fd619029aa retains a protected claim at dispatcher run 20261018T014109Z-6ce6f6c181be and holds paired-review-host-validation. The original claimed checkout is absent. The runner's _processes_owning_review_checkout currently scans every same-UID process and raises on /proc/<pid>/cwd PermissionError before identity matching. A host run was blocked on PID 3198415, observed as /usr/bin/gpg-agent --supervised; its process identity has NOT been independently authenticated by the scanner. An existing separate peer scanner in paired_review_finish_index_pass_recovery.py excludes credential-agent names, but that name-only rule is insufficient protection against spoofed comm values. No original reviewer launched or passed. A previously submitted plan has not been applied.`
- Evidence: `custodian/tools/agent/paired_review_runner.py::_processes_owning_review_checkout (around lines 6421-6460 on reviewed main); custodian/tools/agent/test_paired_review_runner.py; custodian/tools/agent/paired_review_finish_index_pass_recovery.py; original held run .git/custodian-review-runs/review-agent-paired-review-host-validation-recovery-v1-review-corrections-1/20261018T014101Z-f4fd619029aa/; live host report and original claim metadata.`
- Task-specific authority: `AGENTS.md; custodian/AGENTS.md; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md; paired_review_runner.py; reviewer ownership and exact-claim verification contracts; normal dispatcher/source-lock and independent-review lifecycle.`
- Work surface: `custodian/tools/agent/paired_review_runner.py; custodian/tools/agent/test_paired_review_runner.py; only directly necessary test fixtures in the same existing test file; minimal lifecycle documentation if the accepted semantics change. No separate scanner or dispatcher rewrite.`
- Publication inputs: `custodian/tools/agent/paired_review_runner.py; custodian/tools/agent/test_paired_review_runner.py; custodian/tools/agent/paired_review_finish_index_pass_recovery.py; custodian/tools/agent/dispatch.py; custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md.`
- Change: `Refactor only _processes_owning_review_checkout so the scanner obtains and checks readily accessible UID/name/argv identity evidence before requiring cwd. An unreadable cwd may be ignored solely for a narrowly enumerated, independently authenticated non-reviewing credential service matching the actual supervised gpg-agent case, with trustworthy identity evidence independent of the spoofable comm or caller-controlled argv alone (e.g. verified systemd service identity plus trustworthy executable identity when readable). If sufficient independent verification is unavailable, remain fail closed. Do not copy a name-only skip, treat all PermissionErrors as benign, skip arbitrary same-user services, or suppress process identity matching. Check known workstream/run/checkout tokens in readable argv before any exclusion. Continue to reject any possible reviewer owner, unknown/unreadable same-UID process, or replaced/mismatched service identity. Handle vanished PIDs without turning other /proc errors into silent success. Keep other runner recovery and claim logic byte-identical except for necessary call-site adaptation.`
- Preserve: `Exact missing-checkout review run and claim, branch/ref evidence, lock, original host reports, local relay changes, all other process scanning and authorization gates, source test selection and review acceptance; no original review retry or quarantine apply as part of this source correction.`
- Non-goals: `No manual /proc permission changes, kill/restart of gpg-agent, global process exclusion, environment-security disable, retry of the held reviewer, automatic lock release, new worktree by hand, new art/runtime changes, or review result fabrication.`
- Acceptance: `(1) Positive real and synthetic test confirms that a verifiably genuine supervised gpg-agent with unreadable cwd is classified non-reviewing under the documented trust boundary; if the actual host cannot supply independently verifiable identity, report BLOCKED rather than force eligibility. (2) Spoofed comm/argv, unrelated same-UID inaccessible cwd, unreadable independent identity, changed PID between reads, possible reviewer argv/workstream/run/checkout association, and a credential service with forged/ambiguous identity fail closed. (3) Genuine process referencing the exact lost checkout is reported as owner. (4) Existing foreign UID, vanished process, known trusted process, and scanner tests remain green. (5) Original protected review and relay evidence unchanged; focused Python and canonical changed-file validation complete with no uncovered paths. (6) Implementation lands only through claimed canonical lifecycle and receives a separate genuine paired-review PASS before any original-review recovery attempt.`
- Validation: `Add deterministic /proc fixture tests with injectable proc-root and process reads rather than depending on PID 3198415. Exercise verified supervised gpg-agent with denied cwd, fake name/argv, unknown inaccessible cwd, owner by argv or cwd, PID disappearance, identity ambiguity, and denied service verification; fail closed for every unknown case. Run PYTHONPATH=custodian/tools/agent:custodian/tools python3 -m unittest custodian.tools.agent.test_paired_review_runner -v; python3 -m py_compile custodian/tools/agent/paired_review_runner.py custodian/tools/agent/test_paired_review_runner.py; python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json; git diff --check. Require an independently sourced trusted-identity-positive proof on the actual Arch host before treating the observed PID as ignorable.`
- Task overrides: `none`
- Deferred: `After the blocker-review's execution lock has legitimately cleared and this packet has landed with accepted independent review, obtain a fresh exact-run read-only host recovery plan. Do not automatically apply it.`

## Next Handoff

- Next workstream: `review-agent-paired-review-process-ownership-scanner-hardening-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeb925d-9748-83e9-ae97-11c4532466c2`
- Refresh reason: `Source-authority and lock requirements are explicit.`
- Next action: `Claim once ready/auto and dispatcher confirms paired-review-host-validation free; implement narrow scanner/test change and land within one coding turn, then run the genuinely fresh paired review.`
- Blockers or open questions: `The original claimed host-validation correction reviewer currently holds paired-review-host-validation. Do not rename that lock or work around it. Its release requires canonical accepted review or separately approved evidence-preserving quarantine, not this source packet.`
