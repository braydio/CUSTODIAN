---
id: DEBT-0006
title: Owner-approved small merges have no lightweight landing path; direct landing is blocked and a full packet is required
status: open
severity: P2
area: lifecycle
first_seen: origin/main 1dc8db2be; workstream agent-ops-readonly-observer-pilot-20261114; no run ID recorded
reporter: agent-ops-readonly-observer-pilot-20261114
owner:
---

## Symptom

```
land_main: BLOCKED: direct landing is disabled; complete implementation work with workstream.py finish <workstream-id> --validation-report <report>
```

A clean task branch with focused validation already passing, and the repository owner's explicit approval, cannot be landed on `origin/main` without first publishing a task packet and starting a workstream for it. `workstream.py start` refuses with `missing authenticated task definition ... on origin/main`.

## Repro

1. Create a worktree from `origin/main` and commit a small change on a new branch, for example a two-commit tooling fix.
2. Run the focused tests for the touched modules; they pass.
3. From that worktree, run `python3 custodian/tools/agent/land_main.py`. It refuses with the message above.
4. Run `python3 custodian/tools/agent/workstream.py start <id>` for a workstream that has no packet. It refuses because no authenticated task definition exists on `origin/main`.

## Workaround used

Pushed the branch and asked the owner to decide between publishing a packet and opening a pull request for an owner merge. No workaround was applied to `main`.

## Proposed fix

Give owner-approved, non-feature changes a lightweight path. For example, `land_main.py` could accept an explicit owner approval argument, recorded in the landing output and the commit trailer. It would keep the existing guards: clean branch, fast-forward or rebase onto fetched `origin/main` with no force-push, and a focused validation report supplied by the caller. Packet authoring would remain for feature and review work. The owner should be able to give this green light directly in chat, without the full packet ceremony.

## Evidence

- `custodian/tools/agent/land_main.py`: the direct-landing refusal message.
- `custodian/tools/agent/turn_dispatcher_v2.py` (`inspect`): `missing authenticated task definition` for a workstream with no published packet.
- Branch `agent-ops/readonly-observer-pilot-20261114`, commits `d1af1be46` and `aedd6fc22`, pushed to origin.
