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
- The final SOUTH render hash is still pending a committed-SHA capture. Compare directly with rejected SHA `4061704a578aa5b92b0948f2ce2af71f1966f8c57af72b76c05952b033998eaa`; do not publish for human review if unchanged.
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
- Next action: Capture the same four-direction Moment Forge scenario from the clean committed SHA. Compare its SOUTH keyframe hash against 4061704a578aa5b92b0948f2ce2af71f1966f8c57af72b76c05952b033998eaa and publish only if it differs.
- Blockers or open questions: Capture result unknown; AP2 remains open and AP3 remains gated.
