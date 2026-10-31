# Paired-Review Checkout-Profile Emergency Recovery

## Authorization and exception

This maintenance change is authorized by CUSTODIAN control RC-087 in the
coordination conversation recorded below. RC-087 explicitly permits one
documented emergency maintenance PR outside canonical dispatcher claims, with
independent human review and no direct edits to `main`. This PR is an exception
to the normal workstream lifecycle; it is not represented as a canonical claim
or task-packet completion.

Authorizing conversation:
`https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ae5d404-c86c-83ea-aec4-6cd3d75af933`

The change is limited to preserving the legacy dispatcher `checkout` disposition
and placing checkout-profile provenance in a separate `checkout_profile` object,
then enabling one authenticated continuation of the exact held review below.

## Protected continuation identity

- Review workstream: `review-agent-paired-review-runner-profile-summary-coverage-v1`
- Original paired-review run: `20261031T154752Z-1243f08594ef`
- Original claim run: `20261031T154805Z-601d4382c346`
- Original reviewed main: `e1bff4eb3360e7f0fcdbc5bb67fa86bc2b600f4f`
- Original profile: `custodian/docs/ai_context/worktree_profiles/agent_ops_paired_review_bootstrap_v1.json`
- Original claim, run evidence, branch, worktree, and lock remain held and are not
  rewritten or released by this PR.

The continuation command is accepted only for this exact run and requires a
fresh reviewer context. Before coordinator validation or reviewer launch, the
runner authenticates the original run-file manifest and claim receipt, verifies
the original branch and pinned HEAD, checks for an active process owner, rebuilds
the dependency set at the pinned main, and verifies the physical sparse checkout
against Git blobs and sparse-checkout rules. It runs coordinator validation into
the new continuation evidence directory before launching the fresh reviewer.
No earlier reviewer verdict exists or is inferred.

After this PR is independently approved and merged, first create the read-only
plan from a clean coordinator checkout at the exact pinned main:

```bash
python3 custodian/tools/agent/paired_review_runner.py \
  review-agent-paired-review-runner-profile-summary-coverage-v1 \
  --continue-run 20261031T154752Z-1243f08594ef \
  --recover-checkout-profile-mismatch --plan
```

The emitted plan binds the original run manifest, claim receipt, pinned base,
profile dependency set, branch/worktree identity, and lock inode. Review that
plan, then provide separate explicit authorization by using its exact
`plan_sha256` in:

The plan reports all 399 reconstructed review dependencies and distinguishes
paths still tracked/materialized at the pinned tree from historical paths that
were deleted before that baseline. The current exact-run plan records one such
historical path; the deleted path remains reviewable through Git history but is
not claimed as a checked-out file.

```bash
python3 custodian/tools/agent/paired_review_runner.py \
  review-agent-paired-review-runner-profile-summary-coverage-v1 \
  --continue-run 20261031T154752Z-1243f08594ef \
  --recover-checkout-profile-mismatch --apply \
  --plan-sha256 <exact-plan-sha256> \
  --authorize-fresh-reviewer-context
```

The apply recomputes and compares the plan before any recovery write, repeats
plan checks immediately before continuation creation, and performs coordinator
validation before it can launch the first reviewer session for the original
claim. It does not accept another workstream/run pair, dispatch a new claim, or
certify a review outcome. The usual independent reviewer disposition and
coordinator closeout remain required.

## Follow-up drift

The exact held claim has a canonical `agent/<workstream>` branch and worktree,
but no longer has the temporary `dispatch-claims/<workstream>` ref. The scoped
legacy-claim snapshot currently requires that temporary ref, so it cannot snapshot
a normal successfully published claim. Add regression coverage to the quarantine
tool for a canonical claim after the temporary dispatch ref has been removed.
That follow-up is separate from this emergency recovery.
