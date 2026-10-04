# K3D-1 Isometric Blockout Report

## Pack matches and selected count

Seven expected local Kenney pack identities matched their bundled license metadata. Sixteen original 256×512 PNGs were selected: ten from Isometric Miniature Prototype and six from Isometric Miniature Bases. Both bundled licenses identify CC0 1.0. `k3d1_source_inventory.json` records archive SHA-256 values, member counts, version/license text, selected member paths and hashes, dimensions, alpha, state IDs, semantic roles, Asset V2 archive paths, runtime hashes, and source/runtime pixel-equality results.

The duplicate `kenney_space-station-kit(1).zip` is byte-identical to `kenney_space-station-kit.zip` and is counted once. `kenney-shape-1.6.0-linux.zip` is recorded as a future K3D-3 tool input, outside the seven-pack K3D-1 set.

## A/B metrics

Captured with Godot 4.7.2 stable, Vulkan Forward+ on NVIDIA GeForce GTX 1650 SUPER. Each mode used 30 settle frames and 120 sampled frames at the shared 1280×720 viewport and camera transform. Renderer counters are available for this run.

| Metric | CUSTODIAN native 2D | Kenney Isometric 2D |
| --- | ---: | ---: |
| Frame time p50 (ms) | 0.450 | 0.419 |
| Frame time p95 (ms) | 0.679 | 0.665 |
| Object node count | 221 | 221 |
| Rendered objects | 46 | 149 |
| Draw calls | 22 | 30 |
| Presentation node count | 21 | 116 |
| Selected runtime assets | 16 | 16 |
| Sprite instances | 10 | 115 |

Full per-mode data is in `k3d1_metrics.json`. This is a single local renderer sample, not a hardware-independent performance claim.

## Validation result

- Both Asset V2 plans were safe; both family ingests completed and Godot imports resolved all 16 assets.
- All 16 runtime textures were pixel-identical to their selected source PNGs and retained 256×512 dimensions.
- Focused `kenney_isometric_blockout_feasibility` smoke passed.
- A/B capture dimensions are 1280×720 each; composite dimensions are 2560×720.
- Changed-file validation and final `git diff --check` are recorded at task closeout.

## Comparison image

`custodian/docs/ai_context/reports/kenney_presentation/k3d1_ab_compare.png` (native left, Kenney right). Individual captures: `k3d1_native.png` and `k3d1_kenney.png`.

## Technical drift and defects

- H1 remains `in_progress`; its runtime layout file is absent. This experiment uses the locked `HUB_FIRST_SET_BLOCKOUT.md` extents and Road `MODULES` presentation data without instancing the production scene.
- The host display exposed a 931×523 logical window despite the project’s 1280×720 setting. A dedicated 1280×720 `SubViewport` produces the required fixed comparison viewport without changing project or production window settings.
- All 16 archive-member, Asset V2 input-receipt, and runtime SHA-256 values match exactly; source/runtime dimensions and RGBA pixels also match.
- The packet’s `asset.py doctor --verbose` command is not accepted by the live CLI. `asset.py doctor` is the supported invocation.
- The comparison is a bounded visual blockout. It does not establish production traversal, collision, navigation, lighting, or final asset scale.

## Human questions

- Is the processional route readable at this shared camera scale?
- Do the Kenney forms communicate an appropriate architectural scale beside the existing Road plates?
- Does the dais/threshold composition provide enough civic hierarchy?
- Does the Kenney blockout create too much visual clutter or depth ambiguity?
- Does the presentation still feel like CUSTODIAN?
