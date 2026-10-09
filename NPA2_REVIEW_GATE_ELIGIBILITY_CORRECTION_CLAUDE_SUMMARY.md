# NPA-2 Review Gate Eligibility Correction

Corrected stale packet eligibility that let Savage pounce extraction claim before the required NPA-1 paired review and planning refresh.

## Changes

- Marked `enemy-savage-pounce-ability-extraction` `blocked/manual` and added both NPA-1 implementation and paired-review dependencies.
- Updated measured state: NPA-1 implementation is landed; its paired review is pending. The packet now requires a ChatGPT/user planning refresh after that review passes before returning to `ready/auto`.
- Marked the paired Savage review packet `blocked/manual` as well, so it cannot be advertised as executable while its implementation packet remains planning-gated.
- Regenerated the managed task packet index. No Savage runtime or pounce implementation files changed.

## Validation

- `task_packet_index.py --write`: updated the managed index from packet state.
- `validate_review_pairing.py`: passed; 49 `Review: auto` packets are correctly paired. The intentionally blocked/manual Savage implementation/review pair is excluded from automatic review eligibility.
- Changed-file validation and `git diff --check` are recorded at closeout.

The empty Savage claim branch is retained only until this metadata change lands. Its checkpoint `9038f8eee` contains no implementation commits and will be retired at the exact approved SHA before claiming the NPA-1 review, freeing `enemy-runtime`.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: Dispatcher eligibility treated the Savage packet as ready/auto because only the implementation dependency was declared, even though its own handoff and architecture roadmap require a passed paired review and planning refresh.
- Root cause / contributing factors: Packet frontmatter diverged from its handoff and the active architecture tracker; the paired review packet also remained ready/auto.
- Prevention / pipeline improvement: Keep implementation and paired-review packets blocked/manual together whenever a planning refresh gate is unresolved; declare the predecessor review as a dependency explicitly.
- Tooling / docs drift discovered: The dispatcher correctly followed packet metadata but cannot infer prose-only planning gates; the packet metadata was the stale authority.
- Follow-up: fixed-in-scope
- What worked: The packet pairing validator accepts the explicitly blocked/manual implementation/review pair.

## Next Handoff
- Next workstream: review-enemy-marine-dash-ability-extraction-recovery-1
- Next packet state: ready
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac8f303-1b34-83ea-a74b-3e3973c9667d
- Refresh reason: NPA-1's independent paired review must pass before NPA-2 can be remeasured and refreshed.
- Next action: Retire the empty Savage branch at its verified SHA, claim the NPA-1 paired review, and return its durable result to the authoring conversation.
- Blockers or open questions: NPA-1 paired review is pending.
