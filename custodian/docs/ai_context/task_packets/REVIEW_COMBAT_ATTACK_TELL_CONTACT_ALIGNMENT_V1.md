# REVIEW COMBAT ATTACK TELL–CONTACT ALIGNMENT V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-combat-attack-tell-contact-alignment-v1`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `combat-attack-tell-contact-alignment-v1`
- Locks: `enemy-runtime, operator-runtime, combat-feel`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: Independently falsify damage-to-visible-tell and parry timing after implementation lands.
- Review target workstream: `combat-attack-tell-contact-alignment-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/COMBAT_ATTACK_TELL_CONTACT_ALIGNMENT_V1.md`
- Reviewed main: `c4d150edec1ad60d3bc11336cad4333d60df384e`
- Authoring chat: `not-recorded`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Prove that the shipped actor-wide cue/contact alignment fixes unfair invisible or prematurely resolved contact without breaking damage, parry, dash or ranged contracts.
- Reviewed implementation acceptance: `A1–A7` from the exact archived `COMBAT_ATTACK_TELL_CONTACT_ALIGNMENT_V1.md`, including an exhaustive live damage-emitter inventory.
- Review evidence: Exact landed implementation SHA, actor-path matrix, per-attack ID cue/contact/phase logs, frame/clip metadata, focused smokes and final changed-file report. The 2026-10-13 GRUNT lethal report is diagnostic, not proof of the new behavior.
- Correction threshold: Any damaging attack ahead of its readable cue, missed live damaging actor, unverifiable parry interval, stale duplicate hit, fabricated visual proof or changes to untargeted damage/projectile contracts is blocking.
- Focused validation: Independently rerun the bounded `attack_tell_contact_alignment_smoke.gd` plus actual touched-owner smokes, attack-ID terminal reconciliation, canceled/parried/whiffed cases and low-FPS test. Prefer deterministic phase/frame evidence; only use one short visual proof for a material question. Run final required targeted/changed/pairing/doc checks without multiple broad sweeps.
- Review focus: Falsify `>=0.40 s` first-readable-cue budget for parryable actors, GRUNT scene's actual 0.42 s override, clip fallback, original lethal spatial case, Savage's 0.26 s original windup, cross-ability attack IDs, and prevention of damage after cancel. Confirm no actor class is silently excluded.
- Acceptance: Findings-first independent review from fresh context. Record stable `R0-NN` defects/evidence gaps with affected A1–A7 criteria; create a bounded correction/re-review pair when necessary, otherwise record exact PASS receipt and archive only through the approved lifecycle. Never mark the implementation accepted for a blocked/failing review.
- Non-goals: No implementation changes during review; no unrelated art/design tuning or optional presentation work.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the exact implementation packet is archived complete on fetched `origin/main`.
2. Review in a fresh independent workstream. Inspect live source, exact implementation SHA, named profiles and separately captured evidence, not implementer prose alone.
3. Falsify A1–A7, especially timer/animation divergence, non-parryable exceptions, clip/visibility failure, replayed hits and low FPS.
4. Record durable receipt and bounded correction lineage; do not modify implementation. Preserve original authoring-chat value in all summaries.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `not-recorded`
- Refresh reason: `none`
- Next action: PASS only after all A1–A7 checks are evidenced; otherwise preserve findings and author bounded correction work.
- Blockers or open questions: Implementation not yet published/landed.