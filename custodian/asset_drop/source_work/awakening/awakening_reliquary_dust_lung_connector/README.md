# 04→05 full-plate source provenance

`full_plate_source.png` is the byte-preserved approved root master
`connector_a.png` (1374×1145 RGB; SHA-256
`8ff4fc38682bad5d27ef81293833e5a7629a08c030f39532ad08df9f5d6e1264`). It is a
full composition source, not the previous `connector_a` state. The older
`connector_a/b/c` source masters and their normalization notes remain intact.

The new Asset V2 state is composed by
`custodian/tools/assets/compose_awakening_connector_full_plate.py`. Crop boxes
are source pixel edges (left, top, right, bottom); outputs use uniform Lanczos
downsampling and are placed into the unchanged Layout A/B/C union. Only canvas
outside the three authored route regions is made transparent. The generated
master has an opaque dark field, so dark pixels inside each architectural crop
are retained without chroma keying.

| Region | Source crop | Crop size | Target plate rectangle | Uniform scale |
|---|---|---:|---|---:|
| Dust Lung threshold | `(143, 370, 357, 530)` | 214×160 | `(0, 0, 128, 96)` | 0.5981 |
| Eastward corridor | `(250, 530, 1137, 691)` | 887×161 | `(64, 96, 768, 224)` | 0.7937 |
| Reliquary landing/run | `(1030, 691, 1244, 958)` | 214×267 | `(704, 224, 832, 384)` | 0.5981 |

Final target is `832×384 RGBA`, one frame. The three locked target regions are
opaque and canvas beyond them is transparent. The two joins meet at the source
route anchors `(250,530)` and `(1137,691)`; no gameplay/layout geometry changes.
