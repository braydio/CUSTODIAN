# Review: Carrow West Draft House Interior V1

Workstream: `review-carrow-west-draft-house-interior-v1`

## Result

**Blocked; no review verdict or receipt issued.** The implementation itself is pinned at `856c5c8544fa28efc5181eaef426d955c167efd6` and focused machine-checkable checks passed, but a required real-render W1 screenshot crop cannot be captured in this environment. The review packet remains active at `ready` so a renderer-enabled fresh reviewer can resume. Reviewed runtime code was not edited.

## Evidence completed

- Pinned `origin/main`: `856c5c8544fa28efc5181eaef426d955c167efd6`; exact reviewed implementation commit: `856c5c8544fa28efc5181eaef426d955c167efd6`.
- Reviewed archived implementation packet, paired review packet, implementation closing summary, and landed diff.
- `carrow_yard_interior` passed after safe first import: W1 is 12×10/384×320 with 120 floor sprites, the approved grid and three-cell exit; generated-site binding passed at default and alternate seed; East remains 14×10 with 140 floor sprites and 13 production-art sprites; storage persistence, camera/environment/weather changes, and malformed grid/doorway, missing-site/art, allocation overlap, and actor-ownership controls passed.
- `carrow_backdrop_isolation_smoke.gd` passed with four transitions.
- `persistent_compound_layout`, `reciprocal_continuity_canon_docs`, and `visual_review_handoff` passed.
- Pinned local review-pairing and packet-reference checks passed for 77 auto-review packets. The connected-map generator validation is exercised by the interior smoke for default and alternate seeds. `git diff --check` passed on the reviewed implementation.

## Blocking evidence gap

The review packet requires a real game-runtime W1 screenshot crop plus collision/debug capture. A temporary capture harness could instantiate the room and verify its debug geometry, but `--headless` uses Godot's dummy renderer and returns no viewport texture. A non-headless retry under `xvfb-run` failed because X11 is unavailable, and Wayland is unavailable too. No screenshot/collision capture pair was emitted, so the visual/runtime evidence requirement is incomplete.

The ordinary `--changed` wrapper also attempted `git fetch --prune origin` in its pairing test and failed on read-only shared `FETCH_HEAD`; fetching is expressly prohibited in this checkout. The equivalent pairing and validation-reference checks were run against pinned local `HEAD` without network access. The initial focused smoke required the documented import to create Godot's fresh class cache.

## Recovery

Resume this same review workstream in a renderer-enabled environment, capture the minimal W1 room crop and collision/debug evidence, rerun the packet's required validation matrix without fetching, and then append the exact receipt only if the complete evidence is green.

## Authoring chat

Authoring chat: not-recorded

## Next Handoff
- Next workstream: review-carrow-west-draft-house-interior-v1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: not-recorded
- Refresh reason: none
- Next action: Resume this existing review branch through `workstream.py resume`, inspect the preserved screenshot/collision evidence and rerun the required reviewer checks in a fresh context; do not reclaim or edit runner recovery metadata.
- Blockers or open questions: The first runner context exited with a non-green validation report; a renderer-enabled capture has since been produced in the preserved run directory and needs independent verification.
