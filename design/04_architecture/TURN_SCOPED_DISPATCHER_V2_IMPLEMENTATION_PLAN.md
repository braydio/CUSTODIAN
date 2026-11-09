# Turn-Scoped Dispatcher V2 Implementation Plan

**Status:** D2-004 Stage 3A integration candidate in progress; opt-in only, no production cutover.
**Program:** CUSTODIAN Dispatcher V2 replacement
**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af12561-89a4-83ea-bc7f-c896ec89bed0
**Reviewed main:** `841931733cd0103e5dbeb5587063d3b880e50db7` (fetched from `origin/main` on 2026-11-09).
**Prototype:** PR #123, branch `agent/turn-scoped-dispatcher-v2`; candidate only, not current execution authority.

## Purpose and boundary

Replace the current persistent-worktree dispatcher model with a turn-scoped execution lifecycle that can acquire either a new eligible task or useful historical work, preserve recoverable work across turns, and retire temporary checkouts safely. This plan describes the implementation and cutover sequence. It does not itself replace `dispatch.py`, authorize checkout deletion, change task ownership, or alter the historical archive.

The current dispatcher and `workstream.py` lifecycle remain authoritative until all implementation, independent review, validation, and cutover gates in this plan pass. The local coordination checkout used to author this draft has unrelated dirty files; they are outside this scope and must remain intact.

## Goals

- Provide two acquisition modes over one canonical workstream identity and one `agent/<workstream>` Git branch.
- Make each execution turn use a disposable checkout and leave a durable, verifiable handoff that a later turn can resume.
- Permit useful historical work to resume without inheriting obsolete session ownership, lock, or scheduler restrictions. Current human-owned design decisions remain holds.
- Preserve source, ignored/untracked data, Git LFS objects, evidence, and recoverability before a checkout is retired.
- Prevent a concurrent writer from silently overwriting another writer's published progress through non-forcing, expected-parent Git updates and revalidation.
- Retire the old dispatcher authority only after a separately reviewed migration and explicit acceptance of all consumers.

## Non-goals and deferred work

- Root checkout sync timers or other background synchronization services.
- Editing or reorganizing the private `braydio/CUSTODIAN-worktrees` archive.
- Bulk deleting, pruning, or rewriting existing worktrees, refs, claims, locks, packets, or branches during the initial implementation.
- Treating archive membership as proof of task eligibility, task completion, review acceptance, or current ownership.
- Replacing human decisions about design, art, gameplay, or other owner-held acceptance.
- Creating a second queue or scheduler that duplicates task-packet eligibility rules.

## Operating model

### Acquisition modes

**Normal mode** selects a task with a valid durable identity and an available task definition, authenticates those task-definition bytes against fetched `origin/main`, and creates or reuses the remote `agent/<workstream>` branch only under a non-forcing, race-safe operation. It creates a fresh checkout in a managed temporary pool and hydrates required LFS content before work begins. V2 readiness is evaluated independently: task identity and definition are valid, no unresolved user-owned design decision holds selection, and branch/checkout creation is safe. Old packet statuses, dispatcher eligibility, locks, execution claims, and dependency chains cannot block V2 task selection. Implementable technical prerequisites are absorbed into the implementation scope. Validation, independent review, human approval, and data-integrity requirements remain acceptance controls; they are not scheduling gates.

**Historical mode** selects a task with a valid durable identity and available task definition, then treats prior implementation from remote branches, handoffs, evidence references, and the historical archive as optional reference material. Reuse verified useful changes where available. Historical records are not claim authority and cannot veto fresh implementation. Historical mode must not require the original worker/session to return, preserve obsolete persistent locks, or wait on a retired ownership chain. It must respect a current human-owned design hold and all still-applicable safety, review, and acceptance requirements. If historical commits or checkout data are missing, unavailable, or cannot be authenticated, record what could not be reused and continue fresh from current `origin/main`.

### Turn lifecycle

`Acquire → Execute → Checkpoint → Publish and verify → Preserve required local-only data → Retire temporary checkout → Resume later from durable state`

