# REVIEW: OPERATOR FAST CHAIN NORTH/SOUTH CONTINUITY

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-fast-chain-south-continuity`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-fast-chain-south-continuity`
- Locks: `operator-assets, operator-runtime`
- Review: `none`
- Review target workstream: `operator-fast-chain-south-continuity`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_FAST_CHAIN_SOUTH_CONTINUITY.md`
- Reviewed main: `e7402591337fbd7540ea13d5219fedff36f67a47`
- Reviewed implementation commit: `e7402591337fbd7540ea13d5219fedff36f67a47`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac323e0-c600-83ea-bb5c-c706c785cf73`
- Summary backlink: Include this exact Authoring chat URL above in every durable implementation/review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Review modes: `code, architecture, asset-pipeline, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Goal: Independently verify the landed Fast-chain cardinal art closeout on live `main`: seven approved North/South body strips are preserved and normalized at 96×96, their lower/upper decompositions recombine exactly, exact North/South runtime selection replaces the intended body fallbacks, six Fast 02-04 North/South FX identities are truthful fully-transparent editable placeholders rather than completed VFX, protected Fast 01 authorities and gameplay timing remain unchanged, and the compact human visual-review lane accurately represents the landed body art.
- Reviewed implementation acceptance:
  - Fast 01 North plus Fast 02-04 North/South approved full-body masters are preserved byte-for-byte as source provenance and normalized through the repository `pixelart` alias with crisp/method 1 at 96×96 cells.
  - The seven normalized body strips use locked 6/6/7/8 frame clocks as applicable and split into `lower_body` / `upper_body` with exact pixel recomposition and synchronized clocks.
  - Fast 02-04 North/South each own a canonical/runtime `fx` strip with the same animation clock and alpha=0 for every pixel. These six tracks are OPUI authoring placeholders only; their existence is not VFX-completion evidence.
  - Existing Fast 01 South full-body/lower/upper/FX and Fast 01 North FX hashes remain unchanged.
  - Existing East/West art and all Fists gameplay timing/profile data, damage, hit windows, stamina, drive, buffering, chain order, and selectors remain unchanged except for exact-direction asset availability replacing the obsolete body fallback expectation.
  - Specialized Operator publication/provenance and focused contract/selector/modular validation are green.
  - The full-chain smoke's three carry interruption/collision failures are accepted as pre-existing baseline debt only if the reviewer reproduces the same failures on the recorded pre-implementation baseline and finds no implementation delta.
  - Compact human visual evidence exists at `/CUSTODIAN/visual_review/operator-fast-chain-south-continuity/20261005T202406Z/REVIEW_MANIFEST.json` and clearly labels Fast 02-04 FX as intentionally transparent placeholders.
- Review evidence:
  - `OPERATOR_FAST_CHAIN_SOUTH_CONTINUITY_CLAUDE_SUMMARY.md`
  - archived implementation packet and its `## Completion Truth`
  - exact source/runtime hashes and normalization receipts produced by the implementation
  - specialized Operator ingest/runtime-build receipts
  - canonical runtime manifest/reachability diff and exact-selector evidence
  - `operator_fast01_south_decomposition_smoke.py`
  - `operator_animation_contract_report.py --strict`
  - `operator_unarmed_fast_chain_smoke.gd -- --selection-only`
  - `operator_modular_layers_smoke.gd`
  - `operator_modular_fast_attack_smoke.gd`
  - full-chain smoke results on landed main and recorded baseline `16566c48`
  - Dropbox review manifest `/CUSTODIAN/visual_review/operator-fast-chain-south-continuity/20261005T202406Z/REVIEW_MANIFEST.json` and its `fast_ns_shared_transform.png` artifact
  - user/ChatGPT visual disposition from the authoring chat when available
