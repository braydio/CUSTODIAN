# Ranged 2H rifle source-work stash

- Moved `operator_ranged_2h_southwest_rifle_idle_relaxed_01_5f_96f.png` (480x96, 5 frames of 96px, weapon-only rifle layer) from the repo root to
  `custodian/content/sprites/operator/source/source_work/ranged_2h/posture/relaxed_01/`.
- Staged in `source_work` on purpose: it is not on the runtime/animation pipeline path, so nothing loads or overwrites it. The `sw` direction is not an `e`/`w` pipeline token yet.
- Not ingested, no runtime files touched. Copy verified byte-identical before the root copy was removed.
- Next: strip the rifle from the baked upper/lower `sw` art so only this layer carries the weapon, then ingest via the Operator pipeline.
