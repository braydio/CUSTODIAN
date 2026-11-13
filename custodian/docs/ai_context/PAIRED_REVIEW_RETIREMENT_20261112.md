# Paired Review Retirement — 2026-11-12

Owner decision (Brayden, 2026-11-12): paired post-land review is retired.
It had blocked landing work for weeks. The acceptance gate for a packet is
now its focused validation plus the owner's review of the landed change.
There is no Protected tier that keeps paired review, and no new paired
review packets are to be authored.

## What changed in this branch

Code — pairing is advisory, never a blocker:

- `custodian/tools/agent/task_packet_contract.py`: `Review: auto` no longer
  requires a paired review workstream (that was a parse error);
  `validate_review_pairing` is an advisory diagnostic only.
- `custodian/tools/agent/dispatch.py`: `_decision` ignores pairing errors
  for implementation/correction packets; `audit` no longer counts a
  pairing mismatch as `invalid_recovery`, no longer excludes it from
  `managed`, and reports it as `pairing_advisory`. One narrow exception:
  a `Kind: review` packet itself is still blocked by a pairing error,
  because that error is the bounded-override safety bound on what a
  review may mutate — retired reviews must not claim with a bad override.
- `custodian/tools/agent/validate_review_pairing.py`: pairing mismatches
  print as ADVISORY and exit 0; only missing validation-script references
  still fail. CI keeps running it.
- `custodian/tools/agent/validate_task_packet_authoring.py`: pairing is no
  longer a preflight finding; the promotion handoff no longer mentions a
  paired review.
- `custodian/tools/agent/packet_authoring_handoff.py` and its test:
  the handoff promoted only implementation/review *pairs* and raised an
  error for any opted-in packet without a paired review — after the flip
  it would have broken on every opted-in `Review: none` packet, including
  the hourly `--scan-opted` retry. It now promotes single
  implementation/correction packets; a review packet can never be opted in.
  The `.github/workflows/packet-authoring-handoff.yml` step was renamed
  accordingly.
- `custodian/tools/agent/owner_review_exception.py`: the exception lane is
  retired for new work. It is kept only so the one historical record
  (`review-operator-chassis-authority-seal-v1`) still verifies.
- The paired-review runner and recovery tools
  (`paired_review_runner.py`, `paired_review_host_validation.py`, the
  `paired_review_*_recovery.py` files, `review_claim_parking.py`) were
  not deleted: they only operate on review packets when explicitly
  invoked, and with no active review packets they are dormant. Deleting
  them would have been a larger, riskier change with no landing benefit.
- `AGENTS.md` and `custodian/AGENTS.md`: a retirement notice at the top
  of each, superseding the paired-review instructions still present in
  those files, and the risk-policy paragraph in `custodian/AGENTS.md`
  no longer has a Protected tier. Historical narrative in
  `CURRENT_STATE.md` and the packet README's program sections was left
  alone: those reviews did happen, and rewriting history would falsify it.
  Only the prescriptive handoff/preflight sections of the packet README
  were updated.

Templates:

- `AGENT_TASK_PACKET_TEMPLATE.md`: Review Policy is now "paired review
  retired"; new packets use `Review: none`, `Review modes: none`,
  `Paired review workstream: none`.
- `AGENT_CORRECTION_PACKET_TEMPLATE.md`: corrections are `Review: none`,
  depend on the parent implementation (not its review), and have no
  re-review cycle.
- `AGENT_REVIEW_PACKET_TEMPLATE.md`: marked RETIRED, kept as historical
  record only.

Packets — mechanical, script-generated (`retire_paired.py`, not committed):

- 161 active implementation/correction packets flipped `Review: auto` →
  `Review: none`, with `Paired review workstream: none`,
  `Review modes: none`, and `Review rationale` set to the retirement note.
- 127 packets had `Depends on: review-<X>` rewritten to `<X>`, the
  underlying implementation/correction workstream. A dependency on a review
  was a gate on that review's acceptance; the gate is now the work landing.
  Two rewrites needed the review packet's actual target, not a blind
  prefix strip: the five `CONTRACT_WORLD_*_PLACEMENT_EXTRACTION` packets
  now depend on `contract-world-placement-foundation` (the review was
  `review-contract-world-placement-foundation-r1`), and
  `procgen-runtime-optimization-v2-series-authoring` now depends on
  `procgen-performance-soak-v1` — the whole-series review had no single
  target implementation, and the soak was that review's own prerequisite.
  Every other rewritten dependency was verified against its review
  packet's `Review target workstream`.
- 265 active `Kind: review` packets (`REVIEW_*.md`) moved byte-for-byte to
  `custodian/docs/ai_context/task_packets/archived/`. Nothing was deleted.
  Archived reviews are not claimable and, because none was `Status:
  complete`, none triggers the dispatcher's review-rejection gate.
- The managed `task_packets/README.md` index was regenerated with
  `task_packet_index.py --write`, and its hand-written sections were
  updated: the six `REVIEW_*` bullets (Sundered Keep Overlook, Persistent
  Recovery, Ash-Bell/Ritualant) were removed and their review-gate prose
  rewritten to the implementation landing.

## What was deliberately not changed

- Completion Truth and Execution Feedback for completed V2 packets still
  apply. Focused validation still applies.
- `_review_gate` in `dispatch.py` still blocks a downstream packet that
  depends on an archived review that was completed and *rejected* — but
  with no active review packets, that gate has nothing to fire on for new
  work. It is retained for historical archived reviews only.
- `workstream.py` paired-review artifact checks still apply to the archived
  `Kind: review` packets themselves; they do not gate implementations.
- Historical agent summaries, ledgers, and archived packets were not
  rewritten. They describe the old system accurately for their time.

## How to verify

```bash
python3 custodian/tools/agent/check_ai_context.py
python3 custodian/tools/agent/validate_review_pairing.py
python3 custodian/tools/agent/task_packet_index.py
python3 custodian/tools/agent/dispatch.py audit --json
python3 -m unittest custodian.tools.agent.test_task_packet_contract \
  custodian.tools.agent.test_task_packet_index \
  custodian.tools.agent.test_dispatch \
  custodian.tools.agent.test_task_packet_repair
```

After this lands, a ready/auto packet with no review packet at all must be
claimable, and `dispatch.py audit` must not list any packet as
`invalid_recovery` solely for pairing.
