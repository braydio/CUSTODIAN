# REVIEW: RITUALANT — SCORE DIRECTION CORRECTION V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-ritualant-score-direction-correction-v1`
- Authoring handoff: auto
- Kind: review
- Status: draft
- Dispatch: manual
- Priority: P1
- Depends on: ritualant-score-direction-correction-v1
- Locks: ash-bell-music, ritualant-underground-audio
- Review: none
- Review stage: post-land
- Review modes: code, architecture, runtime
- Paired review workstream: none
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independent falsification of music state, nonzero transitions, audio ownership and accidental post-resolution replay
- Review target workstream: ritualant-score-direction-correction-v1
- Review target packet: custodian/docs/ai_context/task_packets/archived/RITUALANT_SCORE_DIRECTION_CORRECTION_V1.md
- Reviewed main: 2f69588a5825eb3212f1b7f0ac0e4782e2384fee
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Visual review: none
- Reviewer context: fresh
- Reviewer provenance: different-agent
- Goal: Independently establish that each of the four Ritualant cues is triggered and changed at its correct authored scene beat, remains stable through real-time duck/crossfade races, and ends in the correct aftermath.
- Reviewed implementation acceptance: Independently verify all numbered Change, Preserve, and Acceptance clauses of the archived implementation packet against landed source and first-party state evidence, especially formerly green tests now intentionally invalidated by corrected aftermath contract.
- Review evidence: Landed immutable source SHA; music director, `MusicManager`, site/wrapper source and scene; actual OGG manifests/hashes; `ritualant_four_cue_music_smoke.gd` with nonzero-duration timings; implementation changed-file report and scenario reproducibility; exact chat backlink.
- Correction threshold: Old score bleeds through Underground arrival, wrong cue start, premature Stilling Release before actual ritual commit, destructive music stop/duck interruption, fake/non-overlap crossfade, lost combat on dialogue, old exploration replay after any terminal one-shot, one-shot re-trigger after save/restore, successor playlist overwritten, duck affecting SFX, failed exit recovery incorrect, stale music after teardown, false claims about audible human review.
- Review focus: Assert real elapsed nonzero fades (not exclusively `transition_seconds=0`), conversation during cue switch, active deck count/ownership and gain continuity, combat rise, pin and third-anchor, violent vs survival, post-resolution silence, return/next zone handoff, state restore, no extra assets. Independent review is findings-first, fresh context; preserve implementation and authoring URL.
- Acceptance: Zero blocking defects and material evidence gaps under actual event sequences; exact receipt tied to landed commit and 4/4 cue hashes; if incomplete publish bounded R0 findings/correction workstream rather than passing. Human listening may remain pending, clearly labeled; it is not a required implementation hold.
- Non-goals: Recompose/remix music, change encounter gameplay/Highland art, take ownership of existing shader human gate, edit the reviewed runtime or unrelated files.
- Validation: Inspect source and regression coverage; independently rerun `python3 custodian/tools/validation/run_validation.py --test ritualant_four_cue_music --json` plus relevant Ash-Bell state/completion and changed-file checks. Require separate nonzero-fade, same-time dialogue, finish, exit and restoration assertions. Conserve media, reuse existing evidence; a targeted human game-feel audition is a separate later task.
- Task overrides: TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.

## Review Receipt
- Review schema: `custodian.task_review.v1`
- Reviewed commit: `<fill at review>`
- Findings: `<fill at review>`
- Acceptance: `<fill at review>`

## Handoff
- Next workstream: none
- Next packet state: none
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acb367f-4ca0-83e8-a226-31a3ae38da20
- Summary backlink: Include this exact Authoring chat URL in every durable review/correction handoff.
- Refresh reason: none
- Next action: Close with exact review receipt on main, or author and execute bounded correction/re-review packets for each blocking finding.
- Blockers or open questions: none before implementation; human in-game listening remains separately recorded.
