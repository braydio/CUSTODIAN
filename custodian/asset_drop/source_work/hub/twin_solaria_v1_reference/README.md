# Twin Solaria Runtime Crop Pack V1 — preserved source references

This directory preserves the ZIP's source-truth metadata for the Twin Solaria crop pass. The original ZIP was temporary and has been removed from the repository worktree.

## Preserved here

- `MASTER_TRACKER.csv` — crop identity, dimensions, hashes, and historical placement/source metadata.
- `CROP_MANIFEST.json` — original crop definitions and hashes.
- `PLACEMENT_MANIFEST.json` — original registered placements and source paths, updated only where the four reference crops were moved into this directory.
- Four reference-only crops: resolved route vista, Second Crown absence, and west/east Crown Verge.

The 15 flattened landmark crops are preserved in the sibling `twin_solaria_v1_landmarks/` directory. They are references, not independent runtime props. The eight gameplay plates and exact uploaded master are preserved in their own source directories.

The master SHA-256 is `a2ffef3f51e690ff6f65e0933843b8efb1b3bfcf1aea7290352b646fcb7bb6ec`. No source crop was resized or otherwise modified.

## Authority note

The ZIP's old implementation spec, proposed family contracts, and standalone runtime guidance are superseded and were not copied as active authority. Current design under `design/` governs future implementation. This salvage publishes only the eight required Asset V2 gameplay plate states and a temporary fidelity underlay; it does not implement the production authored-level runtime.

The ZIP README historically expected a 3500×3000 development preview. A later donor audit measured the loaded development texture at 4000×3000. The full runtime task must resolve whether the development asset is legitimately 4000×3000 or the preview should be restored to the documented 3500×3000 source. This preview debt does not change the exact 2048×1536 production source.
