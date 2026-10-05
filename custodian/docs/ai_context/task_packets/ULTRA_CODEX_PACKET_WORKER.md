# ULTRA CODEX PACKET WORKER

- Packet schema: `custodian.task_packet.v2`
- Workstream: `ultra-codex-packet-worker`
- Status: `ready`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `agent-dispatch-claim-receipt-hardening`
- Locks: `agent-workflow`
- Kind: `implementation`
- Review: `none`
- Reviewed main: `ae172b7ffbb90ba622228182426f25d70fe09c30`
- Authoring chat: `not-recorded`
- Goal: Bootstrap and prove a persistent, bandwidth-conservative Codex worker on the user's Ultra.cc "Speedboat Ops" seedbox that can autonomously claim explicitly eligible CUSTODIAN task packets, implement them serially, validate, checkpoint/land safely, and return to an idle clean state without competing with Codex sessions on the user's local computer.
- Completion boundary: Done when one persistent single-checkout Ultra worker is installed through the repository-native claim/landing model, only explicitly Ultra-eligible packets can auto-run, LFS/media downloads remain fail-closed, one live smoke proves claim/checkpoint-or-land/idle cleanup, and any unavoidable user authentication step is isolated and documented without copying secrets.
- Current measured state: CUSTODIAN already has repository-native packet dispatch, remote claim refs, stable `agent/<workstream-id>` branches, push-first recovery, serialized `land_main.py` landing, artifact finalization, and packet metadata. The user's local machine already has an active CUSTODIAN checkout and Codex sessions; the seedbox has npm available to the non-root user but does not yet have the CUSTODIAN worker installed. The current normal lifecycle creates sibling ephemeral worktrees, while the desired Ultra footprint is one live repository working directory and one task at a time. Large media/asset types are Git LFS-backed in this repository and must not be silently downloaded on the seedbox.
- Evidence: current agent dispatch/workstream/landing tooling; root/local AGENTS; LFS attributes; existing claim-receipt hardening; live Ultra constraints documented in this packet; final same-host smoke and service state produced by implementation.
- Task-specific authority: root `AGENTS.md`; `custodian/AGENTS.md`; `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/AGENT_TASK_PACKET_TEMPLATE.md`; `custodian/docs/ai_context/task_packets/README.md`; `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/workstream.py`; `custodian/tools/agent/land_main.py`; `.gitattributes`; `.gitignore`.
- Work surface: bounded repository-native Ultra worker/bootstrap/service integration, packet metadata/eligibility parsing where required, focused agent-workflow validation, and external host setup through the user's existing SSH configuration. Existing local Codex workflow remains unchanged.
- Change: Add the smallest safe repository-native Ultra worker/bootstrap path, then use the user's existing local SSH identity/config and local project-root connection exports to connect to the actual seedbox and install/configure it. The Ultra worker must use one live CUSTODIAN working directory, serialize all work, reuse the existing remote-claim and landing safety model, fail closed on dirty/ambiguous state, and only auto-accept packets explicitly eligible for the low-bandwidth Ultra profile.
- Preserve: Existing local Codex/worktree workflow; local concurrent sessions; remote claim race safety; no-force-push/no-reset/no-auto-stash rules; push-first recovery; validation/artifact/summary gates; normal `origin/main` authority; secrets staying outside Git; no automatic LFS/media fetches on Ultra; manual packets remaining manual.
- Non-goals: Do not replace the normal local ephemeral-worktree workflow. Do not create parallel Ultra workers or multiple simultaneous Ultra task checkouts. Do not copy SSH private keys, OpenAI credentials, seedbox passwords, project-root secret files, or connection-export values into the repository. Do not make existing auto packets implicitly Ultra-eligible. Do not auto-run asset-heavy, broad-download, source-art ingest, large dependency bootstrap, or other high-bandwidth tasks on Ultra. Do not weaken validation or landing safety to make single-checkout operation easier.
- Acceptance: The implementation is committed and landed through the normal local workstream. The agent has actually connected from the user's local machine to the configured seedbox using the user's existing `~/.ssh` identity/config plus the already-exposed local project-root connection exports, installed/verified Codex CLI in user space, created the single-checkout CUSTODIAN worker, installed its persistent user service, and exercised a safe smoke/dry run against the live repository. The Ultra worker can discover but skip ineligible packets, can claim one explicitly low-bandwidth Ultra-eligible packet without racing another clone, can execute it from the sole working directory on an `agent/<id>` branch, and can either checkpoint safely or land it through existing main-landing semantics. LFS payloads are not fetched automatically. When idle after a successful run, the sole checkout is clean and synchronized to `main`. If Codex authentication requires an unavoidable user confirmation/device-login step, everything else is installed and the exact single remaining auth/start command is reported instead of copying local auth material.
- Validation: Focused unit/smoke coverage for eligibility, single-checkout locking, claim race safety, LFS-disabled behavior, checkpoint/landing cleanup and dirty-state fail-closed behavior; one live Ultra dry-run/smoke using non-secret existing SSH configuration; changed-file validation and `git diff --check` before closeout.
- Task overrides: `TASK OVERRIDE: this workstream may use the local coordination checkout only to discover the already-existing seedbox connection environment and SSH configuration; all repository edits still occur in the isolated local workstream returned by the dispatcher.`
- Deferred: Multi-worker concurrency on Ultra; high-bandwidth asset packets; distributed lease infrastructure beyond the existing Git remote claim refs; automatic remediation of a dirty/blocked Ultra checkout; unattended credential enrollment.

