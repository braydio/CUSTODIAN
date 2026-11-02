# Ranged Operator V2 tooling report

Date: 2026-09-21

## Scope

The six generation masters were found in `review_ranged/`, not at repository
root. They were copied byte-for-byte into:

`custodian/asset_drop/source_work/operator/operator_ranged_2h_refresh_v1/raw/`

The review metadata and alpha inspection show real transparent RGBA sources,
not matte-backed images. The masters are irregular generation contact sheets,
not publishable strips:

| semantic input | useful figures | source geometry |
|---|---:|---|
| relaxed_01 body | 5 | 2172x724 RGBA, 5 figures |
| aim_01 transition body | 5 | 2172x724 RGBA, 5 figures |
| stance_01 body | 5 | 2172x724 RGBA, 5 figures |
| reload_01 body | 6 | 2172x724 RGBA, 6 figures |
| reload_01 weapon reference | 6 | 2172x724 RGBA, 6 figures |
| reload_01 FX | 5 | 2172x724 RGBA, 5 figures |

Prepared, centered 724px grids are in the sibling `prepared/` directory. The
six raw source hashes are recorded by the preserved files and match the review
directory inputs.

SHA256 (review input = preserved raw copy):

```text
relaxed_01 body       f049e600dc59416ed29feec5f65b9c85f2907bc41bb23482b9578477a97df2a7
aim_01 transition     52b3d0feef5b8c6adeb94693e01bf8a0f810527d529060b599aba82d407f5bc3
stance_01 body        6344d3657a9418c08894c30cd9a16494447ed3551a03088d997595395f1c1d67
reload_01 body        820664cb5f2efaee78fc5dd627ff18d17c5f819ed8f74b0451a7fd32cc120d33
reload_01 weapon      2ff10f11823fa1b3c104d46cd3d9425ffdb5b0ec836fbd864b4dd26e3ff796bf
reload_01 FX          9ca5fe7b4b9f7208a67f80b10e3039fb7b433253d3040ef1c3fda9494750c66f
```

## Source Session results

The current Source Session CLI made geometry analysis, shared registration and
96px conversion substantially easier. Six sessions were created:

| semantic input | session | plan |
|---|---|---|
| relaxed_01 | `96ae474550c4` | 5f, feet, balanced |
| aim_01 | `804dcfa027fd` | 5f, feet, balanced |
| stance_01 | `3fbd6565a8cd` | 5f, feet, balanced |
| reload_01 body | `19d18bb1cbed` | 6f, feet, balanced |
| reload_01 weapon reference | `0c88a240e80d` | 6f, feet, balanced |
| reload_01 FX | `10e989f8fa9a` | 5f, feet, balanced |

All six analyses produced no clipping or registration findings. The tool
reported stable integer registration (all offsets zero) and useful global
scales. The review artifacts and converted candidates are retained under
`.ai/operator_art_agent/source_sessions/` for inspection.

## What remains blocked

The posture masters bake the Carbine into the body. Publishing them as the
live `upper_body` layer would duplicate the socket-driven weapon; publishing
them as `full_body` would be ignored by the existing modular ranged selector
while lower/upper layers exist. A safe semantic body/weapon split requires
bounded art editing against the current socket references and cannot be
inferred by the Source Session normalizer alone.

The reload FX master has five useful figures while the reload body and weapon
references have six. It therefore cannot be synchronized without inventing or
dropping a temporal pose. It was not promoted to runtime.

The weapon master remains reference evidence only, consistent with the static
socket-driven Carbine contract. No animated runtime weapon strip was created.
No W direction was fabricated.

## Recommendations

1. Add a first-class bounded body/weapon decomposition workflow to the Art
   Agent/Workbench. It should accept a canonical weapon reference and produce
   an auditable upper-body mask while preserving hands and grip pixels.
2. Make Source Session accept an explicit extracted-frame manifest rather than
   requiring callers to pre-center irregular contact-sheet figures manually.
3. Add a pre-handoff timing check that rejects action-owned FX whose frame count
   differs from the action clock, with a clear synchronization diagnostic.
4. Keep the current static-weapon/socket authority and `aim_01` forward/reverse
   contract; do not introduce `take_aim_01` as a separate action.

## Outcome

This pass intentionally stopped before canonical ingest. No gameplay, timing,
runtime catalog, or ranged presentation authority was changed. The preserved
raw and prepared evidence is ready for a focused decomposition pass.

## Correction — 2026-09-22

A subsequent whole-tree ingest briefly published the reload weapon reference
master as active `ranged_2h/cosmetic/reload_01/e/weapon` and fabricated a west
counterpart. That was an ingest-boundary error, not a change to the Hybrid
Weapon Socket contract. The active source/runtime weapon identities have now
been removed through the normal superseded-runtime cleanup and the generated
runtime manifest/catalog/SpriteFrames were rebuilt. The six-frame weapon master
remains preserved source/reference evidence only; no ranged reload weapon layer
is production authority and no W direction is published from this batch.

The reload FX master remains deferred: it contains five authored frames against
the six-frame reload body. No runtime FX clock was invented or silently
resampled. The bounded body/weapon decomposition and reload-clock decision
remain follow-up work for the Art Agent/Workbench path.
