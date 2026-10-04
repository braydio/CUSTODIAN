# Kenney Isometric Blockout Feasibility — Claude Summary

Implemented K3D-1 as a detached, deterministic 2D A/B comparison. The scene uses the locked South Reach / North Processional / Ashen Forum anchors and camera transform, reads Road module positions and textures without instancing the production scene, and gives the Kenney variant no collision, navigation, or gameplay nodes.

Inventory matched seven expected Kenney pack identities. A duplicate Space Station Kit ZIP was hash-identical and counted once; the downloaded Kenney Shape archive is recorded as a later K3D-3 input. Sixteen source PNGs (ten Isometric Miniature Prototype, six Isometric Miniature Bases) were copied through two Asset V2 family ingests. Every runtime texture retained its 256×512 dimensions and exactly matched its source and V2 input-receipt SHA-256; RGBA pixel comparison also passed. Pipeline receipts, selected member/archive hashes, bundled license text, and the generated catalog are included.

The fixed 1280×720 comparison used Godot 4.7.2 stable, Vulkan Forward+ on an NVIDIA GeForce GTX 1650 SUPER. Each mode used a 30-frame settle and 120 sampled frames.

| Metric | Native | Kenney |
| --- | ---: | ---: |
| Frame time p50 (ms) | 0.450 | 0.419 |
| Frame time p95 (ms) | 0.679 | 0.665 |
| Rendered objects | 46 | 149 |
| Draw calls | 22 | 30 |
| Presentation nodes | 21 | 116 |
| Sprite instances | 10 | 115 |

Evidence is in `custodian/docs/ai_context/reports/kenney_presentation/`. The report records technical limits and leaves readability, scale, hierarchy, clutter/depth, and CUSTODIAN fit to the human. No art-direction winner is declared.

Validation passed: focused Kenney smoke; 13-test changed-file sweep; both family plans and statuses; Asset V2 doctor; manifest JSON parse; capture dimensions and composition checks; and `git diff --check`. The packet's `asset.py doctor --verbose` command was unsupported and corrected to `asset.py doctor`. The first host-sized capture and mixed-format composite were also corrected. The task branch's Road LFS payload matched the root checkout exactly, so no LFS copy was needed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Worktree initialization overlapped Git LFS checkout before the user paused; the first capture used the host logical viewport and the first composite used mismatched image formats. A byte-hash check was too strict for Asset V2's lossless PNG normalization.
- Root cause / contributing factors: Fresh worktree LFS hydration, display scaling, Image format requirements, and assuming the inbox remains populated after successful ingest.
- Prevention / pipeline improvement: Resume after checkout finishes; use a fixed-size SubViewport; convert images to a common format before blitting; verify the archived ingest receipt and runtime hash after V2 ingest.
- Tooling / docs drift discovered: `asset.py doctor` does not accept `--verbose`; packet command corrected.
- Follow-up: fixed-in-scope
- What worked: Asset V2 receipts, deterministic pixel comparison, focused smoke, single changed-file sweep.

## Next Handoff

- Next workstream: review-kenney-isometric-blockout-feasibility
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac17c6f-1dd8-83ea-b296-6e7a8726c7ff
- Refresh reason: none before paired review; K3D-2 requires the user's A/B judgment and planning refresh after review.
- Next action: land K3D-1 and run its paired technical review, then return the report and comparison to the authoring chat before K3D-2.
- Blockers or open questions: review is gated on K3D-1 landing.
