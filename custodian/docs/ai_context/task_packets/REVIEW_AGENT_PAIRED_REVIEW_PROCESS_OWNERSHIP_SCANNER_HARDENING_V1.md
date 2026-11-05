# REVIEW: Paired-review process ownership scanner hardening V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-agent-paired-review-process-ownership-scanner-hardening-v1`
- Category: `agent-ops`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Authoring handoff: `auto`
- Priority: `P1`
- Depends on: `agent-paired-review-process-ownership-scanner-hardening-v1`
- Locks: `paired-review-host-validation`
- Review: `none`
- Review target workstream: `agent-paired-review-process-ownership-scanner-hardening-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/AGENT_PAIRED_REVIEW_PROCESS_OWNERSHIP_SCANNER_HARDENING_V1.md`
- Reviewed main: `56cc783004961c4c4df3d24795b409e27fadbb84`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeb925d-9748-83e9-ae97-11c4532466c2`
- Visual review: `none`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: `Independently establish that the narrow credential-agent scanner correction can safely classify an authenticated non-review owner without admitting a spoofed owner or ignoring real review-session evidence.`
- Reviewed implementation acceptance: `True trusted credential-agent identity may be exempt from inaccessible cwd only when independent evidence authenticates the service; arbitrary same-UID processes, spoofed names/argv, missing identity signals, or processes referencing the claim remain fail-closed. No original review claim or lock is changed.`
- Review evidence: `Exact landed source and test diff, archived implementation packet, original fail-closed scanner before image, synthetic proc-root fixtures, actual Arch host trusted-service identity source, canonical changed-file validation with complete applicable coverage, protected original review evidence untouched.`
- Correction threshold: `Any unconditional name-based exemption, permission-denied silent skip, trusting caller-controlled argv alone, weak or absent binary/system-service authentication, race between PID/identity reads, inability to detect owner tokens, false PASS, material uncovered test path, or mutation of protected original review blocks PASS.`
- Focused validation: `Review the exact changed _processes_owning_review_checkout code, explicitly inspect process trust checks, replay genuine supervised gpg-agent with inaccessible cwd, spoofed process names and argv, unknown inaccessible process, review owner via argv/cwd, exited PID, and identity race; run targeted test_paired_review_runner.py, py_compile, run_validation.py --changed --base origin/main --json and git diff --check. Compare evidence and claimed lock identity before and after.`
- Review focus: `Strict identity verification independent of comm; no generic allowlist bypass; failure states remain fail-closed; genuine prevalidation missing-checkout path still requires the two exact operator attestations, exact claim/ref/branch/trace checks, and explicit recovery plan/apply. Claim and lock remain unchanged until their own lifecycle.`
- Acceptance: `Findings-first independent review PASS requires complete source and synthetic /proc regression evidence, authenticated positive host path or explicit fail-closed classification when trusted identity is impossible, clean changed-file coverage, and unchanged protected claims. Otherwise record stable R0-NN findings and use the canonical correction cycle. This PASS does not accept the original stranded review.`
- Non-goals: `No applying the stranded review's host recovery, reviewing any unrelated game feature, touching WIRE or PixelPlanets held review evidence, releasing any protected lock, changing source under independent review.`
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Review Procedure

1. Verify reviewed source commit, claim provenance, implementation archival and dispatcher independence before launching a fresh reviewer.
2. Inspect the exact process scanner and trusted credential-agent exemption against baseline, including root-owned/systemd service evidence if used.
3. Challenge every hard-coded allowed name and every possible PID identity spoof or race with deterministic fixtures.
4. Run focused tests, canonical changed-file validation and check that the original stranded run, claim, branch, and lock remain unmodified.
5. Produce canonical PASS or findings, archive review and retire worktree only through the ordinary review lifecycle.

## Next Handoff

- Next workstream: `none`
- Next packet state: `n/a`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6aeb925d-9748-83e9-ae97-11c4532466c2`
- Refresh reason: `none`
- Next action: `After independent PASS and actual lock eligibility, separately authorize one read-only original host recovery plan. Do not apply or reinterpret historical acceptance.`
- Blockers or open questions: `Release of paired-review-host-validation from the original claimed review is prerequisite to ordinary dispatch of both implementation and this review.`
