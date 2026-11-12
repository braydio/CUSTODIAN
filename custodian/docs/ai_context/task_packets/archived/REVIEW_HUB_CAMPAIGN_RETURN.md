# REVIEW: HUB CAMPAIGN RETURN — H6

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-hub-campaign-return`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `hub-campaign-return`
- Locks: `hub-runtime, world-lifecycle, campaign-outcome`
- Review: `none`
- Review target workstream: `hub-campaign-return`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/HUB_CAMPAIGN_RETURN.md`
- Reviewed main: `c2d6452ac10d`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Review modes: `code, architecture, runtime`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the landed implementation against its archived packet and live runtime behavior.
- Reviewed implementation acceptance: Reuse every acceptance claim from the archived implementation packet.
- Review evidence: Archived packet/summary, live runtime, focused smoke(s), affected regressions, changed-file evidence.
- Correction threshold: Confirmed acceptance defects or material proof gaps create correction work; optional improvements stay next-slice/deferred.
- Focused validation: Run H6 return smoke, campaign_outcome_exactly_once, WorldSimulation, H5/H2 and any landed recovery/death regression; changed-file closeout last.
- Review focus: Outcome identity and exactly-once Hub mutation; mutation-before-teardown; idempotent retry; recovery/death non-duplication; exact Port return; cleanup only after successful restore.
- Acceptance: Produce a findings-first independent review of live main; record passed or stable cycle findings. Blocking defects/proof gaps create `hub-campaign-return-review-corrections-1` plus paired review. Do not patch reviewed runtime here.
- Non-goals: Do not add new feature behavior or redesign adjacent systems.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Refresh Note

Refresh concrete paths/focus with the implementation packet after predecessor reviews if live seams differ.

## Handoff

- Next action: Follow the roadmap after a clean/non-blocking review.
- Blockers or open questions: implementation dependency only.


## Cross-Program Recovery Check

R2 `custodian-post-recovery-reintegration` is intentionally separate from H6.
This review must verify H6 leaves one exact-outcome return accepted/completed
seam that R2 can consume, while H6 itself does not implement Post recovery,
reset the R1 death latch, or classify every FAILURE as death.

If the review changes the expected R2 integration seam, its closing summary must
surface the recovery planning chat exactly:

https://chatgpt.com/c/6abca2bb-1b3c-83ea-a3ae-e3d368c88461?src=history_search
