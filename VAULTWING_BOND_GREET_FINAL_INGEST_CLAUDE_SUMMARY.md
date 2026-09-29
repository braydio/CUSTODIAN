# Vaultwing bond greet final ingest

## Outcome

The user's actual files are now present in `~/Downloads`; these are distinct
from the main-tracked LFS payloads previously inspected. SHA-256 values:

- `vw1.png`: `3b4e66cb0c96b6e2fdb41c3cce8eaac6c8a27eaec44967e74b631b7be448b7b2`
- `vw2.png`: `19b33d38ba3c18bb747648af89d17541297a7613f4283702cee4d6752c0fdf49`
- `vw3.png`: `c4d53e4d578318a8f25e8de8a1963b5c96fde558ffa920b62e0536b40c66e578`
- `vw4.png`: `708df1d2707354d84f7eeb8616f99f5d8000843d062b5d7d6ea4d95f14e0627e`

All four decode as 2172×724 RGBA with transparency; visual review matches the
packet's E/N/S/W assignment. The current normalizer detects only 5/6/5/4
alpha-X groups rather than eight because adjacent poses connect. Equal 8-cell
slicing places foreground on multiple frame seams (up to 121 active alpha
pixels in a seam column) and visually cuts wing/body anatomy. For comparison,
the previously accepted fixed-cell six-frame source had at most 9 active alpha
pixels at a seam. The current images therefore cannot be safely normalized by
the existing lossless extraction path without a reviewed segmentation method.

No Downloads originals were modified. No source_work, inbox, runtime, catalog,
quarantine, or production art was written. The task remains blocked pending
separable frames/sheets with transparent margins or an approved lossless
segmentation method.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: blocked
- Friction severity: medium
- What went wrong: The actual local images are valid RGBA sheets and correctly oriented, but their adjacent poses overlap/connect; alpha clustering merges them and equal-cell cropping cuts anatomy.
- Root cause / contributing factors: The current stager assumes separable alpha groups and has only a known fixed-cell exception for a prior six-frame sheet; this batch has more substantial foreground at cell seams.
- Prevention / pipeline improvement: Require per-frame extraction evidence and edge-safety review before staging; do not force a cell grid through connected anatomy.
- Tooling / docs drift discovered: packet input provenance is now verified against actual Downloads hashes; frame extraction remains the blocker.
- Follow-up: manual-follow-up — obtain separated frames or agree on a reviewed lossless segmentation path, then resume this workstream.
- What worked: source hashes, RGBA geometry, directional poses, alpha groups, and cell-edge evidence were checked before any production writes.