## Security And Local Bootstrap Contract

1. Start this implementation through the normal local dispatcher so it gets its own `agent/ultra-codex-packet-worker` branch/worktree and cannot trample another Codex session on the same computer.
2. Resolve the user's persistent local CUSTODIAN coordination checkout with Git/worktree metadata. The ignored project-root environment/export surface belongs to that coordination checkout and may not exist in the ephemeral task worktree.
3. Discover only the names/shape needed to use the existing local seedbox connection exports. Do not `cat`, print, log, commit, summarize, or copy secret values. Prefer the current shell environment when already exported; if a root-local ignored env/helper must be sourced, source it privately in a subshell and keep values out of stdout/stderr.
4. Use the user's existing `~/.ssh` keys and SSH config in place. Do not copy private keys into CUSTODIAN or onto Ultra, do not replace the user's keys, and do not add secrets to task summaries. Use ordinary SSH host-key verification and fail closed on an unexpected host-key change.
5. Actually SSH to the seedbox and perform the installation/configuration there. This packet is not satisfied by merely adding a script or documentation for the user to run later.
6. Do not transfer the local Codex/OpenAI auth database to Ultra. Use a supported Codex authentication method on Ultra. If an interactive/device confirmation is required, stop at that narrow gate and report the exact user action needed.

## One-Working-Directory Ultra Contract

The Ultra host is a constrained persistent worker, not a second developer workstation.

- Keep exactly one live CUSTODIAN working directory on Ultra. Do not create sibling `.custodian-worktrees/` task checkouts there.
- Run at most one packet at a time under a process/file lock. A second service invocation must observe the lock and exit or remain idle without mutating Git state.
- Idle state is a clean checkout of `main`, synchronized by fast-forward only.
- Claimed work runs in that same directory after a clean transition onto the stable `agent/<workstream-id>` branch. Preserve the existing remote claim-ref race semantics before publishing the task branch.
- Reuse/refactor existing dispatch helpers rather than inventing a weaker second claim protocol.
- Reuse `land_main.py` and existing artifact/validation rules for completion. The single-checkout path is a documented constrained-host exception to the ordinary sibling-worktree rule, not a new default.
- On successful land, verify ancestry from freshly fetched `origin/main`, return the sole checkout to `main`, fast-forward it, and remove only task-local branch state proven safe to delete.
- On conflict, dirty state, failed validation, ambiguous publication, missing auth, or unexpected network/download need, preserve recoverable state and stop. Never reset, stash, force-push, or silently discard artifacts.
- A blocked task may leave the one checkout on its recovery branch and stop the worker. Do not switch away merely to keep processing other packets if that would obscure unresolved state.

## Ultra Eligibility And Bandwidth Gate

Extend packet metadata/validation/dispatch in a backward-compatible way with a small explicit remote-worker eligibility contract. Use names consistent with the repository's existing packet grammar; the behavioral requirement is:

- Missing remote-worker metadata is **not** Ultra-eligible.
- Ultra automatic selection requires `Dispatch: auto`.
- Ultra automatic selection requires an explicit Ultra/remote-worker opt-in.
- Ultra automatic selection requires an explicit low-bandwidth classification.
- High, normal/unknown, malformed, or omitted bandwidth classification is skipped by the Ultra profile without blocking normal local dispatch.
- Manual packets remain claimable only through explicit local/manual selection and are never swept up by the Ultra daemon.
- The ordinary `dispatch.py claim-next --agent codex` behavior remains unchanged for local workers.
- Add focused temporary-repository tests for eligibility, omission/fail-closed behavior, priority/dependency/lock interaction, cross-clone claim races, and no regression to existing local dispatch.

The Ultra Git environment must additionally enforce low-transfer behavior:

- Set `GIT_LFS_SKIP_SMUDGE=1` for clone/fetch/checkout operations and configure the Ultra clone so LFS payloads are not fetched automatically.
- Treat tracked LFS pointer files as metadata only unless a future explicitly-approved workflow changes this contract.
- Do not run `git lfs pull`, broad LFS fetches, or equivalent automatic media hydration.
- If an otherwise eligible task discovers it genuinely needs missing LFS/media payloads or a substantial unplanned download, checkpoint/block with a clear reason rather than consuming the bandwidth.
- Prefer metadata-only/no-tag fetches where compatible with the existing Git safety checks.
- Keep logs bounded/rotated and do not persist model transcripts or generated scratch artifacts in Git.

