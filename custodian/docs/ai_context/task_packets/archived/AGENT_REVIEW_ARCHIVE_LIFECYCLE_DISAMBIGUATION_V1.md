# Review Receipt Archive Lifecycle Disambiguation

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-review-archive-lifecycle-disambiguation-v1`
- Category: `agent-ops`
- Status: `complete`
- Dispatch: `auto`
- Authoring handoff: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `none`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, workflow`
- Paired review workstream: `review-agent-review-archive-lifecycle-disambiguation-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `A false historical review target can misattribute independent-review evidence and block or misdirect another workstream; independent post-land verification materially reduces this lifecycle-integrity risk.`
- Reviewed main: `8262ac57622059256f9f5d136ef0eff28dd59a1d`
- Implementation commit: `781ecf984bec706849a37ad69e9bc7123afe62b1`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df`
- Visual review: `none`
- Goal: Resolve an archived review packet to its authentic implementation-introduction commit when later restoration of the same archive blob creates multiple historical Add events.
- Completion boundary: Implement and validate the generic archived-target resolver correction, land the source and regression tests on origin/main through the authorized GitHub workflow, preserve the exact implementation commit and V2 checkpoint evidence, and complete the implementation packet's truthful archival. The paired independent review is a required separate post-land acceptance stage, governed by `review-agent-review-archive-lifecycle-disambiguation-v1`; implementation completion does not imply independent-review acceptance.
- Current measured state: `resolve_target_implementation_commit` rejects histories with two archive Add events as ambiguous. In the supplied history, the authentic introduction has a matching active packet in its parent and is followed by retirement of that active path; the later byte-identical archive restoration has no active-packet predecessor.
- Evidence: `custodian/tools/agent/review_receipt_delta.py`; its tests and callers; current Git history at `f3b94d0768bc110755f2b9be1d1e60d22fe1577c`, `30f70182b3dcd47cdb15ee776a4878a78bef295b`, `a74ab183be0eb09c4b2e3a1e23d159812bc2eb6e`, and `38c188421b18e0f5ddcd47ad0ff3dd5399eceac6`.
- Task-specific authority: `custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`; `custodian/docs/ai_context/task_packets/README.md`; the current resolver and its tests.
- Work surface: `custodian/tools/agent/review_receipt_delta.py`; add focused `custodian/tools/agent/test_review_receipt_delta.py`. Preserve adjacent paired-review runner/host-validation files and unrelated queued work.
- Publication inputs: `none`
- Change: Keep the single-candidate path unchanged. When multiple archive Add events exist, resolve only if exactly one candidate is proven by immutable Git ancestry to introduce a complete archived packet whose parent contains the matching active packet (same workstream, kind and reviewed-main identity), with no archive already present; and a later matching active-path retirement exists in that candidate's ancestry. Require the packet identity and relevant refs/pins to remain consistent. Otherwise fail closed as ambiguous. Do not select by earliest date, commit subject, or blob equality alone.
- Preserve: Existing receipt identity checks, one-candidate behavior, ambiguity for unproven histories, filesystem/branch state, unrelated workstreams and existing source review provenance.
- Non-goals: No Ash-Bell-specific allowlist, direct-tail receipt change, Dropbox mutation, review verdict/claim manipulation, or broad resolver redesign.
- Acceptance: (1) Exact supplied history resolves to `f3b94d0768bc110755f2b9be1d1e60d22fe1577c`; (2) restore `38c188421b18e0f5ddcd47ad0ff3dd5399eceac6` is never selected; (3) a single valid candidate remains supported; (4) direct add/delete/re-add without matching active lifecycle remains ambiguous; (5) two valid lifecycle introductions, mismatched workstream/kind/reviewed-main, missing or ambiguous retirement, and inconsistent ancestry all fail closed; (6) resolver does not mutate repository state.
- Validation: Run focused unit tests in the dedicated resolver test module created by this workstream, plus the existing paired-review runner unit tests; py_compile the edited Python modules; run `python3 custodian/tools/validation/run_validation.py --changed --base origin/main --json` and `git diff --check`. Record exact outcomes and any unavailable checks. The focused test module is a workstream output and will be validated after creation.
- Task overrides: `none`
- Deferred: Resume `review-ash-bell-surface-lift-v2-asset-intake` only after this implementation lands and its fresh paired review is accepted; do not create replacement Lift packets.


## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: The generic resolver and four focused regressions landed in implementation commit `781ecf984bec706849a37ad69e9bc7123afe62b1`, reachable from main through PR #135 merge `6ef13efbbd1486f18d0f799817d6f521ef564c46`. The exact Lift history resolves to `f3b94d0768bc110755f2b9be1d1e60d22fe1577c`, not restoration `38c188421b18e0f5ddcd47ad0ff3dd5399eceac6`; the acceptance cases were covered by the four focused regressions and the 326-test paired-review suite; additional temporary real-Git probes rejected mismatched workstream, kind and Reviewed main identities, missing retirement, and cross-branch retirement evidence. V2 handoff is published at task branch head `d4e694a51e3d62050af8fb9d9f2ac388e42648d6`, with verified retirement receipt `13808850d4f24ea597c35320b99e4f0a`. Independent review is pending and is not represented as accepted.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The first automatic packet-authoring handoff attempt failed because its preflight requires referenced validation scripts to already exist on main, while the focused test module was a planned implementation output. The V2 implementation also required a normal GitHub PR for landing; `workstream.py finish` only checkpoints and retires V2 turns.
- Root cause / contributing factors: The handoff validates all explicit validation-script references against main before promotion; the repository uses separate V2 checkpoint and GitHub landing steps.
- Prevention / pipeline improvement: Keep implementation-created validation scripts generic in draft packet Validation until the output exists, or publish every required script as a verified input. Select the PR landing route for V2 implementations and reserve `workstream.py finish` for its documented checkpoint/retirement behavior.
- Tooling / docs drift discovered: Root `AGENTS.md` lines 279–282 state that `workstream.py finish` uses `land_main.py` internally, conflicting with its V2-specific lines 256–262 and 471, plus `custodian/AGENTS.md` and the V2 lifecycle guide, which state V2 finish checkpoints but does not land. A bounded documentation follow-up remains pending.
- Follow-up: `manual-follow-up`
- What worked: Exact Git ancestry, focused real-history regressions, and the authorized PR preserved the distinction between implementation, handoff, and administrative archive commits.

## Handoff

- Next workstream: `review-agent-review-archive-lifecycle-disambiguation-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6af34a5d-ca7c-83ea-b267-382f1be560df`
- Summary backlink: `include the exact Authoring chat URL in every durable summary and final Next Handoff`
- Refresh reason: `none`
- Next action: `After this archive is merged and review eligibility is confirmed, run the existing paired review in a fresh reviewer context; only after accepted review, retry the preserved Ash-Bell Lift intake review.`
- Blockers or open questions: `The paired independent review has not yet been launched or accepted.`