- Correction threshold:
  - Correction-worthy: wrong 96×96/frame-count contract; missing/duplicated/lost body pixels; lower+upper failing exact recomposition; registration/baseline/scale drift that violates the approved body presentation; exact North/South body selector still falling back; placeholder FX missing, wrong clock/canvas, nontransparent, or falsely represented as finished VFX; unintended Fast 01/E/W pixel changes; publication/provenance bypass; gameplay timing/profile drift; or a new full-chain regression not present on baseline.
  - Not a defect by itself: Fast 02-04 North/South FX rendering nothing. They are intentionally all-alpha-zero authoring placeholders.
  - Baseline-only carry interruption/collision failures route to separate gameplay/test-fixture follow-up, not this art correction cycle, unless the review proves a new delta caused by `e7402591`.
  - Optional polish and future real VFX authoring route to next-slice/deferred.
- Focused validation:
  1. Re-run the current strict Operator animation contract/schema report.
  2. Verify exact North/South selector resolution and synchronized lower/upper clocks for Fast 01-04 body identities affected by this slice.
  3. Verify all seven normalized body contracts, exact lower+upper recomposition, alpha/cell bounds, and source/runtime pixel parity from durable receipts or fresh checks where receipts are insufficient.
  4. Verify all six Fast 02-04 N/S FX source/runtime strips are exact 96×96-cell clock-matched RGBA sheets with alpha zero at every pixel; verify no VFX requirement/reachability truth overstates them as completed art.
  5. Re-prove protected Fast 01 South body/FX and Fast 01 North FX hashes and confirm unrelated E/W source/runtime art did not change.
  6. Re-run `operator_fast01_south_decomposition_smoke.py`, `operator_unarmed_fast_chain_smoke.gd -- --selection-only`, `operator_modular_layers_smoke.gd`, and `operator_modular_fast_attack_smoke.gd`.
  7. Re-run the full chain smoke only as regression evidence. If its three carry interruption/collision assertions still fail, compare directly with baseline `16566c48`; do not create art corrections for baseline-equivalent failures.
  8. Reuse the existing compact Dropbox artifact instead of recapturing equivalent frames unless it is stale or materially insufficient.
- Review focus:
  - source/provenance integrity and exact approved-master preservation;
  - mandatory 96×96 crisp normalization with one shared whole-strip transform per identity;
  - semantic lower/upper ownership and exact recomposition;
  - North/South body scale, grounding, pelvis/legs/garment continuity, and distinct 01→04 silhouettes;
  - exact cardinal runtime selection and synchronized clocks;
  - truthful placeholder-FX semantics and future OPUI REPLACE ownership;
  - zero simulation/gameplay retune;
  - no self-approved aesthetic baseline;
  - no mutation of the dirty project-root checkout or unrelated `BRANCH_ARCHIVE.md` state.
- Acceptance: Produce a findings-first independent review of live `main` from a fresh isolated reviewer context. Record `passed` only when objective contracts are proven and the required human/ChatGPT visual disposition exists; use `human_required` when objective checks pass but the normalized contact sheet still needs subjective disposition. Give each finding a stable cycle-scoped ID (`R<cycle>-<NN>`) with class, domain, affected acceptance, evidence, disposition, and rationale. Blocking defects/material proof gaps create `operator-fast-chain-south-continuity-review-corrections-<n>` plus paired re-review. Do not patch reviewed implementation code.
- Non-goals: Do not redesign/regenerate the chain; author finished Fast 02-04 N/S VFX; migrate East/West canvas sizes; change gameplay timing; expand diagonal coverage; modify Workbench architecture; repair baseline carry interruption/collision behavior; reconcile/synchronize the dirty project-root checkout; edit `BRANCH_ARCHIVE.md`; or fix reviewed implementation directly.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation, the dirty root checkout, BRANCH_ARCHIVE.md, or unrelated work.`

## Handoff

- Next action: Auto-dispatch now from fresh `origin/main`; the implementation dependency is complete and archived at `e7402591`. Review the landed N/S body art and truthful placeholder-FX contract, reusing the existing Dropbox evidence.
- Blockers or open questions: No implementation blocker. Human visual disposition of the normalized body contact sheet may still be required. The dirty project-root checkout and baseline carry-smoke debt are explicitly outside this review.