## Remote Worker Runtime

Implement the smallest maintainable service surface, preferably under `custodian/tools/agent/`, with tests and documentation.

Required behavior:

1. Fetch/prune the remote conservatively and inspect packet truth from `origin/main`.
2. Select only the next eligible Ultra low-bandwidth auto packet while honoring existing priority, dependency, lock, duplicate-ID, malformed-metadata, and remote-claim rules.
3. Acquire the existing create-only remote dispatch claim before creating/publishing `agent/<id>`.
4. Transition the sole checkout cleanly to the task branch and release the temporary claim only after the task branch is durably published.
5. Invoke the installed Codex CLI non-interactively using the CLI version's supported automation flags, with the repository root as the working directory and a prompt that tells Codex to read root/local `AGENTS.md`, the claimed packet, and the normal CUSTODIAN lifecycle. Check `codex --help` rather than hard-coding stale flags.
6. Give Codex only the permissions needed to edit the repository. The wrapper, not arbitrary model instructions, owns worker locking, packet claiming, branch transitions, push/landing, and service lifecycle.
7. Capture a bounded run log plus exit status without leaking environment secrets.
8. Require the normal packet completion/archive, required root closing summary, focused validation report(s), clean tree, and push-first recovery branch before attempting landing.
9. Land with existing serialized/race-safe semantics. If main advances and requires post-sync validation under current repository rules, require that validation rather than bypassing it.
10. Return to clean synchronized `main` only after successful landing proof. Otherwise stop on the recoverable task state.
11. A no-eligible-packet poll is a normal idle result, not an error.

## Ultra Installation

During this implementation, use SSH from the user's local machine and perform the live seedbox bootstrap.

- Verify `node`, `npm`, Git, Git LFS behavior, Python, and `systemctl --user` availability before assuming paths.
- Install `@openai/codex` user-locally with npm if `codex` is absent; no sudo/root dependency.
- Put any worker launcher/config/state under user-owned paths such as `$HOME/.local/bin`, `$HOME/.config`, and `$HOME/.local/state`; do not require root.
- Clone/configure exactly one CUSTODIAN working directory on Ultra with the LFS no-smudge/no-fetch contract. Reuse an existing correct checkout if one is already present rather than cloning a duplicate.
- Authenticate Git push/fetch using the seedbox's supported existing Git/SSH setup. Do not copy the local machine's private SSH key onto Ultra. If GitHub authentication is missing, stop at that explicit user-owned credential gate rather than weakening repository visibility or embedding a token.
- Install a user-level service/timer or equivalent supported persistent mechanism that invokes the worker serially at a conservative cadence. Prefer a simple periodic poll over a hot loop.
- Keep the service disabled until all non-auth smoke checks pass. If Codex and GitHub auth are already usable, enable/start it and prove an idle/status cycle. If either requires user confirmation, leave the exact final enable/start command in the closing summary.
- The service must survive SSH disconnects and restart after ordinary process failure without spawning concurrent workers.

## Validation

At minimum, add focused automated coverage for:

- backward-compatible packet parsing;
- Ultra explicit-opt-in plus low-bandwidth eligibility;
- unknown/high bandwidth skipped;
- manual packet skipped;
- existing local auto dispatch unchanged;
- one-worker lock;
- clean-only branch transitions;
- interrupted remote-claim preservation;
- already-published/recovery handling;
- no automatic LFS hydration;
- idle no-task behavior;
- successful task closeout returning the sole checkout to clean `main`;
- blocked task preserving its recovery state.

Also run live non-destructive checks over SSH:

- `codex --version`;
- worker/service status;
- CUSTODIAN checkout count/path;
- Git branch/cleanliness;
- effective LFS no-smudge/no-fetch configuration;
- dispatcher/worker dry-run showing high/unknown-bandwidth packets skipped;
- one idle service invocation with no unintended claim.

Do not use an existing substantive production packet as the smoke-test implementation unless it is explicitly marked Ultra-eligible under the new contract. A synthetic/temp-repository test or dry-run is preferred.

## Documentation And Closeout

Update the relevant lifecycle/packet/template/validation documentation so future task authors know how to mark a packet Ultra-eligible and understand that omission is fail-closed. Document the one-working-directory constrained-host exception without changing the local default.

Write and commit `ULTRA_CODEX_PACKET_WORKER_CLAUDE_SUMMARY.md` with:

- files/tooling changed;
- live Ultra paths/service names created;
- commands/tests executed;
- whether Codex and GitHub auth are ready;
- proof that only one CUSTODIAN working directory exists on Ultra;
- proof that LFS auto-download is disabled;
- the exact current worker status;
- any manual user action still required;
- any awkward failures or deferred risks.

Never include SSH keys, seedbox host/user/password values, auth tokens, device codes, or secret environment values in that summary.
