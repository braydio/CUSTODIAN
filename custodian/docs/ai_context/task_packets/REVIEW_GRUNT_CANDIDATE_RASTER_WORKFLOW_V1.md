# REVIEW GRUNT CANDIDATE RASTER WORKFLOW V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-grunt-candidate-raster-workflow-v1`
- Authoring handoff: `auto`
- Kind: `review`
- Status: `draft`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `grunt-candidate-raster-workflow-v1`
- Locks: `humanoid-raster-tooling`
- Review: `none`
- Review stage: `post-land`
- Review modes: `code, architecture, asset-pipeline, workflow`
- Paired review workstream: `none`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review target workstream: `grunt-candidate-raster-workflow-v1`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/GRUNT_CANDIDATE_RASTER_WORKFLOW_V1.md`
- Reviewed main: `ee52511ad66b610bcea3d28d6b918693b85c0530`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f`
- Visual review: `conditional`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Goal: Independently prove reproducible, safe humanoid raster workflow outputs and A/B preview integrity without allowing accidental source mutation, automatic art approval, or duplication of existing pixelart/Asset V2 authorities.
- Reviewed implementation acceptance: `A1-A8` from the exact archived implementation packet.
- Review evidence: Landed SHA, tracked-input existence plus real Grunt source hash, four source ROI measurements, 4x3 direction/size output hashes, repeated-run canonical JSON, mode selection evidence, full changed-pixel cleanup ledger, warnings/negative-fixture reports, existing pixelart regression and A/B harness load proof.
- Correction threshold: Source or old preview mutation; source hash mismatch silently bypassed; external chat-only implementation dependency; guessed baseline presented as measured; raster mode substitution; unintended clipping or alpha matte; bright-art suppression without explicit approval; nondeterministic output; unsafe output traversal; false Asset V2 status; broken Grunt playback; missing expected test evidence => blocking finding or material evidence gap.
- Focused validation: Re-run new deterministic raster workflow smoke on both synthetic and approved Grunt source; invalid ROIs, same source/output, empty/invalid/corrupted art, hash mismatch, two same-plan byte/pixel equality checks; `python3 custodian/tools/validation/pixelart_colors_smoke.py`; applicable converter/asset boundary tests named by implementation; headless dev scene loading only if updated; `git diff --check`; required targeted reviewer closeout gates.
- Review focus: Falsify baseline/foot plane anchoring against original Grunt scene; detect alpha black-foot block separately from background; ensure disconnected intended armor details and protected highlights survive; ensure all generated PNGs remain dev-only, 96x96, no runtime alias or source mutation; verify per-variant masks/digests and whether reproducible QA results are facts, not art-quality verdicts. Independently check source hash `cbb8f29c9ed2e86c3d3fed7a2664b1828cc6d69a536d199e7bd209a1ff3ec557` with checked-in ZIP fallback rather than accepting an unhydrated LFS pointer as image data.
- Acceptance: Fresh-context findings-first R0-NN review with severity, evidence, affected A1-A8, disposition; no pass without actual replay and false-positive cleanup tests. True defects require bounded correction and fresh review. Human visual selection remains explicitly outside technical completion.
- Non-goals: No implementation edits, source-art retouch, family ingestion, combat changes, or concurrent tooling migration.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Procedure

1. Claim only after the exact implementation is archived complete; inspect latest main and reproduce all A1-A8 from real code and test outputs, not the implementer's prose.
2. Run focused tests, compare direct source and generated output hashes, inspect only compact 4-view 72px pixel/diff ROIs when objective claims need visual falsification.
3. Check that the pre-existing generic conversion/hardening roadmap is still deferred unless independently landed; log any documentation drift as a finding or bounded follow-up, never rewrite third-party work.
4. Publish a truthful review receipt and archive according to normal paired-review lifecycle. Closing summary includes `Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad40d97-158c-83ea-ad70-d593bc628e6f`.

## Handoff

- Next workstream: `none`
- Any subjective Grunt visual approval, rigging, or runtime replacement requires separate user authorization.