Each turn ends at an explicit checkpoint boundary. The handoff records `Original goal:`, `Implemented:`, `Remaining:`, `Validation:`, `Sources/evidence:`, and `Resume:`. V2 adds a versioned block with task identity, authenticated task-definition path and main SHA, remote branch, and checkpoint base; the publish receipt records the exact resulting commit SHA. A checkpoint is not task completion, review PASS, human approval, or permission to land a feature branch on `main`.

There are no long-lived scheduler/session locks or administrative dependency chain in the target model. Git's non-forcing compare-and-swap behavior and exact-parent revalidation protect publication integrity; they do not claim to prevent two workers from beginning simultaneously. A loser of a branch race must preserve its checkout, fetch the winning branch, reconcile the divergent work, and publish only through a verified fast-forward. Never force-push, silently reset, or discard a concurrent writer's progress.

## Durable state and preservation contract

The remote `agent/<workstream>` branch is the canonical durable source for committed implementation progress. Each completed checkpoint must:

1. Revalidate the workstream packet and branch identity against current advertised remote state.
2. Inventory the checkout before staging: tracked modifications, untracked files, ignored files, symlinks, submodules, nested repositories, generated-but-required outputs, external evidence, and LFS pointers/objects.
3. Classify content as publishable source/handoff, reproducible cache, sensitive or private data, or unresolved/unique data. Never stage secrets or private local caches into the project branch.
4. Preserve all task-required Git content and the mandatory handoff in a scoped commit. Include exact source/evidence hashes and locations where appropriate.
5. Verify the commit's LFS object availability by OID and expected size in the remote LFS store, and verify any required archive copy independently. A Git pointer without retrievable object bytes is not a preserved source asset.
6. Push without force while asserting the expected remote parent; fetch and verify that the exact pushed commit is advertised by the expected remote branch.
7. Recheck checkout contents after commit/push. Any remaining unique, ignored, sensitive, unarchived, or otherwise unclassified bytes block retirement.

For content that must remain outside Git, use a verified, content-addressed archive or approved proof store. Before checkout removal, verify that the archive manifest covers every required path and byte, including file modes, symlink targets, relevant metadata, LFS payloads, and non-Git evidence, and that the data can be safely restored into an isolated temporary location. Do not use archive presence, a remote branch, a handoff claim, or a successful push as a substitute for byte-level preservation evidence. If preservation cannot be proven, retain the checkout and report `retained: <path> | <failed predicate> | <next action>`.

The historical archive at `braydio/CUSTODIAN-worktrees` is a candidate source for historical restoration. Before implementation relies on it, establish an auditable inventory and exact manifest/hash contract for archived worktrees, ignored/untracked data, Git/LFS content, evidence, and restoration procedures. Do not assume its current inventory is complete from repository name or README. This plan authorizes no archive writes or deletion.

## Checkout policy

- Create turns in a dedicated temporary checkout pool that is distinct from the legacy `.custodian-worktrees` location. Pool location and lifecycle must be configurable and validated against the repository root.
- A checkout may be retired only after the checkpoint is remotely verified and every non-Git or ignored byte that must survive is independently preserved and verified.
- Retirement must use Git's non-forcing worktree removal for the exact registered checkout after rechecking path, worktree registration, branch/HEAD, status, and inventory. No recursive deletion, blanket cleanup, implicit prune, or deletion by age.
- A clean legacy checkout may be migrated and retired by the new lifecycle after its content and historical owner state have been reconciled; do not require an obsolete owner to authorize routine retirement. A dirty or uniquely valuable legacy checkout is first archived and verified, then rehydrated and compared before retirement. Any unresolved mismatch retains it.
- Stale local coordination metadata is not proof that a checkout is safe to delete. Do not remove claims, locks, refs, or independent reviewer evidence as a side effect of retiring a checkout.
- Completion of one turn must not imply completion of the workstream. The next turn rehydrates from the remote branch plus verified handoff and resumes the remaining acceptance scope.

## Relationship to current authority

The replacement must reuse useful task definitions, review processes, validation recipes, Git LFS configuration, and repository guidance without carrying forward old scheduling gates. During migration:

