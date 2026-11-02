# Awakening Handoff Readiness Art Registration Proof — Review Corrections 1

## Outcome

Completed `awakening-handoff-readiness-art-convergence-v1-r1-review-corrections-1` as a bounded validation and documentation change. No runtime, art, Layout, collision, or progression files changed.

## Correction

The registration smoke now reads the seven ordinary-room definitions from `AwakeningLayout.ZONES`, grows each live envelope by 64 pixels, and checks underlay and foreground texture canvases, global bounds, centers, scale, rotation, anchor, and parity. Zones 04/05 are explicitly excluded from that formula and checked as the approved shared composition exception: root registration, layer order, canvas dimensions, resource identities, SHA-256 values, alpha silhouette bounds, hidden legacy zone sprites, and intentionally unbound Locker foreground.

The smoke includes negative controls for a changed Layout envelope, sprite transform, foreground canvas, composition child transform, and composition source state. The focused validation recipe now documents the ordinary rule and 04/05 exception.

## Verification

All six required focused checks passed individually: `awakening_art_registration`, `awakening_first_return`, `awakening_registered_composition_traversal`, `awakening_first_return_geometry`, `awakening_first_return_progression`, and `awakening_connector_asset_contract`. The registration smoke was also run directly and passed. `git diff --check` passed.

The first multi-`--test` command validated only the last ID because the CLI option is single-valued; I reran all six IDs individually. A new worktree required a full editor import before Godot tests could run. During implementation, the focused smoke caught and I fixed a GDScript type inference error and numeric-type mismatch in the source report comparison.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: fresh worktree cache initialization took a full project import; repeated `--test` flags did not select multiple validation IDs.
- Root cause / contributing factors: empty per-worktree Godot import cache and single-valued validation CLI argument.
- Prevention / pipeline improvement: initialize editor cache once and run each focused test ID individually.
- Tooling / docs drift discovered: `run_validation.py --test` uses the final supplied ID when repeated; outside this packet's bounded tooling surface.
- Follow-up: none
- What worked: executable negative controls prove the registration check rejects representative layout, transform, canvas, child, and source-state drift.

## Authoring chat

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a

## Next Handoff

- Next workstream: review-awakening-handoff-readiness-art-convergence-v1-r1-review-corrections-1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/local-chatgpt%3Aeecfd882-488a-4da3-ab77-b2fbd36b114a
- Refresh reason: none
- Next action: after this correction lands and archives, dispatch the paired review in a fresh reviewer context and independently fault-check the negative controls.
- Blockers or open questions: none.
