# PROCGEN Alpine Cliff Presentation V1 — SOUTH seam correction

**Workstream:** `procgen-alpine-cliff-presentation-v1`

**Authoring chat:** https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391

## Change

The rejected SOUTH viewport was unchanged because the authored SOUTH socket sat near the geology silhouette and its contract accepted only an 8 px connected-alpha crossing. The actual contact had just 24 opaque source pixels inward from the socket, so the mechanical test did not guarantee a visible terrace embed.

Moved sockets for `south_broad_01`, `south_broken_01`, and `south_rooted_01` to y=180. Added a 96 px per-state minimum opaque source support and a 64 px minimum connected-alpha overlap on both sides of the final-world SOUTH frontier. The Alpine profile now owns these thresholds; source derivation, Asset V2 verification, composer placement, and focused smoke enforce the same contract. All 26 normalized states were regenerated; runtime PNG hashes and dimensions remained unchanged.

## Evidence

- `godot --headless --path custodian --script res://tools/validation/procgen_alpine_cliff_presentation_smoke.gd` — PASS.
- `python3 custodian/tools/validation/verify_alpine_cliff_presentation_assets.py` — PASS, 26 states.
- `TMPDIR=/dev/shm python3 custodian/tools/validation/run_validation.py --changed --json` — all five selected owners passed. Aggregate `complete=false` because existing untracked Moment Forge report files and unrelated `.uid` files have no changed-file owners; those artifacts were preserved.
- Clean committed-SHA capture passed from detached checkout `e2c7b7de038e799c5af16b11c63f66a8f86d75a0`: manifest records `dirty=false`, Moment Forge assertions passed, and scenario SHA is `0b1b14582ccf83d4c1833fc14c6c26fa0f2bfbe62edf81626d4c509682a91255`.
- Dedicated SOUTH frame `tick_000075.png` SHA is `c54e2531138bc5801c9e7a9b78f77088254877ac1a227f018ce140e234508a0b`, changed from rejected `4061704a578aa5b92b0948f2ce2af71f1966f8c57af72b76c05952b033998eaa`. The mechanical pre-review hash gate therefore passed.
- Published the compact human-review handoff at `/CUSTODIAN/visual_review/procgen-alpine-cliff-presentation-v1/20261015T060324Z/REVIEW_MANIFEST.json` (delete-after-review). Questions: SOUTH terrace/fascia join; attached geology/no crop wall; N/E/W and playable-edge truthfulness.
- User had already executed the prior delete-after-review cleanup. The manifest was absent when this turn retried it.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: A permissive seam threshold passed while the SOUTH viewport stayed byte-identical to rejected evidence.
- Root cause / contributing factors: SOUTH source socket was only 24 opaque pixels into the geology; final-world overlap only required 8 px.
- Prevention / pipeline improvement: Use profile-owned per-state alpha depth and final-world overlap thresholds, checked at derivation, runtime placement, and smoke levels.
- Tooling / docs drift discovered: Changed-file routing reports incomplete coverage for existing untracked reports and UID artifacts; all selected owners passed.
- Follow-up: fixed-in-scope
- What worked: Measured source alpha and final-world overlap directly, then used one profile contract across producer and consumer checks.

## Next Handoff

- Next workstream: procgen-alpine-cliff-presentation-v1
- Next packet state: human-required
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391
- Refresh reason: none
- Next action: Record the human visual disposition for `/CUSTODIAN/visual_review/procgen-alpine-cliff-presentation-v1/20261015T060324Z/REVIEW_MANIFEST.json`; run its delete-after-review cleanup after disposition. Close AP2 only if the human gate passes.
- Blockers or open questions: Human visual disposition pending; AP2 remains open and AP3 remains gated.


## Recovered visual disposition — 2026-10-24

The user recovered the actual October 15, 2026 ChatGPT review outcome and confirmed it was reaffirmed later that day. Final disposition: PASS / PASS / PASS for the SOUTH terrace/fascia join, attached-geology silhouette, and N/E/W composition with truthful playable edges. Evidence: /CUSTODIAN/visual_review/procgen-alpine-cliff-presentation-v1/20261015T060324Z/REVIEW_MANIFEST.json; clean capture e2c7b7de038e799c5af16b11c63f66a8f86d75a0; SOUTH tick_000075.png, SHA-256 c54e2531138bc5801c9e7a9b78f77088254877ac1a227f018ce140e234508a0b. The separate visual-review conversation URL could not be recovered. This disposition is based on the user's report of that earlier ChatGPT review; no new review was performed. The October 14 failures remain in the chronology as superseded historical results.