- Task identity, task-definition provenance, branch naming, validation evidence, and acceptance outcomes are mapped explicitly. The replacement must not turn review findings, `human_required`, archived state, or a missing supervisor record into a PASS or release signal. Old dispatcher status, locks, claims, dependency chains, or eligibility results do not control V2 selection.
- Existing task packets and branches retain their identities. No bulk packet conversion or historical claim rewrite is needed to launch the new tool.
- Root `AGENTS.md`, `custodian/AGENTS.md`, lifecycle docs, dispatcher docs, review handoffs, packet index consumers, and launch/service entrypoints must be inventoried as cutover consumers. Update them atomically with the approved cutover, not in an early prototype slice.
- Current user instructions and unresolved user-owned design decisions continue to govern owner-held decisions. Other implementation prerequisites are scoped into the work.

## PR #123 prototype assessment

PR #123 is a useful starting point for isolated CLI/test structure and the two-mode concept, but it is not production-ready and does not supersede any current authority. Retain or adapt only code that passes the implementation contract and tests below.

Known gaps to close include: packet bytes are read from the local checkout rather than authenticated against advertised main; existing branch presence is not an exclusive writer lease; historical mode still requires an original-owner retirement route for a clean checkout; ignored data blocks checkpoint instead of using a verified preservation archive; and its current tests do not establish real LFS hydration, concurrent writers, failure recovery, hostile filesystem paths, archive completeness, or complete migration compatibility. Do not copy these assumptions into the production contract.

## Implementation stages

### Stage 1 — Dispatcher core and durable checkpointing

- Implement the two acquisition modes, exact task identity resolution, packet authenticity checks, fresh checkout creation, LFS hydration, handoff schema, checkpoint creation, non-forcing publish/verify, and conservative retirement gates.
- Provide a dry-run/inspect path that reports selected mode, canonical packet and branch identities, expected remote state, checkout destination, LFS needs, preservation inventory, and blocked predicates without mutating refs, worktrees, or files.
- Define versioned, machine-readable inspect/checkpoint/retirement receipts. Make interrupted operations restartable through reinspection rather than hidden in-memory state.
- Add isolated local Git fixtures for normal/historical selection, malformed/ambiguous packets, stale main, absent/existing branch, remote races, interrupted clone/checkout, interrupted commit/push, non-fast-forward, dirty/ignored/untracked paths, symlinks, submodules, secrets, and idempotent resume.
- Keep implementation opt-in; do not change current dispatcher entrypoints or cleanup behavior in this stage.

### Stage 2 — Historical archive integration and automatic checkout retirement

- Define an archive manifest and restore verifier with exact repository, workstream, checkout, commit, path inventory, content hashes, permissions, symlink targets, LFS OIDs/sizes, evidence references, and archive object identity.
- Verify representative legacy worktrees from the designated archive, including difficult cases with ignored/untracked source and LFS objects. Establish measured coverage before relying on archive-based retirement.
- Implement historical rehydration from remote Git state plus archive-only bytes where required. Compare restored content against the manifest before the new checkout is allowed to continue or the archived/old checkout is retired.
- Implement automatic retirement only for the exact new temporary checkout after the Stage 1 preservation contract passes. Legacy checkout retirement remains individually verified and gated; there is no blanket cleanup or age-based sweep.
- Prove restart/retry behavior after each boundary: archive write, archive verification, checkout creation, LFS hydration, remote push, and worktree removal.

Stage 2 implementation adds `turn_archive_v1.py`, which inventories the exact filesystem tree and declared archive commit into a private SHA-256 manifest and restores into a new isolated destination only after path, type, mode, symlink, LFS pointer, and content checks pass. It records external evidence references separately and fails verification when their bytes are unavailable or changed. Dispatcher acquisition provenance is bound to the exact checkout and carried into each committed handoff. An absent historical branch can fall back to authenticated current main with a recorded reason; failed LFS hydration never falls back and always retains the checkout. Ignored content is classified per file, with only validated Python bytecode paired with tracked source considered reproducible; all other ignored paths block retirement with exact local identity receipts.

The actual host archive still requires a stable, complete inventory and one verified representative historical restore before it can be relied on for recovery or retirement. Archive source files, path listings, and manifests remain private and are not task publication inputs.

