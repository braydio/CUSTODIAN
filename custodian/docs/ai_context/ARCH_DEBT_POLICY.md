# Architecture and Tooling Debt Policy

- Status: active from 2026-11-13
- Owner: the orchestration session that maintains `debt/REGISTER.md`
- Scope: tooling, lifecycle, guard, dispatcher, validation and architecture problems that are not inside the reporting agent's own workstream

## Purpose

Let any agent report a shared-tooling or architecture problem without stopping its own work, and give the orchestration session one place to triage and schedule the fixes.

## Non-blocking rule

1. Keep the assigned workstream moving. Apply a documented workaround if it is safe and inside your lane. Continue every step that does not depend on the problem.
2. Record the problem as a debt item (format below) on your workstream branch. Cite its ID in your closing summary and in any checkpoint.
3. Do not fix shared tooling, lifecycle, guard or architecture code from inside an unrelated workstream. Do not open claims, fix packets or reviews for a debt item. The orchestration session decides that.
4. Stop only when the problem makes your own result unsafe or unverifiable: a source-integrity or ownership gate fails, evidence would have to be fabricated, or state would be overwritten. Report that as a blocker in the normal way, not as debt.

## What qualifies

Record it when:

- a lifecycle, dispatch, checkout, guard or validation tool misbehaves or lacks a capability, and the defect is not yours to fix;
- a manual workaround is needed that other agents will also hit;
- two authoritative documents or tools disagree about the same behavior;
- a status, ownership or capacity fact is hard or impossible to determine from the supported commands.

Do not record:

- bugs in your own feature code (fix them in your workstream);
- ordinary dependency waits or claim locks (report them in your summary);
- information-only notes with no defect or missing capability.

## Item format

- Path: `custodian/docs/ai_context/debt/DEBT-NNNN-<slug>.md`
- `NNNN` is the next number after the highest ID listed in `debt/REGISTER.md`. Check the register first; if an open item already covers the problem, do not create a duplicate. Cite its ID instead.
- Do not edit another item. The orchestration session folds new observations in.

Front matter fields:

- `id`: `DEBT-NNNN`
- `title`: one line
- `status`: `open` | `triaged` | `assigned` | `landed` | `wontfix` | `duplicate`. New items are always `open`.
- `severity`: `P0` stops all dispatch or landing; `P1` stops one workflow for everyone; `P2` is recurring friction
- `area`: lifecycle | dispatch | checkout | guard | validation | docs | architecture
- `first_seen`: main SHA, reporting workstream, run ID when one exists
- `reporter`: workstream ID
- `owner`: left blank by the reporter; the orchestration session fills it

Body sections, in order: **Symptom** (exact error text, kept short), **Repro** (minimal steps), **Workaround used**, **Proposed fix** (optional), **Evidence** (repository paths and commands, never secrets, tokens or private file contents).

## Orchestration session

- Owns `debt/REGISTER.md`: triage, duplicate folding, severity, owner, status.
- Groups related items and sequences fixes by blast radius. Records a decision in the register, not in chat.
- Creates fix packets only through the normal packet process, and only for items it has triaged.
- Reviews the open register at the start of each planning session.

## Landing

Debt items are documentation-only. They land with the reporting workstream's normal finish. If that workstream is checkpointed or blocked, the item rides in the checkpoint commit. The orchestration session may land register changes directly to `main` as a fast-forward of `origin/main`.

## Relation to other protocols

- `AGENT_BLOCKER_INBOX_PROTOCOL_V1.md` is an approved but unimplemented design for machine-published incidents on a separate ops branch. Debt items are in-repo, reviewed and not a replacement for it. If it lands, its notices may cite debt IDs.
- `AGENT_WORKSTREAM_LIFECYCLE.md` remains the authority for claims, checkouts, finish and checkpoint. A debt item never changes lifecycle state.
