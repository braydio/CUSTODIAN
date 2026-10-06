# REVIEW: OPERATOR UNARMED FAST CHAIN NORTH VFX

- Packet schema: `custodian.task_packet.v2`
- Workstream: `review-operator-unarmed-fast-chain-north-vfx`
- Kind: `review`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-unarmed-fast-chain-north-vfx`
- Locks: `operator-assets, operator-runtime`
- Review: `none`
- Review target workstream: `operator-unarmed-fast-chain-north-vfx`
- Review target packet: `custodian/docs/ai_context/task_packets/archived/OPERATOR_UNARMED_FAST_CHAIN_NORTH_VFX.md`
- Review modes: `asset-pipeline, runtime, visual`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Reviewed main: `d75e0ee03cfd1348e997518b669485e2df5e8216`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac36534-b620-83ea-9805-525e2ae891ab`
- Summary backlink: Include the exact Authoring chat URL above in every durable review/correction/recovery summary and in the final `## Next Handoff`; do not shorten, redirect, or substitute it.
- Goal: Independently verify that the immutable North Fast 01-04 VFX handoff was normalized and published through the existing Operator replacement authority without gameplay drift, direction bleed, source/runtime divergence, alpha/cell defects, or loss of the approved Black-Gold Afterimage / Amber Vector escalation.
- Review focus:
  - immutable handoff identity/hash and preserved source-work provenance;
  - exact 6/6/7/8 96px-cell contracts and real RGBA alpha;
  - no per-frame independent scaling/repositioning or cross-cell bleed;
  - Fast 01 same-semantic guarded replacement and Fast 02-04 placeholder replacement;
  - source/runtime parity and exact North selector reachability;
  - South/E/W FX and all body art unchanged;
  - gameplay/profile/timing data unchanged;
  - final BODY+FX sequence reads 01 precision → 02 commitment → 03 rotation → 04 terminal pressure while the Operator remains visually dominant.
- Acceptance: Findings-first fresh-context review on live `main` records a pass or creates only bounded correction/re-review work justified by a confirmed defect or material evidence gap. Implementation summary claims alone are insufficient.
- Non-goals: Do not redesign the VFX family, add other directions, retune gameplay, implement Workbench FX adoption, or patch reviewed implementation directly.
- Task overrides: `TASK OVERRIDE: paired post-land review may stage, commit, and push only the durable review receipt, this review packet's lifecycle/archive metadata, its required closing summary, and bounded correction/re-review packets; do not edit the reviewed implementation or unrelated work.`

## Required Review Checks

1. Read the archived implementation packet/summary, live `design/VFX_DESIGN_LOCK.md`, immutable implementation manifest, package `VISUAL_REVIEW.md`, and current Operator source/runtime manifest.
2. Independently verify the fetched handoff ZIP size/SHA and the four preserved source-work master hashes against the package manifest.
3. Inspect all four final canonical source and runtime sheets. Prove exact dimensions 576×96 / 576×96 / 672×96 / 768×96, exact 6/6/7/8 clocks, RGBA with transparent pixels, and no visible-pixel crossing of 96px cell boundaries.
4. Prove canonical source/runtime pixel parity for Fast 01-04 North FX after build.
5. Prove Fast 02-04 North are materially non-empty and Fast 01 North changed only through the scoped replacement transaction.
6. Compare pre/post hashes for Fast 01-04 South and E/W FX plus all North body layers; unrelated art must remain unchanged.
7. Re-run strict animation contract, modular layers, modular fast attack, and selection-only fast-chain smoke.
8. Verify gameplay/profile/timing files are unchanged or semantically identical; no attack/contact/drive/buffer/damage/stamina/camera/audio tuning belongs in this diff.
9. Independently inspect the smallest North Fast 01→04 BODY+FX preview at gameplay scale. Confirm the design-lock progression: Fast 01 smallest; Fast 02 longer driving line; Fast 03 incomplete rotational crescent; Fast 04 compact broken pressure halo; contact white stays sparse; body silhouette remains readable.
10. If final 96px normalization materially changes the approved source character, treat that as a visual defect rather than assuming high-resolution source approval transfers automatically.
11. Run changed-file validation with complete coverage and `git diff --check`.
12. Record findings first with stable IDs and route only real defects/evidence gaps into correction work.

## Handoff

- Next action: Auto-dispatch after `operator-unarmed-fast-chain-north-vfx` lands and archives.
- Blockers or open questions: Dependency only.