### Stage 3 — Validation, compatibility, and cutover

- Produce an intentional behavior-difference matrix for representative tasks, covering V2 identity/readiness/selection and old dispatcher status, dependency, lock, and claim outcomes. Verify every difference follows the approved V2 model; do not “correct” V2 to restore old eligibility parity.
- Inventory and migrate all repository instructions, workflow entrypoints, review/checkpoint integrations, and consumers. Update them as one bounded reviewed cutover so no tool or instruction points at a retired authority.
- Perform an opt-in pilot on a disposable task with no active overlapping claim, then a historical restoration pilot using a verified archived example. Preserve full receipts and prove that a fresh turn can resume from branch, handoff, and archive manifest without prior process/session memory.
- Run focused and repository-level validation from a clean, current checkout; include LFS-enabled host validation, multi-writer races, failure injection, filesystem edge cases, branch integrity checks, and verification that unrelated worktrees/refs are unchanged.
- Obtain the required fresh-context independent technical review of the exact cutover diff. Resolve findings in bounded corrections and re-review. Do not self-approve.
- Only after all gates pass, switch documented/default entrypoints to V2 and mark the old dispatcher superseded. Retain a documented rollback path until post-cutover validation confirms operational continuity. Remove old code only when every supported consumer has migrated and rollback is no longer required.

## Acceptance gates

1. **Identity and authority:** Both modes identify exactly one canonical task/workstream and branch. Normal mode uses current dispatcher-confirmed eligibility and authenticated main packet bytes. Historical mode resolves durable task state without requiring an obsolete owner/session or administrative lock chain. Human-owned design holds remain effective.
2. **Disposable turns:** Each turn uses a fresh or explicitly rehydrated temporary checkout; every checkpoint contains the required handoff fields and exact branch/commit identity; later resume works in a new process with no session memory.
3. **Publication integrity:** First-branch creation and checkpoint pushes are non-forcing and race-safe. Concurrent updates cannot overwrite or silently lose published commits. A race preserves all local work and produces an actionable reconciliation receipt.
4. **Preservation:** Tests prove tracked, untracked, ignored, sensitive, symlink, submodule, external evidence, and Git LFS content are correctly classified. Required bytes are recoverable and hash-verified before retirement; unresolved or unique data keeps the checkout.
5. **Retirement safety:** Only the exact verified temporary checkout can be automatically retired. No broad prune, age sweep, `rm -rf`, unrelated branch/ref deletion, or implicit claim/review cleanup occurs. Legacy checkout retirement requires exact inventory and restore verification.
6. **Failure recovery:** Every mutation boundary has injected-failure coverage and is safe to retry or explicitly retains the checkout. Remote mismatch, missing LFS bytes, archive mismatch, stale packet/main state, unexpected path, and ambiguous ownership fail closed with a precise reason.
7. **Authority migration:** V2 task identity, definition provenance, review acceptance, validation, provenance, and human approval remain truthful. The behavior-difference matrix documents intentional old/new selection differences; old statuses, locks, claims, and dependency chains cannot block V2 selection. All entrypoints and guidance name the same live authority after cutover.
8. **Operations and cutover:** Focused tests, repository validation, LFS host smoke, historical restore pilot, fresh-context independent review, and post-cutover smoke pass. The old path is retired only after a verified rollback window and consumer migration.

## Evidence and reporting

Each implementation stage records the exact reviewed main SHA, workstream and branch SHAs, CLI receipts, packet/handoff identities, archive manifest and verification results (when used), LFS OIDs and availability, validation commands/results, independent review outcome, and any retained checkout with its predicate and next action. Reports distinguish `inspected`, `implemented`, `published`, `verified`, `reviewed`, and `approved`; none implies another.

The first implementation instruction should select a bounded Stage 1 slice and its paired review contract. Stage 2 and Stage 3 proceed only after the preceding implementation and review evidence establish their technical prerequisites; these are absorbed into the work and do not reintroduce task-scheduling dependencies. The current dispatcher remains in force for its existing users until the Stage 3 cutover gate is explicitly met, while V2 selection remains independent of its gates.
