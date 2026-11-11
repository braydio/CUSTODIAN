# Agent Review Pipeline Summary

## Delivered

Made independent post-land review a first-class, dispatcher-scheduled stage
built entirely on existing primitives (`Dispatch`, `Depends on`, `Locks`,
`workstream.py`) — no second scheduler, no pre-land gate, no continuous
worker.

- **Review metadata contract.** `dispatch.py`'s packet parser now understands
  `Kind` (`implementation`/`review`/`correction`), `Review`
  (`auto`/`manual`/`none`), `Review stage`, `Review modes` (validated against
  `code, architecture, runtime, visual, asset-pipeline, workflow`), `Paired
  review workstream`, `Review cycle`, `Max automatic review cycles`, and
  `Review target workstream/packet`. Every field has the specified safe
  default (missing `Kind` → `implementation`, missing `Review` → `none`,
  missing `Review stage` → `post-land` only when `Review` is `auto`, missing
  cycle → `0`, missing cap → `2`), so no historical packet needed editing —
  confirmed against all 144 currently-active real packets, 125 of which
  predate the `Workstream:`-header convention entirely.
- **One reusable consistency guard.** `dispatch.validate_review_pairing(packets)`
  checks that every active `Review: auto` packet has a matching active pair:
  same declared ID, `Kind: review`, `Review: none`, a dependency back on the
  implementation, and a matching `Review target workstream`. It's wired into
  `_decision` (an invalid pairing fails closed at `claim`/`status` time
  exactly like invalid packet metadata) and exposed standalone via
  `custodian/tools/agent/validate_review_pairing.py`, registered in
  `validation_manifest.json` as `review_pairing_contract` — the same function
  backs both, so tooling and the live dispatcher can never disagree.
- **Finite-loop primitive.** `review_cycle_exhausted(packet)` gives a reviewer
  a concrete check (`review_cycle >= max_review_cycles`) to decide
  `human_required` instead of scaffolding another automatic correction,
  rather than relying purely on manual arithmetic against the convention.
- **Legible queue.** `dispatch.py status` now labels review/correction
  packets (`(review of <target>)`, `(correction)`) in every section
  (READY/CLAIMED/BLOCKED/MANUAL).
- **Authoring surface.** Added `AGENT_REVIEW_PACKET_TEMPLATE.md` (the paired
  review counterpart to `AGENT_TASK_PACKET_TEMPLATE.md`, including the
  procedure, human decision gate, and an explicit "do not modify reviewed
  implementation/runtime code" instruction — the actual enforcement mechanism
  for that rule in this documentation-driven, agent-honor-system codebase,
  same as every other non-sandboxed workflow constraint here). Extended
  `AGENT_TASK_PACKET_TEMPLATE.md` with the review metadata block and safe
  defaults.
- **Docs**: added the full Paired Review And Correction lifecycle to
  `task_packets/README.md` (declaration, guard behavior, eligibility, durable
  receipt shape, correction scaffolding, finite cycle, human decision gate);
  noted in `AGENT_WORKSTREAM_LIFECYCLE.md` that review is a follow-on
  workstream, never a `finish` blocker; marked the feature implemented in
  `AGENT_AUTOMATION_BACKLOG.md`; added the focused-validation recipe to
  `VALIDATION_RECIPES.md`; indexed the new template/tool in `FILE_INDEX.md`;
  added a one-line cross-reference in `prompts/README.md`. Left
  `CURRENT_STATE.md`, `review_runtime_change.md`, and root/`custodian/AGENTS.md`
  untouched — none made a claim this work invalidated, and the existing
  routing chain (`custodian/AGENTS.md` → `AGENT_WORKSTREAM_LIFECYCLE.md` →
  `task_packets/README.md` → `AGENT_REVIEW_PACKET_TEMPLATE.md`) already
  reaches this feature without a duplicated essay.

## Validation

