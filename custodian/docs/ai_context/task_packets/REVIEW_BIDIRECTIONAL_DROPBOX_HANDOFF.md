# REVIEW: BIDIRECTIONAL DROPBOX HANDOFF

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-bidirectional-dropbox-handoff`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `bidirectional-dropbox-handoff`
- Locks: `dropbox-handoff`
- Review: `none`
- Review target workstream: `bidirectional-dropbox-handoff`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/BIDIRECTIONAL_DROPBOX_HANDOFF.md`
- Reviewed main: `10560b17`
- Authoring chat: `https://chatgpt.com/share/6ac306f1-f2a0-83e9-9823-86add3c01c91?ogimg=plain`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the landed bidirectional Dropbox handoff against its own packet contract, especially fail-closed external-input handling, credential boundaries, live-provider proof, and preservation of the existing visual-review publisher.
- Reviewed implementation acceptance: Verify every Acceptance item in archived `BIDIRECTIONAL_DROPBOX_HANDOFF.md`, especially immutable manifest-last inputs, path/hash/size safety, staging-only behavior, real Dropbox PNG+ZIP fetch proof, preserved outbound publication, documentation convergence, and absence of credentials or smoke binaries in Git.
- Review evidence: Reuse the implementation closing summary, archived completion receipt, focused unit results, changed-file validation receipt, AI-context/pairing checks, and exact live Dropbox smoke paths/hashes. Gather new evidence only where missing, stale, contradictory, or insufficient.
- Correction threshold: Create correction work only for a confirmed acceptance/correctness defect or an evidence gap that prevents confidence in required acceptance. Route non-blocking issues and optional improvements to next-slice/deferred unless separately justified. There is no subjective art-direction decision in this workflow review.
- Focused validation: Re-run the inbound handoff focused tests, `python3 custodian/tools/iteration/test_publish_review_artifacts.py`, the relevant changed-file validation selection, and `python3 custodian/tools/agent/check_ai_context.py`. Re-run a minimal live Dropbox read/hash check against the implementation's successful smoke paths; do not create redundant large media.
- Review focus:
  - Confirm one shared Dropbox transport authority rather than diverging inbound/outbound remote selection.
  - Confirm backward compatibility of outbound CLI/env/manifest/latest-pointer behavior.
  - Adversarially inspect path normalization, manifest identity binding, duplicate/extra-file handling, byte limits, checksum/size verification, atomic staging, and unsafe destination rejection.
  - Confirm `HANDOFF_MANIFEST.json` is the commit marker and committed inbound handoffs are immutable/new-ID-on-retry.
  - Confirm ZIP payloads stay opaque and fetched bytes are not auto-executed, auto-extracted, or routed into runtime/Asset V2.
  - Confirm live-provider evidence came from the configured Dropbox remote rather than only fake-rclone/unit fixtures.
  - Confirm no credential/token/config output entered Git, durable summaries, or test fixtures.
  - Confirm active docs agree on `CUSTODIAN/implementation_inputs` versus `CUSTODIAN/visual_review` and preserve Git as authority.
- Acceptance: Produce a findings-first independent review of live `main`. Record `passed` only if the archived implementation packet's acceptance is materially proven. Give every finding a stable `R0-NN` ID with class, domain, affected acceptance, evidence, disposition, and rationale. Any defect that can admit unverified/ambiguous external bytes, bypass staging/Asset V2, leak credentials, overwrite a committed handoff, or regress outbound review publication is correction-worthy.
- Non-goals: Do not redesign cloud storage, add a watcher/daemon, alter Asset Pipeline V2 semantics, perform subjective visual critique, or patch reviewed implementation code in this workstream.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure Notes

1. Start from fresh `origin/main` after the implementation dependency is complete/archived.
2. Treat the implementation summary as a claim to verify, not evidence by itself.
3. Inspect actual Dropbox smoke manifest/path/hash receipts and minimally re-read remote bytes when available.
4. Run focused hostile-manifest cases before any broad validation.
5. Append the Independent Review receipt and create bounded correction work only if required.

## Handoff

- Next workstream: `none`
- Next packet state: `none`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/share/6ac306f1-f2a0-83e9-9823-86add3c01c91?ogimg=plain`
- Refresh reason: `none`
- Next action: `If the review passes, use the bidirectional handoff contract in future asset/task packets; if findings exist, execute the generated bounded correction packet.`
- Blockers or open questions: `none`
