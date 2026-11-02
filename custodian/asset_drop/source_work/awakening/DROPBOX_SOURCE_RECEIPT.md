# Awakening 04→05 Dropbox Production Source Receipt

All three preserved source masters below are the exact bytes fetched from the task packet's Dropbox file IDs and revisions. The original connector source set and previous Dust master remain under each family's `pre_dropbox_source_set_20261007/` folder. The historical flattened connector `full_plate_source.png` remains untouched.

| Asset | Dropbox path | File ID / revision | SHA-256 | Source size |
|---|---|---|---|---:|
| Dust Lung underlay | `/CUSTODIAN/implementation_inputs/awakening_dust_lung_underlay_source_v1.png` | `id:8NXqdXuW6GUAAAAAAAACjg` / `65d471fa9ab23915cdd61` | `fa017e6daa218d9a0713be760f19acdb285ae0c5e01854c3fe43126ca547f111` | 1216×1216 |
| Direct connector | `/CUSTODIAN/implementation_inputs/awakening_04_05_direct_connector_source_v1.png` | `id:8NXqdXuW6GUAAAAAAAACjw` / `65d471fe0ce4f915cdd61` | `eb1dd930c6c084a3a9dce59ed57c5b0716730698daf88edbb197cceb08ffe721` | 1374×1076 |
| Locker Reliquary underlay | `/CUSTODIAN/implementation_inputs/awakening_locker_reliquary_underlay_source_v1.png` | `id:8NXqdXuW6GUAAAAAAAACkA` / `65d471fedf65b915cdd61` | `75e253f73f6570b72ed0b646648c2ba31902612c3241df82956b4d00ddd71a6c` | 1200×1211 |

## Publication and registration

- Dust Lung publishes byte-for-byte to its existing 1216×1216 `underlay` state.
- The complete connector publishes byte-for-byte at the new 1374×1076 family/runtime canvas. No crop, room-strip reconstruction, or feather compositor is used.
- Locker source is uniformly fit to 704×704 at scale `0.5813377374071016`, producing a 698×704 image centered with 3 transparent pixels on each horizontal side and no vertical crop. Normalization uses Lanczos resampling.
- The direct connector's source contact centers are `(278,80)` at the Dust Lung north-facing cut and `(1136,800)` at the Locker-facing lower threshold. They map to the unchanged Layout anchors `(0,-2656)` and `(704,-2272)`. The uniform similarity transform is scale `0.7159511476556676`, rotation `-0.198826` radians (`-11.391598°`), sprite center `(351.8212478598143,-2392.3907907448324)`.
- Layout's 04→05 `A/B/C` gameplay rectangles are unchanged. The connector is below both room underlays and world props; both room underlays remain fully opaque while the player is in or near the connector envelope.

## Locker foreground disposition

The existing Locker foreground has opaque pixels where the normalized new underlay is transparent: only 91.6% of pixels with foreground alpha ≥128 have fully opaque underlay support. It was removed from the scene and downgraded from required Asset V2 status. A deferred requirement records the foreground parity gap; the existing foreground file is preserved but unbound. No replacement foreground pixels were authored.

## Retired production path

The historical crop/strip/32px-feather compositor is retired. It must not populate the production inbox or create the live connector. Its old source masters remain preserved for provenance.