- `python3 custodian/tools/agent/test_dispatch.py`: **53 passed** (38
  pre-existing + 15 new, one per the packet's required proof: historical
  packet without review metadata stays valid; `Review: none` needs no pair;
  `Review: manual` needs no pair and isn't auto; `Review: auto` requires a
  declared pair; paired review must be `Kind: review`; paired review must be
  `Review: none`; paired dependency/target identity must match; review stays
  blocked until the implementation dependency completes; review becomes
  eligible once the implementation is archived complete; a passed pairing
  needs no correction packet anywhere; a correction packet uses the exact
  same generic pairing rule as any implementation; a correction's own pairing
  is validated identically (no special case); review cycle parses/reports
  correctly; `review_cycle_exhausted` reports the cap correctly; an
  end-to-end `dispatch.claim()` integration proof that an invalid pairing
  blocks the explicit claim and a fixed pairing then succeeds through the
  real claim path).
- `python3 -m unittest custodian.tools.agent.test_workstream`: **9 passed**
  (untouched by this task — `workstream.py` was not modified).
- `python3 custodian/tools/agent/validate_review_pairing.py`: **PASS (5
  Review: auto packet(s) correctly paired)** against the real fetched
  `origin/main` queue — zero false positives against the live repository.
- `python3 custodian/tools/validation/run_validation.py --test
  review_pairing_contract --json`: passed through the real harness.
- `python3 custodian/tools/validation/agent_workflow_smoke.py`: passed
  (includes its own internal `test_dispatch.py` re-run, also green).
- `git diff --check`: clean. `python3 -m py_compile` on all three changed/new
  Python files: clean.
- Closeout: `run_validation.py --changed --base origin/main --json` (see
  exact selected/passed counts in the commit this summary lands with).
- Moment Forge: not run — this is workflow/tooling/docs only, no runtime or
  presentation behavior changed.

## Awkward Parts And Deferred Work

- I removed one per-packet validation rule I initially added
  ("a review packet must declare Review: none" as a standalone parse error)
  because it made the cross-packet check in `validate_review_pairing` for
  the identical condition permanently unreachable: any review-kind packet
  with `Review` other than `none` would already have its own parse error and
  be excluded from the pairing lookup, so the specific "paired review must
  declare Review: none" message could never actually surface. The packet's
  own "Safe defaults" wording reads as a defaulting rule (what `Review`
  becomes when omitted on a review packet), not a hard prohibition on ever
  declaring anything else, so enforcing it solely through the pairing guard
  — where it's reachable and testable — is the more faithful reading.
- This workstream picked up a genuinely stalled prior claim: the worktree
  attached to `agent-review-pipeline` had zero unique commits after roughly
  four hours, and its remote branch had already been deleted once as stale
  residue by an unrelated cleanup (see `BRANCH_ARCHIVE.md`) before quietly
  reappearing at the current `main` tip via the ordinary clean-local-worktree
  reuse path. I reused that same worktree/branch for this implementation
  rather than discarding it, since it was clean and had no unique commits to
  lose.
- Per the Self-Bootstrap requirement, I did not touch
  `REVIEW_AGENT_REVIEW_PIPELINE.md` (left active/ready) and did not mark it
  complete here — its own independent review of this implementation is the
  intended next eligible workstream once this lands and archives.
- Proof #14 ("reviewer workflow does not grant authority to edit
  implementation code") has no code-level sandbox in this repository for any
  workflow constraint — it's enforced the same way every other agent-honor
  constraint here is: by an explicit, discoverable instruction in the
  authored contract (`AGENT_REVIEW_PACKET_TEMPLATE.md`'s bolded "Do not
  modify reviewed implementation or runtime code in this workstream," mirroring
  `REVIEW_AGENT_REVIEW_PIPELINE.md`'s own existing `Task overrides` line).
  I did not build or claim to build runtime enforcement for this.
- Deferred, unchanged from the packet's own scope: pre-land review gates,
  distributed reviewer leases, continuous worker mode, a dashboard UI, exact
  automatic multi-commit review-range metadata, and automatic subjective
  visual-baseline approval.
